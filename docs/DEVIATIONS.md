# Deviations from plan (date | what happened | what I did instead)

2026-11-16 | add_repo and register_repo_root tools were not available this run; repo was already cloned at /home/claude/starstead and git push access is untested | Worked in the existing clone; will push and report if it fails.
2026-11-16 | Godot missing; GitHub API for godot-builds blocked (no add_repo) | Downloaded Godot 4.3-stable via direct release URL to ~/bin/godot; works headless.
2026-11-16 | GUT not installed | Wrote a tiny own test runner (tests/run_tests.gd); revisit GUT later if needed.
2026-11-16 | WebSearch returned titles only, no page content | Recorded ideas from titles/sources in Backlog only.
2026-11-16 | Owner said the graphics are bad and sent a reference screenshot to match | Inserted "Phase 0.5 art pass" before the remaining Phase 1 items (reorder, nothing cut); ground is now a procedural shader instead of the flat tile atlas (atlas kept only as invisible collision layer). Reference image not committed (possible third-party art); style described in docs/ART_TARGET.md instead.
2026-11-16 | Plan said "slower walking in shallow water" but all water tiles are blocked by collision | Applied slowdown on the wet bank (sdf<0.9) and a speed bonus on paths instead; wading factor kept for future fords.
2026-11-16 | git push prints "repository moved" notice | Still pushes fine; remote is tralesmile/Starstead.
2026-11-16 | Repo clone was on a detached HEAD so git pull --rebase failed | Ran checkout -B main + reset to origin/main (clean tree) and continued.
2026-11-16 | Camera 'soft limits' | Used hard Camera2D limits; soft clamp math kept in CameraMath for later.
2026-11-17 | Run ended with 4 model-level slices and no in-game wiring for NPCs/autotile/blueprint; no screenshot-visible change besides squash | Split the PLAN items into model (done) and view (unchecked) so next run wires them.
2026-11-17 | roof sprite name in build.json clashed with build_floor | Pointed roof at new build_roof.png. NPCs reuse tinted player sheet and walk straight lines (no pathing yet); logged in Backlog.
2026-11-17 | Farmhouse (home 9,8) not placed: no free dry land within search radius; shop test needed cursor fix after adding bait items | Layout skips unplaceable buildings; test now selects turnip_seed explicitly. Car had no motion until MOTION_MODE_FLOATING + collision exception with the player (lesson logged).
2026-11-17 | Fog overlay (previous run) rendered nothing: ColorRect under a CanvasLayer had size 0 | Set size from the viewport every frame (also for the new lightning flash); verified by pixel diff. Lesson logged.
2026-11-17 | Repo clone was on a detached HEAD again; Godot had to be reinstalled (fresh container) | checkout -B main origin/main; downloaded 4.3 to ~/bin/godot. Racing is a rival time trial, not the full lap/menu item (split into a new unchecked item).
2026-11-17 | Another scheduled run was pushing to main at the same time (hoe/can upgrades, float labels); PLAN.md conflicted once | Resolved the conflict keeping both sides' ticks, re-ran tests (245 then 247 green) and pushed. WebSearch returned titles only again; ideas recorded from titles.
2026-11-19 | Phase 3 slices E1-E8 were already done, so this run took the remaining owner items (story gate, camera feel) instead of a new Earth slice; research skipped | Next run: graphics overall (character/farm/UI art bar), NPC routines in the city, Act 2 beats.
