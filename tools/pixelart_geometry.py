"""Kontrola pełnej maski alfa i niezmiennych części; nie klasyfikator anatomii."""
from collections import deque

import numpy as np
from PIL import Image, ImageDraw


def interior_mask(alpha: np.ndarray) -> np.ndarray:
    """Przezroczyste wnętrza bez 8-kierunkowej drogi do brzegu płótna.

    Łączność 8 nie uznaje ukośnej szczeliny między kończynami za dziurę.
    """
    empty = alpha == 0
    height, width = empty.shape
    outside = np.zeros_like(empty)
    queue = deque()
    for y, x in [(0, x) for x in range(width)] + [(height-1, x) for x in range(width)] + \
                [(y, 0) for y in range(height)] + [(y, width-1) for y in range(height)]:
        if empty[y, x] and not outside[y, x]:
            outside[y, x] = True
            queue.append((y, x))
    while queue:
        y, x = queue.popleft()
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                ny, nx = y+dy, x+dx
                if (0 <= ny < height and 0 <= nx < width and empty[ny, nx]
                        and not outside[ny, nx]):
                    outside[ny, nx] = True
                    queue.append((ny, nx))
    return empty & ~outside


def geometry_issues(frame: np.ndarray, reference: np.ndarray,
                    fixed: np.ndarray) -> list[dict]:
    """Porównaj bryłę i RGBA ze źródłem, a nie z potencjalnie uszkodzoną klatką 0."""
    issues = []
    changed = fixed & np.any(frame != reference, axis=2)
    if changed.any():
        ys, xs = np.nonzero(changed)
        issues.append({"kind": "fixed_region_changed", "pixels": int(changed.sum()),
                       "box": [int(xs.min()), int(ys.min()), int(xs.max()+1), int(ys.max()+1)]})
    holes = interior_mask(frame[:, :, 3])
    # Nowa luka jest twardym błędem tylko tam, gdzie źródło miało materiał.
    # Pozostałe wnętrza mogą być prawidłową przestrzenią między ramieniem a tułowiem.
    missing = holes & (reference[:, :, 3] > 0)
    if missing.any():
        ys, xs = np.nonzero(missing)
        issues.append({"kind": "interior_material_lost", "pixels": int(missing.sum()),
                       "box": [int(xs.min()), int(ys.min()), int(xs.max()+1), int(ys.max()+1)]})
    return issues


def review_strips(atlas: np.ndarray, frames: int, cell: tuple[int, int], output) -> None:
    """Wszystkie fazy: kolor, płaska sylwetka, różnica z poprzednią klatką.

    Różnice są pełnymi maskami (czerwone=ubyło, zielone=przybyło), nie tylko konturami.
    Klatka 0 jest porównana z ostatnią: pokazuje również szew pętli.
    """
    cw, ch = cell
    for row, direction in enumerate(("s", "sw", "w", "nw", "n", "ne", "e", "se")):
        sheet = Image.new("RGB", (cw*frames, (ch+20)*3), "#233339")
        draw = ImageDraw.Draw(sheet)
        for frame in range(frames):
            pixels = atlas[row*ch:(row+1)*ch, frame*cw:(frame+1)*cw]
            alpha = pixels[:, :, 3] > 0
            previous = (frame-1) % frames
            before = atlas[row*ch:(row+1)*ch, previous*cw:(previous+1)*cw, 3] > 0
            color = Image.fromarray(pixels)
            silhouette = np.zeros_like(pixels)
            silhouette[alpha] = [230, 230, 230, 255]
            onion = np.zeros_like(pixels)
            onion[before & alpha] = [120, 130, 135, 255]
            onion[before & ~alpha] = [235, 80, 70, 255]
            onion[~before & alpha] = [70, 220, 130, 255]
            for band, tile in enumerate((color, Image.fromarray(silhouette), Image.fromarray(onion))):
                x, y = frame*cw, band*(ch+20)
                sheet.paste(tile, (x, y), tile)
                draw.text((x+2, y+ch+2), f"{direction} #{frame} " + ("RGB", "ALPHA", "PREV->NOW")[band], fill="white")
        sheet.save(output / f"{direction}.png")
