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
- [x] Held tool sprites sweep during the swing (hoe, can, axe, pickaxe, rod, club; tools/gen_tools.py, HitMath.swing_angle). Per-tool body poses still to do
- [x] Sun glints on water (twinkling single pixels in ground shader)
- [x] Foam rings at dock posts (DockFoam)
- [x] Light rays on water
- [x] Ambient particles: drifting leaves, fireflies at night, dust when running (AmbientView/AmbientMath)
- [ ] Day/night: warm point lights at night (lanterns, windows), long evening shadows
- [x] Rain waters crops at day end (FarmModel.rain_water)
- [x] Weather: rain (drops + splashes, overcast darkening, seeded per day; WeatherMath)
- [x] Weather: rain ripples on water (WeatherMath.ripple, elliptical rings)
- [x] Weather: morning fog (WeatherMath.fog_for_day/fog_now, overlay)
- [x] Weather: storm lightning (WeatherMath.lightning_flash, full-screen flash on storms >=0.8 rain; thunder_delay for audio later)
- [x] (tools/run_tests.sh wrapper added) Test runner: fail the run when any SCRIPT ERROR / parse error appears in the output (found 2026-11-17: errors were printed while TESTS said 0 failed)
- [x] Tool-hit feedback: wood chips, stone sparks, screen shake (squash on hit still to do)
Physics / feel:
- [x] Player acceleration + friction (no instant start/stop), tested in PlayerMath
- [x] Rounded/capsule player collider + corner sliding so you do not snag on trees
- [x] Trees and bushes fade semi-transparent when the player is behind them (player now y-sorts with props)
- [x] Footstep signal synced to walk frames (audio later); wet-bank slowdown, faster on paths
- [x] Knockback + hit-stop + whole-pixel shake framework (HitMath, wired to axe/pickaxe)
- [x] Vehicle physics prototype math (drift, grip, handbrake) for the car slice
- [x] Reeds part when the player walks through (ReedMath + prop shader push)
- [x] Squash/stretch on tool swing (HitMath.squash, tested, wired to player sprite)
- [x] Shop BUY tab data-driven (items.json buy/buy_price; wood for building)
- [x] Planet price multipliers (data/planets.json, Shop/ShopMenu world-aware, tested)
- [x] Shop BUY tab: bait (worm/glow, data/bait.json; faster bites, wider reel bar). Tool upgrades still to do
- [x] Fish journal (count + best size per species, saved, shown on catch)
- [x] Fishing: bait (consumed per cast)
- [x] Fishing: rod upgrades (data/rods.json, buy in shop, stacks with bait)
- [ ] Fishing: legendary fish events, journal screen
- [x] Water: reflections of trees/rocks/bushes/player on the surface (flipped, tinted, wobbling)
- [x] Footprints on dirt paths (FootprintMath/View, fade)
- [x] Grass tufts sway near the player (gen_tufts.py sprite, WorldGen.tufts, ReedMath push, wind sway)
- [x] Camera: tiny look-ahead in walk direction (integer-snapped), hard limits at chunk edge (soft clamp math in CameraMath, unused yet)
- [x] Vehicle: wire VehicleMath into a drivable car node (enter/exit, skid marks, tyre smoke on drift)
- [ ] Build: save/restore verified in-game, door open/close animation, wall autotiling view (mask helper Autotile done and tested; needs wall sprite variants)
- [x] Day/night: warm lanterns that light the ground (Lantern + PointLight2D, DayNight.lamp_strength)
- [x] Physics: rain makes paths muddy (PlayerMath.wet_grip/wet_speed: slower start, longer slide)
- [x] Sprint (Shift/B): PlayerMath.sprint_mult/cost, drains energy; cops outrun walking at 4+ stars so sprint is the escape
- [x] Car hits knock pedestrians/cops over (CombatModel.car_hit + HitMath knockback, hit-and-run heat)
- [x] Collision polish: shoreline collision follows the painted shore (ShoreMath, bilinear sdf, 8px runs; --show-collision debug)

## Phase 1.5: Feel & polish (OWNER PRIORITY 2026-11-17, do these BEFORE new Phase 2/3 items; order chosen by owner: feel first)
Owner choices: mouse+keyboard like Stardew; houses are enterable (yours, NPCs', shops, robbery targets). Stardew-inspired.
Controls + camera (1, 9)
- [x] Mouse support: tile cursor (yellow in reach), left-click uses the tool on that tile, right-click interacts, wheel changes slot, Ctrl+wheel or +/- zoom (TargetMath, CursorView, legend line)
- [x] Tab/I opens the inventory screen
- [ ] Context action: when nothing is selected, E/click does the obvious thing (talk, open door, pick up, harvest); on-screen key hints shown in a small bottom-right legend, rebindable later
- [x] Camera zoom 1-3 (Ctrl+wheel, +/-) with a quick glide; look-ahead, pixel snap, shake and edge limits kept
- [x] Camera dead-zone follow (small free box before the camera moves), softer map-edge clamp
- [x] Camera zooms out one step while driving the car or riding the horse
Items, pickup, inventory (2, 3, 4)
- [x] Dropped items in the world (DropMath/DropsView; trees, rocks and crop harvests now drop pickups that pop, bob and magnet to you; fish/loot still go straight to the bag): chopped wood, stone, crops, loot, fish scraps drop as small bobbing sprites that magnet to the player within ~48px and are picked up (ItemDrop node + pure DropMath, tested; stack merges when full)
- [x] Item icons (tools/gen_items.py -> assets/sprites/items.png + data/item_icons.json; used by drops, still to wire into hotbar/inventory/shop): 16x16 icon per item in data/items.json (wood, stone, turnip, egg, milk, fish, seeds, bait...) via tools/gen_items.py; icons used in hotbar, inventory, shop, drops
- [x] Hotbar UI: icon slots with counts, selected highlight, selected-tool name, keys 1-9/0 (durability/quality tint still to do)
- [x] Inventory screen (Tab): 30-slot icon grid, hover tooltip (name, sell price), click-to-move/merge/swap, S sort, X trash, money + energy (item descriptions and tabs later)
- [x] Item rarity/quality border colours (normal/silver/gold like Stardew) and item names with plurals
Farming + working the land (7)
- [x] Tilled soil autotile (connected furrows, darker wet soil), 5-stage turnip + generic crop sprites (tools/gen_farm.py, FarmModel.stage), dirt puff on tilling; harvest pops as pickups
- [ ] (dirt particles done) Hoe dig animation; scythe/hand cuts grass for fibre/hay; weeds appear and can be cleared
- [x] Watering can holds 20 water (refill by using it on water, bar on the hotbar slot, saved; WaterCan). [ ] 3x1 line upgrade, scarecrow + sprinkler placeable
- [x] Skill xp + levels (SkillModel: farming/foraging/mining/fishing, +5%/level bonus harvest, shown in bag, saved). [ ] Seed packets by season, crop quality by fertiliser
Wood chopping (8)
- [x] Trees take 5 axe hits with canopy wobble + falling leaves, topple away from you (ChopFx), leave a stump (gen_stump.py) and drop wood pickups; regrow after days (sap/seed drops and saplings still to do)
- [x] Axe upgrades (copper/iron) cut faster (ResourceNodes.hit power param done and tested; need items/shop); logs and big stumps need a better axe
Fishing (6)
- [x] Fishing visuals: line from the rod tip, bobber that bobs/dips, splash rings, "!" alert, framed reel bar with the fish icon (BobberMath, FishingWorldView). Hold-to-cast done (power bar, 2-7 tiles, CastMath; farther = deeper water)
- [ ] Fish icons, fish pop out of the water onto the player, treasure chests in the mini-game, crab pots placeable, legendary fish events and journal screen (existing items kept)
Houses, buildings, graphics (5, 10)
- [x] Interior system: E at a door -> fade -> room (InteriorModel layouts, InteriorView, 16 interior sprites via tools/gen_interior.py), walk out through the door gap to return to the exact outside spot; barn, workshop, farmhouse walk-in, other houses after picking the lock
- [x] Farmhouse placed near the start with a bed (E sleeps: next day, crops grow, autosave). [ ] storage chest, kitchen/cooking, NPC home furniture; NPC houses and the market/workshop interiors with counters; robbery loot inside rooms (dogs, noise) reusing RobberyModel
- [x] (chimney smoke + window lights at night done; existing sprites already have shingles/windows) Building art pass: roofs with shingle detail and chimney smoke, windows that glow at night, porches, painted wood trim, fences/gates, paths; new building sprites via tools/gen_town.py
- [ ] Graphics pass: tile transitions (grass->path->dirt), seasonal tree/ground colours, flowers, water edge foam, better UI frame art, consistent outlines (see docs/ART_TARGET.md)

- [x] Graphics: clustered meadow flowers in 6 colours that sway and bend away from you (tools/gen_flowers.py)
- [ ] Graphics: seasonal ground/tree colours, grass-to-path tile transitions, porches and fences art
- [ ] Physics: camera look-ahead tuned for dead zone at car speeds
- [ ] Physics: stamina-based sprint inertia, dust on hard direction changes, mount stamina

## Backlog additions (2026-11-17 research)
- Stardew-like satisfaction comes from small visible progress each day (skill levels, quality stars, tool upgrades) plus low-stress loops: https://www.popsci.com/health/stardew-valley-psychology-farming/ and https://mechanicsofmagic.com/?p=1915 . Weakest part of Starstead vs Stardew: progression feedback (no levels/upgrades before today) -> added skills + axe upgrades; next: pickaxe/hoe/can upgrades, level-up fanfare, crop quality stars.
- [ ] Pickaxe/hoe/watering-can upgrades via data/*.json like axes; skill-based perks (level 5 choices)
- [ ] Level-up fanfare (sparkle + toast sound-ready), skill bars in bag

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
- [x] Roof piece, blueprint stamp (hut) and enclosed-room detection in BuildModel (tests)
- [x] Wire blueprint stamp key + roof/interior fade into BuildView
- [x] Shop logic: sell/buy functions with tests (scripts/shop.gd)
- [x] Shop UI: sell items to shop for money (market stall + ShopView)
- [x] Shop UI: buy seeds (tools: still to add to the BUY tab)
- [ ] Car: enterable garage/workshop interior with real repair menu
- [ ] Gate: fun in the first 10 minutes (log self-playtest in docs/PLAYTEST.md)

## Phase 2: Vertical slice (months 4-6)
- [x] NPC schedule model + data/npcs.json (NpcSchedule, tested)
- [x] NpcView: spawn NPC sprites, walk their schedule in the world, talk prompt
- [x] NPC A* pathing around trees/rocks/water (NpcPath, AStarGrid2D)
- [x] NPC dialogue box with per-NPC lines (data/npcs.json)
- [x] Town layout model (TownModel) + barn/workshop/houses placed near NPC places with collision and door prompts (art tools/gen_town.py)
- [ ] Town: enterable interiors, farm fences/field around the barn, roads between buildings
- [x] One drivable car (CarView: E enter/exit, VehicleMath, fuel, skid marks, tyre smoke; crash damage, speed cap, wood repair near the workshop)
- [x] Robbery model (RobberyModel, data/loot.json: locks, lockpick, noise, loot, NPC memory/dog; tested)
- [x] One house to rob in play: RobberyView on town doors (E pick lock, E loot, noise wakes residents -> heat, memory)
- [ ] Robbery: enter interior scene, dogs bark, police respond to noise
- [x] Wanted-level model (WantedMath: heat, stars, decay, police count, fine; tested)
- [x] Wanted HUD stars + police NPC spawn + chase + arrest/fine (PoliceModel/PoliceView; car hit-and-run is the first crime)
- [x] Basic combat: club tool (key 8), swing cone, NPC/cop health + knock-out + knockback + assault heat (CombatModel/CombatView)
- [ ] More crime triggers (theft from stalls, car theft) and combat on animals/dogs
- [x] Animal model (AnimalModel, data/animals.json: taming trust, production, riding, gear slots; tested)
- [x] Animal in play: wild chickens+horse roam/flee, feed turnips to tame (E), tamed follow + daily eggs, ride horse (AnimalView, saved)
- [ ] Animal gear UI (saddle/coat/armour) and more species (cow, sheep) with a pen
- [x] Job + race models (JobModel/RaceModel, data/jobs.json; tested)
- [x] Jobs in play: J key shift at barn/market stall/workshop (JobView: pay, xp ranks, rep, clock; saved xp)
- [x] Race in play: R while driving starts a checkpoint lap vs a rival driver, prize by place, best time (RaceView)
- [ ] Races: lap count/menu, other drivers, race track on the roads, sports venues
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
- Melee juice: hitbox/hurtbox + i-frames, hit flash, knockback, hit-stop (done: flash/knockback/stop); add i-frames + enemy attack telegraphs next | https://www.gdquest.com/library/juicy_attack , https://dev.to/saltmire/godot-4-hitbox-and-hurtbox-the-easy-way-damage-teams-i-frames-knockback-1ccj | 2026-11-17
- Weakest vs comparables (2026-11-17): Palworld/Core Keeper have creature variety + base building loops; we have 2 species and no pen/barn use. Next: cow/sheep in a fenced pen at the barn, gear UI, dogs for robbery defence.
- Cops cannot fight back yet (no player health): add player HP/knock-out + hospital fee | 2026-11-17
(runner appends here: idea, source link, date)
- Town layout generators (house footprints along roads, plaza first) | https://forum.godotengine.org/t/procedural-environment-generation-in-godot-a-whole-city/5296 | 2026-11-17
- Weakest vs comparables (2026-11-17): town is buildings with locked doors and no interiors; next: enterable house/shop interiors, then robbery slice.
- Rain puddle ripples + reflections floor shader, 4-frame pixel rain/reflection animation | https://godotshaders.com/?p=11585 , https://budgetpixel.com/blog/how-to-animate-pixel-art-rain-and-reflections-in-4-frames | 2026-11-17
- Thunder/lightning flash for storms | https://jacobjustice.itch.io/feed/devlog/759034/basic-2d-rain-thunder-and-lightning-in-godot | 2026-11-17
- Weakest vs comparables (2026-11-17): towns still have no buildings (NPCs wander an empty plaza); next: small town layout with house blueprints, then drivable car.
- NPCs currently walk straight lines and slide along water; replace with AStarGrid2D over land cells for routes around trees/buildings | https://papierkorp.github.io/blog/posts/godot-4-2d-pathing | 2026-11-17
- NPC art is a tinted copy of the player sheet: needs distinct NPC sprites + dialogue box + houses at the schedule places | 2026-11-17
- Roof piece only fades over enclosed floors; hut blueprint has a single interior cell, add a bigger house blueprint with roof cells | 2026-11-17
- NPC schedule techniques (time-slot tables, pathing to place targets) | https://forum.godotengine.org/t/what-technique-should-i-use-for-a-schedule/138270 | 2026-11-17
- Weakest vs comparables (2026-11-17): NPC data exists but nobody is visible in the world yet; NpcView is the next priority.
- Grid-building plugins separate placement rules (validators) from indicators, which our BuildModel.check mirrors; consider per-piece rules (needs floor beneath, wall adjacency) | https://chris-tutorials.itch.io/grid-building-godot/devlog | 2026-11-16
- Weakest part vs comparables (run 5): still no NPCs/animals/town and no goal loop beyond chores; build mode now exists but nothing to build for. Next: NPC base + routines.
- Use GUT or GdUnit4 for richer tests (mocking, signals) once scenes get complex | https://helpmetest.com/blog/godot-gut-advanced-testing/ | 2026-11-16
- Study Stardew balance analysis (crop profit vs time, energy as limiter) before tuning crops.json | https://mechanicsofmagic.com/2021/05/26/critical-play-balance-stardew-valley/ | 2026-11-16
- Pixel-art top-down movement: keep camera smoothing off + snap_2d_transforms_to_pixel to avoid sub-pixel jitter (applied) | https://forum.godotengine.org/t/the-character-shakes-when-moving/103543 | 2026-11-16
- Hit-stop should use real-time timers, trauma-based stacking shake | https://forum.godotengine.org/t/game-feel-effects-that-stack-without-fighting-your-code-trauma-shake-real-time-hit-stop-and-apply-the-difference/146379 | 2026-11-16
- Fishing minigame tuning: bar size/gravity vs fish darting; consider a bar-size upgrade via rod level | https://stardewvalleywiki.com/Fishing | 2026-11-16
- Weakest part vs comparables (2026-11-16 run 4): world is empty of life: no NPCs, animals or goals beyond farming/fishing; next priority NPCs + town. Earlier note: everything (no playable yet); priority is Phase 1 walk+farm loop for a 10-minute fun gate.
- Wanted\/heat system design: heat decays faster out of sight, unwitnessed crimes weigh less | https://bugnet.io/blog/how-to-design-a-wanted-or-heat-system , https://gta.fandom.com/wiki/GTA_2_Wanted_Level | 2026-11-17
- GTA-style solo Godot 4 systems showcase (police AI, wanted, chase) for reference | https://forum.godotengine.org/t/building-an-gta-inspired-open-world-crime-game-solo-showcasing-the-systems-ive-built-in-godot-4-6/137378 | 2026-11-17
