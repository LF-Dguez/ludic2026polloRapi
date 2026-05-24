"""Sprite top-down 64x64 del jugador (ranchero chihuahuense)."""
from PIL import Image
from pathlib import Path

ROOT = Path(__file__).parent.parent
OUT = ROOT / "art" / "tiles"
OUT.mkdir(parents=True, exist_ok=True)

T = 64
TRANS = (0, 0, 0, 0)

# Paleta consistente con la del overworld (tétrica)
HAT = (88, 60, 36, 255); HAT_D = (54, 36, 22, 255); HAT_L = (124, 88, 58, 255)
HAT_BRIM_D = (40, 26, 16, 255)
HAT_BAND = (110, 28, 28, 255); HAT_BAND_D = (76, 14, 14, 255)
SKIN = (196, 156, 118, 255); SKIN_D = (148, 110, 78, 255); SKIN_L = (220, 180, 142, 255)
STACHE = (28, 18, 12, 255); STACHE_L = (50, 32, 22, 255)
EYE = (18, 14, 10, 255); EYE_W = (220, 210, 190, 255)
PONCHO = (74, 60, 42, 255); PONCHO_D = (48, 38, 26, 255); PONCHO_L = (100, 84, 60, 255)
PONCHO_STRIPE_R = (132, 38, 32, 255); PONCHO_STRIPE_K = (28, 18, 12, 255)
BANDOLIER = (62, 38, 22, 255); BULLET = (172, 138, 60, 255)
BOOT = (24, 16, 10, 255); BOOT_L = (44, 30, 18, 255)
BELT = (40, 26, 16, 255)
BUCKLE = (188, 148, 56, 255)
GUN_GRIP = (96, 56, 30, 255); GUN_METAL = (60, 56, 52, 255)
OUTLINE = (12, 8, 6, 255)

img = Image.new("RGBA", (T, T), TRANS)
px = img.load()


def dot(x, y, c):
    if 0 <= x < T and 0 <= y < T:
        px[x, y] = c


# ===== SOMBRERO (vista oblicua casi cenital) =====
# Brim (ala ancha): elipse achatada, centro (32, 18), radios 26x14
cx_hat, cy_hat = 32, 19
for x in range(T):
    for y in range(T):
        nx = (x - cx_hat) / 28.0
        ny = (y - cy_hat) / 15.0
        d2 = nx * nx + ny * ny
        if d2 <= 1.0:
            px[x, y] = HAT
        elif d2 <= 1.08:
            px[x, y] = HAT_BRIM_D

# sombra inferior del brim (línea oscura)
for x in range(T):
    nx = (x - cx_hat) / 28.0
    if abs(nx) <= 1.0:
        y = int(cy_hat + 15.0 * (1.0 - nx * nx) ** 0.5)
        if 0 <= y < T:
            px[x, y] = HAT_BRIM_D
            if y + 1 < T:
                px[x, y + 1] = HAT_BRIM_D

# Crown (copa): elipse más chica
for x in range(T):
    for y in range(T):
        nx = (x - cx_hat) / 13.0
        ny = (y - (cy_hat - 4)) / 11.0
        d2 = nx * nx + ny * ny
        if d2 <= 1.0:
            px[x, y] = HAT_L

# Cima del crown más clara
for x in range(T):
    for y in range(T):
        nx = (x - cx_hat) / 10.0
        ny = (y - (cy_hat - 8)) / 7.0
        d2 = nx * nx + ny * ny
        if d2 <= 1.0:
            px[x, y] = (148, 108, 72, 255)

# Banda roja (alrededor del crown, base)
for x in range(T):
    nx = (x - cx_hat) / 13.0
    if abs(nx) < 1.0:
        y_band = cy_hat + 4
        if 0 <= y_band < T:
            px[x, y_band] = HAT_BAND
            if x % 3 == 0:
                px[x, y_band] = HAT_BAND_D

# ===== SOMBRA del sombrero sobre la cara =====
for x in range(22, 43):
    for y in range(28, 32):
        if px[x, y][3] == 0 or px[x, y][:3] == HAT[:3]:
            px[x, y] = SKIN_D

# ===== CARA =====
# Área de piel (curva)
for x in range(T):
    for y in range(T):
        nx = (x - 32) / 11.0
        ny = (y - 35) / 7.0
        d2 = nx * nx + ny * ny
        if d2 <= 1.0 and px[x, y][:3] != HAT[:3] and px[x, y][:3] != HAT_L[:3]:
            px[x, y] = SKIN

# Highlight superior de la cara (apenas)
for x in range(28, 37):
    for y in range(33, 35):
        if px[x, y] == SKIN:
            px[x, y] = SKIN_L

# Ojos
for (ex, ey) in [(27, 34), (28, 34), (36, 34), (37, 34)]:
    px[ex, ey] = EYE_W
px[27, 34] = EYE; px[36, 34] = EYE  # iris izquierdo
px[28, 34] = EYE; px[37, 34] = EYE  # iris derecho — ambos negros para look tétrico

# Cejas pobladas (oscuras, bajo el borde del sombrero)
for x in range(25, 31):
    dot(x, 32, STACHE)
for x in range(34, 40):
    dot(x, 32, STACHE)

# Nariz (sombra sutil)
dot(32, 36, SKIN_D); dot(32, 37, SKIN_D)
dot(33, 37, SKIN_D)

# Bigote grande Pancho Villa-style
# Centro
for x in range(28, 37):
    dot(x, 38, STACHE)
    dot(x, 39, STACHE)
# Extremos curvos
for x in range(25, 28):
    dot(x, 39, STACHE)
for x in range(37, 40):
    dot(x, 39, STACHE)
dot(24, 40, STACHE); dot(40, 40, STACHE)
# Highlight
dot(31, 38, STACHE_L); dot(33, 38, STACHE_L)

# Boca/mentón
dot(31, 40, STACHE); dot(32, 40, STACHE); dot(33, 40, STACHE)

# ===== CUELLO =====
for x in range(28, 37):
    for y in range(41, 43):
        px[x, y] = SKIN_D

# ===== TORSO / PONCHO =====
# Forma general
for x in range(T):
    for y in range(T):
        nx = (x - 32) / 18.0
        ny = (y - 50) / 10.0
        d2 = nx * nx + ny * ny
        if d2 <= 1.0 and y >= 42:
            if px[x, y][3] == 0:
                px[x, y] = PONCHO

# Sombra lateral del poncho
for x in range(T):
    for y in range(T):
        if px[x, y] == PONCHO:
            if x < 22 or x > 42:
                px[x, y] = PONCHO_D

# Highlight central
for x in range(28, 37):
    for y in range(44, 50):
        if px[x, y] == PONCHO:
            px[x, y] = PONCHO_L

# Franjas (motivo)
for y in [46, 47, 53, 54]:
    for x in range(15, 50):
        if px[x, y][:3] in [PONCHO[:3], PONCHO_D[:3], PONCHO_L[:3]]:
            px[x, y] = PONCHO_STRIPE_R if (x + y) % 4 < 2 else PONCHO_STRIPE_K

# V-neck (abertura del poncho en el cuello)
for y in range(42, 47):
    for x in range(31, 34):
        if y - 42 < x - 30 and y - 42 < 33 - x:
            px[x, y] = SKIN_D

# ===== BANDOLERA (cruzada) =====
for i in range(20):
    x = 18 + i; y = 44 + i // 2
    if 0 <= x < T and 0 <= y < T and px[x, y] in [PONCHO, PONCHO_D, PONCHO_L, PONCHO_STRIPE_R, PONCHO_STRIPE_K]:
        px[x, y] = BANDOLIER
        if i % 3 == 1:
            px[x, y] = BULLET

# ===== CINTURÓN + HEBILLA =====
for x in range(16, 48):
    if px[x, 56][3] > 0:
        px[x, 56] = BELT
    if px[x, 57][3] > 0:
        px[x, 57] = BELT
# Hebilla dorada
for x in range(30, 35):
    dot(x, 56, BUCKLE); dot(x, 57, BUCKLE)
dot(32, 56, (88, 60, 22, 255))  # detalle interior

# ===== BOTAS =====
for x in range(22, 30):
    for y in range(58, 64):
        px[x, y] = BOOT
for x in range(34, 42):
    for y in range(58, 64):
        px[x, y] = BOOT
# punteras
for x in range(22, 26): dot(x, 60, BOOT_L)
for x in range(38, 42): dot(x, 60, BOOT_L)

# ===== REVÓLVER al costado =====
for y in range(48, 54):
    px[48, y] = GUN_GRIP
    px[49, y] = GUN_GRIP
px[47, 48] = GUN_METAL; px[46, 48] = GUN_METAL
px[47, 49] = GUN_METAL; px[46, 49] = GUN_METAL

# ===== OUTLINE oscuro (último pase) =====
orig = img.copy()
op = orig.load()
for x in range(T):
    for y in range(T):
        if op[x, y][3] == 0:
            for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < T and 0 <= ny < T and op[nx, ny][3] > 0:
                    px[x, y] = OUTLINE
                    break

img.save(OUT / "player.png")
img.resize((T * 4, T * 4), Image.NEAREST).save(OUT / "player_preview.png")
print(f"OK -> {OUT / 'player.png'} ({T}x{T})")
