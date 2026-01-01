import AppKit
import SwiftUI

class QuickAIManager: ObservableObject {
    static let shared = QuickAIManager()
    var panel: QuickAIPanel?

    private init() {}

    func setup() {
        let panel = QuickAIPanel(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 80),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true

        let rootView = QuickAIView(
            onResize: { [weak panel] size in
                guard let panel = panel else { return }
                DispatchQueue.main.async {
                    let currentFrame = panel.frame
                    if currentFrame.size != size {
                        let newY = currentFrame.maxY - size.height
                        let newFrame = NSRect(
                            x: currentFrame.minX, y: newY,
                            width: size.width,
                            height: size.height)

                        NSAnimationContext.runAnimationGroup { context in
                            context.duration = 0.4
                            context.timingFunction = CAMediaTimingFunction(
                                controlPoints: 0.23, 1, 0.32, 1)  // Ease Out Quint
                            panel.animator().setFrame(newFrame, display: true)
                        }
                    }
                }
            },
            onClose: { [weak panel] in
                panel?.orderOut(nil)

                // If no other windows are visible, hide the app to return focus to previous app
                let otherWindowsVisible = NSApp.windows.contains { $0 != panel && $0.isVisible }
                if !otherWindowsVisible {
                    NSApp.hide(nil)
                }
            }
        )

        panel.contentView = NSHostingView(rootView: rootView)
        self.panel = panel
    }

    func toggle() {
        guard let panel = panel else { return }

        if panel.isVisible && panel.isKeyWindow {
            panel.orderOut(nil)

            // If no other windows are visible, hide the app to return focus to previous app
            let otherWindowsVisible = NSApp.windows.contains { $0 != panel && $0.isVisible }
            if !otherWindowsVisible {
                NSApp.hide(nil)
            }
        } else {
            // If app is not active, we are coming from outside.
            // We should ensure the main window doesn't pop up and distract.
            if !NSApp.isActive {
                for window in NSApp.windows {
                    if window != panel {
                        window.orderOut(nil)
                    }
                }
            }

            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                let panelSize = panel.frame.size
                let x = screenRect.midX - (panelSize.width / 2)
                let y = screenRect.maxY - 200 - panelSize.height
                panel.setFrameOrigin(NSPoint(x: x, y: y))
            } else {
                panel.center()
            }

            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

class QuickAIPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
