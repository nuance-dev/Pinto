import SwiftTerm
import SwiftUI

struct ContentView: View {
    @FocusState private var isTerminalFocused: Bool
    @EnvironmentObject var appDelegate: NSAppDelegate

    var body: some View {
        MainWindowView()
            // Hide the implicit window toolbar that SwiftUI adds so we don't get two bars.
            .toolbarVisibility(.hidden, for: .windowToolbar)
            .toolbar(.hidden, for: .windowToolbar)
            .toolbarBackground(.hidden, for: .windowToolbar)
            .onAppear {
                // Set initial focus to terminal after a brief delay
                // Reason: Ensures view hierarchy is complete on macOS 15
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isTerminalFocused = true
                }
            }
            .ignoresSafeArea(.container, edges: .top)
    }
}

#Preview {
    ContentView()
}
