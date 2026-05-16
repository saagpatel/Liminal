# Liminal

## Overview
Atmospheric first-person exploration game for iPhone + iPad (iOS 17+) built in Swift with SceneKit and Metal shaders. Players navigate abstract 3D spaces by decoding hidden physics-based rules through light and sound behavior. No HUD, no text, no tutorials — 7 spaces, premium App Store release ($4.99).

## Tech Stack
- Swift: 6.0 (structured concurrency, no Objective-C interop)
- SceneKit: iOS 17 SDK — scene graph, geometry, camera, touch input
- Metal: Metal 3 (iOS 17) — custom fragment shaders via SCNShaderModifierEntryPointFragment
- AVAudioEngine: iOS 17 SDK — spatial audio, real-time parameter modulation
- SpriteKit: iOS 17 SDK — title screen and transitions only (no in-game UI)
- CoreHaptics: iOS 17 SDK — exit approach feedback, off by default
- Xcode: 16.x — required for Metal shader debugger and iOS 17 SDK

## Development Conventions
- Swift strict concurrency: `Sendable` conformances required, no data races
- File naming: PascalCase for types/files, camelCase for properties/methods
- No third-party dependencies — Apple SDKs only
- XCTest for all rule logic and data loading; no UI tests in v1
- `#if DEBUG` guard on all debug tooling (DebugOverlay, logging)
- Metal shaders: prototype in LiminalShaderLab target before integrating into main target
- Space definitions: JSON-driven — never hardcode space parameters in Swift

## Current Phase
**Phase 0: Foundation + ShaderLab (Weeks 1–2)**
See IMPLEMENTATION-ROADMAP.md for full phase details, tasks, and acceptance criteria.

## Key Decisions
| Decision | Choice | Why |
|---|---|---|
| Shader approach | SCNShaderModifierEntryPointFragment | Safer than full SCNProgram replacement; SceneKit handles lighting pass |
| Space definitions | JSON files in app bundle | Data-driven; tweak parameters without recompiling |
| Audio engine | AVAudioEngine + AVAudioUnitTimePitch | Continuous real-time modulation; sample triggering can't do this |
| Progression | Linear, 7 spaces | No hub world UI needed; keeps pacing tight |
| Player representation | Pure first-person camera | No character rig required; reduces scope significantly |
| Minimum device | iPhone 13 (A15 chip) | Targets iOS 17 install base; Metal 3 features available |
| Settings | Hidden 5-tap gesture | No visible settings UI; preserves the no-HUD aesthetic |
| Pricing | $4.99 premium | No IAP, no ads, no analytics |

## Do NOT
- Do not write Metal shaders directly into the main target before validating in LiminalShaderLab
- Do not hardcode any space parameters (velocityThreshold, maxColorShift, etc.) — all values come from JSON
- Do not use `SCNProgram` to replace SceneKit's renderer — use shader modifiers only
- Do not add features not in the current phase of IMPLEMENTATION-ROADMAP.md
- Do not add any third-party Swift packages — zero external dependencies
- Do not build any in-game UI (labels, buttons, meters) — the constraint is absolute
- Do not skip physical device testing for Metal shader work — simulator GPU behavior differs

<!-- portfolio-context:start -->
# Portfolio Context

## What This Project Is

Atmospheric first-person exploration game for iPhone + iPad (iOS 17+) built in Swift with SceneKit and Metal shaders. Players navigate abstract 3D spaces by decoding hidden physics-based rules through light and sound behavior. No HUD, no text, no tutorials — 7 spaces, premium App Store release ($4.99).

## Current State

**Phase 0: Foundation + ShaderLab (Weeks 1–2)**
See IMPLEMENTATION-ROADMAP.md for full phase details, tasks, and acceptance criteria.

## Stack

- Swift: 6.0 (structured concurrency, no Objective-C interop)
- SceneKit: iOS 17 SDK — scene graph, geometry, camera, touch input
- Metal: Metal 3 (iOS 17) — custom fragment shaders via SCNShaderModifierEntryPointFragment
- AVAudioEngine: iOS 17 SDK — spatial audio, real-time parameter modulation
- SpriteKit: iOS 17 SDK — title screen and transitions only (no in-game UI)
- CoreHaptics: iOS 17 SDK — exit approach feedback, off by default
- Xcode: 16.x — required for Metal shader debugger and iOS 17 SDK

## How To Run

Build and run. Swipe to move, tilt to look. No other instructions — that's the game.

## Known Risks

- Do not write Metal shaders directly into the main target before validating in LiminalShaderLab
- Do not hardcode any space parameters (velocityThreshold, maxColorShift, etc.) — all values come from JSON
- Do not use `SCNProgram` to replace SceneKit's renderer — use shader modifiers only
- Do not add features not in the current phase of IMPLEMENTATION-ROADMAP.md
- Do not add any third-party Swift packages — zero external dependencies
- Do not build any in-game UI (labels, buttons, meters) — the constraint is absolute
- Do not skip physical device testing for Metal shader work — simulator GPU behavior differs

## Next Recommended Move

Use this context plus the README and supporting docs to resume the next active task, then promote the repo beyond minimum-viable by capturing a dedicated handoff, roadmap, or discovery artifact.

<!-- portfolio-context:end -->
