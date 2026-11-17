#!/bin/bash
# Imports, runs all tests, and fails if the output contains any ERROR line (the runner alone hides script errors).
cd "$(dirname "$0")/.."
~/bin/godot --headless --path . --import >/dev/null 2>&1
OUT=$(~/bin/godot --headless --path . -s tests/run_tests.gd 2>&1)
echo "$OUT" | grep -E "ERROR|FAIL|TESTS"
if echo "$OUT" | grep -qE "ERROR|FAIL" || ! echo "$OUT" | grep -q " 0 failed"; then exit 1; fi
