"""Atlas overworld TÉTRICO — paleta desaturada, 8x6 = 48 tiles, atlas 128x96.

Bioma + variantes atmosféricas + POIs + entradas + componentes para stamps multi-tile.
"""
from PIL import Image
from pathlib import Path
import random

ROOT = Path(__file__).parent.parent
OUT = ROOT / "art" / "tiles"
OUT.mkdir(parents=True, exist_ok=True)

T = 16
COLS, ROWS = 8, 6
W, H = COLS * T, ROWS * T

TRANS = (0, 0, 0, 0)

# --- Paleta tétrica chihuahuense ---
D_BASE = (148, 118, 82, 255); D_DARK = (108, 84, 56, 255); D_LIGHT = (172, 142, 102, 255)
D_DUST = (92, 72, 50, 255)
SOTOL_G = (84, 100, 58, 255); SOTOL_D = (52, 64, 36, 255)
LECH_G = (96, 116, 80, 255); LECH_TIP = (162, 144, 72, 255)
BONE = (218, 208, 184, 255); BONE_D = (152, 142, 120, 255); BONE_K = (40, 30, 22, 255)
L_BASE = (124, 112, 72, 255); L_DARK = (88, 80, 52, 255); L_LIGHT = (152, 140, 96, 255)
L_GRASS = (108, 100, 60, 255); L_GRASS_D = (78, 72, 44, 255)
MEZQ_G = (62, 76, 42, 255); MEZQ_D = (40, 50, 28, 255); MEZQ_TRUNK = (50, 36, 22, 255)
S_FLOOR = (50, 64, 42, 255); S_FLOOR_D = (32, 42, 28, 255); S_FLOOR_L = (68, 84, 56, 255)
PINE_G = (20, 56, 34, 255); PINE_D = (12, 36, 22, 255); PINE_L = (32, 76, 46, 255)
PINE_DEAD = (76, 60, 42, 255); PINE_DEAD_D = (48, 38, 28, 255)
TRUNK = (44, 28, 16, 255)
ROCK = (76, 70, 64, 255); ROCK_D = (48, 44, 40, 255); ROCK_MOSS = (52, 72, 48, 255)
DEAD_TREE = (24, 18, 14, 255); DEAD_BR = (52, 38, 28, 255)
B_EDGE = (98, 70, 46, 255); B_EDGE_D = (66, 46, 28, 255); B_EDGE_L = (124, 92, 60, 255)
CHASM = (10, 8, 8, 255); CHASM_D = (4, 4, 4, 255)
BRIDGE_W = (68, 48, 30, 255); BRIDGE_R = (152, 132, 80, 255)
M_BASE = (62, 56, 52, 255); M_DARK = (38, 34, 32, 255); M_LIGHT = (88, 80, 72, 255)
M_RUST = (132, 64, 32, 255); M_RUST_D = (88, 40, 18, 255)
M_RAIL = (108, 92, 84, 255); M_CART = (40, 26, 20, 255); M_CART_R = (140, 80, 40, 255)
R_BASE = (42, 78, 100, 255); R_LIGHT = (78, 122, 144, 255); R_DEEP = (24, 50, 72, 255)
R_BANK = (132, 110, 80, 255)
PATH_BASE = (118, 96, 68, 255); PATH_DARK = (86, 68, 48, 255); PATH_STONE = (90, 82, 74, 255)
MO_GROUND = (132, 108, 78, 255)
MO_ROOF = (118, 56, 36, 255); MO_ROOF_D = (74, 32, 18, 255)
MO_WALL = (168, 142, 104, 255); MO_WALL_D = (122, 100, 70, 255)
MO_POT_R = (132, 44, 32, 255); MO_DOOR = (30, 22, 16, 255)
MJ_GROUND = (138, 116, 86, 255)
MJ_WALL = (180, 168, 138, 255); MJ_WALL_D = (134, 124, 100, 255)
MJ_DOME = (120, 88, 60, 255)
MJ_CROSS = (30, 22, 16, 255)
CEM_GROUND = (88, 78, 58, 255); CEM_GROUND_D = (60, 54, 40, 255)
CEM_CROSS = (212, 200, 172, 255); CEM_CROSS_D = (148, 136, 112, 255)
EP_GROUND = (134, 102, 64, 255); EP_WALL = (94, 64, 38, 255); EP_HOLE = (8, 6, 4, 255)
ET_GROUND = (52, 62, 44, 255); ET_ROCK = (66, 58, 50, 255); ET_HOLE = (4, 4, 4, 255)
ET_SKULL = (190, 178, 154, 255)
EN_GROUND = (54, 48, 46, 255); EN_FRAME = (118, 50, 22, 255); EN_HOLE = (6, 4, 8, 255)
EN_CRYST = (180, 220, 240, 255); EN_CRYST_GLOW = (220, 240, 255, 255)
# Row 4 nuevos
ADO_WALL = (138, 94, 59, 255); ADO_WALL_D = (88, 56, 32, 255); ADO_WALL_L = (172, 124, 84, 255)
CREAM = (200, 178, 132, 255); CREAM_D = (156, 134, 96, 255)
DIRT = (104, 80, 54, 255); DIRT_D = (74, 56, 36, 255)
CAVE_ROCK = (58, 50, 44, 255); CAVE_ROCK_D = (34, 28, 24, 255); CAVE_ROCK_L = (82, 72, 64, 255)
CAVE_DARK = (6, 4, 4, 255)
WOOD_F = (88, 56, 28, 255); WOOD_F_D = (54, 32, 14, 255); WOOD_F_L = (124, 86, 48, 255)
RAIL_M = (104, 96, 88, 255); RAIL_D = (70, 64, 56, 255); RAIL_TIE = (56, 38, 22, 255)
MESA_TOP = (158, 132, 92, 255); MESA_EDGE = (108, 84, 54, 255); MESA_SHADOW = (74, 56, 34, 255)
# Row 5
PICO_R = (84, 80, 76, 255); PICO_SNOW = (220, 220, 232, 255); PICO_SHADOW = (52, 50, 48, 255)
CARDON_G = (62, 92, 62, 255); CARDON_D = (40, 64, 42, 255); CARDON_SP = (220, 200, 130, 255)
RANCHO_BURN = (28, 20, 16, 255); RANCHO_WOOD = (72, 50, 32, 255)
FENCE_W = (84, 62, 38, 255); FENCE_WIRE = (108, 96, 76, 255)
FOG = (140, 138, 130, 255); FOG_D = (108, 106, 100, 255)
CHARCO_W = (50, 88, 110, 255); CHARCO_L = (90, 138, 160, 255); CHARCO_BANK = (118, 96, 64, 255)
TRACKS = (60, 44, 28, 255)
MONOLITO_R = (66, 60, 54, 255); MONOLITO_D = (38, 34, 30, 255); MONOLITO_L = (88, 80, 72, 255)


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


def base_desert(px, seed=100):
    fill(px, D_BASE)
    speckle(px, 14, D_DARK, seed)
    speckle(px, 6, D_LIGHT, seed + 1)
    speckle(px, 4, D_DUST, seed + 2)


def base_llanos(px, seed=200):
    fill(px, L_BASE)
    speckle(px, 18, L_DARK, seed)
    speckle(px, 8, L_LIGHT, seed + 1)
    speckle(px, 6, L_GRASS, seed + 2)


def base_sierra(px, seed=300):
    fill(px, S_FLOOR)
    speckle(px, 16, S_FLOOR_D, seed)
    speckle(px, 6, S_FLOOR_L, seed + 1)


def base_minero(px, seed=400):
    fill(px, M_BASE)
    speckle(px, 18, M_DARK, seed)
    speckle(px, 8, M_LIGHT, seed + 1)
    speckle(px, 4, M_RUST_D, seed + 2)


def make(painter):
    s = Image.new("RGBA", (T, T), TRANS)
    painter(s.load())
    return s


def put(cx, cy, sub):
    img.paste(sub, (cx * T, cy * T))


# ============ ROW 0: Desierto + variantes ============
put(0, 0, make(lambda px: None))
put(1, 0, make(lambda px: base_desert(px, 101)))

def des_sotol(px):
    base_desert(px, 102)
    cx, cy = 8, 10
    for (dx, dy) in [(-2, 0), (-1, -1), (0, -2), (1, -1), (2, 0), (1, 1), (0, 2), (-1, 1)]:
        dot(px, cx + dx, cy + dy, SOTOL_G)
    for (dx, dy) in [(-1, 0), (0, -1), (1, 0), (0, 1)]:
        dot(px, cx + dx, cy + dy, SOTOL_D)
    dot(px, cx, cy - 3, SOTOL_D); dot(px, cx, cy - 4, SOTOL_D); dot(px, cx, cy - 5, BONE_D)
put(2, 0, make(des_sotol))

def des_lechuguilla(px):
    base_desert(px, 103)
    cx, cy = 8, 9
    for (dx, dy) in [(-3, 0), (-2, -1), (-1, -2), (0, -3), (1, -2), (2, -1), (3, 0),
                      (2, 1), (1, 2), (0, 3), (-1, 2), (-2, 1)]:
        dot(px, cx + dx, cy + dy, LECH_G)
    dot(px, cx, cy, LECH_TIP)
put(3, 0, make(des_lechuguilla))

def des_calavera(px):
    base_desert(px, 104)
    cx, cy = 7, 9
    dot(px, cx - 3, cy - 2, BONE); dot(px, cx - 4, cy - 2, BONE); dot(px, cx - 4, cy - 1, BONE_D)
    dot(px, cx + 3, cy - 2, BONE); dot(px, cx + 4, cy - 2, BONE); dot(px, cx + 4, cy - 1, BONE_D)
    for x in range(cx - 2, cx + 3):
        for y in range(cy - 1, cy + 3):
            d2 = (x - cx) ** 2 + ((y - cy - 0.5) * 0.9) ** 2
            if d2 <= 5:
                dot(px, x, y, BONE)
    dot(px, cx - 1, cy, BONE_K); dot(px, cx + 1, cy, BONE_K)
    dot(px, cx - 1, cy + 2, BONE_D); dot(px, cx, cy + 2, BONE_D); dot(px, cx + 1, cy + 2, BONE_D)
put(4, 0, make(des_calavera))

def des_roca(px):
    base_desert(px, 105)
    for x in range(4, 13):
        for y in range(6, 13):
            d2 = (x - 8) ** 2 + ((y - 10) * 1.1) ** 2
            if d2 <= 18:
                px[x, y] = ROCK
            if 18 < d2 <= 24:
                px[x, y] = ROCK_D
    dot(px, 7, 7, ROCK_MOSS); dot(px, 8, 6, ROCK_MOSS); dot(px, 6, 8, ROCK_MOSS)
put(5, 0, make(des_roca))

def des_cactus_muerto(px):
    base_desert(px, 106)
    cx = 8
    for y in range(4, 14):
        px[cx, y] = DEAD_TREE
        px[cx + 1, y] = DEAD_BR
    for y in range(7, 11):
        px[cx - 2, y] = DEAD_TREE
    px[cx - 1, 7] = DEAD_TREE; px[cx - 2, 6] = DEAD_TREE
    px[cx + 2, 9] = DEAD_TREE; px[cx + 3, 9] = DEAD_TREE
    dot(px, cx - 3, 13, DEAD_BR); dot(px, cx + 4, 13, DEAD_BR)
put(6, 0, make(des_cactus_muerto))

def des_huesos(px):
    base_desert(px, 107)
    for (x, y) in [(4, 9), (5, 8), (6, 8), (7, 9), (8, 8), (9, 8), (10, 9)]:
        px[x, y] = BONE
    for x in range(4, 11):
        if 4 <= x <= 10 and px[x, 10] != BONE:
            px[x, 10] = BONE_D
    px[7, 10] = BONE
    px[3, 12] = BONE; px[4, 12] = BONE; px[5, 12] = BONE_D
    px[11, 11] = BONE; px[12, 11] = BONE
    for x in range(11, 14):
        for y in range(6, 9):
            d2 = (x - 12) ** 2 + (y - 7) ** 2
            if d2 <= 2:
                px[x, y] = BONE
    px[12, 7] = BONE_K
put(7, 0, make(des_huesos))

# ============ ROW 1: Llanos + Sierra ============
put(0, 1, make(lambda px: base_llanos(px, 201)))

def lla_mezquite(px):
    base_llanos(px, 202)
    cx, cy = 8, 10
    px[cx, cy] = MEZQ_TRUNK; px[cx, cy + 1] = MEZQ_TRUNK; px[cx, cy + 2] = MEZQ_TRUNK
    for (dx, dy) in [(-2, -1), (-1, -1), (0, -1), (1, -1), (2, -1),
                      (-2, -2), (-1, -2), (0, -2), (1, -2), (2, -2),
                      (-1, -3), (0, -3), (1, -3)]:
        dot(px, cx + dx, cy + dy, MEZQ_G)
    dot(px, cx - 2, cy - 1, MEZQ_D); dot(px, cx + 2, cy - 1, MEZQ_D)
    dot(px, cx - 1, cy - 3, MEZQ_D); dot(px, cx + 1, cy - 3, MEZQ_D)
put(1, 1, make(lla_mezquite))

def lla_pasto_alto(px):
    base_llanos(px, 203)
    for (x, y) in [(5, 9), (5, 10), (5, 11), (5, 12), (6, 10), (6, 11), (7, 9), (7, 10), (7, 11), (7, 12),
                    (9, 9), (9, 10), (9, 11), (9, 12), (10, 10), (10, 11), (11, 9), (11, 10), (11, 11)]:
        px[x, y] = L_GRASS
    for (x, y) in [(6, 12), (8, 12), (10, 12)]:
        px[x, y] = L_GRASS_D
put(2, 1, make(lla_pasto_alto))

put(3, 1, make(lambda px: base_sierra(px, 301)))

def sie_pino(px):
    base_sierra(px, 302)
    cx = 8
    for y in range(2, 12):
        width = max(1, (y - 1) // 2)
        for dx in range(-width, width + 1):
            x = cx + dx
            if 0 <= x < T:
                px[x, y] = PINE_G if dx % 2 == 0 else PINE_D
        if y > 3:
            dot(px, cx, y, PINE_L)
    px[cx, 12] = TRUNK; px[cx, 13] = TRUNK
    px[cx - 1, 13] = TRUNK; px[cx + 1, 13] = TRUNK
put(4, 1, make(sie_pino))

def sie_pino_seco(px):
    base_sierra(px, 303)
    cx = 8
    for y in range(3, 11):
        width = max(1, (y - 2) // 3)
        for dx in range(-width, width + 1):
            x = cx + dx
            if 0 <= x < T:
                px[x, y] = PINE_DEAD if dx % 2 == 0 else PINE_DEAD_D
    px[cx, 11] = TRUNK; px[cx, 12] = TRUNK
    dot(px, 3, 13, PINE_DEAD_D); dot(px, 13, 13, PINE_DEAD_D)
put(5, 1, make(sie_pino_seco))

def sie_roca(px):
    base_sierra(px, 304)
    for x in range(3, 13):
        for y in range(5, 13):
            d2 = (x - 8) ** 2 + ((y - 9.5) * 0.9) ** 2
            if d2 <= 20:
                px[x, y] = ROCK
            if 20 < d2 <= 26:
                px[x, y] = ROCK_D
    for (x, y) in [(6, 5), (7, 5), (8, 5), (9, 5), (5, 6), (10, 6)]:
        dot(px, x, y, ROCK_MOSS)
put(6, 1, make(sie_roca))

def arbol_muerto(px):
    base_sierra(px, 305)
    cx = 8
    for y in range(4, 13):
        px[cx, y] = DEAD_TREE
        px[cx - 1, y] = DEAD_TREE if y > 6 else px[cx - 1, y]
    px[cx - 3, 5] = DEAD_BR; px[cx - 2, 5] = DEAD_BR; px[cx - 2, 4] = DEAD_BR
    px[cx + 3, 5] = DEAD_BR; px[cx + 2, 5] = DEAD_BR; px[cx + 2, 4] = DEAD_BR
    px[cx - 4, 7] = DEAD_BR; px[cx - 3, 7] = DEAD_BR
    px[cx + 4, 7] = DEAD_BR; px[cx + 3, 7] = DEAD_BR
    px[cx - 1, 13] = DEAD_BR; px[cx + 1, 13] = DEAD_BR
put(7, 1, make(arbol_muerto))

# ============ ROW 2: Barranca + Minero + Río ============
def barranca_borde(px):
    for x in range(T):
        for y in range(T):
            if y < 5: px[x, y] = B_EDGE
            elif y < 7: px[x, y] = B_EDGE_D
            else: px[x, y] = CHASM
    speckle(px, 8, B_EDGE_D, 401)
    dot(px, 4, 5, ROCK_D); dot(px, 9, 4, ROCK_D); dot(px, 13, 5, ROCK_D)
    speckle(px, 6, CHASM_D, 402)
put(0, 2, make(barranca_borde))

def barranca_abismo(px):
    fill(px, CHASM)
    speckle(px, 12, CHASM_D, 403)
    dot(px, 5, 4, ROCK_D); dot(px, 11, 9, ROCK_D)
put(1, 2, make(barranca_abismo))

def barranca_puente(px):
    fill(px, CHASM)
    for x in range(T):
        px[x, 6] = BRIDGE_W; px[x, 7] = BRIDGE_W
    for x in range(0, T, 3):
        px[x, 7] = (40, 26, 16, 255)
    for x in range(T):
        if x % 2 == 0:
            px[x, 5] = BRIDGE_R
            px[x, 8] = BRIDGE_R
put(2, 2, make(barranca_puente))

put(3, 2, make(lambda px: base_minero(px, 401)))

def minero_oxido(px):
    base_minero(px, 402)
    for (x, y) in [(3, 3), (4, 4), (5, 5), (6, 4), (7, 5), (8, 4),
                    (11, 10), (12, 11), (13, 12), (10, 11), (9, 12)]:
        px[x, y] = M_RUST
    dot(px, 4, 4, M_RUST_D); dot(px, 12, 11, M_RUST_D)
put(4, 2, make(minero_oxido))

def minero_carrito(px):
    base_minero(px, 403)
    for x in range(T):
        px[x, 12] = M_RAIL; px[x, 14] = M_RAIL
    for x in range(4, 13):
        for y in range(7, 12):
            px[x, y] = M_CART
    for x in range(5, 12):
        for y in range(8, 10):
            px[x, y] = M_CART_R
    px[5, 12] = M_DARK; px[11, 12] = M_DARK
    px[5, 13] = M_DARK; px[11, 13] = M_DARK
put(5, 2, make(minero_carrito))

def rio(px):
    fill(px, R_BASE)
    for x in range(0, T, 4):
        px[x, 4] = R_LIGHT; px[x + 1, 4] = R_LIGHT
        px[(x + 2) % T, 10] = R_LIGHT; px[(x + 3) % T, 10] = R_LIGHT
    speckle(px, 4, R_DEEP, 601)
put(6, 2, make(rio))

def rio_ribera(px):
    fill(px, R_BANK)
    speckle(px, 8, D_DARK, 602)
    for x in range(T):
        for y in range(10, T):
            px[x, y] = R_BASE
    for x in range(0, T, 3):
        px[x, 10] = R_LIGHT
put(7, 2, make(rio_ribera))

# ============ ROW 3: Caminos + POIs + entradas (1-tile) ============
def camino_horiz(px):
    fill(px, D_BASE)
    speckle(px, 6, D_DARK, 701)
    for x in range(T):
        for y in range(6, 11):
            px[x, y] = PATH_BASE
    speckle(px, 5, PATH_DARK, 702)
    dot(px, 4, 7, PATH_STONE); dot(px, 11, 9, PATH_STONE)
put(0, 3, make(camino_horiz))

def camino_vert(px):
    fill(px, D_BASE)
    speckle(px, 6, D_DARK, 703)
    for y in range(T):
        for x in range(6, 11):
            px[x, y] = PATH_BASE
    speckle(px, 5, PATH_DARK, 704)
    dot(px, 7, 4, PATH_STONE); dot(px, 9, 11, PATH_STONE)
put(1, 3, make(camino_vert))

def mata_ortiz(px):
    fill(px, MO_GROUND)
    speckle(px, 6, D_DARK, 801)
    for x in range(3, 10):
        for y in range(7, 13):
            px[x, y] = MO_WALL
    for y in range(7, 13):
        px[3, y] = MO_WALL_D
    for y in range(4, 7):
        for x in range(2 + (6 - y), 11 - (6 - y)):
            px[x, y] = MO_ROOF
    for y in range(4, 7):
        px[2 + (6 - y), y] = MO_ROOF_D
    px[6, 11] = MO_DOOR; px[6, 12] = MO_DOOR
    px[5, 9] = MO_DOOR
    cx = 12
    for y in range(9, 13):
        for x in range(cx - 1, cx + 2):
            d2 = (x - cx) ** 2 + ((y - 11) * 1.1) ** 2
            if d2 <= 4:
                px[x, y] = MO_WALL
    dot(px, cx, 10, MO_POT_R); dot(px, cx - 1, 11, MO_POT_R); dot(px, cx + 1, 11, MO_POT_R)
put(2, 3, make(mata_ortiz))

def mision(px):
    fill(px, MJ_GROUND)
    speckle(px, 5, D_DARK, 901)
    for x in range(4, 12):
        for y in range(6, 14):
            px[x, y] = MJ_WALL
    for y in range(6, 14):
        px[3, y] = MJ_WALL_D; px[12, y] = MJ_WALL_D
    for x in range(5, 11):
        for y in range(3, 6):
            d2 = (x - 7.5) ** 2 + (y - 5) ** 2
            if d2 <= 8:
                px[x, y] = MJ_DOME
    px[8, 1] = MJ_CROSS; px[8, 2] = MJ_CROSS
    px[7, 2] = MJ_CROSS; px[9, 2] = MJ_CROSS
    for y in range(11, 14):
        px[7, y] = MJ_CROSS; px[8, y] = MJ_CROSS
put(3, 3, make(mision))

def cementerio(px):
    fill(px, CEM_GROUND)
    speckle(px, 10, CEM_GROUND_D, 1001)
    px[3, 6] = CEM_CROSS; px[3, 7] = CEM_CROSS; px[3, 8] = CEM_CROSS; px[3, 9] = CEM_CROSS; px[3, 10] = CEM_CROSS
    px[2, 7] = CEM_CROSS; px[4, 7] = CEM_CROSS
    px[2, 8] = CEM_CROSS_D; px[4, 8] = CEM_CROSS_D
    px[8, 7] = CEM_CROSS; px[8, 8] = CEM_CROSS; px[8, 9] = CEM_CROSS; px[8, 10] = CEM_CROSS; px[8, 11] = CEM_CROSS
    px[7, 8] = CEM_CROSS; px[9, 8] = CEM_CROSS
    px[12, 10] = CEM_CROSS; px[13, 10] = CEM_CROSS; px[14, 10] = CEM_CROSS
    px[13, 9] = CEM_CROSS; px[13, 11] = CEM_CROSS_D
    dot(px, 6, 12, BONE); dot(px, 7, 12, BONE_D)
put(4, 3, make(cementerio))

def entrada_paquime(px):
    fill(px, EP_GROUND)
    speckle(px, 8, D_DARK, 1101)
    for x in range(3, 13):
        for y in range(3, 13):
            px[x, y] = EP_WALL
    for x in range(5, 11):
        for y in range(4, 9):
            px[x, y] = EP_HOLE
    for x in range(7, 9):
        for y in range(9, 12):
            px[x, y] = EP_HOLE
    for x in range(3, 13): px[x, 8] = (40, 26, 16, 255)
    dot(px, 2, 13, ROCK_D); dot(px, 13, 13, ROCK_D); dot(px, 4, 13, BONE_D)
put(5, 3, make(entrada_paquime))

def entrada_tarahumara(px):
    fill(px, ET_GROUND)
    speckle(px, 8, S_FLOOR_D, 1201)
    for x in range(2, 14):
        for y in range(2, 13):
            d2 = (x - 8) ** 2 + (y - 7) ** 2
            if d2 <= 36:
                px[x, y] = ET_ROCK
    for x in range(5, 11):
        for y in range(6, 13):
            d2 = (x - 7.5) ** 2 + (y - 9) ** 2 * 1.4
            if d2 <= 9:
                px[x, y] = ET_HOLE
    px[4, 11] = ET_SKULL; px[5, 11] = ET_SKULL; px[3, 11] = ET_SKULL
    px[4, 10] = ET_SKULL
    dot(px, 4, 11, BONE_K)
put(6, 3, make(entrada_tarahumara))

def entrada_naica(px):
    fill(px, EN_GROUND)
    speckle(px, 12, M_DARK, 1301)
    for x in range(3, 13): px[x, 3] = EN_FRAME; px[x, 13] = EN_FRAME
    for y in range(3, 14):
        px[3, y] = EN_FRAME; px[12, y] = EN_FRAME
    for x in range(4, 12):
        for y in range(4, 13):
            px[x, y] = EN_HOLE
    px[7, 10] = EN_CRYST; px[8, 10] = EN_CRYST_GLOW
    px[7, 11] = EN_CRYST; px[8, 11] = EN_CRYST
    px[9, 11] = EN_CRYST; px[8, 12] = EN_CRYST_GLOW
    px[5, 14] = M_RUST; px[10, 14] = M_RUST
put(7, 3, make(entrada_naica))

# ============ ROW 4: Componentes para stamps multi-tile ============

def adobe_wall(px):
    """Adobe wall genérico (para rodear entrada Paquimé)."""
    fill(px, ADO_WALL)
    for x in range(T): px[x, 0] = ADO_WALL_D; px[x, 8] = ADO_WALL_D
    for y in range(1, 8): px[0, y] = ADO_WALL_D; px[8, y] = ADO_WALL_D
    for y in range(9, T): px[4, y] = ADO_WALL_D; px[12, y] = ADO_WALL_D
    for x in range(1, 8): px[x, 1] = ADO_WALL_L
    for x in range(9, T): px[x, 1] = ADO_WALL_L
    for x in range(5, 12): px[x, 9] = ADO_WALL_L
put(0, 4, make(adobe_wall))

def cream_floor(px):
    """Piso crema interior (Paquimé interior visible)."""
    fill(px, CREAM)
    speckle(px, 6, CREAM_D, 1401)
    # patrón Ramos pequeño
    px[8, 8] = (140, 30, 30, 255)
    px[7, 8] = (40, 30, 22, 255); px[9, 8] = (40, 30, 22, 255)
put(1, 4, make(cream_floor))

def dirt_path(px):
    """Camino de tierra (rodea entradas)."""
    fill(px, DIRT)
    speckle(px, 10, DIRT_D, 1501)
    dot(px, 4, 7, PATH_STONE); dot(px, 11, 9, PATH_STONE)
    dot(px, 7, 4, PATH_STONE); dot(px, 9, 12, PATH_STONE)
put(2, 4, make(dirt_path))

def cave_rock(px):
    """Pared de roca oscura para entrada Tarahumara."""
    fill(px, CAVE_ROCK)
    speckle(px, 16, CAVE_ROCK_D, 1601)
    speckle(px, 6, CAVE_ROCK_L, 1602)
    # vetas
    for y in [3, 9]:
        for x in range(2, 14):
            if x % 3 == 0:
                px[x, y] = CAVE_ROCK_D
put(3, 4, make(cave_rock))

def cave_shadow(px):
    """Sombra interior de cueva (vista al hueco oscuro)."""
    fill(px, CAVE_DARK)
    speckle(px, 8, CAVE_ROCK_D, 1701)
    # un par de cristales tenues
    dot(px, 5, 12, (40, 60, 80, 255)); dot(px, 11, 6, (40, 60, 80, 255))
put(4, 4, make(cave_shadow))

def wood_frame(px):
    """Vigas de madera (entrada Naica, marco)."""
    fill(px, M_BASE)
    speckle(px, 8, M_DARK, 1801)
    # viga vertical
    for y in range(T):
        for x in [5, 6, 7]:
            px[x, y] = WOOD_F
        for x in [5]: px[x, y] = WOOD_F_D
        for x in [7]: px[x, y] = WOOD_F_L
    # clavos
    dot(px, 6, 2, RAIL_M); dot(px, 6, 14, RAIL_M)
put(5, 4, make(wood_frame))

def rails(px):
    """Rieles de mina (Naica)."""
    fill(px, M_BASE)
    speckle(px, 6, M_DARK, 1901)
    # 2 rieles paralelos
    for y in range(T):
        px[5, y] = RAIL_M; px[6, y] = RAIL_D
        px[10, y] = RAIL_M; px[11, y] = RAIL_D
    # durmientes
    for y in [2, 5, 8, 11, 14]:
        for x in range(3, 13):
            px[x, y] = RAIL_TIE
        px[5, y] = RAIL_M; px[6, y] = RAIL_D
        px[10, y] = RAIL_M; px[11, y] = RAIL_D
put(6, 4, make(rails))

def mesa_edge(px):
    """Mesa (meseta) borde — tile para zonas altas planas."""
    fill(px, MESA_TOP)
    speckle(px, 6, MESA_EDGE, 2001)
    # borde abajo más oscuro (sombra)
    for x in range(T):
        for y in range(12, T):
            px[x, y] = MESA_SHADOW
    for x in range(T):
        px[x, 11] = MESA_EDGE
put(7, 4, make(mesa_edge))

# ============ ROW 5: Picos + extras ============

def pico_nieve(px):
    """Pico nevado (Cerro Mohinora, Majalca, etc.)."""
    fill(px, PICO_R)
    # triángulo de nieve
    for y in range(T):
        for x in range(T):
            if abs(x - 8) <= max(0, 9 - y) * 0.8:
                if y < 6:
                    px[x, y] = PICO_SNOW
                elif y < 9:
                    px[x, y] = (180, 184, 192, 255)
    speckle(px, 8, PICO_SHADOW, 2101)
    # sombra a la derecha del pico
    dot(px, 11, 4, PICO_SHADOW); dot(px, 11, 5, PICO_SHADOW); dot(px, 12, 6, PICO_SHADOW)
put(0, 5, make(pico_nieve))

def cardon(px):
    """Cardón (cactus columnar chihuahuense)."""
    base_desert(px, 2201)
    cx = 8
    # cuerpo del cardón vertical con espinas
    for y in range(2, 14):
        px[cx, y] = CARDON_G
        px[cx + 1, y] = CARDON_D
    # brazo
    for y in range(5, 9):
        px[cx - 2, y] = CARDON_G
    px[cx - 1, 5] = CARDON_G; px[cx - 2, 4] = CARDON_G
    # espinas pequeñas amarillas
    for y in range(3, 14, 2):
        dot(px, cx - 1, y, CARDON_SP)
        dot(px, cx + 2, y, CARDON_SP)
put(1, 5, make(cardon))

def rancho_quemado(px):
    """Rancho abandonado/quemado."""
    fill(px, D_BASE)
    speckle(px, 8, D_DARK, 2301)
    # restos de muros (negros, quemados)
    for x in range(3, 13):
        for y in range(8, 13):
            px[x, y] = RANCHO_BURN
    # vigas caídas
    for x in range(4, 12):
        px[x, 7] = RANCHO_WOOD
    # rastros de fuego
    dot(px, 5, 11, M_RUST); dot(px, 10, 12, M_RUST)
    dot(px, 7, 13, BONE_K)
put(2, 5, make(rancho_quemado))

def alambrada(px):
    """Alambrada (fence post + wire)."""
    fill(px, D_BASE)
    speckle(px, 5, D_DARK, 2401)
    # postes verticales
    for y in range(4, 14):
        px[3, y] = FENCE_W; px[12, y] = FENCE_W
    # alambres horizontales
    for x in range(3, 13):
        px[x, 6] = FENCE_WIRE
        px[x, 9] = FENCE_WIRE
        px[x, 12] = FENCE_WIRE
put(3, 5, make(alambrada))

def fogata_apagada(px):
    """Fogata apagada con ceniza."""
    base_llanos(px, 2501)
    # piedras circulares
    for (x, y) in [(6, 10), (8, 8), (10, 10), (9, 12), (6, 12), (11, 9)]:
        dot(px, x, y, ROCK_D)
        dot(px, x + 1, y + 1, ROCK)
    # ceniza al centro
    for x in range(7, 11):
        for y in range(9, 12):
            d2 = (x - 8.5) ** 2 + (y - 10.5) ** 2
            if d2 <= 2:
                px[x, y] = (88, 80, 76, 255)
    dot(px, 8, 10, BONE_K)  # leño quemado
put(4, 5, make(fogata_apagada))

def charco(px):
    """Charco / pozo de agua."""
    fill(px, CHARCO_BANK)
    # ribera de tierra
    speckle(px, 6, D_DARK, 2601)
    # cuerpo de agua oval
    for x in range(T):
        for y in range(T):
            nx = (x - 8) / 6.0
            ny = (y - 8) / 4.5
            if nx * nx + ny * ny <= 1.0:
                px[x, y] = CHARCO_W
    # reflejos
    for x in range(5, 12):
        if x % 2 == 0: px[x, 6] = CHARCO_L
        if x % 3 == 1: px[x, 10] = CHARCO_L
put(5, 5, make(charco))

def tracks(px):
    """Huellas de animal (coyote/venado)."""
    base_desert(px, 2701)
    # dos pares de huellas
    for (x, y) in [(4, 5), (5, 4), (6, 6), (7, 5),
                    (9, 10), (10, 9), (11, 11), (12, 10)]:
        dot(px, x, y, TRACKS)
        dot(px, x + 1, y, TRACKS)
        dot(px, x, y + 1, TRACKS)
put(6, 5, make(tracks))

def monolito(px):
    """Monolito de piedra (landmark vertical)."""
    fill(px, D_BASE)
    speckle(px, 5, D_DARK, 2801)
    # piedra erguida
    cx = 8
    for y in range(3, 14):
        px[cx, y] = MONOLITO_R
        px[cx - 1, y] = MONOLITO_R if y > 5 else px[cx - 1, y]
        px[cx + 1, y] = MONOLITO_D
    for y in range(5, 14):
        px[cx - 2, y] = MONOLITO_R if y > 7 else px[cx - 2, y]
        px[cx + 2, y] = MONOLITO_D if y > 7 else px[cx + 2, y]
    # punto alto destacado
    px[cx, 3] = MONOLITO_L
    px[cx, 4] = MONOLITO_L
    # sombra a la base
    for x in range(cx - 3, cx + 4):
        dot(px, x, 14, MONOLITO_D)
put(7, 5, make(monolito))


img.save(OUT / "overworld_tiles.png")
img.resize((W * 6, H * 6), Image.NEAREST).save(OUT / "overworld_tiles_preview.png")
print(f"OK -> {OUT / 'overworld_tiles.png'} ({W}x{H}, {COLS * ROWS} tiles)")
