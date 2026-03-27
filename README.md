# WorkPulse

WorkPulse is a lightweight macOS work-session timer with a floating capsule widget, presets, and break reminders.

## Features

- Floating widget with:
  - countdown + current phase
  - `Start/Pause`
  - `Complete`
  - `X` quit button
  - drag handle
- Menu bar panel with expandable settings
- Presets:
  - Pomodoro (`25:00 / 05:00`, long break `30:00` every 4 sessions)
  - Focus `45:00 / 10:00`
  - Custom
- Adjustable work/break/long-break minutes and seconds
- Color customization (RGB sliders + HEX input)
- Optional notifications and sound
- Screen flash effect when a phase completes

## Requirements

- macOS 13+
- Xcode Command Line Tools (`xcode-select --install`)
- Swift 6 toolchain (Xcode 16+)

## Run From Source

```bash
swift run WorkPulse
```

## Build

```bash
swift build
```

## Create a macOS `.app` Bundle

Use the packaging script:

```bash
scripts/make-app.sh
```

This produces:

```text
dist/WorkPulse.app
```

Install to user Applications:

```bash
scripts/make-app.sh --install-user
```

Install system-wide Applications:

```bash
scripts/make-app.sh --install-system
```

### Custom App Icon (`.icns`)

macOS app bundles use an `.icns` file, not a single PNG.

1. Put your source image anywhere (PNG or JPG, ideally at least `1024x1024`).
2. Generate `assets/AppIcon.icns`:

```bash
scripts/make-icon.sh /path/to/your-icon.png
```

3. Build the app bundle again:

```bash
scripts/make-app.sh
```

`make-app.sh` will automatically embed `assets/AppIcon.icns` into `WorkPulse.app`.

To use a different icon path:

```bash
ICON_SOURCE=/absolute/path/MyIcon.icns scripts/make-app.sh
```

After install, launch with Spotlight or:

```bash
open ~/Applications/WorkPulse.app
```

If you installed system-wide:

```bash
open /Applications/WorkPulse.app
```

## Add to Login Items (Start On Boot)

1. Open `System Settings` -> `General` -> `Login Items`.
2. Click `+`.
3. Select `WorkPulse.app` from `~/Applications` or `/Applications`.

## Notes

- Timer progression is based on end timestamps, so it remains stable across pauses/sleep.
- Notifications require launching from an app bundle (`.app`) for full system behavior.
- Default bundle identifier in the script is `com.tdphucvn.workpulse`. Override by setting `BUNDLE_ID`, for example:

```bash
BUNDLE_ID=com.yourname.workpulse scripts/make-app.sh
```
