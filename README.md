# 🚨 Hardcore Alarm for macOS

A production-grade, native macOS alarm application designed specifically for **extremely heavy sleepers**.

Built with **Swift 6**, **SwiftUI**, **AppKit**, and **AVFoundation**, Hardcore Alarm makes waking up genuinely difficult. You cannot dismiss alarms through a casual keystroke, closing a window, or interacting with a simple button. To silence the system, you must engage your brain, solve rigorous cognitive challenges, and prove you are actually awake.

---

## ✨ Features at a Glance

### 1. Full-Screen Non-Dismissible Takeover
- Spans the active display at `.screenSaver` system window level.
- Cannot be closed, minimized, or dismissed without completing the required challenge gauntlet.
- Flashing pulse indicators, live real-time digital clock, and alarm metadata.

### 2. Multi-Step Challenge Gauntlet
Configure single or multi-tier sequential challenges that must be solved under high-stakes acoustic pressure:
- 🧮 **Math Challenge**: 4 difficulty tiers (Easy `12 + 7` to Insane `(18 × 4) + (42 ÷ 6)`). Incorrect answers trigger immediate penalty questions!
- 🧠 **Memory Sequence**: Visual memory sequence playback on a 4x4 interactive matrix (4 to 10 steps).
- ⌨️ **Typing Challenge**: Type rigorous motivational and philosophical wake-up quotes with real-time character-by-character accuracy, backspace tracking, and WPM calculation.
- 🧩 **Pattern Recognition**: Memorize a complex matrix pattern within a strict countdown and reproduce it accurately.
- ⛓️ **Multi-Step Pipeline**: Chain multiple challenge types together in sequence.

### 3. Anti-Sleep Post-Wake Verification
Waking up is only half the battle. To prevent immediate relapse into sleep:
- **Two-Stage Verification Window**: Automatically schedules post-wake check-ins at 5 and 10 minutes after alarm dismissal.
- **2-Second Hold-to-Confirm Modal**: Requires active tactile engagement to confirm wakefulness.
- **Nuclear Re-Alarm Penalty**: If you fail to verify before the countdown expires, the system triggers a **Nuclear Re-Alarm** at 100% volume, disabling gradual volume ramping and locking out snooze.

### 4. Zero-Asset Procedural Audio Engine
Synthesizes 7 piercing alarm waveforms programmatically from raw PCM byte streams:
1. **Emergency Siren**: Dual-frequency warble (800 Hz – 1,200 Hz sweep)
2. **Industrial Klaxon**: Harsh dual square wave (440 Hz + 445 Hz acoustic beating)
3. **Electronic Warning**: Rapid alternating dual-tone (1,500 Hz / 2,200 Hz)
4. **Tactical Beeping**: High-priority pulsing beeps (2,800 Hz)
5. **Mechanical Bell**: Damped metallic resonance with authentic acoustic overtone series
6. **Nuclear Klaxon**: Low-frequency piercing saw/square waveform (350 Hz)
7. **Sub-Bass Pulse**: Low-end physical resonance pulse (55 Hz)
- **Smooth Volume Ramping**: Configurable from 5 to 60 seconds.
- **AVSpeechSynthesizer Announcements**: Spoken voice announces the alarm title, current time, and wake-up prompt alongside the synthesized siren.

### 5. Power & Sleep Management
- **Wake Lock Protection**: Uses macOS `IOPMAssertionCreateWithName` (`kIOPMAssertionTypePreventUserIdleDisplaySleep` & `kIOPMAssertionTypePreventUserIdleSystemSleep`) to ensure the display stays on and the Mac stays awake while an alarm is firing.
- **Sleep/Wake Drift Detection**: Observes `NSWorkspace.willSleepNotification` and `NSWorkspace.didWakeNotification`. If the Mac wakes after a scheduled alarm time, it immediately catches up and fires the missed alarm.

### 6. Linear / Raycast-Inspired Dark Interface
- Deep obsidian and charcoal background palette (`#0B0C10`, `#14161D`) with safety amber (`#FF9500`) and emergency red (`#FF3B30`) accents.
- Live dashboard with real-time digital clock, animated countdown to next alarm, and quick preset activation.
- Alarms list with filtering (All, Active, Weekdays, Weekends), one-click sound previews, and toggle controls.
- Comprehensive Statistics & Analytics powered by **Swift Charts** (consistency scores, streak tracking, challenge completion times, and dismissal logs).
- Native **macOS Menu Bar Extra** with live status, upcoming alarm countdown, and a 5-second test alarm trigger.

---

## 🏗️ Architecture & Technology Stack

- **Language**: Swift 6 (Strict Concurrency & Region Isolation compliant)
- **UI Framework**: SwiftUI + AppKit windowing
- **Audio**: AVFoundation (`AVAudioPlayer`, `AVSpeechSynthesizer`, pure PCM generator)
- **Power**: IOKit (`IOPMLib`)
- **System**: UserNotifications, ServiceManagement (`SMAppService`)
- **Analytics**: Swift Charts
- **Persistence**: Atomic local JSON storage in `~/Library/Application Support/com.hardcore.HardcoreAlarm/` (100% offline, zero tracking, zero accounts).

```
Alarm/
├── Package.swift                    # Swift Package Manager manifest
├── build_app.sh                     # Automated release packaging script
├── HardcoreAlarm.app/               # Compiled, signed macOS application bundle
├── HardcoreAlarm.xcodeproj/         # Xcode project file
├── Resources/
│   ├── AppIcon.icns                 # Multi-resolution macOS application icon
│   └── Info.plist                   # App bundle manifest
├── Scripts/
│   ├── generate_app_icon.swift      # CoreGraphics icon generator
│   └── generate_xcodeproj.py        # Xcode project generator
└── Sources/
    ├── HardcoreAlarmCore/           # Core library target
    │   ├── Models/                  # Alarm, Preset, Challenge, Settings models
    │   ├── Core/                    # Audio, Scheduler, Power, Notifications, Persistence
    │   └── Challenges/              # Math, Memory, Typing, Pattern engines
    ├── HardcoreAlarmApp/            # SwiftUI macOS Application
    │   ├── HardcoreAlarmApp.swift   # Main app entry point & AppDelegate
    │   ├── MenuBarController.swift  # NSStatusItem menu bar extra
    │   ├── WindowManager.swift      # High-priority takeover window controller
    │   └── UI/                      # Views, Theme, Challenge views, Components
    └── TestRunner/                  # Automated test binary (37 test assertions)
```

---

## 🚀 Getting Started

### Prerequisites
- macOS 14.0 (Sonoma) or newer
- Apple Silicon Mac (M1, M2, M3, M4 or newer)
- Xcode 15+ or Apple Command Line Tools

### Quick Run
You can launch the pre-compiled, codesigned application directly:
```bash
open HardcoreAlarm.app
```

### Building from Source
To compile an optimized release build and package the `.app` bundle:
```bash
./build_app.sh
```

### Running Automated Tests
Hardcore Alarm features a standalone test suite verifying all challenge engines, scheduler calculations, mistake penalties, and verification state machines:
```bash
swift run TestRunner
```
*Output: `🎉 ALL TESTS PASSED! (37/37 tests)`*

### Opening in Xcode
Double-click `HardcoreAlarm.xcodeproj` or open via terminal:
```bash
open HardcoreAlarm.xcodeproj
```
You can also open `Package.swift` directly in Xcode (`open Package.swift`).

---

## ⚙️ macOS Power Management Notes & Limitations

- **Display & System Sleep**: When an alarm fires, the app acquires an active IOKit assertion preventing sleep while you solve the challenges.
- **Closed Clamshell Mode**: Under macOS security architecture, a MacBook with its lid closed and not connected to external power/display enters deep sleep (S3/hibernation). To ensure alarms sound reliably while asleep, connect your MacBook to power or leave the display open.
- **Permissions**: Notification permissions are requested on first launch to allow banner alerts alongside the audio engine.

---

## 🔒 Privacy & Offline Commitment

Hardcore Alarm is **100% local and offline**.
- No telemetry or network requests.
- No analytics trackers or external SDKs.
- All alarm configurations and statistics remain exclusively on your device.
