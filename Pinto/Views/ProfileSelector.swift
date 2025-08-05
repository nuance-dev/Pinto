import SwiftUI

struct ProfileSelector: View {
    @ObservedObject var profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewProfileSheet = false
    @State private var newProfileName = ""
    @State private var newProfileEmoji = "💻"
    @State private var searchText = ""
    
    var filteredProfiles: [TerminalProfile] {
        if searchText.isEmpty {
            return profileManager.profiles.sorted { $0.lastUsed > $1.lastUsed }
        } else {
            return profileManager.profiles.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.lastUsed > $1.lastUsed }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 16) {
                        ForEach(filteredProfiles) { profile in
                            ModernProfileCard(
                                profile: profile,
                                isActive: profile.id == profileManager.activeProfile.id,
                                onSelect: {
                                    withAnimation(.smooth(duration: 0.4)) {
                                        profileManager.setActiveProfile(profile)
                                    }
                                    dismiss()
                                },
                                onDelete: {
                                    withAnimation(.smooth(duration: 0.4)) {
                                        profileManager.deleteProfile(profile)
                                    }
                                },
                                onDuplicate: {
                                    withAnimation(.smooth(duration: 0.3)) {
                                        profileManager.duplicateProfile(profile)
                                    }
                                }
                            )
                        }
                        
                        // Add new profile card
                        ModernAddProfileCard {
                            showingNewProfileSheet = true
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Choose Personality")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewProfileSheet = true }) {
                        Label("New", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
            }
        }
        .frame(width: 420, height: 360)
        .sheet(isPresented: $showingNewProfileSheet) {
            NewProfileSheet(
                name: $newProfileName,
                emoji: $newProfileEmoji,
                onCreate: { name, emoji in
                    let newProfile = TerminalProfile(name: name, emoji: emoji)
                    withAnimation(.smooth(duration: 0.4)) {
                        profileManager.addProfile(newProfile)
                        profileManager.setActiveProfile(newProfile)
                    }
                    showingNewProfileSheet = false
                    dismiss()
                },
                onCancel: {
                    showingNewProfileSheet = false
                    newProfileName = ""
                    newProfileEmoji = "💻"
                }
            )
        }
    }
}

struct ModernProfileCard: View {
    let profile: TerminalProfile
    let isActive: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Header with emoji and status
                HStack {
                    Text(profile.emoji)
                        .font(.system(size: 24, weight: .medium))
                    
                    Spacer()
                    
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                
                // Profile info
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Gradient preview bar
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(.linearGradient(
                        colors: profile.gradientTheme.swiftUIColors.map { $0.opacity(profile.gradientTheme.intensity) },
                        startPoint: profile.gradientTheme.direction.startPoint,
                        endPoint: profile.gradientTheme.direction.endPoint
                    ))
                    .frame(height: 3)
                    .opacity(profile.windowOpacity)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(
                                isActive ? Color.accentColor : .clear,
                                lineWidth: 2
                            )
                    )
            )
            .scaleEffect(isActive ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onSelect) {
                Label("Select", systemImage: "checkmark.circle")
            }
            
            Button(action: onDuplicate) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button("Delete", role: .destructive, action: onDelete)
        }
        .animation(.smooth(duration: 0.2), value: isActive)
    }
}

struct ModernAddProfileCard: View {
    let onCreate: () -> Void
    
    var body: some View {
        Button(action: onCreate) {
            VStack(spacing: 8) {
                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                
                Text("New")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                
                // Dashed line
                RoundedRectangle(cornerRadius: 2)
                    .stroke(
                        Color.accentColor.opacity(0.4),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
                    .frame(height: 1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(
                                Color.accentColor.opacity(0.3),
                                style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct NewProfileSheet: View {
    @Binding var name: String
    @Binding var emoji: String
    let onCreate: (String, String) -> Void
    let onCancel: () -> Void
    
    @FocusState private var isNameFieldFocused: Bool
    
    var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header with icon
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    VStack(spacing: 8) {
                        Text("New Personality")
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Text("Create a unique terminal experience")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Form fields
                VStack(spacing: 20) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        TextField("Developer Mode, Creative Flow...", text: $name)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .focused($isNameFieldFocused)
                            .onSubmit {
                                if isNameValid {
                                    onCreate(name, emoji)
                                }
                            }
                    }
                    
                    // Emoji picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        CompactEmojiPicker(selectedEmoji: $emoji)
                    }
                }
                
                Spacer()
                
                // Live preview
                VStack(spacing: 12) {
                    Text("Preview")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                    
                    HStack(spacing: 12) {
                        Text(emoji)
                            .font(.title)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name.isEmpty ? "Untitled Personality" : name)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Text("Ready to use")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(24)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(name.isEmpty ? "New Personality" : name, emoji)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(!isNameValid)
                }
            }
        }
        .frame(width: 480, height: 520)
        .onAppear {
            isNameFieldFocused = true
        }
    }
}

// Compact emoji picker for the sheet
struct CompactEmojiPicker: View {
    @Binding var selectedEmoji: String
    @State private var showingFullPicker = false
    
    private let quickEmojis = ["💻", "🚀", "⚡", "🎯", "🔥", "✨", "🧙‍♂️", "🤖", "🎨", "🔮"]
    
    var body: some View {
        HStack(spacing: 12) {
            // Current selection
            Button(action: { showingFullPicker = true }) {
                Text(selectedEmoji)
                    .font(.title)
                    .frame(width: 48, height: 48)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            
            // Quick selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickEmojis, id: \.self) { emoji in
                        Button(emoji) {
                            selectedEmoji = emoji
                        }
                        .font(.title2)
                        .frame(width: 36, height: 36)
                        .background(
                            selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .popover(isPresented: $showingFullPicker) {
            EnhancedEmojiPicker(selectedEmoji: $selectedEmoji)
        }
    }
}

#Preview {
    ProfileSelector(profileManager: ProfileManager())
}