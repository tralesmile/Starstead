# Plan (the runner checks items off in order; reorder allowed, cutting is not)

Rule: one pillar at a time; every new feature must connect to at least one other. Never leave `main` broken.

## Phase 0: Pre-production (weeks 1-4)
- [x] Godot 4 project scaffold (project.godot, scenes/, scripts/, assets/, tests/), run headless
- [x] Art: generate placeholder 32x32 grass/dirt/path tiles as PNG via a Python script (tools/gen_art.py)
- [x] Art: water tile (2 depth shades) + tree + rock + player sprite placeholders
- [x] Art: yellow interactable outline shader/helper
- [x] Core loop doc + save/load skeleton + input map
- [x] Name check note (Steam/itch/trademark) recorded in docs/NAME_CHECK.md

## Phase 1: Prototype (months 2-3)
- [x] Player scene: CharacterBody2D, 8-way move from input map, test movement vector math
- [x] Camera2D follow with integer pixel snap
- [x] 4-direction facing + walk-cycle placeholder animation
- [ ] HUD: clock, day, season, money labels bound to GameState
- [ ] Day/night tint from GameClock (CanvasModulate), bedtime/pass-out to next day with save
- [ ] TileMap world chunk (64x64) generated from seed, with collision
- [ ] Interactable base class + nearest-target highlight (yellow outline) + interact prompt
- [ ] Inventory model + hotbar UI (tests: stack, add, remove)
- [ ] Tool use on facing tile: hoe tills soil
- [ ] Plant seed from crops.json, watering can waters
- [ ] Crop growth per day tick, harvest gives item
- [ ] Energy bar limiting actions (Stardew-style limiter)
- [ ] Fishing: cast on water tile, bite timer
- [ ] Fishing: reel mini-game + fish table in data/fish.json
- [ ] Visible fish shadows in water
- [ ] Axe chops trees (hits, drops wood, stump/regrow)
- [ ] Pickaxe breaks rocks (drops stone)
- [ ] Build mode: grid ghost placement with valid/invalid colour
- [ ] Placeable floor, wall, door, fence consuming inventory
- [ ] Roof + simple house/farm blueprint
- [ ] Shop UI: sell items to shop for money
- [ ] Shop UI: buy seeds/tools
- [ ] Gate: fun in the first 10 minutes (log self-playtest in docs/PLAYTEST.md)

## Phase 2: Vertical slice (months 4-6)
- [ ] Small town + farm, NPCs with routines
- [ ] One drivable car (top-down physics), fuel/repair stub
- [ ] One house to rob (enter, loot, noise, police response, NPC memory)
- [ ] Police/wanted-level basics, basic combat
- [ ] One animal to catch, tame and ride; clothes slot on animals
- [ ] First jobs (3) and first sport (racing)
- [ ] Gate: trailer-ready + Steam page text/screens

## Phase 3: Earth alpha (months 7-15)
- [ ] Full Earth map (farmland, forest, lake, city, caves)
- [ ] All jobs (farmer, mechanic, police, doctor, chef, builder, delivery, miner, astronaut), promotions, own business
- [ ] Sports: car/bike racing, football, basketball, boxing, fishing contests, animal races
- [ ] Mining caves, ore, smelting; forge/garage/workshop crafting of cars, weapons, equipment
- [ ] Full building system incl. shops, garages, sports venues, locks/alarms/dogs/safes
- [ ] Animals: livestock resources (milk/wool/eggs/hides), taming, riding, animal clothing = gear
- [ ] Honest vs street reputation; economy and balance pass
- [ ] Story Acts 1 and 2
- [ ] Gate: Steam demo, then Early Access

## Phase 4: Beyond Earth (month 16+)
- [ ] Rocket building; Moon (low gravity, domes/oxygen, greenhouse farming, lunar mining, buggy racing, Act 3)
- [ ] Interplanetary trade and smuggling
- [ ] Dinosaur/jungle planet (tame and ride dinosaurs), ice planet, desert planet (Act 4)
- [ ] Endgame (Act 5), carry house to ship module

## Backlog (ideas found by research; promote into phases)
(runner appends here: idea, source link, date)
- Use GUT or GdUnit4 for richer tests (mocking, signals) once scenes get complex | https://helpmetest.com/blog/godot-gut-advanced-testing/ | 2026-11-16
- Study Stardew balance analysis (crop profit vs time, energy as limiter) before tuning crops.json | https://mechanicsofmagic.com/2021/05/26/critical-play-balance-stardew-valley/ | 2026-11-16
- Weakest part vs comparables right now: everything (no playable yet); priority is Phase 1 walk+farm loop for a 10-minute fun gate.
