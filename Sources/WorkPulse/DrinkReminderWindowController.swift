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

    @State private var isVisible = false
    @State private var isHolding = false
    @State private var progress: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            topRow
            bodyCopy
            holdToDismissButton
        }
        .padding(18)
        .frame(width: 392, height: 188)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.034, green: 0.04, blue: 0.055),
                            Color(red: 0.042, green: 0.052, blue: 0.075)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.14))
                }
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.26), lineWidth: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
                .padding(1.5)
                .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            tint.opacity(0.2),
                            Color.clear
                        ],
                        center: .topTrailing,
                        startRadius: 2,
                        endRadius: 160
                    )
                )
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .scaleEffect(isVisible ? 1 : 0.98)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 8)
        .onAppear {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                isVisible = true
            }
        }
    }

    private var topRow: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }

                Image(systemName: "drop.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.98),
                                tint.opacity(0.72)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text("Hydration Break")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.97))

                Text("A short reset keeps your focus steady.")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.62))
            }

            Spacer(minLength: 8)

            Text("NOW")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(tint.opacity(0.88))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(tint.opacity(0.16))
                )
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(tint.opacity(0.3), lineWidth: 1)
                }
        }
    }

    private var bodyCopy: some View {
        Text("You have been in deep focus mode. Take a sip of water, roll your shoulders once, and continue with fresh energy.")
            .font(.system(size: 13.5, weight: .medium, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.74))
            .lineSpacing(3.5)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var holdToDismissButton: some View {
        ZStack(alignment: .leading) {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.045))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                }
                .frame(height: 44)

            GeometryReader { proxy in
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.52),
                                tint.opacity(0.26)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * progress, height: 44)
            }
            .allowsHitTesting(false)

            HStack(spacing: 8) {
                Image(systemName: isHolding ? "checkmark.circle.fill" : "hand.tap.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.84))

                Text(isHolding ? "Keep holding..." : "Press and hold to dismiss")
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.92))
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 44)
        .contentShape(Capsule(style: .continuous))
        .onLongPressGesture(
            minimumDuration: holdDuration,
            maximumDistance: 30,
            pressing: { pressing in
                if pressing {
                    guard !isHolding else { return }
                    isHolding = true
                    progress = 0
                    withAnimation(.linear(duration: holdDuration)) {
                        progress = 1
                    }
                } else {
                    isHolding = false
                    withAnimation(.easeOut(duration: 0.18)) {
                        progress = 0
                    }
                }
            },
            perform: {
                onDismiss()
                isHolding = false
                progress = 0
            }
        )
    }
}

@MainActor
final class DrinkReminderWindowController: NSWindowController {
    private let panel: DrinkReminderPanel
    private var isShowing = false

    init() {
        let panel = DrinkReminderPanel(
            contentRect: NSRect(x: 0, y: 0, width: 392, height: 188),
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
            let size = NSSize(width: 392, height: 188)
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

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func dismiss() {
        panel.orderOut(nil)
        isShowing = false
    }
}
