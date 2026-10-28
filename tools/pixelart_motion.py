"""Jawny chód 2D: podparcie stóp, dwuczłonowe nogi, stały wzorzec korpusu.

Współrzędne są w natywnych pikselach: (przód, bok, wysokość), rzut podłoża 2:1.
Żadnego wyrównywania całej klatki względem głowy ani generowania nowej anatomii.
"""
from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

DIRECTIONS = ("s", "sw", "w", "nw", "n", "ne", "e", "se")


def connected_body(image: Image.Image) -> Image.Image:
    """Pozostaw główną sylwetkę po odjęciu starych nóg, bez wiszących skrawków butów."""
    data = np.array(image)
    occupied = data[:, :, 3] > 0
    seen = np.zeros_like(occupied)
    biggest = []
    for y, x in zip(*np.nonzero(occupied)):
        if seen[y, x]:
            continue
        component, stack = [], [(int(y), int(x))]
        seen[y, x] = True
        while stack:
            py, px = stack.pop()
            component.append((py, px))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = py+dy, px+dx
                    if 0 <= ny < image.height and 0 <= nx < image.width and occupied[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
        if len(component) > len(biggest):
            biggest = component
    keep = np.zeros_like(occupied)
    for y, x in biggest:
        keep[y, x] = True
    data[~keep] = 0
    return Image.fromarray(data)


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


def knee_point(hip: tuple[float, float], foot: tuple[float, float], upper: float,
               lower: float, bend: float = 1.0) -> tuple[float, float]:
    delta = np.array(foot, dtype=float) - hip
    distance = float(np.linalg.norm(delta))
    if distance > upper + lower + 0.001 or distance < abs(upper-lower) - .001:
        raise ValueError(f"Nieosiągalna pozycja nogi: {distance:.2f}, długości {upper}/{lower}")
    unit = delta / max(distance, .001)
    along = (upper*upper - lower*lower + distance*distance) / max(2*distance, .001)
    side = math.sqrt(max(0.0, upper*upper - along*along))
    point = np.array(hip) + unit*along + np.array([-unit[1], unit[0]])*side*bend
    return float(point[0]), float(point[1])


def project_pose(forward: float, lateral: float, height: float, direction: int,
                 anchor: tuple[float, float]) -> tuple[int, int]:
    angle = direction * math.pi / 4.0
    fx, fy = -math.sin(angle), math.cos(angle)
    rx, ry = fy, -fx
    return (round(anchor[0] + fx*forward + rx*lateral),
            round(anchor[1] + (fy*forward + ry*lateral)*.5 - height))


def _limb(draw: ImageDraw.ImageDraw, a: tuple, b: tuple, width: float, colors: tuple) -> None:
    dx, dy = b[0]-a[0], b[1]-a[1]
    length = max(1.0, math.hypot(dx, dy))
    nx, ny = -dy/length*width, dx/length*width
    points = [(round(a[0]+nx), round(a[1]+ny)), (round(b[0]+nx*.7), round(b[1]+ny*.7)),
              (round(b[0]-nx*.7), round(b[1]-ny*.7)), (round(a[0]-nx), round(a[1]-ny))]
    draw.polygon(points, fill=colors[0])
    draw.line((a, b), fill=colors[1], width=max(1, round(width)))
    draw.line((points[0], points[1]), fill=colors[2], width=1)


def rig_walk(reference: Image.Image, rig: dict, frames: int, step: int = 2) -> tuple[Image.Image, dict]:
    """Każdy kierunek korzysta z jednego wzorca korpusu; nie z 12 innych twarzy."""
    size = 256 // step
    sheet = Image.new("RGBA", (size*frames, size*8))
    telemetry = {"cycle_distance": rig["cycle_distance"], "frames": frames, "directions": {}}
    human = rig["kind"] == "biped"
    for row, direction in enumerate(DIRECTIONS):
        base = reference.crop((0, row*size, size, (row+1)*size)).convert("RGBA")
        original = np.array(base)
        erase = ImageDraw.Draw(base)
        for polygon in rig["erase_legs"][direction]:
            erase.polygon([tuple(p) for p in polygon], fill=(0, 0, 0, 0))
        if human:
            # Miecz schodzi obok nóg; maska nóg nie może przeciąć stalowej klingi.
            data = np.array(base)
            steel = np.zeros((size, size), dtype=bool)
            for color in ("616b6c", "87918b", "b1b9ab", "bbc0a4"):
                steel |= np.all(original[:, :, :3] == np.array(tuple(bytes.fromhex(color))), axis=2)
            data[steel] = original[steel]
            base = Image.fromarray(data)
        base = connected_body(base)
        frame_data = []
        for frame in range(frames):
            phase = frame / frames
            bob = round(-rig["bob"] * (math.sin(2*math.pi*phase)**2))
            image = Image.new("RGBA", (size, size))
            legs, poses = [], []
            for leg in rig["legs"]:
                fore, lift, support = foot_path(phase+leg["phase"], rig["cycle_distance"]/step,
                                                rig["support"], rig["lift"])
                origin = leg.get("forward", 0.0)
                hip = (origin, rig["hip_height"] - bob)
                foot = (origin+fore, lift)
                knee = knee_point(hip, foot, rig["upper"], rig["lower"], leg.get("bend", 1))
                lateral = leg["lateral"]
                anchor = tuple(rig["anchors"].get(direction, rig["anchor"]))
                a = project_pose(hip[0], lateral, hip[1], row, anchor)
                b = project_pose(knee[0], lateral, knee[1], row, anchor)
                c = project_pose(foot[0], lateral, foot[1], row, anchor)
                toe = project_pose(foot[0]+rig["toe"], lateral, foot[1], row, anchor)
                legs.append((c[1], a, b, c, toe))
                poses.append({"leg": leg["name"], "support": support, "forward": round(fore, 4),
                              "lift": round(lift, 4), "foot": list(c), "hip": list(a), "knee": list(b)})
            # Dalekie nogi za korpusem, bliskie przed dalekimi. Korpus zasłania szwy bioder.
            for _, a, b, c, toe in sorted(legs):
                draw = ImageDraw.Draw(image)
                _limb(draw, a, b, 3.3 if human else 1.9, ("#352a24", "#49382a", "#604833"))
                _limb(draw, b, c, 2.8 if human else 1.4, ("#241e1d", "#352a24", "#604833"))
                _limb(draw, c, toe, 2.0 if human else 1.1, ("#241e1d", "#49382a", "#604833"))
                if human:
                    for t in (.28, .5, .72):
                        x, y = round(b[0]+(c[0]-b[0])*t), round(b[1]+(c[1]-b[1])*t)
                        draw.line((x-1, y, x+1, y), fill="#7c5b3c")
            image.alpha_composite(base, (0, bob))
            sheet.alpha_composite(image, (frame*size, row*size))
            frame_data.append({"frame": frame, "bob": bob, "legs": poses})
        telemetry["directions"][direction] = frame_data
    return sheet, telemetry
