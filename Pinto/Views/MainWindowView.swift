import SwiftUI

// MARK: - Traffic Light Button Component
enum TrafficLightType {
    case close, minimize, zoom
    
    var color: Color {
        switch self {
        case .close: return .red
        case .minimize: return .yellow
        case .zoom: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .close: return "xmark"
        case .minimize: return "minus"
        case .zoom: return "plus"
        }
    }
}

struct TrafficLightButton: View {
    let type: TrafficLightType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(type.color)
                .frame(width: 12, height: 12)
        }
        .buttonStyle(.plain)
    }
}


struct MainWindowView: View {
    @StateObject private var profileManager = ProfileManager()
    @State private var showingCustomization = false
    @State private var showingProfileSelector = false
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
            
            VStack(spacing: 0) {
                // Custom title bar
                titleBar
                
                // Main terminal container
                terminalContainer
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear {
            dragOffset = .zero
            if let window = NSApp.keyWindow {
                window.isMovableByWindowBackground = true
            }
        }
        
        .overlay(
            Rectangle()
                .stroke(
                    profileManager.activeProfile.borderStyle.color.color,
                    lineWidth: profileManager.activeProfile.borderStyle.width
                )
                .allowsHitTesting(false)
        )
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    if dragOffset == .zero {
                        dragOffset = value.translation
                    }
                    if let window = NSApp.keyWindow {
                        let origin = window.frame.origin
                        let deltaX = value.translation.width - dragOffset.width
                        let deltaY = value.translation.height - dragOffset.height
                        let newOrigin = NSPoint(x: origin.x + deltaX, y: origin.y - deltaY)
                        window.setFrameOrigin(newOrigin)
                    }
                }
                .onEnded { _ in
                    dragOffset = .zero
                }
        )
        .sheet(isPresented: $showingCustomization) {
            CustomizationPanel(
                profile: $profileManager.activeProfile,
                profileManager: profileManager
            )
        }
        .sheet(isPresented: $showingProfileSelector) {
            ProfileSelector(profileManager: profileManager)
        }
    }
    
    private var backgroundGradient: some View {
        Group {
            if profileManager.activeProfile.gradientTheme.direction == .radial {
                profileManager.activeProfile.gradientTheme.radialGradient
            } else {
                profileManager.activeProfile.gradientTheme.linearGradient
            }
        }
        .opacity(profileManager.activeProfile.windowOpacity)
        .animation(.easeInOut(duration: 0.3), value: profileManager.activeProfile.gradientTheme)
    }
    
    private var titleBar: some View {
        HStack {
            // macOS traffic light buttons
            HStack(spacing: 8) {
                TrafficLightButton(type: .close) {
                    NSApp.keyWindow?.close()
                }
                
                TrafficLightButton(type: .minimize) {
                    NSApp.keyWindow?.miniaturize(nil)
                }
                
                TrafficLightButton(type: .zoom) {
                    NSApp.keyWindow?.zoom(nil)
                }
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Profile emoji and name (centered) - DRAGGABLE AREA
            HStack(spacing: 8) {
                Text(profileManager.activeProfile.emoji)
                    .font(.title2)
                    .scaleEffect(1.2)
                
                Text(profileManager.activeProfile.name)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .onTapGesture {
                showingProfileSelector = true
            }
            .help("Click to change terminal personality")
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard let window = NSApp.keyWindow else { return }
                        let currentLocation = window.frame.origin
                        let newLocation = NSPoint(
                            x: currentLocation.x + value.translation.width,
                            y: currentLocation.y - value.translation.height
                        )
                        window.setFrameOrigin(newLocation)
                    }
            )
            
            Spacer()
            
            // Control buttons (right side)
            HStack(spacing: 12) {
                Button(action: { showingCustomization = true }) {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Customize appearance")
                
                Button(action: { showingProfileSelector = true }) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Switch profile")
            }
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.primary.opacity(0.1)),
            alignment: .bottom
        )
    }
    
    private var terminalContainer: some View {
        TerminalWrapperView(profile: $profileManager.activeProfile)
    }
}

#Preview {
    MainWindowView()
        .frame(width: 800, height: 600)
}