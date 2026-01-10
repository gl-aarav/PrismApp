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

        MenuBarExtra("", systemImage: "triangle", isInserted: $showMenuBar) {
            QuickChatView()
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var appearanceObservation: NSKeyValueObservation?
    private var lightIcon: NSImage?
    private var darkIcon: NSImage?

    override init() {
        super.init()
        UserDefaults.standard.register(defaults: ["ShowMenuBar": true, "EnableQuickAI": true])
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app is a regular app (shows in Dock, has UI)
        NSApp.setActivationPolicy(.regular)

        // Bring to front
        NSApp.activate(ignoringOtherApps: true)

        // Force main window to appear if needed
        DispatchQueue.main.async {
            // Find the main window (not the Quick AI panel)
            if let window = NSApp.windows.first(where: { !($0 is QuickAIPanel) }) {
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.fullSizeContentView)
                window.makeKeyAndOrderFront(nil)
                window.center()
            }
        }

        QuickAIManager.shared.setup()

        HotKeyManager.shared.onTrigger = {
            if UserDefaults.standard.bool(forKey: "EnableQuickAI") {
                QuickAIManager.shared.toggle()
            }
        }
        HotKeyManager.shared.register()

        loadIcons()
        appearanceObservation = NSApp.observe(\.effectiveAppearance, options: [.initial, .new]) {
            [weak self] app, _ in
            self?.updateAppIcon(for: app.effectiveAppearance)
        }

        print("Prism has launched!")
    }

    func applicationWillTerminate(_ notification: Notification) {
        appearanceObservation = nil
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // If Quick AI is open, we don't want to force the main window to open
        if let panel = QuickAIManager.shared.panel, panel.isVisible {
            return
        }

        // If no windows are visible (excluding Quick AI), show the main window
        // This handles Cmd+Tab or other activation methods where applicationShouldHandleReopen might not be called
        let visibleWindows = NSApp.windows.filter { $0.isVisible && !($0 is QuickAIPanel) }
        if visibleWindows.isEmpty {
            for window in NSApp.windows {
                if !(window is QuickAIPanel) {
                    window.makeKeyAndOrderFront(nil)
                    return
                }
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool)
        -> Bool
    {
        // If Quick AI is open, we don't want to force the main window to open
        if let panel = QuickAIManager.shared.panel, panel.isVisible {
            return true
        }

        if !flag {
            // If no windows are visible (excluding Quick AI which might be hidden), show the main window
            for window in NSApp.windows {
                if !(window is QuickAIPanel) {
                    window.makeKeyAndOrderFront(nil)
                    return false
                }
            }
        }
        return true
    }

    private func loadIcons() {
        lightIcon = loadIcon(named: "AppIconLight") ?? loadIcon(named: "AppIcon")
        darkIcon = loadIcon(named: "AppIconDark") ?? lightIcon
    }

    private func loadIcon(named: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: named, withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }

    private func updateAppIcon(for appearance: NSAppearance) {
        let match = appearance.bestMatch(from: [.darkAqua, .aqua])
        if match == .darkAqua {
            if let icon = darkIcon {
                NSApp.applicationIconImage = icon
                return
            }
        }
        if let icon = lightIcon {
            NSApp.applicationIconImage = icon
        }
    }
}
