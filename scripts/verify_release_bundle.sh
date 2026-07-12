#!/bin/sh
set -eu

APP="${1:?usage: verify_release_bundle.sh /path/to/Liminal.app}"

test -x "$APP/Liminal"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")" = "com.liminal.app"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Info.plist")" = "1.0.0"
test -f "$APP/PrivacyInfo.xcprivacy"
test -f "$APP/LICENSE.txt"
cmp -s "$APP/LICENSE.txt" "$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)/LICENSE"
test -f "$APP/Assets.car"
test -f "$APP/Shaders/Doppler.metal"
test -f "$APP/Shaders/Convergence.metal"
test -f "$APP/Spaces/space_01_doppler.json"
test -f "$APP/Spaces/space_07_convergence.json"

space_count="$(find "$APP/Spaces" -type f -name 'space_*.json' | wc -l | tr -d ' ')"
shader_count="$(find "$APP/Shaders" -type f -name '*.metal' | wc -l | tr -d ' ')"
test "$space_count" -eq 7
test "$shader_count" -eq 10

printf '%s\n' "PASS: Release bundle identity and resources"
