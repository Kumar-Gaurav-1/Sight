import SwiftUI

// MARK: - Achievements View

/// Display badges and achievements with progress
struct SightAchievementsView: View {
    @ObservedObject private var gamification = GamificationManager.shared
    @ObservedObject private var adherence = AdherenceManager.shared
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Stats row
                    statsRow
                    
                    // Badges grid
                    badgesSection
                }
                .padding(SightTheme.sectionSpacing)
            }
        }
        .background(SightTheme.background)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Achievements")
                    .font(SightTheme.titleFont)
                    .foregroundColor(.white)
                
                Text("Earn badges for healthy habits")
                    .font(.system(size: 13))
                    .foregroundColor(SightTheme.secondaryText)
            }
            
            Spacer()
            
            // Points display
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(gamification.totalPoints)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("pts")
                    .font(.system(size: 12))
                    .foregroundColor(SightTheme.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
        }
        .padding(.horizontal, SightTheme.sectionSpacing)
        .padding(.top, SightTheme.sectionSpacing)
        .padding(.bottom, 16)
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: 12) {
            AchievementStatCard(
                icon: "trophy.fill",
                value: "\(gamification.unlockedCount)/\(gamification.totalBadges)",
                label: "Badges",
                color: .yellow
            )
            
            AchievementStatCard(
                icon: "flame.fill",
                value: "\(adherence.currentStreak)",
                label: "Day Streak",
                color: .orange
            )
            
            AchievementStatCard(
                icon: "checkmark.seal.fill",
                value: "\(adherence.totalBreaksCompleted)",
                label: "Total Breaks",
                color: SightTheme.success
            )
        }
    }
    
    // MARK: - Badges Section
    
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Badges")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(gamification.badges) { badge in
                    BadgeCard(badge: badge)
                }
            }
        }
    }
}

// MARK: - Achievement Stat Card

struct AchievementStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(SightTheme.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(SightTheme.cardBackground)
        )
    }
}

// MARK: - Badge Card

struct BadgeCard: View {
    let badge: Badge
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Text(badge.icon)
                .font(.system(size: 40))
                .grayscale(badge.isUnlocked ? 0 : 1)
                .opacity(badge.isUnlocked ? 1 : 0.4)
            
            // Name
            Text(badge.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(badge.isUnlocked ? .white : SightTheme.tertiaryText)
                .lineLimit(1)
            
            // Description or hint
            Text(badge.isUnlocked ? badge.description : badge.hint)
                .font(.system(size: 10))
                .foregroundColor(SightTheme.tertiaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 28)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(badge.isUnlocked ? SightTheme.cardBackground : Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    badge.isUnlocked ? Color.yellow.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .scaleEffect(isHovered ? 1.05 : 1)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    SightAchievementsView()
        .frame(width: 700, height: 600)
}
