# Liminal

[![Swift](https://img.shields.io/badge/Swift-f05138?style=flat-square&logo=swift)](#) [![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](#)

> Find the rule. Find the exit.

Liminal is a first-person atmospheric exploration game for iPhone and iPad. Seven abstract spaces. No instructions. No HUD. Each space operates by a hidden rule — a relationship between your movement, the light, the sound, and the geometry. Discover the rule through observation. Find the exit by mastering it.

## Features

- **Seven distinct spaces** — each defined by a unique rule: chromatic decay, convergence, Doppler-shifted audio, interference patterns, gravitational lensing, resonance, and shadow
- **Metal shaders per space** — custom `.metal` shader for each rule; the shader and the Swift rule type share a common protocol, keeping logic and visuals in sync
- **JSON-driven configuration** — all space geometry, shader parameters, audio, and exit conditions are defined in JSON, loaded at runtime
- **Live rule evaluation** — a `RuleEngine` evaluates player position, velocity, speed, and idle time every frame, producing shader uniforms and audio parameters in real time
- **AVAudioEngine audio** — spatial audio with real-time parameter modulation tied directly to movement and rule state
- **No HUD, no instructions** — the entire game communicates through environmental feedback

## Quick Start

### Prerequisites
- Xcode 16+
- iOS 17.0+ device or simulator

### Installation
```bash
git clone https://github.com/saagpatel/Liminal
open Liminal.xcodeproj
```

### Usage
Build and run. Drag to look, two-finger drag to move, pinch to adjust speed. No other instructions — that's the game.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 6.0, strict concurrency |
| 3D rendering | SceneKit |
| GPU effects | Metal (custom `.metal` shader per space) |
| Audio | AVAudioEngine with real-time parameter modulation |
| Configuration | JSON space definitions decoded at launch |

## Architecture

Each space is represented by a `SpaceDefinition` decoded from JSON, which references a shader name, a rule type, an audio preset, and an exit condition. At runtime, `SpaceScene` loads the Metal shader by name and attaches it as an `SCNShaderModifierEntryPointFragment` on the space material, keeping SceneKit's lighting pass intact. The `RuleEngine` is driven by `SCNSceneRendererDelegate.renderer(_:updateAtTime:)` each frame and produces a `[String: Float]` uniform dictionary that `ShaderUniformBus` pushes to the material via `setValue(_:forKey:)`; the same `RuleOutput` simultaneously drives AVAudioEngine parameter updates, keeping visuals and audio synchronized without a separate message-passing step.

## License

MIT