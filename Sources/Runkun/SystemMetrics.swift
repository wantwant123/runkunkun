import Foundation

struct SystemMetrics {
    var cpuPercent: Double
    var memoryUsedPercent: Double
    var batterySummary: String
    var networkDownBytesPerSecond: Double
    var networkUpBytesPerSecond: Double

    var networkSummary: String {
        "↓ \(Self.formatBytes(networkDownBytesPerSecond))/s  ↑ \(Self.formatBytes(networkUpBytesPerSecond))/s"
    }

    static let empty = SystemMetrics(
        cpuPercent: 0,
        memoryUsedPercent: 0,
        batterySummary: "--",
        networkDownBytesPerSecond: 0,
        networkUpBytesPerSecond: 0
    )

    private static func formatBytes(_ bytes: Double) -> String {
        let units = ["B", "KB", "MB", "GB"]
        var value = max(bytes, 0)
        var unitIndex = 0

        while value >= 1024, unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        if unitIndex == 0 {
            return String(format: "%.0f %@", value, units[unitIndex])
        }
        return String(format: "%.1f %@", value, units[unitIndex])
    }
}
