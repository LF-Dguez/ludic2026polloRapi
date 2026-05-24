"""Genera trees TOP-DOWN (vista cenital real) 16x16, con canopy visible.
Output: art/tiles/trees_topdown.png — atlas 8x1 (8 árboles distintos)

Tipos para Chihuahua:
- Pino (sierra alta): triángulo verde oscuro
- Encina mexicana (sierra media): round canopy verde
- Sabino/ahuehuete (cerca río): canopy ancho ovalado
- Cardón/saguaro top-down: estrella verde (norte desierto)
- Mezquite: pequeño irregular dorado-verde
- Palo verde: amarillento
- Árbol seco: marrón sin hojas
- Pino oscuro: muy denso
"""
from PIL import Image
from pathlib import Path
import random
import math

ROOT = Path(__file__).parent.parent
OUT = ROOT / "art" / "tiles" / "trees_topdown.png"

T = 16
N_TREES = 8
out = Image.new("RGBA", (T * N_TREES, T), (0, 0, 0, 0))


def make_tree(painter):
    img = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    painter(img.load())
    return img


def fill_disk(px, cx, cy, r, color):
    for y in range(T):
        for x in range(T):
            dx = x - cx
            dy = y - cy
            if dx * dx + dy * dy <= r * r:
                px[x, y] = color


def fill_disk_jittered(px, cx, cy, r, color, jitter=1.0, seed=42):
    rng = random.Random(seed)
    for y in range(T):
        for x in range(T):
            dx = x - cx
            dy = y - cy
            d = math.sqrt(dx * dx + dy * dy)
            edge = r + (rng.random() * 2 - 1) * jitter
            if d <= edge:
                px[x, y] = color


def put(idx, img):
    out.paste(img, (idx * T, 0))


# === 1. Pino oscuro (sierra alta) — triángulo verde muy oscuro ===
def pino_oscuro(px):
    dark = (24, 50, 26, 255)
    mid = (40, 78, 40, 255)
    high = (60, 100, 50, 255)
    trunk = (62, 38, 22, 255)
    cx = 8
    # Layered triangle: each "level" is a horizontal band
    for y in range(2, 14):
        width = (y - 1) // 2
        for dx in range(-width, width + 1):
            x = cx + dx
            if 0 <= x < T:
                # outer = dark, inner = mid
                if abs(dx) == width:
                    px[x, y] = dark
                else:
                    px[x, y] = mid
                # tiny highlights
                if dx == -width + 1 and y > 4:
                    px[x, y] = high
    # trunk centro
    px[cx, 14] = trunk
    px[cx, 15] = trunk
put(0, make_tree(pino_oscuro))


# === 2. Encina mexicana — round green canopy ===
def encina(px):
    dark = (26, 60, 30, 255)
    mid = (50, 100, 50, 255)
    light = (90, 140, 75, 255)
    trunk = (74, 50, 30, 255)
    cx, cy = 8, 7
    fill_disk_jittered(px, cx, cy, 6.0, dark, jitter=0.8, seed=10)
    fill_disk_jittered(px, cx, cy, 4.5, mid, jitter=0.6, seed=20)
    # highlight cluster top-left (luz desde NO)
    fill_disk_jittered(px, cx - 1, cy - 1, 2.5, light, jitter=0.5, seed=30)
    # trunk peek
    px[cx, 14] = trunk
    px[cx - 1, 15] = trunk
    px[cx, 15] = trunk
put(1, make_tree(encina))


# === 3. Sabino/ahuehuete — canopy ancho ovalado ===
def sabino(px):
    dark = (28, 62, 28, 255)
    mid = (52, 96, 52, 255)
    light = (96, 132, 70, 255)
    trunk = (60, 36, 20, 255)
    cx, cy = 8, 7
    # Oval (más ancho que alto)
    for y in range(T):
        for x in range(T):
            dx = x - cx
            dy = y - cy
            # ellipse
            v = (dx * dx) / 49.0 + (dy * dy) / 25.0
            if v <= 1.0:
                px[x, y] = dark
            if v <= 0.55:
                px[x, y] = mid
            if v <= 0.18 and dx < 1 and dy < 1:
                px[x, y] = light
    px[cx, 14] = trunk
    px[cx, 15] = trunk
put(2, make_tree(sabino))


# === 4. Cardón (top-down saguaro/cardonal) — estrella verde-azulada ===
def cardon(px):
    base = (60, 100, 70, 255)
    spike = (90, 130, 90, 255)
    cx, cy = 8, 8
    # 5 brazos
    angles = [-math.pi / 2, -math.pi / 2 + 1.4, -math.pi / 2 - 1.4,
              math.pi / 2 - 0.5, math.pi / 2 + 0.5]
    fill_disk(px, cx, cy, 2, base)
    for a in angles:
        for r in range(1, 6):
            x = cx + int(round(math.cos(a) * r))
            y = cy + int(round(math.sin(a) * r))
            if 0 <= x < T and 0 <= y < T:
                px[x, y] = base
                if r >= 4:
                    px[x, y] = spike
put(3, make_tree(cardon))


# === 5. Mezquite — pequeño irregular ===
def mezquite(px):
    dark = (78, 96, 50, 255)
    mid = (122, 142, 70, 255)
    light = (160, 170, 96, 255)
    trunk = (74, 50, 24, 255)
    cx, cy = 8, 8
    fill_disk_jittered(px, cx, cy, 5.0, dark, jitter=1.4, seed=100)
    fill_disk_jittered(px, cx, cy, 3.0, mid, jitter=1.0, seed=110)
    fill_disk_jittered(px, cx - 1, cy - 1, 1.5, light, jitter=0.5, seed=120)
    px[cx, 14] = trunk
put(4, make_tree(mezquite))


# === 6. Palo verde (verdoso-amarillento) ===
def palo_verde(px):
    dark = (104, 122, 60, 255)
    mid = (148, 168, 88, 255)
    light = (190, 200, 110, 255)
    trunk = (110, 130, 60, 255)  # palo verde literalmente tiene tronco verde
    cx, cy = 8, 8
    fill_disk_jittered(px, cx, cy, 5.5, dark, jitter=1.2, seed=200)
    fill_disk_jittered(px, cx, cy, 3.5, mid, jitter=0.8, seed=210)
    fill_disk_jittered(px, cx - 1, cy - 1, 1.8, light, jitter=0.4, seed=220)
    px[cx, 14] = trunk
    px[cx, 15] = trunk
put(5, make_tree(palo_verde))


# === 7. Árbol seco / muerto — marrón sin hojas ===
def arbol_seco(px):
    branch = (76, 50, 30, 255)
    branch_dark = (50, 32, 18, 255)
    cx, cy = 8, 8
    # Tronco central
    for y in range(4, 14):
        px[cx, y] = branch_dark
        px[cx + 1, y] = branch
    # Ramas en cruz
    for x in range(3, 14):
        px[x, 7] = branch_dark
        if x % 2 == 0:
            px[x, 6] = branch
    # diagonal branches
    pts = [(5, 5), (6, 4), (11, 5), (10, 4), (4, 9), (12, 9)]
    for (x, y) in pts:
        px[x, y] = branch
put(6, make_tree(arbol_seco))


# === 8. Pino claro / pino piñón (sierra media) ===
def pino_claro(px):
    dark = (40, 80, 38, 255)
    mid = (66, 116, 60, 255)
    light = (108, 152, 80, 255)
    trunk = (74, 50, 28, 255)
    cx = 8
    for y in range(1, 14):
        width = (y) // 2
        for dx in range(-width, width + 1):
            x = cx + dx
            if 0 <= x < T:
                if abs(dx) >= width - 1:
                    px[x, y] = dark
                else:
                    px[x, y] = mid
                if dx == -width + 1 and y > 3 and y < 12:
                    px[x, y] = light
    px[cx, 14] = trunk
    px[cx, 15] = trunk
put(7, make_tree(pino_claro))


out.save(OUT)
out.resize((T * N_TREES * 8, T * 8), Image.NEAREST).save(
    str(OUT).replace(".png", "_preview.png")
)
print(f"OK -> {OUT} ({T * N_TREES}x{T}, {N_TREES} tipos de árbol top-down)")
