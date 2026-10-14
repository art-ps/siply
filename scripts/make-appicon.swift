#!/usr/bin/swift
// Рендерит design/siply-icon.svg в Siply/Assets.xcassets/AppIcon.appiconset.
// Запуск из корня репозитория: swift scripts/make-appicon.swift
import AppKit

let svgURL = URL(fileURLWithPath: "design/siply-icon.svg")
let outDir = URL(fileURLWithPath: "Siply/Assets.xcassets/AppIcon.appiconset")
guard let source = NSImage(contentsOf: svgURL) else { fatalError("не удалось открыть \(svgURL.path)") }
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

// (точка, масштаб) — стандартный набор macOS
let slots: [(Int, Int)] = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)]
var images: [[String: String]] = []

for (pt, scale) in slots {
    let px = pt * scale
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    // Шаблон Apple: сквиркл 824/1024 холста, вокруг прозрачные поля
    let side = CGFloat(px) * 824 / 1024, inset = (CGFloat(px) - side) / 2
    source.draw(in: NSRect(x: inset, y: inset, width: side, height: side), from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    let name = "icon_\(pt)x\(pt)\(scale == 2 ? "@2x" : "").png"
    try rep.representation(using: .png, properties: [:])!.write(to: outDir.appendingPathComponent(name))
    images.append(["idiom": "mac", "size": "\(pt)x\(pt)", "scale": "\(scale)x", "filename": name])
}

let contents: [String: Any] = ["images": images, "info": ["version": 1, "author": "xcode"]]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: outDir.appendingPathComponent("Contents.json"))
print("готово: \(images.count) изображений в \(outDir.path)")
