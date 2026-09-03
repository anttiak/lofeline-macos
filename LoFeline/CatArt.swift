import SwiftUI
import AppKit

enum Palette {
    static let surface = dynamic(
        light: NSColor(srgbRed: 0.957, green: 0.957, blue: 0.969, alpha: 1),   // #f4f4f7
        dark: NSColor(srgbRed: 0.157, green: 0.157, blue: 0.169, alpha: 1))    // #28282b
    static let text = dynamic(
        light: NSColor(srgbRed: 0.114, green: 0.114, blue: 0.122, alpha: 1),   // #1d1d1f
        dark: NSColor(srgbRed: 0.909, green: 0.909, blue: 0.918, alpha: 1))    // #e8e8ea
    static let secondary = dynamic(
        light: NSColor(srgbRed: 0.431, green: 0.431, blue: 0.451, alpha: 1),   // #6e6e73
        dark: NSColor(srgbRed: 0.557, green: 0.557, blue: 0.576, alpha: 1))    // #8e8e93
    static let accent = dynamic(
        light: NSColor(srgbRed: 0.0, green: 0.478, blue: 1.0, alpha: 1),       // #007aff
        dark: NSColor(srgbRed: 0.039, green: 0.518, blue: 1.0, alpha: 1))      // #0a84ff
    static let separator = dynamic(
        light: NSColor(white: 0, alpha: 0.12),
        dark: NSColor(white: 1, alpha: 0.13))
    static let hover = dynamic(
        light: NSColor(white: 0, alpha: 0.08),
        dark: NSColor(white: 1, alpha: 0.07))
    static let headphonesOff = Color(red: 0.431, green: 0.431, blue: 0.451)    // #6e6e73

    /// Builds a Color that resolves to `light` or `dark` based on the current appearance.
    private static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }
}

/// Pixel rectangles (x, y, width, height) on a 16x14 grid.
private enum CatPixels {
    nonisolated static let fur: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (3, 2, 2, 2), (11, 2, 2, 2),   // ears
        (3, 4, 10, 5),                  // upper body
        (4, 9, 8, 4),                   // lower body
    ]
    nonisolated static let face: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (5, 6, 1, 1), (10, 6, 1, 1),    // eyes
        (7, 7, 2, 1),                   // nose / mouth
    ]
    nonisolated static let headphones: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (3, 3, 10, 1),                  // band
        (1, 4, 2, 4), (13, 4, 2, 4),    // ear cups
    ]

    nonisolated static let gridWidth: CGFloat = 16
    nonisolated static let gridHeight: CGFloat = 14

    /// Bounding box of the drawn pixels, used to center the sprite.
    nonisolated static let contentBounds: CGRect = {
        let all = fur + face + headphones
        let minX = all.map { $0.0 }.min()!
        let minY = all.map { $0.1 }.min()!
        let maxX = all.map { $0.0 + $0.2 }.max()!
        let maxY = all.map { $0.1 + $0.3 }.max()!
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }()
}

/// Single-color cat silhouette with the eyes and nose cut out, used as the menu-bar glyph.
struct CatShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let unit = min(rect.width / CatPixels.gridWidth, rect.height / CatPixels.gridHeight)
        let ox = rect.width / 2 - CatPixels.contentBounds.midX * unit
        let oy = rect.height / 2 - CatPixels.contentBounds.midY * unit

        func pixel(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: ox + x * unit, y: oy + y * unit, width: w * unit, height: h * unit)
        }

        var path = Path()
        for p in CatPixels.fur { path.addRect(pixel(p.0, p.1, p.2, p.3)) }
        // Even-odd fill turns these overlapping face rects into transparent cutouts.
        for p in CatPixels.face { path.addRect(pixel(p.0, p.1, p.2, p.3)) }
        return path
    }
}

/// Template image of the cat for the menu-bar status item; macOS tints it for light/dark bars.
enum CatIcon {
    static let menuBar: NSImage = {
        let size = NSSize(width: 18, height: 16)
        let image = NSImage(size: size, flipped: true) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.addPath(CatShape().path(in: rect).cgPath)
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fillPath(using: .evenOdd)
            return true
        }
        image.isTemplate = true
        return image
    }()
}

/// Full-color cat for the popover header, also the play/pause button.
struct CatArtView: View {
    var playing: Bool

    var body: some View {
        Canvas { context, size in
            let unit = min(size.width / CatPixels.gridWidth, size.height / CatPixels.gridHeight)
            let ox = size.width / 2 - CatPixels.contentBounds.midX * unit
            let oy = size.height / 2 - CatPixels.contentBounds.midY * unit

            func fill(_ pixels: [(CGFloat, CGFloat, CGFloat, CGFloat)], _ color: Color) {
                var path = Path()
                for p in pixels {
                    path.addRect(CGRect(x: ox + p.0 * unit, y: oy + p.1 * unit,
                                        width: p.2 * unit, height: p.3 * unit))
                }
                context.fill(path, with: .color(color))
            }

            fill(CatPixels.headphones, playing ? Palette.accent : Palette.headphonesOff)
            fill(CatPixels.fur, Palette.text)
            fill(CatPixels.face, Palette.surface)
        }
    }
}
