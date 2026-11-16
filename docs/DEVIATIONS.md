# Deviations from plan (date | what happened | what I did instead)

2026-11-16 | add_repo and register_repo_root tools were not available this run; repo was already cloned at /home/claude/starstead and git push access is untested | Worked in the existing clone; will push and report if it fails.
2026-11-16 | Godot missing; GitHub API for godot-builds blocked (no add_repo) | Downloaded Godot 4.3-stable via direct release URL to ~/bin/godot; works headless.
2026-11-16 | GUT not installed | Wrote a tiny own test runner (tests/run_tests.gd); revisit GUT later if needed.
2026-11-16 | WebSearch returned titles only, no page content | Recorded ideas from titles/sources in Backlog only.
2026-11-16 | Owner said the graphics are bad and sent a reference screenshot to match | Inserted "Phase 0.5 art pass" before the remaining Phase 1 items (reorder, nothing cut); ground is now a procedural shader instead of the flat tile atlas (atlas kept only as invisible collision layer). Reference image not committed (possible third-party art); style described in docs/ART_TARGET.md instead.
