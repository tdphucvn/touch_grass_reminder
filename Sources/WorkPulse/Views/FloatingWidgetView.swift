import SwiftUI

struct FloatingWidgetView: View {
    @EnvironmentObject private var store: TimerStore

    private let outerRadius: CGFloat = 12
    private let segmentRadius: CGFloat = 8

    var body: some View {
        HStack(spacing: 6) {
            WindowDragHandle()

            timerBadge

            segmentButton(
                title: store.isRunning ? "Pause" : "Start",
                systemImage: store.isRunning ? "pause.circle.fill" : "play.circle.fill"
            ) {
                store.startOrPause()
            }

            segmentButton(
                title: "Complete",
                systemImage: "checkmark.circle"
            ) {
                store.completeCurrentPhase()
            }

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: segmentRadius, style: .continuous)
                            .fill(Color.red)
                    )
            }
            .buttonStyle(.plain)
            .help("Quit")
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                .fill(Color.black.opacity(0.52))
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Rectangle()
                            .fill(store.activeTint.opacity(0.18))
                            .frame(width: (proxy.size.width * store.progress) + 2)
                            .offset(x: -1)
                    }
                    .allowsHitTesting(false)
                    .clipShape(RoundedRectangle(cornerRadius: outerRadius, style: .continuous))
                }
            )
        .overlay {
            RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        }
        .fixedSize(horizontal: true, vertical: true)
    }

    private var timerBadge: some View {
        HStack(spacing: 8) {
            Text(store.formattedRemaining)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()

            Text(store.phaseDisplayTitle)
                .font(.system(size: 12, weight: .bold, design: .rounded))

            Circle()
                .fill(store.activeTint)
                .frame(width: 7, height: 7)
        }
        .foregroundStyle(.white.opacity(0.96))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: segmentRadius, style: .continuous)
                .fill(Color.white.opacity(0.09))
        )
    }

    private func segmentButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.93))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: segmentRadius, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                )
        }
        .buttonStyle(.plain)
    }
}
