"""biome_bases.png — 8 biomas × 4 variantes cada uno = 32 tiles 16x16.

Cada bioma tiene textura específica subtil:
- LLANOS/SIERRA: pequeñas "hojas" verticales 1-2 px en posiciones quasi-random
- DESIERTO: micro-granos de arena + ondas
- BARRANCA/MINERO: moteado de piedra
- RIO: ondas horizontales
- MESA: arena más clara con piedras
- PICO: nieve con manchas

Layout: 32x4 → 8 biomas en columnas × 4 variantes en filas.
"""
from PIL import Image
from pathlib import Path
import random
import math

ROOT = Path(__file__).parent.parent
OUT = ROOT / "art" / "tiles" / "biome_bases.png"

T = 16
N_BIOMES = 8
N_VARIANTS = 4

# Paletas (base, dark, light, accent)
PALETTES = [
    # LLANOS — pastizal seco verde-oliva
    ((118, 132, 70, 255), (84, 96, 50, 255), (160, 172, 100, 255), (200, 200, 110, 255)),
    # SIERRA — bosque pino verde oscuro
    ((62, 92, 54, 255), (38, 60, 34, 255), (96, 130, 78, 255), (140, 168, 100, 255)),
    # DESIERTO — arena dorada
    ((178, 142, 90, 255), (138, 108, 66, 255), (212, 180, 130, 255), (232, 200, 150, 255)),
    # BARRANCA — cañón profundo casi negro
    ((58, 46, 36, 255), (30, 22, 16, 255), (88, 70, 54, 255), (108, 88, 68, 255)),
    # MINERO — tierra minera marrón oscuro
    ((76, 62, 48, 255), (46, 36, 26, 255), (108, 90, 70, 255), (132, 108, 78, 255)),
    # RIO — agua azul
    ((48, 96, 130, 255), (32, 68, 96, 255), (88, 140, 170, 255), (160, 200, 220, 255)),
    # MESA — meseta tan claro
    ((148, 116, 72, 255), (108, 84, 50, 255), (184, 148, 98, 255), (210, 178, 124, 255)),
    # PICO — nieve gris-blanco
    ((210, 212, 220, 255), (170, 174, 186, 255), (240, 242, 250, 255), (255, 255, 255, 255)),
]

# Tipo de textura por bioma index → función render
# 0=LLANOS grass, 1=SIERRA grass, 2=DESIERTO sand, 3=BARRANCA rock,
# 4=MINERO rock, 5=RIO water, 6=MESA sand, 7=PICO snow


def render_grass(base, dark, light, accent, seed):
    """Grass: 4-6 hojas verticales pequeñas + micro-shading."""
    img = Image.new("RGBA", (T, T), base)
    px = img.load()
    r = random.Random(seed)
    # Micro-shading via sin/cos (variación tonal sutil base)
    for y in range(T):
        for x in range(T):
            t = math.sin(x * 0.4 + seed) * math.cos(y * 0.5 + seed * 1.3) * 0.5
            rr = max(0, min(255, int(base[0] + t * (dark[0] - base[0]) * 0.3)))
            gg = max(0, min(255, int(base[1] + t * (dark[1] - base[1]) * 0.3)))
            bb = max(0, min(255, int(base[2] + t * (dark[2] - base[2]) * 0.3)))
            px[x, y] = (rr, gg, bb, 255)
    # 4-6 hojitas verticales 2px de alto
    n_blades = r.randint(4, 6)
    for _ in range(n_blades):
        bx = r.randint(1, T - 2)
        by = r.randint(2, T - 3)
        col = dark if r.random() < 0.5 else light
        px[bx, by] = col
        px[bx, by + 1] = col
        # ocasional acento (flor o highlight)
        if r.random() < 0.25:
            px[bx, by - 1] = accent
    return img


def render_sand(base, dark, light, accent, seed):
    """Arena: micro-granos puntiformes y ondas suaves."""
    img = Image.new("RGBA", (T, T), base)
    px = img.load()
    r = random.Random(seed)
    # Ondas horizontales suaves
    for y in range(T):
        for x in range(T):
            t = math.sin(x * 0.3 + y * 0.15 + seed * 0.5) * 0.5
            rr = max(0, min(255, int(base[0] + t * (light[0] - base[0]) * 0.25)))
            gg = max(0, min(255, int(base[1] + t * (light[1] - base[1]) * 0.25)))
            bb = max(0, min(255, int(base[2] + t * (light[2] - base[2]) * 0.25)))
            px[x, y] = (rr, gg, bb, 255)
    # Granos sutiles dispersos
    for _ in range(6):
        gx = r.randint(0, T - 1)
        gy = r.randint(0, T - 1)
        px[gx, gy] = dark if r.random() < 0.5 else light
    return img


def render_rock(base, dark, light, accent, seed):
    """Roca: manchas (mottled) con varios tonos."""
    img = Image.new("RGBA", (T, T), base)
    px = img.load()
    r = random.Random(seed)
    # 6-10 manchas pequeñas
    n_spots = r.randint(6, 10)
    for _ in range(n_spots):
        sx = r.randint(0, T - 1)
        sy = r.randint(0, T - 1)
        sr = r.randint(0, 1)
        col = dark if r.random() < 0.6 else light
        for dy in range(-sr, sr + 1):
            for dx in range(-sr, sr + 1):
                xx = sx + dx
                yy = sy + dy
                if 0 <= xx < T and 0 <= yy < T:
                    px[xx, yy] = col
    return img


def render_water(base, dark, light, accent, seed):
    """Agua: ondas horizontales con highlights."""
    img = Image.new("RGBA", (T, T), base)
    px = img.load()
    r = random.Random(seed)
    for y in range(T):
        # tono según onda
        t = math.sin(y * 0.6 + seed) * 0.5
        for x in range(T):
            t2 = t + math.sin(x * 0.3 + y * 0.2) * 0.2
            rr = max(0, min(255, int(base[0] + t2 * (light[0] - base[0]) * 0.4)))
            gg = max(0, min(255, int(base[1] + t2 * (light[1] - base[1]) * 0.4)))
            bb = max(0, min(255, int(base[2] + t2 * (light[2] - base[2]) * 0.4)))
            px[x, y] = (rr, gg, bb, 255)
    # 2-3 highlights brillantes (reflejo)
    for _ in range(2):
        hy = r.randint(2, T - 3)
        hx = r.randint(2, T - 4)
        for dx in range(3):
            if hx + dx < T:
                px[hx + dx, hy] = accent
    return img


def render_snow(base, dark, light, accent, seed):
    """Nieve: textura muy clara con sombras suaves."""
    img = Image.new("RGBA", (T, T), base)
    px = img.load()
    r = random.Random(seed)
    for y in range(T):
        for x in range(T):
            t = math.sin(x * 0.5 + seed) * math.cos(y * 0.4) * 0.3
            rr = max(0, min(255, int(base[0] + t * (dark[0] - base[0]) * 0.3)))
            gg = max(0, min(255, int(base[1] + t * (dark[1] - base[1]) * 0.3)))
            bb = max(0, min(255, int(base[2] + t * (dark[2] - base[2]) * 0.3)))
            px[x, y] = (rr, gg, bb, 255)
    # Few brighter highlights
    for _ in range(3):
        gx = r.randint(0, T - 1)
        gy = r.randint(0, T - 1)
        px[gx, gy] = accent
    return img


RENDERERS = [render_grass, render_grass, render_sand, render_rock,
             render_rock, render_water, render_sand, render_snow]


# Layout: 8 cols (biomas) × 4 rows (variantes)
out = Image.new("RGBA", (T * N_BIOMES, T * N_VARIANTS), (0, 0, 0, 0))
for bi, (base, dark, light, accent) in enumerate(PALETTES):
    renderer = RENDERERS[bi]
    for vi in range(N_VARIANTS):
        seed = bi * 100 + vi * 17 + 3
        tile = renderer(base, dark, light, accent, seed)
        out.paste(tile, (bi * T, vi * T))

out.save(OUT)
out.resize((T * N_BIOMES * 8, T * N_VARIANTS * 8), Image.NEAREST).save(
    str(OUT).replace(".png", "_preview.png")
)
print(f"OK -> {OUT} ({T * N_BIOMES}x{T * N_VARIANTS}, {N_BIOMES} biomas × {N_VARIANTS} variantes)")
