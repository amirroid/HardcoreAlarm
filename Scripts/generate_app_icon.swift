import Cocoa

func renderIcon(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        img.unlockFocus()
        return img
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let margin = size * 0.08
    let badgeRect = rect.insetBy(dx: margin, dy: margin)
    let cornerRadius = size * 0.22

    // 1. Draw outer shadow & background rounded rectangle
    ctx.saveGState()
    let path = CGPath(roundedRect: badgeRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(path)
    ctx.clip()

    // Deep dark background gradient (#0D0D11 to #1C1C24)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0).cgColor,
        NSColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0).cgColor
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(bgGradient, start: CGPoint(x: badgeRect.midX, y: badgeRect.maxY), end: CGPoint(x: badgeRect.midX, y: badgeRect.minY), options: [])
    }
    ctx.restoreGState()

    // 2. Neon Amber Outer Border
    ctx.saveGState()
    ctx.addPath(path)
    ctx.setLineWidth(size * 0.025)
    ctx.setStrokeColor(NSColor(red: 1.0, green: 0.42, blue: 0.0, alpha: 0.85).cgColor)
    ctx.strokePath()
    ctx.restoreGState()

    // 3. Central Glowing Emblem: Bell + Lightning Bolt / Tactical Alarm
    let centerX = size * 0.5
    let centerY = size * 0.52
    let scale = size / 512.0

    // Draw Bell Dome
    ctx.saveGState()
    let bellPath = CGMutablePath()
    
    // Top handle / loop
    let loopRect = CGRect(x: centerX - 14 * scale, y: centerY + 90 * scale, width: 28 * scale, height: 28 * scale)
    bellPath.addEllipse(in: loopRect)
    
    // Main Bell Body
    bellPath.move(to: CGPoint(x: centerX - 60 * scale, y: centerY - 40 * scale))
    bellPath.addCurve(to: CGPoint(x: centerX - 30 * scale, y: centerY + 80 * scale),
                      control1: CGPoint(x: centerX - 55 * scale, y: centerY + 20 * scale),
                      control2: CGPoint(x: centerX - 40 * scale, y: centerY + 60 * scale))
    bellPath.addLine(to: CGPoint(x: centerX + 30 * scale, y: centerY + 80 * scale))
    bellPath.addCurve(to: CGPoint(x: centerX + 60 * scale, y: centerY - 40 * scale),
                      control1: CGPoint(x: centerX + 40 * scale, y: centerY + 60 * scale),
                      control2: CGPoint(x: centerX + 55 * scale, y: centerY + 20 * scale))
    
    // Bell lip
    bellPath.addCurve(to: CGPoint(x: centerX + 85 * scale, y: centerY - 65 * scale),
                      control1: CGPoint(x: centerX + 70 * scale, y: centerY - 55 * scale),
                      control2: CGPoint(x: centerX + 80 * scale, y: centerY - 60 * scale))
    bellPath.addLine(to: CGPoint(x: centerX - 85 * scale, y: centerY - 65 * scale))
    bellPath.addCurve(to: CGPoint(x: centerX - 60 * scale, y: centerY - 40 * scale),
                      control1: CGPoint(x: centerX - 80 * scale, y: centerY - 60 * scale),
                      control2: CGPoint(x: centerX - 70 * scale, y: centerY - 55 * scale))
    bellPath.closeSubpath()
    
    // Bell Clapper
    let clapperRect = CGRect(x: centerX - 20 * scale, y: centerY - 82 * scale, width: 40 * scale, height: 22 * scale)
    bellPath.addEllipse(in: clapperRect)

    // Bell Gradient Fill (Amber/Gold metallic #FFA500 to #FF4500)
    ctx.addPath(bellPath)
    ctx.clip()
    let bellColors = [
        NSColor(red: 1.0, green: 0.72, blue: 0.15, alpha: 1.0).cgColor,
        NSColor(red: 1.0, green: 0.35, blue: 0.05, alpha: 1.0).cgColor,
        NSColor(red: 0.85, green: 0.18, blue: 0.05, alpha: 1.0).cgColor
    ] as CFArray
    let bellLocations: [CGFloat] = [0.0, 0.5, 1.0]
    if let bellGrad = CGGradient(colorsSpace: colorSpace, colors: bellColors, locations: bellLocations) {
        ctx.drawLinearGradient(bellGrad, start: CGPoint(x: centerX, y: centerY + 110 * scale), end: CGPoint(x: centerX, y: centerY - 90 * scale), options: [])
    }
    ctx.restoreGState()

    // 4. Central Cutout Lightning Bolt (Tactical Energy)
    ctx.saveGState()
    let boltPath = CGMutablePath()
    boltPath.move(to: CGPoint(x: centerX + 4 * scale, y: centerY + 50 * scale))
    boltPath.addLine(to: CGPoint(x: centerX - 24 * scale, y: centerY + 2 * scale))
    boltPath.addLine(to: CGPoint(x: centerX - 2 * scale, y: centerY + 2 * scale))
    boltPath.addLine(to: CGPoint(x: centerX - 10 * scale, y: centerY - 45 * scale))
    boltPath.addLine(to: CGPoint(x: centerX + 26 * scale, y: centerY - 2 * scale))
    boltPath.addLine(to: CGPoint(x: centerX + 4 * scale, y: centerY - 2 * scale))
    boltPath.closeSubpath()

    ctx.addPath(boltPath)
    ctx.setFillColor(NSColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    img.unlockFocus()
    return img
}

let fm = FileManager.default
let currentDir = fm.currentDirectoryPath
let iconsetDir = (currentDir as NSString).appendingPathComponent("AppIcon.iconset")
let resourcesDir = (currentDir as NSString).appendingPathComponent("Resources")

try? fm.removeItem(atPath: iconsetDir)
try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true, attributes: nil)
try? fm.createDirectory(atPath: resourcesDir, withIntermediateDirectories: true, attributes: nil)

let sizes: [(String, CGFloat)] = [
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

print("🎨 Generating AppIcon png assets...")
for (name, size) in sizes {
    let img = renderIcon(size: size)
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let dest = (iconsetDir as NSString).appendingPathComponent(name)
        try? png.write(to: URL(fileURLWithPath: dest))
    }
}

print("🔨 Compiling AppIcon.icns via iconutil...")
let icnsDest = (resourcesDir as NSString).appendingPathComponent("AppIcon.icns")
let task = Process()
task.launchPath = "/usr/bin/iconutil"
task.arguments = ["-c", "icns", iconsetDir, "-o", icnsDest]
task.launch()
task.waitUntilExit()

if task.terminationStatus == 0 {
    print("✅ Successfully generated AppIcon.icns at Resources/AppIcon.icns")
    try? fm.removeItem(atPath: iconsetDir)
} else {
    print("❌ iconutil failed with code \(task.terminationStatus)")
    exit(task.terminationStatus)
}
