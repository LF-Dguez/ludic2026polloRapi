"""Pancho Villa 64x64 — pixel art a mano, sin IA."""
from PIL import Image
from pathlib import Path

OUT = Path(__file__).parent
W = H = 64

P = {
    ".": (0, 0, 0, 0),
    "B": (20, 14, 10, 255),     # outline
    # sombrero
    "S": (150, 105, 60, 255),
    "s": (104, 70, 38, 255),
    "H": (188, 142, 88, 255),   # highlight
    "T": (110, 30, 30, 255),    # banda
    "t": (78, 18, 18, 255),
    # piel
    "F": (228, 188, 142, 255),
    "f": (180, 134, 92, 255),
    "h": (248, 212, 170, 255),
    # bigote / pelo
    "M": (38, 22, 14, 255),
    "m": (66, 40, 24, 255),
    # ojos
    "E": (250, 250, 240, 255),
    "e": (24, 18, 12, 255),
    # pañuelo
    "R": (172, 36, 36, 255),
    "r": (118, 22, 22, 255),
    # chaqueta
    "J": (114, 100, 64, 255),
    "j": (78, 68, 42, 255),
    "K": (146, 130, 86, 255),   # highlight
    # bandolera (cuero)
    "L": (70, 42, 24, 255),
    "l": (124, 82, 48, 255),
    # latón (balas/hebilla/botones)
    "Y": (220, 178, 70, 255),
    "y": (160, 124, 40, 255),
    # pantalón
    "P": (54, 40, 28, 255),
    "p": (34, 24, 16, 255),
    # botas
    "N": (24, 18, 14, 255),
    # revolver
    "G": (90, 90, 100, 255),    # acero
    "g": (60, 60, 70, 255),
    "W": (96, 56, 30, 255),     # cacha madera
}

# Cada fila se rellena con "." a 64. Espacios se tratan como "." también.
ROWS = [
    "",                                                                   # 0
    "",                                                                   # 1
    "                       sSSSSSSSSSSSSSs",                              # 2  hat top
    "                     sSSSHHHHHHHHHHHSSSs",                            # 3
    "                    sSSSHHHHHHHHHHHHHSSSs",                           # 4
    "                   sSSSHHHHHHHHHHHHHHHSSSs",                          # 5
    "                  sSSSSHHHHHHHHHHHHHHHSSSSs",                         # 6
    "                 sSSSSSHHHHHHHHHHHHHHHSSSSSs",                        # 7
    "                 sSSSSSSSSSSSSSSSSSSSSSSSSSs",                        # 8
    "                 sSSTTTTTTTTTTTTTTTTTTTTTSSs",                        # 9  banda
    "                 sSSttttttttttttttttttttSSSs",                        # 10
    "                 sSSSSSSSSSSSSSSSSSSSSSSSSSs",                        # 11
    "                sSSSSSSSSSSSSSSSSSSSSSSSSSSSs",                       # 12
    "               sSSSSSSSSSSSSSSSSSSSSSSSSSSSSSs",                      # 13
    "         sssssssSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSsssssss",               # 14 brim flare
    "       sSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSs",            # 15
    "     sSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSs",        # 16
    "   sSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSs",    # 17 widest
    "  sSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSs",   # 18
    " sBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBs",    # 19 brim bottom
    "",                                                                   # 20
    "                       fFFFFFFFFFFFFFf",                              # 21 face top
    "                      FFFFFFFFFFFFFFFFFF",                            # 22
    "                     FFFhhhhFFFFFFhhhhFFF",                           # 23
    "                     FFhhhhFFFFFFFFhhhhFF",                           # 24
    "                     FFhhEEFFFFFFFFEEhhFF",                           # 25 eyes shape
    "                     FFhEeEFFFFFFFFEeEhFF",                           # 26 pupils
    "                     FFhEEFFFFFFFFFFEEhFF",                           # 27
    "                     FFFFFFFFFhhFFFFFFFFF",                           # 28 nose hint
    "                     FFFFFFFFFhhFFFFFFFFF",                           # 29
    "                     FFFFFFFFFhhFFFFFFFFF",                           # 30
    "                    FFFmMMMMMMMMMMMMmFFF",                            # 31 stache root
    "                   FFmMMMMMMMMMMMMMMMMmFF",                           # 32
    "                  FmMMMMMMMMMMMMMMMMMMMMmF",                          # 33
    "                 FmMMMMMMMMMMMMMMMMMMMMMMm",                          # 34
    "                FmMMM     MMMM     MMMMMm",                          # 35 curl gap
    "                 mMM        MM        MMm",                          # 36
    "                       fFFFFFFFFFFFFFf",                              # 37 chin
    "                      fFFFFFFFFFFFFFFFf",                             # 38
    "                     RRRRRRRRRRRRRRRRRRR",                            # 39 scarf
    "                    RrrRRRRRRRRRRRRRRrrR",                           # 40
    "                   RrrrRRRRRRRRRRRRRRrrrR",                          # 41
    "                  JJJJrrRRRRRRRRRRRRrJJJJJ",                          # 42 collar
    "                 JJJJJJJJJJJJJJJJJJJJJJJJJJ",                         # 43 shoulders
    "                JJLLJJJJJJJJJJJJJJJJJJLLJJJ",                         # 44 bandolier X
    "               JJJlLLJJJJJJJJJJJJJJJJLLlJJJ",                         # 45
    "              JJJJJlLLJJJJJJJJJJJJJJLLlJJJJJ",                        # 46
    "              JJJJJJlLLJJJJJJJJJJJJLLlJJJJJJ",                        # 47
    "              JJJJJJJlLLJJJJJJJJJJLLlJJJJJJJ",                        # 48
    "              JJJJJJJJlLLJJJJJJJJLLlJJJJJJJJ",                        # 49
    "              JJJJJJJJJlLLJJJJJJLLlJJJJJJJJJ",                        # 50
    "              JJJJJJJJJJlLLYYYYLLlJJJbJJJJJJ",                        # 51 bullets center + button
    "              JJJJJJJJJJJlLYbYLlJJJJJbJJJJJJ",                        # 52
    "              JKJJJJJJJJJJlLLLlJJJJJJbJJJJJJ",                        # 53
    "              JKJJJJjjJJJJJJJJJJJJJJjjJJJJJJ",                        # 54 jacket bottom shadow
    "              JJJJJjjjjjjjjjjjjjjjjjjjjJJJJJ",                        # 55
    "              PPPPPPPPPPPPPPPPPPPPPPPPPPPP",                          # 56 belt
    "              PPPPPPPPPPYYYYYYYYPPPPPPPPPPP",                         # 57 buckle
    "              PPPPPPPPPPYbBBBBbYPPPPPPPPPPP",                         # 58
    "              PPPPPPPPPPPPPPPPPPPPGGGWWWWPP",                         # 59 holster + gun grip on hip
    "              PPPPPPPPPP    PPPPPPGGGWWWWPP",                         # 60 legs split, gun extends
    "              PPPPPPPPPP    PPPPPPPPPPPPPPP",                         # 61
    "              NNNNNNNNNN    NNNNNNNNNNNNNNN",                         # 62 boots
    "             NNNNNNNNNNNN  NNNNNNNNNNNNNNNN",                        # 63
]

def pad(row):
    row = row.replace(" ", ".")
    if len(row) < W:
        row += "." * (W - len(row))
    return row[:W]

art = [pad(r) for r in ROWS]
while len(art) < H:
    art.append("." * W)
art = art[:H]

for i, r in enumerate(art):
    assert len(r) == W, f"row {i} length {len(r)}"

def render(grid, palette, scale=1):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    for y, row in enumerate(grid):
        for x, ch in enumerate(row):
            px[x, y] = palette.get(ch, (0, 0, 0, 0))
    if scale > 1:
        img = img.resize((W * scale, H * scale), Image.NEAREST)
    return img

render(art, P).save(OUT / "pancho_villa_64.png")
render(art, P, scale=6).save(OUT / "pancho_villa_64_preview.png")
print("OK ->", OUT / "pancho_villa_64.png")
