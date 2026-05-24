# Norte Profundo

Generador procedural de mundo abierto + mazmorras inspirado en **Chihuahua, México**.

Hecho en **Godot 4.6 .NET** (Mono). El mundo es un mapa top-down de 1024×768 tiles
con biomas tipo Whittaker (banda W→E: Sierra Madre Occidental → Llanos/Mesetas →
Desierto Chihuahuense), Río Conchos serpenteando del SW al NE, y POIs distribuidos
con scatter aleatorio + min-distance.

## Lugares reales que aparecen

| POI | Inspirado en | Algoritmo de mazmorra |
|---|---|---|
| 🔴 Paquimé | Casas Grandes (ruinas adobe, puertas T, 1200-1450 CE) | BSP rectangular |
| 🟢 Cueva Tarahumara | Sierra Tarahumara / Barrancas del Cobre | Cellular automata + drunkard's walk |
| 🔵 Naica | Cueva de los Cristales / mina de selenita | Pozo principal + ramas + cámara de cristales |
| ⚪ Mata Ortiz | Pueblo de cerámica (heredero Paquimé) | — pueblo seguro |
| 🟡 Misión | Misiones jesuitas (San Francisco Javier de Satevó) | — anchor |
| ⚫ Cementerio | Cementerios chihuahuenses | — POI atmosférico |

## Cómo correrlo

1. Instalar Godot 4.6+ (Mono recomendado): https://godotengine.org/download
2. Abrir Godot, importar el proyecto desde esta carpeta
3. F5 para correr (escena principal: `scenes/Main.tscn`)

## Controles

- **WASD** — caminar
- **SPACE** — entrar a mazmorra cuando estás sobre una entrada
- **BACKSPACE** — salir de mazmorra al overworld
- **M** — agrandar / achicar minimapa
- **R** — regenerar mundo (nuevo seed)
- **Q / E** — zoom out / in (limitado a 0.6×–3.0×)
- **F12** — auto-tour (entra a las 3 mazmorras y captura screenshots — debug)
- **Esc** — salir

## Estructura

```
jueguito/
├── project.godot               # Configuración Godot 4
├── scenes/Main.tscn            # Escena raíz
├── scripts/
│   ├── Main.gd                 # Orquesta overworld + mazmorras
│   ├── Overworld.gd            # Generador del mundo (biomas + ríos + POIs)
│   ├── Player.gd               # Movimiento WASD + colisión por tile
│   ├── Minimap.gd              # Minimapa con tooltips
│   ├── BSPGenerator.gd         # Mazmorra Paquimé (BSP)
│   ├── CaveGenerator.gd        # Mazmorra Tarahumara (CA + drunkard's walk)
│   └── MineGenerator.gd        # Mazmorra Naica (pozo + cámara de cristales)
├── art/tiles/
│   ├── overworld_tiles.png     # Atlas hand-drawn (8x6, 16px)
│   ├── desert_tiles_clean.png  # Atlas usuario (8x8, 16px)
│   ├── paquime_tiles.png       # Atlas Paquimé (4x4, 16px)
│   ├── cave_tiles_clean.png    # Atlas usuario (8x8, 32px) — Tarahumara
│   ├── mines_tiles_clean.png   # Atlas usuario (8x9, 32px) — Naica
│   ├── cave_floor.png          # Variantes de piso de cueva (4, 32px)
│   ├── mine_floor.png          # Variantes de piso de mina (4, 32px)
│   ├── paquime_floor.png       # Variantes de piso adobe (4, 16px)
│   ├── player.png              # Sprite jugador (64x64 top-down)
│   └── light_texture.png       # Textura radial para PointLight2D
└── tools/                      # Scripts Python (PIL) para generar tiles
    ├── gen_overworld_tiles.py
    ├── gen_player.py
    ├── gen_floor_and_light.py
    ├── process_user_tilesets.py
    └── ...
```

## Sistemas implementados

- **Generación de biomas**: ruido Simplex multi-octava + bias W→E + picos
  específicos (Cerro Mohinora, Cumbres de Majalca)
- **Ríos como path explícito**: Conchos (SW→NE), tributario Florido, Río Casas
  Grandes (NW endorreico)
- **POIs**: anchors handcrafted (Mata Ortiz, Paquimé, Naica, Parral) +
  scatter aleatorio con min-distance por bioma
- **Multi-source TileSet**: overworld carga 2 sources (hand-drawn + desert atlas
  del usuario)
- **Iluminación dinámica**: `CanvasModulate` oscurece dungeons + `PointLight2D`
  en el jugador revela el entorno
- **Mazmorras con set-pieces**: cada dungeon tiene un elemento central forzado
  (plaza Paquimé, cámara principal Tarahumara, cámara de cristales Naica)
- **Autotile bitmask**: 4-vecinos cardinales → fill / edge / corner / cap /
  isolated, usa todas las filas del atlas

## Para contribuir

- Los tilesets se generan con scripts Python en `tools/` (requiere Pillow).
- Para procesar tilesets nuevos del usuario: poner el PNG fuente en la raíz
  con formato `PRINTS DE [TIPO].png`, modificar `tools/process_user_tilesets.py`
  y correr.
- Los generadores de mazmorra siguen el patrón: clase `XGenerator extends
  RefCounted` con método `generate(w, h, seed_value)` que retorna un
  objeto inner-class con grids de wall/floor.

## Stack

- Godot 4.6 (Mono build, aunque solo se usa GDScript)
- Python 3.12 + Pillow para herramientas de tiles
- Atlases de cueva, desierto y minas: aportados por el usuario
