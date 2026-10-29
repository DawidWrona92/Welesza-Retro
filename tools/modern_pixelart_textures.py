"""Deterministyczny generator modern pixel-art tekstur Weleszy.

python tools/modern_pixelart_textures.py --write   # konwersja i archiwizacja oryginałów
python tools/modern_pixelart_textures.py --check   # weryfikacja bajt po bajcie
"""
from __future__ import annotations

import argparse
import hashlib
import io
from pathlib import Path

import numpy as np
from PIL import Image, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "art-src" / "_tekstury"
SOURCE = ROOT / "art-src" / "_tekstury-source"
PREVIEW = ROOT / "docs" / "art" / "modern-pixelart-textures-preview.png"
MATERIALS = {
    "bark": (
        "birch_bark_white.png", "old_bark_weathered.png", "pine_bark_reddish_flaky.png"
    ),
    "ground": (
        "dense_forest_moss.png", "exposed_roots_wet_soil.png",
        "forest_litter_mixed.png", "forest_path_compacted_earth.png",
        "forest_soil_sparse_grass.png", "pine_needles_and_twigs.png",
        "wet_fallen_leaves.png", "wet_grass_earth.png", "wet_mud_with_puddles.png"
    ),
    "rock": (
        "rock_cracked_with_moss.png", "rock_lichen_moss_ground.png",
        "rock_stones_mossy.png"
    ),
}
# Nasycenie, jasność, kontrast, maksymalna luminancja. Matowa, ciemna paleta boru.
GRADING = {
    "birch_bark_white": (.72, .91, 1.04, 213),
    "old_bark_weathered": (.79, .84, 1.08, 197),
    "pine_bark_reddish_flaky": (.75, .86, 1.09, 199),
    "dense_forest_moss": (.76, .82, 1.08, 181),
    "exposed_roots_wet_soil": (.70, .82, 1.09, 189),
    "forest_litter_mixed": (.70, .81, 1.07, 194),
    "forest_path_compacted_earth": (.73, .85, 1.07, 196),
    "forest_soil_sparse_grass": (.72, .85, 1.06, 194),
    "pine_needles_and_twigs": (.71, .84, 1.07, 192),
    "wet_fallen_leaves": (.70, .80, 1.10, 190),
    "wet_grass_earth": (.70, .82, 1.07, 184),
    "wet_mud_with_puddles": (.70, .81, 1.07, 193),
    "rock_cracked_with_moss": (.65, .86, 1.08, 203),
    "rock_lichen_moss_ground": (.65, .84, 1.06, 200),
    "rock_stones_mossy": (.66, .84, 1.07, 199),
}
WORK_SIZE = 256
COLORS = 28
SEAM = 12


def _grade(im: Image.Image, stem: str) -> Image.Image:
    sat, bright, contrast, ceiling = GRADING[stem]
    im = ImageEnhance.Color(im).enhance(sat)
    im = ImageEnhance.Brightness(im).enhance(bright)
    im = ImageEnhance.Contrast(im).enhance(contrast)
    pixels = np.asarray(im, dtype=np.float32)
    luminance = pixels[..., 0] * .2126 + pixels[..., 1] * .7152 + pixels[..., 2] * .0722
    factor = np.minimum(1., ceiling / np.maximum(luminance, 1.))
    pixels *= factor[..., None]
    return Image.fromarray(np.clip(pixels + .5, 0, 255).astype(np.uint8), "RGB")


def _seamless(im: Image.Image) -> Image.Image:
    """Dopasuj brzegi kafla; brak powtarzalnych jasnych pionowych linii."""
    px = np.asarray(im, dtype=np.float32).copy()
    for d in range(SEAM):
        strength = .5 * (1. - d / SEAM) ** 2
        a, b = px[:, d, :].copy(), px[:, -1 - d, :].copy()
        px[:, d, :] = a * (1. - strength) + b * strength
        px[:, -1 - d, :] = b * (1. - strength) + a * strength
    for d in range(SEAM):
        strength = .5 * (1. - d / SEAM) ** 2
        a, b = px[d, :, :].copy(), px[-1 - d, :, :].copy()
        px[d, :, :] = a * (1. - strength) + b * strength
        px[-1 - d, :, :] = b * (1. - strength) + a * strength
    edge = ((px[:, 0, :] + px[:, -1, :]) * .5).copy()
    px[:, 0, :] = px[:, -1, :] = edge
    edge = ((px[0, :, :] + px[-1, :, :]) * .5).copy()
    px[0, :, :] = px[-1, :, :] = edge
    return Image.fromarray(np.clip(px + .5, 0, 255).astype(np.uint8), "RGB")


def pixelart(source: Image.Image, stem: str) -> Image.Image:
    """Zachowaj plamy i układ oryginału, odrzuć fotograficzny szum."""
    dimensions = source.size
    low = source.convert("RGB").resize((WORK_SIZE, WORK_SIZE), Image.Resampling.BOX)
    low = low.filter(ImageFilter.MedianFilter(3))
    low = low.filter(ImageFilter.GaussianBlur(.42))
    low = _grade(low, stem)
    low = _seamless(low)
    low = low.quantize(colors=COLORS, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    low = low.filter(ImageFilter.ModeFilter(3))
    indices = np.asarray(low, dtype=np.uint8).copy()
    indices[:, -1] = indices[:, 0]
    indices[-1, :] = indices[0, :]
    low.putdata(indices.reshape(-1).tolist())
    return low.resize(dimensions, Image.Resampling.NEAREST)


def _png_bytes(image: Image.Image) -> bytes:
    out = io.BytesIO()
    image.save(out, format="PNG", optimize=True)
    return out.getvalue()


def _preview(previews: list[tuple[str, Image.Image]]) -> bytes:
    from PIL import ImageDraw
    cell, label, columns = 190, 31, 3
    rows = (len(previews) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * cell, rows * (cell + label)), (27, 30, 29))
    pen = ImageDraw.Draw(sheet)
    for i, (name, image) in enumerate(previews):
        x, y = (i % columns) * cell, (i // columns) * (cell + label)
        sheet.paste(image.convert("RGB").resize((cell, cell), Image.Resampling.NEAREST), (x, y))
        pen.text((x + 3, y + cell + 4), name[:28], fill=(211, 207, 191))
    return _png_bytes(sheet)


def generate(check: bool) -> int:
    if check and not SOURCE.exists():
        print("Brak art-src/_tekstury-source; uruchom --write.")
        return 2
    failures: list[str] = []
    previews: list[tuple[str, Image.Image]] = []
    for group, names in MATERIALS.items():
        for name in names:
            src, dst = SOURCE / group / name, DEST / group / name
            if not src.exists() and not check:
                if not dst.exists():
                    raise FileNotFoundError(dst)
                src.parent.mkdir(parents=True, exist_ok=True)
                src.write_bytes(dst.read_bytes())
            with Image.open(src) as original:
                generated = pixelart(original, Path(name).stem)
            payload = _png_bytes(generated)
            if check:
                if not dst.is_file() or dst.read_bytes() != payload:
                    failures.append(str(dst.relative_to(ROOT)))
            else:
                dst.write_bytes(payload)
            previews.append((Path(name).stem, generated))
            print(f"{'OK' if not check or dst.read_bytes() == payload else 'FAIL'} {group}/{name}: {generated.size}, {COLORS} kolorów")
    sheet = _preview(previews)
    if check:
        if not PREVIEW.is_file() or PREVIEW.read_bytes() != sheet:
            failures.append(str(PREVIEW.relative_to(ROOT)))
    else:
        PREVIEW.parent.mkdir(parents=True, exist_ok=True)
        PREVIEW.write_bytes(sheet)
    if failures:
        print("Różnice względem generatora:\n" + "\n".join(failures))
        return 1
    print(f"Zweryfikowano {len(previews)} materiałów; SHA256 podglądu: {hashlib.sha256(sheet).hexdigest()}")
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--check", action="store_true")
    args = parser.parse_args()
    raise SystemExit(generate(check=args.check))
