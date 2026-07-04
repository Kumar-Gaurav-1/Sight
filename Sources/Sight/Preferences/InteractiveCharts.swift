import SwiftUI

// MARK: - Interactive Charts for Statistics

// MARK: - Wellness Gauge View

/// Animated circular gauge showing wellness score
struct WellnessGaugeView: View {
    let score: Double  // 0-100
    let animate: Bool

    @State private var animatedScore: Double = 0

    private var scoreColor: Color {
        if score >= 80 { return SightTheme.success }
        if score >= 60 { return SightTheme.accent }
        if score >= 40 { return SightTheme.warning }
        return SightTheme.danger
    }

    private var scoreGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                SightTheme.danger,
                SightTheme.warning,
                SightTheme.accent,
                SightTheme.success,
            ]),
            center: .center,
            startAngle: .degrees(135),
            endAngle: .degrees(405)
        )
    }

    var body: some View {
        ZStack {
            // Background arc
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(
                    Color.white.opacity(0.1),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(135))

            // Progress arc
            Circle()
                .trim(from: 0, to: animate ? CGFloat(animatedScore / 100) * 0.75 : 0)
                .stroke(
                    scoreColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(135))
                .shadow(color: scoreColor.opacity(0.5), radius: 4)

            // Score display
            VStack(spacing: 2) {
                Text(String(format: "%.0f", animatedScore))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Wellness")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(SightTheme.tertiaryText)
            }
        }
        .frame(width: 120, height: 120)
        .onAppear {
            if animate {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                    animatedScore = score
                }
            } else {
                animatedScore = score
            }
        }
        .onChange(of: score) { newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animatedScore = newValue
            }
        }
    }
}

// MARK: - Activity Heatmap View

/// 7-day × hourly activity heatmap
struct ActivityHeatmapView: View {
    let hourlyDistribution: [Int: Int]  // hour (0-23) -> count
    let animate: Bool

    private let columns = 7
    private let hours = Array(6..<22)  // 6 AM to 10 PM

    @State private var selectedHour: Int?
    @State private var isAnimated = false

    private var maxValue: Int {
        max(1, hourlyDistribution.values.max() ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Hour labels
            HStack(spacing: 0) {
                Text(" ")
                    .frame(width: 30)

                ForEach(hours, id: \.self) { hour in
                    if hour % 3 == 0 {
                        Text(hourLabel(hour))
                            .font(.system(size: 9))
                            .foregroundColor(SightTheme.tertiaryText)
                            .frame(maxWidth: .infinity)
                    } else {
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            // Heatmap grid
            HStack(spacing: 4) {
                // Hour axis
                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(hours, id: \.self) { hour in
                        if hour % 4 == 0 {
                            Text(hourLabel(hour))
                                .font(.system(size: 9))
                                .foregroundColor(SightTheme.tertiaryText)
                        } else {
                            Text("")
                                .font(.system(size: 9))
                        }
                    }
                }
                .frame(width: 30)

                // Grid cells
                LazyHGrid(
                    rows: Array(repeating: GridItem(.fixed(16), spacing: 2), count: hours.count),
                    spacing: 2
                ) {
                    ForEach(hours, id: \.self) { hour in
                        HeatmapCell(
                            value: hourlyDistribution[hour] ?? 0,
                            maxValue: maxValue,
                            isSelected: selectedHour == hour,
                            animate: isAnimated
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedHour = selectedHour == hour ? nil : hour
                            }
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 12) {
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundColor(SightTheme.tertiaryText)

                HStack(spacing: 2) {
                    ForEach(0..<5) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(intensityColor(Double(level) / 4.0))
                            .frame(width: 12, height: 12)
                    }
                }

                Text("More")
                    .font(.system(size: 9))
                    .foregroundColor(SightTheme.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // Selected hour info
            if let hour = selectedHour {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(SightTheme.accent)
                    Text("\(hourLabel(hour)): \(hourlyDistribution[hour] ?? 0) breaks")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(SightTheme.cardBackground)
                .cornerRadius(8)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .onAppear {
            if animate {
                withAnimation(.easeOut(duration: 0.5)) {
                    isAnimated = true
                }
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }

    private func intensityColor(_ intensity: Double) -> Color {
        if intensity < 0.1 {
            return Color.white.opacity(0.05)
        } else if intensity < 0.3 {
            return SightTheme.accent.opacity(0.3)
        } else if intensity < 0.6 {
            return SightTheme.accent.opacity(0.6)
        } else if intensity < 0.8 {
            return SightTheme.success.opacity(0.7)
        } else {
            return SightTheme.success
        }
    }
}

struct HeatmapCell: View {
    let value: Int
    let maxValue: Int
    let isSelected: Bool
    let animate: Bool

    @State private var isAnimated = false

    private var intensity: Double {
        guard maxValue > 0 else { return 0 }
        return Double(value) / Double(maxValue)
    }

    private var cellColor: Color {
        if intensity < 0.1 {
            return Color.white.opacity(0.05)
        } else if intensity < 0.3 {
            return SightTheme.accent.opacity(0.3)
        } else if intensity < 0.6 {
            return SightTheme.accent.opacity(0.6)
        } else if intensity < 0.8 {
            return SightTheme.success.opacity(0.7)
        } else {
            return SightTheme.success
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(cellColor)
            .frame(width: 16, height: 16)
            .scaleEffect(isAnimated ? 1 : 0.5)
            .opacity(isAnimated ? 1 : 0)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1)
            )
            .onAppear {
                if animate {
                    withAnimation(
                        .spring(response: 0.4, dampingFraction: 0.7).delay(Double(value) * 0.05)
                    ) {
                        isAnimated = true
                    }
                } else {
                    isAnimated = true
                }
            }
    }
}

// MARK: - Time Breakdown Chart

/// Donut chart showing time distribution
struct TimeBreakdownChart: View {
    let screenTime: Int
    let breakTime: Int
    let meetingTime: Int
    let idleTime: Int
    let animate: Bool

    @State private var animationProgress: Double = 0

    private var total: Int {
        max(1, screenTime + breakTime + meetingTime + idleTime)
    }

    private var segments: [(label: String, value: Int, color: Color, icon: String)] {
        [
            ("Screen", screenTime, SightTheme.accent, "display"),
            ("Breaks", breakTime, SightTheme.success, "eye.slash"),
            ("Meetings", meetingTime, .purple, "video.fill"),
            ("Idle", idleTime, SightTheme.tertiaryText, "moon.zzz"),
        ].filter { $0.value > 0 }
    }

    var body: some View {
        HStack(spacing: 24) {
            // Donut chart
            ZStack {
                ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                    let startAngle = segmentStartAngle(at: index)
                    let endAngle = segmentEndAngle(at: index)

                    Circle()
                        .trim(
                            from: animate ? startAngle / 360 * animationProgress : startAngle / 360,
                            to: animate ? endAngle / 360 * animationProgress : endAngle / 360
                        )
                        .stroke(
                            segment.color,
                            style: StrokeStyle(lineWidth: 20, lineCap: .butt)
                        )
                        .rotationEffect(.degrees(-90))
                }

                // Center text
                VStack(spacing: 2) {
                    Text("\(total)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("min")
                        .font(.system(size: 10))
                        .foregroundColor(SightTheme.tertiaryText)
                }
            }
            .frame(width: 100, height: 100)

            // Legend
            VStack(alignment: .leading, spacing: 8) {
                ForEach(segments, id: \.label) { segment in
                    HStack(spacing: 8) {
                        Image(systemName: segment.icon)
                            .font(.system(size: 10))
                            .foregroundColor(segment.color)
                            .frame(width: 16)

                        Circle()
                            .fill(segment.color)
                            .frame(width: 8, height: 8)

                        Text(segment.label)
                            .font(.system(size: 12))
                            .foregroundColor(SightTheme.secondaryText)

                        Spacer()

                        Text("\(segment.value)m")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)

                        Text("(\(Int(Double(segment.value) / Double(total) * 100))%)")
                            .font(.system(size: 10))
                            .foregroundColor(SightTheme.tertiaryText)
                    }
                }
            }
        }
        .onAppear {
            if animate {
                withAnimation(.easeOut(duration: 1.0)) {
                    animationProgress = 1
                }
            } else {
                animationProgress = 1
            }
        }
    }

    private func segmentStartAngle(at index: Int) -> Double {
        var angle: Double = 0
        for i in 0..<index {
            angle += Double(segments[i].value) / Double(total) * 360
        }
        return angle
    }

    private func segmentEndAngle(at index: Int) -> Double {
        segmentStartAngle(at: index) + Double(segments[index].value) / Double(total) * 360
    }
}

// MARK: - Comparison Bar View

/// Week-over-week comparison visualization
struct ComparisonBarView: View {
    let currentValue: Double
    let previousValue: Double
    let label: String
    let format: String  // e.g., "%.0f" or "%.1f%%"
    let animate: Bool

    @State private var animatedCurrent: Double = 0
    @State private var animatedPrevious: Double = 0

    private var change: Double {
        guard previousValue > 0 else { return 0 }
        return ((currentValue - previousValue) / previousValue) * 100
    }

    private var isImproving: Bool {
        currentValue >= previousValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label and change indicator
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                if previousValue > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: isImproving ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(String(format: "%.0f%%", abs(change)))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(isImproving ? SightTheme.success : SightTheme.warning)
                }
            }

            // Bars
            GeometryReader { geometry in
                let maxValue = max(currentValue, previousValue, 1)
                let width = geometry.size.width

                VStack(spacing: 4) {
                    // Current week
                    HStack(spacing: 8) {
                        Text("This")
                            .font(.system(size: 10))
                            .foregroundColor(SightTheme.tertiaryText)
                            .frame(width: 30, alignment: .trailing)

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 16)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(SightTheme.accent)
                                .frame(
                                    width: (width - 80) * CGFloat(animatedCurrent / maxValue),
                                    height: 16)
                        }

                        Text(String(format: format, animatedCurrent))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, alignment: .trailing)
                    }

                    // Previous week
                    HStack(spacing: 8) {
                        Text("Last")
                            .font(.system(size: 10))
                            .foregroundColor(SightTheme.tertiaryText)
                            .frame(width: 30, alignment: .trailing)

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 16)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.3))
                                .frame(
                                    width: (width - 80) * CGFloat(animatedPrevious / maxValue),
                                    height: 16)
                        }

                        Text(String(format: format, animatedPrevious))
                            .font(.system(size: 11))
                            .foregroundColor(SightTheme.secondaryText)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
            .frame(height: 40)
        }
        .onAppear {
            if animate {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animatedCurrent = currentValue
                    animatedPrevious = previousValue
                }
            } else {
                animatedCurrent = currentValue
                animatedPrevious = previousValue
            }
        }
    }
}

// MARK: - Trend Line Chart

/// Simple line chart for showing trends
struct TrendLineChart: View {
    let values: [Double]
    let labels: [String]
    let animate: Bool

    @State private var drawProgress: CGFloat = 0

    private var maxValue: Double {
        max(values.max() ?? 1, 1)
    }

    private var minValue: Double {
        max(0, (values.min() ?? 0) - 10)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let stepX = width / CGFloat(max(1, values.count - 1))

            ZStack {
                // Grid lines
                ForEach(0..<5) { i in
                    let y = height * CGFloat(i) / 4
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                }

                // Area fill
                Path { path in
                    guard !values.isEmpty else { return }

                    path.move(to: CGPoint(x: 0, y: height))

                    for (index, value) in values.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y =
                            height - (height * CGFloat((value - minValue) / (maxValue - minValue)))
                        if index == 0 {
                            path.addLine(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }

                    path.addLine(to: CGPoint(x: CGFloat(values.count - 1) * stepX, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [SightTheme.accent.opacity(0.3), SightTheme.accent.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask(
                    Rectangle()
                        .frame(width: width * drawProgress)
                        .frame(maxWidth: .infinity, alignment: .leading)
                )

                // Line
                Path { path in
                    guard !values.isEmpty else { return }

                    for (index, value) in values.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y =
                            height - (height * CGFloat((value - minValue) / (maxValue - minValue)))
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .trim(from: 0, to: drawProgress)
                .stroke(
                    SightTheme.accent,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )

                // Data points
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    let x = CGFloat(index) * stepX
                    let y = height - (height * CGFloat((value - minValue) / (maxValue - minValue)))

                    Circle()
                        .fill(SightTheme.accent)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                        .opacity(drawProgress > CGFloat(index) / CGFloat(values.count) ? 1 : 0)
                }

                // Labels
                HStack {
                    ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                        if index == 0 || index == labels.count - 1 || labels.count <= 7 {
                            Text(label)
                                .font(.system(size: 9))
                                .foregroundColor(SightTheme.tertiaryText)
                        }
                        if index < labels.count - 1 {
                            Spacer()
                        }
                    }
                }
                .position(x: width / 2, y: height + 12)
            }
        }
        .onAppear {
            if animate {
                withAnimation(.easeOut(duration: 1.2)) {
                    drawProgress = 1
                }
            } else {
                drawProgress = 1
            }
        }
    }
}

// MARK: - Insight Card View

/// Card displaying a wellness insight
struct InsightCardView: View {
    let insight: WellnessInsight

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: insight.icon)
                .font(.system(size: 18))
                .foregroundColor(insight.isPositive ? SightTheme.success : SightTheme.warning)
                .frame(width: 36, height: 36)
                .background(
                    (insight.isPositive ? SightTheme.success : SightTheme.warning).opacity(0.15)
                )
                .cornerRadius(8)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                Text(insight.description)
                    .font(.system(size: 11))
                    .foregroundColor(SightTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(SightTheme.cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isHovered
                        ? (insight.isPositive ? SightTheme.success : SightTheme.warning).opacity(
                            0.3) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Nudge Compliance Card

/// Visual representation of nudge compliance
struct NudgeComplianceCard: View {
    let blinkShown: Int
    let blinkFollowed: Int
    let postureShown: Int
    let postureFollowed: Int
    let animate: Bool

    @State private var isAnimated = false

    private var blinkCompliance: Double {
        guard blinkShown > 0 else { return 1.0 }
        return Double(blinkFollowed) / Double(blinkShown)
    }

    private var postureCompliance: Double {
        guard postureShown > 0 else { return 1.0 }
        return Double(postureFollowed) / Double(postureShown)
    }

    var body: some View {
        HStack(spacing: 20) {
            // Blink compliance
            ComplianceRing(
                value: blinkCompliance,
                icon: "eye.fill",
                label: "Blink",
                color: SightTheme.accent,
                animate: isAnimated
            )

            // Posture compliance
            ComplianceRing(
                value: postureCompliance,
                icon: "figure.stand",
                label: "Posture",
                color: .purple,
                animate: isAnimated
            )
        }
        .onAppear {
            if animate {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    isAnimated = true
                }
            }
        }
    }
}

struct ComplianceRing: View {
    let value: Double  // 0-1
    let icon: String
    let label: String
    let color: Color
    let animate: Bool

    @State private var animatedValue: Double = 0

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)

                // Progress
                Circle()
                    .trim(from: 0, to: CGFloat(animatedValue))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            .frame(width: 50, height: 50)

            VStack(spacing: 2) {
                Text(String(format: "%.0f%%", animatedValue * 100))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(SightTheme.tertiaryText)
            }
        }
        .onAppear {
            if animate {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animatedValue = value
                }
            } else {
                animatedValue = value
            }
        }
    }
}

// MARK: - Previews

#Preview("Wellness Gauge") {
    WellnessGaugeView(score: 78, animate: true)
        .padding()
        .background(SightTheme.background)
}

#Preview("Time Breakdown") {
    TimeBreakdownChart(
        screenTime: 120,
        breakTime: 25,
        meetingTime: 45,
        idleTime: 30,
        animate: true
    )
    .padding()
    .frame(height: 150)
    .background(SightTheme.background)
}

#Preview("Comparison Bar") {
    ComparisonBarView(
        currentValue: 8,
        previousValue: 6,
        label: "Breaks Completed",
        format: "%.0f",
        animate: true
    )
    .padding()
    .background(SightTheme.background)
}
