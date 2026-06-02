import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    fatalError("Usage: clean_runner_assets <source-dir> <output-dir>")
}

let sourceDir = URL(fileURLWithPath: arguments[1], isDirectory: true)
let outputDir = URL(fileURLWithPath: arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

let frameNames = (1...8).map { String(format: "frame_%02d.png", $0) }

for frameName in frameNames {
    let sourceURL = sourceDir.appendingPathComponent(frameName)
    let outputURL = outputDir.appendingPathComponent(frameName)

    guard
        let sourceImage = NSImage(contentsOf: sourceURL),
        let cgImage = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil),
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
    else {
        fatalError("Could not load \(frameName)")
    }

    let width = cgImage.width
    let height = cgImage.height
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

    guard let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Could not create bitmap context for \(frameName)")
    }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    for y in 0..<height {
        for x in 0..<width {
            let offset = y * bytesPerRow + x * bytesPerPixel
            let red = pixels[offset]
            let green = pixels[offset + 1]
            let blue = pixels[offset + 2]
            let maxChannel = max(red, green, blue)
            let minChannel = min(red, green, blue)
            let isCheckerBackground = red > 220 && green > 220 && blue > 220 && (maxChannel - minChannel) < 18

            if isCheckerBackground {
                pixels[offset] = 0
                pixels[offset + 1] = 0
                pixels[offset + 2] = 0
                pixels[offset + 3] = 0
            }
        }
    }

    guard
        let outputImage = context.makeImage(),
        let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil)
    else {
        fatalError("Could not encode \(frameName)")
    }

    CGImageDestinationAddImage(destination, outputImage, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Could not write \(frameName)")
    }
}
