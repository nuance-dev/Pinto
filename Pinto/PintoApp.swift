import SwiftUI
import Cocoa

@main
struct PintoApp: App {
    @NSApplicationDelegateAdaptor(NSAppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 400)
                .environmentObject(appDelegate)
        }
        // Hide the default macOS title/toolbar so only our custom SwiftUI bar remains.
        .windowStyle(.hiddenTitleBar)
        // Allow dragging the whole background because we removed the native titlebar.
        .windowBackgroundDragBehavior(.enabled)
        .handlesExternalEvents(matching: ["pinto"])
    }
}

class NSAppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var openedFolderPath: String?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register for services
        NSApp.servicesProvider = self
        
        // Handle command line arguments
        let arguments = CommandLine.arguments
        if arguments.count > 1 {
            let folderPath = arguments[1]
            if FileManager.default.fileExists(atPath: folderPath) {
                DispatchQueue.main.async {
                    self.openedFolderPath = folderPath
                }
            }
        }
    }
    
    func openFolder(at path: String) {
        if FileManager.default.fileExists(atPath: path) {
            openedFolderPath = path
        }
    }
    
    // Service method that will be called when "Open with Pinto" is selected
    @objc func openWithPinto(_ pboard: NSPasteboard, userData: String, error: NSErrorPointer) {
        guard let filenames = pboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? [String] else {
            return
        }
        
        for filename in filenames {
            var isDirectory: ObjCBool = false
            
            if FileManager.default.fileExists(atPath: filename, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    // Open folder in Pinto
                    DispatchQueue.main.async {
                        self.openedFolderPath = filename
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    break // Only open the first folder
                }
            }
        }
    }
}
