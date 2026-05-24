"""Atlas de tiles 16x16 para INTERIOR de mazmorra Paquimé.
4x4 = 16 tiles, atlas final 64x64.
"""
from PIL import Image
from pathlib import Path
import random

ROOT = Path(__file__).parent.parent
OUT = ROOT / "art" / "tiles"
OUT.mkdir(parents=True, exist_ok=True)

T = 16
COLS, ROWS = 4, 4
W, H = COLS * T, ROWS * T

# Paleta Paquimé
PQ_SAND = (201, 165, 116, 255); PQ_SAND_D = (170, 134, 88, 255)
PQ_WALL = (138, 94, 59, 255); PQ_WALL_L = (172, 124, 84, 255); PQ_WALL_D = (88, 56, 32, 255)
PQ_CREAM = (232, 216, 168, 255)
PQ_BALL = (170, 128, 76, 255)
PQ_RED = (170, 36, 36, 255); PQ_BLACK = (28, 20, 14, 255)
PQ_WATER = (58, 110, 140, 255); PQ_WATER_L = (96, 158, 188, 255)
PQ_COPPER = (180, 92, 36, 255); PQ_COPPER_D = (118, 56, 16, 255)
PQ_M_R = (190, 40, 40, 255); PQ_M_B = (40, 88, 168, 255); PQ_M_Y = (220, 184, 60, 255); PQ_M_G = (48, 132, 56, 255)
PQ_STONE = (108, 100, 92, 255); PQ_STONE_D = (72, 64, 56, 255)
PQ_LADDER = (124, 84, 44, 255); PQ_HOLE = (24, 18, 12, 255)
PQ_POT_BUFF = (224, 200, 152, 255); PQ_POT_R = (162, 56, 40, 255); PQ_POT_K = (32, 24, 18, 255)
TRANS = (0, 0, 0, 0)

img = Image.new("RGBA", (W, H), TRANS)


def fill(px, c, x0=0, y0=0, x1=T, y1=T):
    for x in range(x0, x1):
        for y in range(y0, y1):
            px[x, y] = c


def dot(px, x, y, c):
    if 0 <= x < T and 0 <= y < T:
        px[x, y] = c


def speckle(px, n, color, seed):
    r = random.Random(seed)
    for _ in range(n):
        dot(px, r.randrange(T), r.randrange(T), color)


def make(painter):
    s = Image.new("RGBA", (T, T), TRANS)
    painter(s.load())
    return s


def put(cx, cy, sub):
    img.paste(sub, (cx * T, cy * T))


# Row 0: VOID, FLOOR, WALL, DOOR
put(0, 0, make(lambda px: None))

def paq_floor(px):
    fill(px, PQ_SAND)
    speckle(px, 6, PQ_SAND_D, 11)
put(1, 0, make(paq_floor))

def paq_wall(px):
    fill(px, PQ_WALL)
    for x in range(T): px[x, 0] = PQ_WALL_D; px[x, 8] = PQ_WALL_D
    for y in range(1, 8): px[0, y] = PQ_WALL_D; px[8, y] = PQ_WALL_D
    for y in range(9, T): px[4, y] = PQ_WALL_D; px[12, y] = PQ_WALL_D
    for x in range(1, 8): px[x, 1] = PQ_WALL_L
    for x in range(9, T): px[x, 1] = PQ_WALL_L
    for x in range(5, 12): px[x, 9] = PQ_WALL_L
    for x in range(13, T): px[x, 9] = PQ_WALL_L
put(2, 0, make(paq_wall))

def paq_door(px):
    fill(px, PQ_SAND)
    for x in range(2, 14):
        for y in range(1, 9):
            px[x, y] = PQ_HOLE
    for x in range(5, 11):
        for y in range(9, T):
            px[x, y] = PQ_HOLE
    frame = (94, 60, 36, 255)
    for x in range(2, 14): px[x, 0] = frame
    for y in range(1, 9):
        px[1, y] = frame; px[14, y] = frame
    for x in [2, 3, 4]: px[x, 9] = frame
    for x in [11, 12, 13]: px[x, 9] = frame
    for y in range(10, T):
        px[4, y] = frame; px[11, y] = frame
put(3, 0, make(paq_door))

# Row 1: PLAZA_FLOOR, MACAW, WORKSHOP, WATER
def paq_plaza(px):
    fill(px, PQ_CREAM)
    cx, cy = 8, 8
    px[cx, cy - 3] = PQ_RED; px[cx, cy + 3] = PQ_RED
    px[cx - 3, cy] = PQ_RED; px[cx + 3, cy] = PQ_RED
    px[cx - 2, cy - 1] = PQ_BLACK; px[cx + 2, cy - 1] = PQ_BLACK
    px[cx - 2, cy + 1] = PQ_BLACK; px[cx + 2, cy + 1] = PQ_BLACK
    px[cx - 1, cy - 2] = PQ_BLACK; px[cx + 1, cy - 2] = PQ_BLACK
    px[cx - 1, cy + 2] = PQ_BLACK; px[cx + 1, cy + 2] = PQ_BLACK
    px[cx, cy] = PQ_RED
    for (qx, qy) in [(2, 2), (13, 2), (2, 13), (13, 13)]:
        px[qx, qy] = PQ_BLACK
put(0, 1, make(paq_plaza))

def paq_macaw(px):
    fill(px, PQ_SAND)
    nest = (98, 68, 38, 255)
    for x in range(4, 12):
        for y in range(5, 12):
            d2 = (x - 7.5) ** 2 + (y - 8.5) ** 2
            if 3 <= d2 <= 18:
                px[x, y] = nest
    px[6, 6] = PQ_M_R; px[7, 5] = PQ_M_R
    px[10, 7] = PQ_M_B; px[9, 6] = PQ_M_B
    px[8, 9] = PQ_M_Y; px[7, 10] = PQ_M_Y
    px[9, 10] = PQ_M_G
put(1, 1, make(paq_macaw))

def paq_workshop(px):
    fill(px, PQ_SAND)
    for x in range(4, 12):
        for y in range(5, 13):
            px[x, y] = PQ_COPPER_D
    for x in range(6, 10):
        for y in range(8, 12):
            px[x, y] = PQ_COPPER
    px[7, 9] = PQ_M_Y; px[8, 10] = PQ_M_Y
    px[8, 3] = PQ_STONE_D; px[8, 4] = PQ_STONE_D
put(2, 1, make(paq_workshop))

def paq_water(px):
    fill(px, PQ_WATER)
    for x in range(0, T, 4):
        px[x, 4] = PQ_WATER_L; px[x + 1, 4] = PQ_WATER_L
        px[(x + 2) % T, 10] = PQ_WATER_L; px[(x + 3) % T, 10] = PQ_WATER_L
put(3, 1, make(paq_water))

# Row 2: EFFIGY_CROSS, EFFIGY_BIRD, EFFIGY_SERPENT, BALL_FLOOR
def stone_base(px):
    for x in range(3, 13):
        for y in range(3, 13):
            px[x, y] = PQ_STONE
    for x in range(3, 13):
        px[x, 3] = PQ_STONE_D; px[x, 12] = PQ_STONE_D
    for y in range(3, 13):
        px[3, y] = PQ_STONE_D; px[12, y] = PQ_STONE_D

def paq_effigy_cross(px):
    fill(px, PQ_SAND); stone_base(px)
    for y in range(5, 11):
        px[7, y] = PQ_BLACK; px[8, y] = PQ_BLACK
    for x in range(5, 11):
        px[x, 7] = PQ_BLACK; px[x, 8] = PQ_BLACK
put(0, 2, make(paq_effigy_cross))

def paq_effigy_bird(px):
    fill(px, PQ_SAND); stone_base(px)
    bird = PQ_BLACK
    for x in range(6, 10): px[x, 9] = bird; px[x, 10] = bird
    px[10, 7] = bird; px[11, 7] = bird
    px[10, 8] = bird; px[11, 8] = bird
    px[12, 8] = PQ_M_Y
    px[6, 8] = bird; px[7, 8] = bird; px[5, 9] = bird; px[5, 10] = bird
    px[11, 7] = PQ_M_R
put(1, 2, make(paq_effigy_bird))

def paq_effigy_serpent(px):
    fill(px, PQ_SAND); stone_base(px)
    pts = [(5, 6), (6, 6), (7, 7), (8, 7), (8, 8), (9, 9), (10, 9),
           (11, 10), (10, 11), (9, 11), (8, 10), (7, 10), (6, 10), (5, 10)]
    for (x, y) in pts: px[x, y] = PQ_BLACK
    px[5, 5] = PQ_M_R; px[6, 5] = PQ_M_R
put(2, 2, make(paq_effigy_serpent))

def paq_ball(px):
    fill(px, PQ_BALL)
    for x in range(T): px[x, 7] = PQ_BLACK; px[x, 8] = PQ_BLACK
    for cx in [4, 12]:
        px[cx, 3] = PQ_BLACK; px[cx, 12] = PQ_BLACK
put(3, 2, make(paq_ball))

# Row 3: ENTRANCE, EXIT, POT, RESERVED
def paq_entrance(px):
    fill(px, PQ_SAND)
    for x in range(3, 13):
        for y in range(3, 13):
            px[x, y] = (60, 44, 28, 255)
    for y in [4, 7, 10]:
        for x in range(5, 11): px[x, y] = PQ_M_Y
put(0, 3, make(paq_entrance))

def paq_exit(px):
    fill(px, PQ_SAND)
    for x in range(3, 13):
        for y in range(3, 13):
            px[x, y] = PQ_HOLE
    for y in [5, 8, 11]:
        for x in range(5, 11): px[x, y] = PQ_LADDER
    px[8, 8] = PQ_RED
put(1, 3, make(paq_exit))

def paq_pot(px):
    fill(px, PQ_SAND)
    for x in range(4, 12):
        for y in range(5, 13):
            d2 = (x - 7.5) ** 2 + ((y - 9) * 1.2) ** 2
            if d2 <= 16:
                px[x, y] = PQ_POT_BUFF
    for x in range(6, 10): px[x, 4] = PQ_POT_BUFF
    px[5, 8] = PQ_POT_K; px[6, 7] = PQ_POT_K; px[7, 8] = PQ_POT_K
    px[8, 7] = PQ_POT_K; px[9, 8] = PQ_POT_K; px[10, 7] = PQ_POT_K
    px[6, 10] = PQ_POT_R; px[9, 10] = PQ_POT_R
put(2, 3, make(paq_pot))

put(3, 3, make(lambda px: None))

img.save(OUT / "paquime_tiles.png")
img.resize((W * 6, H * 6), Image.NEAREST).save(OUT / "paquime_tiles_preview.png")
print(f"OK -> {OUT / 'paquime_tiles.png'} ({W}x{H}, {COLS*ROWS} tiles)")
