# Liminal

Atmospheric first-person exploration game for iPhone + iPad (iOS 17+) built in Swift with SceneKit and Metal shaders. Players navigate abstract 3D spaces by decoding hidden physics-based rules through light and sound behavior. No HUD, no text, no tutorials — 7 spaces, premium App Store release ($4.99).

## Stack
- Swift: 6.0 (structured concurrency, no Objective-C interop)
- SceneKit: iOS 17 SDK — scene graph, geometry, camera, touch input
- Metal: Metal 3 (iOS 17) — custom fragment shaders via SCNShaderModifierEntryPointFragment
- AVAudioEngine: iOS 17 SDK — spatial audio, real-time parameter modulation
- SpriteKit: iOS 17 SDK — title screen and transitions only (no in-game UI)
- CoreHaptics: iOS 17 SDK — exit approach feedback, off by default
- Xcode: 16.x — required for Metal shader debugger and iOS 17 SDK

## Build / Test / Run
Build and run via Xcode 16.x on a physical device (iPhone 13 / A15 or newer). Drag to look, two-finger drag to move, pinch to adjust speed.

XCTest covers all rule logic and data loading. Run tests via `xcodebuild test` or the Xcode test navigator. No UI tests in v1.

See IMPLEMENTATION-ROADMAP.md for phase details and docs/PORTFOLIO-DISPOSITION.md for release state.

## Conventions
- Swift strict concurrency: `Sendable` conformances required, no data races
- File naming: PascalCase for types/files, camelCase for properties/methods
- No third-party dependencies — Apple SDKs only
- `#if DEBUG` guard on all debug tooling (DebugOverlay, logging)
- Space definitions are JSON-driven — all space parameters (velocityThreshold, maxColorShift, etc.) come from JSON files in the app bundle, never hardcoded in Swift

## Gotchas
- **Metal shader workflow**: prototype in LiminalShaderLab target first, then integrate into the main target. Simulator GPU behavior differs from device — physical device testing is required for Metal work.
- **Shader approach**: use `SCNShaderModifierEntryPointFragment` only; do not replace SceneKit's renderer with `SCNProgram` — SceneKit must handle the lighting pass.
- **Scope**: add only features in the current phase of IMPLEMENTATION-ROADMAP.md; no in-game UI (labels, buttons, meters) — the no-HUD constraint is absolute.

<!-- portfolio-context:start -->
# Portfolio Context

## What This Project Is

Atmospheric first-person exploration game for iPhone + iPad (iOS 17+) built in Swift with SceneKit and Metal shaders. Players navigate abstract 3D spaces by decoding hidden physics-based rules through light and sound behavior. No HUD, no text, no tutorials — 7 spaces, premium App Store release ($4.99).

## Current State

**Feature-complete — all 5 phases shipped; App Store submission ready**
See IMPLEMENTATION-ROADMAP.md for full phase details and docs/PORTFOLIO-DISPOSITION.md for current release state.

## Stack

- Swift: 6.0 (structured concurrency, no Objective-C interop)
- SceneKit: iOS 17 SDK — scene graph, geometry, camera, touch input
- Metal: Metal 3 (iOS 17) — custom fragment shaders via SCNShaderModifierEntryPointFragment
- AVAudioEngine: iOS 17 SDK — spatial audio, real-time parameter modulation
- SpriteKit: iOS 17 SDK — title screen and transitions only (no in-game UI)
- CoreHaptics: iOS 17 SDK — exit approach feedback, off by default
- Xcode: 16.x — required for Metal shader debugger and iOS 17 SDK

## How To Run

Build and run. Drag to look, two-finger drag to move, pinch to adjust speed. No other instructions — that's the game.

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
