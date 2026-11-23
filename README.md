# Liminal

[![Swift](https://img.shields.io/badge/Swift-f05138?style=flat-square&logo=swift)](#tech-stack) [![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

> Find the rule. Find the exit.

Liminal is a first-person atmospheric exploration game for iPhone and iPad. Seven abstract spaces. No tutorial. Each space operates by a hidden rule — a relationship between your movement, the light, the sound, and the geometry. Discover the rule through observation. Find the exit by mastering it.

## Features

- **Seven distinct spaces** — each defined by a unique rule: chromatic decay, convergence, Doppler-shifted audio, interference patterns, gravitational lensing, resonance, and shadow
- **Metal shaders per space** — each space has a fragment shader modifier, and resonance and convergence also have geometry modifiers
- **JSON-driven configuration** — each space file selects the geometry type and configures its dimensions, shader, audio, exit condition, and idle nudge
- **Live rule evaluation** — each frame, `RuleEngine` evaluates the active rule against the player’s state to produce shader uniforms and audio parameters
- **AVAudioEngine audio** — spatial audio with real-time parameter modulation tied directly to movement and rule state
- **No gameplay HUD in Release builds** — light, sound, and geometry give clues to each rule. Debug builds show a diagnostic overlay.

## Quick Start

### Prerequisites
- A Mac with Xcode 16+
- An iOS 17.0+ simulator runtime or a compatible iPhone or iPad running 17.0+

The app uses bundle ID `com.liminall.app`, marketing version `1.0.0`, and build `4`. To run on a device, select your team and a bundle ID it can provision in Xcode’s Signing & Capabilities tab.

### Installation
```bash
git clone https://github.com/saagpatel/Liminal
cd Liminal
open Liminal.xcodeproj
```

### Usage
Select the `Liminal` scheme and your simulator or device in Xcode, then build and run. Drag with one finger to look, drag with two fingers to move, and pinch to adjust speed. Tap the top-left corner five times to open settings.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 6.0, strict concurrency |
| 3D rendering | SceneKit |
| GPU effects | Metal shader modifiers on SceneKit materials |
| Audio | AVAudioEngine with real-time parameter modulation |
| Configuration | Bundled JSON decoded as each space loads |

## Architecture

`SpaceLoader` decodes each space’s JSON into a `SpaceDefinition`. `SpaceScene` uses the shader name to select a Swift `SpaceRule` and load the matching Metal modifiers onto a SceneKit material. It uses the exit condition’s name and parameters to configure the exit check.

In SceneKit’s per-frame render callback, `RuleEngine` evaluates the player state. `ShaderUniformBus` writes the resulting uniforms to the material by name. The callback sends audio parameters and the listener position to `AudioManager` on the main queue.

## License

MIT
