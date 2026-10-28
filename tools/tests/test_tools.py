"""Testy walidatora i pipeline'u sprite'ów. Uruchom: python3 -m unittest discover tools/tests"""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import make_test_asset  # noqa: E402
from sprite_pipeline import build  # noqa: E402
from validate_asset import validate  # noqa: E402
from welesza_assets import ground_point  # noqa: E402


class PipelineTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.src = Path(self.tmp.name) / "art-src"
        self.out = Path(self.tmp.name) / "assets"
        self.asset = make_test_asset.main(self.src)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_valid_asset_passes(self) -> None:
        rep = validate(self.asset)
        self.assertTrue(rep.ok, rep.errors)

    def test_missing_strip_is_error(self) -> None:
        (self.asset / "walk" / "n.png").unlink()
        self.assertFalse(validate(self.asset).ok)

    def test_wrong_strip_size_is_error(self) -> None:
        Image.new("RGBA", (100, 100)).save(self.asset / "idle" / "s.png")
        self.assertFalse(validate(self.asset).ok)

    def test_event_out_of_range_is_error(self) -> None:
        meta = json.loads((self.asset / "asset.json").read_text())
        meta["animations"]["attack"]["events"].append({"frame": 9, "name": "hit_end"})
        (self.asset / "asset.json").write_text(json.dumps(meta))
        self.assertFalse(validate(self.asset).ok)

    def test_build_aligns_mirrors_and_writes_godot_resources(self) -> None:
        self.assertTrue(build("TEST-manekin", self.src, self.out))
        out = self.out / "TEST-manekin"
        meta = json.loads((out / "meta.json").read_text())
        self.assertEqual(meta["cell"], [256, 256])
        self.assertEqual(meta["anchor"], [128.0, 224.0])
        sheet = np.asarray(Image.open(out / "walk.png"), dtype=np.float32)
        self.assertEqual(sheet.shape[:2], (256 * 8, 256 * 4))
        # każdy kierunek po wyrównaniu stoi na kotwicy (tolerancja 2 px po zmniejszeniu)
        for row in range(8):
            fr = sheet[row * 256:(row + 1) * 256, 0:256]
            gx, gy = ground_point(fr)
            self.assertAlmostEqual(gy, 224, delta=2, msg=f"wiersz {row}")
            self.assertAlmostEqual(gx, 128, delta=3, msg=f"wiersz {row}")
        # odbity kierunek e (wiersz 6) jest lustrem w (wiersz 2)
        w_row = sheet[2 * 256:3 * 256, 0:256, 3]
        e_row = sheet[6 * 256:7 * 256, 0:256, 3]
        self.assertGreater(np.mean(np.abs(w_row - e_row)), 1.0)
        tres = (out / "sprite_frames.tres").read_text()
        for name in ("walk_s", "walk_e", "attack_ne", "idle_n"):
            self.assertIn(f'&"{name}"', tres)
        self.assertEqual(meta["animations"]["attack"]["events"][0], {"frame": 1, "name": "hit_start"})


if __name__ == "__main__":
    unittest.main()
