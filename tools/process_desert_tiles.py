"""Procesa el atlas de desierto del usuario.
Output: 16x16 cada tile (compatible con overworld atlas).
"""
from PIL import Image
from pathlib import Path
import shutil

ROOT = Path(__file__).parent.parent
SRC_RAW = ROOT / "PRINTS DEL DESIERTO.png"
SRC = ROOT / "art" / "tiles" / "desert_source.png"
OUT = ROOT / "art" / "tiles" / "desert_tiles_clean.png"

# Copiar a art/
if SRC_RAW.exists():
    shutil.copy(SRC_RAW, SRC)

T_OUT = 16

src = Image.open(SRC).convert("RGBA")
W, H = src.size
print(f"Source: {W}x{H}")
px = src.load()


def is_dark_row(y, threshold=40):
    s = 0
    for x in range(W):
        r, g, b, _ = px[x, y]
        s += (r + g + b) / 3
    return (s / W) < threshold


def is_dark_col(x, threshold=40):
    s = 0
    for y in range(H):
        r, g, b, _ = px[x, y]
        s += (r + g + b) / 3
    return (s / H) < threshold


def split_runs(values):
    runs = []
    cur = []
    for v in values:
        if not cur or v == cur[-1] + 1:
            cur.append(v)
        else:
            runs.append(cur)
            cur = [v]
    if cur:
        runs.append(cur)
    return runs


def regions_from_runs(runs, total):
    regions = []
    prev_end = 0
    for run in runs:
        s = run[0]
        e = run[-1] + 1
        if s > prev_end:
            regions.append((prev_end, s))
        prev_end = e
    if prev_end < total:
        regions.append((prev_end, total))
    return regions


dark_rows = [y for y in range(H) if is_dark_row(y)]
dark_cols = [x for x in range(W) if is_dark_col(x)]
print(f"Dark rows: {len(dark_rows)} cols: {len(dark_cols)}")

row_runs = split_runs(dark_rows)
col_runs = split_runs(dark_cols)

row_regions = [r for r in regions_from_runs(row_runs, H) if r[1] - r[0] > 30]
col_regions = [r for r in regions_from_runs(col_runs, W) if r[1] - r[0] > 30]
print(f"Tiles detected: {len(col_regions)} cols x {len(row_regions)} rows")

COLS = len(col_regions)
ROWS = len(row_regions)

# Atlas de salida limpio
out = Image.new("RGBA", (COLS * T_OUT, ROWS * T_OUT), (0, 0, 0, 0))

for r, (y0, y1) in enumerate(row_regions):
    for c, (x0, x1) in enumerate(col_regions):
        tile = src.crop((x0, y0, x1, y1))
        # Si tiene bg negro y queremos transparencia, podríamos hacer un alpha sobre negros puros.
        # Para los del desierto preservamos todo (no asumimos transparent bg).
        tile = tile.resize((T_OUT, T_OUT), Image.NEAREST)
        out.paste(tile, (c * T_OUT, r * T_OUT))

out.save(OUT)
out.resize((COLS * T_OUT * 6, ROWS * T_OUT * 6), Image.NEAREST).save(
    str(OUT).replace(".png", "_preview.png")
)
print(f"OK -> {OUT} ({COLS * T_OUT}x{ROWS * T_OUT}, {ROWS * COLS} tiles a {T_OUT}x{T_OUT})")
