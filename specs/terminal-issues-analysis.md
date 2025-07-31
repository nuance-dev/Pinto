# Terminal Issues Analysis - macOS 15 Sequoia & SwiftTerm

## Overview
This document analyzes the reported terminal issues in Pinto (a SwiftTerm-based macOS terminal wrapper) on macOS 15 Sequoia, including weird cursor blinking, input not working, non-responsive window controls, and content disappearing.

## Reported Issues

### 1. Weird Type Blinking Cursor ⚠️
**Symptoms**: Non-standard cursor blinking behavior, not matching terminal defaults
**Potential Causes**:
- macOS 15 introduced "Prefer non-blinking cursor" accessibility feature
- SwiftTerm cursor configuration conflicts with system preferences
- NSViewRepresentable lifecycle issues affecting cursor state
- Custom cursor styling in `TerminalEmbedding.swift:204` may conflict with system

### 2. Cannot Type in Terminal ❌
**Symptoms**: Terminal appears but keyboard input is completely unresponsive
**Root Causes Identified**:
- **First Responder Chain Issues**: SwiftUI NSViewRepresentable has known focus handling limitations
- **Input Method Problems**: macOS 15 changes to input handling may affect embedded NSView components
- **Timing Issues**: Terminal initialization and focus setting happening asynchronously

### 3. Window Controls Don't Work ❌
**Symptoms**: Close, minimize, zoom buttons are unresponsive; cannot move window
**Root Causes Identified**:
- **Custom Window Style**: `PintoApp.swift:10-11` uses `.windowStyle(.plain)` which removes system controls
- **Custom Traffic Lights**: App implements custom window controls that may have event handling issues
- **Drag Behavior Conflicts**: `.windowBackgroundDragBehavior(.enabled)` may conflict with custom drag implementation

### 4. Terminal Content Disappears ⚠️
**Symptoms**: After some time, terminal content vanishes unexpectedly
**Potential Causes**:
- **Memory Management**: SwiftTerm LocalProcessTerminalView may be deallocated
- **View State Issues**: NSViewRepresentable updating lifecycle problems
- **Background/Foreground Transitions**: macOS 15 app lifecycle changes

## Technical Analysis

### Current SwiftTerm Implementation
Located in `/Pinto/Services/TerminalEmbedding.swift`:

**Architecture**:
- `TerminalEmbeddingView` (NSViewRepresentable) 
- `PintoTerminalView` (NSView container)
- `LocalProcessTerminalView` (SwiftTerm component)

**Known Issues in Current Code**:

#### Input Handling Problems (`TerminalEmbedding.swift:58-68`)
```swift
override func becomeFirstResponder() -> Bool {
    if let terminalView = terminalView {
        return terminalView.becomeFirstResponder()
    }
    return super.becomeFirstResponder()
}
```
**Issue**: First responder chain is complex with multiple layers, timing-dependent

#### Cursor Configuration (`TerminalEmbedding.swift:194-215`)
```swift
func updateTheme(with profile: TerminalProfile) {
    // ...
    terminalView.caretColor = NSColor.labelColor
    // ...
}
```
**Issue**: Manual cursor styling may conflict with macOS 15 accessibility preferences

#### Async Initialization (`TerminalEmbedding.swift:111-113`)
```swift
DispatchQueue.main.async { [weak self] in
    self?.startShellProcess()
}
```
**Issue**: Race conditions between view setup and process initialization

### macOS 15 Sequoia Compatibility Issues

#### 1. NSViewRepresentable Focus Limitations
- **SwiftUI Focus System**: Limited programmatic focus control
- **Sequoia Changes**: New input handling behaviors may break existing workarounds
- **First Responder Chain**: More complex in SwiftUI embedded views

#### 2. Accessibility Changes
- **Cursor Preferences**: "Prefer non-blinking cursor" feature affects all apps
- **Input Method Framework**: Changes may affect terminal emulators
- **Window Management**: New behaviors for plain window styles

#### 3. Memory Management
- **View Lifecycle**: Stricter cleanup in Sequoia may cause premature deallocation
- **Process Termination**: More aggressive process management may kill terminal processes

## Identified Root Causes

### Primary Issues
1. **NSViewRepresentable First Responder Chain**: Complex focus handling with multiple async operations
2. **Custom Window Implementation**: Plain window style with custom controls has interaction conflicts
3. **SwiftTerm Integration Timing**: Race conditions in terminal initialization sequence
4. **macOS 15 Compatibility**: New OS behaviors affecting terminal emulator patterns

### Code-Specific Problems

#### `TerminalEmbedding.swift` Issues
- **Line 39-56**: `viewDidMoveToWindow()` has complex async chain that may fail
- **Line 75-114**: `setupTerminal()` initialization sequence is fragile
- **Line 103-105**: First responder setting in async block may be too late
- **Line 194-215**: Theme update may interfere with system cursor preferences

#### `PintoApp.swift` Issues  
- **Line 10**: `.windowStyle(.plain)` removes system window controls
- **Line 11**: `.windowBackgroundDragBehavior(.enabled)` may conflict with custom implementation

## Recommended Solutions

### Immediate Fixes

#### 1. Fix Input Handling
**Priority**: Critical ❌
**Location**: `TerminalEmbedding.swift`
**Solution**: Implement synchronous first responder chain with proper focus management

#### 2. Fix Window Controls  
**Priority**: Critical ❌
**Location**: `PintoApp.swift` + window management
**Solution**: Either use standard window style or fix custom traffic light implementation

#### 3. Fix Cursor Behavior
**Priority**: High ⚠️
**Location**: `TerminalEmbedding.swift:204`
**Solution**: Respect system cursor preferences, remove manual cursor styling

### Long-term Improvements

#### 1. Robust Terminal Integration
- Implement proper NSViewRepresentable lifecycle management
- Add comprehensive error handling for terminal process management
- Implement view state persistence across app lifecycle events

#### 2. macOS 15 Optimization
- Test and optimize for Sequoia-specific behaviors
- Implement proper accessibility support
- Add proper memory management for embedded views

#### 3. Enhanced Window Management
- Fix custom window controls or revert to system controls
- Implement proper drag behavior without conflicts
- Add window state restoration

## Testing Strategy

### Manual Testing
1. **Input Testing**: Verify keyboard input works immediately after app launch
2. **Window Controls**: Test all window controls (close, minimize, zoom, drag)
3. **Cursor Behavior**: Verify cursor follows system preferences
4. **Content Persistence**: Test terminal content remains visible during extended use

### Automated Testing
1. **Focus Chain Testing**: Unit tests for first responder chain
2. **Memory Leak Testing**: Profile for view deallocation issues
3. **Process Management**: Test terminal process lifecycle

## Risk Assessment

### High Risk Issues ❌
- **No Terminal Input**: Breaks core functionality
- **Unresponsive Window**: Makes app unusable
- **Content Disappearing**: Data loss risk

### Medium Risk Issues ⚠️
- **Cursor Behavior**: UX degradation but terminal still functional

### Low Risk Issues ℹ️
- **Minor UI Glitches**: Cosmetic issues

## Implementation Priority

1. **Phase 1** (Critical): Fix input handling and window controls
2. **Phase 2** (High): Fix cursor behavior and content persistence  
3. **Phase 3** (Enhancement): Optimize for macOS 15 and improve robustness

---

**Document Status**: ✅ Research Complete  
**Last Updated**: July 31, 2025  
**Next Steps**: Begin implementation of critical fixes in Phase 1