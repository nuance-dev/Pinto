import SwiftUI
import Foundation

struct GradientTheme: Codable, Equatable {
    var colors: [CodableColor]
    var direction: GradientDirection
    var intensity: Double // 0.0 to 1.0
    
    init(colors: [Color], direction: GradientDirection = .diagonal, intensity: Double = 0.8) {
        self.colors = colors.map { CodableColor($0) }
        self.direction = direction
        self.intensity = intensity
    }
    
    var swiftUIColors: [Color] {
        colors.map { $0.color }
    }
    
    var linearGradient: LinearGradient {
        LinearGradient(
            colors: swiftUIColors.map { $0.opacity(intensity) },
            startPoint: direction.startPoint,
            endPoint: direction.endPoint
        )
    }
    
    var radialGradient: RadialGradient {
        RadialGradient(
            colors: swiftUIColors.map { $0.opacity(intensity) },
            center: .center,
            startRadius: 0,
            endRadius: 400
        )
    }
    
    static let `default` = GradientTheme(
        colors: [Color.blue, Color.purple, Color.pink],
        direction: .diagonal,
        intensity: 0.6
    )
    
    static let presets: [String: GradientTheme] = [
        "Ocean Breeze": GradientTheme(
            colors: [Color.blue, Color.cyan, Color.teal],
            direction: .vertical
        ),
        "Sunset Glow": GradientTheme(
            colors: [Color.orange, Color.red, Color.pink],
            direction: .diagonal
        ),
        "Forest Depth": GradientTheme(
            colors: [Color.green, Color.mint, Color.yellow],
            direction: .horizontal
        ),
        "Cosmic Purple": GradientTheme(
            colors: [Color.purple, Color.indigo, Color.blue],
            direction: .radial
        ),
        "Monochrome": GradientTheme(
            colors: [Color.black, Color.gray, Color.white],
            direction: .vertical,
            intensity: 0.3
        )
    ]
}

enum GradientDirection: String, Codable, CaseIterable {
    case horizontal
    case vertical
    case diagonal
    case radial
    
    var startPoint: UnitPoint {
        switch self {
        case .horizontal:
            return .leading
        case .vertical:
            return .top
        case .diagonal:
            return .topLeading
        case .radial:
            return .center
        }
    }
    
    var endPoint: UnitPoint {
        switch self {
        case .horizontal:
            return .trailing
        case .vertical:
            return .bottom
        case .diagonal:
            return .bottomTrailing
        case .radial:
            return .center
        }
    }
    
    var displayName: String {
        switch self {
        case .horizontal:
            return "Horizontal"
        case .vertical:
            return "Vertical"
        case .diagonal:
            return "Diagonal"
        case .radial:
            return "Radial"
        }
    }
}