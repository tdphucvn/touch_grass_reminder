import AppKit
import SwiftUI

private final class WindowDragHandleNSView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .openHand)
    }
}

private struct WindowDragHandleRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowDragHandleNSView {
        let view = WindowDragHandleNSView(frame: .zero)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }

    func updateNSView(_ nsView: WindowDragHandleNSView, context: Context) {}
}

struct WindowDragHandle: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.10))

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.88))

            WindowDragHandleRepresentable()
        }
        .frame(width: 30, height: 28)
        .help("Drag")
    }
}
