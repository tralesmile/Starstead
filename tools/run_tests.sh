#!/bin/bash
# Imports, runs the tests, and fails if the output contains any ERROR line (the runner alone hides script errors).
# Usage: tools/run_tests.sh            all tests
#        tools/run_tests.sh chest      only tests/test_*chest*.gd (fast loop while working on one slice)
cd "$(dirname "$0")/.."
~/bin/godot --headless --path . --import >/dev/null 2>&1
ARGS=()
[ -n "$1" ] && ARGS=(-- "--only=$1")
OUT=$(~/bin/godot --headless --path . -s tests/run_tests.gd "${ARGS[@]}" 2>&1)
echo "$OUT" | grep -E "ERROR|FAIL|TESTS"
if echo "$OUT" | grep -qE "ERROR|FAIL" || ! echo "$OUT" | grep -q " 0 failed"; then exit 1; fi
