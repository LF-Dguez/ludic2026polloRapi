from PIL import Image
from pathlib import Path

OUT = Path(__file__).parent

# Paleta simple estilo GameBoy
P = {
    "_": (0, 0, 0, 0),         # transparente
    "K": (15, 56, 15, 255),    # verde oscuro (outline)
    "G": (48, 98, 48, 255),    # verde medio
    "L": (139, 172, 15, 255),  # verde claro
    "W": (155, 188, 15, 255),  # verde lima (highlight)
}

# Sprite 16x16: una "babosa" pixel art como demo
ART = [
    "________________",
    "________________",
    "_____KKKKKK_____",
    "____KGGGGGGK____",
    "___KGLLLLLLGK___",
    "__KGLLLLLLLLGK__",
    "__KGLWLLLLWLGK__",
    "__KGLLLLLLLLGK__",
    "__KGLLKLLKLLGK__",
    "__KGLLLLLLLLGK__",
    "___KGLLLLLLGK___",
    "____KGGGGGGK____",
    "_____KKKKKK_____",
    "______K__K______",
    "________________",
    "________________",
]

def render(art, palette, scale=1):
    h = len(art); w = len(art[0])
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y, row in enumerate(art):
        for x, ch in enumerate(row):
            px[x, y] = palette[ch]
    if scale > 1:
        img = img.resize((w * scale, h * scale), Image.NEAREST)
    return img

# 1x (para el juego) y 8x (preview para que veas)
render(ART, P).save(OUT / "slime_16.png")
render(ART, P, scale=8).save(OUT / "slime_16_preview.png")
print("OK ->", OUT / "slime_16.png")
