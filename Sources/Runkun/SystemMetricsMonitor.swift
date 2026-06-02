import Darwin
import Foundation
import IOKit.ps
import MachO

final class SystemMetricsMonitor {
    private var previousCPUCounts: CPUCounts?
    private var previousNetworkSample: NetworkSample?

    func sample() -> SystemMetrics {
        let network = networkRates()
        return SystemMetrics(
            cpuPercent: cpuPercent(),
            memoryUsedPercent: memoryUsedPercent(),
            batterySummary: batterySummary(),
            networkDownBytesPerSecond: network.down,
            networkUpBytesPerSecond: network.up
        )
    }

    private func cpuPercent() -> Double {
        guard let current = CPUCounts.current() else {
            return 0
        }

        defer {
            previousCPUCounts = current
        }

        guard let previous = previousCPUCounts else {
            return 0
        }

        let user = current.user - previous.user
        let system = current.system - previous.system
        let nice = current.nice - previous.nice
        let idle = current.idle - previous.idle
        let total = user + system + nice + idle

        guard total > 0 else {
            return 0
        }

        return Double(user + system + nice) / Double(total) * 100.0
    }

    private func memoryUsedPercent() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return 0
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let usedPages = UInt64(stats.active_count + stats.wire_count + stats.compressor_page_count)
        let usedBytes = Double(usedPages * pageSize)
        let totalBytes = Double(ProcessInfo.processInfo.physicalMemory)

        guard totalBytes > 0 else {
            return 0
        }

        return min(100, max(0, usedBytes / totalBytes * 100.0))
    }

    private func batterySummary() -> String {
        guard
            let powerInfo = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sourceList = IOPSCopyPowerSourcesList(powerInfo)?.takeRetainedValue() as? [CFTypeRef]
        else {
            return "No battery"
        }

        for source in sourceList {
            guard
                let description = IOPSGetPowerSourceDescription(powerInfo, source)?.takeUnretainedValue() as? [String: Any],
                let current = description[kIOPSCurrentCapacityKey] as? Int,
                let maximum = description[kIOPSMaxCapacityKey] as? Int,
                maximum > 0
            else {
                continue
            }

            let percent = Int(round(Double(current) / Double(maximum) * 100))
            let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
            return isCharging ? "\(percent)% charging" : "\(percent)%"
        }

        return "No battery"
    }

    private func networkRates() -> (down: Double, up: Double) {
        let totals = networkTotals()
        let now = Date()
        let current = NetworkSample(date: now, downBytes: totals.down, upBytes: totals.up)

        defer {
            previousNetworkSample = current
        }

        guard let previous = previousNetworkSample else {
            return (0, 0)
        }

        let elapsed = max(now.timeIntervalSince(previous.date), 0.001)
        let down = Double(totals.down.subtractingReportingOverflow(previous.downBytes).partialValue) / elapsed
        let up = Double(totals.up.subtractingReportingOverflow(previous.upBytes).partialValue) / elapsed
        return (down, up)
    }

    private func networkTotals() -> (down: UInt64, up: UInt64) {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let first = interfaces else {
            return (0, 0)
        }
        defer {
            freeifaddrs(interfaces)
        }

        var down: UInt64 = 0
        var up: UInt64 = 0
        var cursor: UnsafeMutablePointer<ifaddrs>? = first

        while let current = cursor {
            let interface = current.pointee
            defer {
                cursor = interface.ifa_next
            }

            guard let address = interface.ifa_addr, address.pointee.sa_family == UInt8(AF_LINK) else {
                continue
            }

            let flags = Int32(interface.ifa_flags)
            guard (flags & IFF_UP) != 0, (flags & IFF_LOOPBACK) == 0 else {
                continue
            }

            guard let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self).pointee else {
                continue
            }

            down += UInt64(data.ifi_ibytes)
            up += UInt64(data.ifi_obytes)
        }

        return (down, up)
    }
}

private struct CPUCounts {
    var user: UInt64
    var system: UInt64
    var idle: UInt64
    var nice: UInt64

    static func current() -> CPUCounts? {
        var cpuInfo: processor_info_array_t?
        var numCPUInfo = mach_msg_type_number_t(0)
        var numCPUs = natural_t(0)

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )

        guard result == KERN_SUCCESS, let cpuInfo else {
            return nil
        }

        defer {
            let size = vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: cpuInfo)), size)
        }

        var counts = CPUCounts(user: 0, system: 0, idle: 0, nice: 0)
        let stride = Int(CPU_STATE_MAX)

        for cpuIndex in 0..<Int(numCPUs) {
            let base = cpuIndex * stride
            counts.user += UInt64(cpuInfo[base + Int(CPU_STATE_USER)])
            counts.system += UInt64(cpuInfo[base + Int(CPU_STATE_SYSTEM)])
            counts.idle += UInt64(cpuInfo[base + Int(CPU_STATE_IDLE)])
            counts.nice += UInt64(cpuInfo[base + Int(CPU_STATE_NICE)])
        }

        return counts
    }
}

private struct NetworkSample {
    var date: Date
    var downBytes: UInt64
    var upBytes: UInt64
}
