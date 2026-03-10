import AppKit
import Combine
import Foundation
import SwiftUI
import UserNotifications

enum SessionPhase: String, CaseIterable {
    case work
    case breakTime

    var title: String {
        switch self {
        case .work:
            return "Work"
        case .breakTime:
            return "Break"
        }
    }

    var shortTitle: String {
        switch self {
        case .work:
            return "W"
        case .breakTime:
            return "B"
        }
    }
}

enum WidgetCorner: String, CaseIterable, Identifiable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .topLeft:
            return "Top Left"
        case .topRight:
            return "Top Right"
        case .bottomLeft:
            return "Bottom Left"
        case .bottomRight:
            return "Bottom Right"
        }
    }
}

enum TimerPreset: String, CaseIterable, Identifiable {
    case custom
    case pomodoroClassic
    case focus4510

    var id: String { rawValue }

    var title: String {
        switch self {
        case .custom:
            return "Custom"
        case .pomodoroClassic:
            return "Pomodoro"
        case .focus4510:
            return "45/10"
        }
    }

    var subtitle: String {
        switch self {
        case .custom:
            return "Manual configuration"
        case .pomodoroClassic:
            return "25:00 work, 05:00 break, long 30:00 every 4 sessions"
        case .focus4510:
            return "45:00 work, 10:00 break"
        }
    }
}

@MainActor
final class TimerStore: ObservableObject {
    static let shared = TimerStore()

    @Published private(set) var phase: SessionPhase = .work
    @Published private(set) var isRunning = false
    @Published private(set) var isLongBreakActive = false
    @Published private(set) var remainingTimeSeconds: TimeInterval
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var completedWorkSessions = 0
    @Published private(set) var completionMessage: String?

    @Published var preset: TimerPreset {
        didSet {
            defaults.set(preset.rawValue, forKey: Keys.preset)
            guard !isApplyingPreset, preset != .custom else { return }
            applyPreset(preset)
        }
    }

    @Published var workMinutes: Int {
        didSet {
            let clamped = max(0, min(workMinutes, 180))
            if workMinutes != clamped {
                workMinutes = clamped
                return
            }
            if workMinutes == 0, workSeconds == 0 {
                workSeconds = 1
            }
            defaults.set(workMinutes, forKey: Keys.workMinutes)
            markPresetCustomIfNeeded()
            if phase == .work, !isRunning {
                syncRemainingToCurrentPhase()
            }
        }
    }

    @Published var workSeconds: Int {
        didSet {
            let clamped = max(0, min(workSeconds, 59))
            if workSeconds != clamped {
                workSeconds = clamped
                return
            }
            if workMinutes == 0, workSeconds == 0 {
                workSeconds = 1
                return
            }
            defaults.set(workSeconds, forKey: Keys.workSeconds)
            markPresetCustomIfNeeded()
            if phase == .work, !isRunning {
                syncRemainingToCurrentPhase()
            }
        }
    }

    @Published var breakMinutes: Int {
        didSet {
            let clamped = max(0, min(breakMinutes, 90))
            if breakMinutes != clamped {
                breakMinutes = clamped
                return
            }
            if breakMinutes == 0, breakSeconds == 0 {
                breakSeconds = 1
            }
            defaults.set(breakMinutes, forKey: Keys.breakMinutes)
            markPresetCustomIfNeeded()
            if phase == .breakTime, !isRunning, !isLongBreakActive {
                syncRemainingToCurrentPhase()
            }
        }
    }

    @Published var breakSeconds: Int {
        didSet {
            let clamped = max(0, min(breakSeconds, 59))
            if breakSeconds != clamped {
                breakSeconds = clamped
                return
            }
            if breakMinutes == 0, breakSeconds == 0 {
                breakSeconds = 1
                return
            }
            defaults.set(breakSeconds, forKey: Keys.breakSeconds)
            markPresetCustomIfNeeded()
            if phase == .breakTime, !isRunning, !isLongBreakActive {
                syncRemainingToCurrentPhase()
            }
        }
    }

    @Published var longBreakMinutes: Int {
        didSet {
            let clamped = max(0, min(longBreakMinutes, 180))
            if longBreakMinutes != clamped {
                longBreakMinutes = clamped
                return
            }
            defaults.set(longBreakMinutes, forKey: Keys.longBreakMinutes)
            markPresetCustomIfNeeded()
            if phase == .breakTime, !isRunning, isLongBreakActive {
                syncRemainingToCurrentPhase()
            }
        }
    }

    @Published var longBreakSeconds: Int {
        didSet {
            let clamped = max(0, min(longBreakSeconds, 59))
            if longBreakSeconds != clamped {
                longBreakSeconds = clamped
                return
            }
            defaults.set(longBreakSeconds, forKey: Keys.longBreakSeconds)
            markPresetCustomIfNeeded()
            if phase == .breakTime, !isRunning, isLongBreakActive {
                syncRemainingToCurrentPhase()
            }
        }
    }

    @Published var longBreakEveryWorkSessions: Int {
        didSet {
            let clamped = max(0, min(longBreakEveryWorkSessions, 12))
            if longBreakEveryWorkSessions != clamped {
                longBreakEveryWorkSessions = clamped
                return
            }
            defaults.set(longBreakEveryWorkSessions, forKey: Keys.longBreakEvery)
            markPresetCustomIfNeeded()
        }
    }

    @Published var corner: WidgetCorner {
        didSet {
            defaults.set(corner.rawValue, forKey: Keys.corner)
        }
    }

    @Published var widgetOpacity: Double {
        didSet {
            let clamped = min(max(widgetOpacity, 0.45), 1.0)
            if widgetOpacity != clamped {
                widgetOpacity = clamped
                return
            }
            defaults.set(widgetOpacity, forKey: Keys.opacity)
        }
    }

    @Published var workTintRed: Double {
        didSet {
            let clamped = min(max(workTintRed, 0.0), 1.0)
            if workTintRed != clamped {
                workTintRed = clamped
                return
            }
            defaults.set(workTintRed, forKey: Keys.workTintRed)
        }
    }

    @Published var workTintGreen: Double {
        didSet {
            let clamped = min(max(workTintGreen, 0.0), 1.0)
            if workTintGreen != clamped {
                workTintGreen = clamped
                return
            }
            defaults.set(workTintGreen, forKey: Keys.workTintGreen)
        }
    }

    @Published var workTintBlue: Double {
        didSet {
            let clamped = min(max(workTintBlue, 0.0), 1.0)
            if workTintBlue != clamped {
                workTintBlue = clamped
                return
            }
            defaults.set(workTintBlue, forKey: Keys.workTintBlue)
        }
    }

    @Published var breakTintRed: Double {
        didSet {
            let clamped = min(max(breakTintRed, 0.0), 1.0)
            if breakTintRed != clamped {
                breakTintRed = clamped
                return
            }
            defaults.set(breakTintRed, forKey: Keys.breakTintRed)
        }
    }

    @Published var breakTintGreen: Double {
        didSet {
            let clamped = min(max(breakTintGreen, 0.0), 1.0)
            if breakTintGreen != clamped {
                breakTintGreen = clamped
                return
            }
            defaults.set(breakTintGreen, forKey: Keys.breakTintGreen)
        }
    }

    @Published var breakTintBlue: Double {
        didSet {
            let clamped = min(max(breakTintBlue, 0.0), 1.0)
            if breakTintBlue != clamped {
                breakTintBlue = clamped
                return
            }
            defaults.set(breakTintBlue, forKey: Keys.breakTintBlue)
        }
    }

    @Published var autoStartNextPhase: Bool {
        didSet {
            defaults.set(autoStartNextPhase, forKey: Keys.autoStart)
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
        }
    }

    @Published var playSound: Bool {
        didSet {
            defaults.set(playSound, forKey: Keys.playSound)
        }
    }

    @Published var isWidgetVisible: Bool {
        didSet {
            defaults.set(isWidgetVisible, forKey: Keys.widgetVisible)
        }
    }

    @Published var manualWidgetPosition: CGPoint? {
        didSet {
            if let manualWidgetPosition {
                defaults.set(manualWidgetPosition.x, forKey: Keys.manualWidgetX)
                defaults.set(manualWidgetPosition.y, forKey: Keys.manualWidgetY)
            } else {
                defaults.removeObject(forKey: Keys.manualWidgetX)
                defaults.removeObject(forKey: Keys.manualWidgetY)
            }
        }
    }

    var onPhaseCompleted: ((SessionPhase) -> Void)?

    var formattedRemaining: String {
        let displaySeconds = max(0, Int(ceil(remainingTimeSeconds)))
        let minutes = displaySeconds / 60
        let seconds = displaySeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var phaseDisplayTitle: String {
        phase == .breakTime && isLongBreakActive ? "Long Break" : phase.title
    }

    var menuBarPhaseShortTitle: String {
        phase == .breakTime && isLongBreakActive ? "LB" : phase.shortTitle
    }

    var workTint: Color {
        Color(red: workTintRed, green: workTintGreen, blue: workTintBlue)
    }

    var breakTint: Color {
        Color(red: breakTintRed, green: breakTintGreen, blue: breakTintBlue)
    }

    var activeTint: Color {
        tint(for: phase)
    }

    var progress: Double {
        let total = max(Double(phaseDurationSeconds), 1)
        return min(max(remainingTimeSeconds / total, 0), 1)
    }

    private let defaults = UserDefaults.standard
    private var ticker: AnyCancellable?
    private var phaseEndDate: Date?
    private var pausedTimeSeconds: TimeInterval
    private var messageDismissWorkItem: DispatchWorkItem?
    private var workSessionsSinceLastLongBreak = 0
    private var isApplyingPreset = false

    private enum Keys {
        static let preset = "timerPreset"
        static let workMinutes = "workMinutes"
        static let workSeconds = "workSeconds"
        static let breakMinutes = "breakMinutes"
        static let breakSeconds = "breakSeconds"
        static let longBreakMinutes = "longBreakMinutes"
        static let longBreakSeconds = "longBreakSeconds"
        static let longBreakEvery = "longBreakEveryWorkSessions"
        static let corner = "corner"
        static let opacity = "widgetOpacity"
        static let workTintRed = "workTintRed"
        static let workTintGreen = "workTintGreen"
        static let workTintBlue = "workTintBlue"
        static let breakTintRed = "breakTintRed"
        static let breakTintGreen = "breakTintGreen"
        static let breakTintBlue = "breakTintBlue"
        static let autoStart = "autoStartNextPhase"
        static let notificationsEnabled = "notificationsEnabled"
        static let playSound = "playSound"
        static let widgetVisible = "widgetVisible"
        static let manualWidgetX = "manualWidgetX"
        static let manualWidgetY = "manualWidgetY"
    }

    private struct PresetConfig {
        let workMinutes: Int
        let workSeconds: Int
        let breakMinutes: Int
        let breakSeconds: Int
        let longBreakMinutes: Int
        let longBreakSeconds: Int
        let longBreakEveryWorkSessions: Int
    }

    private init() {
        let defaults = UserDefaults.standard
        let savedPreset = defaults.string(forKey: Keys.preset).flatMap(TimerPreset.init(rawValue:)) ?? .custom
        let savedWorkMinutes = defaults.object(forKey: Keys.workMinutes) as? Int ?? 50
        let savedWorkSeconds = defaults.object(forKey: Keys.workSeconds) as? Int ?? 0
        let savedBreakMinutes = defaults.object(forKey: Keys.breakMinutes) as? Int ?? 10
        let savedBreakSeconds = defaults.object(forKey: Keys.breakSeconds) as? Int ?? 0
        let savedLongBreakMinutes = defaults.object(forKey: Keys.longBreakMinutes) as? Int ?? 30
        let savedLongBreakSeconds = defaults.object(forKey: Keys.longBreakSeconds) as? Int ?? 0
        let savedLongBreakEvery = defaults.object(forKey: Keys.longBreakEvery) as? Int ?? 0

        let savedCorner = defaults.string(forKey: Keys.corner).flatMap(WidgetCorner.init(rawValue:)) ?? .topRight
        let savedOpacity = defaults.object(forKey: Keys.opacity) as? Double ?? 0.92

        preset = savedPreset

        var startWorkMinutes: Int
        var startWorkSeconds: Int
        var startBreakMinutes: Int
        var startBreakSeconds: Int
        var startLongBreakMinutes: Int
        var startLongBreakSeconds: Int
        var startLongBreakEvery: Int

        if let presetConfig = Self.config(for: savedPreset) {
            startWorkMinutes = presetConfig.workMinutes
            startWorkSeconds = presetConfig.workSeconds
            startBreakMinutes = presetConfig.breakMinutes
            startBreakSeconds = presetConfig.breakSeconds
            startLongBreakMinutes = presetConfig.longBreakMinutes
            startLongBreakSeconds = presetConfig.longBreakSeconds
            startLongBreakEvery = presetConfig.longBreakEveryWorkSessions
        } else {
            startWorkMinutes = max(0, min(savedWorkMinutes, 180))
            startWorkSeconds = max(0, min(savedWorkSeconds, 59))
            startBreakMinutes = max(0, min(savedBreakMinutes, 90))
            startBreakSeconds = max(0, min(savedBreakSeconds, 59))
            startLongBreakMinutes = max(0, min(savedLongBreakMinutes, 180))
            startLongBreakSeconds = max(0, min(savedLongBreakSeconds, 59))
            startLongBreakEvery = max(0, min(savedLongBreakEvery, 12))
        }

        if startWorkMinutes == 0, startWorkSeconds == 0 {
            startWorkSeconds = 1
        }
        if startBreakMinutes == 0, startBreakSeconds == 0 {
            startBreakSeconds = 1
        }

        workMinutes = startWorkMinutes
        workSeconds = startWorkSeconds
        breakMinutes = startBreakMinutes
        breakSeconds = startBreakSeconds
        longBreakMinutes = startLongBreakMinutes
        longBreakSeconds = startLongBreakSeconds
        longBreakEveryWorkSessions = startLongBreakEvery

        corner = savedCorner
        widgetOpacity = min(max(savedOpacity, 0.45), 1.0)

        workTintRed = min(max(defaults.object(forKey: Keys.workTintRed) as? Double ?? 0.10, 0.0), 1.0)
        workTintGreen = min(max(defaults.object(forKey: Keys.workTintGreen) as? Double ?? 0.53, 0.0), 1.0)
        workTintBlue = min(max(defaults.object(forKey: Keys.workTintBlue) as? Double ?? 0.42, 0.0), 1.0)

        breakTintRed = min(max(defaults.object(forKey: Keys.breakTintRed) as? Double ?? 0.07, 0.0), 1.0)
        breakTintGreen = min(max(defaults.object(forKey: Keys.breakTintGreen) as? Double ?? 0.42, 0.0), 1.0)
        breakTintBlue = min(max(defaults.object(forKey: Keys.breakTintBlue) as? Double ?? 0.62, 0.0), 1.0)

        autoStartNextPhase = defaults.object(forKey: Keys.autoStart) as? Bool ?? true
        notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        playSound = defaults.object(forKey: Keys.playSound) as? Bool ?? false
        isWidgetVisible = defaults.object(forKey: Keys.widgetVisible) as? Bool ?? true

        if let x = defaults.object(forKey: Keys.manualWidgetX) as? Double,
           let y = defaults.object(forKey: Keys.manualWidgetY) as? Double {
            manualWidgetPosition = CGPoint(x: x, y: y)
        } else {
            manualWidgetPosition = nil
        }

        let initialSeconds = max(1, (startWorkMinutes * 60) + startWorkSeconds)
        remainingTimeSeconds = TimeInterval(initialSeconds)
        remainingSeconds = initialSeconds
        pausedTimeSeconds = TimeInterval(initialSeconds)

        startTicker()
        requestNotificationPermissionsIfNeeded()
    }

    var phaseDurationSeconds: Int {
        switch phase {
        case .work:
            return (workMinutes * 60) + workSeconds
        case .breakTime:
            return isLongBreakActive ? longBreakDurationSeconds : shortBreakDurationSeconds
        }
    }

    private var shortBreakDurationSeconds: Int {
        max(1, (breakMinutes * 60) + breakSeconds)
    }

    private var longBreakDurationSeconds: Int {
        max(0, (longBreakMinutes * 60) + longBreakSeconds)
    }

    func tint(for phase: SessionPhase) -> Color {
        switch phase {
        case .work:
            return workTint
        case .breakTime:
            return breakTint
        }
    }

    func nsTint(for phase: SessionPhase) -> NSColor {
        let components = rgbComponents(for: phase)
        return NSColor(
            calibratedRed: components.red,
            green: components.green,
            blue: components.blue,
            alpha: 1.0
        )
    }

    func hexTint(for phase: SessionPhase) -> String {
        let components = rgbComponents(for: phase)
        let red = Int((components.red * 255.0).rounded())
        let green = Int((components.green * 255.0).rounded())
        let blue = Int((components.blue * 255.0).rounded())
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    @discardableResult
    func applyWorkHex(_ value: String) -> Bool {
        guard let (r, g, b) = Self.parseHexColor(value) else { return false }
        workTintRed = r
        workTintGreen = g
        workTintBlue = b
        return true
    }

    @discardableResult
    func applyBreakHex(_ value: String) -> Bool {
        guard let (r, g, b) = Self.parseHexColor(value) else { return false }
        breakTintRed = r
        breakTintGreen = g
        breakTintBlue = b
        return true
    }

    func setWorkTint(_ color: Color) {
        let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? NSColor.systemGreen
        workTintRed = Double(nsColor.redComponent)
        workTintGreen = Double(nsColor.greenComponent)
        workTintBlue = Double(nsColor.blueComponent)
    }

    func setBreakTint(_ color: Color) {
        let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? NSColor.systemBlue
        breakTintRed = Double(nsColor.redComponent)
        breakTintGreen = Double(nsColor.greenComponent)
        breakTintBlue = Double(nsColor.blueComponent)
    }

    func startOrPause() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }

    func start() {
        if isRunning { return }

        let secondsToRun = max(1, pausedTimeSeconds)
        phaseEndDate = Date().addingTimeInterval(secondsToRun)
        isRunning = true
        recalculateRemaining()
    }

    func pause() {
        guard isRunning else { return }

        recalculateRemaining()
        phaseEndDate = nil
        pausedTimeSeconds = max(1, remainingTimeSeconds)
        isRunning = false
    }

    func resetCurrentPhase() {
        isRunning = false
        phaseEndDate = nil
        syncRemainingToCurrentPhase()
    }

    func skipPhase() {
        transitionToNextPhase(triggerNotification: false)
    }

    func completeCurrentPhase() {
        transitionToNextPhase(triggerNotification: true)
    }

    func cancelCurrentCycle() {
        phase = .work
        isLongBreakActive = false
        isRunning = false
        phaseEndDate = nil
        workSessionsSinceLastLongBreak = 0
        syncRemainingToCurrentPhase()
        setCompletionMessage("Focus session canceled")
    }

    func setManualWidgetPosition(_ point: CGPoint) {
        manualWidgetPosition = point
    }

    func resetWidgetPosition() {
        manualWidgetPosition = nil
        corner = .topRight
    }

    func clearManualWidgetPosition() {
        manualWidgetPosition = nil
    }

    private func startTicker() {
        ticker = Timer.publish(every: 0.05, tolerance: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard isRunning else { return }
        recalculateRemaining()
    }

    private func recalculateRemaining() {
        guard let endDate = phaseEndDate else { return }

        let secondsLeft = endDate.timeIntervalSinceNow
        if secondsLeft > 0 {
            remainingTimeSeconds = secondsLeft
            remainingSeconds = max(1, Int(ceil(secondsLeft)))
            pausedTimeSeconds = secondsLeft
            return
        }

        transitionToNextPhase(triggerNotification: true)
    }

    private func transitionToNextPhase(triggerNotification: Bool) {
        let completedPhase = phase
        if completedPhase == .work {
            completedWorkSessions += 1
            workSessionsSinceLastLongBreak += 1
        }

        if completedPhase == .work {
            let shouldUseLongBreak = longBreakEveryWorkSessions > 0
                && longBreakDurationSeconds > 0
                && workSessionsSinceLastLongBreak >= longBreakEveryWorkSessions

            phase = .breakTime
            isLongBreakActive = shouldUseLongBreak
            if shouldUseLongBreak {
                workSessionsSinceLastLongBreak = 0
            }
        } else {
            phase = .work
            isLongBreakActive = false
        }

        phaseEndDate = nil
        isRunning = false
        syncRemainingToCurrentPhase()

        if triggerNotification {
            setCompletionMessage(transitionMessage)
            sendPhaseTransitionNotification()
            onPhaseCompleted?(completedPhase)
        }

        if autoStartNextPhase {
            start()
        }
    }

    private func syncRemainingToCurrentPhase() {
        let fullDuration = max(1, phaseDurationSeconds)
        remainingTimeSeconds = TimeInterval(fullDuration)
        remainingSeconds = fullDuration
        pausedTimeSeconds = TimeInterval(fullDuration)
    }

    private func setCompletionMessage(_ message: String) {
        completionMessage = message

        messageDismissWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.completionMessage = nil
        }
        messageDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2, execute: workItem)
    }

    private func sendPhaseTransitionNotification() {
        guard notificationsEnabled else { return }

        if playSound {
            playTransitionCueSound()
        }

        guard canUseUserNotifications else { return }

        let content = UNMutableNotificationContent()
        let notificationText = transitionNotificationText
        content.title = notificationText.title
        content.body = notificationText.body

        if playSound {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func playTransitionCueSound() {
        let preferredNames = preferredSoundNamesForCurrentTransition
        for name in preferredNames {
            if let sound = NSSound(named: NSSound.Name(name)) {
                sound.play()
                scheduleBeepAccent(
                    count: phase == .work ? 1 : (isLongBreakActive ? 3 : 2),
                    startAfter: 0.18,
                    interval: 0.13
                )
                return
            }
        }

        scheduleBeepAccent(
            count: phase == .work ? 2 : (isLongBreakActive ? 4 : 3),
            startAfter: 0,
            interval: 0.14
        )
    }

    private var preferredSoundNamesForCurrentTransition: [String] {
        if phase == .work {
            return ["Hero", "Glass", "Ping"]
        }
        if isLongBreakActive {
            return ["Funk", "Hero", "Glass", "Ping"]
        }
        return ["Glass", "Ping", "Hero"]
    }

    private func scheduleBeepAccent(count: Int, startAfter: TimeInterval, interval: TimeInterval) {
        guard count > 0 else { return }
        for index in 0..<count {
            let delay = startAfter + (Double(index) * interval)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                NSSound.beep()
            }
        }
    }

    private func requestNotificationPermissionsIfNeeded() {
        guard notificationsEnabled, canUseUserNotifications else { return }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private var canUseUserNotifications: Bool {
        Bundle.main.bundleURL.pathExtension.lowercased() == "app"
    }

    private func markPresetCustomIfNeeded() {
        guard !isApplyingPreset, preset != .custom else { return }
        preset = .custom
    }

    private func applyPreset(_ preset: TimerPreset) {
        guard let config = Self.config(for: preset) else { return }

        isApplyingPreset = true
        workMinutes = config.workMinutes
        workSeconds = config.workSeconds
        breakMinutes = config.breakMinutes
        breakSeconds = config.breakSeconds
        longBreakMinutes = config.longBreakMinutes
        longBreakSeconds = config.longBreakSeconds
        longBreakEveryWorkSessions = config.longBreakEveryWorkSessions
        isApplyingPreset = false

        phase = .work
        isLongBreakActive = false
        isRunning = false
        phaseEndDate = nil
        workSessionsSinceLastLongBreak = 0
        syncRemainingToCurrentPhase()
    }

    private static func config(for preset: TimerPreset) -> PresetConfig? {
        switch preset {
        case .custom:
            return nil
        case .pomodoroClassic:
            return PresetConfig(
                workMinutes: 25,
                workSeconds: 0,
                breakMinutes: 5,
                breakSeconds: 0,
                longBreakMinutes: 30,
                longBreakSeconds: 0,
                longBreakEveryWorkSessions: 4
            )
        case .focus4510:
            return PresetConfig(
                workMinutes: 45,
                workSeconds: 0,
                breakMinutes: 10,
                breakSeconds: 0,
                longBreakMinutes: 0,
                longBreakSeconds: 0,
                longBreakEveryWorkSessions: 0
            )
        }
    }

    private static func parseHexColor(_ raw: String) -> (Double, Double, Double)? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let stripped = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        guard stripped.count == 6, stripped.allSatisfy({ $0.isHexDigit }) else { return nil }

        guard let value = Int(stripped, radix: 16) else { return nil }
        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        return (red, green, blue)
    }

    private func rgbComponents(for phase: SessionPhase) -> (red: Double, green: Double, blue: Double) {
        let components: (Double, Double, Double) = switch phase {
        case .work:
            (workTintRed, workTintGreen, workTintBlue)
        case .breakTime:
            (breakTintRed, breakTintGreen, breakTintBlue)
        }
        return (
            min(max(components.0, 0.0), 1.0),
            min(max(components.1, 0.0), 1.0),
            min(max(components.2, 0.0), 1.0)
        )
    }

    private var transitionMessage: String {
        if phase == .work {
            return "Break is over. Back to work."
        }
        if isLongBreakActive {
            return "Great run. Start your long break."
        }
        return "Focus session done. Time to walk around."
    }

    private var transitionNotificationText: (title: String, body: String) {
        if phase == .work {
            return ("Back to work", "Break ended. Starting your next focus session.")
        }
        if isLongBreakActive {
            return ("Long break time", "You completed a full cycle. Take a longer pause.")
        }
        return ("Time for a break", "Work session finished. Stand up and walk around a bit.")
    }
}
