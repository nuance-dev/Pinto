import SwiftUI

struct TerminalWrapperView: View {
    @Binding var profile: TerminalProfile
    @State private var isTerminalReady = false
    
    var body: some View {
        ZStack {
            // Base background for terminal - more subtle, just enough to prevent pure black
            Color.primary.opacity(0.02)
            
            // Terminal embedding
            TerminalEmbeddingView(profile: $profile)
                .background(.clear) // Let the gradient from MainWindowView show through
                .onAppear {
                    // Small delay to indicate terminal is loading
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isTerminalReady = true
                        }
                    }
                }
            
            // Optional: Subtle loading indicator (only shows very briefly)
            if !isTerminalReady {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                    .scaleEffect(0.7)
                    .opacity(0.6)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: profile.gradientTheme)
    }
}

#Preview {
    TerminalWrapperView(profile: .constant(TerminalProfile()))
        .frame(width: 600, height: 400)
}