import SwiftUI

struct ProfileSelector: View {
    @ObservedObject var profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewProfileSheet = false
    @State private var newProfileName = ""
    @State private var newProfileEmoji = "💻"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 20) {
                    ForEach(profileManager.profiles) { profile in
                        ProfileCard(
                            profile: profile,
                            isActive: profile.id == profileManager.activeProfile.id,
                            onSelect: {
                                withAnimation(.smooth(duration: 0.3)) {
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
                    AddProfileCard {
                        showingNewProfileSheet = true
                    }
                }
                .padding(24)
            }
            .navigationTitle("Terminal Personalities")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewProfileSheet = true }) {
                        Label("New Profile", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
            }
        }
        .frame(minWidth: 640, minHeight: 520)
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

struct ProfileCard: View {
    let profile: TerminalProfile
    let isActive: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 14) {
            // Gradient preview with enhanced styling
            ZStack {
                if profile.gradientTheme.direction == .radial {
                    profile.gradientTheme.radialGradient
                } else {
                    profile.gradientTheme.linearGradient
                }
                
                // Emoji with subtle glow effect
                Text(profile.emoji)
                    .font(.system(size: 36, weight: .medium))
                    .scaleEffect(isActive ? 1.15 : 1.0)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
            }
            .frame(height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isActive ? Color.accentColor : (isHovered ? Color.primary.opacity(0.3) : Color.clear),
                        lineWidth: isActive ? 2.5 : 1.5
                    )
            )
            .shadow(
                color: isActive ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.1),
                radius: isActive ? 8 : 4,
                x: 0,
                y: isActive ? 4 : 2
            )
            
            // Profile info with improved typography
            VStack(spacing: 6) {
                Text(profile.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Text("Modified \(RelativeDateTimeFormatter().localizedString(for: profile.lastUsed, relativeTo: Date()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
            
            // Status indicator with improved design
            HStack {
                if isActive {
                    Label("ACTIVE", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.green.gradient, in: Capsule())
                } else {
                    Text("Available")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.regularMaterial, in: Capsule())
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.primary.opacity(isHovered ? 0.2 : 0.1), lineWidth: 1)
        )
        .scaleEffect(isActive ? 1.03 : (isHovered ? 1.01 : 1.0))
        .onHover { hovered in
            withAnimation(.smooth(duration: 0.2)) {
                isHovered = hovered
            }
        }
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            Button(action: onSelect) {
                Label("Select Profile", systemImage: "checkmark.circle")
            }
            
            Button(action: onDuplicate) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button("Delete", role: .destructive, action: onDelete)
        }
        .animation(.smooth(duration: 0.3), value: isActive)
        .animation(.smooth(duration: 0.2), value: isHovered)
    }
}

struct AddProfileCard: View {
    let onCreate: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 14) {
            // Plus icon area with enhanced styling
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                Color.accentColor.opacity(isHovered ? 0.6 : 0.3),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [10, 6])
                            )
                    )
                
                VStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                        .background(Circle().fill(Color.accentColor))
                    
                    Text("Add")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .frame(height: 88)
            
            // Enhanced labels
            VStack(spacing: 6) {
                Text("New Profile")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                
                Text("Create personality")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
            
            // Call to action
            Text("Tap to create")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Color.accentColor.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1), in: Capsule())
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.primary.opacity(isHovered ? 0.2 : 0.1), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovered in
            withAnimation(.smooth(duration: 0.2)) {
                isHovered = hovered
            }
        }
        .onTapGesture {
            onCreate()
        }
        .animation(.smooth(duration: 0.2), value: isHovered)
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
            VStack(spacing: 24) {
                // Header section
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(Color.accentColor)
                    
                    Text("Create New Terminal Personality")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("Give your terminal a unique personality with a custom name and emoji")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Form section
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Profile Name", systemImage: "textformat")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        TextField("Enter personality name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                            .focused($isNameFieldFocused)
                            .onSubmit {
                                if isNameValid {
                                    onCreate(name, emoji)
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Profile Emoji", systemImage: "face.smiling")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        EnhancedEmojiPicker(selectedEmoji: $emoji)
                    }
                }
                
                Spacer()
                
                // Preview section
                VStack(spacing: 8) {
                    Text("Preview")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        Text(emoji)
                            .font(.title2)
                        Text(name.isEmpty ? "New Terminal" : name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(24)
            .navigationTitle("New Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(name.isEmpty ? "New Terminal" : name, emoji)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(!isNameValid)
                }
            }
        }
        .frame(width: 440, height: 380)
        .onAppear {
            isNameFieldFocused = true
        }
    }
}

#Preview {
    ProfileSelector(profileManager: ProfileManager())
}