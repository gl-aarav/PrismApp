import SwiftUI

@main
struct PrismApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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
                                    .foregroundColor: NSColor.labelColor
                                ]
                            )
                        ]
                    )
                }
            }
        }
        
        MenuBarExtra("Prism", systemImage: "triangle") {
            QuickChatView()
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
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
        
        print("AppAI has launched! Check your Dock if you don't see the window.")
    }
}
