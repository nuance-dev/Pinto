import SwiftUI

struct TerminalWrapperView: View {
    @Binding var profile: TerminalProfile
    @State private var isTerminalReady = false
    
    var body: some View {
        // Terminal embedding without overlay animations that might interfere
        TerminalEmbeddingView(profile: $profile)
            .background(.clear) // Let the gradient from MainWindowView show through
    }
}

#Preview {
    TerminalWrapperView(profile: .constant(TerminalProfile()))
        .frame(width: 600, height: 400)
}