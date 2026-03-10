import AppKit
import SwiftUI

private struct ScreenFlashView: View {
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(color.opacity(0.95), lineWidth: 12)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(color.opacity(0.7), lineWidth: 24)
                .blur(radius: 8)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(color.opacity(0.45), lineWidth: 34)
                .blur(radius: 18)
        }
        .padding(4)
        .background(Color.clear)
    }
}

@MainActor
final class ScreenFlashWindowController: NSWindowController {
    private let panel: NSPanel

    init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.alphaValue = 0

        self.panel = panel
        super.init(window: panel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func flash(on screen: NSScreen?, color: NSColor) {
        guard let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first else { return }

        panel.setFrame(targetScreen.frame, display: false)
        panel.contentView = NSHostingView(rootView: ScreenFlashView(color: Color(nsColor: color)))
        panel.orderFrontRegardless()
        panel.alphaValue = 0

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 0.96
        } completionHandler: { [weak self] in
            Task { @MainActor [weak self] in
                self?.pulseThenFadeOut()
            }
        }
    }

    private func pulseThenFadeOut() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = 0.55
        } completionHandler: { [weak self] in
            Task { @MainActor [weak self] in
                self?.fadeInThenHide()
            }
        }
    }

    private func fadeInThenHide() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 0.98
        } completionHandler: { [weak self] in
            Task { @MainActor [weak self] in
                self?.fadeOutAndHide()
            }
        }
    }

    private func fadeOutAndHide() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 1.05
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor [weak self] in
                self?.panel.orderOut(nil)
            }
        }
    }
}
