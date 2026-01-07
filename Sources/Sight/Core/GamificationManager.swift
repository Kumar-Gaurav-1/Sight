import Combine
import Foundation
import os.log

// MARK: - Badge

/// Achievement badge that can be unlocked
public struct Badge: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let icon: String
    public let description: String
    public let hint: String
    public var isUnlocked: Bool
    public var unlockedDate: Date?

    public init(
        id: String, name: String, icon: String, description: String, hint: String,
        isUnlocked: Bool = false, unlockedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.hint = hint
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
    }
}

// MARK: - Gamification Manager

/// Manages achievements, badges, and streaks
public final class GamificationManager: ObservableObject {
    public static let shared = GamificationManager()

    @Published public private(set) var badges: [Badge] = []
    @Published public private(set) var totalPoints: Int = 0
    @Published public private(set) var newlyUnlockedBadge: Badge?

    private let defaults = UserDefaults.standard
    private let logger = Logger(subsystem: "com.kumargaurav.Sight.app", category: "Gamification")
    private var cancellables = Set<AnyCancellable>()

    // SECURITY: Generation counter for badge display race protection
    private var badgeDisplayGeneration = 0

    private let badgesKey = "unlockedBadges"
    private let pointsKey = "totalPoints"

    // MARK: - Badge Definitions

    private static let allBadgeDefinitions: [Badge] = [
        Badge(
            id: "first_break",
            name: "First Break",
            icon: "🎉",
            description: "Completed your first break",
            hint: "Complete your first break"
        ),
        Badge(
            id: "streak_3",
            name: "Streak Starter",
            icon: "🔥",
            description: "Maintained a 3-day streak",
            hint: "Take breaks for 3 days in a row"
        ),
        Badge(
            id: "streak_7",
            name: "Week Warrior",
            icon: "💪",
            description: "Maintained a 7-day streak",
            hint: "Take breaks for a full week"
        ),
        Badge(
            id: "streak_30",
            name: "Marathon",
            icon: "🏆",
            description: "Maintained a 30-day streak",
            hint: "Keep going for a whole month"
        ),
        Badge(
            id: "breaks_10",
            name: "Getting Started",
            icon: "🌱",
            description: "Completed 10 breaks",
            hint: "Complete 10 breaks total"
        ),
        Badge(
            id: "breaks_50",
            name: "Halfway Hero",
            icon: "🌟",
            description: "Completed 50 breaks",
            hint: "Complete 50 breaks total"
        ),
        Badge(
            id: "breaks_100",
            name: "Century Club",
            icon: "💯",
            description: "Completed 100 breaks",
            hint: "Complete 100 breaks total"
        ),
        Badge(
            id: "perfect_day",
            name: "Perfect Day",
            icon: "⭐",
            description: "Achieved 100% daily score",
            hint: "Complete all scheduled breaks in a day"
        ),
        Badge(
            id: "early_bird",
            name: "Early Bird",
            icon: "🐤",
            description: "Took a break before 7 AM",
            hint: "Take a break early in the morning"
        ),
        Badge(
            id: "night_owl",
            name: "Night Owl",
            icon: "🦉",
            description: "Took a break after 9 PM",
            hint: "Take a break late in the evening"
        ),
        Badge(
            id: "weekend_warrior",
            name: "Weekend Warrior",
            icon: "🎮",
            description: "Took breaks on a weekend",
            hint: "Stay healthy even on weekends"
        ),
        Badge(
            id: "profile_master",
            name: "Profile Master",
            icon: "🎯",
            description: "Used all break profiles",
            hint: "Try all different break profiles"
        ),
    ]

    // MARK: - Initialization

    private init() {
        loadBadges()
        loadPoints()
        setupObservers()
    }

    private func loadBadges() {
        var loadedBadges = Self.allBadgeDefinitions

        if let data = defaults.data(forKey: badgesKey),
            let unlockedIds = try? JSONDecoder().decode([String: Date].self, from: data)
        {
            // SECURITY: Validate each badge ID exists in known definitions before applying
            let validBadgeIds = Set(loadedBadges.map { $0.id })
            for i in loadedBadges.indices {
                let badgeId = loadedBadges[i].id
                if let unlockedDate = unlockedIds[badgeId], validBadgeIds.contains(badgeId) {
                    loadedBadges[i].isUnlocked = true
                    loadedBadges[i].unlockedDate = unlockedDate
                }
            }
        }

        badges = loadedBadges
    }

    private func loadPoints() {
        totalPoints = defaults.integer(forKey: pointsKey)
    }

    private func saveBadges() {
        var unlockedIds: [String: Date] = [:]
        for badge in badges where badge.isUnlocked {
            unlockedIds[badge.id] = badge.unlockedDate ?? Date()
        }

        if let data = try? JSONEncoder().encode(unlockedIds) {
            defaults.set(data, forKey: badgesKey)
        }
    }

    private func savePoints() {
        defaults.set(totalPoints, forKey: pointsKey)
    }

    private func setupObservers() {
        // Observe break completions
        AdherenceManager.shared.$todayStats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkAchievements()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    /// Called when a break is completed
    public func onBreakCompleted() {
        addPoints(10)
        checkAchievements()
    }

    /// Add points
    public func addPoints(_ points: Int) {
        totalPoints += points
        savePoints()
    }

    /// Get unlocked badge count
    public var unlockedCount: Int {
        badges.filter { $0.isUnlocked }.count
    }

    /// Get total badge count
    public var totalBadges: Int {
        badges.count
    }

    // MARK: - Achievement Checking

    public func checkAchievements() {
        let adherence = AdherenceManager.shared
        let stats = adherence.todayStats
        let streak = adherence.currentStreak
        let totalBreaks = adherence.totalBreaksCompleted

        // First break
        if totalBreaks >= 1 {
            unlockBadge(id: "first_break")
        }

        // Break count badges
        if totalBreaks >= 10 {
            unlockBadge(id: "breaks_10")
        }
        if totalBreaks >= 50 {
            unlockBadge(id: "breaks_50")
        }
        if totalBreaks >= 100 {
            unlockBadge(id: "breaks_100")
        }

        // Streak badges
        if streak >= 3 {
            unlockBadge(id: "streak_3")
        }
        if streak >= 7 {
            unlockBadge(id: "streak_7")
        }
        if streak >= 30 {
            unlockBadge(id: "streak_30")
        }

        // Perfect day
        if stats.dailyScore >= 100 && stats.breaksCompleted > 0 {
            unlockBadge(id: "perfect_day")
        }

        // Time-based badges
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 7 && stats.breaksCompleted > 0 {
            unlockBadge(id: "early_bird")
        }
        if hour >= 21 && stats.breaksCompleted > 0 {
            unlockBadge(id: "night_owl")
        }

        // Weekend badge
        let weekday = Calendar.current.component(.weekday, from: Date())
        if (weekday == 1 || weekday == 7) && stats.breaksCompleted > 0 {
            unlockBadge(id: "weekend_warrior")
        }
    }

    private func unlockBadge(id: String) {
        guard let index = badges.firstIndex(where: { $0.id == id }),
            !badges[index].isUnlocked
        else {
            return
        }

        badges[index].isUnlocked = true
        badges[index].unlockedDate = Date()
        newlyUnlockedBadge = badges[index]

        // SECURITY: Increment generation to prevent race conditions with multiple badge unlocks
        badgeDisplayGeneration += 1
        let currentGeneration = badgeDisplayGeneration

        addPoints(50)  // Bonus for badge
        saveBadges()

        logger.info("Badge unlocked: \(id)")

        // Clear the notification after a delay, only if generation matches
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self, self.badgeDisplayGeneration == currentGeneration else { return }
            self.newlyUnlockedBadge = nil
        }
    }

    /// Reset all gamification data
    public func resetAll() {
        badges = Self.allBadgeDefinitions
        totalPoints = 0
        saveBadges()
        savePoints()
    }
}
