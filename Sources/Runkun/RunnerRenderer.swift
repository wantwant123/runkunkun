import AppKit

final class RunnerRenderer {
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
