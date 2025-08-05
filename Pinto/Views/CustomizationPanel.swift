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
            case .appearance: return "sparkles"
            case .gradient: return "paintpalette"
            case .advanced: return "gearshape.2"
            }
        }
        
        var subtitle: String {
            switch self {
            case .appearance: return "Transparency & borders"
            case .gradient: return "Themes & directions"
            case .advanced: return "Import & export"
            }
        }
    }
    
    init(profile: Binding<TerminalProfile>, profileManager: ProfileManager) {
        self._profile = profile
        self.profileManager = profileManager
        self._tempProfile = State(initialValue: profile.wrappedValue)
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                sidebarView
                mainContentView
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .background(.ultraThinMaterial)
        .onAppear {
            setupInitialState()
        }
    }
    
    private var sidebarView: some View {
        VStack(spacing: 0) {
            sidebarHeader
            navigationTabs
            Spacer()
            actionButtons
        }
        .frame(width: 280)
        .background(.ultraThinMaterial)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(width: 1)
        }
    }
    
    private var sidebarHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                profileEmojiView
                profileNameView
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            
            Divider()
                .opacity(0.3)
        }
    }
    
    private var profileEmojiView: some View {
        Button {
            // Quick emoji picker or focus on appearance section
            selectedTab = .appearance
        } label: {
            Text(tempProfile.emoji)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(emojiBackground)
        }
        .buttonStyle(.plain)
        .help("Click to change emoji")
    }
    
    private var emojiBackground: some View {
        Circle()
            .fill(.white.opacity(0.1))
            .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 1)
                    .scaleEffect(1.2)
                    .opacity(0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: tempProfile.emoji)
            )
    }
    
    private var profileNameView: some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField("Profile Name", text: $tempProfile.name)
                .font(.headline)
                .fontWeight(.semibold)
                .textFieldStyle(.plain)
                .foregroundColor(.primary)
                .onSubmit {
                    // Optional: Auto-save or validation
                }
            
            Text("Click name to edit • \(tempProfile.gradientTheme.colors.count) colors")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var navigationTabs: some View {
        VStack(spacing: 4) {
            ForEach(CustomizationTab.allCases) { tab in
                NavigationTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("Save Changes") {
                profile = tempProfile
                profileManager.updateProfile(tempProfile)
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            previewHeaderView
            
            Divider()
                .opacity(0.3)
            
            contentScrollView
        }
        .frame(maxWidth: .infinity)
    }
    
    private var previewHeaderView: some View {
        expandedPreviewHeader
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
    }
    
    private var contentScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                contentForTab(selectedTab)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 32)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
    }
    
    private func setupInitialState() {
        if let presetName = GradientTheme.presets.first(where: { $0.value == tempProfile.gradientTheme })?.key {
            selectedGradientPreset = presetName
        }
    }
    
    
    private var expandedPreviewHeader: some View {
        VStack(spacing: 16) {
            expandedPreviewTitleRow
            fullPreviewWindow
        }
    }
    
    private var expandedPreviewTitleRow: some View {
        HStack {
            Text("Live Preview")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("Updates in real-time")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var fullPreviewWindow: some View {
        VStack(spacing: 0) {
            expandedTitleBar
            expandedTerminalContent
        }
        .frame(height: 116)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 0.5)
        )
        .opacity(tempProfile.windowOpacity)
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }
    
    private var expandedTitleBar: some View {
        HStack(spacing: 8) {
            expandedTrafficLights
            Spacer()
            expandedTitleText
            Spacer()
            expandedControlButtons
        }
        .padding(.vertical, 8)
        .background(expandedTitleBackground)
    }
    
    private var expandedTrafficLights: some View {
        HStack(spacing: 6) {
            Circle().fill(.red.opacity(0.9)).frame(width: 12, height: 12)
            Circle().fill(.yellow.opacity(0.9)).frame(width: 12, height: 12)
            Circle().fill(.green.opacity(0.9)).frame(width: 12, height: 12)
        }
        .padding(.leading, 12)
    }
    
    private var expandedTitleText: some View {
        HStack(spacing: 8) {
            Text(tempProfile.emoji)
                .font(.title3)
            Text(tempProfile.name.isEmpty ? "Terminal" : tempProfile.name)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundColor(.primary.opacity(0.9))
    }
    
    private var expandedControlButtons: some View {
        HStack(spacing: 8) {
            Circle().fill(.white.opacity(0.15)).frame(width: 20, height: 20)
                .overlay(
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.primary.opacity(0.6))
                )
            Circle().fill(.white.opacity(0.15)).frame(width: 20, height: 20)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.primary.opacity(0.6))
                )
        }
        .padding(.trailing, 12)
    }
    
    private var expandedTitleBackground: some View {
        ZStack {
            if tempProfile.gradientTheme.direction == .radial {
                tempProfile.gradientTheme.radialGradient
            } else {
                tempProfile.gradientTheme.linearGradient
            }
            Color.clear.background(.ultraThinMaterial)
        }
    }
    
    private var expandedTerminalContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("user@terminal ~ % echo 'Hello \(tempProfile.name.isEmpty ? "World" : tempProfile.name)'")
            Text("Hello \(tempProfile.name.isEmpty ? "World" : tempProfile.name)")
                .foregroundStyle(.green.opacity(0.9))
            HStack(spacing: 0) {
                Text("user@terminal ~ % ")
                Rectangle()
                    .fill(.primary.opacity(0.9))
                    .frame(width: 8, height: 12)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: tempProfile.name)
            }
        }
        .font(.system(size: 11, design: .monospaced))
        .foregroundStyle(.primary.opacity(0.9))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .frame(height: 80)
        .background(.ultraThinMaterial)
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
        VStack(spacing: 32) {
            colorThemesCard
            directionControlCard
            intensityControlCard
        }
    }
    
    private var colorThemesCard: some View {
        ModernCard(
            title: "Color Themes",
            subtitle: "Choose from curated gradient presets",
            icon: "paintpalette.fill"
        ) {
            colorThemesGrid
        }
    }
    
    private var colorThemesGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
            ForEach(Array(GradientTheme.presets.keys.sorted()), id: \.self) { presetName in
                ColorThemeButton(
                    presetName: presetName,
                    preset: GradientTheme.presets[presetName]!,
                    isSelected: selectedGradientPreset == presetName,
                    action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            tempProfile.gradientTheme = GradientTheme.presets[presetName]!
                            selectedGradientPreset = presetName
                        }
                    }
                )
            }
        }
    }
    
    private var directionControlCard: some View {
        ModernCard(
            title: "Direction",
            subtitle: "Control gradient flow direction",
            icon: "arrow.triangle.swap"
        ) {
            directionButtons
        }
    }
    
    private var directionButtons: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ForEach(GradientDirection.allCases, id: \.self) { direction in
                    DirectionButton(
                        direction: direction,
                        isSelected: tempProfile.gradientTheme.direction == direction,
                        gradientTheme: tempProfile.gradientTheme,
                        action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                tempProfile.gradientTheme.direction = direction
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var intensityControlCard: some View {
        ModernCard(
            title: "Intensity",
            subtitle: "Adjust gradient opacity and strength",
            icon: "dial.low"
        ) {
            intensityControl
        }
    }
    
    private var intensityControl: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Opacity")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(tempProfile.gradientTheme.intensity * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            
            CustomSlider(
                value: $tempProfile.gradientTheme.intensity,
                range: 0.1...1.0,
                step: 0.05,
                gradient: tempProfile.gradientTheme.linearGradient
            )
        }
    }
    
    private var appearanceSection: some View {
        VStack(spacing: 32) {
            // Profile Identity - Most Important Section
            ModernCard(
                title: "Profile Identity",
                subtitle: "Name and emoji for your terminal profile",
                icon: "person.circle"
            ) {
                VStack(spacing: 24) {
                    // Large, prominent profile name field
                    VStack(spacing: 8) {
                        Text("Profile Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("Enter profile name", text: $tempProfile.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Enhanced emoji picker - full width and prominent
                    VStack(spacing: 8) {
                        Text("Profile Icon")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        EnhancedEmojiPicker(selectedEmoji: $tempProfile.emoji)
                    }
                }
            }
            
            // Window Transparency with visual feedback
            ModernCard(
                title: "Transparency",
                subtitle: "Control window opacity for desktop blending",
                icon: "circle.dotted"
            ) {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Window Opacity")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            
                            Text("\(Int(tempProfile.windowOpacity * 100))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        
                        Spacer()
                        
                        // Visual opacity indicator
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .fill(tempProfile.gradientTheme.linearGradient)
                                .frame(width: 50, height: 50)
                                .opacity(tempProfile.windowOpacity)
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    
                    CustomSlider(
                        value: $tempProfile.windowOpacity,
                        range: 0.3...1.0,
                        step: 0.05,
                        gradient: LinearGradient(
                            colors: [.clear, .primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            }
            
            // Border Styling with live preview
            ModernCard(
                title: "Border Style",
                subtitle: "Customize window frame appearance",
                icon: "rectangle.dashed"
            ) {
                VStack(spacing: 24) {
                    // Border preview
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Live Preview")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            
                            RoundedRectangle(
                                cornerRadius: tempProfile.borderStyle.cornerRadius,
                                style: .continuous
                            )
                            .stroke(
                                tempProfile.gradientTheme.linearGradient,
                                lineWidth: max(tempProfile.borderStyle.width, 1)
                            )
                            .frame(width: 80, height: 50)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: tempProfile.borderStyle.cornerRadius,
                                    style: .continuous
                                )
                                .fill(.ultraThinMaterial)
                            )
                        }
                        
                        Spacer()
                    }
                    
                    // Border controls
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Border Width")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Text("\(tempProfile.borderStyle.width, specifier: "%.1f")px")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                            
                            CustomSlider(
                                value: $tempProfile.borderStyle.width,
                                range: 0.0...4.0,
                                step: 0.5,
                                gradient: LinearGradient(
                                    colors: [.clear, tempProfile.gradientTheme.swiftUIColors.first ?? .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Corner Radius")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(tempProfile.borderStyle.cornerRadius))px")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                            
                            CustomSlider(
                                value: $tempProfile.borderStyle.cornerRadius,
                                range: 0.0...20.0,
                                step: 1.0,
                                gradient: LinearGradient(
                                    colors: [.gray, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var advancedSection: some View {
        VStack(spacing: 32) {
            // Profile Management with enhanced actions
            ModernCard(
                title: "Profile Management",
                subtitle: "Import, export, and reset your profiles",
                icon: "folder.badge.gearshape"
            ) {
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        Button {
                            exportProfile()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Export")
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            importProfile()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Import")
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Divider()
                        .opacity(0.3)
                    
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            tempProfile = TerminalProfile()
                            selectedGradientPreset = nil
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .medium))
                            Text("Reset to Default")
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Profile Information with modern styling
            ModernCard(
                title: "Profile Information",
                subtitle: "Details about this terminal profile",
                icon: "info.circle"
            ) {
                VStack(spacing: 16) {
                    ProfileInfoRow(
                        title: "Created",
                        value: tempProfile.createdAt.formatted(date: .abbreviated, time: .shortened),
                        icon: "calendar.badge.plus"
                    )
                    
                    ProfileInfoRow(
                        title: "Last Used",
                        value: tempProfile.lastUsed.formatted(date: .abbreviated, time: .shortened),
                        icon: "clock.arrow.circlepath"
                    )
                    
                    ProfileInfoRow(
                        title: "Profile ID",
                        value: String(tempProfile.id.uuidString.prefix(8)).uppercased(),
                        icon: "number",
                        isMonospace: true
                    )
                    
                    ProfileInfoRow(
                        title: "Color Count",
                        value: "\(tempProfile.gradientTheme.colors.count) colors",
                        icon: "paintpalette"
                    )
                }
            }
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

// MARK: - Modern Components

struct NavigationTabButton: View {
    let tab: CustomizationPanel.CustomizationTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    Text(tab.subtitle)
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? .white.opacity(0.2) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? .white.opacity(0.3) : .clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct ModernCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let content: Content
    
    init(title: String, subtitle: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Content
            content
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let gradient: LinearGradient
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(height: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                
                // Track gradient fill
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(gradient)
                    .frame(
                        width: geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)),
                        height: 12
                    )
                
                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                    .offset(
                        x: geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) - 10
                    )
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { dragValue in
                        let percentage = max(0, min(1, dragValue.location.x / geometry.size.width))
                        let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * Double(percentage)
                        let steppedValue = round(newValue / step) * step
                        value = min(max(steppedValue, range.lowerBound), range.upperBound)
                    }
            )
        }
        .frame(height: 20)
    }
}

struct ProfileInfoRow: View {
    let title: String 
    let value: String
    let icon: String
    var isMonospace: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 16)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(isMonospace ? .system(.subheadline, design: .monospaced) : .subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.blue)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct ColorThemeButton: View {
    let presetName: String
    let preset: GradientTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(preset.linearGradient)
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white, lineWidth: 2)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(.black.opacity(0.3))
                                    .blur(radius: 4)
                                    .scaleEffect(1.2)
                            )
                    }
                }
                
                VStack(spacing: 4) {
                    Text(presetName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("\(preset.colors.count) colors")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .shadow(
            color: isSelected ? .white.opacity(0.3) : .black.opacity(0.1),
            radius: isSelected ? 12 : 6,
            x: 0,
            y: isSelected ? 6 : 3
        )
    }
}

struct DirectionButton: View {
    let direction: GradientDirection
    let isSelected: Bool
    let gradientTheme: GradientTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(directionGradient)
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: direction.systemImage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                
                Text(direction.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .opacity(isSelected ? 1.0 : 0.7)
    }
    
    private var directionGradient: AnyShapeStyle {
        if direction == .radial {
            return AnyShapeStyle(gradientTheme.radialGradient)
        } else {
            return AnyShapeStyle(LinearGradient(
                colors: gradientTheme.swiftUIColors,
                startPoint: direction.startPoint,
                endPoint: direction.endPoint
            ))
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