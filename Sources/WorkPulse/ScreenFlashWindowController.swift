import AppKit
import SwiftUI

private struct ScreenFlashView: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(color.opacity(0.95), lineWidth: 8)
            .shadow(color: color.opacity(0.6), radius: 24)
            .padding(8)
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
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        } completionHandler: { [weak self] in
            Task { @MainActor [weak self] in
                self?.fadeOutAndHide()
            }
        }
    }

    private func fadeOutAndHide() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.9
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor [weak self] in
                self?.panel.orderOut(nil)
            }
        }
    }
}
