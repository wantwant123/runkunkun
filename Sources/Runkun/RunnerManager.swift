import Foundation

final class RunnerManager {
    private(set) var definition = RunnerDefinition.fallback
    private(set) var usesCustomDefinition = false
    private let fileManager = FileManager.default

    var folderURL: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return (base ?? URL(fileURLWithPath: NSHomeDirectory())).appendingPathComponent("Runkun", isDirectory: true)
    }

    private var runnerURL: URL {
        folderURL.appendingPathComponent("runner.json")
    }

    func ensureCustomizationFile() {
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            guard !fileManager.fileExists(atPath: runnerURL.path) else {
                return
            }
            try RunnerManager.sampleJSON.write(to: runnerURL, atomically: true, encoding: .utf8)
        } catch {
            NSLog("Runkun failed to create runner.json: \(error)")
        }
    }

    func reload() {
        do {
            let data = try Data(contentsOf: runnerURL)
            let decoded = try JSONDecoder().decode(RunnerDefinition.self, from: data)
            let validated = try decoded.validated()
            definition = validated
            usesCustomDefinition = !validated.isBundledDefaultPlaceholder
        } catch {
            NSLog("Runkun using fallback runner: \(error)")
            definition = .fallback
            usesCustomDefinition = false
        }
    }

    static let sampleJSON = """
    {
      "name": "Default Kun",
      "palette": {
        "K": "#222222",
        "S": "#F6C36B",
        "B": "#2F80ED",
        "W": "#FFFFFF",
        "R": "#F05265",
        "Y": "#FFD84D"
      },
      "frames": [
        {
          "rows": [
            "................",
            "......SSSS......",
            ".....SWWWS......",
            ".....SWKWS......",
            "......SSSS......",
            ".......B........",
            "....RRBBB.......",
            "...R..BBB.......",
            "......BBB.......",
            ".....B.B........",
            "....B...B.......",
            "...B.....B......",
            "..K.......K.....",
            "................",
            "................",
            "................"
          ]
        },
        {
          "rows": [
            "................",
            "......SSSS......",
            ".....SWWWS......",
            ".....SWKWS......",
            "......SSSS......",
            ".......B........",
            ".....RBBB.......",
            "....R.BBB.......",
            "......BBB.......",
            ".....B..B.......",
            "....B....B......",
            "...B......K.....",
            "..K.............",
            "................",
            "................",
            "................"
          ]
        },
        {
          "rows": [
            "................",
            "......SSSS......",
            ".....SWWWS......",
            ".....SWKWS......",
            "......SSSS......",
            ".......B........",
            "......BBB.......",
            "....RRBBB.......",
            "......BBB.......",
            "......B.B.......",
            ".....B...B......",
            "....B.....B.....",
            "...K.......K....",
            "................",
            "................",
            "................"
          ]
        },
        {
          "rows": [
            "................",
            "......SSSS......",
            ".....SWWWS......",
            ".....SWKWS......",
            "......SSSS......",
            ".......B........",
            "......BBBR......",
            "......BBB.R.....",
            "......BBB.......",
            ".....B..B.......",
            "....B....B......",
            "...K......B.....",
            "..........K.....",
            "................",
            "................",
            "................"
          ]
        },
        {
          "rows": [
            "................",
            "......SSSS......",
            ".....SWWWS......",
            ".....SWKWS......",
            "......SSSS......",
            ".......B........",
            "......BBB.......",
            "......BBBRR.....",
            "......BBB.......",
            ".......B.B......",
            "......B...B.....",
            ".....B.....B....",
            "....K.......K...",
            "................",
            "................",
            "................"
          ]
        },
        {
          "rows": [
            "................",
            "......SSSS......",
            ".....SWWWS......",
            ".....SWKWS......",
            "......SSSS......",
            ".......B........",
            "......BBB.......",
            ".....RBBB.......",
            "....R.BBB.......",
            "......B..B......",
            ".....B....B.....",
            "....K......B....",
            "...........K....",
            "................",
            "................",
            "................"
          ]
        }
      ]
    }
    """
}
