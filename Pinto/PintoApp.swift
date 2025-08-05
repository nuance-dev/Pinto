import SwiftUI

@main
struct PintoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 400)
        }
        // Use hiddenTitleBar to remove the system titlebar so our custom SwiftUI chrome is the only bar rendered.
        // This still preserves standard window behaviours (traffic-light buttons, full-screen etc.) while hiding the duplicate toolbar.
        .windowStyle(.hiddenTitleBar)
        // Allow dragging anywhere in the background because there is no native titlebar area any more.
        .windowBackgroundDragBehavior(.enabled)

    }
}
