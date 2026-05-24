"""Genera:
1. cave_floor.png — 4 variantes 32x32 de piso de cueva (tierra/grava)
2. mine_floor.png — 4 variantes 32x32 de piso de mina (madera/tierra)
3. paquime_floor.png — 4 variantes 16x16 de piso de adobe interior
4. light_texture.png — textura radial 256x256 para PointLight2D
"""
from PIL import Image, ImageDraw
from pathlib import Path
import random
import math

ROOT = Path(__file__).parent.parent
OUT = ROOT / "art" / "tiles"
OUT.mkdir(parents=True, exist_ok=True)

TRANS = (0, 0, 0, 0)


def base_dirt(T, base, dark, mid, seed):
    """Piso de tierra con grava."""
    img = Image.new("RGBA", (T, T), base)
    px = img.load()
    r = random.Random(seed)
    # Grava
    for _ in range(T * T // 8):
        x = r.randrange(T); y = r.randrange(T)
        px[x, y] = dark
    # Highlight
    for _ in range(T * T // 16):
        x = r.randrange(T); y = r.randrange(T)
        px[x, y] = mid
    # Algunas piedritas
    for _ in range(3):
        cx = r.randrange(4, T - 4); cy = r.randrange(4, T - 4)
        radius = r.randrange(1, 3)
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if dx * dx + dy * dy <= radius * radius:
                    px[cx + dx, cy + dy] = dark
    return img


def gen_cave_floor():
    """4 variantes 32x32 de tierra/grava de cueva."""
    out = Image.new("RGBA", (32 * 4, 32), TRANS)
    palettes = [
        ((52, 42, 36, 255), (28, 22, 18, 255), (76, 64, 54, 255)),  # tierra oscura
        ((48, 40, 34, 255), (24, 20, 16, 255), (72, 60, 50, 255)),
        ((56, 46, 38, 255), (32, 24, 20, 255), (80, 66, 56, 255)),
        ((50, 40, 32, 255), (26, 20, 16, 255), (72, 58, 48, 255)),
    ]
    for i, (b, d, m) in enumerate(palettes):
        tile = base_dirt(32, b, d, m, 100 + i)
        out.paste(tile, (i * 32, 0))
    out.save(OUT / "cave_floor.png")
    print(f"OK: cave_floor.png ({out.size[0]}x{out.size[1]}, 4 variants)")


def gen_mine_floor():
    """4 variantes 32x32 de piso de mina (tablones + tierra)."""
    out = Image.new("RGBA", (32 * 4, 32), TRANS)
    palettes = [
        ((60, 44, 28, 255), (40, 28, 18, 255), (80, 60, 38, 255)),  # tablones marrón
        ((54, 42, 30, 255), (32, 24, 16, 255), (76, 58, 38, 255)),
        ((48, 40, 32, 255), (28, 22, 18, 255), (72, 60, 48, 255)),  # tierra mina
        ((44, 36, 28, 255), (24, 18, 14, 255), (68, 56, 44, 255)),
    ]
    for i, (b, d, m) in enumerate(palettes):
        tile = base_dirt(32, b, d, m, 200 + i)
        # Agrega líneas horizontales para sugerir tablones (en los primeros 2)
        if i < 2:
            px = tile.load()
            for x in range(32):
                px[x, 0] = d
                px[x, 16] = d
                px[x, 31] = d
        out.paste(tile, (i * 32, 0))
    out.save(OUT / "mine_floor.png")
    print(f"OK: mine_floor.png ({out.size[0]}x{out.size[1]}, 4 variants)")


def gen_paquime_floor():
    """4 variantes 16x16 de piso adobe interior."""
    out = Image.new("RGBA", (16 * 4, 16), TRANS)
    palettes = [
        ((180, 152, 110, 255), (140, 116, 84, 255), (208, 178, 134, 255)),  # adobe claro
        ((172, 144, 102, 255), (130, 108, 76, 255), (200, 170, 128, 255)),
        ((188, 158, 116, 255), (148, 122, 88, 255), (216, 184, 140, 255)),
        ((176, 148, 106, 255), (134, 112, 80, 255), (204, 174, 130, 255)),
    ]
    for i, (b, d, m) in enumerate(palettes):
        tile = base_dirt(16, b, d, m, 300 + i)
        out.paste(tile, (i * 16, 0))
    out.save(OUT / "paquime_floor.png")
    print(f"OK: paquime_floor.png ({out.size[0]}x{out.size[1]}, 4 variants)")


def gen_light_texture():
    """Textura radial blanca para PointLight2D — degradado suave."""
    T = 256
    img = Image.new("RGBA", (T, T), TRANS)
    px = img.load()
    cx, cy = T / 2, T / 2
    max_r = T / 2
    for y in range(T):
        for x in range(T):
            dx = x - cx
            dy = y - cy
            d = math.sqrt(dx * dx + dy * dy)
            if d >= max_r:
                px[x, y] = (255, 255, 255, 0)
            else:
                # Falloff cuadrático suave
                t = d / max_r
                a = int(255 * (1.0 - t * t))
                px[x, y] = (255, 255, 255, a)
    img.save(OUT / "light_texture.png")
    print(f"OK: light_texture.png ({T}x{T}) radial")


gen_cave_floor()
gen_mine_floor()
gen_paquime_floor()
gen_light_texture()
