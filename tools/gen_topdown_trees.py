"""Genera trees TOP-DOWN GRANDES — 32x32 native por tile (4x área vs antes).
Output: art/tiles/trees_big.png (atlas 8x1 de 32x32 cada uno)

Rendered como Sprite2D en game con scale 2 → 64x64 display (1x player),
o scale 4 → 128x128 (2x player).
"""
from PIL import Image
from pathlib import Path
import random
import math

ROOT = Path(__file__).parent.parent
OUT = ROOT / "art" / "tiles" / "trees_big.png"

T = 32
N_TREES = 8
out = Image.new("RGBA", (T * N_TREES, T), (0, 0, 0, 0))


def make_tree(painter):
    img = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    painter(img.load())
    return img


def fill_disk(px, cx, cy, r, color):
    for y in range(T):
        for x in range(T):
            dx = x - cx; dy = y - cy
            if dx * dx + dy * dy <= r * r:
                px[x, y] = color


def fill_disk_jittered(px, cx, cy, r, color, jitter=1.0, seed=42):
    rng = random.Random(seed)
    for y in range(T):
        for x in range(T):
            dx = x - cx; dy = y - cy
            d = math.sqrt(dx * dx + dy * dy)
            edge = r + (rng.random() * 2 - 1) * jitter
            if d <= edge:
                px[x, y] = color


def put(idx, img):
    out.paste(img, (idx * T, 0))


# === 1. Pino oscuro — triángulo verde muy oscuro ===
def pino_oscuro(px):
    dark = (24, 50, 26, 255); mid = (40, 78, 40, 255); high = (60, 100, 50, 255)
    trunk = (62, 38, 22, 255); trunk_d = (40, 24, 14, 255)
    cx = 16
    # Layered triangle más alto (24px tall)
    for y in range(2, 27):
        width = (y - 1) // 2
        for dx in range(-width, width + 1):
            x = cx + dx
            if 0 <= x < T:
                if abs(dx) >= width - 1:
                    px[x, y] = dark
                else:
                    px[x, y] = mid
                if dx == -width + 2 and y > 6 and y < 22:
                    px[x, y] = high
    # Trunk grueso
    for ty in range(27, T):
        px[cx - 1, ty] = trunk_d
        px[cx, ty] = trunk
        px[cx + 1, ty] = trunk_d
put(0, make_tree(pino_oscuro))


# === 2. Encina — round green canopy ===
def encina(px):
    dark = (26, 60, 30, 255); mid = (50, 100, 50, 255); light = (90, 140, 75, 255)
    trunk = (74, 50, 30, 255); trunk_d = (50, 32, 18, 255)
    cx, cy = 16, 14
    fill_disk_jittered(px, cx, cy, 12.0, dark, jitter=1.5, seed=10)
    fill_disk_jittered(px, cx, cy, 9.0, mid, jitter=1.0, seed=20)
    fill_disk_jittered(px, cx - 2, cy - 2, 5.0, light, jitter=0.8, seed=30)
    # Trunk
    for ty in range(27, T):
        px[cx - 1, ty] = trunk_d
        px[cx, ty] = trunk
        px[cx + 1, ty] = trunk_d
put(1, make_tree(encina))


# === 3. Sabino — canopy ancho ovalado ===
def sabino(px):
    dark = (28, 62, 28, 255); mid = (52, 96, 52, 255); light = (96, 132, 70, 255)
    trunk = (60, 36, 20, 255); trunk_d = (40, 24, 12, 255)
    cx, cy = 16, 14
    for y in range(T):
        for x in range(T):
            dx = x - cx; dy = y - cy
            v = (dx * dx) / 196.0 + (dy * dy) / 100.0
            if v <= 1.0:
                px[x, y] = dark
            if v <= 0.55:
                px[x, y] = mid
            if v <= 0.18 and dx < 1 and dy < 1:
                px[x, y] = light
    for ty in range(27, T):
        px[cx - 1, ty] = trunk_d
        px[cx, ty] = trunk
        px[cx + 1, ty] = trunk_d
put(2, make_tree(sabino))


# === 4. Cardón — top-down saguaro estrella ===
def cardon(px):
    base = (60, 100, 70, 255); spike = (90, 130, 90, 255); spike_d = (40, 76, 50, 255)
    cx, cy = 16, 16
    angles = [-math.pi / 2, -math.pi / 2 + 1.4, -math.pi / 2 - 1.4,
              math.pi / 2 - 0.5, math.pi / 2 + 0.5]
    fill_disk(px, cx, cy, 4, base)
    for a in angles:
        for r in range(2, 13):
            x = cx + int(round(math.cos(a) * r))
            y = cy + int(round(math.sin(a) * r))
            if 0 <= x < T and 0 <= y < T:
                px[x, y] = base
                # grosor brazo
                if 0 <= x+1 < T: px[x+1, y] = spike_d
                if 0 <= x-1 < T: px[x-1, y] = spike_d
                if r >= 8:
                    px[x, y] = spike
put(3, make_tree(cardon))


# === 5. Mezquite — pequeño irregular ===
def mezquite(px):
    dark = (78, 96, 50, 255); mid = (122, 142, 70, 255); light = (160, 170, 96, 255)
    trunk = (74, 50, 24, 255); trunk_d = (50, 32, 14, 255)
    cx, cy = 16, 16
    fill_disk_jittered(px, cx, cy, 10.0, dark, jitter=2.5, seed=100)
    fill_disk_jittered(px, cx, cy, 6.5, mid, jitter=1.8, seed=110)
    fill_disk_jittered(px, cx - 2, cy - 2, 3.0, light, jitter=1.0, seed=120)
    for ty in range(27, T):
        px[cx, ty] = trunk
        px[cx - 1, ty] = trunk_d
put(4, make_tree(mezquite))


# === 6. Palo verde ===
def palo_verde(px):
    dark = (104, 122, 60, 255); mid = (148, 168, 88, 255); light = (190, 200, 110, 255)
    trunk = (110, 130, 60, 255); trunk_d = (76, 96, 42, 255)
    cx, cy = 16, 16
    fill_disk_jittered(px, cx, cy, 11.0, dark, jitter=2.0, seed=200)
    fill_disk_jittered(px, cx, cy, 7.0, mid, jitter=1.5, seed=210)
    fill_disk_jittered(px, cx - 2, cy - 2, 3.5, light, jitter=0.8, seed=220)
    for ty in range(26, T):
        px[cx - 1, ty] = trunk_d
        px[cx, ty] = trunk
        px[cx + 1, ty] = trunk_d
put(5, make_tree(palo_verde))


# === 7. Árbol seco ===
def arbol_seco(px):
    branch = (76, 50, 30, 255); branch_dark = (50, 32, 18, 255)
    cx, cy = 16, 16
    # Tronco grueso central
    for y in range(8, 30):
        px[cx, y] = branch_dark
        px[cx + 1, y] = branch
        px[cx - 1, y] = branch_dark
    # Ramas en cruz amplias
    for x in range(5, 28):
        px[x, 14] = branch_dark
        if x % 3 == 0:
            px[x, 13] = branch
            px[x, 15] = branch_dark
    # diagonal branches
    pts = [(8, 10), (10, 8), (24, 10), (22, 8), (6, 20), (26, 20),
           (12, 18), (20, 18), (9, 24), (23, 24)]
    for (x, y) in pts:
        if 0 <= x < T and 0 <= y < T:
            px[x, y] = branch
put(6, make_tree(arbol_seco))


# === 8. Pino claro ===
def pino_claro(px):
    dark = (40, 80, 38, 255); mid = (66, 116, 60, 255); light = (108, 152, 80, 255)
    trunk = (74, 50, 28, 255); trunk_d = (50, 32, 16, 255)
    cx = 16
    for y in range(2, 28):
        width = (y) // 2
        for dx in range(-width, width + 1):
            x = cx + dx
            if 0 <= x < T:
                if abs(dx) >= width - 1:
                    px[x, y] = dark
                else:
                    px[x, y] = mid
                if dx == -width + 2 and y > 6 and y < 24:
                    px[x, y] = light
    for ty in range(28, T):
        px[cx - 1, ty] = trunk_d
        px[cx, ty] = trunk
        px[cx + 1, ty] = trunk_d
put(7, make_tree(pino_claro))


out.save(OUT)
out.resize((T * N_TREES * 4, T * 4), Image.NEAREST).save(
    str(OUT).replace(".png", "_preview.png")
)
print(f"OK -> {OUT} ({T * N_TREES}x{T}, {N_TREES} tipos BIG)")
