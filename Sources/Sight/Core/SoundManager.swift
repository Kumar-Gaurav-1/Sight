import AVFoundation
import AppKit
import AudioToolbox
import os.log

// MARK: - Sound Manager

/// Manages app sounds for break notifications
public final class SoundManager {

    public static let shared = SoundManager()

    // MARK: - Sound Categories

    public enum SoundCategory: String, CaseIterable {
        case nature = "Nature"
        case classic = "Classic"
        case minimal = "Minimal"
        case none = "None"

        public var sounds: [SoundType] {
            switch self {
            case .nature: return [.ocean, .rain, .forest, .wind]
            case .classic: return [.chime, .bell, .gentle, .harp]
            case .minimal: return [.tick, .click, .soft]
            case .none: return [.none]
            }
        }
    }

    // MARK: - Sound Types

    public enum SoundType: String, CaseIterable, Identifiable {
        // Nature sounds
        case ocean = "Ocean Wave"
        case rain = "Gentle Rain"
        case forest = "Forest Birds"
        case wind = "Soft Wind"

        // Classic sounds
        case chime = "Chime"
        case bell = "Bell"
        case gentle = "Gentle"
        case harp = "Harp"

        // Minimal sounds
        case tick = "Tick"
        case click = "Click"
        case soft = "Soft Pop"

        case none = "None"

        public var id: String { rawValue }

        public var icon: String {
            switch self {
            case .ocean: return "water.waves"
            case .rain: return "cloud.rain"
            case .forest: return "leaf"
            case .wind: return "wind"
            case .chime: return "bell"
            case .bell: return "bell.fill"
            case .gentle: return "speaker.wave.1"
            case .harp: return "guitars"
            case .tick: return "metronome"
            case .click: return "hand.tap"
            case .soft: return "circle.fill"
            case .none: return "speaker.slash"
            }
        }

        var systemSound: NSSound.Name? {
            switch self {
            // Nature sounds - mapped to closest available system sounds
            case .ocean: return NSSound.Name("Sosumi")
            case .rain: return NSSound.Name("Purr")
            case .forest: return NSSound.Name("Frog")
            case .wind: return NSSound.Name("Blow")
            // Classic sounds
            case .chime: return NSSound.Name("Tink")
            case .bell: return NSSound.Name("Glass")
            case .gentle: return NSSound.Name("Pop")
            case .harp: return NSSound.Name("Hero")
            // Minimal sounds
            case .tick: return NSSound.Name("Morse")
            case .click: return NSSound.Name("Ping")
            case .soft: return NSSound.Name("Pop")
            case .none: return nil
            }
        }

        public var category: SoundCategory {
            switch self {
            case .ocean, .rain, .forest, .wind: return .nature
            case .chime, .bell, .gentle, .harp: return .classic
            case .tick, .click, .soft: return .minimal
            case .none: return .none
            }
        }
    }

    // MARK: - Properties

    private var currentSound: NSSound?
    private let logger = Logger(subsystem: "com.kumargaurav.Sight.sound", category: "SoundManager")

    public var volume: Float {
        get { Float(PreferencesManager.shared.soundVolume) }
        set { PreferencesManager.shared.soundVolume = Double(newValue) }
    }

    private init() {
        logger.info("SoundManager initialized, volume: \(self.volume)")
    }

    // MARK: - Play Sounds

    /// Play break start sound (uses sound pair mapping)
    public func playBreakStart() {
        guard PreferencesManager.shared.breakStartSoundEnabled else { return }
        let pair = PreferencesManager.shared.soundPair
        let selectedType = soundTypeForPair(pair, isStart: true)
        play(selectedType)
    }

    /// Play break end sound (uses sound pair mapping)
    public func playBreakEnd() {
        guard PreferencesManager.shared.breakEndSoundEnabled else { return }
        let pair = PreferencesManager.shared.soundPair
        let selectedType = soundTypeForPair(pair, isStart: false)
        play(selectedType)
    }

    /// Play break reminder sound (countdown notification)
    public func playBreakReminder() {
        guard PreferencesManager.shared.breakReminderSoundEnabled else { return }
        play(.tick)  // Use tick sound for countdown reminder
    }

    /// Map sound pair name to actual sound types
    private func soundTypeForPair(_ pair: String, isStart: Bool) -> SoundType {
        switch pair {
        case "Default":
            return isStart ? .chime : .bell
        case "Gentle":
            return isStart ? .gentle : .soft
        case "Chime":
            return isStart ? .chime : .harp
        case "Bell":
            return isStart ? .bell : .chime
        case "Nature":
            return isStart ? .ocean : .rain
        case "Minimal":
            return isStart ? .tick : .click
        default:
            return isStart ? .chime : .bell
        }
    }

    /// Play nudge sound (uses wellness volume)
    public func playNudge() {
        // Play nudge if either posture or blink sound is enabled
        let postureSoundOn = PreferencesManager.shared.postureSoundEnabled
        let blinkSoundOn = PreferencesManager.shared.blinkSoundEnabled

        // At least one must be enabled
        guard postureSoundOn || blinkSoundOn else {
            logger.debug("Both posture and blink sounds disabled, skipping nudge sound")
            return
        }

        let selectedType = SoundType(rawValue: PreferencesManager.shared.nudgeSoundType) ?? .gentle
        play(selectedType, useWellnessVolume: true)
    }

    /// Play focus start sound
    public func playFocusStart() {
        play(.harp)
    }

    /// Play focus end sound
    public func playFocusEnd() {
        play(.ocean)
    }

    /// Play smart pause sound (when timer is auto-paused)
    public func playSmartPause() {
        guard PreferencesManager.shared.smartPauseSoundEnabled else { return }
        play(.soft)  // Subtle sound for pause
    }

    /// Play idle resume sound (when returning from idle)
    public func playIdleResume() {
        guard PreferencesManager.shared.activeAfterIdleSoundEnabled else { return }
        play(.gentle)  // Gentle notification sound
    }

    /// Play milestone celebration sound
    public func playCelebration() {
        // Play a special sound for achievements
        if let sound = NSSound(named: NSSound.Name("Funk")) {
            currentSound?.stop()
            sound.volume = volume
            sound.play()
            currentSound = sound
        } else {
            play(.bell)
        }
    }

    /// Play specific sound type
    public func play(_ type: SoundType, useWellnessVolume: Bool = false) {
        guard type != .none else {
            logger.debug("Sound type is .none, skipping")
            return
        }

        guard let soundName = type.systemSound else {
            logger.warning("No system sound for type: \(type.rawValue)")
            playDefaultAlert()
            return
        }

        logger.info("Playing sound: \(type.rawValue) -> \(soundName)")

        // Use wellness volume or standard volume, clamped to valid range
        let rawVolume =
            useWellnessVolume
            ? Float(PreferencesManager.shared.wellnessReminderVolume)
            : volume
        let soundVolume = min(max(rawVolume, 0.0), 1.0)

        // Try to load NSSound
        if let sound = NSSound(named: soundName) {
            // Stop current sound
            currentSound?.stop()

            // Play new sound
            sound.volume = soundVolume
            let success = sound.play()
            currentSound = sound

            if success {
                logger.debug("Sound playing successfully")
            } else {
                logger.warning("NSSound.play() returned false, using fallback")
                playDefaultAlert()
            }
        } else {
            // NSSound failed - use system alert as fallback
            logger.warning("NSSound not found: \(soundName), using fallback")
            playDefaultAlert()
        }
    }

    /// Play default system alert sound as fallback
    private func playDefaultAlert() {
        logger.info("Playing default system alert")
        AudioServicesPlaySystemSound(1005)  // Default alert sound
    }

    /// Preview a sound (for settings)
    public func preview(_ type: SoundType) {
        play(type)
    }

    /// Stop any playing sound
    public func stop() {
        currentSound?.stop()
        currentSound = nil
    }

    // MARK: - Available Sounds

    /// Get all available sounds grouped by category
    public func soundsByCategory() -> [(category: SoundCategory, sounds: [SoundType])] {
        return SoundCategory.allCases.filter { $0 != .none }.map { category in
            (category: category, sounds: category.sounds)
        }
    }
}
