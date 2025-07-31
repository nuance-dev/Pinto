import SwiftUI
import Foundation
import AppKit

struct TerminalProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var emoji: String
    var gradientTheme: GradientTheme
    var windowOpacity: Double
    var borderStyle: BorderStyle
    var createdAt: Date
    var lastUsed: Date
    
    init(
        id: UUID = UUID(),
        name: String = "Terminal",
        emoji: String = "💻",
        gradientTheme: GradientTheme = .default,
        windowOpacity: Double = 0.95,
        borderStyle: BorderStyle = .subtle
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.gradientTheme = gradientTheme
        self.windowOpacity = windowOpacity
        self.borderStyle = borderStyle
        self.createdAt = Date()
        self.lastUsed = Date()
    }
    
    // Preset profiles for quick setup
    static let presets: [TerminalProfile] = [
        TerminalProfile(
            name: "Code Wizard",
            emoji: "🧙‍♂️",
            gradientTheme: GradientTheme(
                colors: [Color.purple, Color.blue, Color.cyan],
                direction: .diagonal
            )
        ),
        TerminalProfile(
            name: "Debug Detective",
            emoji: "🕵️",
            gradientTheme: GradientTheme(
                colors: [Color.red, Color.orange, Color.yellow],
                direction: .vertical
            )
        ),
        TerminalProfile(
            name: "Deploy Captain",
            emoji: "🚀",
            gradientTheme: GradientTheme(
                colors: [Color.green, Color.mint, Color.teal],
                direction: .radial
            )
        ),
        TerminalProfile(
            name: "AI Assistant",
            emoji: "🤖",
            gradientTheme: GradientTheme(
                colors: [Color.indigo, Color.purple, Color.pink],
                direction: .diagonal
            )
        )
    ]
}

struct BorderStyle: Codable, Equatable {
    var width: Double
    var color: CodableColor
    var cornerRadius: Double
    
    static let subtle = BorderStyle(
        width: 1.0,
        color: CodableColor(Color.primary.opacity(0.1)),
        cornerRadius: 12.0
    )
    
    static let bold = BorderStyle(
        width: 2.0,
        color: CodableColor(Color.accentColor),
        cornerRadius: 8.0
    )
}

// Helper for encoding/decoding Colors
struct CodableColor: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    init(_ color: Color) {
        // Extract RGBA components from Color using NSColor for macOS
        let nsColor = NSColor(color)
        
        // Convert to a compatible colorspace first to avoid catalog color issues
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            // Fallback to a safe default if conversion fails
            self.red = 0.0
            self.green = 0.0
            self.blue = 1.0
            self.alpha = 1.0
            return
        }
        
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}