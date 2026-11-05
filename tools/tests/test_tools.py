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
from validate_asset import _check_jitter, validate  # noqa: E402
from welesza_assets import ground_point, to_rgba  # noqa: E402


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

    def test_build_rejects_path_instead_of_id(self) -> None:
        asset_dir = self.src / "TEST-manekin"
        self.assertFalse(build(str(asset_dir), self.src, self.out))
        self.assertTrue((asset_dir / "asset.json").exists(), "źródła nietknięte")

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


class MagentaKeyTest(unittest.TestCase):
    def test_opaque_pink_fringe_is_cleaned_but_inner_purple_stays(self) -> None:
        img = np.zeros((64, 64, 3), dtype=np.uint8)
        img[...] = (255, 0, 255)  # tło
        img[16:48, 16:48] = (150, 40, 140)  # kryjąca obwódka zmieszana z magentą
        img[20:44, 20:44] = (60, 120, 40)  # liście
        img[30:34, 30:34] = (150, 40, 140)  # fiolet w środku obrazu
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "fringe.png"
            Image.fromarray(img).save(path)
            out = to_rgba(path, "magenta")
        ring = out[17, 17]
        self.assertEqual(ring[3], 255, "obwódka zostaje kryjąca")
        self.assertLess(min(ring[0], ring[2]) - ring[1], 10, "bez różowej poświaty na obwódce")
        self.assertEqual(tuple(out[31, 31, :3]), (150.0, 40.0, 140.0), "fiolet w środku nietknięty")
        self.assertEqual(out[2, 2, 3], 0, "tło przezroczyste")

    def test_transparent_source_with_leftover_fringe_is_cleaned(self) -> None:
        img = np.zeros((64, 64, 4), dtype=np.uint8)
        img[16:48, 16:48] = (150, 40, 140, 255)  # resztka po ręcznym wycięciu magenty
        img[20:44, 20:44] = (60, 120, 40, 255)
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "cut.png"
            Image.fromarray(img).save(path)
            out = to_rgba(path, "transparent")
        ring = out[17, 17]
        self.assertLess(min(ring[0], ring[2]) - ring[1], 10, "bez różowej poświaty")
        self.assertEqual(tuple(out[30, 30, :3]), (60.0, 120.0, 40.0), "środek nietknięty")


class JitterTest(unittest.TestCase):
    META = {"canvas": [512, 512], "animations": {"walk": {"loop": True}}}

    def _warnings(self, heads: list[float]) -> list[str]:
        from welesza_assets import Report
        rep = Report()
        _check_jitter(Path("walk/s.png"), heads, self.META, "walk", rep)
        return rep.warnings

    def test_smooth_walk_passes(self) -> None:
        self.assertEqual(self._warnings([250, 252, 254, 255, 254, 252, 250, 249]), [])

    def test_jumping_head_warns(self) -> None:
        self.assertTrue(self._warnings([234, 276, 309, 244, 275, 301, 274, 241]))

    def test_loop_wrap_is_checked(self) -> None:
        self.assertTrue(self._warnings([250, 255, 260, 265, 270, 275, 280, 285]))

