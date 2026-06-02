import AppKit
import Foundation

let outputDirectory = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    : URL(fileURLWithPath: "Assets/DefaultRunner", isDirectory: true)

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

struct Pose {
    let bob: CGFloat
    let armLeft: CGFloat
    let armRight: CGFloat
    let legLeft: CGFloat
    let legRight: CGFloat
    let lean: CGFloat
}

let poses: [Pose] = [
    Pose(bob: 0, armLeft: -8, armRight: 7, legLeft: -10, legRight: 9, lean: -1),
    Pose(bob: -2, armLeft: -3, armRight: 2, legLeft: -5, legRight: 5, lean: 0),
    Pose(bob: -3, armLeft: 6, armRight: -7, legLeft: 8, legRight: -8, lean: 1),
    Pose(bob: -1, armLeft: 9, armRight: -10, legLeft: 12, legRight: -11, lean: 1),
    Pose(bob: 0, armLeft: 7, armRight: -8, legLeft: 9, legRight: -10, lean: 0),
    Pose(bob: -2, armLeft: 2, armRight: -3, legLeft: 4, legRight: -5, lean: -1),
    Pose(bob: -3, armLeft: -7, armRight: 6, legLeft: -8, legRight: 8, lean: -1),
    Pose(bob: -1, armLeft: -10, armRight: 9, legLeft: -11, legRight: 12, lean: 0)
]

let canvasSize = NSSize(width: 128, height: 128)
let pixelSize = 512

extension NSColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        self.init(
            calibratedRed: CGFloat((hex >> 16) & 0xff) / 255.0,
            green: CGFloat((hex >> 8) & 0xff) / 255.0,
            blue: CGFloat(hex & 0xff) / 255.0,
            alpha: alpha
        )
    }
}

func strokeLine(from start: NSPoint, to end: NSPoint, color: NSColor, width: CGFloat, cap: NSBezierPath.LineCapStyle = .round) {
    let path = NSBezierPath()
    path.lineWidth = width
    path.lineCapStyle = cap
    path.move(to: start)
    path.line(to: end)
    color.setStroke()
    path.stroke()
}

func fillOval(_ rect: NSRect, _ color: NSColor) {
    color.setFill()
    NSBezierPath(ovalIn: rect).fill()
}

func fillRounded(_ rect: NSRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func drawFrame(_ pose: Pose, index: Int) throws {
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelSize,
            pixelsHigh: pixelSize,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
    else {
        fatalError("Could not create bitmap")
    }

    bitmap.size = canvasSize
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current = context
    context?.cgContext.setShouldAntialias(true)
    context?.imageInterpolation = .high

    NSColor.clear.setFill()
    NSRect(origin: .zero, size: canvasSize).fill()

    let x = 64 + pose.lean
    let y = 67 + pose.bob

    let outline = NSColor(hex: 0x202124)
    let shadow = NSColor(hex: 0x101214, alpha: 0.22)
    let hairDark = NSColor(hex: 0x4c5157)
    let hairMid = NSColor(hex: 0x8c9299)
    let hairLight = NSColor(hex: 0xd6d8db)
    let face = NSColor(hex: 0xffd956)
    let cheek = NSColor(hex: 0xf34f48)
    let suit = NSColor(hex: 0x151719)
    let suitLight = NSColor(hex: 0x2a2d30)
    let orange = NSColor(hex: 0xf28b2e)
    let yellow = NSColor(hex: 0xffd33f)
    let shoe = NSColor(hex: 0x111111)

    fillOval(NSRect(x: x - 27, y: y - 50, width: 54, height: 12), shadow)

    let body = NSRect(x: x - 20, y: y - 28, width: 39, height: 41)
    fillRounded(body.offsetBy(dx: 2, dy: -2), radius: 13, color: outline)
    fillRounded(body, radius: 13, color: suit)
    fillRounded(NSRect(x: x - 14, y: y - 21, width: 18, height: 25), radius: 8, color: suitLight)

    let shirt = NSBezierPath()
    shirt.move(to: NSPoint(x: x - 15, y: y + 5))
    shirt.line(to: NSPoint(x: x + 16, y: y + 5))
    shirt.line(to: NSPoint(x: x + 11, y: y - 17))
    shirt.line(to: NSPoint(x: x - 12, y: y - 17))
    shirt.close()
    yellow.setFill()
    shirt.fill()

    strokeLine(
        from: NSPoint(x: x - 17, y: y - 8),
        to: NSPoint(x: x - 30 + pose.armLeft * 0.55, y: y - 18 + abs(pose.armLeft) * 0.4),
        color: outline,
        width: 10
    )
    strokeLine(
        from: NSPoint(x: x + 16, y: y - 8),
        to: NSPoint(x: x + 29 + pose.armRight * 0.55, y: y - 18 + abs(pose.armRight) * 0.4),
        color: outline,
        width: 10
    )
    strokeLine(
        from: NSPoint(x: x - 17, y: y - 8),
        to: NSPoint(x: x - 29 + pose.armLeft * 0.55, y: y - 17 + abs(pose.armLeft) * 0.4),
        color: orange,
        width: 7
    )
    strokeLine(
        from: NSPoint(x: x + 16, y: y - 8),
        to: NSPoint(x: x + 28 + pose.armRight * 0.55, y: y - 17 + abs(pose.armRight) * 0.4),
        color: face,
        width: 7
    )

    strokeLine(
        from: NSPoint(x: x - 8, y: y - 27),
        to: NSPoint(x: x - 9 + pose.legLeft, y: y - 46),
        color: outline,
        width: 11
    )
    strokeLine(
        from: NSPoint(x: x + 8, y: y - 27),
        to: NSPoint(x: x + 8 + pose.legRight, y: y - 46),
        color: outline,
        width: 11
    )
    strokeLine(
        from: NSPoint(x: x - 9 + pose.legLeft, y: y - 46),
        to: NSPoint(x: x - 17 + pose.legLeft * 1.25, y: y - 49),
        color: shoe,
        width: 7
    )
    strokeLine(
        from: NSPoint(x: x + 8 + pose.legRight, y: y - 46),
        to: NSPoint(x: x + 16 + pose.legRight * 1.25, y: y - 49),
        color: shoe,
        width: 7
    )

    let head = NSRect(x: x - 22, y: y + 4, width: 45, height: 39)
    fillOval(head.offsetBy(dx: 2, dy: -2), outline)
    fillOval(head, face)

    let leftHair = NSBezierPath()
    leftHair.move(to: NSPoint(x: x - 26, y: y + 26))
    leftHair.curve(
        to: NSPoint(x: x - 2, y: y + 45),
        controlPoint1: NSPoint(x: x - 23, y: y + 42),
        controlPoint2: NSPoint(x: x - 12, y: y + 48)
    )
    leftHair.curve(
        to: NSPoint(x: x + 23, y: y + 24),
        controlPoint1: NSPoint(x: x + 13, y: y + 47),
        controlPoint2: NSPoint(x: x + 22, y: y + 37)
    )
    leftHair.line(to: NSPoint(x: x + 16, y: y + 18))
    leftHair.curve(
        to: NSPoint(x: x - 24, y: y + 18),
        controlPoint1: NSPoint(x: x + 1, y: y + 28),
        controlPoint2: NSPoint(x: x - 12, y: y + 30)
    )
    leftHair.close()
    hairDark.setFill()
    leftHair.fill()

    fillRounded(NSRect(x: x - 18, y: y + 31, width: 18, height: 12), radius: 4, color: hairLight)
    fillRounded(NSRect(x: x - 3, y: y + 34, width: 20, height: 10), radius: 4, color: hairMid)
    fillRounded(NSRect(x: x + 12, y: y + 25, width: 13, height: 13), radius: 5, color: hairDark)
    fillRounded(NSRect(x: x - 24, y: y + 18, width: 12, height: 17), radius: 5, color: hairDark)

    fillOval(NSRect(x: x - 14, y: y + 18, width: 7, height: 8), outline)
    fillOval(NSRect(x: x + 7, y: y + 18, width: 7, height: 8), outline)
    fillOval(NSRect(x: x - 12, y: y + 21, width: 2.3, height: 2.3), NSColor.white)
    fillOval(NSRect(x: x + 9, y: y + 21, width: 2.3, height: 2.3), NSColor.white)

    fillOval(NSRect(x: x - 20, y: y + 11, width: 8, height: 5), cheek)
    fillOval(NSRect(x: x + 13, y: y + 11, width: 8, height: 5), cheek)

    strokeLine(
        from: NSPoint(x: x - 2, y: y + 15),
        to: NSPoint(x: x + 4, y: y + 14),
        color: outline,
        width: 2.5,
        cap: .round
    )

    fillRounded(NSRect(x: x - 24, y: y + 8, width: 9, height: 13), radius: 3, color: orange)
    fillRounded(NSRect(x: x + 17, y: y + 8, width: 9, height: 13), radius: 3, color: yellow)

    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode frame")
    }
    let url = outputDirectory.appendingPathComponent(String(format: "frame_%02d.png", index + 1))
    try data.write(to: url)
}

for (index, pose) in poses.enumerated() {
    try drawFrame(pose, index: index)
}

let preview = NSImage(size: NSSize(width: 8 * 72, height: 72))
preview.lockFocus()
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: 8 * 72, height: 72).fill()
for index in 0..<8 {
    let frameURL = outputDirectory.appendingPathComponent(String(format: "frame_%02d.png", index + 1))
    NSImage(contentsOf: frameURL)?.draw(
        in: NSRect(x: index * 72, y: 0, width: 72, height: 72),
        from: .zero,
        operation: .sourceOver,
        fraction: 1
    )
}
preview.unlockFocus()

if let tiff = preview.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let data = rep.representation(using: .png, properties: [:]) {
    try data.write(to: outputDirectory.appendingPathComponent("preview.png"))
}
