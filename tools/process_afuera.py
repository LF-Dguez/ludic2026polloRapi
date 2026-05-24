"""Procesa afuera.png (atlas vegetación) — detecta grid, recorta, escala a 16x16
para integrar como tercer source en overworld TileSet.
"""
from PIL import Image
from pathlib import Path
import shutil

ROOT = Path(__file__).parent.parent
SRC_RAW = ROOT / "afuera.png"
SRC = ROOT / "art" / "tiles" / "afuera_source.png"
OUT = ROOT / "art" / "tiles" / "afuera_clean.png"

if SRC_RAW.exists():
    shutil.copy(SRC_RAW, SRC)

T_OUT = 16
src = Image.open(SRC).convert("RGBA")
W, H = src.size
print(f"Source: {W}x{H}")
px = src.load()


def is_dark_row(y, threshold=30):
    s = 0
    for x in range(W):
        r, g, b, _ = px[x, y]
        s += (r + g + b) / 3
    return (s / W) < threshold


def is_dark_col(x, threshold=30):
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


def regions(runs, total):
    out = []
    prev = 0
    for run in runs:
        s = run[0]; e = run[-1] + 1
        if s > prev:
            out.append((prev, s))
        prev = e
    if prev < total:
        out.append((prev, total))
    return out


dark_rows = [y for y in range(H) if is_dark_row(y)]
dark_cols = [x for x in range(W) if is_dark_col(x)]
row_runs = split_runs(dark_rows)
col_runs = split_runs(dark_cols)
row_regions = [r for r in regions(row_runs, H) if r[1] - r[0] > 40]
col_regions = [r for r in regions(col_runs, W) if r[1] - r[0] > 40]
print(f"Detected {len(col_regions)} cols x {len(row_regions)} rows")

# Fallback si detection falla
if len(col_regions) < 4:
    print("Auto-detect fallback — forcing 12 cols")
    cw = W / 12
    col_regions = [(int(c * cw), int((c + 1) * cw)) for c in range(12)]
if len(row_regions) < 4:
    print("Auto-detect fallback — forcing 11 rows")
    rh = H / 11
    row_regions = [(int(r * rh), int((r + 1) * rh)) for r in range(11)]

COLS = len(col_regions)
ROWS = len(row_regions)
print(f"Final grid: {COLS}x{ROWS}")

out = Image.new("RGBA", (COLS * T_OUT, ROWS * T_OUT), (0, 0, 0, 0))
for r, (y0, y1) in enumerate(row_regions):
    for c, (x0, x1) in enumerate(col_regions):
        tile = src.crop((x0, y0, x1, y1))
        # Treat very dark pixels as transparent (background)
        tile_rgba = tile.convert("RGBA")
        pxt = tile_rgba.load()
        tw, th = tile_rgba.size
        for ty in range(th):
            for tx in range(tw):
                rr, gg, bb, _aa = pxt[tx, ty]
                if rr + gg + bb < 30:  # near-black → transparent (esto separa decoración del fondo)
                    pxt[tx, ty] = (0, 0, 0, 0)
        tile_rgba = tile_rgba.resize((T_OUT, T_OUT), Image.NEAREST)
        out.paste(tile_rgba, (c * T_OUT, r * T_OUT))

out.save(OUT)
out.resize((COLS * T_OUT * 6, ROWS * T_OUT * 6), Image.NEAREST).save(
    str(OUT).replace(".png", "_preview.png")
)
print(f"OK -> {OUT} ({COLS * T_OUT}x{ROWS * T_OUT}, {COLS * ROWS} tiles a {T_OUT}x{T_OUT})")
