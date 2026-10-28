"""Kontrakt pixel artu: paleta, alfa, brak losowości i trwałe poprawki."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from pixelart_generator import PROFILE, apply_override, pixelate, stabilize_walk
from check_pixelart import frame_issues


class PixelArtTest(unittest.TestCase):
    def setUp(self):
        self.profile = json.loads(PROFILE.read_text())
        rng = np.random.default_rng(42)
        self.source = Image.fromarray(rng.integers(0, 256, (64, 64, 4), dtype=np.uint8))

    def test_output_has_only_shared_palette_and_binary_alpha(self):
        result = np.asarray(pixelate(self.source, self.profile))
        allowed = {tuple(bytes.fromhex(c)) for c in self.profile["palette"]}
        visible = result[result[:, :, 3] == 255]
        self.assertGreater(len(visible), 0)
        self.assertTrue({tuple(p[:3]) for p in visible} <= allowed)
        self.assertTrue(set(np.unique(result[:, :, 3])) <= {0, 255})

    def test_identical_input_is_byte_identical(self):
        self.assertEqual(pixelate(self.source, self.profile).tobytes(),
                         pixelate(self.source, self.profile).tobytes())

    def test_transparent_color_does_not_bleed_into_silhouette(self):
        a = Image.new("RGBA", (8, 8), (255, 0, 255, 0))
        b = Image.new("RGBA", (8, 8), (0, 255, 0, 0))
        for image in (a, b):
            image.paste((160, 100, 60, 255), (2, 2, 6, 6))
        self.assertEqual(pixelate(a, self.profile).tobytes(), pixelate(b, self.profile).tobytes())

    def test_hand_pixel_survives_rebuild_and_can_be_erased(self):
        with tempfile.TemporaryDirectory() as tmp:
            patch_path = Path(tmp) / "walk.png"
            patch = Image.new("RGBA", (32, 32))
            color = tuple(bytes.fromhex(self.profile["palette"][-1])) + (255,)
            patch.putpixel((10, 11), color)
            patch.save(patch_path)
            for _ in range(2):
                base = pixelate(self.source, self.profile)
                result = apply_override(base, patch_path, self.profile["palette"])
                self.assertEqual(result.getpixel((10, 11)), color)
            mask = Image.new("L", (32, 32))
            mask.putpixel((10, 11), 255)
            mask.save(patch_path.with_suffix(".erase.png"))
            self.assertEqual(apply_override(base, patch_path, self.profile["palette"]).getpixel((10, 11)),
                             (0, 0, 0, 0))

    def test_bad_override_and_fractional_grid_are_rejected(self):
        with self.assertRaises(ValueError):
            pixelate(Image.new("RGBA", (31, 31)), self.profile)
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "walk.png"
            Image.new("RGBA", (32, 32), (255, 0, 255, 255)).save(path)
            with self.assertRaises(ValueError):
                apply_override(Image.new("RGBA", (32, 32)), path, self.profile["palette"])

    def test_detached_blade_and_clipped_silhouette_are_flagged(self):
        alpha = np.zeros((32, 32), dtype=np.uint8)
        alpha[4:28, 10:20] = 255
        self.assertEqual(frame_issues(alpha), [])
        alpha[10:12, 25:29] = 255
        self.assertEqual(frame_issues(alpha)[0]["kind"], "detached_cluster")
        alpha[10:12, 0:12] = 255
        self.assertIn("canvas_edge", [issue["kind"] for issue in frame_issues(alpha)])

    def test_walk_stabilization_removes_drift_without_changing_pixels(self):
        sheet = Image.new("RGBA", (96, 32))
        shape = Image.new("RGBA", (8, 20), (97, 107, 108, 255))
        for frame, x in enumerate([8, 12, 16]):
            sheet.paste(shape, (frame*32+x, 6))
        stable, corrections = stabilize_walk(sheet, (32, 32), 3, 8)
        self.assertEqual([p["shift_x"] for p in corrections], [4, 0, -4])
        for frame in range(3):
            self.assertEqual(stable.crop((frame*32, 0, (frame+1)*32, 32)).tobytes(),
                             stable.crop((32, 0, 64, 32)).tobytes())
        with self.assertRaises(ValueError):
            stabilize_walk(sheet, (32, 32), 3, 2)
