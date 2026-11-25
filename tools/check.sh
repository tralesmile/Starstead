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
  for spec in "start|12|" "farm|12|--farm-demo" "car|30|--car-demo" "race|40|--car-demo --race-demo" "build|12|--build-demo --zoom=1" "hotspot|20|--hotspot-demo --zoom=2" "blueprints|14|--blueprint-demo --zoom=1" \
              "bag|10|--bag-demo" "chest|8|--chest-demo" "cook|8|--cook-demo" "upgrade|8|--upgrade-demo" "garage|8|--garage-demo" "journal|8|--journal-demo" "story|10|--story-demo" "map|10|--map-demo" "carhud|30|--car-demo" \
              "city|40|--at=192,-2 --zoom=1 --hour=12" "bank|20|--enter-demo=city_bank" "cave|60|--cave-demo --cave-walls" "cave3|90|--cave-demo --cave-floor=3" "smelt|8|--smelt-demo" "forge|8|--forge-demo" "shift1|20|--shift-demo=timing" "shift2|20|--shift-demo=sequence" "shift3|30|--shift-demo=balance" "craft|8|--craft-demo" "fish|20|--fish-demo --zoom=3" "shop|8|--shop-demo" "hunt|20|--hunt-demo" "workshop|20|--enter-demo=workshop" "cavemouth|24|--at=96,-157 --hour=12" "circuit|40|--at=-96,166 --zoom=1 --hour=12" "pit|20|--enter-demo=circ_pit" "sporthall|20|--enter-demo=circ_hall" "hoops|8|--sports-demo=hoops" "derby|50|--derby-demo" "ride|16|--ride-demo --at=72,26 --zoom=3 --hour=12" "boxing|8|--sports-demo=boxing" "fx|14|--fx-demo" "pots|12|--pot-demo" "gate|30|--at=125,1 --zoom=2 --hour=12 --gated" "citynight|40|--at=192,0 --zoom=1 --hour=23" "maplocked|10|--map-demo --gated" "crime|34|--crime-demo --at=184,-1 --zoom=1.5 --hour=12" "knock|36|--knock-demo --at=184,-1 --zoom=1.5 --hour=12" "yard|30|--at=288,-109 --zoom=1 --hour=12" "vancegate|30|--at=288,-96 --zoom=1.5 --hour=20" "leap|23|--fish-demo --leap-demo --zoom=3" "vancejob|30|--at=289,-96 --zoom=1.5 --hour=12" "treasure|26|--fish-demo --treasure-demo --zoom=3" "dog|40|--enter-demo=city_house1 --dog-demo" "home2|20|--enter-demo=city_house2" "home3|20|--enter-demo=city_house3" "flat|20|--enter-demo=city_apt_a" "safe|16|--enter-demo=city_house2 --safe-demo" "sleepers|20|--enter-demo=city_house1 --hour=23" "evening|20|--enter-demo=city_house1 --hour=19" "woke|26|--enter-demo=city_house1 --hour=23 --wake-demo --zoom=2" "windows|40|--at=180,9 --zoom=1.5 --hour=23.5" "alarm|40|--enter-demo=city_house2 --safe-demo --alarm-demo" "yarddog|30|--at=285,-101 --zoom=2 --hour=12" "prints|10|--at=192,2 --zoom=3 --hour=12 --rain --prints-demo" "dealer|24|--at=183,18 --zoom=3 --hour=22 --dealer-demo" "steal|30|--at=180,-1 --zoom=2 --hour=12 --steal-demo" "village|20|--at=39,22 --zoom=1 --hour=12" "porch|30|--at=171,10 --zoom=3 --hour=12" "bench|30|--bench-demo --zoom=3 --hour=12" "arrow|30|--arrow-demo=bed --zoom=2 --hour=12" "till|20|--enter-demo=city_bank --hour=23 --zoom=2 --till-demo" "passout|30|--at=192,2 --zoom=2 --hour=14 --passout-demo" "traffic|120|--traffic-demo --at=140,33 --zoom=1.5 --hour=12" "trafficnight|120|--traffic-demo --at=140,33 --zoom=1.5 --hour=21.5" "mud|12|--mud-demo --at=60,30 --zoom=4 --hour=12 --rain" "autumn|12|--season=2" "night|12|--hour=22"; do
    IFS='|' read -r name frames flags <<< "$spec"
    ERR=$(tools/screenshot.sh "$frames" -- $flags 2>&1 | grep -E "SCRIPT|SHADER ERROR")
    cp "$(ls /tmp/mv*.png | tail -1)" "/tmp/check/$name.png" 2>/dev/null
    if [ -n "$ERR" ]; then echo "FAIL screen $name:"; echo "$ERR" | head -3; FAIL=1; else echo "ok   $name"; fi
  done
fi
if [ $FAIL -eq 0 ]; then echo "PASS"; else echo "FAIL"; fi
exit $FAIL
