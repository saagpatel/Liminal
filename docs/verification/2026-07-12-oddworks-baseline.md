# Liminal — Oddworks Baseline Verification

- Date: 2026-07-12 PDT
- Branch: `codex/feat/liminal-oddworks-release-slice-20260712`
- Base: clean `main` at `29ae1bccd493351cedffb84eaddec3aea55cd4a7`
- Toolchain: Xcode 26.6 (`17F113`), Swift 6, iOS 26.5 Simulator SDK

## Corrected release blockers

- The checked-in Xcode project had no game-resource build phase. Its successful 244 KB archive contained no spaces, shaders, or app icon. `project.yml` now owns the resource contract and the regenerated project copies seven space definitions and ten Metal shader sources while compiling the asset catalog normally.
- Copying the entire raw `Resources` directory nested `Assets.xcassets` inside the app and made iOS reject installation as `Missing bundle ID`. Only `Spaces` is now copied as a folder; the asset catalog stays in its correct compiled build phase.
- Release builds had no bundled audio and compiled the procedural fallback only under `DEBUG`, producing an empty player in Release. Missing optional stems now use looped, redistribution-safe procedural buffers in every configuration.
- Volume and control-sensitivity settings persisted but did not affect the live engine/controller. Both now apply immediately, and a saved zero volume remains zero.
- The opening camera’s yaw faced the corridor’s back wall. It now faces down the authored corridor, whose geometry includes repeating ribs and a distinct exit frame for depth and motion-parallax feedback.
- The unavailable `SFMono-Light` title font was replaced with `Menlo-Regular`.
- VoiceOver can identify the game surface and invoke an `Open Settings` custom action; settings controls have explicit labels and identifiers.
- Entering the background now suspends the audio engine, and foreground return restarts and reschedules the procedural soundscape through the app lifecycle delegate.
- The Makefile used nonexistent SwiftPM commands. It now drives the real Xcode project for simulator build/test and device Release bundle verification.

## Checks

| Check | Result |
|---|---|
| XcodeGen regeneration | Passed with XcodeGen 2.45.4 |
| iPhone 17 / iOS 26.5 simulator tests | 102 passed, 0 failed |
| Release device build | Passed, unsigned as intended for this engineering gate |
| Release bundle verifier | Passed: executable, bundle ID `com.liminal.app`, version `1.0.0`, privacy manifest, compiled assets, 7 spaces, and 10 shaders |
| Release executable SHA-256 | `fc4b7252a2c262c0c90f8f74820e35a0afb4f10eac9de63408a019a41c359ef8` |
| Release resource-path manifest SHA-256 | `4cbaf84c2d785689962557cf1b3163b01b831816a1401d8cf3b4e646f9b6ac34` |
| Bundled MIT license SHA-256 | `6118a611296437620de9140424a829b3ef1eebca6726c948ba78a7c61d7d286e` |
| Simulator install and launch | Passed for `com.liminal.app` on booted iPhone 17 |
| Live first-space visual readback | Passed: forward corridor, repeating depth ribs, distinct exit frame, and debug rule values rendered at 60 FPS |
| Runtime console | No missing-space or missing-font warning after corrections |

The only build note is Xcode’s expected App Intents metadata skip because the app does not link AppIntents.

## Not yet proven

- No physical-device Metal/API validation or Instruments performance capture has occurred.
- Audio audibility and spatial behavior have not been judged on physical speakers/headphones.
- Audio-engine background suspension and foreground resumption pass automated coverage, but the complete app transition, interruption, reduced-audio completion, final-space ending, and every-space visual behavior still require runtime exercises.
- No naive external cohort has run. Discoverability, puzzle fairness, motion comfort, completion, and retention remain unknown.
- The device Release bundle is unsigned. A valid provisioning profile, signed archive/export, App Store Connect record, live marketing URL, screenshot set, pricing confirmation, TestFlight evidence, and explicit submission approval remain publication gates.
- Existing screenshots and “submission ready” documentation predate this verified build and must not be used as release evidence without replacement.

This is a working engineering receipt, not an App Store readiness declaration.
