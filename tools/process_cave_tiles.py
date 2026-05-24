"""Procesa el atlas de cueva del usuario:
- Detecta los separadores oscuros
- Recorta cada uno de los 64 tiles (8x8 grid)
- Escala cada tile a 32x32 (efectivo en pantalla)
- Guarda atlas limpio 256x256 con padding 0

Resultado: art/tiles/cave_tiles_clean.png (uso directo desde Godot)
"""
from PIL import Image
from pathlib import Path

ROOT = Path(__file__).parent.parent
SRC = ROOT / "art" / "tiles" / "cave_tiles.png"
OUT = ROOT / "art" / "tiles" / "cave_tiles_clean.png"

T_OUT = 32
COLS, ROWS = 8, 8

src = Image.open(SRC).convert("RGBA")
W, H = src.size
print(f"Source: {W}x{H}")

px = src.load()


def is_dark_row(y, threshold=40):
    total = 0
    count = 0
    for x in range(W):
        r, g, b, _ = px[x, y]
        total += (r + g + b) / 3
        count += 1
    return (total / count) < threshold


def is_dark_col(x, threshold=40):
    total = 0
    count = 0
    for y in range(H):
        r, g, b, _ = px[x, y]
        total += (r + g + b) / 3
        count += 1
    return (total / count) < threshold


# Detectar filas oscuras (separadores horizontales)
dark_rows = [y for y in range(H) if is_dark_row(y)]
dark_cols = [x for x in range(W) if is_dark_col(x)]
print(f"Dark rows count: {len(dark_rows)}")
print(f"Dark cols count: {len(dark_cols)}")


def split_runs(values):
    """Divide una secuencia de índices en runs contiguos."""
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


row_runs = split_runs(dark_rows)
col_runs = split_runs(dark_cols)
print(f"Row separator runs: {len(row_runs)}")
print(f"Col separator runs: {len(col_runs)}")

# Los separadores definen las regiones entre ellos.
# Esperamos COLS+1 runs de columnas (bordes + separadores)
# y ROWS+1 runs de filas.

def regions_from_runs(runs, total):
    """Convierte runs de separadores en regiones de contenido."""
    regions = []
    prev_end = 0
    for run in runs:
        start_sep = run[0]
        end_sep = run[-1] + 1
        if start_sep > prev_end:
            regions.append((prev_end, start_sep))
        prev_end = end_sep
    if prev_end < total:
        regions.append((prev_end, total))
    return regions


row_regions = regions_from_runs(row_runs, H)
col_regions = regions_from_runs(col_runs, W)
print(f"Row regions: {len(row_regions)} -> {row_regions[:3]}")
print(f"Col regions: {len(col_regions)} -> {col_regions[:3]}")

# Filtrar regiones demasiado pequeñas (ruido)
row_regions = [r for r in row_regions if r[1] - r[0] > 30]
col_regions = [r for r in col_regions if r[1] - r[0] > 30]
print(f"After filter — rows: {len(row_regions)}, cols: {len(col_regions)}")

assert len(row_regions) >= ROWS, f"Solo encontré {len(row_regions)} filas, esperaba {ROWS}"
assert len(col_regions) >= COLS, f"Solo encontré {len(col_regions)} columnas, esperaba {COLS}"

# Tomar las primeras ROWS y COLS
row_regions = row_regions[:ROWS]
col_regions = col_regions[:COLS]

# Atlas de salida limpio
out = Image.new("RGBA", (COLS * T_OUT, ROWS * T_OUT), (0, 0, 0, 0))

for r, (y0, y1) in enumerate(row_regions):
    for c, (x0, x1) in enumerate(col_regions):
        tile = src.crop((x0, y0, x1, y1))
        tile = tile.resize((T_OUT, T_OUT), Image.NEAREST)
        out.paste(tile, (c * T_OUT, r * T_OUT))

out.save(OUT)
out.resize((COLS * T_OUT * 4, ROWS * T_OUT * 4), Image.NEAREST).save(
    str(OUT).replace(".png", "_preview.png")
)
print(f"OK -> {OUT} ({COLS * T_OUT}x{ROWS * T_OUT}, {ROWS * COLS} tiles a {T_OUT}x{T_OUT})")
