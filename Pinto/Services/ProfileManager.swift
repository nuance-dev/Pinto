import SwiftUI
import Foundation

@MainActor
class ProfileManager: ObservableObject {
    @Published var profiles: [TerminalProfile] = []
    @Published var activeProfile: TerminalProfile
    
    private let userDefaults = UserDefaults.standard
    private let profilesKey = "PintoProfiles"
    private let activeProfileKey = "PintoActiveProfile"
    
    init() {
        // Initialize with default profile
        self.activeProfile = TerminalProfile()
        
        // Load saved profiles or use presets
        loadProfiles()
        
        // Set active profile from last session
        loadActiveProfile()
    }
    
    // MARK: - Profile Management
    
    func addProfile(_ profile: TerminalProfile) {
        profiles.append(profile)
        saveProfiles()
    }
    
    func updateProfile(_ profile: TerminalProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            saveProfiles()
        }
        
        // Update active profile if it matches
        if activeProfile.id == profile.id {
            activeProfile = profile
            saveActiveProfile()
        }
    }
    
    func deleteProfile(_ profile: TerminalProfile) {
        profiles.removeAll { $0.id == profile.id }
        saveProfiles()
        
        // If deleted profile was active, switch to first available
        if activeProfile.id == profile.id && !profiles.isEmpty {
            setActiveProfile(profiles[0])
        }
    }
    
    func setActiveProfile(_ profile: TerminalProfile) {
        var updatedProfile = profile
        updatedProfile.lastUsed = Date()
        
        activeProfile = updatedProfile
        
        // Update in profiles array
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = updatedProfile
        }
        
        saveActiveProfile()
        saveProfiles()
    }
    
    // MARK: - Persistence
    
    private func saveProfiles() {
        do {
            let data = try JSONEncoder().encode(profiles)
            userDefaults.set(data, forKey: profilesKey)
        } catch {
            print("Failed to save profiles: \(error)")
        }
    }
    
    private func loadProfiles() {
        guard let data = userDefaults.data(forKey: profilesKey) else {
            // First launch - load preset profiles
            profiles = TerminalProfile.presets
            saveProfiles()
            return
        }
        
        do {
            profiles = try JSONDecoder().decode([TerminalProfile].self, from: data)
        } catch {
            print("Failed to load profiles: \(error)")
            // Fallback to presets
            profiles = TerminalProfile.presets
            saveProfiles()
        }
    }
    
    private func saveActiveProfile() {
        do {
            let data = try JSONEncoder().encode(activeProfile)
            userDefaults.set(data, forKey: activeProfileKey)
        } catch {
            print("Failed to save active profile: \(error)")
        }
    }
    
    private func loadActiveProfile() {
        guard let data = userDefaults.data(forKey: activeProfileKey) else {
            // Use first profile as default
            if !profiles.isEmpty {
                activeProfile = profiles[0]
            }
            return
        }
        
        do {
            activeProfile = try JSONDecoder().decode(TerminalProfile.self, from: data)
        } catch {
            print("Failed to load active profile: \(error)")
            // Fallback to first profile
            if !profiles.isEmpty {
                activeProfile = profiles[0]
            }
        }
    }
    
    // MARK: - Import/Export
    
    func exportProfile(_ profile: TerminalProfile) -> Data? {
        do {
            return try JSONEncoder().encode(profile)
        } catch {
            print("Failed to export profile: \(error)")
            return nil
        }
    }
    
    func importProfile(from data: Data) -> Bool {
        do {
            let profile = try JSONDecoder().decode(TerminalProfile.self, from: data)
            addProfile(profile)
            return true
        } catch {
            print("Failed to import profile: \(error)")
            return false
        }
    }
    
    // MARK: - Utilities
    
    func duplicateProfile(_ profile: TerminalProfile) {
        var newProfile = profile
        newProfile.name += " Copy"
        newProfile.createdAt = Date()
        addProfile(newProfile)
    }
}