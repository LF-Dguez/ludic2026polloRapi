"""Floor tiles + light texture. Floors LIMPIOS: solo color base con
micro-gradiente sutil (no dots aleatorios, no stripes artificiales).
"""
from PIL import Image
from pathlib import Path
import math

ROOT = Path(__file__).parent.parent
OUT = ROOT / "art" / "tiles"
OUT.mkdir(parents=True, exist_ok=True)

TRANS = (0, 0, 0, 0)


def smooth_floor(T, base, dark, light, variant_seed):
    """Genera floor con gradiente perlin-like sutil. Sin dots ni stripes."""
    img = Image.new("RGBA", (T, T), base)
    px = img.load()
    # Variación tonal usando función trig — suave, sin pattern visible al tilear
    phase_x = variant_seed * 0.7
    phase_y = variant_seed * 1.3
    amp_r = (dark[0] - base[0]) * 0.4
    amp_g = (dark[1] - base[1]) * 0.4
    amp_b = (dark[2] - base[2]) * 0.4
    for y in range(T):
        for x in range(T):
            # Suave variación con sin/cos — periodica pero no obvia al ojo
            t = math.sin(x * 0.3 + phase_x) * math.cos(y * 0.4 + phase_y)
            t += math.sin((x + y) * 0.2 + phase_x) * 0.5
            t *= 0.5  # normalizar [-0.75, 0.75]
            r = max(0, min(255, int(base[0] + t * amp_r)))
            g = max(0, min(255, int(base[1] + t * amp_g)))
            b = max(0, min(255, int(base[2] + t * amp_b)))
            px[x, y] = (r, g, b, 255)
    return img


def gen_cave_floor():
    """4 variantes 32x32 — tierra de cueva oscura, suave."""
    out = Image.new("RGBA", (32 * 4, 32), TRANS)
    palettes = [
        ((52, 42, 36, 255), (28, 22, 18, 255), (76, 64, 54, 255)),
        ((48, 40, 34, 255), (24, 20, 16, 255), (72, 60, 50, 255)),
        ((56, 46, 38, 255), (32, 24, 20, 255), (80, 66, 56, 255)),
        ((50, 40, 32, 255), (26, 20, 16, 255), (72, 58, 48, 255)),
    ]
    for i, (b, d, m) in enumerate(palettes):
        tile = smooth_floor(32, b, d, m, i * 7 + 3)
        out.paste(tile, (i * 32, 0))
    out.save(OUT / "cave_floor.png")
    print(f"OK: cave_floor.png ({out.size[0]}x{out.size[1]}, 4 variants, smooth)")


def gen_mine_floor():
    """4 variantes 32x32 — piso de mina: tierra oscura con tono cálido."""
    out = Image.new("RGBA", (32 * 4, 32), TRANS)
    palettes = [
        ((54, 42, 28, 255), (32, 24, 16, 255), (80, 60, 36, 255)),  # tierra cálida
        ((50, 38, 26, 255), (28, 20, 14, 255), (76, 56, 34, 255)),
        ((58, 46, 32, 255), (36, 26, 18, 255), (84, 64, 40, 255)),
        ((46, 36, 24, 255), (24, 18, 12, 255), (72, 54, 32, 255)),
    ]
    for i, (b, d, m) in enumerate(palettes):
        tile = smooth_floor(32, b, d, m, i * 11 + 5)
        out.paste(tile, (i * 32, 0))
    out.save(OUT / "mine_floor.png")
    print(f"OK: mine_floor.png ({out.size[0]}x{out.size[1]}, 4 variants, smooth, no stripes)")


def gen_paquime_floor():
    """4 variantes 16x16 — adobe interior cremoso."""
    out = Image.new("RGBA", (16 * 4, 16), TRANS)
    palettes = [
        ((192, 162, 118, 255), (148, 122, 88, 255), (216, 184, 140, 255)),
        ((184, 154, 110, 255), (140, 116, 80, 255), (208, 176, 132, 255)),
        ((200, 170, 124, 255), (156, 130, 96, 255), (224, 192, 148, 255)),
        ((188, 158, 114, 255), (144, 120, 84, 255), (212, 180, 136, 255)),
    ]
    for i, (b, d, m) in enumerate(palettes):
        tile = smooth_floor(16, b, d, m, i * 13 + 7)
        out.paste(tile, (i * 16, 0))
    out.save(OUT / "paquime_floor.png")
    print(f"OK: paquime_floor.png ({out.size[0]}x{out.size[1]}, 4 variants, smooth)")


def gen_light_texture():
    """Textura radial blanca para PointLight2D."""
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
                t = d / max_r
                a = int(255 * (1.0 - t * t))
                px[x, y] = (255, 255, 255, a)
    img.save(OUT / "light_texture.png")
    print(f"OK: light_texture.png ({T}x{T}) radial")


gen_cave_floor()
gen_mine_floor()
gen_paquime_floor()
gen_light_texture()
