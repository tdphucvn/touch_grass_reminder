import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingWidgetController: FloatingWidgetWindowController?
    private var settingsWindowController: SettingsWindowController?
    private let screenFlashController = ScreenFlashWindowController()
    private var drinkReminderController: DrinkReminderWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = FloatingWidgetWindowController()
        controller.showWindow(nil)
        floatingWidgetController = controller

        TimerStore.shared.onPhaseCompleted = { [weak self] completedPhase in
            self?.flashActiveScreen(for: completedPhase)
        }

        TimerStore.shared.onHydrationReminderDue = { [weak self] in
            self?.presentHydrationReminder()
        }
    }

    @objc func showSettingsWindow(_ sender: Any?) {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(store: TimerStore.shared)
        }

        settingsWindowController?.present()
    }

    private func flashActiveScreen(for completedPhase: SessionPhase) {
        let color = TimerStore.shared.nsTint(for: completedPhase)
        let targetScreen = floatingWidgetController?.currentScreen
        screenFlashController.flash(on: targetScreen, color: color)
    }

    private func presentHydrationReminder() {
        let targetScreen = floatingWidgetController?.currentScreen
        if drinkReminderController == nil {
            drinkReminderController = DrinkReminderWindowController()
        }
        drinkReminderController?.present(on: targetScreen, tint: NSColor.systemTeal)
    }
}
