# Pinto ‑ Terminal Blank-On-Focus-Loss Fix

## Problem statement

On macOS 15 (Sequoia) any `NSView` that is wrapped with `NSViewRepresentable` **and** touches
the responder chain during regular SwiftUI update cycles triggers a ViewBridge reset:

```
ViewBridge to RemoteViewService Terminated: Error Domain=com.apple.ViewBridge Code=18
```

When that happens SwiftUI tears the AppKit view down and recreates it from scratch – for
`SwiftTerm` that means the whole terminal buffer is **lost** and the window appears blank the
next time it receives focus.

## Root cause

Our old `updateNSView` implementation executed on _every_ SwiftUI refresh and performed two
heavy-weight operations:

1. `updateTheme()` – changed fonts, colours, layout.
2. Forced the window to `makeFirstResponder()` again.

Both operations force AppKit to re-layout the terminal view, which macOS 15 decided is
"unexpected" once the hosting view loses key status. Result: ViewBridge termination → blank
terminal.

## Minimal, stable strategy

* Configure the terminal **once** when it is first created.
* Never touch its responder chain again unless absolutely necessary.

```swift
func updateNSView(_ nsView: PintoTerminalView, context: Context) {
    if !nsView.isTerminalInitialized {
        nsView.setupTerminal(with: profile)
    }
    // No more work during routine SwiftUI refreshes.
}
```

The initial focus is still set **once** (via `DispatchQueue.main.async` after the view
appears) but we removed all subsequent focus juggling.

## Result

* No more ViewBridge terminations.
* Terminal contents survive app-switching, Mission Control, fast user switching, etc.

---

## Bonus – remove duplicate macOS title bar

`WindowGroup` now uses:

```swift
.windowStyle(.borderless)
```

which removes AppKit's default title bar entirely, leaving only the custom SwiftUI bar in
`MainWindowView`.

`windowBackgroundDragBehavior(.enabled)` keeps drag-to-move functionality.

---

*Last updated:* 2025-08-05
