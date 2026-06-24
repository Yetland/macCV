import Carbon
import Cocoa

final class GlobalHotkey: @unchecked Sendable {
    nonisolated(unsafe) private static var hotKeyRef: EventHotKeyRef?
    nonisolated(unsafe) private static var eventHandlerRef: EventHandlerRef?
    nonisolated(unsafe) private static var handler: (() -> Void)?

    static func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) -> Bool {
        self.handler = handler

        let hotKeyID = EventHotKeyID(signature: 0x4D4356, id: 1)
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard status == noErr else { return false }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, event, _ in
            var hkID = EventHotKeyID()
            let err = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hkID
            )
            guard err == noErr, hkID.signature == 0x4D4356 else { return err }
            DispatchQueue.main.async { GlobalHotkey.handler?() }
            return noErr
        }

        let status2 = InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventType,
            &eventHandlerRef,
            nil
        )
        return status2 == noErr
    }

    static func unregister() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref); hotKeyRef = nil }
        if let ref = eventHandlerRef { RemoveEventHandler(ref); eventHandlerRef = nil }
        handler = nil
    }
}

struct HotkeyConfig {
    var keyCode: UInt32
    var modifiers: UInt32

    static let defaultToggle = HotkeyConfig(
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: UInt32(cmdKey | shiftKey)
    )
}
