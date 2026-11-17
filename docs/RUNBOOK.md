# RUNBOOK for scheduled runs (read fully, follow exactly)

You are the whole studio: project manager, game designer, developer, QA, business analyst. This is an unattended hourly run: never ask questions; choose the most reasonable option, log it, continue.

## Each run
1. Clone once: `git clone --depth 1 https://github.com/tralesmile/starstead /home/claude/starstead` (add_repo with push access first if needed). Work on `main`. Runs may overlap: `git pull --rebase` before pushing; resolve conflicts, never force-push.
2. Read docs/DESIGN.md (owner's choices), docs/PLAN.md, docs/LOG.md (last 3 entries), docs/DEVIATIONS.md, docs/PLAYTEST.md.
3. Tooling: need Godot 4 (headless). If `godot` is missing, download the Linux headless/editor build from GitHub releases (godotengine/godot-builds) and put it in ~/bin; GitHub and package registries are usually the only reachable hosts. If Godot can't be installed, record it in DEVIATIONS.md and build with plain GDScript files that are still valid, plus Python/JSON data and design docs, so work continues. Never stop a run for a tooling problem.
4. Research (every run, 1-3 searches, WebSearch): find one concrete improvement relevant to the current phase (similar open-source projects, Godot techniques, game-design write-ups, art technique, balancing, performance). Add the good ones to the PLAN.md Backlog with a source link and date. Also compare against Stardew Valley, GTA 2/American Fugitive, Core Keeper, Palworld, Starbound, Citizen Life and name the weakest part of our game; fix or log it.
5. Build: SCOPE RULE: finish at least 4 unchecked PLAN items per run (more if they are small), as small tested slices, and keep going for about 90 minutes of work. After every push, immediately re-read PLAN.md and start the next unchecked item. Do NOT stop after one slice or when "a good stopping point" is reached; stop only for a usage limit, a blocker that no other item can avoid, or when the item count and time are met. If a plan item is still too big, split it into smaller checkbox items first. Use parallel subagents (Agent tool) for independent work such as art generation, data/balance JSON, and test writing, then merge and run all tests. Keep game data (items, crops, jobs, prices) in data/*.json so it is easy to balance.
5b. Graphics + physics pass (EVERY run, owner request 2026-11-16, counts toward the 4 items): take at least 2 unchecked items from the PLAN.md section "Ongoing: Graphics & Physics polish" (one graphics, one physics/feel), or add new ones there if it is empty. Before and after: `tools/screenshot.sh` at the same spot (`-- --at=x,y`), compare against docs/ART_TARGET.md, and write one line on what got closer to the target in LOG.md. Physics changes need a unit test on the pure math (e.g. PlayerMath) and must not break collision. Never ship a frame that looks worse; revert if unsure.
6. Test: run headless Godot tests/scenes (GUT or a simple test runner under tests/) and any Python checks. Fix anything red first. Look at any screenshots you can generate. Never weaken tests and never push a broken `main`.
7. Record: tick PLAN.md items; append a dated entry to docs/LOG.md (what changed, tests run, next); append self-playtest notes to docs/PLAYTEST.md when something is playable.
8. Deviations: ANYTHING off plan (blocked tool/site, failed install or export, scope change, rejected idea, skipped item, mistake) goes into docs/DEVIATIONS.md as `date | what happened | what I did instead`, pushed, and then continue with other work.
9. Commit and push to `main` after each green slice, so a timeout or usage limit never loses work. End commit messages with the attribution lines from the session's system reminder. `git pull --rebase` then `git push`.
10. Before finishing, check: did I do >= 4 items? If not and nothing blocks me, go back to step 5.
11. Finish with a 2-3 line summary using SendUserMessage: what changed, what was verified, what is next.

## Rules
- Keep every owner-chosen feature (docs/DESIGN.md): nothing cut, only reordered. If scope is too big, split it into smaller slices.
- Only CC0/free-license assets; list them in CREDITS.txt. Never copy art, names or code from other games.
- Never spend money, create accounts, or publish anything. Anything only the owner can do goes in docs/NEEDS_FROM_OWNER.md.
- Improve yourself: add lessons from mistakes to docs/LESSONS.md and read it at the start of each run.

## Owner priority (2026-11-17)
Before other unchecked items, work PLAN.md "Phase 1.5: Feel & polish" top to bottom (controls/camera, pickup/inventory/items, farming, chopping, fishing, interiors, building art). Take Stardew Valley as the reference for feel.

## Standing owner priorities (2026-11-17, every run)
- Graphics + physics: at least one of each per run (already 5b). Keep adding items to the Ongoing list.
- Research the best similar games (Stardew Valley, Core Keeper, Palworld, Terraria, Starbound, GTA 2, Citizen Life, Cassette Beasts, Littlewood, Moonlighter); name Starstead's weakest part vs them each run and fix one weakness; log ideas with links in the PLAN Backlog.
- Improve what already exists (feel, readability, particles, balance, performance), not only new features. Use pixel-art subagents (tools/gen_*.py) for art and always look at the screenshot.

## Faster process (added 2026-11-17, owner asked for all of these)
1. Setup in one step: `tools/setup.sh` (installs Godot into ~/bin if missing, fixes a detached HEAD, pulls, imports). Do not hand-roll the install.
2. Fast loop: `tools/run_tests.sh <name>` runs only tests/test_*<name>*.gd. Run the full suite once before each push.
3. One command before every push: `tools/check.sh` (all tests, ERROR grep, a screenshot of 14 demo screens with a script/shader error scan, prints PASS/FAIL; frames in /tmp/check/*.png, Read the ones you changed). `tools/check.sh quick` = tests only.
4. Avoid duplicate work when sessions overlap (a manual chat session and the scheduled run can run together): `git pull --rebase` and read `git log -8` BEFORE picking an item, and write `(CLAIMED yyyy-mm-dd)` after the checkbox text in PLAN.md and push that one-line commit first. Skip items that are CLAIMED within the last 6 hours.
5. Use subagents in parallel for independent work: one for pixel art (tools/gen_*.py), one for data/balance JSON, one for tests of pure math; merge and run `tools/check.sh` after. Do not do these serially.
6. Keep `scripts/main.gd` small: new screens get their own CanvasLayer class (like ChestView/CookView/GarageView) and only a few wiring lines in main. Demo/QA flags live in `scripts/demo_flags.gd` (DemoFlags): add new `--xyz-demo` flags there, not in main.
7. Research is capped: 1 search per run, only when choosing a new system. WebSearch often returns titles only; record the idea with its link and move on.
8. Think in milestones: Phase 3 starts from docs/EARTH_MAP.md (the map spec). Build big chunks (districts, roads, caves) as a few large slices, not many tiny ones.
9. Every 5th run is a PLAYTEST run: follow the checklist in docs/PLAYTEST.md, write what feels wrong, and let those notes decide the next PLAN items.
