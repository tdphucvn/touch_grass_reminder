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
        VStack(alignment: .leading, spacing: 18) {
            headerRow
            bodyCopy
            holdToDismissButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(width: 360, height: 220)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.035, green: 0.04, blue: 0.05),
                            Color(red: 0.05, green: 0.065, blue: 0.09)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.45), radius: 18, y: 8)
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

    private var headerRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }

                Image(systemName: "drop.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint.opacity(0.92))
            }
            .frame(width: 30, height: 30)

            Text("Hydration")
                .font(.system(size: 29, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.95))
        }
    }

    private var bodyCopy: some View {
        Text("You've been focused for a while. Take a brief\nmoment to drink some water and reset.")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.72))
            .lineSpacing(4)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var holdToDismissButton: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
                .frame(height: 40)

            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.38),
                                tint.opacity(0.18)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * progress, height: 40)
            }
            .allowsHitTesting(false)

            Text(progress >= 1 ? "Done" : "Hold to dismiss")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 40)
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
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 220),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
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
            let size = NSSize(width: 360, height: 220)
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
