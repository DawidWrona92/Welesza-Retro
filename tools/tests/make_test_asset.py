"""Generuje syntetyczny asset art-src/TEST-manekin/ do testów pipeline'u i gry.

Figura z prostych kształtów na tle magenta, celowo przesunięta względem kotwicy, żeby test sprawdzał
wyrównanie. Pięć kierunków malowanych, trzy odbite.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from welesza_assets import ART_SRC  # noqa: E402

ID = "TEST-manekin"
CELL = 512
PAINTED = ["s", "sw", "w", "nw", "n"]
ANIMS = {
    "idle": {"frames": 2, "fps": 6, "loop": True},
    "walk": {"frames": 4, "fps": 12, "loop": True,
             "events": [{"frame": 1, "name": "step"}, {"frame": 3, "name": "step"}]},
    "attack": {"frames": 3, "fps": 12, "loop": False,
               "events": [{"frame": 1, "name": "hit_start"}, {"frame": 2, "name": "hit_end"},
                          {"frame": 2, "name": "combo_open"}]},
}
OFFSET = (10, -8)  # celowe przesunięcie styku z ziemią względem kotwicy (256, 448)


def figure(draw: ImageDraw.ImageDraw, x0: int, frame: int, direction_index: int) -> None:
    cx, gy = x0 + 256 + OFFSET[0], 448 + OFFSET[1]
    lean = (frame % 2) * 6
    draw.rectangle([cx - 30 + lean, gy - 250, cx + 30 + lean, gy - 60], fill=(90, 70, 50, 255))
    draw.ellipse([cx - 26 + lean, gy - 320, cx + 26 + lean, gy - 260], fill=(200, 170, 140, 255))
    draw.rectangle([cx - 28, gy - 60, cx - 8, gy], fill=(60, 45, 35, 255))
    draw.rectangle([cx + 8, gy - 60, cx + 28, gy], fill=(60, 45, 35, 255))
    # znacznik kierunku: asymetria, żeby odbicie było widoczne
    draw.rectangle([cx + 30 + lean, gy - 200 + direction_index * 10, cx + 60 + lean, gy - 180 + direction_index * 10],
                   fill=(180, 180, 190, 255))


def main(root: Path = ART_SRC) -> Path:
    out = root / ID
    out.mkdir(parents=True, exist_ok=True)
    for anim, spec in ANIMS.items():
        (out / anim).mkdir(exist_ok=True)
        for di, d in enumerate(PAINTED):
            img = Image.new("RGBA", (CELL * spec["frames"], CELL), (255, 0, 255, 255))
            draw = ImageDraw.Draw(img)
            for i in range(spec["frames"]):
                figure(draw, i * CELL, i, di)
            img.save(out / anim / f"{d}.png", optimize=True)
    meta = {
        "schema": "welesza.asset.v1",
        "id": ID,
        "kind": "character",
        "canvas": [CELL, CELL],
        "anchor": [256, 448],
        "status": "test",
        "source": "tools/tests/make_test_asset.py",
        "background": "magenta",
        "directions": PAINTED,
        "mirror": {"se": "sw", "e": "w", "ne": "nw"},
        "layers": ["full"],
        "animations": ANIMS,
        "collision": {"circle": 36},
    }
    (out / "asset.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return out


if __name__ == "__main__":
    print(main())
