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

from sprite_pipeline import build
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


def make_ground(profile: dict) -> Image.Image:
    """Autorski teren z klastrów pikseli, bez modelu generatywnego i tekstur GPT."""
    rng = random.Random(profile["seed"])
    im = Image.new("RGB", (896, 544), "#233339")
    d = ImageDraw.Draw(im)
    grass = ["#202923", "#2c392b", "#3c4c32", "#52603b", "#6a7548"]
    earth = ["#352a24", "#49382a", "#604833", "#7c5b3c", "#997348"]
    # Pochylony trakt, łagodne zmiany szerokości; piksele pogrupowane w płaskie kamyczki.
    for y in range(544):
        for x in range(896):
            center = 445 + (y - 272) * 0.60 + 19 * np.sin(y / 70)
            edge = abs(x - center) / (130 + 10 * np.sin(y / 43))
            if edge < 1:
                c = earth[1 if edge > .85 else 2]
            else:
                c = grass[1]
            d.point((x, y), fill=c)
    for _ in range(37000):
        x, y = rng.randrange(896), rng.randrange(544)
        center = 445 + (y - 272) * .60 + 19 * np.sin(y / 70)
        distance = abs(x - center)
        road = distance < 128 + rng.randrange(-20, 20)
        colors = earth if road else grass
        color = rng.choices(colors, [2, 4, 5, 3, 1])[0]
        w, h = rng.randrange(1, 6), rng.randrange(1, 3)
        d.rectangle((x, y, x + w, y + h), fill=color)
        if not road and rng.random() < .2:
            d.line((x, y, x + 1, y - 3), fill=grass[3])
    # Kałuże z poziomymi odbiciami, zgodne z izometrią.
    for x, y, w in [(459, 400, 43), (405, 306, 25), (431, 179, 32), (532, 459, 21), (352, 92, 19)]:
        poly = [(x-w,y), (x-w//2,y-5), (x+w//3,y-7), (x+w,y-1), (x+w//2,y+6), (x-w//3,y+5)]
        d.polygon(poly, fill="#30464a")
        d.line([(x-w+5,y+2),(x-w//4,y+4),(x+w//2,y+2)], fill="#5d7574", width=1)
        for _ in range(12):
            px, py = x + rng.randrange(-w//2, w//2), y + rng.randrange(-3, 4)
            d.line((px, py, px + rng.randrange(2, 8), py), fill="#41595b")
    return im.resize((1792, 1088), Image.Resampling.NEAREST)


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
                    if overrides:
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
            for p in sorted(dest.iterdir()):
                if p.suffix in (".png", ".tres", ".json"):
                    report["outputs"][p.relative_to(out_root).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
    review = out_root / "pixelart"
    review.mkdir(parents=True, exist_ok=True)
    make_ground(profile).save(review / "clearing.png")
    report["outputs"]["pixelart/clearing.png"] = hashlib.sha256((review / "clearing.png").read_bytes()).hexdigest()
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
