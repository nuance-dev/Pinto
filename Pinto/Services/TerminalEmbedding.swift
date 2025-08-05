import AppKit
import SwiftTerm
import SwiftUI

struct TerminalEmbeddingView: NSViewRepresentable {
    @Binding var profile: TerminalProfile

    func makeNSView(context: Context) -> PintoTerminalView {
        let terminalView = PintoTerminalView()

        // Request focus after view is in window hierarchy
        // Reason: macOS 15 requires delayed focus for NSViewRepresentable
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = terminalView.window {
                window.makeFirstResponder(terminalView)
            }
        }

        return terminalView
    }

    func updateNSView(_ nsView: PintoTerminalView, context: Context) {
        // Configure terminal only once. Re-applying theme or forcing layout
        // every time SwiftUI refreshes the view is what still triggers
        // ViewBridge resets on macOS 15. We therefore opt-in to *immutable*
        // configuration — if users explicitly change the profile we can add
        // invalidation logic later, but day-to-day focus changes will no
        // longer cause any work on the AppKit side.
        if !nsView.isTerminalInitialized {
            nsView.setupTerminal(with: profile)
        }
        // intentionally do **not** run updateTheme on every refresh
    }
}

// MARK: - PintoTerminalView using SwiftTerm
class PintoTerminalView: NSView, LocalProcessTerminalViewDelegate {
    private(set) var terminalView: LocalProcessTerminalView!
    private(set) var isTerminalInitialized = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        // Set a light background color to prevent black screen
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Setup when view is added to window hierarchy
        guard window != nil, !isTerminalInitialized else { return }

        // Initialize terminal immediately with synchronous setup
        if let profile = getCurrentProfile() {
            setupTerminal(with: profile)
        }

        // Delayed focus setup to ensure view hierarchy is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self,
                let window = self.window,
                let terminal = self.terminalView
            else { return }

            // Rely on the existing key window without re-activating the app each time.
            // Forcing key status repeatedly can lead to ViewBridge resets on macOS 15.
            window.makeFirstResponder(terminal)
        }
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        // Pass first responder to terminal view if available
        if let terminalView = terminalView {
            // Use window's makeFirstResponder for reliability on macOS 15
            // Reason: Direct becomeFirstResponder calls can fail
            if let window = window {
                return window.makeFirstResponder(terminalView)
            }
            return terminalView.becomeFirstResponder()
        }
        return super.becomeFirstResponder()
    }

    private func getCurrentProfile() -> TerminalProfile? {
        // Helper method to get current profile if available
        return TerminalProfile()  // Default profile for now
    }

    func setupTerminal(with profile: TerminalProfile) {
        // Prevent double initialization
        guard !isTerminalInitialized else { return }

        // Create the SwiftTerm LocalProcessTerminalView
        terminalView = LocalProcessTerminalView(frame: bounds)

        // Set ourselves as the process delegate
        terminalView.processDelegate = self

        // Configure terminal appearance first
        updateTheme(with: profile)

        // Add to view hierarchy
        addSubview(terminalView)
        terminalView.translatesAutoresizingMaskIntoConstraints = false

        // Add padding around the terminal for better visual spacing
        let padding: CGFloat = 16.0
        NSLayoutConstraint.activate([
            terminalView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            terminalView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            terminalView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            terminalView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
        ])

        // Ensure the terminal view resizes with its container
        terminalView.autoresizingMask = [.width, .height]

        // Set initial focus without async to avoid race conditions
        // Reason: Synchronous focus setup prevents macOS 15 timing issues
        if let window = window {
            window.makeFirstResponder(terminalView)
        }

        // Mark as initialized before starting process
        isTerminalInitialized = true

        // Start shell process immediately - view is already initialized
        // Reason: Removing async prevents race conditions on macOS 15
        startShellProcess()
    }

    private func startShellProcess() {
        guard let terminalView = terminalView else {
            print("Error: Terminal view not initialized")
            return
        }

        // Get the user's default shell with robust fallback
        let shell = getDefaultShell()
        let shellName = NSString(string: shell).lastPathComponent
        let shellIdiom = "-\(shellName)"  // Login shell format

        // Set the working directory to user's home
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        FileManager.default.changeCurrentDirectoryPath(homeDirectory)

        // Feed welcome message to make terminal visible immediately
        terminalView.feed(text: "Welcome to \(shellName) in Pinto!\r\n")

        // Start the shell process with login arguments
        terminalView.startProcess(
            executable: shell,
            args: ["-l"],  // Login shell
            environment: getEnvironmentArray(),
            execName: shellIdiom
        )
        print("Started shell process: \(shell)")
    }

    private func getDefaultShell() -> String {
        // Try to get shell from environment
        if let shell = ProcessInfo.processInfo.environment["SHELL"],
            FileManager.default.fileExists(atPath: shell)
        {
            return shell
        }

        // Try common shell locations in order of preference
        let shellCandidates = [
            "/bin/zsh",  // macOS default since Catalina
            "/bin/bash",  // Traditional macOS/Linux default
            "/usr/bin/zsh",  // Alternative zsh location
            "/usr/bin/bash",  // Alternative bash location
            "/bin/sh",  // POSIX shell fallback
        ]

        for shell in shellCandidates {
            if FileManager.default.fileExists(atPath: shell) {
                return shell
            }
        }

        // Last resort
        return "/bin/sh"
    }

    private func getEnvironmentArray() -> [String] {
        var env = ProcessInfo.processInfo.environment

        // Ensure essential environment variables are set
        if env["HOME"] == nil {
            env["HOME"] = FileManager.default.homeDirectoryForCurrentUser.path
        }

        if env["USER"] == nil {
            env["USER"] = NSUserName()
        }

        if env["PATH"] == nil {
            env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        }

        // Add terminal identification
        env["TERM"] = "xterm-256color"
        env["PINTO_TERMINAL"] = "1"

        // Convert dictionary to array of "KEY=VALUE" strings
        return env.map { "\($0.key)=\($0.value)" }
    }

    func updateTheme(with profile: TerminalProfile) {
        guard let terminalView = terminalView else { return }

        // Apply terminal styling
        terminalView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)

        // Configure native colors for better visibility
        terminalView.configureNativeColors()

        // Let system handle cursor to respect accessibility preferences
        // Reason: macOS 15 Sequoia cursor preferences conflict with manual styling

        // Configure selection colors
        terminalView.selectedTextBackgroundColor = NSColor.selectedContentBackgroundColor

        // Request display update
        terminalView.needsDisplay = true

        // Focus will be handled by window's makeFirstResponder
        // Reason: Direct becomeFirstResponder calls fail on macOS 15

        // The gradient background from our wrapper will show through
        // Reason: This creates a unified visual experience with the app's theming
    }

    // MARK: - LocalProcessTerminalViewDelegate

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        // Handle process termination with user feedback
        let exitStatus = exitCode ?? -1
        print("Terminal process terminated with exit code: \(exitStatus)")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if exitStatus == 0 {
                // Normal exit
                self.terminalView?.feed(text: "\r\n[Process completed successfully]\r\n")
            } else {
                // Error exit
                self.terminalView?.feed(text: "\r\n[Process exited with code \(exitStatus)]\r\n")
            }

            // Optionally restart the shell for continuous usage
            self.terminalView?.feed(text: "Type 'exit' to close or press Cmd+R to restart\r\n")
        }
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        // Handle directory changes for enhanced UI feedback
        if let directory = directory {
            print("Working directory changed to: \(directory)")
        }
    }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
        // This delegate method is called frequently during resizing.
        // We only need to ensure the view is redrawn.
        DispatchQueue.main.async { [weak self] in
            self?.needsDisplay = true
        }
    }

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        // Handle terminal title changes and propagate to window if needed
        print("Terminal title set to: \(title)")

        // Future enhancement: Could update the Pinto window title based on terminal title
        DispatchQueue.main.async {
            // Could implement title propagation to parent window
        }
    }
}
