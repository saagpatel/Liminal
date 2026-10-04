import Foundation
import Testing

/// SceneKit parses `#pragma arguments` one declaration per line. A line with several
/// declarations makes the whole shader modifier fail to compile at runtime, and the
/// surface renders solid magenta with no error surfaced to the app.
struct ShaderArgumentDeclarationTests {
    @Test func everyShaderDeclaresOneArgumentPerLine() throws {
        let shaderDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Liminal/Shaders")
        let files = try FileManager.default.contentsOfDirectory(at: shaderDirectory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "metal" }
        #expect(!files.isEmpty, "No shaders found at \(shaderDirectory.path)")

        for file in files {
            let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: .newlines)
            var inArguments = false
            for (number, rawLine) in lines.enumerated() {
                let line = rawLine.trimmingCharacters(in: .whitespaces)
                if line.hasPrefix("#pragma") {
                    inArguments = line == "#pragma arguments"
                    continue
                }
                guard inArguments, !line.isEmpty, !line.hasPrefix("//") else { continue }
                let declarations = line.components(separatedBy: "//")[0].filter { $0 == ";" }.count
                #expect(
                    declarations <= 1,
                    "\(file.lastPathComponent):\(number + 1) declares \(declarations) arguments on one line"
                )
            }
        }
    }
}
