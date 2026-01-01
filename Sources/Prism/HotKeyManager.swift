import AppKit
import Carbon

class HotKeyManager {
    static let shared = HotKeyManager()
    private var hotKeyRef: EventHotKeyRef?
    var onTrigger: (() -> Void)?

    private init() {}

    func register() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        // Install handler
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                DispatchQueue.main.async {
                    HotKeyManager.shared.onTrigger?()
                }
                return noErr
            }, 1, &eventType, nil, nil)

        // Register Control + Space
        // kVK_Space = 0x31
        let keyCode = UInt32(kVK_Space)

        // Modifiers: controlKey
        let modifiers = controlKey

        let hotKeyID = EventHotKeyID(signature: OSType(1111), id: 1)

        let status = RegisterEventHotKey(
            keyCode, UInt32(modifiers), hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        if status != noErr {
            print("Failed to register hotkey: \(status)")
        } else {
            print("Registered Control+Space hotkey")
        }
    }

    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
}
