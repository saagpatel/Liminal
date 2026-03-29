![Swift](https://img.shields.io/badge/Swift-6.0-FA7343?logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-17.0%2B-000000?logo=apple&logoColor=white)
![SceneKit](https://img.shields.io/badge/SceneKit-3D%20Rendering-blue)
![Metal](https://img.shields.io/badge/Metal-GPU%20Shaders-A90000?logo=apple&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

# Liminal

> Find the rule. Find the exit.

Liminal is a first-person atmospheric exploration game for iPhone and iPad. Seven abstract spaces. No instructions. No HUD. Each space operates by a hidden rule — a relationship between your movement, the light, the sound, and the geometry around you. Discover the rule through observation and experimentation. Find the exit by mastering it.

## How It Works

Every space is defined entirely by a JSON configuration that describes its geometry, shader, audio, and exit condition. At runtime, a `RuleEngine` evaluates your position, velocity, speed, and idle time on every frame, producing shader uniforms and audio parameters that respond in real time.

The seven rules include chromatic decay, convergence, Doppler-shifted audio, interference patterns, gravitational lensing, resonance, and shadow — each expressed as a Metal shader and a Swift rule type sharing a common protocol.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift 6.0 (strict concurrency) |
| 3D rendering | SceneKit |
| GPU effects | Metal (custom `.metal` shaders per space) |
| Audio | AVAudioEngine with real-time parameter modulation |
| Configuration | JSON space definitions decoded at launch |
| UI lifecycle | SwiftUI App + UIKit scene delegate |
| Testing | XCTest unit tests (11 test files) |

## Prerequisites

- Xcode 16.0+
- iOS 17.0+ device or simulator
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) 2.38+ (to regenerate the `.xcodeproj` from `project.yml`)

## Getting Started

```bash
# Clone the repository
git clone <repo-url>
cd Liminal

# Regenerate the Xcode project (if needed)
xcodegen generate

# Open in Xcode
open Liminal.xcodeproj
```

Select the **Liminal** scheme, choose a simulator or connected device running iOS 17+, and press Run.

To iterate on shaders in isolation, use the **LiminalShaderLab** scheme — a lightweight companion app that loads test Metal shaders without the full game runtime.

## Project Structure

```
Liminal/
├── Liminal/
│   ├── App/               # @main entry point and AVAudioSession setup
│   ├── Core/              # RuleEngine, SpaceLoader, AudioManager,
│   │                      #   PlayerController, ShaderUniformBus
│   ├── Scenes/            # SCNScene setup, SpaceViewController,
│   │                      #   TitleScene, TransitionManager
│   ├── Spaces/            # SpaceDefinition (Codable), ExitCondition,
│   │                      #   and one Swift type per rule
│   ├── Shaders/           # Ten .metal files (one per visual effect)
│   └── Resources/         # JSON space definitions and audio assets
├── LiminalShaderLab/      # Standalone shader development target
├── LiminalTests/          # Unit tests for rules, engine, audio, and loader
└── project.yml            # XcodeGen project spec
```

## Architecture

```
[JSON Space Definitions]
        ↓
[SpaceLoader] → [SCNScene + Geometry] → [Metal Shader Modifiers]
                        ↓
              [PlayerController] ← [Touch Input]
                        ↓
              [RuleEngine] ← PlayerState (position, velocity, speed, idle)
                   ↓              ↓
         [ShaderUniformBus]   [AudioManager]
              ↓                    ↓
         [Metal GPU]          [AVAudioEngine]
```

## Screenshots

<!-- Add screenshots here -->

## License

MIT License. Copyright © 2026 Saag Patel. See [LICENSE](LICENSE) for details.
