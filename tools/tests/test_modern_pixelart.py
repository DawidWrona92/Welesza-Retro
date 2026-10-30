"""Testy czytelności i odtwarzalności proceduralnego modern pixel-art."""
import sys
import unittest
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from modern_pixelart_textures import COLORS, GRADING, MATERIALS, WORK_SIZE, pixelart


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
        cls.out = pixelart(cls.src, "old_bark_weathered")
        cls.out_rgb = np.asarray(cls.out.convert("RGB"))

    def test_source_set_complete(self) -> None:
        names = {Path(f).stem for paths in MATERIALS.values() for f in paths}
        self.assertEqual(names, set(GRADING))
        self.assertEqual(len(names), 15)

    def test_true_pixel_grid(self) -> None:
        self.assertEqual(self.out.size, (1024, 1024))
        scale = 1024 // WORK_SIZE
        self.assertGreaterEqual(scale, 8)
        base = self.out_rgb[::scale, ::scale]
        reconstructed = np.repeat(np.repeat(base, scale, axis=0), scale, axis=1)
        np.testing.assert_array_equal(reconstructed, self.out_rgb)

    def test_limit_palette(self) -> None:
        self.assertLessEqual(len(self.out.getcolors(maxcolors=1024 * 1024) or []), COLORS)

    def test_tile_edges_match(self) -> None:
        np.testing.assert_array_equal(self.out_rgb[:, 0], self.out_rgb[:, -1])
        np.testing.assert_array_equal(self.out_rgb[0], self.out_rgb[-1])

    def test_reproducibility(self) -> None:
        second = pixelart(self.src, "old_bark_weathered")
        self.assertEqual(self.out.tobytes(), second.tobytes())

    def test_shape_is_not_flat_color(self) -> None:
        gray = np.asarray(self.out.convert("L"))
        self.assertGreater(float(gray.std()), 10)

    def test_reject_wrong_dimensions(self) -> None:
        with self.assertRaises(ValueError):
            pixelart(self.src.resize((512, 512)), "old_bark_weathered")


if __name__ == "__main__":
    unittest.main()
