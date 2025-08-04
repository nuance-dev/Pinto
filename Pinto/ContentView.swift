import SwiftUI
import SwiftTerm

struct ContentView: View {
    @FocusState private var isTerminalFocused: Bool
    
    var body: some View {
        MainWindowView()
            .onAppear {
                // Set initial focus to terminal after a brief delay
                // Reason: Ensures view hierarchy is complete on macOS 15
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isTerminalFocused = true
                }
            }
    }
}

#Preview {
    ContentView()
}
