"""Pipeline sprite'ów: art-src/<ID>/ -> game/assets/<ID>/.

Kroki: walidacja kontraktu, usunięcie tła, cięcie pasków na klatki, wyrównanie styku z ziemią do
kotwicy (jedno przesunięcie na cały pasek, żeby nie psuć ruchu), odbicia brakujących kierunków,
zmniejszenie do rozdzielczości gry, atlas, SpriteFrames (.tres) i meta.json dla gry.

Użycie: python3 tools/sprite_pipeline.py [ID ...]   (bez argumentów: wszystkie assety z art-src/)
"""

from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

from validate_asset import validate
from welesza_assets import (ART_SRC, DIRECTIONS, GAME_ASSETS, SOURCE_SCALE, ground_point, load_meta,
                            painted_and_mirrored, split_strip, strip_path, to_rgba)

RES_ROOT = "res://assets"
# Jak w asset_schema.json. Argument to ID, nie ścieżka: ścieżka absolutna wskazałaby katalog
# wyjściowy poza game/assets, a build go czyści.
ID_RE = re.compile(r"^(HERO|ENM|CHR|PROP|TILE|TEST)-[a-z0-9-]+$")


def build(asset_id: str, src_root: Path = ART_SRC, out_root: Path = GAME_ASSETS) -> bool:
    if not ID_RE.match(asset_id):
        print(f"[BŁĄD] {asset_id}\n  błąd: to nie jest ID assetu (np. ENM-zdziczaly-pies)")
        return False
    asset_dir = src_root / asset_id
    rep = validate(asset_dir)
    rep.print(asset_id)
    if not rep.ok:
        return False
    meta = load_meta(asset_dir)
    out = out_root / asset_id
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    runtime = {
        "id": meta["id"],
        "kind": meta["kind"],
        "cell": [meta["canvas"][0] // SOURCE_SCALE, meta["canvas"][1] // SOURCE_SCALE],
        "anchor": [v / SOURCE_SCALE for v in meta["anchor"]],
        "layers": meta.get("layers", []),
    }
    if "collision" in meta:
        col = meta["collision"]
        runtime["collision"] = ({"circle": col["circle"] / SOURCE_SCALE} if "circle" in col else
                                {"polygon": [[x / SOURCE_SCALE, y / SOURCE_SCALE] for x, y in col["polygon"]]})
    if "occlusion_y" in meta:
        runtime["occlusion_y"] = meta["occlusion_y"] / SOURCE_SCALE
    if meta["kind"] == "tile":
        runtime["variants"] = meta["variants"]
    if meta["kind"] == "character":
        runtime["animations"] = _build_character(asset_dir, meta, out, rep)
    else:
        _build_static(asset_dir, meta, out)
    (out / "meta.json").write_text(json.dumps(runtime, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    rep.print(f"{asset_id}: zbudowano {out.relative_to(out_root.parent.parent) if out_root == GAME_ASSETS else out}")
    return True


def _build_character(asset_dir: Path, meta: dict, out: Path, rep) -> dict:
    w, h = meta["canvas"]
    cw, ch = w // SOURCE_SCALE, h // SOURCE_SCALE
    ax, ay = meta["anchor"]
    bg = meta.get("background", "transparent")
    sources = painted_and_mirrored(meta)
    dirs = [d for d in DIRECTIONS if d in sources]
    ref_layer = "full" if "full" in meta["layers"] else "body"
    anims_meta = {}
    atlases: dict[str, list[tuple[str, str, int]]] = {layer: [] for layer in meta["layers"]}
    for anim, spec in meta["animations"].items():
        n = spec["frames"]
        strips: dict[tuple[str, str], list[np.ndarray]] = {}
        for layer in meta["layers"]:
            for d in meta["directions"]:
                strips[(layer, d)] = split_strip(to_rgba(strip_path(asset_dir, meta, anim, layer, d), bg), n, (w, h))
        # jedno przesunięcie na pasek: mediana styku z ziemią warstwy odniesienia trafia w kotwicę
        offsets = {}
        for d in meta["directions"]:
            pts = [p for p in (ground_point(f) for f in strips[(ref_layer, d)]) if p]
            mx, my = np.median([p[0] for p in pts]), np.median([p[1] for p in pts])
            offsets[d] = (int(round(ax - mx)), int(round(ay - my)))
            if max(abs(v) for v in offsets[d]) > 2:
                rep.notes.append(f"{anim}/{d}: przesunięto o {offsets[d]}")
        for layer in meta["layers"]:
            sheet = Image.new("RGBA", (cw * n, ch * len(dirs)), (0, 0, 0, 0))
            for row, d in enumerate(dirs):
                src, flip = sources[d]
                for i, fr in enumerate(strips[(layer, src)]):
                    img = Image.fromarray(np.clip(fr, 0, 255).astype(np.uint8), "RGBA")
                    img = _shift(img, *offsets[src])
                    if flip:
                        # odbicie wokół kotwicy, nie wokół środka płótna
                        img = _shift(img.transpose(Image.Transpose.FLIP_LEFT_RIGHT), int(round(2 * ax - w + 1)), 0)
                    img = img.resize((cw, ch), Image.Resampling.LANCZOS)
                    sheet.paste(img, (i * cw, row * ch))
            name = f"{anim}.png" if layer == "full" else f"{anim}_{layer}.png"
            sheet.save(out / name, optimize=True)
            atlases[layer].append((anim, name, n))
        anims_meta[anim] = {"frames": n, "fps": spec["fps"], "loop": spec["loop"],
                            "events": spec.get("events", [])}
    for layer, items in atlases.items():
        fname = "sprite_frames.tres" if layer == "full" else f"sprite_frames_{layer}.tres"
        _write_sprite_frames(out / fname, meta["id"], items, dirs, (cw, ch), anims_meta)
    return anims_meta


def _shift(img: Image.Image, dx: int, dy: int) -> Image.Image:
    if dx == 0 and dy == 0:
        return img
    canvas = Image.new("RGBA", img.size, (0, 0, 0, 0))
    canvas.paste(img, (dx, dy))
    return canvas


def _build_static(asset_dir: Path, meta: dict, out: Path) -> None:
    w, h = meta["canvas"]
    bg = meta.get("background", "transparent")
    names = ([f"{layer}.png" for layer in meta["layers"]] if meta["kind"] == "prop"
             else [f"{i:02d}.png" for i in range(1, meta["variants"] + 1)])
    for name in names:
        img = Image.fromarray(np.clip(to_rgba(asset_dir / name, bg), 0, 255).astype(np.uint8), "RGBA")
        img.resize((w // SOURCE_SCALE, h // SOURCE_SCALE), Image.Resampling.LANCZOS).save(out / name, optimize=True)


def _write_sprite_frames(path: Path, asset_id: str, items: list[tuple[str, str, int]], dirs: list[str],
                         cell: tuple[int, int], anims_meta: dict) -> None:
    cw, ch = cell
    ext = []
    subs = []
    anims = []
    for ei, (anim, name, n) in enumerate(items, start=1):
        ext.append(f'[ext_resource type="Texture2D" path="{RES_ROOT}/{asset_id}/{name}" id="{ei}"]')
        spec = anims_meta[anim]
        for row, d in enumerate(dirs):
            frames = []
            for i in range(n):
                sid = f"{anim}_{d}_{i}"
                subs.append(f'[sub_resource type="AtlasTexture" id="{sid}"]\natlas = ExtResource("{ei}")\n'
                            f"region = Rect2({i * cw}, {row * ch}, {cw}, {ch})")
                frames.append(f'{{"duration": 1.0, "texture": SubResource("{sid}")}}')
            loop = "true" if spec["loop"] else "false"
            anims.append(f'{{"frames": [{", ".join(frames)}], "loop": {loop}, '
                         f'"name": &"{anim}_{d}", "speed": {float(spec["fps"])}}}')
    body = [f'[gd_resource type="SpriteFrames" load_steps={len(ext) + len(subs) + 1} format=3]', ""]
    body += ext + [""]
    for s in subs:
        body += [s, ""]
    body += ["[resource]", f"animations = [{', '.join(anims)}]", ""]
    path.write_text("\n".join(body), encoding="utf-8")


def main(argv: list[str]) -> int:
    ids = argv or sorted(p.name for p in ART_SRC.iterdir() if p.is_dir() and not p.name.startswith("_"))
    results = [build(i) for i in ids]
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
