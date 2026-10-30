"""Deterministyczny generator modern pixel-art v3 dla 15 tekstur Weleszy.

python tools/modern_pixelart_textures.py --write   # generacja od oryginałów
python tools/modern_pixelart_textures.py --check   # weryfikacja bajt po bajcie

Kora zachowuje drobniejszy rytm 128x128, podłoże i skały 64x64.
Ostre klastry, posterization + wyostrzenie zamiast rozmytych półtonów.
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
# Parametry per grupa materiału: większy piksel w ziemi i skałach.
WORK_SIZES = {"bark": 128, "ground": 64, "rock": 64}
COLORS = {"bark": 12, "ground": 10, "rock": 10}
SEAM = 8
CONTRAST_BOOST = {"bark": 1.28, "ground": 1.58, "rock": 1.42}
CLUSTER_PASSES = 1  # Jeden mały przebieg: detale liści i pęknięcia zostają
POSTERIZE_LEVELS = {"bark": 5, "ground": 7, "rock": 7}


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


def _material_group(stem: str) -> str:
    """Zwraca kategorię materiału (źródłem prawdy jest MATERIALS)."""
    for group, names in MATERIALS.items():
        if f"{stem}.png" in names:
            return group
    raise ValueError(f"Nieznany materiał: {stem}")


def _posterize_bands(im: Image.Image, levels: int) -> Image.Image:
    """Dyskretyzuje luminancję, a nie trzy kanały RGB osobno.

    Niezależna posterizacja R/G/B zmieniała brązy i zielenie w jaskrawe
    czerwienie/fiolety. Jedna wspólna skala zachowuje odcień materiału.
    """
    if levels < 2:
        raise ValueError("Posterize: levels musi być >= 2")
    arr = np.asarray(im.convert("RGB"), dtype=np.float32)
    lum = arr[..., 0] * .2126 + arr[..., 1] * .7152 + arr[..., 2] * .0722
    index = np.floor(lum * (levels - 1) / 255 + .5).astype(np.int16)
    ramp = np.floor(np.arange(levels, dtype=np.float32) * 255 / (levels - 1) + .5)
    quant = ramp[index]
    factor = quant / np.maximum(lum, 1)
    poster = np.clip(arr * factor[..., None] + .5, 0, 255).astype(np.uint8)
    # Dla neutralnych szarości ton musi być dokładnie jednym poziomem rampy.
    # Zapobiega to dodatkowym odcieniom przez zaokrąglenie float32.
    gray = (arr[..., 0] == arr[..., 1]) & (arr[..., 1] == arr[..., 2])
    poster[gray] = quant[gray, None].astype(np.uint8)
    return Image.fromarray(poster, "RGB")

def pixelart(source: Image.Image, stem: str) -> Image.Image:
    """Wyraźny modern pixel-art: oddzielne siatki dla kory / ziemi / skał.

    Odrzucamy szum, ograniczamy półtony, wyostrzamy znaczące kontury
    i budujemy duże jednorodne klastry przed powiększeniem NEAREST.
    """
    dimensions = source.size
    if dimensions != (1024, 1024):
        raise ValueError(f"Oczekiwano tekstury 1024x1024: {stem}: {dimensions}")

    group = _material_group(stem)
    work_size = WORK_SIZES[group]
    colors = COLORS[group]

    # Przy 64x64 zwykły BOX uśredniał wszystko do jednolitej plamy.
    # Zachowaj detale przez antyaliasing tylko w próbkowanej ćwiartce pola.
    # To deterministyczny wybór barwy, nie losowy szum i bez wygładzania pikseli.
    if group == "bark":
        low = source.convert("RGB").resize((work_size, work_size), Image.Resampling.BOX)
    else:
        sample = source.convert("RGB").resize((work_size * 2, work_size * 2),
                                              Image.Resampling.BOX)
        low = sample.resize((work_size, work_size), Image.Resampling.NEAREST)
    low = low.filter(ImageFilter.MedianFilter(3))
    low = _grade(low, stem)
    low = ImageEnhance.Contrast(low).enhance(CONTRAST_BOOST[group])
    low = _posterize_bands(low, POSTERIZE_LEVELS[group])
    low = low.filter(ImageFilter.UnsharpMask(radius=1, percent=180, threshold=2))
    low = _seamless(low)
    low = low.quantize(colors=colors, method=Image.Quantize.MEDIANCUT,
                       dither=Image.Dither.NONE)
    # Lekki filtr usuwa samotne piksele; nie zjada form liści i pęknięć.
    for _ in range(CLUSTER_PASSES):
        low = low.filter(ImageFilter.ModeFilter(3))

    # Szwów na skrajach kafla nie może uszkodzić filtr klastrów.
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
    """Przegląd 15 tekstur: skalowanie NEAREST, bez ukrywania struktury."""
    from PIL import ImageDraw
    cell, label, columns = 320, 30, 3
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
            pixel_size = 1024 // WORK_SIZES[group]
            ok = not check or (dst.exists() and dst.read_bytes() == payload)
            print(f"{'OK' if ok else 'FAIL'} {group}/{name}: {generated.size}, "
                  f"<= {COLORS[group]} kolorów, siatka {WORK_SIZES[group]}x{WORK_SIZES[group]}, "
                  f"piksel {pixel_size}x{pixel_size}")
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
