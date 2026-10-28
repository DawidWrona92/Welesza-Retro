"""Walidator assetów art-src/<ID>/ według kontraktu welesza.asset.v1.

Użycie: python3 tools/validate_asset.py [art-src/<ID> ...]   (bez argumentów: wszystkie)
Kod wyjścia 1, gdy którykolwiek asset ma błędy.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import jsonschema
import numpy as np

from welesza_assets import (ART_SRC, image_size, DIRECTIONS, SCHEMA, Report, bbox, ground_point, load_meta,
                            split_strip, strip_path, to_rgba)

GROUND_TOLERANCE = 0.06   # odchylenie styku z ziemią od kotwicy, jako część wysokości płótna
HEIGHT_TOLERANCE = 0.08   # dopuszczalna zmienność wysokości sylwetki w animacjach chodu i spoczynku
STABLE_ANIMS = ("idle", "walk")
JITTER_TOLERANCE = 0.025  # dopuszczalny skok głowy w poziomie między kolejnymi klatkami (część szerokości płótna)
HEAD_SHARE = 0.15         # górna część sylwetki traktowana jako głowa przy pomiarze drgania


def validate(asset_dir: Path) -> Report:
    rep = Report()
    meta_path = asset_dir / "asset.json"
    if not meta_path.exists():
        rep.error("brak asset.json")
        return rep
    try:
        meta = load_meta(asset_dir)
    except json.JSONDecodeError as exc:
        rep.error(f"asset.json nie jest poprawnym JSON: {exc}")
        return rep
    schema = json.loads(SCHEMA.read_text(encoding="utf-8"))
    for err in jsonschema.Draft202012Validator(schema).iter_errors(meta):
        path = "/".join(str(p) for p in err.path) or "(korzeń)"
        rep.error(f"schemat: {path}: {err.message}")
    if not rep.ok:
        return rep
    if meta["id"] != asset_dir.name:
        rep.error(f"id {meta['id']} różni się od nazwy katalogu {asset_dir.name}")
    w, h = meta["canvas"]
    ax, ay = meta["anchor"]
    if not (0 <= ax < w and 0 <= ay < h):
        rep.error("kotwica poza płótnem")
    {"character": _character, "prop": _prop, "tile": _tile}[meta["kind"]](asset_dir, meta, rep)
    return rep


def _character(asset_dir: Path, meta: dict, rep: Report) -> None:
    w, h = meta["canvas"]
    painted = meta["directions"]
    mirror = meta.get("mirror", {})
    for target, src in mirror.items():
        if target in painted:
            rep.error(f"kierunek {target} jest malowany i jednocześnie odbijany")
        if src not in painted:
            rep.error(f"odbicie {target} wskazuje niemalowany kierunek {src}")
    missing = [d for d in DIRECTIONS if d not in painted and d not in mirror]
    if missing:
        rep.warn(f"brak kierunków: {', '.join(missing)}")
    heights: dict[str, list[float]] = {}
    for anim, spec in meta["animations"].items():
        n = spec["frames"]
        for ev in spec.get("events", []):
            if ev["frame"] >= n:
                rep.error(f"{anim}: zdarzenie {ev['name']} na klatce {ev['frame']} poza zakresem 0..{n - 1}")
        for layer in meta["layers"]:
            for d in painted:
                path = strip_path(asset_dir, meta, anim, layer, d)
                if not path.exists():
                    rep.error(f"brak pliku {path.relative_to(asset_dir)}")
                    continue
                size = image_size(path)
                if size != (w * n, h):
                    rep.error(f"{path.relative_to(asset_dir)}: rozmiar {size}, oczekiwano {(w * n, h)}")
                    continue
                frames = split_strip(to_rgba(path, meta.get("background", "transparent")), n, (w, h))
                _check_frames(path.relative_to(asset_dir), frames, meta, anim, layer, rep, heights)
    for anim, hs in heights.items():
        if len(hs) > 1:
            med = float(np.median(hs))
            dev = max(abs(x - med) for x in hs) / med
            rep.notes.append(f"{anim}: wysokość sylwetki {med:.0f} px, maks. odchylenie {dev:.1%}")
            if dev > HEIGHT_TOLERANCE:
                rep.warn(f"{anim}: wysokość sylwetki skacze o {dev:.1%} (limit {HEIGHT_TOLERANCE:.0%})")


def _check_frames(rel: Path, frames: list[np.ndarray], meta: dict, anim: str, layer: str,
                  rep: Report, heights: dict[str, list[float]]) -> None:
    h = meta["canvas"][1]
    ay = meta["anchor"][1]
    grounds = []
    heads: list[float] = []
    for i, fr in enumerate(frames):
        box = bbox(fr)
        if box is None:
            rep.error(f"{rel}: klatka {i} jest pusta")
            continue
        if fr[..., 3].min() >= 250:
            rep.error(f"{rel}: klatka {i} nie ma przezroczystego tła")
            continue
        x0, y0, x1, y1 = box
        if x0 == 0 or y0 == 0 or x1 == fr.shape[1] or y1 == fr.shape[0]:
            rep.warn(f"{rel}: klatka {i} dotyka krawędzi płótna (możliwe ucięcie)")
        grounds.append(ground_point(fr)[1])
        if layer in ("full", "body") and anim in STABLE_ANIMS:
            heights.setdefault(anim, []).append(float(y1 - y0))
            heads.append(_head_x(fr, box))
    if len(heads) > 1:
        _check_jitter(rel, heads, meta, anim, rep)
    if grounds and layer in ("full", "body"):
        med = float(np.median(grounds))
        if abs(med - ay) > GROUND_TOLERANCE * h:
            rep.warn(f"{rel}: styk z ziemią na y={med:.0f}, kotwica y={ay} (pipeline wyrówna)")


def _head_x(frame: np.ndarray, box: tuple[int, int, int, int]) -> float:
    """Środek głowy w poziomie: średnia kolumn widocznych w górnej części sylwetki."""
    x0, y0, x1, y1 = box
    top = frame[y0:y0 + max(1, int((y1 - y0) * HEAD_SHARE)), :, 3] > 40
    cols = np.nonzero(top.any(axis=0))[0]
    return float(cols.mean())


def _check_jitter(rel: Path, heads: list[float], meta: dict, anim: str, rep: Report) -> None:
    """Chód i spoczynek: głowa przesuwa się płynnie; duży skok między klatkami to drganie postaci."""
    loop = meta["animations"][anim].get("loop", False)
    pairs = list(zip(heads, heads[1:] + (heads[:1] if loop else [])))
    jump, at = max((abs(b - a), i) for i, (a, b) in enumerate(pairs))
    limit = JITTER_TOLERANCE * meta["canvas"][0]
    if jump > limit:
        rep.warn(f"{rel}: głowa skacze w poziomie o {jump:.0f} px między klatkami {at} i "
                 f"{(at + 1) % len(heads)} (limit {limit:.0f} px): postać drga")


def _prop(asset_dir: Path, meta: dict, rep: Report) -> None:
    w, h = meta["canvas"]
    for layer in meta["layers"]:
        path = asset_dir / f"{layer}.png"
        if not path.exists():
            rep.error(f"brak pliku {layer}.png")
            continue
        if image_size(path) != (w, h):
            rep.error(f"{layer}.png: rozmiar inny niż płótno {w}x{h}")
            continue
        if bbox(to_rgba(path, meta.get("background", "transparent"))) is None:
            rep.error(f"{layer}.png jest pusty")
    if not 0 <= meta["occlusion_y"] <= h:
        rep.error("occlusion_y poza płótnem")


def _tile(asset_dir: Path, meta: dict, rep: Report) -> None:
    w, h = meta["canvas"]
    if w != 2 * h:
        rep.error(f"kafel izometryczny musi mieć proporcje 2:1, jest {w}x{h}")
    for i in range(1, meta["variants"] + 1):
        path = asset_dir / f"{i:02d}.png"
        if not path.exists():
            rep.error(f"brak pliku {path.name}")
            continue
        if image_size(path) != (w, h):
            rep.error(f"{path.name}: rozmiar inny niż płótno {w}x{h}")
            continue
        img = to_rgba(path, meta.get("background", "transparent"))
        corners = [img[2, 2, 3], img[2, w - 3, 3], img[h - 3, 2, 3], img[h - 3, w - 3, 3]]
        if max(corners) >= 250:
            rep.warn(f"{path.name}: narożniki nieprzezroczyste; kafel powinien być rombem")


def main(argv: list[str]) -> int:
    dirs = [Path(a) for a in argv] or sorted(p for p in ART_SRC.iterdir()
                                             if p.is_dir() and not p.name.startswith("_"))
    failed = 0
    for d in dirs:
        rep = validate(d)
        rep.print(d.name)
        failed += not rep.ok
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
