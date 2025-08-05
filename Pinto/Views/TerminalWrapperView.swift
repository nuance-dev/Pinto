import SwiftUI

struct TerminalWrapperView: View {
    @Binding var profile: TerminalProfile
    @State private var isTerminalReady = false
    var initialDirectory: String?
    
    var body: some View {
        // Terminal embedding without overlay animations that might interfere
        TerminalEmbeddingView(
            profile: $profile,
            initialDirectory: initialDirectory
        )
        .background(.clear) // Let the gradient from MainWindowView show through
    }
}

#Preview {
    TerminalWrapperView(profile: .constant(TerminalProfile()))
        .frame(width: 600, height: 400)
}