"""Powtarzalny wariant pixel art: paleta, siatka, poprawki i polana testowa.

python tools/pixelart_generator.py
Źródła pozostają nietknięte. Wyniki: game/assets/*-pixel, raport i podgląd w
game/assets/pixelart/. Ręczne poprawki: art-src/_pixel_overrides/<ID>/<atlas>.png
w NATYWNEJ siatce pikseli (atlas wyjściowy / pixel_size). Alfa 0 = bez zmiany;
alfa 255 = zastąp piksel. Osobna <atlas>.erase.png (biały = usuń) usuwa piksele.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import random
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

from sprite_pipeline import build, _write_sprite_frames
from pixelart_motion import rig_walk
from pixelart_terrain import make_ground, projection_guide
from welesza_assets import ART_SRC, GAME_ASSETS, REPO

ASSETS = ("HERO-bohater", "ENM-zdziczaly-pies", "PROP-drzewo-lisciaste", "PROP-kamien", "PROP-woz")
PROFILE = Path(__file__).with_name("pixelart_profile.json")


def palette_image(colors: list[str]) -> Image.Image:
    if not 2 <= len(colors) <= 256 or len(set(colors)) != len(colors):
        raise ValueError("Paleta wymaga 2–256 różnych kolorów")
    rgb = [tuple(bytes.fromhex(c)) for c in colors]
    if any(len(c) != 3 for c in rgb):
        raise ValueError("Kolory muszą mieć postać RRGGBB")
    p = Image.new("P", (1, 1))
    p.putpalette([v for c in rgb + [rgb[-1]] * (256 - len(rgb)) for v in c])
    return p


def pixelate(image: Image.Image, profile: dict) -> Image.Image:
    """Stała siatka całego atlasu; BOX respektuje alfę, brak ditheringu i auto-palety."""
    step = profile["pixel_size"]
    if step not in (1, 2, 4, 8) or any(v % step for v in image.size):
        raise ValueError("Siatka 1/2/4/8 musi dzielić wymiary obrazu i klatki")
    small = image.convert("RGBA").resize(tuple(v // step for v in image.size), Image.Resampling.BOX)
    alpha = small.getchannel("A").point(lambda a: 255 if a >= profile["alpha_threshold"] else 0)
    rgb = ImageEnhance.Contrast(small.convert("RGB")).enhance(profile["contrast"])
    rgb = rgb.filter(ImageFilter.UnsharpMask(radius=0.7, percent=110, threshold=5))
    rgb = rgb.quantize(palette=palette_image(profile["palette"]), dither=Image.Dither.NONE).convert("RGBA")
    rgb.putalpha(alpha)
    # Jeden kanoniczny kolor przezroczystości: powtarzalne pliki i porównania.
    data = np.array(rgb)
    data[data[:, :, 3] == 0] = 0
    return Image.fromarray(data)


def apply_override(small: Image.Image, override: Path, colors: list[str]) -> Image.Image:
    result = small.copy()
    if override.exists():
        with Image.open(override) as src:
            patch = src.convert("RGBA")
        if patch.size != small.size:
            raise ValueError(f"Zły wymiar poprawki: {override}, wymagany {small.size}")
        pixels = np.asarray(patch)
        if not np.isin(pixels[:, :, 3], [0, 255]).all():
            raise ValueError(f"Poprawka musi mieć ostrą alfę: {override}")
        allowed = {tuple(bytes.fromhex(c)) for c in colors}
        used = {tuple(c[:3]) for c in pixels.reshape(-1, 4) if c[3]}
        if not used <= allowed:
            raise ValueError(f"Kolory poprawki spoza palety: {override}")
        result.paste(patch, (0, 0), patch)
    erase = override.with_suffix(".erase.png")
    if erase.exists():
        with Image.open(erase) as src:
            mask = src.convert("L")
        if mask.size != small.size:
            raise ValueError(f"Zły wymiar maski: {erase}")
        result.paste((0, 0, 0, 0), (0, 0, *result.size), mask.point(lambda a: 255 if a >= 128 else 0))
    return result


def stabilize_walk(sheet: Image.Image, cell: tuple[int, int], frames: int,
                   max_shift: int) -> tuple[Image.Image, list[dict]]:
    """Usuwa dryf górnej części sylwetki; całe klatki przesuwane na całkowitej siatce.

    Nie deformuje części ciała. Nie stosować do ciosu/skoku, gdzie wychylenie jest celowe.
    """
    cw, ch = cell
    result = Image.new("RGBA", sheet.size)
    corrections = []
    for row in range(sheet.height // ch):
        images, centers = [], []
        for frame in range(frames):
            image = sheet.crop((frame*cw, row*ch, (frame+1)*cw, (row+1)*ch))
            alpha = np.asarray(image)[:, :, 3]
            ys, xs = np.nonzero(alpha)
            if not len(xs):
                raise ValueError("Nie można stabilizować pustej klatki")
            upper = xs[ys < ys.min() + max(1, (ys.max()-ys.min()) // 3)]
            centers.append(float(np.median(upper)))
            images.append(image)
        target = float(np.median(centers))
        for frame, (image, center) in enumerate(zip(images, centers)):
            shift = int(round(target - center))
            if abs(shift) > max_shift:
                raise ValueError(f"Dryf {shift}px przekracza bezpieczny limit: rząd {row}, klatka {frame}")
            box = image.getbbox()
            if box[0] + shift < 0 or box[2] + shift > cw:
                raise ValueError("Stabilizacja obcięłaby sylwetkę; wymagana korekta źródła")
            tile = Image.new("RGBA", (cw, ch))
            tile.paste(image, (shift, 0))
            result.paste(tile, (frame*cw, row*ch))
            corrections.append({"row": row, "frame": frame, "shift_x": shift})
    return result, corrections


def motion_preview(out_root: Path, review: Path, profile: dict, attack: bool = False) -> None:
    """Osiem kierunków jednocześnie: ocena pętli/ciosu bez ręcznego cięcia atlasów."""
    hero_anim, dog_anim = ("attack", "leap") if attack else ("walk", "walk")
    hero = Image.open(out_root / f"HERO-bohater-pixel/{hero_anim}.png").convert("RGBA")
    dog = Image.open(out_root / f"ENM-zdziczaly-pies-pixel/{dog_anim}.png").convert("RGBA")
    hero_n, dog_n = hero.width // 256, dog.width // 256
    images = []
    for frame in range(7 if attack else 24):
        sheet = Image.new("RGBA", (1280, 416), "#233339")
        draw = ImageDraw.Draw(sheet)
        for row, (atlas, count) in enumerate(((hero, hero_n), (dog, dog_n))):
            for direction, name in enumerate(("S", "SW", "W", "NW", "N", "NE", "E", "SE")):
                index = frame % count
                cell = atlas.crop((index*256+48, direction*256+32,
                                   index*256+208, direction*256+240))
                sheet.alpha_composite(cell, (direction*160, row*208))
                draw.text((direction*160+8, row*208+4), f"{hero_anim if row == 0 else dog_anim} {name}", fill="#bbc0a4")
        images.append(sheet.convert("RGB").quantize(palette=palette_image(profile["palette"]),
                                                    dither=Image.Dither.NONE))
    images[0].save(review / ("combat.gif" if attack else "walk.gif"), save_all=True,
                   append_images=images[1:], duration=83, loop=0, optimize=False)


def generate(profile: dict, source_root: Path = ART_SRC, out_root: Path = GAME_ASSETS,
             overrides: Path | None = None) -> dict:
    palette_image(profile["palette"])
    if profile["pixel_size"] not in (1, 2, 4, 8) or not 1 <= profile["alpha_threshold"] <= 255:
        raise ValueError("Niepoprawna siatka lub próg alfa")
    report = {"profile": profile, "generator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "inputs": {}, "overrides": {}, "outputs": {}, "stabilization": {}}
    rig_path = source_root / profile["walk_rig"]
    rigs = json.loads(rig_path.read_text())
    report["inputs"][rig_path.relative_to(source_root).as_posix()] = hashlib.sha256(rig_path.read_bytes()).hexdigest()
    for name in ("TILE-sciolka", "TILE-bloto"):
        for path in sorted((source_root / name).glob("*.png")):
            report["inputs"][path.relative_to(source_root).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    report["generator_sources"] = {
        name: hashlib.sha256(Path(__file__).with_name(name).read_bytes()).hexdigest()
        for name in ("pixelart_motion.py", "pixelart_terrain.py", "sprite_pipeline.py", "welesza_assets.py", "requirements.txt", "pixelart_geometry.py")
    }
    walk_telemetry = {}
    previews = []
    with tempfile.TemporaryDirectory() as tmp:
        cache = Path(tmp)
        for asset_id in ASSETS:
            for p in sorted((source_root / asset_id).rglob("*")):
                if p.is_file() and p.suffix in (".json", ".png"):
                    report["inputs"][p.relative_to(source_root).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
            if not build(asset_id, src_root=source_root, out_root=cache):
                raise ValueError(f"Niepoprawny asset źródłowy: {asset_id}")
            dest_id = asset_id + "-pixel"
            dest = out_root / dest_id
            dest.mkdir(parents=True, exist_ok=True)
            for p in sorted((cache / asset_id).iterdir()):
                if p.suffix == ".png":
                    with Image.open(p) as src:
                        source = src.convert("RGBA")
                        tint = profile.get("asset_tints", {}).get(asset_id)
                        if tint:
                            tinted = np.array(source)
                            tinted[:, :, :3] = np.clip(tinted[:, :, :3] * np.array(tint), 0, 255).astype(np.uint8)
                            source = Image.fromarray(tinted)
                        small = pixelate(source, profile)
                        size = src.size
                    stabilization = profile.get("walk_stabilization", {})
                    if p.stem == "walk" and stabilization.get("enabled", False):
                        source_meta = json.loads((cache / asset_id / "meta.json").read_text())
                        cell = tuple(v // profile["pixel_size"] for v in source_meta["cell"])
                        small, corrections = stabilize_walk(small, cell,
                                                            source_meta["animations"]["walk"]["frames"],
                                                            stabilization["max_shift"])
                        report["stabilization"][asset_id] = corrections
                    if overrides and not (p.stem == "walk" and asset_id in rigs):
                        patch = overrides / asset_id / p.name
                        small = apply_override(small, patch, profile["palette"])
                        for f in [patch, patch.with_suffix(".erase.png")]:
                            if f.exists():
                                report["overrides"][f.relative_to(overrides).as_posix()] = hashlib.sha256(f.read_bytes()).hexdigest()
                    small.resize(size, Image.Resampling.NEAREST).save(dest / p.name)
                    if p.stem == "idle" or (asset_id.startswith("ENM") and p.stem == "walk"):
                        # Pierwsza klatka s, sw, w, nw dla oceny sylwetki, bez resamplingu.
                        n = 1 if p.stem == "idle" else 6
                        cw, ch = size[0] // n, size[1] // 8
                        full = small.resize(size, Image.Resampling.NEAREST)
                        for row in range(4):
                            previews.append(full.crop((0, row * ch, cw, (row+1) * ch)))
                else:
                    text = p.read_text(encoding="utf-8").replace(asset_id, dest_id)
                    (dest / p.name).write_text(text, encoding="utf-8")
            if asset_id in rigs:
                runtime = json.loads((dest / "meta.json").read_text())
                reference_name = "idle.png" if (dest / "idle.png").exists() else "walk.png"
                with Image.open(dest / reference_name) as source:
                    reference = source.convert("RGBA").resize(tuple(v//profile["pixel_size"] for v in source.size),
                                                               Image.Resampling.NEAREST)
                audit = {}
                walk, telemetry = rig_walk(reference, rigs[asset_id], runtime["animations"]["walk"]["frames"],
                                           profile["pixel_size"], audit=audit)
                source_meta = json.loads((source_root / asset_id / "asset.json").read_text())
                directions = ["s", "sw", "w", "nw", "n", "ne", "e", "se"]
                for target, origin in source_meta.get("mirror", {}).items():
                    origin_row, target_row = directions.index(origin), directions.index(target)
                    for frame in range(runtime["animations"]["walk"]["frames"]):
                        cell = walk.crop((frame*128, origin_row*128, (frame+1)*128, (origin_row+1)*128))
                        walk.paste(cell.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (frame*128, target_row*128))
                    telemetry["directions"][target] = {"mirror_of": origin}
                    for audit_image in audit.values():
                        tile = audit_image.crop((0, origin_row*128, 128, (origin_row+1)*128))
                        audit_image.paste(tile.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (0, target_row*128))
                if overrides:
                    patch = overrides / asset_id / "walk.png"
                    walk = apply_override(walk, patch, profile["palette"])
                    for f in [patch, patch.with_suffix(".erase.png")]:
                        if f.exists():
                            report["overrides"][f.relative_to(overrides).as_posix()] = hashlib.sha256(f.read_bytes()).hexdigest()
                audit_path = out_root / "pixelart/audit" / asset_id
                audit_path.mkdir(parents=True, exist_ok=True)
                for label, audit_image in audit.items():
                    path = audit_path / f"{label}.png"
                    audit_image.save(path)
                    report["outputs"][path.relative_to(out_root).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
                walk.resize((runtime["animations"]["walk"]["frames"]*256, 8*256), Image.Resampling.NEAREST).save(dest / "walk.png")
                runtime["walk_cycle_distance"] = rigs[asset_id]["cycle_distance"]
                (dest / "meta.json").write_text(json.dumps(runtime, ensure_ascii=False, indent=2)+"\n")
                items = [(anim, f"{anim}.png", spec["frames"]) for anim, spec in runtime["animations"].items()]
                _write_sprite_frames(dest / "sprite_frames.tres", dest_id, items,
                                     ["s", "sw", "w", "nw", "n", "ne", "e", "se"], (256, 256), runtime["animations"])
                walk_telemetry[asset_id] = telemetry
            for p in sorted(dest.iterdir()):
                if p.suffix in (".png", ".tres", ".json"):
                    report["outputs"][p.relative_to(out_root).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
    review = out_root / "pixelart"
    review.mkdir(parents=True, exist_ok=True)
    ground = make_ground(profile)
    ground.save(review / "clearing.png")
    projection_guide(ground).save(review / "projection-guide.png")
    (review / "walk-poses.json").write_text(json.dumps(walk_telemetry, indent=2)+"\n")
    report["outputs"]["pixelart/clearing.png"] = hashlib.sha256((review / "clearing.png").read_bytes()).hexdigest()
    report["outputs"]["pixelart/walk-poses.json"] = hashlib.sha256((review / "walk-poses.json").read_bytes()).hexdigest()
    sheet = Image.new("RGBA", (1024, 512), "#233339")
    for i, im in enumerate(previews):
        sheet.alpha_composite(im, ((i % 4) * 256, (i // 4) * 256))
    sheet.save(review / "sprites.png")
    motion_preview(out_root, review, profile)
    motion_preview(out_root, review, profile, attack=True)
    (review / "manifest.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", type=Path, default=PROFILE)
    parser.add_argument("--overrides", type=Path, default=ART_SRC / "_pixel_overrides")
    args = parser.parse_args()
    generate(json.loads(args.profile.read_text(encoding="utf-8")), overrides=args.overrides)
    print("Pixel art: game/assets/*-pixel; podgląd i manifest: game/assets/pixelart/")


if __name__ == "__main__":
    main()
