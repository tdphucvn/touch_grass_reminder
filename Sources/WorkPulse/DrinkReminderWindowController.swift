import AppKit
import SwiftUI

private final class DrinkReminderPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private struct DrinkReminderView: View {
    let tint: Color
    let holdDuration: TimeInterval
    let onDismiss: () -> Void

    @State private var pressStart: Date?
    @State private var progress: Double = 0
    private let ticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hydration Reminder")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Text("Time to drink some water. Press and hold to dismiss.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            holdToDismissButton
        }
        .padding(20)
        .frame(width: 360)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(0.75), lineWidth: 2)
        }
        .shadow(color: tint.opacity(0.35), radius: 24)
        .onReceive(ticker) { now in
            guard let pressStart else { return }
            let elapsed = now.timeIntervalSince(pressStart)
            let ratio = min(max(elapsed / holdDuration, 0), 1)
            progress = ratio
            if ratio >= 1 {
                resetHold()
                onDismiss()
            }
        }
    }

    private var holdToDismissButton: some View {
        ZStack(alignment: .leading) {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.14))
                .frame(height: 46)

            GeometryReader { proxy in
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.85))
                    .frame(width: proxy.size.width * progress, height: 46)
            }
            .allowsHitTesting(false)

            Text(progress >= 1 ? "Done" : "Hold to dismiss")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 46)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if pressStart == nil {
                        pressStart = Date()
                        progress = 0
                    }
                }
                .onEnded { _ in
                    resetHold()
                }
        )
    }

    private func resetHold() {
        pressStart = nil
        progress = 0
    }
}

@MainActor
final class DrinkReminderWindowController: NSWindowController {
    private let panel: DrinkReminderPanel
    private var isShowing = false

    init() {
        let panel = DrinkReminderPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .moveToActiveSpace]
        panel.hidesOnDeactivate = false
        panel.isMovable = false

        self.panel = panel
        super.init(window: panel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(on screen: NSScreen?, tint: NSColor) {
        guard !isShowing else { return }
        isShowing = true

        let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first
        if let frame = targetScreen?.visibleFrame {
            let size = NSSize(width: 360, height: 200)
            let origin = NSPoint(
                x: frame.midX - (size.width / 2),
                y: frame.midY - (size.height / 2)
            )
            panel.setFrame(NSRect(origin: origin, size: size), display: false)
        }

        let rootView = DrinkReminderView(
            tint: Color(nsColor: tint),
            holdDuration: 1.2
        ) { [weak self] in
            self?.dismiss()
        }

        panel.contentView = NSHostingView(rootView: rootView)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func dismiss() {
        panel.orderOut(nil)
        isShowing = false
    }
}
