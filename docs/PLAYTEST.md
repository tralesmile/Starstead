# Self-playtest notes (date | what I tried | what felt good/bad | fix)

2026-11-16 | Booted game under xvfb, viewed frame | Spawn on path, grass/water/trees read clearly, HUD legible | Not yet hand-played (no input in unattended run); tool loop covered by unit tests only.
2026-11-16 | Screenshots at dock, river and oak grove after art pass | Reads as a cosy painted world now; water depth and dock close to the reference | Still flat: no shadows under props, no sway, character lower detail than reference.
2026-11-16 | Screenshot of spawn + stall; shop and fishing covered by unit tests only (no input in unattended run) | Stall reads clearly beside the path | Needs hands-on feel check of reel difficulty.
2026-11-17 | Screenshots: hut stamp, night dock with lanterns, NPC lunch spot | Night lanterns read cosy; NPC hidden behind trees at plaza (place snapping) | Needs town clearing and pathing.
2026-11-17 | Screenshot at dock in rain (--rain) | Rain reads as mood without hiding the scene | Drops faint; add ripples on water and thunder later.

2026-11-17 | Drove the car from the spawn onto the dirt path: drift leaves skid marks and smoke, trees block it, repairs only near the workshop. Town buildings are solid; doors are locked (no interiors yet). Bait is bought at the stall BUY tab.
2026-11-17 | Screenshot --wanted: cops spawn around the player, WANTED stars show top-right; robbery/sprint covered by unit tests only | Cops at 1 star slower than walking, 4+ stars need sprint | Needs hands-on feel check.
2026-11-17 | Screenshots: chickens near the stall, held hoe mid-swing, race HUD with car-demo | Chickens read well; checkpoint markers are faint squares; held tool sits near the hand | Combat/taming/shift feel covered by unit tests only (no input in unattended run); needs hands-on check of flee distances and club cooldown.

## Playtest checklist (use every 5th run; log the answers below as a dated entry)
Start a new game with no flags and play ~10 minutes with only the key legend visible. Answer yes/no, then fix the worst "no" first:
1. Do I know what to do in the first 30 seconds without reading docs? (goal text, prompts)
2. Can I till, plant, water and harvest a crop without confusion? Is the reward clear (pickup, sell price, xp)?
3. Is there a reason to leave the farm in the first 5 minutes? (fish, chop, town, race)
4. Does anything feel sluggish or floaty (movement, tool swings, camera, car)?
5. Does any text overflow, overlap or vanish? Any screen I cannot close with Esc/E?
6. Is energy/money pacing fair (never stuck, never trivial) over one in-game day?
7. What would I show in a trailer? What is the ugliest thing on screen?
(Note: the playtest is done by the agent through the demo flags and screenshots; a human playtest by the owner is still the real test.)

2026-11-18 | PLAYTEST run 5 (checklist, demos + screenshots; no live input) | 1 NO: no goal visible at start (fixed: GoalText line under the HUD). 2 yes by unit tests/screens: till/plant/water/harvest with pickups. 3 yes: road east to Port Halden now exists with signposts, bank, hospital, shop. 4 car now slides more on grass and grips on asphalt (needs hands-on check). 5 yes in screenshots (bank/hospital interiors fit; region banner overlaps the back wall in interiors: cosmetic). 6 unchecked by hand; bank interest capped $200/day. 7 trailer: Port Halden street at night with lit windows; ugliest: big flat grey plazas and the hospital window glow wash.

2026-11-18 | Run 8 screenshots: circuit start straight, pit office, Sports Hall interior, boxing UI | Kerbs and chequered line read clearly; Sports Hall ring/lockers fit the room; mini-game timing numbers (meter speed 1.4, dodge window 0.9s) need a hands-on feel check | Tune after the owner plays.

2026-11-18 | Run 9 | Story log screenshot (K) and Town Hall interior with the ledger desk | Log reads clearly, 9 beats; ledger fits beside the notice desk | Needs hands-on check of beat pacing (day-3 Vance visit).
