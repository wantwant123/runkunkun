import AppKit

final class RunnerRenderer {
    func menuImage(from image: NSImage, size: NSSize) -> NSImage {
        let sourceImage = image.visibleAlphaImage() ?? image
        let output = NSImage(size: size)
        output.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let sourceSize = sourceImage.size
        let scale = min(size.width / max(sourceSize.width, 1), size.height / max(sourceSize.height, 1))
        let drawSize = NSSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
        let drawRect = NSRect(
            x: floor((size.width - drawSize.width) / 2),
            y: floor((size.height - drawSize.height) / 2),
            width: drawSize.width,
            height: drawSize.height
        )
        sourceImage.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1)
        output.unlockFocus()
        output.isTemplate = false
        return output
    }

    func image(for frame: RunnerFrame, palette: [Character: NSColor], size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let width = frame.rows.map(\.count).max() ?? 1
        let height = max(frame.rows.count, 1)
        let pixel = floor(min(size.width / CGFloat(width), size.height / CGFloat(height)))
        let drawingWidth = CGFloat(width) * pixel
        let drawingHeight = CGFloat(height) * pixel
        let offsetX = floor((size.width - drawingWidth) / 2)
        let offsetY = floor((size.height - drawingHeight) / 2)

        for (rowIndex, row) in frame.rows.enumerated() {
            for (columnIndex, character) in row.enumerated() {
                guard character != ".", character != " ", let color = palette[character] else {
                    continue
                }

                color.setFill()
                let rect = NSRect(
                    x: offsetX + CGFloat(columnIndex) * pixel,
                    y: offsetY + CGFloat(height - rowIndex - 1) * pixel,
                    width: pixel,
                    height: pixel
                )
                rect.fill()
            }
        }

        image.unlockFocus()
        return image
    }

    func fallbackImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 22, height: 22))
        image.lockFocus()
        NSColor.systemBlue.setFill()
        NSBezierPath(ovalIn: NSRect(x: 4, y: 4, width: 14, height: 14)).fill()
        image.unlockFocus()
        return image
    }
}

private extension NSImage {
    func visibleAlphaImage() -> NSImage? {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1

        for y in 0..<height {
            for x in 0..<width {
                let alpha = pixels[y * bytesPerRow + x * bytesPerPixel + 3]
                guard alpha > 8 else {
                    continue
                }
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }

        guard maxX >= minX, maxY >= minY else {
            return nil
        }

        let padding = 1
        let cropX = max(minX - padding, 0)
        let cropY = max(minY - padding, 0)
        let cropMaxX = min(maxX + padding, width - 1)
        let cropMaxY = min(maxY + padding, height - 1)
        let cropRect = CGRect(
            x: cropX,
            y: cropY,
            width: cropMaxX - cropX + 1,
            height: cropMaxY - cropY + 1
        )

        guard let cropped = cgImage.cropping(to: cropRect) else {
            return nil
        }

        let result = NSImage(cgImage: cropped, size: NSSize(width: cropRect.width, height: cropRect.height))
        result.isTemplate = false
        return result
    }
}
