"""Testy czytelności i odtwarzalności proceduralnego modern pixel-art."""
import sys
import unittest
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from modern_pixelart_textures import (COLORS, GRADING, MATERIALS, WORK_SIZES,
                                      POSTERIZE_LEVELS, _material_group,
                                      _posterize_bands, pixelart)


def specimen() -> Image.Image:
    """Kontrastowe bryły plus fotograficzny szum, bez zależności od repo PNG."""
    im = Image.new("RGB", (1024, 1024), (60, 71, 46))
    draw = ImageDraw.Draw(im)
    draw.ellipse((130, 140, 740, 630), fill=(125, 105, 65))
    draw.polygon(((330, 30), (480, 960), (700, 960), (480, 30)), fill=(35, 32, 27))
    rng = np.random.default_rng(20261030)
    px = np.asarray(im, dtype=np.int16)
    noise = rng.integers(-22, 23, size=(1024, 1024, 1), dtype=np.int16)
    return Image.fromarray(np.clip(px + noise, 0, 255).astype(np.uint8), "RGB")


class ModernPixelartTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.src = specimen()
        cls.examples = {
            "bark": ("old_bark_weathered", pixelart(cls.src, "old_bark_weathered")),
            "ground": ("forest_litter_mixed", pixelart(cls.src, "forest_litter_mixed")),
            "rock": ("rock_stones_mossy", pixelart(cls.src, "rock_stones_mossy")),
        }

    def test_source_set_complete(self) -> None:
        names = {Path(f).stem for paths in MATERIALS.values() for f in paths}
        self.assertEqual(names, set(GRADING))
        self.assertEqual(len(names), 15)
        self.assertEqual(set(MATERIALS), set(WORK_SIZES))
        self.assertEqual(set(MATERIALS), set(COLORS))
        self.assertEqual(set(MATERIALS), set(POSTERIZE_LEVELS))
        for group, files in MATERIALS.items():
            for filename in files:
                self.assertEqual(_material_group(Path(filename).stem), group)

    def test_different_material_scales(self) -> None:
        self.assertEqual(WORK_SIZES["bark"], 128)
        self.assertEqual(WORK_SIZES["ground"], 64)
        self.assertEqual(WORK_SIZES["rock"], 64)
        for group, (stem, out) in self.examples.items():
            with self.subTest(group=group):
                self.assertEqual(out.size, (1024, 1024))
                scale = 1024 // WORK_SIZES[group]
                rgb = np.asarray(out.convert("RGB"))
                small = rgb[::scale, ::scale]
                recreated = np.repeat(np.repeat(small, scale, axis=0), scale, axis=1)
                np.testing.assert_array_equal(rgb, recreated)

    def test_palette_limit(self) -> None:
        for group, (_, out) in self.examples.items():
            with self.subTest(group=group):
                self.assertLessEqual(len(out.getcolors(maxcolors=1024 * 1024) or []),
                                     COLORS[group])

    def test_tile_edges_match(self) -> None:
        for group, (_, out) in self.examples.items():
            with self.subTest(group=group):
                rgb = np.asarray(out.convert("RGB"))
                np.testing.assert_array_equal(rgb[:, 0], rgb[:, -1])
                np.testing.assert_array_equal(rgb[0], rgb[-1])

    def test_reproducibility(self) -> None:
        for group, (stem, out) in self.examples.items():
            with self.subTest(group=group):
                self.assertEqual(out.tobytes(), pixelart(self.src, stem).tobytes())

    def test_distinct_shapes_remain(self) -> None:
        for group, (_, out) in self.examples.items():
            with self.subTest(group=group):
                self.assertGreater(float(np.asarray(out.convert("L")).std()), 10)

    def test_posterization_bands_no_uint8_overflow(self) -> None:
        ramp = Image.fromarray(np.tile(np.arange(256, dtype=np.uint8),
                                     (256, 1)), "L").convert("RGB")
        for group, levels in POSTERIZE_LEVELS.items():
            with self.subTest(group=group):
                arr = np.asarray(_posterize_bands(ramp, levels))
                self.assertLessEqual(len(np.unique(arr[..., 0])), levels)
                self.assertEqual(int(arr[0, 0, 0]), 0)
                self.assertEqual(int(arr[0, -1, 0]), 255)
                self.assertTrue(np.all(np.diff(arr[0, :, 0].astype(np.int16)) >= 0))

    def test_reject_unknown_material(self) -> None:
        with self.assertRaises(ValueError):
            pixelart(self.src, "unknown_material")

    def test_reject_wrong_dimensions(self) -> None:
        with self.assertRaises(ValueError):
            pixelart(self.src.resize((512, 512)), "old_bark_weathered")


if __name__ == "__main__":
    unittest.main()
