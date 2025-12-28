# Sight 👁

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0+-blue.svg" alt="macOS 13.0+">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License">
</p>

A premium macOS menu bar app for eye care and break reminders, implementing the scientifically-backed **20-20-20 rule** to protect your vision during extended screen time.

## ✨ Features

### Core Functionality
- **🕐 20-20-20 Rule**: Every 20 minutes, look at something 20 feet away for 20 seconds
- **⏰ Customizable Timers**: Adjust work intervals (10-60 min), break durations (20-300 sec)
- **🔔 Pre-Break Warnings**: Configurable countdown before breaks start
- **⏭️ Skip & Postpone**: Delay breaks by 5 minutes when needed

### Smart Features
- **📅 Meeting Detection**: Auto-pauses during calendar meetings
- **🎬 Fullscreen Detection**: Pauses during videos, presentations, and games
- **💻 Screen Recording Detection**: Won't interrupt during recordings
- **🌙 Working Hours**: Only remind during your configured work schedule
- **😴 Idle Detection**: Pauses when you're away from your computer

### Wellness Reminders
- **👁 Blink Reminders**: Gentle nudges to blink (reduces dry eyes)
- **🧘 Posture Reminders**: Periodic reminders to sit up straight
- **🎵 Sound Effects**: Calming audio notifications

### Premium UI
- **🎨 Beautiful Break Overlay**: Full-screen calming gradient with breathing guide
- **📊 Statistics Dashboard**: Track break streaks and daily adherence
- **🏆 Achievements**: Earn badges for healthy habits
- **⌨️ Global Shortcuts**: Control from anywhere with keyboard shortcuts

## 📸 Screenshots

| Menu Bar | Break Overlay | Preferences |
|----------|---------------|-------------|
| Quick access dashboard | Calming full-screen break | Customizable settings |

## 📋 Requirements

- **macOS 13.0+** (Ventura or later)
- **Xcode 15.0+** (for development)
- **Swift 5.9+**

## 🚀 Installation

### Using Swift Package Manager

```bash
# Clone the repository
git clone https://github.com/piyushpratap2/Sight.git
cd Sight

# Build
swift build

# Run
swift run Sight
```

### Using Xcode

```bash
# Open in Xcode
open Package.swift
```

Then press `⌘R` to build and run.

## 📁 Project Structure

```
Sight/
├── Package.swift                    # Swift Package manifest
├── Sources/Sight/
│   ├── App/                         # Main app entry & delegate
│   │   ├── SightApp.swift          # @main entry point
│   │   ├── AppDelegate.swift       # App lifecycle management
│   │   ├── NotificationManager.swift # System notifications
│   │   └── SightOnboardingView.swift # First-run onboarding
│   ├── Core/                        # Business logic
│   │   ├── TimerStateMachine.swift # State machine for timer
│   │   ├── TimerConfiguration.swift # Timer settings
│   │   ├── SoundManager.swift      # Audio playback
│   │   ├── MeetingDetector.swift   # Calendar integration
│   │   ├── WorkHoursManager.swift  # Schedule management
│   │   ├── IdleDetector.swift      # User activity detection
│   │   └── GamificationManager.swift # Achievements system
│   ├── MenuBar/                     # Menu bar interface
│   │   ├── MenuBarController.swift # Status bar item
│   │   ├── MenuBarViewModel.swift  # UI state management
│   │   └── SightMenuBarView.swift  # SwiftUI dashboard
│   ├── Preferences/                 # Settings screens
│   │   ├── PreferencesManager.swift # Settings storage
│   │   ├── SightPreferencesView.swift # Main preferences
│   │   ├── SightGeneralView.swift  # General settings
│   │   ├── SightBreaksView.swift   # Break configuration
│   │   └── ...                     # Additional preference views
│   ├── Overlay/                     # Break overlay
│   │   ├── BreakOverlayView.swift  # Full-screen overlay
│   │   └── SightBreakHUDView.swift # Break countdown UI
│   ├── Nudges/                      # Micro-nudges system
│   │   └── MicroNudges.swift       # Blink/posture reminders
│   ├── SmartPause/                  # Smart pause detection
│   │   └── SmartPause.swift        # Meeting/fullscreen detection
│   ├── State/                       # Statistics tracking
│   │   └── AdherenceManager.swift  # Break history & streaks
│   ├── UI/                          # Shared UI components
│   │   ├── BlinkNudgeView.swift    # Blink reminder overlay
│   │   ├── PostureNudgeView.swift  # Posture reminder overlay
│   │   └── NudgeOverlayWindow.swift # Floating nudge window
│   ├── Input/                       # User input handling
│   │   └── ShortcutManager.swift   # Global keyboard shortcuts
│   └── Renderer/                    # Rendering abstraction
│       └── Renderer.swift          # Overlay rendering API
└── Tests/SightTests/               # Unit tests
```

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘ + ⌃ + P` | Pause / Resume timer |
| `⌘ + ⌃ + B` | Take break now |
| `⌘ + ⌃ + S` | Skip current break |
| `⌘ + ⌃ + ,` | Open preferences |
| `Escape` | Dismiss break overlay |

## 🖱️ Menu Bar Usage

- **Click**: Open dashboard
- **Option + Click**: Toggle pause/resume
- **Right-click**: Context menu

### Status Icons
| Icon | State |
|------|-------|
| 👁 | Idle / Stopped |
| 👁 (filled) | Working |
| 🔔 (pulsing) | Pre-break warning |
| ☕ | On break |
| ⏸️ | Paused |

## ⚙️ Configuration

### Default Settings (20-20-20 Rule)
| Setting | Default |
|---------|---------|
| Work Interval | 20 minutes |
| Break Duration | 20 seconds |
| Pre-break Warning | 10 seconds |

### Available Profiles
- **Deep Work**: 25 min work, 30 sec break
- **Relaxed**: 15 min work, 20 sec break  
- **Intense Focus**: 45 min work, 60 sec break
- **Custom**: Configure your own

## 🔒 Privacy

Sight is designed with privacy first:
- ✅ **No data collection** - All data stays on your device
- ✅ **No network requests** - Works completely offline
- ✅ **Calendar access** - Only checks if you're in a meeting (no event details read)
- ✅ **Accessibility access** - Only used for global shortcuts

## 🔧 Permissions Required

| Permission | Purpose |
|------------|---------|
| Notifications | Break reminders |
| Accessibility | Global keyboard shortcuts |
| Calendar (Optional) | Meeting detection |

## 📈 Performance

| Metric | Target |
|--------|--------|
| CPU at idle | < 2% |
| Memory usage | < 50 MB |
| Battery impact | Negligible |

### Optimizations
- Event-driven architecture (no polling)
- Combine publishers for reactive updates
- Lazy UI updates (only on state change)
- Metal-accelerated overlay rendering

## 🧪 Testing

```bash
# Run all tests
swift test

# Run with verbose output
swift test --verbose
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the 20-20-20 rule recommended by ophthalmologists
- Built with SwiftUI and Combine
- Uses SF Symbols for iconography

---

<p align="center">
  Made with ❤️ for healthier screen time
</p>
