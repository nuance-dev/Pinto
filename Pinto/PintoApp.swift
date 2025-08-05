import SwiftUI

@main
struct PintoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 400)
        }
        // Hide the default macOS title/toolbar so only our custom SwiftUI bar remains.
        .windowStyle(.hiddenTitleBar)
        // Allow dragging the whole background because we removed the native titlebar.
        .windowBackgroundDragBehavior(.enabled)
    }
}
