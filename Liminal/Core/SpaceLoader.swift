import Foundation

/// Loads and decodes space definitions from JSON files in the app bundle.
enum SpaceLoader {
    enum LoadError: Error, CustomStringConvertible {
        case fileNotFound(String)
        case decodingFailed(String, Error)

        var description: String {
            switch self {
            case .fileNotFound(let name):
                return "Space JSON not found in bundle: \(name)"
            case .decodingFailed(let name, let error):
                return "Failed to decode \(name): \(error)"
            }
        }
    }

    /// Load a single space definition by filename (without extension).
    static func load(_ name: String, from bundle: Bundle = .main,
                     subdirectory: String? = "Resources/Spaces") throws -> SpaceDefinition {
        guard let url = bundle.url(forResource: name, withExtension: "json",
                                   subdirectory: subdirectory) else {
            throw LoadError.fileNotFound(name)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LoadError.fileNotFound(name)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(SpaceDefinition.self, from: data)
        } catch {
            throw LoadError.decodingFailed(name, error)
        }
    }

    /// Load all space definitions, sorted by index.
    static func loadAll(from bundle: Bundle = .main) throws -> [SpaceDefinition] {
        let names = (1...7).map { String(format: "space_%02d", $0) }
        var spaces: [SpaceDefinition] = []

        for name in names {
            // Find any JSON file starting with this prefix
            if let url = bundle.urls(forResourcesWithExtension: "json", subdirectory: "Resources/Spaces")?
                .first(where: { $0.lastPathComponent.hasPrefix(name) })
            {
                let data = try Data(contentsOf: url)
                let space = try JSONDecoder().decode(SpaceDefinition.self, from: data)
                spaces.append(space)
            }
        }

        return spaces.sorted { $0.index < $1.index }
    }

    /// Decode from raw JSON data — useful for testing.
    static func decode(from data: Data) throws -> SpaceDefinition {
        try JSONDecoder().decode(SpaceDefinition.self, from: data)
    }
}
