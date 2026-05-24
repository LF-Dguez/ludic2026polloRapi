"""Procesa los 3 tilesets del usuario (cueva, desierto, minas).
Detecta separadores, recorta, escala, guarda atlas limpios.
"""
from PIL import Image
from pathlib import Path
import shutil

ROOT = Path(__file__).parent.parent
TILES_DIR = ROOT / "art" / "tiles"
TILES_DIR.mkdir(parents=True, exist_ok=True)


def detect_regions(img):
    W, H = img.size
    px = img.load()

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

    dark_rows = [y for y in range(H) if is_dark_row(y)]
    dark_cols = [x for x in range(W) if is_dark_col(x)]

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

    row_runs = split_runs(dark_rows)
    col_runs = split_runs(dark_cols)
    rows = [r for r in regions(row_runs, H) if r[1] - r[0] > 30]
    cols = [r for r in regions(col_runs, W) if r[1] - r[0] > 30]
    return rows, cols


def even_grid(img, n_cols, n_rows):
    W, H = img.size
    cw = W / n_cols
    rh = H / n_rows
    cols = [(int(c * cw), int((c + 1) * cw)) for c in range(n_cols)]
    rows = [(int(r * rh), int((r + 1) * rh)) for r in range(n_rows)]
    return rows, cols


def process(src_path: Path, out_path: Path, tile_out: int, force_grid=None):
    print(f"\n--- Processing {src_path.name} -> {out_path.name} @ {tile_out}px ---")
    img = Image.open(src_path).convert("RGBA")
    if force_grid:
        rows, cols = even_grid(img, force_grid[0], force_grid[1])
        print(f"Using forced grid {force_grid[0]}x{force_grid[1]}")
    else:
        rows, cols = detect_regions(img)
        print(f"Detected {len(cols)} cols x {len(rows)} rows")
        # Si la detección falla (pocas filas/cols), asumir 8x8
        if len(cols) < 4 or len(rows) < 4:
            print(f"Detection failed, falling back to 8x8 grid")
            rows, cols = even_grid(img, 8, 8)
    out = Image.new("RGBA", (len(cols) * tile_out, len(rows) * tile_out), (0, 0, 0, 0))
    for r, (y0, y1) in enumerate(rows):
        for c, (x0, x1) in enumerate(cols):
            t = img.crop((x0, y0, x1, y1))
            t = t.resize((tile_out, tile_out), Image.NEAREST)
            out.paste(t, (c * tile_out, r * tile_out))
    out.save(out_path)
    out.resize((len(cols) * tile_out * 4, len(rows) * tile_out * 4), Image.NEAREST).save(
        str(out_path).replace(".png", "_preview.png")
    )
    print(f"OK: {out_path} ({len(cols) * tile_out}x{len(rows) * tile_out})")


# Cueva — 32px (alta resolución para dungeon)
cave_raw = ROOT / "PRINTS DE LA DE CUEVA.png"
if cave_raw.exists():
    shutil.copy(cave_raw, TILES_DIR / "cave_source.png")
process(TILES_DIR / "cave_source.png", TILES_DIR / "cave_tiles_clean.png", 32)

# Desierto — 16px (compatible con overworld atlas)
des_raw = ROOT / "PRINTS DEL DESIERTO.png"
if des_raw.exists():
    shutil.copy(des_raw, TILES_DIR / "desert_source.png")
process(TILES_DIR / "desert_source.png", TILES_DIR / "desert_tiles_clean.png", 16)

# Minas — 32px (dungeon Naica) — fondo no es negro puro, forzar grid 8x9
mines_raw = ROOT / "PRINTS DE LAS MINAS.png"
if mines_raw.exists():
    shutil.copy(mines_raw, TILES_DIR / "mines_source.png")
process(TILES_DIR / "mines_source.png", TILES_DIR / "mines_tiles_clean.png", 32, force_grid=(8, 9))
