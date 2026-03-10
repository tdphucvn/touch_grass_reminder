import SwiftUI

enum SettingsFieldFormatters {
    static let minutes: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 0
        formatter.maximum = 180
        return formatter
    }()

    static let seconds: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 0
        formatter.maximum = 59
        return formatter
    }()

    static let cycle: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 0
        formatter.maximum = 12
        return formatter
    }()
}

struct DurationInputRow: View {
    let title: String
    @Binding var minutes: Int
    @Binding var seconds: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(title)

            Spacer()

            TextField("mm", value: $minutes, formatter: SettingsFieldFormatters.minutes)
                .textFieldStyle(.roundedBorder)
                .frame(width: 52)
                .multilineTextAlignment(.trailing)

            Text(":")
                .foregroundStyle(.secondary)
                .monospacedDigit()

            TextField("ss", value: $seconds, formatter: SettingsFieldFormatters.seconds)
                .textFieldStyle(.roundedBorder)
                .frame(width: 52)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct LongBreakCycleRow: View {
    @Binding var longBreakEveryWorkSessions: Int

    var body: some View {
        HStack(spacing: 8) {
            Text("Long Break Every")
            Spacer()
            TextField("0", value: $longBreakEveryWorkSessions, formatter: SettingsFieldFormatters.cycle)
                .textFieldStyle(.roundedBorder)
                .frame(width: 52)
                .multilineTextAlignment(.trailing)
            Text("work sessions")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ColorControlsSection: View {
    let title: String
    let color: Color
    @Binding var red: Double
    @Binding var green: Double
    @Binding var blue: Double
    @Binding var hexText: String
    let applyHex: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Circle()
                    .fill(color)
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }
            }

            ColorChannelRow(channel: "R", value: $red)
            ColorChannelRow(channel: "G", value: $green)
            ColorChannelRow(channel: "B", value: $blue)

            HStack(spacing: 8) {
                TextField("#RRGGBB", text: $hexText)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption.monospaced())
                    .onSubmit(applyHex)

                Button("Apply") {
                    applyHex()
                }
            }
        }
        .padding(.vertical, 2)
    }
}

private struct ColorChannelRow: View {
    let channel: String
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 8) {
            Text(channel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 14, alignment: .leading)

            Slider(value: $value, in: 0...1)

            Text("\(Int((value * 255).rounded()))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)
        }
    }
}
