"""Szablony dla grafika (T05): art-src/_templates/.

- strip_<n>.png: pasek n klatek 512x512 na tle magenta z linią ziemi, kotwicą i linią wzrostu bohatera.
- directions.png: kolejność 8 kierunków (s, sw, w, nw, n, ne, e, se) jako strzałki na ziemi.
- tile_iso.png: romb kafla 512x256.

Szablon jest przewodnikiem układu. W gotowych klatkach nie może być linii ani znaków z szablonu.
"""

from __future__ import annotations

import math

from PIL import Image, ImageDraw

from welesza_assets import ART_SRC, DIRECTIONS

CELL = 512
ANCHOR = (256, 448)
HERO_HEIGHT = 320      # wysokość bohatera w płótnie 2x (160 px w grze)
DOG_SHOULDER = 110     # wysokość psa w kłębie
BG = (255, 0, 255, 255)
LINE = (60, 0, 60, 255)
GUIDE = (150, 60, 150, 255)
STRIP_SIZES = (1, 3, 4, 6, 7, 8, 9)

# kąt strzałki na ekranie dla kierunku (0 = w dół ekranu, ku kamerze), zgodnie z ruchem wskazówek
ANGLES = {d: i * 45 for i, d in enumerate(DIRECTIONS)}


def _cell(draw: ImageDraw.ImageDraw, x0: int) -> None:
    draw.rectangle([x0, 0, x0 + CELL - 1, CELL - 1], outline=LINE, width=2)
    gy = ANCHOR[1]
    draw.line([x0 + 16, gy, x0 + CELL - 16, gy], fill=LINE, width=2)
    ax = x0 + ANCHOR[0]
    draw.line([ax - 12, gy, ax + 12, gy], fill=(0, 0, 0, 255), width=4)
    draw.line([ax, gy - 12, ax, gy + 12], fill=(0, 0, 0, 255), width=4)
    for y, dash in ((gy - HERO_HEIGHT, 12), (gy - DOG_SHOULDER, 6)):
        for x in range(x0 + 16, x0 + CELL - 16, dash * 2):
            draw.line([x, y, x + dash, y], fill=GUIDE, width=1)


def strip(n: int) -> Image.Image:
    img = Image.new("RGBA", (CELL * n, CELL), BG)
    draw = ImageDraw.Draw(img)
    for i in range(n):
        _cell(draw, i * CELL)
    return img


def directions() -> Image.Image:
    img = Image.new("RGBA", (CELL * 8, CELL), BG)
    draw = ImageDraw.Draw(img)
    for i, d in enumerate(DIRECTIONS):
        x0 = i * CELL
        _cell(draw, x0)
        ax, ay = x0 + ANCHOR[0], ANCHOR[1]
        # strzałka w rzucie izometrycznym 2:1: składowa pionowa skrócona o połowę
        a = math.radians(ANGLES[d])
        dx, dy = -math.sin(a) * 100, math.cos(a) * 50
        draw.line([ax, ay, ax + dx, ay + dy], fill=(0, 0, 0, 255), width=6)
        draw.ellipse([ax + dx - 10, ay + dy - 10, ax + dx + 10, ay + dy + 10], fill=(0, 0, 0, 255))
        draw.text((x0 + 20, 20), d.upper(), fill=(0, 0, 0, 255))
    return img


def tile() -> Image.Image:
    img = Image.new("RGBA", (512, 256), BG)
    ImageDraw.Draw(img).polygon([(256, 0), (511, 128), (256, 255), (0, 128)], outline=LINE, width=2)
    return img


def main() -> None:
    out = ART_SRC / "_templates"
    out.mkdir(parents=True, exist_ok=True)
    for n in STRIP_SIZES:
        strip(n).save(out / f"strip_{n}.png", optimize=True)
    directions().save(out / "directions.png", optimize=True)
    tile().save(out / "tile_iso.png", optimize=True)
    print(f"Szablony zapisane w {out}")


if __name__ == "__main__":
    main()
