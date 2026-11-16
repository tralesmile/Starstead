# Art target (from the owner's reference screenshot, 2026-11-16)

The owner sent a reference frame (not committed: it may be another game's art; we match the STYLE only, all our art is original and generated).
What it shows and how we match it:
- Clear turquoise water that darkens with depth; big pale submerged boulders visible in the shallows; short light ripple dashes -> `assets/shaders/ground.gdshader` (sdf-driven depth, voronoi boulders, animated ripples).
- Mossy rounded grey stones along every shoreline -> shader shore band (sdf 0..0.42).
- Lily pads (one with a flower), reeds, small fish shadows swimming -> `lily_pads.png`, `reeds.png`, `fish.png` + `FishShadow`.
- Warm wooden dock with plank seams, posts and a sagging rope rail -> `dock.png`, placed at the shore nearest spawn.
- Painterly grass: yellow-green and dark-green patches, dry ochre patches, small tufts, orange dirt path -> shader land branch.
- Big leafy broadleaf trees and deep evergreen pines, 1px dark outlines, top-left light -> `tree_oak.png`, `tree_pine.png`, `bush.png`.
- Chunky bearded character -> `player.png`.
- Yellow outline on the interactable (the rock) -> `outline.gdshader`, applied to the faced tree/rock.
- Camera close to the action -> Camera2D zoom 2 (integer, crisp pixels).

Still short of the reference (planned): higher-res characters and props (reference uses ~2x our pixel density), tree wind sway, water reflections of props, soft shadows under props, richer moss texture, layered cliff/bank height.
