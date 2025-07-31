import SwiftUI

@main
struct PintoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 400)
        }
        .windowStyle(.plain)
        .windowBackgroundDragBehavior(.enabled)
        
    }
}