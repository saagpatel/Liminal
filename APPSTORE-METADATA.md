# App Store Metadata — Liminal

## Identity

| Field | Value |
|---|---|
| Name | Liminal |
| Subtitle | Find the Rule. Find the Exit. |
| Bundle ID | com.liminal.app |
| SKU | LIMINAL-001 |
| Primary Category | Games |
| Secondary Category | Entertainment |
| Age Rating | 4+ |
| Price | $4.99 |
| Availability | All territories |

---

## Keywords

*(100 character limit — comma-separated)*

```
atmospheric,exploration,puzzle,abstract,ambient,shader,light,sound,spatial,meditative,art
```

Character count: 91

---

## Description

*(4,000 character limit)*

**Seven spaces. Seven hidden rules. No instructions.**

Liminal is a first-person exploration game where the environment itself is the puzzle. Each space follows a hidden law — a physics-like rule governing how light, color, and sound respond to your movement. Discover the rule. Satisfy the condition. Pass through.

There is no map, no HUD, no tutorial, and no text. Only you, the space, and something worth figuring out.

**Seven spaces, seven rules**

Each space has a distinct geometry, a unique Metal fragment shader, and a rule you must discover through experimentation:

1. **Doppler** — A long corridor where speed reshapes color temperature and pitch. Move fast enough, long enough, and the space opens.

2. **Lensing** — A spherical chamber with a hidden mass point. Approach it and the geometry bends around you. Find the center.

3. **Shadow** — An open field where shadows refuse to follow the light. Something in the floor holds the answer.

4. **Interference** — A lattice environment with two audio sources whose waves cancel each other. Find the silence.

5. **Chromatic Decay** — A corridor that loses color the longer you stand still. Motion is restoration. Stillness is the challenge.

6. **Resonance** — A sphere room where specific movement speeds make the geometry vibrate. Match the frequency.

7. **Convergence** — An open field where all prior rules are present at once, at low intensity. One position, one speed, satisfies all six simultaneously.

**How Liminal plays**

Drag one finger to look. Drag two fingers to move. Pinch to adjust speed. There are no buttons.

The environment responds to everything you do. Color temperature, shader distortion, audio pitch, spatial sound positioning — all of it changes based on where you are and how you move. Observe the relationships. Form a hypothesis. Test it.

Each space has a nudge: if you stand still for long enough, the environment gives you a subtle signal pointing toward what matters. Progress is always possible. The rules are always fair.

**Design philosophy**

No in-game UI means no labels, no progress meters, and no indicators pointing toward the answer. This is by design — the moment you read a label, you stop observing. Liminal is a game about learning to read environments, not text.

Settings (volume, haptic feedback, sensitivity) are accessible through a hidden 5-tap gesture. The game will not tell you this. You may discover it.

**Audio**

Each space has a unique ambient stem that modulates in real time based on your movement. Pitch, reverb mix, and 3D spatial positioning all respond to the same rules governing the visuals. Headphones are strongly recommended. Spatial audio is supported.

**Performance**

Runs at 60 fps on iPhone 13 (A15) and newer. Universal binary — runs on all iOS 17+ iPhones and iPads.

---

## Promotional Text

*(170 character limit — can be updated without a new app review)*

```
Seven spaces. Seven rules. No instructions. A first-person exploration game where the environment itself tells you everything — if you know how to listen.
```

Character count: 152

---

## Support and Privacy URLs

| Field | URL |
|---|---|
| Support URL | https://[placeholder]/liminal/support |
| Marketing URL | https://[placeholder]/liminal |
| Privacy Policy URL | https://[placeholder]/liminal/privacy |

*Replace with actual URLs before submission.*

---

## Screenshots Plan

### iPhone 6.9" (iPhone 16 Pro Max — 1320×2868 px) — 4 required

| # | Screen | Description | Key elements to show |
|---|---|---|---|
| 1 | Space 1 — Doppler at high speed | Corridor view at high movement speed with full blueshift applied | Deep blue-shifted walls and ceiling clearly visible; no UI elements; strong color saturation shift showing the rule in action |
| 2 | Space 2 — Lensing near mass point | Sphere room with significant UV distortion active near the mass point | Visible geometry warp/lens distortion on the sphere walls; subtle, otherworldly quality |
| 3 | Space 5 — Chromatic Decay at partial desaturation | Corridor partially desaturated, showing the decay in progress | Left third of view desaturated to near-grayscale, right third still colored — shows the rule's effect without fully explaining it; no text or UI visible anywhere |
| 4 | Title screen | "Liminal" title in SF Mono Light on solid black, mid-fade | Clean typographic composition; no background imagery; pure text on black shows the no-frills aesthetic |

### iPad 13" (iPad Pro M4 — 2064×2752 px) — 4 required

| # | Screen | Description |
|---|---|---|
| 1 | Space 3 — Shadow in open field | Wide-angle first-person view of the open field, shadow visibly diverging from expected light source direction — shows the rule without labeling it |
| 2 | Space 6 — Resonance with visible geometry vibration | Sphere room with Resonance shader active showing geometric surface distortion peaks at resonant speed |
| 3 | Space 7 — Convergence | Open field with multiple subtle simultaneous effects visible — color temperature shift, slight lensing, shadow anomaly — the visual complexity of the final space |
| 4 | Space 4 — Interference close to null point | Lattice geometry from within, audio interference pattern implied by the visual composition; no sound meter or indicator present |

*Note: No screenshots should show any HUD, label, menu, or on-screen text. All screenshots must be captured on physical device — simulator GPU rendering differs for Metal shader work.*

---

## App Review Notes

**How to play:**

- Single-finger drag: look around
- Two-finger drag: move forward/backward/strafe
- Pinch: adjust movement speed multiplier (0.5× to 3.0×)
- There is no other input and no UI

**To complete Space 1 (Doppler) — the first space a reviewer will encounter:**

Move using two-finger drag, then pinch out to increase speed. As speed increases, notice the color temperature of the corridor shifting toward blue. Continue at high speed (pinch fully out) for approximately 3 continuous seconds. The space will fade to black and transition to Space 2.

The rule for Space 1 is: speed above approximately 0.85 normalized velocity, maintained for 3 continuous seconds, triggers exit. The corridor geometry and audio pitch change are the signal. No other information is required.

**Hidden settings panel:** A 5-tap gesture on the lower-left corner of the screen opens a settings overlay with haptic, volume, and sensitivity controls. This is intentionally undiscovered by most users — it is not a hidden feature you need to evaluate, but it is present if you wish to confirm it. Settings persist to `UserDefaults`.

**No network connections.** Liminal makes zero outbound network requests. No analytics, no crash reporter, no advertising SDK. Audio stems are bundled in the binary.

**Space progression is linear.** There is no chapter select or way to skip spaces. A reviewer testing all 7 spaces will need to complete them in order. Estimated time to complete all 7 spaces for a first-time player who understands physics-based puzzle conventions: 30–60 minutes. For reference in review: the exit condition for each space is documented in the App Review notes attachment (available on request) — we are happy to provide it without spoiling the experience if it would expedite review.

**Performance:** The app targets 60 fps on iPhone 13 (A15) and newer. All Metal shaders are validated against Apple's Metal API Validation during development.

---

## Submission Checklist

### Metadata
- [ ] App name: "Liminal" — confirm no trademark conflict in Games category
- [ ] Subtitle within 30 characters: "Find the Rule. Find the Exit."
- [ ] Keywords within 100 characters — no spoilers for space rules in keywords
- [ ] Description does not reveal the exact exit condition for any space (the rules are discoverable — description gives genre context only)
- [ ] Promotional text within 170 characters
- [ ] Support and Privacy Policy URLs live

### Screenshots
- [ ] 4 screenshots per required size — no UI, labels, or HUD visible in any screenshot
- [ ] Screenshots captured on physical device (required — simulator GPU differs for Metal shaders)
- [ ] iPhone 6.9" — 1320×2868 px
- [ ] iPad 13" — 2064×2752 px
- [ ] App preview video optional but recommended: 60 seconds, 60 fps, no UI visible — recommend showing Space 1 progression from slow movement → blueshift → fast movement → exit transition

### Build
- [ ] `xcodebuild archive` on Release scheme: zero errors, zero warnings, Swift 6 strict concurrency
- [ ] Metal API Validation confirms zero errors during all 7 spaces on physical device
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`): zero data types declared — no collection, no tracking
- [ ] `UserDefaults` keys used: `liminal.hapticEnabled`, `liminal.volume`, `liminal.sensitivity` — all non-sensitive, no PII
- [ ] App binary size < 150 MB (check Xcode Organizer → App Size report before submission)
- [ ] CoreHaptics capability check present — no crash on devices without haptic hardware
- [ ] All `#if DEBUG` guards confirmed present in release build — zero debug logs in Release scheme
- [ ] App icon in all required sizes (1024×1024 source in asset catalog)
- [ ] `LiminalShaderLab` target excluded from archive scheme (development-only target)

### App Store Connect
- [ ] Age rating: 4+ (no violence, no mature content, no user-generated content)
- [ ] Export compliance: no custom encryption — answer "No"
- [ ] Primary category: Games; Secondary: Entertainment
- [ ] Price: $4.99 — no IAP, no subscriptions, no advertising
- [ ] Privacy manifest: zero data collected → privacy nutrition label will show "No Data Collected"
- [ ] App Review Notes: include Space 1 completion instructions and offer to provide full solution guide if needed to expedite review
- [ ] TestFlight: 10 external testers, 8/10 solved Space 1 within 7 minutes, 0 crash reports
- [ ] Performance verified: 60 fps on iPhone 13, ≥55 fps on iPhone 13 minimum per Instruments profiling
