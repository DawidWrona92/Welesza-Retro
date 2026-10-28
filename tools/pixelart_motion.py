"""Jawny chód 2D: teksturowane wycinki kończyn i stały wzorzec korpusu.

Współrzędne są w natywnych pikselach: (przód, bok, wysokość), rzut podłoża 2:1.
Bez proceduralnego zastępowania anatomii i bez usuwania fragmentów korpusu.
"""
from __future__ import annotations

import math

import numpy as np
from PIL import Image, ImageDraw

DIRECTIONS = ("s", "sw", "w", "nw", "n", "ne", "e", "se")


def foot_path(phase: float, stride: float, support: float, lift: float) -> tuple[float, float, bool]:
    """W podparciu stopa cofa się ze stałą prędkością względem idącego korpusu."""
    p = phase % 1.0
    reach = stride * support / 2.0
    if p < support:
        return reach - stride*p, 0.0, True
    t = (p - support) / (1.0 - support)
    # Powrót: monotoniczny łuk; kontakt nie zależy od losowania pozy klatki.
    smooth = t*t*(3.0 - 2.0*t)
    return -reach + 2.0*reach*smooth, lift*math.sin(math.pi*t), False


def project_pose(forward: float, lateral: float, height: float, direction: int,
                 anchor: tuple[float, float]) -> tuple[int, int]:
    angle = direction * math.pi / 4.0
    fx, fy = -math.sin(angle), math.cos(angle)
    rx, ry = fy, -fx
    return (round(anchor[0] + fx*forward + rx*lateral),
            round(anchor[1] + (fy*forward + ry*lateral)*.5 - height))


def deform_cutout(cutout: Image.Image, dx: float, dy: float) -> Image.Image:
    """Odkształć wyłącznie wyciętą nogę, mocując górny szew; próbkuj nearest.

    Odwracalne mapowanie wierszy zachowuje teksturę i nie dokleja nowej anatomii.
    Dolna ćwiartka (but/łapa) przesuwa się sztywno, szew pozostaje nieruchomy.
    """
    box = cutout.getbbox()
    if box is None:
        raise ValueError("Pusta maska kończyny")
    top, bottom = box[1], box[3] - 1
    span = max(1, bottom - top)
    if abs(dy) > span * .45 or abs(dx) > span * .85:
        raise ValueError(f"Deformacja przekracza bezpieczny zakres kończyny: {dx=}, {dy=}, {span=}")
    rows = np.arange(cutout.height, dtype=float)
    weight = np.clip((rows - top) / max(1, span * .75), 0, 1)
    weight = weight * weight * (3 - 2 * weight)
    source = np.asarray(cutout)
    sy, sx = np.nonzero(source[:, :, 3])
    tx, ty = sx + weight[sy] * dx, sy + weight[sy] * dy
    if (tx.min() < 0 or tx.max() > cutout.width - 1 or
            ty.min() < 0 or ty.max() > cutout.height - 1):
        raise ValueError("Deformacja obcięłaby kończynę na krawędzi płótna")
    target_y = rows + weight * dy
    if np.any(np.diff(target_y) <= 0):
        raise ValueError("Deformacja zawija siatkę kończyny")
    source_y = np.interp(rows, target_y, rows)
    shift_x = np.interp(source_y, rows, weight) * dx
    yy = np.broadcast_to(np.rint(source_y).astype(int)[:, None],
                         (cutout.height, cutout.width))
    xx = np.rint(np.arange(cutout.width)[None, :] - shift_x[:, None]).astype(int)
    valid = (xx >= 0) & (xx < cutout.width) & (yy >= 0) & (yy < cutout.height)
    data = np.zeros((cutout.height, cutout.width, 4), dtype=np.uint8)
    data[valid] = source[yy[valid], xx[valid]]
    return Image.fromarray(data)


def rig_walk(reference: Image.Image, rig: dict, frames: int, step: int = 2) -> tuple[Image.Image, dict]:
    """Chód z teksturowanych wycinków jednej pozy, bez zastępowania nóg wielokątami.

    Maski i amplitudy są w jawnej siatce 128 px. Inna siatka wymaga osobnego rigu.
    """
    if step != 2:
        raise ValueError("Rig wycinkowy wymaga pixel_size=2; przygotuj osobny rig dla innej siatki")
    size = 128
    sheet = Image.new("RGBA", (size * frames, size * 8))
    telemetry = {"mode": "textured_cutouts", "cycle_distance": rig["cycle_distance"],
                 "frames": frames, "directions": {}}
    for row, direction in enumerate(DIRECTIONS):
        base = reference.crop((0, row*size, size, (row+1)*size)).convert("RGBA")
        original = np.array(base)
        masks = []
        for polygon in rig["erase_legs"][direction]:
            mask = Image.new("L", base.size)
            ImageDraw.Draw(mask).polygon([tuple(p) for p in polygon], fill=255)
            masks.append(np.asarray(mask) > 0)
        # Wycinaj całe spójne fragmenty, nigdy połowy buta według mediany X.
        occupied = np.logical_or.reduce(masks) & (original[:, :, 3] > 0)
        for polygon in rig.get("protect", {}).get(direction, []):
            mask = Image.new("L", base.size)
            ImageDraw.Draw(mask).polygon([tuple(p) for p in polygon], fill=255)
            occupied &= np.asarray(mask) == 0
        # W widokach z przodu osobne maski rozdzielają nogi także wtedy, gdy
        # stykają się pikselem przy biodrach. Złączone maski nie mogą zsynchronizować nóg.
        owners = np.zeros_like(occupied, dtype=int)
        if rig.get("kind") == "biped" and direction in ("s", "sw", "se"):
            for index, mask in enumerate(masks):
                owners[mask] = index + 1
        seen = np.zeros_like(occupied)
        parts = []
        claimed = np.zeros_like(occupied)
        for y, x in zip(*np.nonzero(occupied)):
            if seen[y, x]:
                continue
            stack, points = [(int(y), int(x))], []
            seen[y, x] = True
            while stack:
                py, px = stack.pop()
                points.append((py, px))
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        ny, nx = py + dy, px + dx
                        if (0 <= ny < size and 0 <= nx < size and occupied[ny, nx]
                                and not seen[ny, nx] and owners[ny, nx] == owners[py, px]):
                            seen[ny, nx] = True
                            stack.append((ny, nx))
            ys, xs = zip(*points)
            if len(points) < 12 or max(ys) - min(ys) < 8:
                continue  # mały detal zostaje w korpusie, nie znika z obrazu
            mask = np.zeros_like(occupied)
            mask[ys, xs] = True
            pixels = np.zeros_like(original)
            pixels[mask] = original[mask]
            claimed |= mask
            parts.append(Image.fromarray(pixels))
        if not parts:
            raise ValueError(f"Brak wyciętych kończyn: {direction}")
        parts.sort(key=lambda part: part.getbbox()[0])
        body = original.copy()
        body[claimed] = 0
        body = Image.fromarray(body)
        frame_data = []
        for frame in range(frames):
            # Pierwszy kontakt wypada na klatce 1, zgodnie z asset.json.
            phase = (frame - 1) / frames
            image = Image.new("RGBA", base.size)
            poses = []
            for index, part in enumerate(parts):
                fore, lift, support = foot_path(phase + index * .5,
                                                rig["cycle_distance"] / step,
                                                rig["support"], rig["lift"])
                dx, dy = project_pose(fore, 0, lift, row, (0, 0))
                moved = deform_cutout(part, dx, dy)
                image.alpha_composite(moved)
                poses.append({"part": index, "support": support, "forward": fore,
                              "lift": lift, "offset": [dx, dy], "source_box": list(part.getbbox())})
            # Korpus pozostaje identyczny i zasłania szwy, nie usuwamy jego fragmentów heurystycznie.
            image.alpha_composite(body)
            if image.getbbox() is None:
                raise ValueError("Pusta klatka rigu")
            sheet.alpha_composite(image, (frame*size, row*size))
            frame_data.append({"frame": frame, "parts": poses})
        telemetry["directions"][direction] = frame_data
    return sheet, telemetry
