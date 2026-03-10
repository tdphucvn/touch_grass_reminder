import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: TimerStore
    @State private var workHex = ""
    @State private var breakHex = ""

    var body: some View {
        Form {
            Section("Preset") {
                Picker("Mode", selection: $store.preset) {
                    ForEach(TimerPreset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }
                Text(store.preset.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Durations") {
                DurationInputRow(title: "Work", minutes: $store.workMinutes, seconds: $store.workSeconds)
                DurationInputRow(title: "Break", minutes: $store.breakMinutes, seconds: $store.breakSeconds)
                DurationInputRow(title: "Long Break", minutes: $store.longBreakMinutes, seconds: $store.longBreakSeconds)
                LongBreakCycleRow(longBreakEveryWorkSessions: $store.longBreakEveryWorkSessions)
            }

            Section("Colors") {
                ColorControlsSection(
                    title: "Work Color",
                    color: store.workTint,
                    red: $store.workTintRed,
                    green: $store.workTintGreen,
                    blue: $store.workTintBlue,
                    hexText: $workHex,
                    applyHex: applyWorkHex
                )

                ColorControlsSection(
                    title: "Break Color",
                    color: store.breakTint,
                    red: $store.breakTintRed,
                    green: $store.breakTintGreen,
                    blue: $store.breakTintBlue,
                    hexText: $breakHex,
                    applyHex: applyBreakHex
                )
            }

            Section("Widget") {
                Toggle("Show floating panel", isOn: $store.isWidgetVisible)

                LabeledContent("Opacity", value: "\(Int(store.widgetOpacity * 100))%")
                Slider(value: $store.widgetOpacity, in: 0.45...1.0)

                Button("Reset Panel Position") {
                    store.resetWidgetPosition()
                }
            }

            Section("Behavior") {
                Toggle("Auto-start next phase", isOn: $store.autoStartNextPhase)
                Toggle("Notifications", isOn: $store.notificationsEnabled)
                Toggle("Sound on phase switch", isOn: $store.playSound)
            }
        }
        .formStyle(.grouped)
        .onAppear(perform: syncHexFieldsFromStore)
        .onChange(of: store.workTintRed) { _ in syncHexFieldsFromStore() }
        .onChange(of: store.workTintGreen) { _ in syncHexFieldsFromStore() }
        .onChange(of: store.workTintBlue) { _ in syncHexFieldsFromStore() }
        .onChange(of: store.breakTintRed) { _ in syncHexFieldsFromStore() }
        .onChange(of: store.breakTintGreen) { _ in syncHexFieldsFromStore() }
        .onChange(of: store.breakTintBlue) { _ in syncHexFieldsFromStore() }
    }

    private func syncHexFieldsFromStore() {
        workHex = store.hexTint(for: .work)
        breakHex = store.hexTint(for: .breakTime)
    }

    private func applyWorkHex() {
        if store.applyWorkHex(workHex) {
            workHex = store.hexTint(for: .work)
        }
    }

    private func applyBreakHex() {
        if store.applyBreakHex(breakHex) {
            breakHex = store.hexTint(for: .breakTime)
        }
    }
}
