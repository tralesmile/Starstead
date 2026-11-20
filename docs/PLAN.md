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
- [x] Tree/reed wind sway (vertex shader) and lily pad bob (done in the Ongoing list; ticked run 14)
- [x] Prop reflections/darkening in water; dock shadow on water (soft dark silhouette under the planks, 2026-11-18)
- [x] Higher-detail player (more frames, tool-use poses) and NPC base (player_hd 32x48; NPC base = tools/gen_npcs.py villager sheet, run 14)
- [x] Bank height: raised grass edge over shore stones (3/4 depth illusion) (done in the Ongoing list; ticked run 14)
- [ ] Farm soil, crops and HUD/hotbar art in the same style (replace rect placeholders)

## Ongoing: Graphics & Physics polish (2+ items EVERY run, never finished; see RUNBOOK 5b)
- [x] Run 12: Graphics: held fishing rod with charge/cast/bite poses (RodMath tested). Physics: planting your feet during a tool swing (PlayerMath.swing_slow 0.35x, tested). [ ] next: fishing cast pose frames, swing slow only for heavy tools
Rule: add new items at the bottom whenever one is ticked, so this queue never runs dry.
Graphics:
- [x] Run 13: road barricades with warning sign at story gates (before: roads just ran into the city on day 1; after: the road visibly ends at a striped barrier). [x] Run 14: soft two-step shadow on the water south-east of causeways/roadside banks (ground shader, warped path-mask lookup). [ ] next: wet footprints on quay, reflections of pedestrians in puddles
- [x] Port Halden plazas: checkered slab tone, terracotta inlays, 8 planters (run 11). [ ] Next graphics ideas: shadow under bridges/causeways on water, wet footprints on quay
- [x] Port Halden asphalt with painted lane dashes, paved sidewalk slabs, crisp cell-exact street edges (ground shader, texelFetch); city window glow and streetlamp pools at night
- [x] Zebra crossings (CityModel.zebra, bars across the avenue and the streets) and a curb shadow/lit lip between sidewalk and street (ground shader). [x] wet-asphalt shine and puddles in rain (ground shader `wet`, World.set_wet)
- [x] Harbour quay in the paved-slab shader look (grey stone, sunlit curb) instead of orange dirt
- [x] Wind sway shader on trees, bushes, reeds (top moves, base fixed, whole-pixel steps, gusts)
- [x] Lily pads bob/drift and part around the player (reeds parting still to do)
- [x] Raised grass bank over shoreline stones (3/4 height illusion: stone face under north banks, sunlit grass lip)
- [x] Higher-detail player sheet 32x48 (6-frame walk, generic tool-swing pose) via tools/gen_player_hd.py
- [x] Held tool sprites sweep during the swing (hoe, can, axe, pickaxe, rod, club; tools/gen_tools.py, HitMath.swing_angle). Per-tool body poses still to do
- [x] Sun glints on water (twinkling single pixels in ground shader)
- [x] Foam rings at dock posts (DockFoam)
- [x] Light rays on water
- [x] Ambient particles: drifting leaves, fireflies at night, dust when running (AmbientView/AmbientMath)
- [x] Long evening shadows (ShadowMath: shadows lean west in the morning, east at dusk, stretch near the horizon, fade at night; World.apply_sun). [ ] warm point lights at night (lanterns, windows partly done)
- [x] Rain waters crops at day end (FarmModel.rain_water)
- [x] Weather: rain (drops + splashes, overcast darkening, seeded per day; WeatherMath)
- [x] Weather: rain ripples on water (WeatherMath.ripple, elliptical rings)
- [x] Weather: morning fog (WeatherMath.fog_for_day/fog_now, overlay)
- [x] Weather: storm lightning (WeatherMath.lightning_flash, full-screen flash on storms >=0.8 rain; thunder_delay for audio later)
- [x] (tools/run_tests.sh wrapper added) Test runner: fail the run when any SCRIPT ERROR / parse error appears in the output (found 2026-11-17: errors were printed while TESTS said 0 failed)
- [x] Tool-hit feedback: wood chips, stone sparks, screen shake (squash on hit still to do)
Physics / feel:
- [x] Run 13: camera recentre when standing still + per-tool swing plant (tested). [x] Run 14: sprint zoom punch (CameraMath.sprint_zoom: 4% kick out when a sprint starts, decays in ~0.3 s, holds 5% out while running; tested). [ ] next: tyre squeal audio, landing squash after a jump/fall
- [x] Drift smoke by surface (VehicleMath.smoke_style: white tyre smoke on asphalt, tan dust on paths, olive dust on grass, thin in rain, puffs scale with slide angle; tested). [ ] tyre squeal audio, drift leaderboard
- [x] Circuit kerb rumble (VehicleMath.rumble: shake + 8% grip loss on red/white kerbs) and slipstream drafting (VehicleMath.slipstream, up to +8% top speed behind a rival), both tested
- [x] Graphics: car headlights (cone beams) + tail lights at night, brake lights flare (VehicleMath.light_levels). [x] tyre marks linger 40 s on the circuit (skid_life, tested)
- [x] Physics: pit-lane/infield speed limit (DriftScore.pit_cap) and drift scoring on the circuit (DriftScore: multiplier by drift time, banks on clean exit, crash loses it, best saved). [ ] drift leaderboard/ghost, tyre squeal audio
- [x] Car high-speed understeer (VehicleMath.steer_scale: up to 40% less steering at top speed; tested)
- [x] Car tyre grip by surface (VehicleMath.surface_grip: asphalt 1.2, path 0.95, grass 0.7, wet bank 0.5, rain slicks asphalt most), wired into the car step
- [x] Car is capped to half speed on city sidewalks (VehicleMath.surface_cap sidewalk, tested). [x] skid mark opacity by surface (VehicleMath.skid_alpha: asphalt strongest, rain washes out) and kerb bump (VehicleMath.kerb_bump: fast drop onto a sidewalk/quay loses up to 25% speed + camera jolt, tested). [ ] tyre squeal audio
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
- [x] Fishing: journal screen (J: silhouettes until caught, count, best size, depth/season hints; FishJournal.rows tested). [ ] legendary fish events
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

## OWNER PLAYTEST 2026-11-18 (human hands-on; do these BEFORE Phase 3 slices, top to bottom)
- [x] K quest log did not close (stale canvas redraw after close; StoryView now redraws on toggle)
- [x] Camera too close: default zoom 1.5x (TargetMath.ZOOMS 1/1.5/2/3, +/- cycles; tested)
- [x] Wanted HUD looked bad: drawn badge with 5 stars that fill with heat + red/blue siren strip when seen (WantedHud, tested); cops lighter police-blue instead of black faces
- [x] Hunting: club hits wild animals (HuntModel + AnimalView.hunt), drops raw meat / hide / feathers, boar fights back, game restocks overnight; new deer, rabbit, boar sprites (gen_wildlife.py), more wildlife around the start (WILD table), Grilled Meat recipe. [ ] bow/traps, butcher/tannery, fists on the hand slot, hunting licence/ranger heat
- [x] First 30 seconds: new game starts with hoe, axe, hand and seeds; C opens the craft menu (wood -> can, scythe, club, rod, pickaxe; ToolKit/CraftView, data/crafting.json, saved, old saves own everything), unowned hotbar slots dim, goal line says chop wood + craft the can. [ ] craft bench prop, stone/iron tool tiers via smelting, a tutorial arrow
- [x] Crops: show growth time (days left / stage bar on hover), and redo hoed-dirt, crop and watering art (they look bad) (CropInfo hover label + stage bar, new soil rows and sprout art; tested)
- [x] Fishing: character visibly holds the rod (RodMath: leans back while charging, whips forward on release, tip dips on a bite, flexes while reeling; line starts at the tip). [x] fish jumping out of the water (run 14, LeapMath). [ ] cast/reel player pose frames
- [x] Chopping: tree should fall, then be chopped into logs you pick up (TreeFall: last hit topples the tree, trunk needs 2 chops, wood drops; tested. logs not saved)
- [x] Map: M world map with the town, roads, circuit, harbour, player marker (owner could not find the town) (MapModel/MapView: M opens terrain+roads+regions+POIs+player dot, fuel stations in orange with nearest-fuel hint; tested)
- [x] Race start line: R only works at a start line (chequered strip beside the parked car, or the circuit line), prompt tells you where to drive (RaceModel.gate_near, StartGateView). Fuel gauge + fuel stations on the map done; still: bigger car, race start line prompt), mark fuel station(s) on the map/prompt where to refuel; race must start at a marked start line, not wherever you press R
- [x] Energy bar: make energy readable (bar + number in the HUD) (HudBars: green/amber/red bar with number, blinks when low; car fuel gauge while driving)
- [x] Movement/sprint/camera feel pass: camera drifts back onto the player after 0.35 s standing still (CameraMath.recenter, tested); swing slow depends on the tool (PlayerMath.tool_plant: axe/pickaxe/club 0.35, hoe/scythe 0.55, can/rod/hand 0.85, tested). [x] sprint zoom punch (run 14). [ ] hands-on check by owner
- [ ] Graphics overall: owner says nothing feels real; raise the art bar toward docs/ART_TARGET.md (characters, farm tiles, UI), sports/racing feel. Run 14: [x] UI: framed wooden HUD panel (day dial with sun/moon, date, time, coin + $1,234 money, energy bar inside; HudText.dial/money_text tested; right-aligned text no longer spills). [x] characters: villager sheet replaces tinted clones. [x] hotbar: wooden tray, inset parchment slots, lifted gold-framed pick, name tag above it, outlined counts. [ ] farm tiles, sports/racing feel
- [x] Story-first start: data/gates.json locks Port Halden, harbour and circuit until the Vance visit (step vance_car, day 3), the Highlands until the ledger visit, the Vance yard until the debt is cleared. StoryGate/Keeper bounces walker or car back with a message, red-white road barricades (tools/gen_barrier.py) stand on the roads and vanish when the story opens them; demo flags bypass (use --gated to test). Tested. [x] map shows locked regions (run 14: red hatching over gated chunks, LOCKED tags on POIs, short hints from gates.json; MapModel.locked_regions tested). [x] NPC hint about the closed road (run 14: every other talk a villager gossips about a still-closed road, data/gates.json "gossip", Dialogue.gate_gossip tested). [ ] planets gate (rocket)

## Phase 1.5: Feel & polish (OWNER PRIORITY 2026-11-17, do these BEFORE new Phase 2/3 items; order chosen by owner: feel first)
Owner choices: mouse+keyboard like Stardew; houses are enterable (yours, NPCs', shops, robbery targets). Stardew-inspired.
Controls + camera (1, 9)
- [x] Mouse support: tile cursor (yellow in reach), left-click uses the tool on that tile, right-click interacts, wheel changes slot, Ctrl+wheel or +/- zoom (TargetMath, CursorView, legend line)
- [x] Tab/I opens the inventory screen
- [x] Context action (partly): E talks/opens doors/enters/rides already, and now harvests a ripe crop on the faced or underfoot tile with any tool in hand (ContextAction, tested). [ ] pick up drops/open chest; also on-screen key hints shown in a small bottom-right legend, rebindable later
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
- [x] Weeds sprout on fallow tilled soil overnight (deterministic, capped at half the fields, block planting) and the new scythe (hotbar 9, frame 7) cuts them for fibre (FarmModel.spawn_weeds/cut_weed, saved). [x] scythe cuts wild grass tufts for hay (run 14: World.cut_tuft, grass puff, hay icon, cows/sheep/horses eat hay before turnips, tested). [ ] Hoe dig animation
- [x] Watering can holds 20 water (refill by using it on water, bar on the hotbar slot, saved; WaterCan). [x] 3x1 line upgrade (done via hoe/can tiers). [x] Sprinkler (shop 120, hotbar 0, waters 3x3 each night, hand picks it up, saved; gen_sprinkler.py). [ ] scarecrow
- [x] Skill xp + levels (SkillModel: farming/foraging/mining/fishing, +5%/level bonus harvest, shown in bag, saved). [x] Seed packets by season: potato (spring), tomato (summer), pumpkin (autumn) with icons, shop, wrong-season message; press the seed key again to cycle seeds; ripe fruit tinted. [x] crop quality: silver/gold crops by farming level (QualityMath, items share the base icon, cooking accepts them, rarity borders). [x] fertiliser (run 14: craft 2 hay + 1 fibre -> 3 in the C menu, item recipes in crafting.json, hotbar slot 0 cycles sprinkler/crab pot/fertiliser, +12% gold chance on the next harvest, green flecks on the soil, saved; tested)
Wood chopping (8)
- [x] Trees take 5 axe hits with canopy wobble + falling leaves, topple away from you (ChopFx), leave a stump (gen_stump.py) and drop wood pickups; regrow after days (sap/seed drops and saplings still to do)
- [x] Axe upgrades (copper/iron) cut faster (ResourceNodes.hit power param done and tested; need items/shop); logs and big stumps need a better axe
Fishing (6)
- [x] Fishing visuals: line from the rod tip, bobber that bobs/dips, splash rings, "!" alert, framed reel bar with the fish icon (BobberMath, FishingWorldView). Hold-to-cast done (power bar, 2-7 tiles, CastMath; farther = deeper water)
- [ ] [x] fish pop out of the water onto the player (run 14: LeapMath arc with 1.5 flips, ground shadow, water drops, landing squash; tested; --leap-demo). [x] treasure chests in the mini-game (run 14: 18% of reels, keep the bar on the chest to open it while the fish slips, loot only if the fish is landed; Fishing.treasure_loot tested). [ ] Fish icons, [x] crab pots placeable (shop 150, hotbar 0 cycles sprinkler/crab pot, fill overnight, hand empties; CrabPots tested, saved) and legendary River King + journal screen
Houses, buildings, graphics (5, 10)
- [x] Interior system: E at a door -> fade -> room (InteriorModel layouts, InteriorView, 16 interior sprites via tools/gen_interior.py), walk out through the door gap to return to the exact outside spot; barn, workshop, farmhouse walk-in, other houses after picking the lock
- [x] Farmhouse placed near the start with a bed (E sleeps: next day, crops grow, autosave). [x] storage chest in the farmhouse (E near it: ChestView, click/shift-click moves stacks, saved; ChestModel tested). [x] kitchen/cooking (farmhouse stove: CookView, 6 recipes in data/recipes.json, dishes restore energy, right-click a dish in the bag to eat; CookModel tested). [ ] NPC home furniture; NPC houses and the market/workshop interiors with counters; robbery loot inside rooms (dogs, noise) reusing RobberyModel
- [x] (chimney smoke + window lights at night done; existing sprites already have shingles/windows) Building art pass: roofs with shingle detail and chimney smoke, windows that glow at night, porches, painted wood trim, fences/gates, paths; new building sprites via tools/gen_town.py
- [ ] Graphics pass: tile transitions (grass->path->dirt), seasonal tree/ground colours, flowers, water edge foam, better UI frame art, consistent outlines (see docs/ART_TARGET.md)

- [x] Graphics: clustered meadow flowers in 6 colours that sway and bend away from you (tools/gen_flowers.py)
- [x] Graphics: lapping white shore foam in the ground shader (2026-11-18)
- [x] Graphics: grass-to-path transition in the ground shader (dark fringe, lit blade tips, grass creeping onto the dirt rim). [x] seasonal ground/tree colours (SeasonMath: warm summer, orange autumn leaves/grass, frosted pale winter, flowers hidden; ground shader season_mul/frost; --season=N demo flag). [x] fences autotile (build_fence_auto.png 16 frames, BuildView refreshes neighbours). [ ] porches art
- [x] Physics: camera look-ahead grows to 56px and the dead zone shrinks to 2x1 at car speeds (CameraMath.look_for_speed/box_for_speed, Player.ext_velocity, tested)
- [x] Physics: sprint inertia (PlayerMath.sprint_ease) and skid dust on hard reversals (is_skid). [x] mount stamina (MountMath, winded trot, bar; found already wired). [x] car top speed by ground (roads full, grass 0.82, wet bank 0.55, rain; VehicleMath.surface_cap)

## Backlog additions (2026-11-17 research)
- Chunk streaming / roads (2026-11-18, run 4): https://forum.godotengine.org/t/how-to-build-a-2d-open-world/105697 , https://godotengine.org/asset-library/asset/5268 (Chunk Loader), https://docsearch.algolia.com/mcp/docs/repo/theduckcow/godot-road-generator (road generator ideas). Weakest part of Starstead vs Core Keeper/Palworld this run: the world was one 64x64 pond-map; fixed by E1/E2. Next weakest: nothing to do outside the homestead (no NPCs/animals/cars beyond it) -> E3 city block.
- Game juice / feel (2026-11-17, run 3): small feedback on every action (screen pop, particles, banner) is what makes Stardew-like tool use satisfying: https://eolt.org/articles/game-feel/ and https://sites.google.com/view/game-dev-guide/home/construct/game-juice . Weakest part of Starstead vs Stardew this run: level/reward feedback (fixed: fanfare + skill bars) and interaction clarity (context action started). Ideas: crop quality stars, tool-use body poses, mount stamina.
- Stardew-like satisfaction comes from small visible progress each day (skill levels, quality stars, tool upgrades) plus low-stress loops: https://www.popsci.com/health/stardew-valley-psychology-farming/ and https://mechanicsofmagic.com/?p=1915 . Weakest part of Starstead vs Stardew: progression feedback (no levels/upgrades before today) -> added skills + axe upgrades; next: pickaxe/hoe/can upgrades, level-up fanfare, crop quality stars.
- [x] Pickaxe upgrades (pickaxes.json, copper/iron, shop). [x] Hoe/watering-can upgrades (copper/iron: till/water 2-3 tiles in a line, can 40/60 water; LineMath, hoes.json, cans.json, icons, shop). [ ] skill-based perks (level 5 choices)
- [x] Level-up fanfare (LevelFx sparkle ring + rising banner, skill-coloured, fishing too) and coloured skill bars in the bag (LevelFxMath, tested)
- [x] Floating \"+2 Wood\" pickup labels with item icons (FloatFx/FloatMath, tested)

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
- [x] Car: workshop workbench opens a garage menu (repair, refuel, repaint for money; GarageModel tested, paint saved)
- [ ] Gate: fun in the first 10 minutes (log self-playtest in docs/PLAYTEST.md)

## Phase 2: Vertical slice (months 4-6)
- [x] NPC schedule model + data/npcs.json (NpcSchedule, tested)
- [x] NpcView: spawn NPC sprites, walk their schedule in the world, talk prompt
- [x] NPC A* pathing around trees/rocks/water (NpcPath, AStarGrid2D)
- [x] NPC dialogue box with per-NPC lines (data/npcs.json)
- [x] Town layout model (TownModel) + barn/workshop/houses placed near NPC places with collision and door prompts (art tools/gen_town.py)
- [ ] Town: enterable interiors, farm fences/field around the barn (run 14: paddock, footpaths, bare-earth field plot south of the barn), roads between buildings
- [x] One drivable car (CarView: E enter/exit, VehicleMath, fuel, skid marks, tyre smoke; crash damage, speed cap, wood repair near the workshop)
- [x] Robbery model (RobberyModel, data/loot.json: locks, lockpick, noise, loot, NPC memory/dog; tested)
- [x] One house to rob in play: RobberyView on town doors (E pick lock, E loot, noise wakes residents -> heat, memory)
- [x] Robbery: enter interior scene, dogs bark, police respond to noise (interiors + loot furniture existed; run 14: houses that got a dog from NPC memory now have a visible guard dog that wakes, chases and barks, each bark is noise toward waking residents -> heat; raw meat keeps it chewing; DogMath tested, gen_dog.py, --dog-demo)
- [x] Wanted-level model (WantedMath: heat, stars, decay, police count, fine; tested)
- [x] Wanted HUD stars + police NPC spawn + chase + arrest/fine (PoliceModel/PoliceView; car hit-and-run is the first crime)
- [x] Basic combat: club tool (key 8), swing cone, NPC/cop health + knock-out + knockback + assault heat (CombatModel/CombatView)
- [x] Stall theft (T at the market stall: 3 grabs/day, vendor may shout and raise heat; StallTheft tested). [ ] car theft and combat on animals/dogs
- [x] Animal model (AnimalModel, data/animals.json: taming trust, production, riding, gear slots; tested)
- [x] Animal in play: wild chickens+horse roam/flee, feed turnips to tame (E), tamed follow + daily eggs, ride horse (AnimalView, saved)
- [x] cow and sheep roam, tame and give milk/wool (sprites, LOOK table). [x] pen: E on a fed tame animal toggles stay/follow, stayers wander within 56px of their spot and fences/walls block animals (AnimalModel.pen_target). [x] Animal gear (G next to a tamed animal wears/removes saddle, coat, armour from the bag; shop sells them; tint; AnimalModel.next_gear tested)
- [x] Job + race models (JobModel/RaceModel, data/jobs.json; tested)
- [x] Jobs in play: J key shift at barn/market stall/workshop (JobView: pay, xp ranks, rep, clock; saved xp)
- [x] Race in play: R while driving starts a checkpoint lap vs a rival driver, prize by place, best time (RaceView)
- [x] Races: L picks 1-3 laps, two visible rival cars, prize x laps, best time per lap count saved (also fixed: rivals no longer overwrite your best). [ ] race track on the roads, sports venues
- [ ] Gate: trailer-ready + Steam page text/screens

## Phase 3: Earth alpha (months 7-15)
- [ ] Full Earth map (farmland, forest, lake, city, caves), built as slices from docs/EARTH_MAP.md:
  - [x] E1 World streaming: 8x8 chunk grid (ChunkGrid/ChunkStream/ChunkView), seamless global noise + padded sdf/data texture, 3x3 chunks around the player built one per frame, choppable trees/rocks in neighbours, data/regions.json biomes + region banner, sea wall around the 512x512 world. [ ] NPC/animal/car awareness outside the homestead, fish shadows + reflections in neighbour chunks, saving streamed node state
  - [x] E2 Roads: RoadNet (A* on a coarse grid over the water noise + string pulling) paints branches from the east-west spine to farmland, highlands, harbour, circuit, Vance and the lumber camp; the spine crosses lakes on causeways; dry-land signposts (E reads direction + steps). [ ] asphalt in the city (E3), bridges over rivers, bus stops
  - [x] E3 Port Halden block (CityModel): land-forced 53x51 city over four chunks, asphalt streets with lane dashes + paved sidewalks + plazas, avenue to the spine, 12 buildings (shop, police, cafe, bank, hospital, garage, town hall, 2 apartments, 3 townhouses), street lamps/benches/fountain, enterable interiors with working counters (shop menu, bank deposit/withdraw + 2%/day interest, hospital treatment, police fine desk clears wanted, cafe coffee, notice board, garage). Apartments/townhouses are lockable robbery targets. [ ] NPC routines in the city, asphalt tile in car sound/skid, shop stock per building, jail cells use
  - [x] E4 Caves: CaveModel (drunken-walk cavern, copper/coal/iron by depth, daily ore respawn, torches, bats), CaveView (fade in from a cave mouth at the Highlands road end, miner lamp + torch PointLights, pickaxe mines ore with skill xp, club drives off bats that bite energy, bat wings drop), furnace in the workshop (SmeltView, data/smelting.json: copper/iron bars), 6 item icons. [ ] multi-floor mines with ladders, bars for tool upgrades/crafting, more enemies (slimes, rock crabs), minecart/ore-vein variety
  - [x] E5 Harbour: HarbourModel (forced sea south of the harbour road end, paved quay + T-pier, lighthouse, moored boats, bollards, barrels), 4 sea fish (sardine/mackerel/tuna/swordfish; Fishing.pick_fish sea flag, no lake legend in the sea), weekly contest every 7th day 8:00-18:00 (board: $25 entry, sea catches add cm, ranks vs 3 rivals pay $300/150/75; HarbourState tested), night smuggling crate every 3rd night at the pier head (+20 heat, fence barrel in Port Halden pays $200+, refuses at 3+ stars). Art via tools/gen_harbour.py. [x] contest entry + crate pickup saved (HarbourState.to_dict), stone-slab quay (shader). [ ] ferry, legendary sea fish, fish auction
  - [x] E6 Race circuit + sports venues: CircuitModel (forced-land oval asphalt track at chunk (1,6), kerbs, chequered start line, 12 checkpoints, grid slots, pit office + Sports Hall interiors, football pitch, grandstand/gantry), circuit licence ($150, races pay x3), SportsModel/SportsView (basketball free throws, penalty shootout, boxing bouts), art tools/gen_circuit.py. [ ] bike racing, basketball/football matches with teams, venue jobs
  - [x] E7 Story Act 1 beats: StoryModel + data/story.json (9 beats in 3 quests: grandmother's letter, Vance visit, grandmother's notes), events/polls drive the chain, rewards, K quest log + banner (StoryView), goal line follows the story after day 1, Vance debt $2000 paid in $250 slices at the new Town Hall ledger desk (Shift+E all), saved. [x] Vance NPC with dialogue (suit outfit, stands at his yard gate), debt deadline (due day 28, $100 per late week up to $500, clerk's note, log shows fees), Act 2 "Two Roads" (visit the yard, talk to Vance, 10 rep on either road, rocket seat by a $5000 ticket or a keycard from the harbour fence; multi-trigger "any" + rep_any_min + debt_clear in StoryModel, tested) (run 14). [x] gate rolls away as soon as the seat is earned. [x] honest ladder: Rocket Yard Tech job at Vance's gate (honest rep 10, Yard Hand -> Rigger -> Launch Tech, within EconomyAudit caps). [ ] Act 2 heists inside the yard
  - [x] E9 City life: villager sheet tools/gen_npcs.py (8 beardless outfits, 3 hair styles, police cap; NpcLook) replaces tinted player copies for named NPCs and cops (cops now animate), CityFolk/CityFolkView pedestrians walk sidewalks + plazas, cross only at zebras (AStar over CityFolk.walkable), idle at shop doors, sit on benches, 16 by day / 2 at night, go back inside a door when the crowd thins, 1-2 beat cops; tested. [x] pedestrians react to crime: witnesses within 7 cells make it count as seen (PoliceView.witness_cb), everyone within 9 cells runs for the nearest safe door with a red "!", beat cops walk to the scene, "N witnesses saw that!" (CityFolk.witnesses/panics/flee_spot tested, --crime-demo). [x] car hits and club swings knock pedestrians down (CombatView.extra_targets; they lie still, then limp home through a door; --knock-demo), pedestrians keep personal space (CityFolk.separation, tested), wild animals stay off city/circuit/quay paving (AnimalModel.wild_ok, tested). [x] named residents on city door prompts (CityFolk.RESIDENTS, door_label, tested)
  - [x] E10 Vance Aerospace yard (run 14): VanceYard model (forced paved compound north of the Vance road end, razor-wire fence ring, shut hazard gate that opens with the rocket_seat step, launch pad, half-built rocket in scaffolding, hangar, fuel tanks, floodlights, crates; tested), art tools/gen_vance.py, wild animals kept out. [x] floodlights throw cold white pools at night (night_lights group). [x] two guard dogs patrol loops, chase you inside the fence and bite for -10 energy (YardGuard rules + YardGuardView, tested, check screen yarddog). [x] two crates inside the fence can be searched once a week for cash + metal, +2 street rep, theft heat (YardHeist, tested, saved as yard_looted). [ ] bigger yard interior heist
  - [x] E8 Economy + balance pass: MarketModel (first 4 units/day full price, -3% per extra unit down to 55%, quarter of the glut remembered overnight, deterministic +-8% daily demand, shop list shows +/- trend, saved), EconomyAudit + tests/test_economy.gd lock the ladders (crop profit/day within 3x, job pay per energy rises by rank, no buy-sell exploit, tool tiers, smelting gain, fish prices match items.json). [ ] bars as upgrade currency, Vance debt deadline pressure, price boards per town, export/import prices between regions
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

## Backlog additions (2026-11-18 run 5, research)
- Onboarding: Stardew-style first-days guidance (what to do first, a gentle quest log). Weakest part vs Stardew was no visible goal; GoalText hint added. Next: a real quest log screen (J tab) fed by data/story.json. Source: https://gamerant.com/stardew-valley-first-things-to-do/ , https://www.thegamer.com/stardew-valley-common-mistakes-new/ (2026-11-18, titles only)

## Backlog additions (2026-11-17 run 3, research)
- Interaction clarity and low-friction chores are what keep Stardew sticky: https://medium.com/super-jump/what-makes-a-game-about-mundane-chores-hopelessly-addictive and UI notes https://neverendingbacklog.substack.com/p/interfacing-with-the-player . Weakest part of Starstead vs Stardew/Core Keeper now: storage and crafting UI (no chest, no kitchen) -> promote: farmhouse storage chest, then cooking. Also tool-line upgrades done this run (hoe/can) to match Core Keeper-style tool tiers.
- [x] Storage chest with the bag-style grid, shift-click (farmhouse; placeable chest still to do)
- [x] Weeds and scythe (fibre) so the farm needs upkeep

## Backlog additions (2026-11-18 run 6, research)
- Weakest vs Core Keeper/Stardew mines: our mine is one chamber; they reward going deeper (floors, ladders, boss floors, light radius upgrades). Next: multi-floor mine with ladder holes and a lamp upgrade. Sources (titles only): https://www.thegamer.com/core-keeper-and-the-endless-craving-for-digging-holes/ , https://www.gamesradar.com/games/simulation/stardew-valley-creator-wanted-the-mines-to-be-like-terraria-but-it-was-way-too-ambitious-in-the-end-should-have-been-an-entire-game-on-its-own (2026-11-18)
- Use smelted bars for pickaxe/axe upgrades and car parts so the cave feeds the garage economy (E8).

## Backlog additions (2026-11-18 run 7, research)
- Weakest part vs Stardew Valley this run: fishing starts too hard for newcomers (Eric Barone admits it: https://www.pcgamer.com/games/life-sim/a-lot-of-people-hate-it-but-i-think-its-fun-eric-barone-backs-stardew-valleys-fishing-minigame-but-does-admit-that-it-starts-too-hard). Idea: wider reel bar for the first 5 catches (beginner assist) and a harbour fish auction / deep-sea fishing (community idea https://forums.stardewvalley.net/threads/%F0%9F%8E%A3-late-game-suggestion-deep-sea-fishing-pelican-town-fish-auction.53459/latest). Aquarium-style fish collection display (https://gamesradar.com/the-best-thing-about-animal-crossing-new-horizons-is-its-aquarium-so-this-indie-dev-is-bringing-it-to-their-stardew-valley-like-in-a-way-thats-as-fun-to-explore). Festival ideas: https://forums.stardewvalley.net/threads/new-festivals-at-zuzu-city-and-other-festival-suggestions.339/latest
- [x] Beginner fishing assist: bar +0.12 for the first 5 catches (Fishing.BEGINNER_BONUS, tested)

## Backlog additions (2026-11-18 run 8, research)
- Weakest part vs Stardew/Moonlighter: the new circuit and sports hall have one minigame each and no progression ladder; next: tournaments (bracket of 3 bouts, league table) and ranked circuit licences (B/A) tied to E8 economy.

## Backlog additions (2026-11-18 run 9)
- Weakest vs Stardew Valley: story was invisible (no letters, no named antagonist beat). Fixed with the Act 1 quest log + Vance debt. Next: Vance as an NPC who talks, deadline pressure (interest after day 30), Act 2 honest/street branch. Reference: Stardew's Joja vs Community Center choice as the model for the honest/street fork.
- Cassette Beasts/Moonlighter: quest log with tracked step on the HUD is the genre norm; ours is the goal line + K log.

## Backlog additions (2026-11-18 run 10, research)
- Weakest vs Stardew Valley: no price pressure, so one crop could be dumped forever and late-game had no money sinks. Added sell pressure/demand (MarketModel). Next: artisan goods (jam, cheese, bars) as the value-add ladder and money sinks (house upgrades, licences). Sources (titles only): https://gamerant.com/stardew-valley-economy-cost-goods-market-supply-demand/ , https://forums.stardewvalley.net/threads/market-economy-supply-demand-mechanic.2063/latest , https://mechanicsofmagic.com/?p=1915 (Critical Play: Balance, Stardew)
