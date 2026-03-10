import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var store: TimerStore
    @State private var showSettings = false
    @State private var workHex = ""
    @State private var breakHex = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.phaseDisplayTitle)
                .font(.headline)

            Text(store.formattedRemaining)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 8) {
                Button(store.isRunning ? "Pause" : "Start") {
                    store.startOrPause()
                }

                Button("Complete") {
                    store.completeCurrentPhase()
                }

                Button("Reset") {
                    store.resetCurrentPhase()
                }
            }

            Divider()

            Toggle("Show floating panel", isOn: $store.isWidgetVisible)

            HStack {
                Text("Completed work sessions")
                Spacer()
                Text("\(store.completedWorkSessions)")
                    .monospacedDigit()
            }
            .font(.subheadline)

            if let completionMessage = store.completionMessage {
                Text(completionMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            settingsToggleRow

            if showSettings {
                settingsContent
                    .transition(.opacity)
            }

            Button("Quit WorkPulse") {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
        .onAppear(perform: syncHexFieldsFromStore)
        .onChange(of: store.workTintRed) { _ in syncHexFieldsFromStore() }
        .onChange(of: store.workTintGreen) { _ in syncHexFieldsFromStore() }
        .onChange(of: store.workTintBlue) { _ in syncHexFieldsFromStore() }
        .onChange(of: store.breakTintRed) { _ in syncHexFieldsFromStore() }
        .onChange(of: store.breakTintGreen) { _ in syncHexFieldsFromStore() }
        .onChange(of: store.breakTintBlue) { _ in syncHexFieldsFromStore() }
    }

    private var settingsToggleRow: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                showSettings.toggle()
            }
        } label: {
            HStack {
                Label("Settings", systemImage: "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text(showSettings ? "Hide" : "Show")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Preset", selection: $store.preset) {
                ForEach(TimerPreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            Text(store.preset.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            DurationInputRow(title: "Work", minutes: $store.workMinutes, seconds: $store.workSeconds)
            DurationInputRow(title: "Break", minutes: $store.breakMinutes, seconds: $store.breakSeconds)
            DurationInputRow(title: "Long Break", minutes: $store.longBreakMinutes, seconds: $store.longBreakSeconds)
            LongBreakCycleRow(longBreakEveryWorkSessions: $store.longBreakEveryWorkSessions)

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

            LabeledContent("Opacity", value: "\(Int(store.widgetOpacity * 100))%")
            Slider(value: $store.widgetOpacity, in: 0.45...1.0)

            Toggle("Auto-start next phase", isOn: $store.autoStartNextPhase)
            Toggle("Notifications", isOn: $store.notificationsEnabled)
            Toggle("Sound on phase switch", isOn: $store.playSound)
            Toggle("Hydration reminders", isOn: $store.hydrationRemindersEnabled)

            if store.hydrationRemindersEnabled {
                if store.preset == .custom {
                    HydrationOffsetInputRow(
                        title: "After Start",
                        enabled: $store.customHydrationAfterStartEnabled,
                        minutes: $store.customHydrationAfterStartMinutes,
                        seconds: $store.customHydrationAfterStartSeconds
                    )
                    HydrationOffsetInputRow(
                        title: "Before End",
                        enabled: $store.customHydrationBeforeEndEnabled,
                        minutes: $store.customHydrationBeforeEndMinutes,
                        seconds: $store.customHydrationBeforeEndSeconds
                    )
                }

                Text(store.hydrationReminderSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Reset Panel Position") {
                store.resetWidgetPosition()
            }
            .buttonStyle(.borderless)
        }
        .padding(.top, 4)
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
