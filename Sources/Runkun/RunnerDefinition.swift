import AppKit

struct RunnerDefinition: Decodable {
    var name: String?
    var palette: [String: String]
    var frames: [RunnerFrame]

    var isBundledDefaultPlaceholder: Bool {
        name == "Default Kun" && frames.count == 6
    }

    var paletteColors: [Character: NSColor] {
        palette.reduce(into: [:]) { result, entry in
            guard let key = entry.key.first, let color = NSColor(hex: entry.value) else {
                return
            }
            result[key] = color
        }
    }

    static let fallback = RunnerDefinition(
        name: "Default Kun",
        palette: [
            "K": "#222222",
            "S": "#F6C36B",
            "B": "#2F80ED",
            "W": "#FFFFFF",
            "R": "#F05265",
            "Y": "#FFD84D"
        ],
        frames: DefaultRunner.frames
    )
}

struct RunnerFrame: Decodable {
    var rows: [String]
}

extension RunnerDefinition {
    func validated() throws -> RunnerDefinition {
        guard !frames.isEmpty else {
            throw RunnerValidationError.emptyFrames
        }

        for frame in frames {
            guard !frame.rows.isEmpty else {
                throw RunnerValidationError.emptyFrame
            }

            let width = frame.rows.first?.count ?? 0
            guard width > 0 else {
                throw RunnerValidationError.emptyFrame
            }

            guard frame.rows.allSatisfy({ $0.count == width }) else {
                throw RunnerValidationError.inconsistentRowWidth
            }

            guard width <= 64, frame.rows.count <= 64 else {
                throw RunnerValidationError.tooLarge
            }
        }

        return self
    }
}

enum RunnerValidationError: Error {
    case emptyFrames
    case emptyFrame
    case inconsistentRowWidth
    case tooLarge
}

enum DefaultRunner {
    static let frames: [RunnerFrame] = [
        RunnerFrame(rows: [
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
        ]),
        RunnerFrame(rows: [
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
        ]),
        RunnerFrame(rows: [
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
        ]),
        RunnerFrame(rows: [
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
        ]),
        RunnerFrame(rows: [
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
        ]),
        RunnerFrame(rows: [
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
        ])
    ]
}

extension NSColor {
    convenience init?(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard trimmed.count == 6, let value = Int(trimmed, radix: 16) else {
            return nil
        }

        let red = CGFloat((value >> 16) & 0xff) / 255.0
        let green = CGFloat((value >> 8) & 0xff) / 255.0
        let blue = CGFloat(value & 0xff) / 255.0
        self.init(calibratedRed: red, green: green, blue: blue, alpha: 1)
    }
}
