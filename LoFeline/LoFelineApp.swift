import SwiftUI
import AppKit

@main
struct LoFelineApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

/// Manages the menu-bar status item and popover.
/// Left-click toggles playback; right-click (or control-click) opens the menu.
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let player = LoFelinePlayer()
    private var statusItem: NSStatusItem!
    private var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = CatIcon.menuBar
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        updateIcon()
        observeIcon()
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true

        if isRightClick {
            togglePopover(sender)
        } else {
            player.toggle()
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if let popover, popover.isShown {
            popover.performClose(nil)
            return
        }

        let popover = NSPopover()
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: MenuView(player: player))
        self.popover = popover

        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    // Release the SwiftUI hierarchy once the menu is dismissed.
    func popoverDidClose(_ notification: Notification) {
        popover?.contentViewController = nil
        popover = nil
    }

    private func updateIcon() {
        statusItem.button?.alphaValue = player.isPlaying ? 1.0 : 0.5
    }

    // Keep the icon in sync with isPlaying, however the toggle was triggered.
    private func observeIcon() {
        withObservationTracking {
            _ = player.isPlaying
        } onChange: {
            Task { @MainActor [weak self] in
                self?.updateIcon()
                self?.observeIcon()
            }
        }
    }
}
