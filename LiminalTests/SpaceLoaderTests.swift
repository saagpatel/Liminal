import XCTest
@testable import Liminal

final class SpaceLoaderTests: XCTestCase {

    // MARK: - Valid JSON

    func testValidDopplerJSONDecodesCorrectly() throws {
        let json = """
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
        """.data(using: .utf8)!

        let space = try SpaceLoader.decode(from: json)

        XCTAssertEqual(space.id, "space_01_doppler")
        XCTAssertEqual(space.index, 1)
        XCTAssertEqual(space.geometry.type, .corridor)
        XCTAssertEqual(space.geometry.scale.x, 40.0, accuracy: 0.01)
        XCTAssertEqual(space.geometry.scale.y, 6.0, accuracy: 0.01)
        XCTAssertEqual(space.geometry.scale.z, 4.0, accuracy: 0.01)
        XCTAssertEqual(space.geometry.subdivisions, 48)
        XCTAssertEqual(space.shader.name, "Doppler")
        XCTAssertEqual(space.shader.parameters["maxColorShift"] ?? -1, 0.4, accuracy: 0.01)
        XCTAssertEqual(space.audio.stem, "ambient_drone_01")
        XCTAssertEqual(space.audio.parameters["maxPitchShiftSemitones"] ?? -1, 3.0, accuracy: 0.01)
        XCTAssertEqual(space.exit.condition, "velocityThresholdHeld")
        XCTAssertEqual(space.exit.parameters["targetVelocity"] ?? -1, 0.85, accuracy: 0.01)
        XCTAssertEqual(space.exit.parameters["durationSeconds"] ?? -1, 3.0, accuracy: 0.01)
        XCTAssertEqual(space.nudge.idleThresholdSeconds, 90, accuracy: 0.01)
        XCTAssertEqual(space.nudge.type, .amplitudeFlare)
    }

    // MARK: - Missing Required Fields

    func testMissingIdThrowsDecodingError() {
        let json = """
        {
          "index": 1,
          "geometry": { "type": "corridor", "scale": [1,1,1], "subdivisions": 1 },
          "shader": { "name": "X", "parameters": {} },
          "audio": { "stem": "x", "rule": "x", "parameters": {} },
          "exit": { "condition": "x", "parameters": {} },
          "nudge": { "idleThresholdSeconds": 1, "type": "amplitudeFlare" }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try SpaceLoader.decode(from: json)) { error in
            XCTAssertTrue(error is DecodingError, "Expected DecodingError, got \(type(of: error))")
        }
    }

    func testMissingExitConditionThrowsDecodingError() {
        let json = """
        {
          "id": "test",
          "index": 1,
          "geometry": { "type": "corridor", "scale": [1,1,1], "subdivisions": 1 },
          "shader": { "name": "X", "parameters": {} },
          "audio": { "stem": "x", "rule": "x", "parameters": {} },
          "exit": { "parameters": {} },
          "nudge": { "idleThresholdSeconds": 1, "type": "amplitudeFlare" }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try SpaceLoader.decode(from: json)) { error in
            XCTAssertTrue(error is DecodingError, "Expected DecodingError, got \(type(of: error))")
        }
    }

    // MARK: - Extra Fields

    func testExtraUnknownFieldsAreIgnored() throws {
        let json = """
        {
          "id": "space_test",
          "index": 99,
          "unknownField": "should be ignored",
          "geometry": { "type": "sphere", "scale": [10,10,10], "subdivisions": 24 },
          "shader": { "name": "Test", "parameters": {}, "extraShaderField": true },
          "audio": { "stem": "test", "rule": "test", "parameters": {} },
          "exit": { "condition": "test", "parameters": {} },
          "nudge": { "idleThresholdSeconds": 60, "type": "colorPulse" }
        }
        """.data(using: .utf8)!

        let space = try SpaceLoader.decode(from: json)
        XCTAssertEqual(space.id, "space_test")
        XCTAssertEqual(space.geometry.type, .sphere)
        XCTAssertEqual(space.nudge.type, .colorPulse)
    }

    // MARK: - Audio Sources

    func testJSONWithSourcesArrayDecodes() throws {
        let json = """
        {
          "id": "space_multi_source",
          "index": 4,
          "geometry": { "type": "lattice", "scale": [20,6,20], "subdivisions": 16 },
          "shader": { "name": "Interference", "parameters": {} },
          "audio": {
            "stem": "ambient_drone_04",
            "rule": "InterferenceAudio",
            "parameters": {},
            "sources": [
              { "stem": "tone_a", "position": [-6.0, 1.7, 0.0] },
              { "stem": "tone_b", "position": [6.0, 1.7, 0.0] }
            ]
          },
          "exit": { "condition": "silencePoint", "parameters": {} },
          "nudge": { "idleThresholdSeconds": 120, "type": "amplitudeFlare" }
        }
        """.data(using: .utf8)!

        let space = try SpaceLoader.decode(from: json)
        XCTAssertEqual(space.audio.sources?.count, 2)
        XCTAssertEqual(space.audio.sources?[0].stem, "tone_a")
        XCTAssertEqual(space.audio.sources?[1].position, [6.0, 1.7, 0.0])
    }

    func testJSONWithoutSourcesDecodesAsNil() throws {
        let json = """
        {
          "id": "space_single",
          "index": 1,
          "geometry": { "type": "corridor", "scale": [40,6,4], "subdivisions": 48 },
          "shader": { "name": "Doppler", "parameters": {} },
          "audio": { "stem": "ambient_drone_01", "rule": "DopplerAudio", "parameters": {} },
          "exit": { "condition": "velocityThresholdHeld", "parameters": {} },
          "nudge": { "idleThresholdSeconds": 90, "type": "amplitudeFlare" }
        }
        """.data(using: .utf8)!

        let space = try SpaceLoader.decode(from: json)
        XCTAssertNil(space.audio.sources)
    }
}
