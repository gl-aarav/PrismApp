import SwiftUI

@main
struct PrismApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("ShowMenuBar") private var showMenuBar = true

    var body: some Scene {
        WindowGroup {
            ContentView()
                .navigationTitle("Prism")
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Prism") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                string: "Developed by Aarav Goyal",
                                attributes: [
                                    .font: NSFont.systemFont(ofSize: 11),
                                    .foregroundColor: NSColor.labelColor,
                                ]
                            )
                        ]
                    )
                }
            }
        }

        MenuBarExtra("Prism", systemImage: "triangle", isInserted: $showMenuBar) {
            QuickChatView()
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var quickAIWindow: NSPanel?

    override init() {
        super.init()
        UserDefaults.standard.register(defaults: ["ShowMenuBar": true])
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app is a regular app (shows in Dock, has UI)
        NSApp.setActivationPolicy(.regular)

        // Bring to front
        NSApp.activate(ignoringOtherApps: true)

        // Force window to appear if needed
        DispatchQueue.main.async {
            if let window = NSApp.windows.first {
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.fullSizeContentView)
                window.makeKeyAndOrderFront(nil)
                window.center()
            }
        }

        setupQuickAIWindow()

        HotKeyManager.shared.onTrigger = { [weak self] in
            self?.toggleQuickAI()
        }
        HotKeyManager.shared.register()

        print("AppAI has launched! Check your Dock if you don't see the window.")
    }

    func setupQuickAIWindow() {
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
                        let newFrame = NSRect(
                            x: currentFrame.minX, y: currentFrame.maxY - size.height,
                            width: size.width,
                            height: size.height)
                        panel.setFrame(newFrame, display: true, animate: panel.isVisible)
                    }
                }
            },
            onClose: { [weak panel] in
                panel?.orderOut(nil)
                NSApp.hide(nil)
            }
        )

        panel.contentView = NSHostingView(rootView: rootView)
        panel.center()
        self.quickAIWindow = panel
    }

    func toggleQuickAI() {
        guard let panel = quickAIWindow else { return }

        if panel.isVisible {
            panel.orderOut(nil)
            let hasVisibleWindows = NSApp.windows.contains { $0 != panel && $0.isVisible }
            if !hasVisibleWindows {
                NSApp.hide(nil)
            }
        } else {
            panel.center()
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

class QuickAIPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
