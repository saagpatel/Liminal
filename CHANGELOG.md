# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed

- Restore all authored spaces, shaders, icon resources, and redistribution-safe procedural audio to Release builds.
- Apply volume and control-sensitivity settings immediately and recover audio across app lifecycle transitions.
- Improve opening-space depth cues, camera orientation, and VoiceOver access to settings.
- Replace stale SwiftPM commands with verified Xcode build, test, archive, and bundle-validation workflows.

### Fixed

- Keep the game faded to black after the final-space ending instead of returning to active play.
- Surface missing space resources and audio initialization failures to the player.
