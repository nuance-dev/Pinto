import SwiftUI

struct CustomizationPanel: View {
    @Binding var profile: TerminalProfile
    @ObservedObject var profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempProfile: TerminalProfile
    @State private var selectedGradientPreset: String?
    @State private var selectedTab: CustomizationTab = .appearance
    
    enum CustomizationTab: String, CaseIterable, Identifiable {
        case appearance = "Appearance"
        case gradient = "Colors"
        case advanced = "Advanced"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .appearance: return "paintbrush.pointed"
            case .gradient: return "eyedropper.halffull"
            case .advanced: return "slider.horizontal.3"
            }
        }
    }
    
    init(profile: Binding<TerminalProfile>, profileManager: ProfileManager) {
        self._profile = profile
        self.profileManager = profileManager
        self._tempProfile = State(initialValue: profile.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with live preview
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // Tab selector
                tabSelector
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                
                // Content area
                ScrollView {
                    VStack(spacing: 24) {
                        contentForTab(selectedTab)
                    }
                    .padding(20)
                }
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            }
            .navigationTitle("Customize \(tempProfile.emoji) \(tempProfile.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        profile = tempProfile
                        profileManager.updateProfile(tempProfile)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
            }
        }
        .frame(minWidth: 580, minHeight: 640)
        .onAppear {
            // Auto-select matching gradient preset
            if let presetName = GradientTheme.presets.first(where: { $0.value == tempProfile.gradientTheme })?.key {
                selectedGradientPreset = presetName
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Live preview window mock-up
            VStack(spacing: 0) {
                // Title bar
                HStack(spacing: 8) {
                    // Traffic lights
                    HStack(spacing: 6) {
                        Circle().fill(.red.opacity(0.8)).frame(width: 12, height: 12)
                        Circle().fill(.yellow.opacity(0.8)).frame(width: 12, height: 12)
                        Circle().fill(.green.opacity(0.8)).frame(width: 12, height: 12)
                    }
                    .padding(.leading, 12)
                    
                    Spacer()
                    
                    // Profile info in title bar
                    HStack(spacing: 8) {
                        Text(tempProfile.emoji)
                            .font(.title3)
                        Text(tempProfile.name.isEmpty ? "Terminal" : tempProfile.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    // Control buttons
                    HStack(spacing: 8) {
                        Circle().fill(.secondary.opacity(0.3)).frame(width: 20, height: 20)
                        Circle().fill(.secondary.opacity(0.3)).frame(width: 20, height: 20)
                    }
                    .padding(.trailing, 12)
                }
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        if tempProfile.gradientTheme.direction == .radial {
                            tempProfile.gradientTheme.radialGradient
                        } else {
                            tempProfile.gradientTheme.linearGradient
                        }
                        
                        Color.clear.background(.ultraThinMaterial)
                    }
                )
                
                // Terminal content area
                VStack(alignment: .leading, spacing: 2) {
                    Text("user@terminal ~ % echo 'Hello \(tempProfile.name)'")
                    Text("Hello \(tempProfile.name)")
                        .foregroundStyle(.green)
                    HStack(spacing: 0) {
                        Text("user@terminal ~ % ")
                        Rectangle().fill(.primary).frame(width: 8, height: 12)
                    }
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .frame(height: 80)
                .background(.ultraThinMaterial)
            }
            .frame(height: 116)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.primary.opacity(0.2), lineWidth: 0.5)
            )
            .opacity(tempProfile.windowOpacity)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Profile name editor
            VStack(spacing: 8) {
                TextField("Profile Name", text: $tempProfile.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .submitLabel(.done)
                
                VStack(spacing: 8) {
                    Text("Profile Icon")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    EnhancedEmojiPicker(selectedEmoji: $tempProfile.emoji)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(CustomizationTab.allCases) { tab in
                Button(action: {
                    withAnimation(.smooth(duration: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14, weight: .medium))
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(selectedTab == tab ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    @ViewBuilder
    private func contentForTab(_ tab: CustomizationTab) -> some View {
        switch tab {
        case .appearance:
            appearanceSection
        case .gradient:
            gradientSection
        case .advanced:
            advancedSection
        }
    }
    
    
    private var gradientSection: some View {
        VStack(spacing: 24) {
            // Gradient presets in a more macOS style
            VStack(alignment: .leading, spacing: 12) {
                Text("Color Themes")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(Array(GradientTheme.presets.keys.sorted()), id: \.self) { presetName in
                        let preset = GradientTheme.presets[presetName]!
                        
                        Button(action: {
                            withAnimation(.smooth(duration: 0.4)) {
                                tempProfile.gradientTheme = preset
                                selectedGradientPreset = presetName
                            }
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(preset.linearGradient)
                                        .frame(height: 48)
                                    
                                    if selectedGradientPreset == presetName {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Color.accentColor, lineWidth: 3)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(6)
                                            .background(Circle().fill(Color.accentColor))
                                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                    }
                                }
                                
                                Text(presetName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(selectedGradientPreset == presetName ? Color.accentColor : .secondary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(selectedGradientPreset == presetName ? 1.05 : 1.0)
                        .shadow(color: selectedGradientPreset == presetName ? Color.accentColor.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Direction control
            VStack(alignment: .leading, spacing: 12) {
                Text("Direction")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Picker("Direction", selection: $tempProfile.gradientTheme.direction) {
                    ForEach(GradientDirection.allCases, id: \.self) { direction in
                        HStack(spacing: 8) {
                            Image(systemName: direction.systemImage)
                            Text(direction.displayName)
                        }
                        .tag(direction)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Intensity slider
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Intensity")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(Int(tempProfile.gradientTheme.intensity * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: Capsule())
                }
                
                Slider(value: $tempProfile.gradientTheme.intensity, in: 0.1...1.0, step: 0.05)
                    .tint(Color.accentColor)
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    private var appearanceSection: some View {
        VStack(spacing: 24) {
            // Window transparency
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Transparency")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(Int(tempProfile.windowOpacity * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: Capsule())
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "eyeglasses")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    
                    Slider(value: $tempProfile.windowOpacity, in: 0.3...1.0, step: 0.05)
                        .tint(Color.accentColor)
                    
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Border styling
            VStack(alignment: .leading, spacing: 16) {
                Text("Border")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Width")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 80, alignment: .leading)
                        
                        Slider(value: $tempProfile.borderStyle.width, in: 0.0...4.0, step: 0.5)
                            .tint(Color.accentColor)
                        
                        Text("\(tempProfile.borderStyle.width, specifier: "%.1f")")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Roundness")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 80, alignment: .leading)
                        
                        Slider(value: $tempProfile.borderStyle.cornerRadius, in: 0.0...20.0, step: 1.0)
                            .tint(Color.accentColor)
                        
                        Text("\(Int(tempProfile.borderStyle.cornerRadius))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    private var advancedSection: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Profile Management")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    Button("Export Profile") {
                        exportProfile()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    
                    Button("Import Profile") {
                        importProfile()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    
                    Spacer()
                    
                    Button("Reset to Default") {
                        withAnimation(.smooth(duration: 0.4)) {
                            tempProfile = TerminalProfile()
                            selectedGradientPreset = nil
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .foregroundStyle(.red)
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Profile info
            VStack(alignment: .leading, spacing: 12) {
                Text("Profile Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Created:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(tempProfile.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Last Used:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(tempProfile.lastUsed.formatted(date: .abbreviated, time: .shortened))
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Profile ID:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(tempProfile.id.uuidString.prefix(8).uppercased())
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                }
                .font(.subheadline)
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    private func exportProfile() {
        // Implementation for exporting profile
        if let data = profileManager.exportProfile(tempProfile) {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = "\(tempProfile.name).pintoprofile"
            panel.allowedContentTypes = [.json]
            
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    do {
                        try data.write(to: url)
                    } catch {
                        print("Export failed: \(error)")
                    }
                }
            }
        }
    }
    
    private func importProfile() {
        // Implementation for importing profile
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        
        panel.begin { response in
            if response == .OK, let url = panel.urls.first {
                do {
                    let data = try Data(contentsOf: url)
                    if profileManager.importProfile(from: data) {
                        // Success feedback
                    }
                } catch {
                    print("Import failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Enhanced Emoji Picker with better UX
struct EnhancedEmojiPicker: View {
    @Binding var selectedEmoji: String
    @State private var showingEmojiGrid = false
    @State private var searchText = ""
    
    private let emojiCategories: [EmojiCategory] = [
        EmojiCategory(name: "Tech", icon: "laptopcomputer", emojis: ["💻", "🖥️", "⌨️", "🖱️", "📱", "⌚", "🎧", "🔌", "💾", "🖨️"]),
        EmojiCategory(name: "People", icon: "person.2", emojis: ["🧙‍♂️", "🕵️", "👨‍💻", "👩‍💻", "🤖", "👾", "🥷", "🦸", "🧞", "🧚"]),
        EmojiCategory(name: "Animals", icon: "pawprint", emojis: ["🐱", "🐶", "🦊", "🐸", "🐵", "🦄", "🐲", "🦁", "🐯", "🐺"]),
        EmojiCategory(name: "Objects", icon: "cube", emojis: ["🚀", "⚡", "🔥", "✨", "💫", "⭐", "🌟", "🔮", "💎", "🎯"]),
        EmojiCategory(name: "Activities", icon: "gamecontroller", emojis: ["🎮", "🎲", "🎪", "🎨", "🎭", "🎵", "🎸", "🎹", "🎺", "🎻"])
    ]
    
    struct EmojiCategory {
        let name: String
        let icon: String
        let emojis: [String]
    }
    
    var filteredEmojis: [String] {
        let allEmojis = emojiCategories.flatMap { $0.emojis }
        return searchText.isEmpty ? allEmojis : allEmojis.filter { _ in true } // Simple filter for now
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Current emoji display with clear customization hint
            Button(action: { showingEmojiGrid.toggle() }) {
                HStack(spacing: 8) {
                    Text(selectedEmoji)
                        .font(.title2)
                    
                    VStack(spacing: 2) {
                        Text("Change")
                            .font(.caption2)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.primary.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help("Click to choose from hundreds of emojis")
            .popover(isPresented: $showingEmojiGrid) {
                VStack(spacing: 12) {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search emojis...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(emojiCategories, id: \.name) { category in
                                VStack(alignment: .leading, spacing: 8) {
                                    Label(category.name, systemImage: category.icon)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                                        ForEach(category.emojis, id: \.self) { emoji in
                                            Button(emoji) {
                                                selectedEmoji = emoji
                                                showingEmojiGrid = false
                                                searchText = ""
                                            }
                                            .font(.title3)
                                            .frame(width: 32, height: 32)
                                            .background(
                                                selectedEmoji == emoji ? Color.accentColor.opacity(0.3) : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 6)
                                            )
                                            .buttonStyle(.plain)
                                            .scaleEffect(selectedEmoji == emoji ? 1.1 : 1.0)
                                            .animation(.spring(duration: 0.2), value: selectedEmoji == emoji)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                    
                    // Quick access to recent/favorites
                    HStack {
                        Text("Recent")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                .padding(16)
                .frame(width: 320)
            }
            
            // Manual text input
            TextField("Or type custom emoji", text: $selectedEmoji)
                .textFieldStyle(.roundedBorder)
                .font(.body)
        }
    }
}

// MARK: - Extension for GradientDirection icons
extension GradientDirection {
    var systemImage: String {
        switch self {
        case .horizontal: return "arrow.left.and.right"
        case .vertical: return "arrow.up.and.down"
        case .diagonal: return "arrow.up.right"
        case .radial: return "circle.dotted"
        }
    }
}

#Preview {
    CustomizationPanel(
        profile: .constant(TerminalProfile()),
        profileManager: ProfileManager()
    )
    .preferredColorScheme(.dark)
}