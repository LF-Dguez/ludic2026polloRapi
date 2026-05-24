"""Genera tiles de BASE de bioma — colores sólidos suaves con gradiente perlin-like.
NO scallops, NO dots aleatorios, NO patterns visibles al tilear.

Output: art/tiles/biome_bases.png — 8x1 atlas de 16x16:
0=LLANOS, 1=SIERRA, 2=DESIERTO, 3=BARRANCA, 4=MINERO, 5=RIO, 6=MESA, 7=PICO
"""
from PIL import Image
from pathlib import Path
import math

ROOT = Path(__file__).parent.parent
OUT = ROOT / "art" / "tiles" / "biome_bases.png"

T = 16


def smooth_tile(base, dark, light, seed):
    """Tile con micro-gradient sin patrones visibles al tilear."""
    img = Image.new("RGBA", (T, T), base)
    px = img.load()
    phase_x = seed * 0.7
    phase_y = seed * 1.3
    amp_r = (dark[0] - base[0]) * 0.35
    amp_g = (dark[1] - base[1]) * 0.35
    amp_b = (dark[2] - base[2]) * 0.35
    for y in range(T):
        for x in range(T):
            t = math.sin(x * 0.35 + phase_x) * math.cos(y * 0.45 + phase_y)
            t += math.sin((x + y) * 0.22 + phase_x) * 0.4
            t *= 0.5
            r = max(0, min(255, int(base[0] + t * amp_r)))
            g = max(0, min(255, int(base[1] + t * amp_g)))
            b = max(0, min(255, int(base[2] + t * amp_b)))
            px[x, y] = (r, g, b, 255)
    return img


# Paletas inspiradas en Chihuahua real, desaturadas/tétricas
BIOMES = [
    # (name, base, dark, light)
    ("LLANOS",    (124, 138, 78, 255),  (86, 100, 54, 255),   (160, 170, 100, 255)),  # pastizal seco
    ("SIERRA",    (64, 96, 56, 255),    (38, 62, 36, 255),    (96, 130, 78, 255)),    # bosque pino verde oscuro
    ("DESIERTO",  (172, 138, 88, 255),  (130, 102, 64, 255),  (208, 174, 124, 255)),  # arena dorada
    ("BARRANCA",  (60, 48, 38, 255),    (32, 24, 18, 255),    (88, 70, 52, 255)),     # cañón profundo casi negro
    ("MINERO",    (78, 64, 50, 255),    (48, 38, 28, 255),    (108, 90, 70, 255)),    # tierra minera
    ("RIO",       (52, 100, 132, 255),  (32, 68, 96, 255),    (88, 138, 168, 255)),   # agua azul
    ("MESA",      (148, 116, 72, 255),  (108, 84, 50, 255),   (184, 148, 98, 255)),   # meseta tan
    ("PICO",      (212, 212, 222, 255), (170, 174, 188, 255), (240, 240, 248, 255)),  # nieve/piedra alta
]

out = Image.new("RGBA", (T * len(BIOMES), T), (0, 0, 0, 0))
for i, (name, base, dark, light) in enumerate(BIOMES):
    tile = smooth_tile(base, dark, light, i * 17 + 3)
    out.paste(tile, (i * T, 0))
    print(f"  {i} {name}: base={base[:3]}")

out.save(OUT)
out.resize((T * len(BIOMES) * 8, T * 8), Image.NEAREST).save(
    str(OUT).replace(".png", "_preview.png")
)
print(f"OK -> {OUT} ({T * len(BIOMES)}x{T}, {len(BIOMES)} biomas)")
