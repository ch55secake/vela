import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fatalError("Usage: generate-icon.swift <output.png>")
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let iconSize = 1024
let canvas = NSRect(x: 0, y: 0, width: iconSize, height: iconSize)

guard
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: iconSize,
        pixelsHigh: iconSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ),
    let context = NSGraphicsContext(bitmapImageRep: bitmap),
    let background = NSGradient(
        colors: [
            NSColor(calibratedRed: 0.16, green: 0.24, blue: 0.53, alpha: 1),
            NSColor(calibratedRed: 0.055, green: 0.08, blue: 0.22, alpha: 1),
        ]
    )
else {
    fatalError("Could not prepare app icon artwork")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high

let roundedBackground = NSBezierPath(
    roundedRect: canvas,
    xRadius: 220,
    yRadius: 220
)
roundedBackground.addClip()
background.draw(in: canvas, angle: 90)

NSColor(calibratedRed: 0.48, green: 0.62, blue: 1, alpha: 0.12).setFill()
NSBezierPath(
    ovalIn: NSRect(x: 390, y: 520, width: 760, height: 760)
).fill()

let bellShadow = NSShadow()
bellShadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.24)
bellShadow.shadowBlurRadius = 34
bellShadow.shadowOffset = NSSize(width: 0, height: -16)
bellShadow.set()

let bellColor = NSColor(calibratedRed: 1, green: 0.96, blue: 0.84, alpha: 1)
bellColor.setFill()

let bellBody = NSBezierPath()
bellBody.move(to: NSPoint(x: 345, y: 350))
bellBody.curve(
    to: NSPoint(x: 385, y: 405),
    controlPoint1: NSPoint(x: 345, y: 350),
    controlPoint2: NSPoint(x: 385, y: 350)
)
bellBody.line(to: NSPoint(x: 385, y: 515))
bellBody.curve(
    to: NSPoint(x: 465, y: 680),
    controlPoint1: NSPoint(x: 385, y: 605),
    controlPoint2: NSPoint(x: 415, y: 668)
)
bellBody.curve(
    to: NSPoint(x: 559, y: 680),
    controlPoint1: NSPoint(x: 485, y: 702),
    controlPoint2: NSPoint(x: 539, y: 702)
)
bellBody.curve(
    to: NSPoint(x: 639, y: 515),
    controlPoint1: NSPoint(x: 609, y: 668),
    controlPoint2: NSPoint(x: 639, y: 605)
)
bellBody.line(to: NSPoint(x: 639, y: 405))
bellBody.curve(
    to: NSPoint(x: 679, y: 350),
    controlPoint1: NSPoint(x: 639, y: 350),
    controlPoint2: NSPoint(x: 679, y: 350)
)
bellBody.curve(
    to: NSPoint(x: 645, y: 310),
    controlPoint1: NSPoint(x: 679, y: 328),
    controlPoint2: NSPoint(x: 665, y: 310)
)
bellBody.line(to: NSPoint(x: 379, y: 310))
bellBody.curve(
    to: NSPoint(x: 345, y: 350),
    controlPoint1: NSPoint(x: 359, y: 310),
    controlPoint2: NSPoint(x: 345, y: 328)
)
bellBody.close()
bellBody.fill()

NSBezierPath(
    roundedRect: NSRect(x: 488, y: 684, width: 48, height: 56),
    xRadius: 24,
    yRadius: 24
).fill()
NSBezierPath(
    ovalIn: NSRect(x: 476, y: 248, width: 72, height: 72)
).fill()
NSShadow().set()

let badge = NSBezierPath(
    ovalIn: NSRect(x: 625, y: 635, width: 182, height: 182)
)
NSColor(calibratedRed: 0.98, green: 0.28, blue: 0.31, alpha: 1).setFill()
badge.fill()
NSColor(calibratedRed: 1, green: 0.94, blue: 0.85, alpha: 1).setStroke()
badge.lineWidth = 15
badge.stroke()

NSColor(calibratedRed: 1, green: 0.96, blue: 0.88, alpha: 1).setFill()
NSBezierPath(
    ovalIn: NSRect(x: 686, y: 696, width: 60, height: 60)
).fill()

NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode app icon")
}
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try pngData.write(to: outputURL, options: .atomic)
