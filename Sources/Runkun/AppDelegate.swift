import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let statusItemLength: CGFloat = 34
    private static let bundledRunnerSize = NSSize(width: 30, height: 30)

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let metricsMonitor = SystemMetricsMonitor()
    private let runnerManager = RunnerManager()
    private let renderer = RunnerRenderer()
    private let bundledFrameNames = (1...8).map { String(format: "frame_%02d", $0) }

    private var timer: Timer?
    private var menu: NSMenu?
    private var cpuItem = NSMenuItem()
    private var memoryItem = NSMenuItem()
    private var batteryItem = NSMenuItem()
    private var networkItem = NSMenuItem()
    private var runnerItem = NSMenuItem()
    private var pauseItem = NSMenuItem()

    private var currentFrameIndex = 0
    private var lastFrameDate = Date()
    private var isPaused = false
    private var lastMetrics = SystemMetrics.empty
    private var bundledFrames: [NSImage] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        runnerManager.ensureCustomizationFile()
        runnerManager.reload()
        bundledFrames = loadBundledRunnerFrames()
        configureStatusItem()
        configureMenu()
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }

    private func configureStatusItem() {
        statusItem.length = Self.statusItemLength
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.imageScaling = .scaleProportionallyUpOrDown
        statusItem.button?.toolTip = "Runkun"
    }

    private func configureMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        runnerItem = NSMenuItem(title: "Runkun", action: nil, keyEquivalent: "")
        runnerItem.isEnabled = false
        menu.addItem(runnerItem)
        menu.addItem(.separator())

        cpuItem = NSMenuItem(title: "CPU: --", action: nil, keyEquivalent: "")
        cpuItem.isEnabled = false
        memoryItem = NSMenuItem(title: "Memory: --", action: nil, keyEquivalent: "")
        memoryItem.isEnabled = false
        batteryItem = NSMenuItem(title: "Battery: --", action: nil, keyEquivalent: "")
        batteryItem.isEnabled = false
        networkItem = NSMenuItem(title: "Network: --", action: nil, keyEquivalent: "")
        networkItem.isEnabled = false

        menu.addItem(cpuItem)
        menu.addItem(memoryItem)
        menu.addItem(batteryItem)
        menu.addItem(networkItem)
        menu.addItem(.separator())

        pauseItem = NSMenuItem(title: "Pause Animation", action: #selector(togglePause), keyEquivalent: "")
        pauseItem.target = self
        menu.addItem(pauseItem)

        let revealItem = NSMenuItem(title: "Open Runner Folder", action: #selector(openRunnerFolder), keyEquivalent: "")
        revealItem.target = self
        menu.addItem(revealItem)

        let reloadItem = NSMenuItem(title: "Reload Runner", action: #selector(reloadRunner), keyEquivalent: "r")
        reloadItem.target = self
        menu.addItem(reloadItem)

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(title: "About Runkun", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(title: "Quit Runkun", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)

        statusItem.menu = menu
        self.menu = menu
    }

    private func tick() {
        lastMetrics = metricsMonitor.sample()
        updateMenu()
        updateAnimation()
    }

    private func updateMenu() {
        let runnerName = runnerManager.usesCustomDefinition ? (runnerManager.definition.name ?? "Custom Runner") : "Bundled Kun"
        runnerItem.title = "Runkun - \(runnerName)"
        cpuItem.title = String(format: "CPU: %.0f%%", lastMetrics.cpuPercent)
        memoryItem.title = String(format: "Memory: %.0f%% used", lastMetrics.memoryUsedPercent)
        batteryItem.title = "Battery: \(lastMetrics.batterySummary)"
        networkItem.title = "Network: \(lastMetrics.networkSummary)"
        pauseItem.state = isPaused ? .on : .off
    }

    private func updateAnimation() {
        if !runnerManager.usesCustomDefinition, !bundledFrames.isEmpty {
            updateBundledAnimation()
            return
        }

        let frames = runnerManager.definition.frames
        guard !frames.isEmpty else {
            statusItem.button?.image = renderer.fallbackImage()
            return
        }

        if !isPaused {
            let now = Date()
            let frameDuration = animationFrameDuration(cpuPercent: lastMetrics.cpuPercent)
            if now.timeIntervalSince(lastFrameDate) >= frameDuration {
                currentFrameIndex = (currentFrameIndex + 1) % frames.count
                lastFrameDate = now
            }
        }

        let frame = frames[currentFrameIndex % frames.count]
        let image = renderer.image(
            for: frame,
            palette: runnerManager.definition.paletteColors,
            size: NSSize(width: 22, height: 22)
        )
        image.isTemplate = false
        statusItem.button?.image = image
    }

    private func updateBundledAnimation() {
        if !isPaused {
            let now = Date()
            let frameDuration = animationFrameDuration(cpuPercent: lastMetrics.cpuPercent)
            if now.timeIntervalSince(lastFrameDate) >= frameDuration {
                currentFrameIndex = (currentFrameIndex + 1) % bundledFrames.count
                lastFrameDate = now
            }
        }

        let frame = bundledFrames[currentFrameIndex % bundledFrames.count]
        statusItem.button?.image = renderer.menuImage(from: frame, size: Self.bundledRunnerSize)
    }

    private func loadBundledRunnerFrames() -> [NSImage] {
        bundledFrameNames.compactMap { name in
            Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "DefaultRunner")
                .flatMap(NSImage.init(contentsOf:))
        }
    }

    private func animationFrameDuration(cpuPercent: Double) -> TimeInterval {
        let clamped = max(0, min(cpuPercent, 100))
        return 0.42 - (clamped / 100.0) * 0.34
    }

    @objc private func togglePause() {
        isPaused.toggle()
    }

    @objc private func openRunnerFolder() {
        NSWorkspace.shared.open(runnerManager.folderURL)
    }

    @objc private func reloadRunner() {
        runnerManager.reload()
        currentFrameIndex = 0
        tick()
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Runkun"
        alert.informativeText = "A customizable macOS menu bar runner. Edit runner.json to draw your own runner."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
