# App Store Metadata: Liminal

## Identity

| Field | Value |
|---|---|
| Name | Liminal: Hidden Rules |
| Subtitle | Find the Rule. Find the Exit. |
| Bundle ID | com.liminall.app |
| SKU | LIMINAL-001 |
| Primary Category | Games |
| Secondary Category | Entertainment |
| Age Rating | 4+ |
| Price | $4.99 |
| Availability | All territories |

The store choices above are submission values to confirm in App Store Connect.
Code establishes the bundle ID, not saved store settings or trademark clearance.

Character counts: Name 21/30; Subtitle 29/30.

---

## Keywords

*(100 character limit, comma-separated)*

```
atmospheric,exploration,puzzle,abstract,ambient,meditative,art,first person,minimalist,indie
```

Character count: 92/100

---

## Description

*(4,000 character limit; submit the plain text inside the block)*

```
Seven spaces. Seven hidden rules.

Liminal is a first-person exploration game where the environment is the puzzle. Walk through corridors, spherical rooms, and open fields. Watch the light. Listen to the sound. Experiment with movement and discover what each space asks of you.

The spaces

Doppler: A corridor of cool color and shifting pitch.
Lensing: A spherical room with a warped grid pattern and blue tint.
Shadow: An open field with a dark line across its floor.
Interference: A lattice of beams with wave patterns and changing sound levels.
Chromatic Decay: A corridor where color fades and returns.
Resonance: A spherical room with rippling surfaces and color that shifts from cool to warm.
Convergence: An open field that layers visual effects from the earlier spaces.

How Liminal plays

Drag one finger to look. Drag two fingers to move. Pinch to change how fast you move. Observe the relationships. Form a hypothesis. Test it.

There is no map, HUD, or tutorial during play. Each space communicates through light and sound rather than written instructions. If you stall for a while, some spaces pulse to nudge you.

Settings

Settings are hidden on purpose: tap five times in the top-left corner for volume, haptics, and control sensitivity. VoiceOver users will find Open Settings in the Actions rotor.

Audio

Soundscapes are made on your device. In some spaces movement bends the pitch; in others your position changes what you hear. Headphones recommended.

Liminal is built for iPhone and iPad with iOS 17 or later. Play offline, with no accounts, ads, or in-app purchases.
```

Character count: 1591/4000

---

## Promotional Text

*(170 character limit)*

```
Seven abstract spaces, each with a hidden rule. No map, no HUD, no tutorial. Watch the light, listen, move, and work out what each space wants from you.
```

Character count: 152/170

---

## Support and Privacy URLs

| Field | URL |
|---|---|
| Support URL | https://github.com/saagpatel/Liminal/issues |
| Marketing URL | https://github.com/saagpatel/Liminal/issues |
| Privacy Policy URL | https://github.com/saagpatel/Liminal/blob/main/PRIVACY.md |

Confirm reachability and suitability before submission. These are the repository's
current URLs; this copy pass does not verify their published content.

---

## Screenshots Plan

Global launch numbers `n = 1...8` identify the eight planned states below.
`scripts/capture-screenshots.sh` captures every state at both sizes: **6.9-inch
iPhone 1320x2868 px** (`iPhone 18 Pro Max`) and **13-inch iPad 2064x2752 px**
(`iPad Pro 13-inch (M5)`). The original four selections per device are retained
in the Selection column; the other captures are available for inspection.
The app targets device families 1 and 2.

| n | Screen | Selection | Device sizes (portrait px) | Capture | Capture path |
|---|---|---|---|---|---|
| 1 | Space 1: Doppler | iPhone 1 | iPhone 1320x2868; iPad 2064x2752 | Corridor during movement with the blue color shift visible. | Simulator |
| 2 | Space 2: Lensing | iPhone 2 | iPhone 1320x2868; iPad 2064x2752 | Spherical room showing the warped surface grid and blue tint. | Simulator |
| 3 | Space 5: Chromatic Decay | iPhone 3 | iPhone 1320x2868; iPad 2064x2752 | Corridor with partial desaturation on shader-covered surfaces. One desaturation value applies to those surfaces; do not create a grayscale/color split. | Simulator |
| 4 | Title screen | iPhone 4 | iPhone 1320x2868; iPad 2064x2752 | The actual white "Liminal" title in Menlo on black, frozen at 1.5 seconds in its launch fade. | Simulator |
| 5 | Space 3: Shadow | iPad 1 | iPhone 1320x2868; iPad 2064x2752 | Oblique view of the open-field boundary during movement, facing away from the exit-hint groove. Confirm player-relative floor darkening from the corrected world-space shader in the recapture; it should remain visible at the existing pose. | Simulator |
| 6 | Space 6: Resonance | iPad 2 | iPhone 1320x2868; iPad 2064x2752 | Near-wall, tangential view of the spherical room during partial resonance, framing its curvature, warm tint, and authored displacement. Confirm visible surface relief from the displaced normals, along with the warm tint, in the recapture. | Simulator |
| 7 | Space 7: Convergence | iPad 3 | iPhone 1320x2868; iPad 2064x2752 | Open field showing the layered color and surface-pattern effects actually visible in the build. | Simulator |
| 8 | Space 4: Interference | iPad 4 | iPhone 1320x2868; iPad 2064x2752 | A view among lattice beams showing the wave pattern. A still image does not demonstrate sound. | Simulator |

Run `scripts/capture-screenshots.sh` on the dispatcher Mac with Xcode and both
named simulators installed. It builds Debug once without signing, launches with
`-AppStoreScreenshot <n>`, and writes `screenshots/appstore/<device-slug>/<nn>.png`.
Before the first capture on each device, it launches the app once, waits 2 seconds,
then terminates it to clear the cross-app back link from subsequent launches.
`DERIVED` defaults to `.build/shots`; `SHOT_WAIT` defaults to 4 seconds, and
`SHOT_WAIT_1` through `SHOT_WAIT_8` override the wait for an individual state.
Screenshot mode requests portrait orientation; the script rejects dimensions
that differ from the table.
Generated images and derived build products are ignored by Git.

Screenshot mode exists only in Debug. It loads the bundled JSON spaces and uses
the existing geometry, materials, and rules with fixed player poses and movement
snapshots. It holds the rule output and shader clock, skips the normal title for
gameplay, and disables input, settings, debug overlay, audio, haptics, and progression.
The title capture uses the actual title scene, layout, font, and fade opacity.
Shots 5 and 6 retain their existing poses and JSON-driven rule snapshots: recapture
them after the shader fixes to check floor darkening and lit surface ripples,
respectively. Keep exit hints and conditions out of the frame; see
[the shader audit](docs/SHADER-AUDIT.md) for per-space checks.
There are no random assets or hardware-only scenes in this plan, so no row requires
`OPERATOR: capture on device` for missing simulator hardware. No camera imagery is used.

These are reproducible Debug simulator captures, not verified release screenshots.
Inspect every image for the planned visible effects before selecting or uploading;
simulator rendering is not physical-device Metal validation. The Release and
physical-device checks in the submission checklist remain operator work.
Gameplay images have no UI or text; the title image retains its real title text
as explicitly planned. Do not add effects, labels, or a simulated HUD. Normal
Release progression remains linear with no chapter selector.

---

## App Review Notes

**Launch and controls:**

1. Launch Liminal. The title reads **Liminal** and fades automatically in about four seconds. No Start button is present. Space 1 is a corridor.
2. Drag one finger to look. Drag two fingers up/down to move or left/right to strafe. Movement stays on the floor plane and uses drag distance, so holding fingers still does not keep you moving.
3. Pinch to set the movement speed multiplier between 0.5 and 3.0. Pinching alone does not move the player. The multiplier follows the current pinch scale rather than accumulating across pinches.

**Settings inspection without completing a puzzle:**

1. After the title fades, tap five times within the top-left 44x44-point corner of the game view. This opens the settings overlay.
2. The visible labels are **Haptic Feedback**, **Volume**, and **Sensitivity**. Adjust Volume or Sensitivity, then tap **Done** to close the overlay. These preferences are saved locally and can be checked by reopening settings after relaunch.
3. With VoiceOver enabled, focus **Liminal game world** and choose **Open Settings** from the Actions rotor. The sensitivity slider's accessibility label is **Control sensitivity**. Haptic feedback is off by default and depends on supported hardware; the simulator cannot demonstrate physical haptics.

**Space 1 completion (review-only solution):**

The code advances when normalized movement speed is at least 0.85 for three
continuous seconds. The counter resets below that speed. Increase the pinch
multiplier and keep dragging two fingers rapidly; a slow drag or stationary touch
will not meet the condition. Stopping at a wall also reduces measured speed.
The signals are a blue color shift and rising audio pitch, not a geometry change.
On exit, the view fades out and Space 2 fades in. This is the configured condition,
not a verified physical-device completion procedure; gesture feel and timing
remain pending device checks. The settings path above can be inspected without
completing Space 1.

**Progression:** Spaces advance in order with no chapter select or skip control.
Relaunching starts at the title and Space 1; progress is not saved. After Space 7,
the view fades to black and stays there. Relaunch to start again. No completion-time
estimate or solution attachment is supplied with these notes.

**Offline behavior and review environment:** No account, sign-in, or location
permission is needed. The app does not use the reviewer's geographic location.
There are no outbound network requests, analytics, crash-reporting SDKs, or ads in
the app source. Audio is generated locally. A simulator can be used to inspect
the title and settings, but cannot establish device haptics, audio behavior,
performance, or Metal rendering. Physical-device validation remains pending.

**Error alerts:** If resources or audio fail to load, the app may show **Space
Unavailable** or **Audio Unavailable**, with an **OK** button. The messages ask
the reviewer to relaunch; the audio message also asks them to check audio output.
These alerts are errors, not puzzle states.

---

## Submission Checklist

Unchecked items are submission tasks, not claims that testing or store setup has
already passed.

### Metadata

- [ ] Use the Name row exactly: "Liminal: Hidden Rules"; confirm trademark clearance.
- [ ] Name within 30 characters (21); subtitle within 30 (29).
- [ ] Keywords within 100 characters (92); no exit-condition hints.
- [ ] Description within 4000 characters; use the plain text block and keep exit conditions out of public copy.
- [ ] Promotional text within 170 characters (152).
- [ ] Confirm Support, Marketing, and Privacy Policy URLs are live and suitable; publish the revised privacy policy before submission.

### Screenshots

- [ ] Capture the planned four images at each required size; confirm the submission's screenshot count requirements.
- [ ] Use actual Release UI on physical devices; close settings for gameplay images and include the real title text in the title image.
- [ ] 6.9-inch iPhone: 1320x2868 px.
- [ ] 13-inch iPad: 2064x2752 px.
- [ ] Check visible effects against the build. No added geometry warp, split desaturation, or visual claim of sound cancellation.
- [ ] If providing an optional preview, use real footage and confirm duration/format requirements before submission.

### Build

- [ ] Dispatcher archives the Release scheme and reviews build errors and warnings under Swift 6 strict concurrency.
- [ ] Validate Metal visuals and API behavior through all seven spaces on physical devices.
- [ ] Confirm the bundled privacy manifest declares no collection or tracking and the app-only UserDefaults reason.
- [ ] Confirm local preference keys: `liminal.hapticEnabled`, `liminal.volume`, `liminal.sensitivity`.
- [ ] Measure binary size in Xcode Organizer before submission.
- [ ] Check haptic behavior on hardware with and without haptic support.
- [ ] Confirm the Release runtime has no debug overlay or debug logs.
- [ ] Confirm the app icon and required asset sizes.
- [ ] Confirm `LiminalShaderLab` is excluded from the archive scheme.
- [ ] Exercise the review steps on the upload candidate; measure performance on the intended devices before making any frame-rate claim.

### App Store Connect

- [ ] Confirm age rating, categories, SKU, territories, and the $4.99 price.
- [ ] Confirm export compliance answers against the archived build.
- [ ] Confirm no in-app purchases, subscriptions, or advertising.
- [ ] Enter and verify "No Data Collected" and no tracking answers; a local manifest does not prove saved store answers.
- [ ] Include the current review notes. Do not claim an attachment unless one is supplied.
- [ ] Complete external playtesting and record actual solve/crash results. No cohort outcome is claimed here.

## Copyright
© 2026 saagpatel
