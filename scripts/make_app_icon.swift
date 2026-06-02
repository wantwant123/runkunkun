import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    fatalError("Usage: make_app_icon <source-png> <iconset-dir>")
}

let sourceURL = URL(fileURLWithPath: arguments[1])
let iconsetURL = URL(fileURLWithPath: arguments[2])

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    fatalError("Could not load source image: \(sourceURL.path)")
}

try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let targets: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for target in targets {
    let pixels = target.pixels
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixels,
            pixelsHigh: pixels,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
    else {
        fatalError("Could not create bitmap for \(target.name)")
    }

    bitmap.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current = context
    context?.cgContext.setShouldAntialias(true)
    context?.imageInterpolation = .high

    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: pixels, height: pixels).fill()

    let inset = CGFloat(pixels) * 0.08
    let backgroundRect = NSRect(
        x: inset,
        y: inset,
        width: CGFloat(pixels) - inset * 2,
        height: CGFloat(pixels) - inset * 2
    )
    let background = NSBezierPath(
        roundedRect: backgroundRect,
        xRadius: CGFloat(pixels) * 0.18,
        yRadius: CGFloat(pixels) * 0.18
    )
    NSGradient(
        starting: NSColor(calibratedRed: 0.14, green: 0.15, blue: 0.16, alpha: 1),
        ending: NSColor(calibratedRed: 0.33, green: 0.34, blue: 0.35, alpha: 1)
    )?.draw(in: background, angle: 90)

    NSColor(calibratedWhite: 1, alpha: 0.18).setStroke()
    background.lineWidth = max(1, CGFloat(pixels) * 0.018)
    background.stroke()

    let runnerSize = CGFloat(pixels) * 0.78
    let runnerRect = NSRect(
        x: (CGFloat(pixels) - runnerSize) / 2,
        y: (CGFloat(pixels) - runnerSize) / 2,
        width: runnerSize,
        height: runnerSize
    )
    sourceImage.draw(in: runnerRect, from: .zero, operation: .sourceOver, fraction: 1)

    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode \(target.name)")
    }
    try data.write(to: iconsetURL.appendingPathComponent(target.name))
}
