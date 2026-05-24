# Norte Profundo — Design Document

> Generador procedural de mundo abierto + mazmorras inspirado en Chihuahua, México.
> Godot 4.6.1 mono, Windows.

## Pilares

1. **Chihuahua, no genérico**. Paquimé, Naica, Sierra Tarahumara, Mata Ortiz, minería colonial. Nada de saguaros (eso es Sonora) ni bandidos de spaghetti western.
2. **Mundo abierto + mazmorras procgen anidadas**. Híbrido a la Diablo/Valheim. Anchors handcrafted + procgen alrededor.
3. **Navegación por landmarks** (lección BotW). El jugador siempre ve algo curioso a lo lejos. Mínimo HUD.
4. **Determinismo por seed**. `seed(world)` → mundo. `hash(world_seed, poi_id)` → mazmorra. Reproducible.

## Estructura macro

```
WORLD (procgen, semilla global)
├── BIOMA: Desierto chihuahuense       → entradas Paquimé
├── BIOMA: Llanos / mesetas            → misión jesuita (anchor handcrafted)
├── BIOMA: Sierra Tarahumara           → entradas cuevas (Tarahumara)
├── BIOMA: Barrancas del Cobre         → puentes colgantes, descenso
└── BIOMA: Distrito minero (Parral)    → entradas Naica
		│
		├── POI handcrafted: Mata Ortiz (refugio + vendedor)
		├── POI handcrafted: Misión San Francisco Javier de Satevó
		├── POI handcrafted: Hidalgo del Parral (mina histórica)
		└── POIs procgen: entradas de mazmorra (≥ 1 por bioma)
				│
				└── DUNGEON (procgen on-demand, seed derivado)
						├── Tipo Paquimé: BSP + puertas T + plaza + cancha + efigies
						├── Tipo Tarahumara: cellular automata + petroglifos + fogatas
						└── Tipo Naica: CA denso + cristales + fumarolas (heat damage)
```

## Algoritmos elegidos (con razón)

| Capa | Algoritmo | Por qué |
|---|---|---|
| Overworld biomas | Voronoi / value noise sobre IDs | Manchas grandes naturales, bordes definidos |
| POI placement | Poisson disk sampling | Distribución sin amontonamiento |
| Mazmorra Paquimé | BSP rectangular | Arquitectura ortogonal con plaza horseshoe |
| Mazmorra Tarahumara | Cellular automata | Cuevas orgánicas irregulares |
| Mazmorra Naica | CA + crystal seeds | CA base + grupos de cristales sembrados |

## Lecciones aplicadas

**Spelunky → tomamos:**
- Grid de rooms con templates (en mazmorra Paquimé). Cada room tipo (vivienda, taller, plaza) tiene 1-3 variantes.
- Validación de conectividad (flood-fill post-gen).
- Comodín de escape: pico/dinamita con costo de stamina.

**BotW → tomamos:**
- Landmarks visibles a través de biomas (mesas, montañas, torres).
- Triangle approach: cerros que ocultan parcialmente otros landmarks.
- Topografía como guía (descender hacia oasis/pueblos).

**Diablo → tomamos:**
- Overworld con anchors handcrafted + dungeons procgen on-demand.
- POIs marcados en el mapa solo después de visitar.

**Roguelikes (Cogmind, Hades) → tomamos:**
- Static rest zones entre procgen (Mata Ortiz = el refugio).
- Tension/release loop: superficie → Paquimé (medio) → Tarahumara (alto) → Naica (pico).

## Loop de juego

```
Spawn (Mata Ortiz)
  → Ver landmarks en el horizonte
  → Caminar a uno
  → POI handcrafted (loot, lore) o entrada de mazmorra
  → [si mazmorra] generar dungeon con seed(world, poi)
  → Limpiar mazmorra → loot → exit
  → Vuelta a Mata Ortiz → vendedor / upgrade / save
  → Repetir hacia mazmorra más profunda
```

## Roadmap step-by-step

- [ ] **Paso 1**: Design doc + atlas de tiles de superficie ← AHORA
- [ ] **Paso 2**: Proyecto Godot + render del biome map procgen
- [ ] **Paso 3**: POIs handcrafted + entradas de mazmorra
- [ ] **Paso 4**: Cámara + personaje placeholder
- [ ] **Paso 5**: Mazmorra Paquimé (BSP) on-demand desde POI
- [ ] **Paso 6**: Mazmorras Tarahumara y Naica (CA)
- [ ] **Paso 7**: Transición overworld ↔ dungeon con seed determinístico
- [ ] **Paso 8**: Mecánicas: inventory, peligro térmico Naica, vendor Mata Ortiz
- [ ] **Paso 9**: Polish: música, sfx, lore strings, splash

## Fuentes
- [Cómo Nintendo resolvió el open world de Zelda — GMTK](https://gmtk.substack.com/p/how-nintendo-solved-zeldas-open-world)
- [Realism & Legibility in Open World Level Design — Game Developer](https://www.gamedeveloper.com/design/realism-and-legibility-in-open-world-level-design)
- [Constructive Generation Methods for Dungeons — Liapis](https://antoniosliapis.com/articles/pcgbook_dungeons.php)
- [Dungeon Generation in Diablo 1 — BorisTheBrave](https://www.boristhebrave.com/2019/07/14/dungeon-generation-in-diablo-1/)
- [Roguelike Level Design: Procedural Layouts — Cogmind](https://www.gridsagegames.com/blog/2019/03/roguelike-level-design-addendum-procedural-layouts/)
- [Single Player Level Design Pacing — Pete Ellis](https://www.worldofleveldesign.com/categories/wold-members-tutorials/peteellis/level-design-pacing-gameplay-beats-part2.php)
