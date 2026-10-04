#!/bin/bash
set -euo pipefail

# Run from any directory. SHOT_WAIT defaults to 4 seconds; SHOT_WAIT_1 through
# SHOT_WAIT_8 override individual shots. DERIVED overrides the build directory.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
DERIVED="${DERIVED:-.build/shots}"

fail() { echo "capture-screenshots: $*" >&2; exit 1; }
for tool in xcodebuild xcrun python3 sips; do
    command -v "$tool" >/dev/null || fail "Required tool missing: $tool"
done

booted_devices=()
overridden_devices=()
cleanup() {
    local result=$? id
    trap - EXIT
    set +e
    for id in ${overridden_devices[@]+"${overridden_devices[@]}"}; do
        if ! xcrun simctl status_bar "$id" clear; then
            echo "capture-screenshots: Could not clear status bar override for $id" >&2
            result=1
        fi
    done
    for id in ${booted_devices[@]+"${booted_devices[@]}"}; do
        if ! xcrun simctl shutdown "$id"; then
            echo "capture-screenshots: Could not shut down task-booted device $id" >&2
            result=1
        fi
    done
    exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Preflight both exact device names before building or booting anything. Choose
# the latest installed runtime, then UDID, if a name exists more than once.
device_json="$(xcrun simctl list devices available -j)"
select_device() {
    DEVICE_NAME="$1" python3 -c '
import json, os, re, sys
name = os.environ["DEVICE_NAME"]
matches = []
for runtime, devices in json.load(sys.stdin)["devices"].items():
    if ".iOS-" not in runtime:
        continue
    version = tuple(map(int, re.findall(r"\d+", runtime.split(".iOS-", 1)[1])))
    for device in devices:
        if device["name"] == name and device.get("isAvailable", False):
            matches.append((version, device["udid"], device["state"]))
if not matches:
    sys.exit("capture-screenshots: Missing available simulator: " + name +
             ". Install its iOS runtime and create this exact device in Xcode.")
_, udid, state = sorted(matches)[-1]
if state not in ("Booted", "Shutdown"):
    sys.exit("capture-screenshots: Simulator " + name + " is " + state +
             "; wait for it to settle and retry.")
print(udid, state)
' <<< "$device_json"
}
iphone="$(select_device 'iPhone 18 Pro Max')"
ipad="$(select_device 'iPad Pro 13-inch (M5)')"

xcodebuild build -project Liminal.xcodeproj -scheme Liminal \
    -configuration Debug -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED" CODE_SIGNING_ALLOWED=NO
APP="$(find "$DERIVED/Build/Products/Debug-iphonesimulator" \
    -maxdepth 1 -type d -name 'Liminal.app' -print -quit)"
[[ -n "$APP" ]] || fail "Built Liminal.app not found under $DERIVED"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")"
[[ -n "$BUNDLE_ID" ]] || fail "Built app has no CFBundleIdentifier"

capture_device() {
    local selection="$1" slug="$2" expected_width="$3" expected_height="$4"
    local id state n nn wait_key settle output_dir png dimensions width height
    read -r id state <<< "$selection"
    if [[ "$state" == Shutdown ]]; then
        xcrun simctl boot "$id"
        booted_devices+=("$id")
    fi
    xcrun simctl bootstatus "$id" -b
    overridden_devices+=("$id")
    xcrun simctl status_bar "$id" override --time 9:41 --dataNetwork wifi \
        --wifiBars 3 --cellularBars 4 --batteryState charged --batteryLevel 100
    xcrun simctl install "$id" "$APP"
    xcrun simctl ui "$id" appearance dark
    output_dir="screenshots/appstore/$slug"
    mkdir -p "$output_dir"

    # Prime the launch history so captures do not show a cross-app back link.
    xcrun simctl launch "$id" "$BUNDLE_ID" -AppStoreScreenshot 1
    sleep 2
    xcrun simctl terminate "$id" "$BUNDLE_ID" >/dev/null 2>&1 || true

    # Global shot numbers match APPSTORE-METADATA.md. Capture all eight at both
    # sizes; the plan identifies the original four selections for each device.
    for n in 1 2 3 4 5 6 7 8; do
        wait_key="SHOT_WAIT_$n"
        settle="${!wait_key:-${SHOT_WAIT:-4}}"
        [[ "$settle" =~ ^[0-9]+([.][0-9]+)?$ ]] || fail "Invalid $wait_key/SHOT_WAIT: $settle"
        printf -v nn '%02d' "$n"
        png="$output_dir/$nn.png"
        xcrun simctl terminate "$id" "$BUNDLE_ID" >/dev/null 2>&1 || true
        xcrun simctl launch "$id" "$BUNDLE_ID" -AppStoreScreenshot "$n"
        sleep "$settle"
        xcrun simctl io "$id" screenshot "$png"
        dimensions="$(sips -g pixelWidth -g pixelHeight "$png")"
        width="$(awk '/pixelWidth:/ {print $2}' <<< "$dimensions")"
        height="$(awk '/pixelHeight:/ {print $2}' <<< "$dimensions")"
        [[ "$width" == "$expected_width" && "$height" == "$expected_height" ]] || \
            fail "$png is ${width}x${height}; expected ${expected_width}x${expected_height}. Check the device model and portrait orientation."
        echo "Captured $png (${width}x${height})"
    done
    xcrun simctl terminate "$id" "$BUNDLE_ID" >/dev/null 2>&1 || true
}

capture_device "$iphone" iphone-18-pro-max 1320 2868
capture_device "$ipad" ipad-pro-13-inch-m5 2064 2752
