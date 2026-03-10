import SwiftUI

@main
struct WorkPulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var store = TimerStore.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(store)
                .frame(width: 320)
        } label: {
            Text("\(store.formattedRemaining) \(store.menuBarPhaseShortTitle)")
        }
        .menuBarExtraStyle(.window)
    }
}
