# Liminal — Implementation Roadmap

## Architecture

### System Overview
```
[JSON Space Definitions]
        ↓
[SpaceLoader] → [SCNScene + Geometry] → [Metal Shader Modifiers]
                        ↓
              [PlayerController] ← [TouchInputHandler]
                        ↓
              [RuleEngine] ← PlayerState (position, velocity, speed, idleSeconds)
                   ↓              ↓
         [ShaderUniformBus]   [AudioManager]
              ↓                    ↓
     [SCNMaterial uniforms]   [AVAudioEngine node graph]
              ↓                    ↓
         [Metal GPU]          [Speaker / headphones]
```

RuleEngine is the frame-by-frame heart: reads PlayerState → produces RuleOutput → dispatches uniforms to ShaderUniformBus and parameter updates to AudioManager simultaneously. All rule behavior is defined by JSON; Swift rule types implement a common protocol.

### File Structure
```
Liminal/
├── Liminal.xcodeproj
├── Liminal/
│   ├── App/
│   │   ├── LiminalApp.swift              # @main entry, SwiftUI App lifecycle
│   │   └── AppDelegate.swift             # AVAudioSession configuration (category, activation)
│   ├── Core/
│   │   ├── SpaceLoader.swift             # Decodes JSON → SpaceDefinition; validates schema
│   │   ├── RuleEngine.swift              # Per-frame evaluation; dispatches to shader bus + audio
│   │   ├── ShaderUniformBus.swift        # Typed wrapper: [String: Float] → SCNMaterial uniforms
│   │   ├── AudioManager.swift            # AVAudioEngine singleton; node graph; real-time param mod
│   │   └── PlayerController.swift        # SCNNode camera; velocity tracking; touch gesture handling
│   ├── Spaces/
│   │   ├── SpaceDefinition.swift         # Codable structs matching JSON schema exactly
│   │   ├── ExitCondition.swift           # Protocol + concrete exit condition evaluators
│   │   └── Rules/
│   │       ├── SpaceRule.swift           # Protocol: evaluate(PlayerState) → RuleOutput
│   │       ├── DopplerRule.swift         # Space 1: speed → color blueshift + pitch rise
│   │       ├── LensingRule.swift         # Space 2: proximity to mass point → UV warp
│   │       ├── ShadowRule.swift          # Space 3: player-relative shadow direction
│   │       ├── InterferenceRule.swift    # Space 4: position between audio nodes → phase cancel
│   │       ├── ChromaticDecayRule.swift  # Space 5: stillness → desaturation over time
│   │       ├── ResonanceRule.swift       # Space 6: specific speed → geometry vibration
│   │       └── ConvergenceRule.swift     # Space 7: all prior rules at low intensity simultaneously
│   ├── Shaders/
│   │   ├── Common.metal                  # Shared SIMD math helpers; imported by all shader files
│   │   ├── Doppler.metal                 # Fragment: color temperature shift via velocity uniform
│   │   ├── Lensing.metal                 # Fragment: UV coordinate distortion via proximity uniform
│   │   ├── Shadow.metal                  # Fragment: player-relative shadow override
│   │   ├── ChromaticDecay.metal          # Fragment: saturation reduction via idle time uniform
│   │   └── Resonance.metal              # Fragment: geometry vibration via speed-frequency uniform
│   ├── Scenes/
│   │   ├── SpaceScene.swift             # SCNScene subclass; wires RuleEngine + PlayerController
│   │   ├── TitleScene.swift             # SpriteKit overlay: "Liminal" fade in/out only
│   │   └── TransitionManager.swift      # Async space loading during black fade (1.5s)
│   ├── Resources/
│   │   ├── Spaces/
│   │   │   ├── space_01_doppler.json
│   │   │   ├── space_02_lensing.json
│   │   │   ├── space_03_shadow.json
│   │   │   ├── space_04_interference.json
│   │   │   ├── space_05_chromatic.json
│   │   │   ├── space_06_resonance.json
│   │   │   └── space_07_convergence.json
│   │   └── Audio/
│   │       ├── ambient_drone_01.caf      # Space 1 stem (AAC 128kbps, converted to CAF)
│   │       ├── ambient_drone_02.caf
│   │       ├── ambient_drone_03.caf
│   │       ├── ambient_drone_04.caf
│   │       ├── ambient_drone_05.caf
│   │       ├── ambient_drone_06.caf
│   │       └── ambient_drone_07.caf
│   └── Support/
│       ├── Extensions/
│       │   ├── SCNNode+Helpers.swift     # childNode(named:) convenience; position/velocity helpers
│       │   └── simd+Helpers.swift        # SIMD3<Float> magnitude, normalize, lerp
│       └── Debug/
│           └── DebugOverlay.swift        # #if DEBUG only: fps, speed, uniform values, rule state
├── LiminalShaderLab/                     # Separate Xcode target — shader isolation harness
│   ├── ShaderLabApp.swift
│   ├── ShaderLabViewController.swift     # SCNView + CADisplayLink + uniform sliders
│   └── TestShaders/                      # Working copies of shaders under development
├── LiminalTests/
│   ├── SpaceLoaderTests.swift            # JSON → SpaceDefinition round-trip; malformed JSON rejection
│   ├── RuleEngineTests.swift             # Per-rule: 5 PlayerState inputs → expected RuleOutput
│   └── AudioManagerTests.swift          # Graph init; parameter update without crash
└── IMPLEMENTATION-ROADMAP.md
```

### Core Type Definitions

```swift
// MARK: - SpaceDefinition.swift

struct SpaceDefinition: Codable {
    let id: String
    let index: Int
    let geometry: GeometryConfig
    let shader: ShaderConfig
    let audio: AudioConfig
    let exit: ExitConfig
    let nudge: NudgeConfig
}

struct GeometryConfig: Codable {
    let type: GeometryType       // corridor | sphere | lattice | open_field
    let scale: SIMD3<Float>      // x/y/z dimensions
    let subdivisions: Int        // mesh density
}

enum GeometryType: String, Codable {
    case corridor, sphere, lattice, openField = "open_field"
}

struct ShaderConfig: Codable {
    let name: String             // maps to [name].metal file
    let parameters: [String: Double]
}

struct AudioConfig: Codable {
    let stem: String             // maps to Audio/[stem].caf
    let rule: String             // maps to audio behavior in AudioManager
    let parameters: [String: Double]
}

struct ExitConfig: Codable {
    let condition: String        // velocityThresholdHeld | enterMassPoint | alignShadow | etc.
    let parameters: [String: Double]
}

struct NudgeConfig: Codable {
    let idleThresholdSeconds: Double
    let type: NudgeType
}

enum NudgeType: String, Codable {
    case amplitudeFlare, colorPulse, shadowReveal
}

// MARK: - SpaceRule.swift

protocol SpaceRule {
    func evaluate(playerState: PlayerState) -> RuleOutput
}

struct PlayerState {
    let position: SIMD3<Float>
    let velocity: SIMD3<Float>
    let speed: Float             // magnitude of velocity, normalized 0.0–1.0
    let lookDirection: SIMD3<Float>
    let idleSeconds: Float       // seconds since last movement > 0.05 units/frame
    let deltaTime: Float         // seconds since last frame
}

struct RuleOutput {
    let shaderUniforms: [String: Float]     // pushed to ShaderUniformBus each frame
    let audioParameters: [String: Float]    // pushed to AudioManager each frame
    let exitTriggered: Bool
    let nudgeActive: Bool
}

// MARK: - ExitCondition.swift

protocol ExitCondition {
    mutating func evaluate(playerState: PlayerState, ruleOutput: RuleOutput) -> Bool
}

struct VelocityThresholdHeld: ExitCondition {
    let targetVelocity: Float
    let durationSeconds: Float
    var accumulatedSeconds: Float = 0
    mutating func evaluate(playerState: PlayerState, ruleOutput: RuleOutput) -> Bool {
        if playerState.speed >= targetVelocity {
            accumulatedSeconds += playerState.deltaTime
        } else {
            accumulatedSeconds = 0
        }
        return accumulatedSeconds >= durationSeconds
    }
}
```

### JSON Schema (canonical — all 7 space files must match this shape)

```json
{
  "id": "space_01_doppler",
  "index": 1,
  "geometry": {
    "type": "corridor",
    "scale": [40.0, 6.0, 4.0],
    "subdivisions": 48
  },
  "shader": {
    "name": "Doppler",
    "parameters": {
      "maxColorShift": 0.4,
      "velocityThreshold": 0.3,
      "transitionSpeed": 2.0
    }
  },
  "audio": {
    "stem": "ambient_drone_01",
    "rule": "DopplerAudio",
    "parameters": {
      "maxPitchShiftSemitones": 3.0,
      "reverbMix": 0.6
    }
  },
  "exit": {
    "condition": "velocityThresholdHeld",
    "parameters": {
      "targetVelocity": 0.85,
      "durationSeconds": 3.0
    }
  },
  "nudge": {
    "idleThresholdSeconds": 90,
    "type": "amplitudeFlare"
  }
}
```

### Metal Shader Modifier Pattern

SceneKit injects fragment shaders via `SCNShaderModifierEntryPointFragment`. The shader receives SceneKit's fully-lit fragment and modifies `_output.color` and `_output.diffuse`. Uniforms are set per-frame via `SCNMaterialProperty`.

```metal
// Doppler.metal — registered as SCNShaderModifierEntryPointFragment
#pragma arguments
float velocityNormalized;     // 0.0–1.0, updated by ShaderUniformBus each frame
float colorShiftAmount;       // from JSON: shader.parameters.maxColorShift
float transitionSpeed;        // from JSON: shader.parameters.transitionSpeed

#pragma body
// Blueshift: reduce red/green, increase blue proportional to speed
float shift = velocityNormalized * colorShiftAmount;
_output.color.r = max(0.0, _output.color.r - shift * 0.35);
_output.color.g = max(0.0, _output.color.g - shift * 0.12);
_output.color.b = min(1.0, _output.color.b + shift * 0.55);
```

```swift
// ShaderUniformBus.swift — how uniforms reach the shader each frame
class ShaderUniformBus {
    func update(_ material: SCNMaterial, uniforms: [String: Float]) {
        for (key, value) in uniforms {
            material.setValue(value, forKey: key)
        }
    }
}
// Called from RuleEngine inside renderer(_:updateAtTime:) delegate
```

### AVAudioEngine Graph Structure

```
[AVAudioPlayerNode (stem)]
          ↓
[AVAudioUnitTimePitch]     ← pitch shift: -3.0 to +3.0 semitones, ramped not snapped
          ↓
[AVAudioUnitReverb]        ← reverb mix: 0.0–1.0
          ↓
[AVAudioEnvironmentNode]   ← 3D spatial positioning (used from Space 4+)
          ↓
[AVAudioEngine.mainMixerNode]
          ↓
[AVAudioEngine.outputNode]
```

Parameter updates use `AVAudioUnit.auAudioUnit.parameterTree` for sample-accurate ramping to avoid zipper noise. Never snap parameters — always ramp over ≥ 0.05 seconds.

### Space Sequence — Locked Design

| # | Name | Hidden Rule | Geometry | Exit Condition |
|---|---|---|---|---|
| 1 | Doppler | Speed → color blueshift + pitch rise | Corridor | Hold speed ≥ 0.85 normalized for 3s |
| 2 | Lensing | Proximity to hidden mass point → UV warp | Sphere room | Enter within 1.5 units of mass point center |
| 3 | Shadow | Shadows track player position, not light source | Open field | Align shadow with carved groove in floor geometry |
| 4 | Interference | Position between two audio nodes → phase cancellation | Lattice | Find the exact silence point (full cancellation) |
| 5 | Chromatic Decay | Stillness → desaturation; movement restores color | Corridor | Hold perfectly still for 10 continuous seconds |
| 6 | Resonance | Specific speed → geometry vibration frequency match | Sphere room | Move at resonant speed for 5 continuous seconds |
| 7 | Convergence | All prior rules active simultaneously at 0.2x intensity | Open field | Single position + speed satisfying all 6 constraints |

---

## Scope Boundaries

**In scope (v1):**
- 7 fully playable spaces with unique shaders and audio rules
- iPhone + iPad universal binary, iOS 17 minimum
- Pure first-person movement (drag to look, two-finger drag to move, pinch for speed)
- Real-time shader uniforms driven by player state every frame
- AVAudioEngine spatial audio with real-time parameter modulation
- JSON-driven space definitions (no hardcoded parameters)
- Hidden 5-tap settings panel (haptic on/off, volume, sensitivity)
- CoreHaptics exit-approach feedback
- Title screen (SpriteKit, "Liminal" text fade only)
- LiminalShaderLab isolated shader testing target
- App Store submission at $4.99 premium

**Out of scope (never in v1):**
- Any in-game HUD, labels, meters, or UI elements
- Tutorial or hint system
- Branching progression or hub world
- Third-party dependencies
- Multiplayer or networking of any kind
- Cloud save or iCloud sync
- Analytics, crash reporting SDKs

**Deferred to v2:**
- Apple Vision Pro / visionOS port
- Level editor + community spaces
- Speedrun mode with leaderboards
- Narrative thread across spaces
- Branching progression

---

## Security & Credentials

- Zero network calls — no credentials, no API keys, no external services
- `UserDefaults` for settings only (haptic toggle, volume, sensitivity floats)
- No sensitive data stored anywhere
- Audio stems bundled in app binary — no CDN, no download-on-first-run
- App Store privacy manifest: declare zero data collection

---

## Phase 0: Foundation + ShaderLab (Weeks 1–2)

**Objective:** Xcode project configured correctly as Universal; `LiminalShaderLab` target running a validated Metal shader; Swift fundamentals practiced in playgrounds before touching game code.

**Tasks:**
1. Create Xcode project: Universal App, SwiftUI lifecycle, iOS 17.0 deployment target, Bundle ID `com.[yourname].liminal` — **Acceptance:** Builds and runs on iPhone 15 simulator + iPad Air (5th gen) simulator with zero errors and zero warnings
2. Create `LiminalShaderLab` as second target in same `.xcodeproj`: `UIKit` lifecycle, single `SCNView` displaying a `SCNBox` with SceneKit's default lighting — **Acceptance:** Rotating cube renders on both simulators at 60fps; Metal layer visible in Xcode's View Hierarchy debugger
3. Write `TestShaders/DopplerTest.metal` as `SCNShaderModifierEntryPointFragment` that cycles cube color based on `sin(time)` uniform — **Acceptance:** Cube visibly cycles warm→cool over 2 seconds in ShaderLab; Metal GPU Frame Capture shows no API validation errors; uniform values visible in debugger
4. Wire `CADisplayLink` in `ShaderLabViewController` calling `renderer.updateAtTime` to push `time` uniform via `SCNMaterialProperty.setValue(_:forKey:)` at 60fps — **Acceptance:** Color cycle is smooth (no frame drops below 58fps in Instruments → GPU); uniform value updates visible in Xcode's Metal Debugger
5. Complete Swift playgrounds (do these before writing production code): optionals + guard, structs + protocols + extensions, closures + higher-order functions, async/await basics — **Acceptance:** Implement a working `SpaceRule` protocol with `DopplerRule` mock that returns hardcoded `RuleOutput`; compiles without errors
6. Scaffold production target file structure: create all directories and empty Swift files from the File Structure section — **Acceptance:** Project navigator matches the defined file structure exactly; all empty files compile
7. Implement `SpaceDefinition.swift` Codable structs + `SpaceLoader.swift` — **Acceptance:** `SpaceLoaderTests.swift` passes: valid `space_01_doppler.json` decodes correctly; JSON with missing required field throws `DecodingError`

**Verification checklist:**
- [ ] `CMD+B` on both targets: zero errors, zero warnings
- [ ] ShaderLab runs at 60fps on iPhone 15 simulator (Instruments → GPU shows < 8ms frame time)
- [ ] Metal API Validation enabled (Edit Scheme → Diagnostics): zero validation errors during ShaderLab run
- [ ] `CMD+U` on LiminalTests: `SpaceLoaderTests` 4/4 passing
- [ ] Xcode Organizer shows no memory leaks in ShaderLab after 60 seconds

**Risks:**
- Metal shader compiler errors: silent at build time, fail at runtime as black geometry → Enable Metal API Validation immediately; read errors in GPU Frame Capture, not console → Fallback: reduce shader to `_output.color = float4(1,0,0,1)` (solid red) to confirm wiring before adding logic

---

## Phase 1: Space 1 — Doppler (Weeks 3–5)

**Objective:** First complete playable space end-to-end on physical device. Touch movement, Doppler shader driven by real player velocity, spatial audio in sync, exit condition functional.

**Tasks:**
1. Build `PlayerController.swift`: single-finger pan → rotate camera node (clamp vertical look ±70°); two-finger pan → translate camera along XZ look vector; pinch → speed multiplier (0.5×–3.0×) — **Acceptance:** Movement is fluid on physical iPhone 15 and physical iPad; no gimbal lock at vertical extremes; camera does not clip through `SCNBox` geometry
2. Implement velocity tracking: rolling 10-frame average of `SCNNode.position` delta → `PlayerState.speed` (normalized: 0.0 at rest, 1.0 at max pinch speed) — **Acceptance:** `DebugOverlay` shows speed = 0.00 when stationary, ≈ 0.30 at default walk, ≈ 1.00 at max pinch; verified on physical device
3. Implement `DopplerRule.swift` mapping `PlayerState.speed` → `RuleOutput` with `velocityNormalized` and `colorShiftAmount` uniforms — **Acceptance:** `RuleEngineTests.swift` passes 5 cases: speed [0.0, 0.25, 0.5, 0.75, 1.0] → expected uniform values within ±0.02 tolerance
4. Build `ShaderUniformBus.swift` and wire `DopplerRule` output → `SCNMaterial` uniforms in `renderer(_:updateAtTime:)` SCNSceneRendererDelegate — **Acceptance:** Color shift in Space 1 matches ShaderLab DopplerTest behavior; no frame rate drop below 58fps on iPhone 15 during full-speed movement
5. Build `AudioManager.swift`: load `ambient_drone_01.caf`; construct AVAudioEngine graph (`AVAudioPlayerNode` → `AVAudioUnitTimePitch` → `AVAudioUnitReverb` → `mainMixerNode`); modulate pitch from `RuleOutput.audioParameters["pitchShiftSemitones"]` using parameter ramping over 0.1s — **Acceptance:** Pitch audibly rises when moving fast; returns to base when stationary; 30-second continuous movement test produces zero audio interruptions or gaps
6. Implement `VelocityThresholdHeld` exit condition evaluator: accumulates deltaTime while `speed ≥ 0.85`; resets if speed drops below threshold; triggers at 3.0 accumulated seconds — **Acceptance:** `TransitionManager` fade-to-black triggers after exactly 3.0s at target speed in 10/10 test runs; never triggers at speed 0.80 in 10/10 test runs
7. Load all Space 1 parameters exclusively from `space_01_doppler.json` via `SpaceLoader` — **Acceptance:** Change `maxColorShift` from 0.4 to 0.8 in JSON → in-game color shift intensity doubles without recompiling

**Verification checklist:**
- [ ] Space 1 playable start-to-finish on physical iPhone 15 (not simulator)
- [ ] Space 1 playable start-to-finish on physical iPad (any model, iOS 17+)
- [ ] 60fps sustained on iPhone 15; ≥ 55fps on iPhone 13 (test in Instruments → Game Performance)
- [ ] Audio pitch ramp produces no zipper noise (smooth continuous change, not stepped)
- [ ] Exit condition 10/10 correct triggers; 10/10 correct non-triggers at sub-threshold speed
- [ ] `CMD+U`: all tests passing (SpaceLoaderTests + RuleEngineTests + AudioManagerTests)
- [ ] Instruments → Leaks: zero leaks after full Space 1 playthrough

**Risks:**
- `AVAudioEngine` pitch node zipper noise at fast parameter changes → Use `AVAudioUnit.scheduleParameterBlock` with 0.1s ramp duration; never set pitch value directly → Fallback: use reverb mix change as secondary audio differentiator if pitch ramping remains noisy

---

## Phase 2: Spaces 2 + 3 — Lensing + Shadow + Transitions (Weeks 6–9)

**Objective:** Two more shaders integrated; data-driven pattern proven to scale; `TransitionManager` connecting spaces; nudge system live.

**Tasks:**
1. Write `Lensing.metal` (`SCNShaderModifierEntryPointFragment`): distort fragment UV coordinates based on `proximityNormalized` uniform (0.0 = far, 1.0 = at mass point); distortion peaks at ±0.15 UV units at full proximity — **Acceptance:** Geometry visibly warps beginning at 15 units from mass point, peaks at 5 units; no UV seaming artifacts on sphere geometry at any approach angle
2. Write `Shadow.metal`: override fragment shadow contribution using `playerPosition` uniform (vec3) instead of scene light position — **Acceptance:** Shadow direction demonstrably tracks player movement not light source; verified by moving light source in Xcode SceneKit editor — shadow does not change; moving player camera — shadow changes
3. Build `LensingRule.swift` and `ShadowRule.swift`; author `space_02_lensing.json` and `space_03_shadow.json` — **Acceptance:** Both spaces load, play, and trigger their exit conditions without any code changes to `SpaceLoader` or `RuleEngine`
4. Build `TransitionManager.swift`: on exit trigger, fade `SCNView` alpha 1.0 → 0.0 over 0.75s; async load next `SCNScene`; fade 0.0 → 1.0 over 0.75s (total 1.5s) — **Acceptance:** No visible stutter during transition; memory from previous space deallocated (Instruments → Allocations: allocation count returns to pre-space baseline within 2 seconds of transition)
5. Implement nudge system in `RuleEngine`: idle timer increments when `PlayerState.idleSeconds` crosses `NudgeConfig.idleThresholdSeconds`; dispatches nudge type to `ShaderUniformBus` and `AudioManager`; resets on player progress toward exit condition — **Acceptance:** Amplitude flare triggers at exactly 90s idle in Space 1 (verified with `DebugOverlay`); resets correctly when player accelerates

**Verification checklist:**
- [ ] Spaces 1 → 2 → 3 playable in sequence on physical iPhone + physical iPad without restart
- [ ] Lensing shader: zero UV seaming on sphere geometry at all approach angles
- [ ] Shadow shader: shadow direction tracks player on physical device (not simulator — GPU behavior differs)
- [ ] Transition duration 1.4–1.6 seconds measured manually across 10 trials
- [ ] Instruments → Allocations: no memory growth across 3 full playthroughs (baseline ± 5MB)
- [ ] Nudge fires at 90s ± 2s; resets correctly in 10/10 trials

---

## Phase 3: Spaces 4–6 + 3D Audio + Haptics (Weeks 10–13)

**Objective:** Three more spaces; `AVAudioEnvironmentNode` for true spatial audio; CoreHaptics exit feedback; debug tooling locked behind `#if DEBUG`.

**Tasks:**
1. Implement `InterferenceRule.swift` + `interference_04.metal`: player position between two fixed audio nodes → compute phase cancellation as `1.0 - abs(dot(normalize(toNode1), normalize(toNode2)))`; silence at full cancellation — **Acceptance:** Audio amplitude measurably reduces as player approaches cancellation point; full silence (< -40dB in AudioManager output) at exact cancellation position
2. Implement `ChromaticDecayRule.swift` + `ChromaticDecay.metal`: `idleSeconds` → desaturation uniform (0.0 color at 15s idle); movement → resaturation at same rate — **Acceptance:** Full desaturation reached in exactly 15 seconds of stillness; color fully restored within 5 seconds of movement
3. Implement `ResonanceRule.swift` + `Resonance.metal`: `PlayerState.speed` → proximity to resonant frequency; geometry vibration amplitude peaks when speed matches resonant value from JSON — **Acceptance:** Visible geometry vibration at resonant speed; amplitude drops smoothly as speed deviates ± 0.15 from target
4. Upgrade `AudioManager`: add `AVAudioEnvironmentNode` between reverb and mainMixer; set listener position to `PlayerController.camera.simdWorldPosition` each frame; Space 4 uses two `AVAudioPlayerNode` instances with fixed 3D positions — **Acceptance:** Audio panning is directionally accurate when rotating in-place in Space 4; standing between nodes and rotating produces audible left-right shift
5. Add CoreHaptics exit-approach feedback: `CHHapticEngine` plays increasing-intensity pattern as exit condition completion % rises from 0% to 100%; defaults to off; toggled in hidden settings — **Acceptance:** Haptic pattern fires correctly on physical iPhone 15; `CHHapticEngine.capabilitiesForHardware().supportsHaptics` check prevents crash on simulator
6. Guard `DebugOverlay` and all `print()` statements with `#if DEBUG` — **Acceptance:** Release scheme build contains zero debug logging; `CMD+B` with Release configuration produces identical frame rate to Debug on physical device

**Verification checklist:**
- [ ] Spaces 1–6 playable in sequence on physical iPhone + iPad without crash
- [ ] Space 4: audio panning directionally accurate (verified by rotating in-place at cancellation midpoint)
- [ ] Space 5: desaturation timer accurate to ± 0.5s (verified with DebugOverlay)
- [ ] Space 6: resonant frequency match produces visible vibration peak
- [ ] Haptics fire on iPhone 15; no crash on iPhone 13 simulator
- [ ] Release build: zero debug logs in Xcode console during 10-minute session
- [ ] Cold launch to Space 1 interactive < 3 seconds on iPhone 13 (measured with Instruments → App Launch)

---

## Phase 4: Space 7 + Polish + TestFlight (Weeks 14–16)

**Objective:** Convergence space; title screen; hidden settings; external playtesting.

**Tasks:**
1. Implement `ConvergenceRule.swift`: combines `DopplerRule` + `LensingRule` + `ShadowRule` + `InterferenceRule` + `ChromaticDecayRule` + `ResonanceRule` each at 0.2× intensity; exit condition requires all 6 sub-conditions simultaneously within a narrow tolerance (speed within ± 0.05 of resonant, position within 3 units of interference null, etc.) — **Acceptance:** Space 7 solvable in < 15 minutes by 2 blind playtesters who have completed Spaces 1–6; solution discoverable through experimentation without prior knowledge
2. Build `TitleScene.swift` (SpriteKit `SKScene`): black background; `SKLabelNode` "Liminal" in SF Mono Light 48pt; `SKAction` fade-in 1.5s → hold 1.0s → fade-out 1.5s; on completion, `TransitionManager` loads Space 1 — **Acceptance:** Title to Space 1 interactive in < 4 seconds total; title text readable on both 6.7" iPhone and 12.9" iPad
3. Implement hidden 5-tap settings panel: `UITapGestureRecognizer` with `numberOfTapsRequired = 5` on a 44×44pt corner region; presents a `UIView` overlay with three controls (haptic `UISwitch`, volume `UISlider`, sensitivity `UISlider`); persisted to `UserDefaults` under keys `liminal.hapticEnabled`, `liminal.volume`, `liminal.sensitivity` — **Acceptance:** Panel appears on 5-tap on both form factors; settings persist across app restarts; no visible UI element hints at existence of panel
4. Submit to TestFlight with 10 external testers; provide zero instructions beyond "here is a game" — **Acceptance:** 8/10 testers solve Space 1 within 7 minutes; 7/10 rate experience "complete" or "very complete" in post-session form; all reported crashes fixed before Phase 5

**Verification checklist:**
- [ ] All 7 spaces on physical iPhone 13 (A15 minimum), iPhone 15, iPad Air M1, iPad Pro M4
- [ ] App binary size < 150MB (check in Xcode Organizer → App Size report)
- [ ] App Store privacy manifest: zero data types declared
- [ ] TestFlight build passes Apple's automated binary checks
- [ ] 60fps on iPhone 15; ≥ 55fps on iPhone 13 across all 7 spaces (Instruments)

---

## Phase 5: App Store Submission (Weeks 17–18)

**Tasks:**
1. Address all TestFlight feedback — **Acceptance:** Zero open crash reports; any space with < 50% solve rate has nudge intensity increased by 1.5× in JSON (no code change)
2. Produce App Store assets: screenshots at 1290×2796 (6.7" iPhone) and 2048×2732 (12.9" iPad) — 5 screenshots each showing different spaces; App Store preview video 60 seconds, 60fps, no UI visible — **Acceptance:** All assets pass App Store Connect validator with no size or format errors
3. App Store listing: title "Liminal", subtitle "Find the rule. Find the exit.", description (no space rule spoilers), keywords (atmospheric, exploration, puzzle, abstract, sound, light, shader) — **Acceptance:** Listing approved by App Store Connect metadata validator
4. Submit binary for App Store review — **Acceptance:** Approved and live

---

## Testing Strategy

**Automated (XCTest — run `CMD+U` before every phase completion):**
- `SpaceLoaderTests`: valid JSON → correct `SpaceDefinition` field values; JSON missing `id` → `DecodingError`; JSON missing `exit.condition` → `DecodingError`; extra unknown field → silently ignored (4 tests)
- `RuleEngineTests`: for each of 7 rules, provide `PlayerState` at speed [0.0, 0.25, 0.5, 0.75, 1.0] → assert `RuleOutput.shaderUniforms` values within ± 0.02 (35 tests total)
- `AudioManagerTests`: engine initializes without throwing; `startEngine()` twice doesn't crash; `updateParameters([:])` with empty dict is a no-op (3 tests)

**Manual (physical device required for all):**
- Metal shader behavior (simulator GPU differs)
- CoreHaptics (unavailable on simulator)
- AVAudioEngine spatial audio directionality
- 60fps verification under load
- Touch gesture feel on both form factors

**Playtest protocol (Phase 4, 10 external testers):**
- Hand tester a device, say nothing
- Observe without speaking; note: first exit time, spaces abandoned, moments of confusion
- Post-session: "Did you feel like you understood what was expected of you? Did the experience feel complete?"
- Target: 80% solve Space 1 in < 7 minutes; 70% rate experience "complete"
