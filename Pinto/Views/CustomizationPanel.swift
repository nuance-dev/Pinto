import SwiftUI

struct CustomizationPanel: View {
    @Binding var profile: TerminalProfile
    @ObservedObject var profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempProfile: TerminalProfile
    @State private var selectedGradientPreset: String?
    @State private var expandedSections: Set<CustomizationSection> = [.basic, .gradient, .appearance]
    
    enum CustomizationSection: String, CaseIterable, Identifiable {
        case basic = "Basic Information"
        case gradient = "Gradient Theme"
        case appearance = "Appearance"
        case preview = "Preview"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .basic: return "info.circle"
            case .gradient: return "paintpalette"
            case .appearance: return "eyeglasses"
            case .preview: return "eye"
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
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Header with live preview
                    headerSection
                    
                    // Collapsible sections with progressive disclosure
                    ForEach(CustomizationSection.allCases) { section in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedSections.contains(section) },
                                set: { isExpanded in
                                    if isExpanded {
                                        expandedSections.insert(section)
                                    } else {
                                        expandedSections.remove(section)
                                    }
                                }
                            )
                        ) {
                            contentForSection(section)
                                .padding(.top, 12)
                        } label: {
                            Label(section.rawValue, systemImage: section.icon)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .tint(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.primary.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                .padding(20)
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
        .frame(minWidth: 520, minHeight: 600)
        .onAppear {
            // Auto-select matching gradient preset
            if let presetName = GradientTheme.presets.first(where: { $0.value == tempProfile.gradientTheme })?.key {
                selectedGradientPreset = presetName
            }
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Live preview thumbnail
            ZStack {
                if tempProfile.gradientTheme.direction == .radial {
                    tempProfile.gradientTheme.radialGradient
                } else {
                    tempProfile.gradientTheme.linearGradient
                }
                
                Text(tempProfile.emoji)
                    .font(.system(size: 28, weight: .medium))
                    .scaleEffect(1.1)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.primary.opacity(0.2), lineWidth: 1)
            )
            .opacity(tempProfile.windowOpacity)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tempProfile.name.isEmpty ? "Untitled Terminal" : tempProfile.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("Live Preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func contentForSection(_ section: CustomizationSection) -> some View {
        switch section {
        case .basic:
            basicInfoSection
        case .gradient:
            gradientSection
        case .appearance:
            appearanceSection
        case .preview:
            previewSection
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Name", systemImage: "textformat")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TextField("Enter terminal name", text: $tempProfile.name)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Emoji", systemImage: "face.smiling")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                EnhancedEmojiPicker(selectedEmoji: $tempProfile.emoji)
            }
        }
    }
    
    private var gradientSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Gradient presets with improved layout
            VStack(alignment: .leading, spacing: 8) {
                Label("Preset Themes", systemImage: "swatchpalette")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 12) {
                    ForEach(Array(GradientTheme.presets.keys.sorted()), id: \.self) { presetName in
                        let preset = GradientTheme.presets[presetName]!
                        
                        Button(action: {
                            withAnimation(.smooth(duration: 0.3)) {
                                tempProfile.gradientTheme = preset
                                selectedGradientPreset = presetName
                            }
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(preset.linearGradient)
                                        .frame(height: 44)
                                    
                                    if selectedGradientPreset == presetName {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.accentColor, lineWidth: 2.5)
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white)
                                            .background(Circle().fill(Color.accentColor))
                                            .font(.caption)
                                    }
                                }
                                
                                Text(presetName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(selectedGradientPreset == presetName ? .primary : .secondary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(selectedGradientPreset == presetName ? 1.02 : 1.0)
                        .animation(.smooth(duration: 0.2), value: selectedGradientPreset == presetName)
                    }
                }
            }
            
            Divider()
            
            // Direction and intensity controls
            VStack(alignment: .leading, spacing: 12) {
                Label("Gradient Direction", systemImage: "arrow.up.right")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Picker("Direction", selection: $tempProfile.gradientTheme.direction) {
                    ForEach(GradientDirection.allCases, id: \.self) { direction in
                        Label(direction.displayName, systemImage: direction.systemImage)
                            .tag(direction)
                    }
                }
                .pickerStyle(.segmented)
                .animation(.smooth(duration: 0.3), value: tempProfile.gradientTheme.direction)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Intensity", systemImage: "dial.low")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(tempProfile.gradientTheme.intensity * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.regularMaterial, in: Capsule())
                }
                
                Slider(value: $tempProfile.gradientTheme.intensity, in: 0.1...1.0, step: 0.05) {
                    Text("Intensity")
                } minimumValueLabel: {
                    Image(systemName: "dial.low")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } maximumValueLabel: {
                    Image(systemName: "dial.high")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .tint(Color.accentColor)
            }
        }
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Window opacity
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Window Opacity", systemImage: "opacity")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(tempProfile.windowOpacity * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.regularMaterial, in: Capsule())
                }
                
                Slider(value: $tempProfile.windowOpacity, in: 0.3...1.0, step: 0.05) {
                    Text("Opacity")
                } minimumValueLabel: {
                    Image(systemName: "opacity")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } maximumValueLabel: {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .tint(Color.accentColor)
            }
            
            Divider()
            
            // Border styling
            VStack(alignment: .leading, spacing: 12) {
                Label("Border Style", systemImage: "rectangle.dashed")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Width")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .leading)
                        
                        Slider(value: $tempProfile.borderStyle.width, in: 0.0...4.0, step: 0.5)
                            .tint(Color.accentColor)
                        
                        Text("\(tempProfile.borderStyle.width, specifier: "%.1f")px")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .frame(width: 35)
                    }
                    
                    HStack {
                        Text("Radius")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .leading)
                        
                        Slider(value: $tempProfile.borderStyle.cornerRadius, in: 0.0...20.0, step: 1.0)
                            .tint(Color.accentColor)
                        
                        Text("\(Int(tempProfile.borderStyle.cornerRadius))px")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .frame(width: 35)
                    }
                }
            }
        }
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Live Preview", systemImage: "eye")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            // Enhanced live preview
            ZStack {
                // Background gradient
                if tempProfile.gradientTheme.direction == .radial {
                    tempProfile.gradientTheme.radialGradient
                } else {
                    tempProfile.gradientTheme.linearGradient
                }
                
                VStack(spacing: 0) {
                    // Mock title bar with improved styling
                    HStack(spacing: 12) {
                        Text(tempProfile.emoji)
                            .font(.title3)
                        
                        Text(tempProfile.name.isEmpty ? "Terminal" : tempProfile.name)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        // Mock traffic lights
                        HStack(spacing: 6) {
                            Circle().fill(.red.opacity(0.8)).frame(width: 12, height: 12)
                            Circle().fill(.yellow.opacity(0.8)).frame(width: 12, height: 12)
                            Circle().fill(.green.opacity(0.8)).frame(width: 12, height: 12)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    
                    // Mock terminal content with better realism
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Last login: \(Date().formatted(date: .abbreviated, time: .shortened))")
                            .foregroundStyle(.secondary)
                        Text("user@\(tempProfile.name.lowercased().replacingOccurrences(of: " ", with: "-")) ~ % echo 'Welcome to \(tempProfile.name)'")
                        Text("Welcome to \(tempProfile.name)")
                            .foregroundStyle(.green)
                        HStack(spacing: 0) {
                            Text("user@\(tempProfile.name.lowercased().replacingOccurrences(of: " ", with: "-")) ~ % ")
                            Rectangle()
                                .fill(.primary)
                                .frame(width: 8, height: 14)
                                .opacity(0.8)
                        }
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.ultraThinMaterial)
                    
                    Spacer(minLength: 0)
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: tempProfile.borderStyle.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: tempProfile.borderStyle.cornerRadius)
                    .stroke(
                        tempProfile.borderStyle.color.color,
                        lineWidth: tempProfile.borderStyle.width
                    )
            )
            .opacity(tempProfile.windowOpacity)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .animation(.smooth(duration: 0.3), value: tempProfile.gradientTheme)
            .animation(.smooth(duration: 0.3), value: tempProfile.windowOpacity)
            .animation(.smooth(duration: 0.3), value: tempProfile.borderStyle.cornerRadius)
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
            // Current emoji display
            Button(action: { showingEmojiGrid.toggle() }) {
                Text(selectedEmoji)
                    .font(.title2)
                    .frame(width: 44, height: 36)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.primary.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help("Click to choose emoji")
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