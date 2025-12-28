import AVFoundation
import AppKit

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
            case .ocean: return NSSound.Name("Submarine")
            case .rain: return NSSound.Name("Sosumi")
            case .forest: return NSSound.Name("Frog")
            case .wind: return NSSound.Name("Breeze")
            case .chime: return NSSound.Name("Tink")
            case .bell: return NSSound.Name("Glass")
            case .gentle: return NSSound.Name("Pop")
            case .harp: return NSSound.Name("Hero")
            case .tick: return NSSound.Name("Morse")
            case .click: return NSSound.Name("Ping")
            case .soft: return NSSound.Name("Purr")
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

    public var volume: Float {
        get { Float(PreferencesManager.shared.soundVolume) }
        set { PreferencesManager.shared.soundVolume = Double(newValue) }
    }

    private init() {}

    // MARK: - Play Sounds

    /// Play break start sound
    public func playBreakStart() {
        guard PreferencesManager.shared.breakStartSoundEnabled else { return }
        play(.chime)
    }

    /// Play break end sound
    public func playBreakEnd() {
        guard PreferencesManager.shared.breakEndSoundEnabled else { return }
        play(.bell)
    }

    /// Play nudge sound
    public func playNudge() {
        play(.gentle)
    }

    /// Play focus start sound
    public func playFocusStart() {
        play(.harp)
    }

    /// Play focus end sound
    public func playFocusEnd() {
        play(.ocean)
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
    public func play(_ type: SoundType) {
        guard type != .none,
            let soundName = type.systemSound,
            let sound = NSSound(named: soundName)
        else {
            return
        }

        // Stop current sound
        currentSound?.stop()

        // Play new sound
        sound.volume = volume
        sound.play()
        currentSound = sound
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
