"""Wspólne stałe i funkcje narzędzi assetów Welesza (kontrakt welesza.asset.v1)."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
ART_SRC = REPO / "art-src"
GAME_ASSETS = REPO / "game" / "assets"
SCHEMA = Path(__file__).resolve().parent / "asset_schema.json"

DIRECTIONS = ("s", "sw", "w", "nw", "n", "ne", "e", "se")
SOURCE_SCALE = 2  # grafika malowana w 2x rozdzielczości gry
MAGENTA = np.array([255, 0, 255], dtype=np.float32)
ALPHA_MIN = 16  # piksel o alfie poniżej progu uznajemy za tło
SPILL_BAND = 6  # szerokość pasa (px w 2x) czyszczonego z różowej poświaty przy tle magenta


@dataclass
class Report:
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)

    def error(self, msg: str) -> None:
        self.errors.append(msg)

    def warn(self, msg: str) -> None:
        self.warnings.append(msg)

    @property
    def ok(self) -> bool:
        return not self.errors

    def print(self, title: str) -> None:
        state = "OK" if self.ok else "BŁĄD"
        print(f"[{state}] {title}")
        for m in self.errors:
            print(f"  błąd: {m}")
        for m in self.warnings:
            print(f"  uwaga: {m}")
        for m in self.notes:
            print(f"  info: {m}")


def load_meta(asset_dir: Path) -> dict:
    return json.loads((asset_dir / "asset.json").read_text(encoding="utf-8"))


def strip_path(asset_dir: Path, meta: dict, anim: str, layer: str, direction: str) -> Path:
    """Pasek klatek jednej animacji w jednym kierunku: <anim>/<dir>.png albo <anim>/<warstwa>/<dir>.png."""
    if meta["layers"] == ["full"]:
        return asset_dir / anim / f"{direction}.png"
    return asset_dir / anim / layer / f"{direction}.png"


def to_rgba(path: Path, background: str) -> np.ndarray:
    """Wczytuje obraz jako RGBA float32 0..255; tło magenta zamienia na przezroczystość."""
    with Image.open(path) as im:
        img = np.asarray(im.convert("RGBA"), dtype=np.float32)
    if background == "magenta":
        dist = np.linalg.norm(img[..., :3] - MAGENTA, axis=-1)
        # pełne tło przy odległości < 60, miękkie przejście do 140 (malarskie krawędzie)
        alpha = np.clip((dist - 60.0) / 80.0, 0.0, 1.0)
        img[..., 3] = np.minimum(img[..., 3], alpha * 255.0)
    _remove_pink_spill(img)
    return img


def _remove_pink_spill(img: np.ndarray) -> None:
    """Usuwa różową poświatę z pasa SPILL_BAND px przy tle.

    Malowana krawędź miesza magentę z kolorem także w pikselach w pełni kryjących (np. 150, 40,
    140 na skraju liści), a obraz z „przezroczystym” tłem bywa wycięty z magenty ręcznie i ma te
    same resztki. Dotyczy tylko pikseli, w których czerwony i niebieski przewyższają zielony;
    ciepłe barwy (skóra, drewno, ziemia) i fiolet głębiej w obrazie zostają.
    """
    rgb = img[..., :3]
    spill = np.clip(np.minimum(rgb[..., 0], rgb[..., 2]) - rgb[..., 1], 0, None)
    edge = _dilate(img[..., 3] < 255.0, SPILL_BAND)
    for channel in (0, 2):
        rgb[..., channel] = np.where(edge, np.clip(rgb[..., channel] - spill, 0, 255), rgb[..., channel])


def _dilate(mask: np.ndarray, radius: int) -> np.ndarray:
    """Poszerza maskę o `radius` px (kwadrat), bez zawijania przy krawędziach obrazu."""
    out = mask.copy()
    h, w = mask.shape
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            src = mask[max(0, -dy):h - max(0, dy), max(0, -dx):w - max(0, dx)]
            out[max(0, dy):h - max(0, -dy), max(0, dx):w - max(0, -dx)] |= src
    return out


def image_size(path: Path) -> tuple[int, int]:
    with Image.open(path) as im:
        return im.size


def split_strip(img: np.ndarray, frames: int, canvas: tuple[int, int]) -> list[np.ndarray]:
    w, h = canvas
    return [img[:h, i * w:(i + 1) * w] for i in range(frames)]


def bbox(frame: np.ndarray) -> tuple[int, int, int, int] | None:
    """Ramka nieprzezroczystych pikseli (x0, y0, x1, y1), wyłącznie."""
    mask = frame[..., 3] >= ALPHA_MIN
    if not mask.any():
        return None
    ys = np.where(mask.any(axis=1))[0]
    xs = np.where(mask.any(axis=0))[0]
    return int(xs[0]), int(ys[0]), int(xs[-1]) + 1, int(ys[-1]) + 1


def ground_point(frame: np.ndarray) -> tuple[float, float] | None:
    """Środek najniższego pasa nieprzezroczystych pikseli: przybliżenie punktu styku z ziemią."""
    box = bbox(frame)
    if box is None:
        return None
    x0, _, x1, y1 = box
    band = frame[max(y1 - 6, 0):y1, x0:x1, 3] >= ALPHA_MIN
    cols = np.where(band.any(axis=0))[0]
    cx = x0 + (cols.mean() if cols.size else (x1 - x0) / 2)
    return float(cx), float(y1)


def painted_and_mirrored(meta: dict) -> dict[str, tuple[str, bool]]:
    """Kierunek -> (kierunek źródłowy, czy odbić)."""
    out = {d: (d, False) for d in meta.get("directions", [])}
    for target, src in meta.get("mirror", {}).items():
        out[target] = (src, True)
    return out
