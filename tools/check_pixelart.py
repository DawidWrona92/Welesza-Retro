"""Automatyczna bramka jakości; --build buduje, --godot BIN sprawdza również grę.

python tools/check_pixelart.py --build --godot godot
Zapisuje raport z podejrzanymi klatkami zamiast wymagać oglądania całych atlasów.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

from pixelart_generator import ASSETS, PROFILE, generate
from welesza_assets import ART_SRC, GAME_ASSETS, REPO


def frame_issues(alpha: np.ndarray) -> list[dict]:
    """Sygnały wycieku między klatkami; brak semantycznej oceny broni czy anatomii."""
    occupied = alpha > 0
    issues = []
    if occupied[0].any() or occupied[-1].any() or occupied[:, 0].any() or occupied[:, -1].any():
        issues.append({"kind": "canvas_edge"})
    seen = np.zeros_like(occupied)
    components = []
    for y, x in zip(*np.nonzero(occupied)):
        if seen[y, x]:
            continue
        stack = [(int(y), int(x))]
        seen[y, x] = True
        points = []
        while stack:
            py, px = stack.pop()
            points.append((px, py))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = py + dy, px + dx
                    if (0 <= ny < alpha.shape[0] and 0 <= nx < alpha.shape[1]
                            and occupied[ny, nx] and not seen[ny, nx]):
                        seen[ny, nx] = True
                        stack.append((ny, nx))
        components.append(points)
    components.sort(key=len, reverse=True)
    for points in components[1:]:
        if len(points) >= 6:
            xs, ys = zip(*points)
            issues.append({"kind": "detached_cluster", "pixels": len(points),
                           "box": [min(xs), min(ys), max(xs)+1, max(ys)+1]})
    return issues


def check_runtime_contract(source: dict, runtime: dict, asset_id: str) -> None:
    """Kontrakt źródłowy jest nadrzędny także dla proceduralnego chodu."""
    expected = {a: dict(spec, events=spec.get("events", []))
                for a, spec in source.get("animations", {}).items()}
    for key, value in {"id": asset_id + "-pixel", "kind": source["kind"],
                       "cell": [v // 2 for v in source["canvas"]],
                       "anchor": [v / 2 for v in source["anchor"]],
                       "layers": source.get("layers", []), "animations": expected}.items():
        actual = runtime.get(key, {} if key == "animations" else None)
        if actual != value:
            raise ValueError(f"Kontrakt {key} zmieniony: {asset_id}")
    if "collision" in source:
        collision = source["collision"]
        expected_collision = ({"circle": collision["circle"] / 2} if "circle" in collision else
                              {"polygon": [[x / 2, y / 2] for x, y in collision["polygon"]]})
        if runtime.get("collision") != expected_collision:
            raise ValueError(f"Kolizja zmieniona: {asset_id}")


def check() -> dict:
    manifest = json.loads((GAME_ASSETS / "pixelart/manifest.json").read_text())
    profile = manifest["profile"]
    # Zmiana profilu wymaga przebudowy; nie akceptujemy przypadkiem starych wyników.
    if profile != json.loads(PROFILE.read_text()):
        raise ValueError("Profil zmieniony: przebuduj pixel art")
    generator = Path(__file__).with_name("pixelart_generator.py")
    if hashlib.sha256(generator.read_bytes()).hexdigest() != manifest["generator_sha256"]:
        raise ValueError("Generator zmieniony: przebuduj pixel art")
    for name, digest in manifest.get("generator_sources", {}).items():
        if hashlib.sha256(Path(__file__).with_name(name).read_bytes()).hexdigest() != digest:
            raise ValueError(f"Moduł {name} zmieniony: przebuduj pixel art")
    for name, digest in manifest["inputs"].items():
        if hashlib.sha256((ART_SRC / name).read_bytes()).hexdigest() != digest:
            raise ValueError(f"Źródło zmienione: {name}")
    override_root = ART_SRC / "_pixel_overrides"
    current_overrides = {
        p.relative_to(override_root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
        for p in override_root.rglob("*.png")
    }
    if current_overrides != manifest["overrides"]:
        raise ValueError("Poprawki zmienione lub nieużyte: przebuduj i sprawdź ich nazwy")
    for name, digest in manifest["outputs"].items():
        if hashlib.sha256((GAME_ASSETS / name).read_bytes()).hexdigest() != digest:
            raise ValueError(f"Wynik zmieniony poza pipeline'em: {name}")
    allowed = {tuple(bytes.fromhex(c)) for c in profile["palette"]}
    report = {"assets": len(ASSETS), "atlases": 0, "frames": 0, "warnings": []}
    step = profile["pixel_size"]
    for asset_id in ASSETS:
        source = json.loads((ART_SRC / asset_id / "asset.json").read_text())
        dest = GAME_ASSETS / (asset_id + "-pixel")
        runtime = json.loads((dest / "meta.json").read_text())
        check_runtime_contract(source, runtime, asset_id)
        for path in sorted(dest.glob("*.png")):
            data = np.asarray(Image.open(path).convert("RGBA"))
            if source["kind"] == "character":
                spec = runtime["animations"].get(path.stem)
                if spec is None or data.shape[:2] != (runtime["cell"][1] * 8,
                                                      runtime["cell"][0] * spec["frames"]):
                    raise ValueError(f"Wymiary atlasu niezgodne z kontraktem: {path}")
            small = data[::step, ::step]
            restored = small.repeat(step, 0).repeat(step, 1)
            if not np.array_equal(restored, data):
                raise ValueError(f"Piksele poza siatką: {path}")
            if not set(np.unique(data[:, :, 3])) <= {0, 255}:
                raise ValueError(f"Miękka alfa: {path}")
            visible = small[small[:, :, 3] == 255]
            if not {tuple(p[:3]) for p in visible} <= allowed:
                raise ValueError(f"Kolory poza paletą: {path}")
            report["atlases"] += 1
            if source["kind"] != "character":
                continue
            cw, ch = [v // step for v in runtime["cell"]]
            anim = path.stem
            n = runtime["animations"][anim]["frames"]
            directions = ("s", "sw", "w", "nw", "n", "ne", "e", "se")
            if anim == "walk":
                for target, origin in source.get("mirror", {}).items():
                    a, b = directions.index(target), directions.index(origin)
                    for frame in range(n):
                        actual = small[a*ch:(a+1)*ch, frame*cw:(frame+1)*cw]
                        expected = small[b*ch:(b+1)*ch, frame*cw:(frame+1)*cw][:, ::-1]
                        if not np.array_equal(actual, expected):
                            raise ValueError(f"Niespójne odbicie {asset_id}/{target}/{frame}")
            for row, direction in enumerate(directions):
                centers = []
                previous = None
                for frame in range(n):
                    alpha = small[row*ch:(row+1)*ch, frame*cw:(frame+1)*cw, 3]
                    ys, xs = np.nonzero(alpha)
                    if not len(xs):
                        raise ValueError(f"Pusta klatka {asset_id}/{anim}/{direction}/{frame}")
                    for issue in frame_issues(alpha):
                        report["warnings"].append(dict(issue, asset=asset_id, animation=anim,
                                                       direction=direction, frame=frame))
                    # Górna 1/3 sylwetki: tani sygnał dryfu głowy/ramion, bez oceny anatomii.
                    upper = xs[ys < ys.min() + max(1, (ys.max()-ys.min()) // 3)]
                    center = float(np.median(upper))
                    if anim == "walk" and previous is not None and abs(center - previous) > 4:
                        report["warnings"].append({"asset": asset_id, "animation": anim,
                                                   "direction": direction, "frame": frame,
                                                   "upper_body_shift_px": round(center - previous, 1)})
                    centers.append(center)
                    previous = center
                    report["frames"] += 1
                if anim == "walk" and abs(centers[-1] - centers[0]) > 4:
                    report["warnings"].append({"asset": asset_id, "animation": anim,
                        "direction": direction, "frame": 0, "kind": "loop_body_shift",
                        "upper_body_shift_px": round(centers[0] - centers[-1], 1)})
    (GAME_ASSETS / "pixelart/quality.json").write_text(json.dumps(report, indent=2) + "\n")
    # Każda podejrzana klatka raz; podgląd tworzony automatycznie obok raportu.
    flagged = {}
    for warning in report["warnings"]:
        key = (warning["asset"], warning["animation"], warning["direction"], warning["frame"])
        flagged.setdefault(key, []).append(warning.get("kind", "body_shift"))
    if flagged:
        sheet = Image.new("RGB", (6*160, ((len(flagged)+5)//6)*172), "#233339")
        draw = ImageDraw.Draw(sheet)
        directions = ("s", "sw", "w", "nw", "n", "ne", "e", "se")
        for i, ((asset, anim, direction, frame), reasons) in enumerate(flagged.items()):
            with Image.open(GAME_ASSETS / f"{asset}-pixel/{anim}.png") as atlas:
                row = directions.index(direction)
                tile = atlas.crop((frame*256, row*256, (frame+1)*256, (row+1)*256))
                tile = tile.resize((128, 128), Image.Resampling.NEAREST).convert("RGBA")
            x, y = (i % 6)*160, (i // 6)*172
            sheet.paste(tile, (x+16, y), tile)
            draw.text((x+4, y+128), f"{asset.split('-')[0]} {anim}_{direction} #{frame}\n{', '.join(reasons)}", fill="#cfad75")
        sheet.save(GAME_ASSETS / "pixelart/quality_review.png")
    else:
        sheet = Image.new("RGB", (960, 172), "#233339")
        ImageDraw.Draw(sheet).text((24, 60), "Brak klatek wskazanych przez heurystyki. Sprawdz walk.gif i combat.gif.", fill="#cfad75")
        sheet.save(GAME_ASSETS / "pixelart/quality_review.png")
    broken_walk = [w for w in report["warnings"] if w["animation"] == "walk"]
    if broken_walk:
        raise ValueError(f"Chód nie przeszedł bramki: {len(broken_walk)} problemów; zobacz quality_review.png")
    return report


def run(command: list[str], env: dict) -> None:
    completed = subprocess.run(command, cwd=REPO, env=env, text=True,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
    print(completed.stdout, end="", flush=True)
    completed.check_returncode()
    if any(line.startswith(("ERROR:", "SCRIPT ERROR:")) for line in completed.stdout.splitlines()):
        raise RuntimeError(f"Błędy w logu pomimo kodu wyjścia 0: {command}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", action="store_true")
    parser.add_argument("--godot", help="Binarka Godota 4.7.2; uruchom import, testy i pokaz walki")
    args = parser.parse_args()
    if args.build:
        generate(json.loads(PROFILE.read_text()), overrides=ART_SRC / "_pixel_overrides")
    result = check()
    print(f"PIXEL_QUALITY {result['frames']} klatek, {result['atlases']} atlasów; "
          f"{len(result['warnings'])} ostrzeżeń ruchu (quality.json)", flush=True)
    if args.godot:
        env = os.environ.copy()
        for name, directory in [("XDG_CONFIG_HOME", ".config"), ("XDG_CACHE_HOME", ".cache"),
                                ("XDG_DATA_HOME", ".local/share")]:
            env.setdefault(name, str(REPO.parent / directory))
            Path(env[name]).mkdir(parents=True, exist_ok=True)
        version = subprocess.check_output([args.godot, "--version"], env=env, text=True)
        if not version.strip().startswith("4.7.2.stable."):
            raise ValueError(f"Wymagany Godot 4.7.2, otrzymano {version.strip()}")
        run([sys.executable, "-m", "unittest", "discover", "-s", "tools/tests"], env)
        run([args.godot, "--headless", "--path", "game", "--editor", "--import", "--quit"], env)
        run([args.godot, "--headless", "--path", "game", "--script", "res://tests/run_tests.gd"], env)
        run([args.godot, "--headless", "--path", "game", "res://world/pixelart/pixelart.tscn", "--", "--demo"], env)


if __name__ == "__main__":
    main()
