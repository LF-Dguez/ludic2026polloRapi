"""Pancho Villa pixel sprite 32x32, no AI, pixel-por-pixel."""
from PIL import Image
from pathlib import Path

OUT = Path(__file__).parent

# Paleta
P = {
    ".": (0, 0, 0, 0),          # transparente
    "B": (24, 16, 16, 255),     # outline negro/marron oscuro
    "S": (140, 100, 60, 255),   # sombrero marron claro
    "s": (96, 64, 36, 255),     # sombra sombrero
    "T": (180, 140, 80, 255),   # banda del sombrero (highlight)
    "F": (224, 184, 140, 255),  # piel
    "f": (176, 132, 92, 255),   # sombra piel
    "M": (40, 24, 16, 255),     # bigote (negro-cafe)
    "E": (255, 255, 255, 255),  # blanco de ojos
    "e": (32, 24, 16, 255),     # pupila
    "J": (108, 96, 64, 255),    # chaqueta caqui
    "j": (76, 68, 44, 255),     # sombra chaqueta
    "L": (72, 44, 28, 255),     # cuero bandolera
    "l": (132, 88, 52, 255),    # highlight cuero
    "Y": (212, 172, 64, 255),   # latón balas
    "P": (60, 44, 32, 255),     # pantalon
    "p": (40, 28, 20, 255),     # sombra pantalon
    "R": (160, 32, 32, 255),    # pañuelo rojo (cuello)
}

# Diseño: 32 cols x 32 rows.  Rellenamos a 32 con "." si me quedo corto.
ROWS_RAW = [
    "",                                                              # 0
    "             sssssss",                                          # 1 hat top
    "            sSSSSSSSs",                                         # 2
    "           sSSSSSSSSSs",                                        # 3
    "           sSSSTTTSSSs",                                        # 4 banda
    "          sSSSTTTTTSSSs",                                       # 5
    "          sSSSSSSSSSSSs",                                       # 6
    "      sssssSSSSSSSSSSSsssss",                                   # 7 brim flare
    "    sSSSSSSSSSSSSSSSSSSSSSSSSs",                                # 8 brim
    "  sSSSSSSSSSSSSSSSSSSSSSSSSSSSSs",                              # 9 widest brim
    " BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB ",                              # 10 brim shadow
    "            FFFFFFFF",                                          # 11 face top
    "           FFFFFFFFFF",                                         # 12
    "           FeEFFFFEeF",                                         # 13 eyes
    "           FFFFFFFFFF",                                         # 14
    "           FFMMMMMMFF",                                         # 15 mustache root
    "          MMMMMMMMMMMM",                                        # 16 big stache
    "          MMMMMMMMMMMM",                                        # 17
    "           FFFFFFFFFF",                                         # 18 chin
    "          RRRRRRRRRRRR",                                        # 19 red scarf
    "         JJJJJRRRRJJJJJ",                                       # 20 shoulders + scarf
    "        JJLLJJJJJJJJLLJJ",                                      # 21 bandolier X start
    "       JJJLLJJJJJJJJLLJJJ",                                     # 22
    "       JJJJLLJJJJJJLLJJJJ",                                     # 23
    "       JJJJJLLJJJJLLJJJJJ",                                     # 24
    "       JJJJJJLLJJLLJJJJJJ",                                     # 25
    "       JJJJJJJLLLLJJJJJJJ",                                     # 26
    "       JJJJJJJYYYYJJJJJJJ",                                     # 27 bullets center
    "       PPPPPPPPPPPPPPPPPP",                                     # 28 belt/pants
    "       PPPPPPPPPPPPPPPPPP",                                     # 29
    "       PPPPPP    PPPPPPPP",                                     # 30 legs split
    "       BBBBBB    BBBBBBBB",                                     # 31 boots
]

W, H = 32, 32

def pad(row):
    row = row.replace(" ", ".")
    if len(row) < W:
        row = row + "." * (W - len(row))
    return row[:W]

art = [pad(r) for r in ROWS_RAW]
while len(art) < H:
    art.append("." * W)
art = art[:H]

# Sanity check
for i, r in enumerate(art):
    assert len(r) == W, f"row {i} len {len(r)}"

def render(grid, palette, scale=1):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    for y, row in enumerate(grid):
        for x, ch in enumerate(row):
            px[x, y] = palette.get(ch, (0, 0, 0, 0))
    if scale > 1:
        img = img.resize((W * scale, H * scale), Image.NEAREST)
    return img

render(art, P).save(OUT / "pancho_villa.png")
render(art, P, scale=10).save(OUT / "pancho_villa_preview.png")
print("OK ->", OUT / "pancho_villa.png")
