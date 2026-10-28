"""Teren w rzucie 2:1: warstwy materiałów zamiast szumu prostokątnych plamek."""
from __future__ import annotations

import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

TERRAIN_COLORS = {
    "soil": ["151915", "1a1d18", "1e211b", "23251f", "282922", "2d2e26", "33322a", "38372d",
             "3e3b31", "434034", "494538", "4e4a3c", "544f40", "595444", "5f5948", "645e4c"],
    "moss": ["141d18", "19231c", "1f2920", "252f25", "2b3529", "313b2e", "374132", "3d4737",
             "434d3b", "49533f", "4f5944", "555f48"],
    "water": ["111d22", "19292e", "26393e", "3b5054", "53686a"],
    "stone": ["232b29", "303a34", "3c463d", "4b5549", "606958"],
    "leaf": ["24291f", "303421", "3b3d28", "4a4930", "565135"]
}


def sample_material(u: np.ndarray, v: np.ndarray, name: str) -> np.ndarray:
    """Próbka istniejącego kafla: stała skala świata i warianty, bez perspektywy zbieżnej."""
    source = Path(__file__).resolve().parents[1] / "art-src" / name
    tiles = [np.asarray(Image.open(source / f"{i:02d}.png").convert("RGB").filter(ImageFilter.MedianFilter(3)))
             for i in range(1, 4)]
    scale = 192.0
    fu, fv = .02+.96*((u/scale) % 1), .02+.96*((v/scale) % 1)
    px = np.clip(((fu-fv)*256+256).astype(int), 0, 511)
    py = np.clip(((fu+fv)*128).astype(int), 0, 255)
    tile = ((np.floor(u/scale).astype(int)*5 + np.floor(v/scale).astype(int)*7) % 3)
    result = np.zeros((*u.shape, 3), dtype=np.float32)
    for i, image in enumerate(tiles):
        mask = tile == i
        result[mask] = image[py[mask], px[mask]]
    return result


def iso(u: float, v: float, height: float = 0) -> tuple[float, float]:
    return u-v, (u+v)*.5-height


def noise(u: np.ndarray, v: np.ndarray, scale: float, seed: int) -> np.ndarray:
    """Gładkie pole na płaszczyźnie świata; izometria pojawia się przy próbkowaniu."""
    x, y = u/scale, v/scale
    ix, iy = np.floor(x).astype(np.int32), np.floor(y).astype(np.int32)
    tx, ty = x-ix, y-iy
    tx, ty = tx*tx*(3-2*tx), ty*ty*(3-2*ty)
    def corner(dx, dy):
        h = ((ix+dx).astype(np.uint32)*np.uint32(374761393)
             + (iy+dy).astype(np.uint32)*np.uint32(668265263) + np.uint32(seed))
        h = (h ^ (h >> 13))*np.uint32(1274126177)
        return ((h ^ (h >> 16)) & 65535).astype(np.float32)/65535
    a, b, c, d = corner(0, 0), corner(1, 0), corner(0, 1), corner(1, 1)
    return (a*(1-tx)+b*tx)*(1-ty)+(c*(1-tx)+d*tx)*ty


def make_ground(profile: dict, size: tuple[int, int] = (2560, 1536)) -> Image.Image:
    width, height = size
    seed = profile["seed"]
    y, x = np.mgrid[:height, :width].astype(np.float32)
    sx, sy = x-width/2, y-height/2
    u, v = sy+sx*.5, sy-sx*.5
    broad = noise(u, v, 160, seed)
    medium = noise(u, v, 36, seed+3)
    fine = noise(u, v, 6, seed+7)
    center = 50*np.sin(v/400) + 15*np.sin(v/135)
    edge = np.abs(u-center) - (115 + 14*(broad-.5))
    on_path = edge < 0
    tonal = broad*.5 + medium*.36 + fine*.14
    # Orne koleiny tego samego traktu; woda i mokre błoto mają własne wartości.
    rut = np.minimum(np.abs(u-center-38), np.abs(u-center+38)) < 4+medium*4
    leaves = sample_material(u, v, "TILE-sciolka")
    mud = sample_material(u, v, "TILE-bloto")
    path_mix = np.clip((10-edge)/20, 0, 1)[:, :, None]
    material = leaves*(1-path_mix) + mud*path_mix
    material *= np.array([.58, .62, .57], dtype=np.float32)
    material *= (.80 + broad*.25 + fine*.07 - rut*.14)[:, :, None]
    # Mech jest warstwą materiału o podobnej jasności, nie zielonymi wyspami z twardym obrysem.
    moss_mix = np.clip((medium*.7+broad*.3-.53)*2.5, 0, .35)*(1-path_mix[:, :, 0])
    moss_luma = material.mean(axis=2)
    moss_color = np.stack((moss_luma*.80, moss_luma*1.04, moss_luma*.78), axis=2)
    material = material*(1-moss_mix[:, :, None]) + moss_color*moss_mix[:, :, None]
    pal = Image.new("P", (1, 1))
    colors = [tuple(bytes.fromhex(c)) for group in TERRAIN_COLORS.values() for c in group]
    pal.putpalette([v for c in colors+[colors[-1]]*(256-len(colors)) for v in c])
    im = Image.fromarray(np.clip(material, 0, 255).astype(np.uint8)).quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
    draw = ImageDraw.Draw(im)
    rng = random.Random(seed)
    def point(a, b, z=0):
        px, py = iso(a, b, z)
        return round(px+width/2), round(py+height/2)
    # Kompozycja kałuż wzdłuż traktu. Obrysy w świecie, wszystkie w tym samym rzucie.
    for vv, side, length in [(-700, -38, 75), (-360, 38, 54), (-100, -38, 83),
                              (180, 38, 64), (430, -38, 92), (760, 38, 57)]:
        uu = 50*math.sin(vv/400) + 15*math.sin(vv/135) + side
        contour = []
        for j in range(24):
            angle = j*math.tau/24
            wobble = rng.uniform(.8, 1.15)
            contour.append(point(uu+math.cos(angle)*12*wobble,
                                 vv+math.sin(angle)*length*wobble))
        draw.polygon(contour, fill="#111d22")
        inner = [point(uu+math.cos(j*math.tau/24)*8,
                       vv+math.sin(j*math.tau/24)*length*.82) for j in range(24)]
        draw.polygon(inner, fill="#19292e")
        # Stojące odbicia mają poziomy kierunek ekranu, brzeg leży w płaszczyźnie świata.
        for _ in range(9):
            px, py = point(uu+rng.uniform(-5, 5), vv+rng.uniform(-length*.7, length*.7))
            draw.line((px-2, py, px+rng.randrange(3, 11), py), fill="#26393e")
    # Grupki ściółki, nie równomierna posypka. Cienkie krawędzie, ciche tony.
    for _ in range(14000):
        uu, vv = rng.uniform(-1400, 1400), rng.uniform(-1400, 1400)
        road_center = 50*math.sin(vv/400)+15*math.sin(vv/135)
        if abs(uu-road_center) < 130 and rng.random() < .92:
            continue
        for _ in range(rng.randrange(2, 6)):
            a, b = uu+rng.gauss(0, 7), vv+rng.gauss(0, 7)
            r = rng.uniform(1, 3)
            poly = [point(a-r, b), point(a, b-r*.5), point(a+r, b), point(a, b+r*.5)]
            draw.polygon(poly, fill="#"+rng.choice(TERRAIN_COLORS["leaf"][:4]))
    for _ in range(950):
        a, b = rng.uniform(-1400, 1400), rng.uniform(-1400, 1400)
        r = rng.uniform(1.5, 5.0)
        poly = [point(a+math.cos(j*math.tau/8)*r, b+math.sin(j*math.tau/8)*r) for j in range(8)]
        draw.polygon(poly, fill="#232b29")
        draw.line(poly[:4], fill="#3c463d", width=1)
    return im


def projection_guide(ground: Image.Image) -> Image.Image:
    im = ground.copy()
    draw = ImageDraw.Draw(im)
    for k in range(-6, 7):
        for u0, v0, u1, v1 in [(k*128, -1000, k*128, 1000), (-1000, k*128, 1000, k*128)]:
            x0, y0 = iso(u0, v0)
            x1, y1 = iso(u1, v1)
            draw.line((x0+im.width/2, y0+im.height/2, x1+im.width/2, y1+im.height/2),
                      fill="#87968b", width=1)
    return im
