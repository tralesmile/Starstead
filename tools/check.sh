#!/bin/bash
# One command before every push: all tests + ERROR grep + a screenshot of every demo screen with a script/shader error scan.
# Frames land in /tmp/check/<name>.png so you can Read the ones you changed. Prints PASS or FAIL.
# Usage: tools/check.sh          full check
#        tools/check.sh quick    tests only
cd "$(dirname "$0")/.."
FAIL=0
echo "== tests =="
tools/run_tests.sh || FAIL=1
if [ "$1" != "quick" ]; then
  mkdir -p /tmp/check
  echo "== screens =="
  # name|frames|flags
  for spec in "start|12|" "farm|12|--farm-demo" "car|30|--car-demo" "race|40|--car-demo --race-demo" "build|12|--build-demo --zoom=1" \
              "bag|10|--bag-demo" "chest|8|--chest-demo" "cook|8|--cook-demo" "garage|8|--garage-demo" "journal|8|--journal-demo" \
              "city|40|--at=192,-2 --zoom=1 --hour=12" "bank|20|--enter-demo=city_bank" "fx|14|--fx-demo" "pots|12|--pot-demo" "autumn|12|--season=2" "night|12|--hour=22"; do
    IFS='|' read -r name frames flags <<< "$spec"
    ERR=$(tools/screenshot.sh "$frames" -- $flags 2>&1 | grep -E "SCRIPT|SHADER ERROR")
    cp "$(ls /tmp/mv*.png | tail -1)" "/tmp/check/$name.png" 2>/dev/null
    if [ -n "$ERR" ]; then echo "FAIL screen $name:"; echo "$ERR" | head -3; FAIL=1; else echo "ok   $name"; fi
  done
fi
if [ $FAIL -eq 0 ]; then echo "PASS"; else echo "FAIL"; fi
exit $FAIL
