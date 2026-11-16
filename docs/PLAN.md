# Plan (the runner checks items off in order; reorder allowed, cutting is not)

Rule: one pillar at a time; every new feature must connect to at least one other. Never leave `main` broken.

## Phase 0: Pre-production (weeks 1-4)
- [x] Godot 4 project scaffold (project.godot, scenes/, scripts/, assets/, tests/), run headless
- [x] Art: generate placeholder 32x32 grass/dirt/path tiles as PNG via a Python script (tools/gen_art.py)
- [x] Art: water tile (2 depth shades) + tree + rock + player sprite placeholders
- [x] Art: yellow interactable outline shader/helper
- [x] Core loop doc + save/load skeleton + input map
- [x] Name check note (Steam/itch/trademark) recorded in docs/NAME_CHECK.md

## Phase 0.5: Art pass to the owner's reference (docs/ART_TARGET.md) - owner priority 2026-11-16
- [x] Detailed original sprites (pine, oak, bush, rock, shore stones, lily pads, reeds, fish, dock, bearded player) via tools/gen_sprites.py
- [x] Painted ground shader: water depth + submerged boulders + ripples, mossy shore stones, layered grass, dirt path
- [x] Water decor placement (lily pads, reeds, swimming fish shadows) + dock at shore near spawn, camera zoom 2
- [x] Soft drop shadows under trees, rocks, bushes, player
- [ ] Tree/reed wind sway (vertex shader) and lily pad bob
- [ ] Prop reflections/darkening in water; dock shadow on water
- [ ] Higher-detail player (more frames, tool-use poses) and NPC base
- [ ] Bank height: raised grass edge over shore stones (3/4 depth illusion)
- [ ] Farm soil, crops and HUD/hotbar art in the same style (replace rect placeholders)

## Ongoing: Graphics & Physics polish (2+ items EVERY run, never finished; see RUNBOOK 5b)
Rule: add new items at the bottom whenever one is ticked, so this queue never runs dry.
Graphics:
- [x] Wind sway shader on trees, bushes, reeds (top moves, base fixed, whole-pixel steps, gusts)
- [x] Lily pads bob/drift and part around the player (reeds parting still to do)
- [x] Raised grass bank over shoreline stones (3/4 height illusion: stone face under north banks, sunlit grass lip)
- [x] Higher-detail player sheet 32x48 (6-frame walk, generic tool-swing pose) via tools/gen_player_hd.py
- [ ] Tool-specific poses and held tool sprites (hoe, axe, can, rod)
- [ ] Light rays / sun specular glints on water; foam where water meets dock posts
- [x] Ambient particles: drifting leaves, fireflies at night, dust when running (AmbientView/AmbientMath)
- [ ] Day/night: warm point lights at night (lanterns, windows), long evening shadows
- [ ] Weather: rain (drops + ripples), fog, storm darkening
- [x] Tool-hit feedback: wood chips, stone sparks, screen shake (squash on hit still to do)
Physics / feel:
- [x] Player acceleration + friction (no instant start/stop), tested in PlayerMath
- [x] Rounded/capsule player collider + corner sliding so you do not snag on trees
- [x] Trees and bushes fade semi-transparent when the player is behind them (player now y-sorts with props)
- [x] Footstep signal synced to walk frames (audio later); wet-bank slowdown, faster on paths
- [x] Knockback + hit-stop + whole-pixel shake framework (HitMath, wired to axe/pickaxe)
- [x] Vehicle physics prototype math (drift, grip, handbrake) for the car slice
- [ ] Reeds part when the player walks through; squash/stretch on tool hit
- [x] Shop BUY tab data-driven (items.json buy/buy_price; wood for building)
- [ ] Shop BUY tab: tools; sell-price display by planet (trade hook)
- [ ] Fishing: rod/bait upgrades, fish journal, legendary fish events
- [ ] Water: reflections of trees/player on the surface (flipped, tinted, wobbling)
- [ ] Grass tufts sway near the player; footprints on dirt paths
- [x] Camera: tiny look-ahead in walk direction (integer-snapped), hard limits at chunk edge (soft clamp math in CameraMath, unused yet)
- [ ] Vehicle: wire VehicleMath into a drivable car node (enter/exit, skid marks, tyre smoke on drift)
- [ ] Build: save/restore verified in-game, door open/close animation, wall autotiling (corners/T-joins)
- [ ] Day/night: ambient fireflies exist; add warm lanterns that light the ground
- [ ] Collision polish: shoreline collision follows the painted shore (not square tiles)

## Phase 1: Prototype (months 2-3)
- [x] Player scene: CharacterBody2D, 8-way move from input map, test movement vector math
- [x] Camera2D follow with integer pixel snap
- [x] 4-direction facing + walk-cycle placeholder animation
- [x] HUD: clock, day, season, money labels bound to GameState
- [x] Day/night tint from GameClock (CanvasModulate), bedtime/pass-out to next day with save
- [x] TileMap world chunk (64x64) generated from seed, with collision
- [x] Nearest-target highlight (yellow outline on the faced tree/rock)
- [x] Interactable base class + interact prompt (Interactables registry, E prompt label)
- [x] Inventory model + hotbar UI (tests: stack, add, remove) [model + tool hotbar done; item-slot hotbar UI still to do]
- [x] Tool use on facing tile: hoe tills soil
- [x] Plant seed from crops.json, watering can waters
- [x] Crop growth per day tick, harvest gives item
- [x] Energy bar limiting actions (Stardew-style limiter)
- [x] Fishing: cast on water tile, bite timer
- [x] Fishing: reel mini-game + fish table in data/fish.json
- [x] Visible fish shadows in water
- [x] Axe chops trees (hits, drops wood, stump/regrow)
- [x] Pickaxe breaks rocks (drops stone)
- [x] Build mode: grid ghost placement with valid/invalid colour
- [x] Placeable floor, wall, door, fence consuming inventory
- [ ] Roof + simple house/farm blueprint (pieces exist; add roof piece, blueprint stamp, interior fade when inside)
- [x] Shop logic: sell/buy functions with tests (scripts/shop.gd)
- [x] Shop UI: sell items to shop for money (market stall + ShopView)
- [x] Shop UI: buy seeds (tools: still to add to the BUY tab)
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
- Grid-building plugins separate placement rules (validators) from indicators, which our BuildModel.check mirrors; consider per-piece rules (needs floor beneath, wall adjacency) | https://chris-tutorials.itch.io/grid-building-godot/devlog | 2026-11-16
- Weakest part vs comparables (run 5): still no NPCs/animals/town and no goal loop beyond chores; build mode now exists but nothing to build for. Next: NPC base + routines.
- Use GUT or GdUnit4 for richer tests (mocking, signals) once scenes get complex | https://helpmetest.com/blog/godot-gut-advanced-testing/ | 2026-11-16
- Study Stardew balance analysis (crop profit vs time, energy as limiter) before tuning crops.json | https://mechanicsofmagic.com/2021/05/26/critical-play-balance-stardew-valley/ | 2026-11-16
- Pixel-art top-down movement: keep camera smoothing off + snap_2d_transforms_to_pixel to avoid sub-pixel jitter (applied) | https://forum.godotengine.org/t/the-character-shakes-when-moving/103543 | 2026-11-16
- Hit-stop should use real-time timers, trauma-based stacking shake | https://forum.godotengine.org/t/game-feel-effects-that-stack-without-fighting-your-code-trauma-shake-real-time-hit-stop-and-apply-the-difference/146379 | 2026-11-16
- Fishing minigame tuning: bar size/gravity vs fish darting; consider a bar-size upgrade via rod level | https://stardewvalleywiki.com/Fishing | 2026-11-16
- Weakest part vs comparables (2026-11-16 run 4): world is empty of life: no NPCs, animals or goals beyond farming/fishing; next priority NPCs + town. Earlier note: everything (no playable yet); priority is Phase 1 walk+farm loop for a 10-minute fun gate.
