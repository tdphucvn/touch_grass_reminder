import AppKit
import Combine
import SwiftUI

private final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class FloatingWidgetWindowController: NSWindowController, NSWindowDelegate {
    private let store = TimerStore.shared
    private let hostingView: NSHostingView<AnyView>
    private var cancellables = Set<AnyCancellable>()
    private var isProgrammaticMove = false

    var currentScreen: NSScreen? {
        if let manualPosition = store.manualWidgetPosition {
            return NSScreen.screens.first { $0.frame.contains(manualPosition) }
                ?? window?.screen
                ?? NSScreen.main
                ?? NSScreen.screens.first
        }

        return activePointerScreen()
            ?? window?.screen
            ?? NSScreen.main
            ?? NSScreen.screens.first
    }

    init() {
        let hostingView = NSHostingView(
            rootView: AnyView(
                FloatingWidgetView()
                    .environmentObject(store)
            )
        )
        self.hostingView = hostingView

        let panel = OverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 56),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false
        panel.isMovable = true
        panel.isMovableByWindowBackground = false

        if #available(macOS 13.0, *) {
            hostingView.sizingOptions = []
        }

        panel.contentView = hostingView

        super.init(window: panel)

        panel.delegate = self
        bindState()
        updateWindowAppearance(animated: false)
        updateVisibility(store.isWidgetVisible)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowDidMove(_ notification: Notification) {
        guard !isProgrammaticMove, let window else { return }
        store.setManualWidgetPosition(window.frame.origin)
    }

    private func bindState() {
        store.$corner
            .sink { [weak self] _ in
                self?.updateWindowAppearance(animated: true)
            }
            .store(in: &cancellables)

        store.$widgetOpacity
            .sink { [weak self] _ in
                self?.updateWindowAppearance(animated: false)
            }
            .store(in: &cancellables)

        store.$isWidgetVisible
            .sink { [weak self] visible in
                self?.updateVisibility(visible)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.updateWindowAppearance(animated: true)
            }
            .store(in: &cancellables)
    }

    private func updateVisibility(_ isVisible: Bool) {
        guard let window else { return }

        if isVisible {
            updateWindowAppearance(animated: false)
            window.orderFrontRegardless()
        } else {
            window.orderOut(nil)
        }
    }

    private func updateWindowAppearance(animated: Bool) {
        guard let window else { return }

        let size = desiredPanelSize()
        if window.frame.size != size {
            window.setContentSize(size)
        }
        window.alphaValue = store.widgetOpacity

        guard let screen = preferredScreen() else { return }
        let frame = screen.visibleFrame
        let margin: CGFloat = 16

        let origin: NSPoint
        if let manualPosition = store.manualWidgetPosition {
            let x = min(max(manualPosition.x, frame.minX + 4), frame.maxX - size.width - 4)
            let y = min(max(manualPosition.y, frame.minY + 4), frame.maxY - size.height - 4)
            origin = NSPoint(x: x, y: y)
        } else {
            switch store.corner {
            case .topLeft:
                origin = NSPoint(x: frame.minX + margin, y: frame.maxY - size.height - margin)
            case .topRight:
                origin = NSPoint(x: frame.maxX - size.width - margin, y: frame.maxY - size.height - margin)
            case .bottomLeft:
                origin = NSPoint(x: frame.minX + margin, y: frame.minY + margin)
            case .bottomRight:
                origin = NSPoint(x: frame.maxX - size.width - margin, y: frame.minY + margin)
            }
        }

        if window.frame.origin == origin {
            return
        }

        isProgrammaticMove = true
        if animated {
            window.animator().setFrameOrigin(origin)
        } else {
            window.setFrameOrigin(origin)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { [weak self] in
            self?.isProgrammaticMove = false
        }
    }

    private func desiredPanelSize() -> NSSize {
        hostingView.layoutSubtreeIfNeeded()
        let fitting = hostingView.fittingSize

        let width = max(220, ceil(fitting.width))
        let height = max(36, ceil(fitting.height))
        return NSSize(width: width, height: height)
    }

    private func preferredScreen() -> NSScreen? {
        if let manualPosition = store.manualWidgetPosition {
            return NSScreen.screens.first { screen in
                screen.frame.contains(manualPosition)
            }
        }

        return activePointerScreen()
            ?? window?.screen
            ?? NSScreen.main
            ?? NSScreen.screens.first
    }

    private func activePointerScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
    }
}
