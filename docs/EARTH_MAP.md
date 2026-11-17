# Earth map spec (Phase 3 starting point, 2026-11-17)

Goal: turn the single 64x64-tile test chunk into the full Earth: Port Halden and its surroundings, built as a grid of chunks streamed in around the player.
Each step below is one large slice with a screenshot gate. Keep every owner feature; this only orders them.

## Scale and tech
- World = 8x8 chunks of 64x64 tiles (32px tiles): 512x512 tiles. Current WorldGen.SIZE chunk becomes chunk (3,4) "Homestead".
- Chunk data via WorldGen seeds + hand-authored "anchor" rectangles (town, farm, caves) that override noise. Stream: keep the 3x3 chunks around the player loaded.
- Save stays per-world dictionaries (farm, build, pots, animals use world-space cells, so no migration).
- Fast travel: car and horse; later bus stops (money sink).

## Regions (chunk coordinates, x right / y down)
| Region | Chunks | Purpose |
|---|---|---|
| Homestead + lake | (3,4) | tutorial farm, dock, workshop, barn (exists) |
| Farmland / meadows | (2..4,3..5) | big fields, livestock, farm jobs, horse races |
| Pine forest | (0..2,2..4) | lumber, foraging, deer/boar, logging job, hunting |
| Port Halden (city) | (5..6,3..4) | shops, bank, police station, hospital, garage, stadium, apartment houses to rob |
| Harbour + sea | (5..7,5..6) | big fishing, ferry, smuggling dock, fishing contests |
| Highlands + caves | (3..5,0..2) | mining caves with ore, smelting, danger |
| Vance Aerospace compound | (7,2) | story Act 2/3, rocket yard (locked until story) |
| Race circuit | (1,6) | car/bike racing, racing licences |

## Build order (each is one big slice)
1. World streaming + chunk grid with the homestead in the middle (empty neighbours filled with noise terrain: meadow/forest/lake).
2. Roads: A* road network between regions, drawn as the existing dirt/path tiles, later asphalt tiles in the city.
3. Port Halden block layout: 12 buildings with enterable interiors (shop, bank, police, hospital, garage), NPC routines move between regions.
4. Caves: separate cave chunk(s) with ore nodes, torches, simple enemies; smelting furnace at the workshop.
5. Harbour: sea fishing zone, fishing contest, smuggling crate job.
6. Race circuit: track checkpoints from roads, licences, sports venue buildings (football/basketball/boxing ring) as enterable arenas.
7. Story Act 1 beats (debt letter, first Vance visit, grandmother's notes) as a small quest model with data/story.json.
8. Economy + balance pass across jobs, crops, fish, ore, car prices.

## Gate
Walk from the homestead to the city, enter the bank, race a lap, mine one ore, and come home in under 15 real minutes without a loading hitch.
