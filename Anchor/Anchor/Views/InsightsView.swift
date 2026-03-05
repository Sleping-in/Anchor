//
//  InsightsView.swift
//  Anchor
//
//  Mood trend visualization using Swift Charts.
//

import Charts
import SwiftData
import SwiftUI

struct InsightsView: View {
    @Query(sort: \Session.timestamp, order: .reverse) private var sessions: [Session]
    @Query private var settingsModels: [UserSettings]
    @Query private var profiles: [UserProfile]
    @State private var selectedRange: InsightsRange = .last30
    @State private var moodChartRange: MoodChartView.Range = .last30
    @State private var activeFilter: InsightsFilter = .all
    @State private var analysis: PatternAnalyzer.AnalysisResult?

    private var filteredSessions: [Session] {
        let cutoff =
            Calendar.current.date(byAdding: .day, value: -selectedRange.days + 1, to: Date())
            ?? Date.distantPast
        return sessions.filter { $0.timestamp >= cutoff }
    }

    private var sessionsWithMood: [Session] {
        filteredSessions.filter { $0.moodBefore != nil || $0.moodAfter != nil }
    }

    private var moodDataPoints: [MoodDataPoint] {
        sessionsWithMood.reversed().flatMap { session -> [MoodDataPoint] in
            var points: [MoodDataPoint] = []
            if let before = session.moodBefore {
                points.append(MoodDataPoint(date: session.timestamp, value: before, type: .before))
            }
            if let after = session.moodAfter {
                points.append(MoodDataPoint(date: session.timestamp, value: after, type: .after))
            }
            return points
        }
    }

    private var averageMoodBefore: Double? {
        let values = sessionsWithMood.compactMap(\.moodBefore)
        guard !values.isEmpty else { return nil }
        return Double(values.reduce(0, +)) / Double(values.count)
    }

    private var averageMoodAfter: Double? {
        let values = sessionsWithMood.compactMap(\.moodAfter)
        guard !values.isEmpty else { return nil }
        return Double(values.reduce(0, +)) / Double(values.count)
    }

    private var totalSessionCount: Int { filteredSessions.count }

    private var totalMinutes: Int {
        Int(filteredSessions.reduce(0) { $0 + $1.duration }) / 60
    }

    private var streakDays: Int {
        settingsModels.first?.currentStreak ?? 0
    }

    private var voiceStressAverage: Double? {
        let values = filteredSessions.compactMap(\.voiceStressScore)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var thisWeekSessions: [Session] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else {
            return []
        }
        return sessions.filter { $0.timestamp >= interval.start && $0.timestamp < interval.end }
    }

    private var lastWeekSessions: [Session] {
        let calendar = Calendar.current
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: Date()),
            let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeek.start),
            let lastWeek = calendar.dateInterval(of: .weekOfYear, for: lastWeekStart)
        else { return [] }
        return sessions.filter { $0.timestamp >= lastWeek.start && $0.timestamp < lastWeek.end }
    }

    private var thisWeekStats: WeeklyStats { weeklyStats(for: thisWeekSessions) }
    private var lastWeekStats: WeeklyStats { weeklyStats(for: lastWeekSessions) }

    private var heatmapDays: [HeatmapDay] {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -29, to: end) ?? end
        let gridStart = calendar.dateInterval(of: .weekOfYear, for: start)?.start ?? start

        let totalDays = 42
        return (0..<totalDays).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: gridStart) else {
                return nil
            }
            let sessionsForDay = sessions.filter {
                calendar.isDate($0.timestamp, inSameDayAs: date)
            }
            let values = sessionsForDay.compactMap { $0.moodAfter ?? $0.moodBefore }
            let avg = values.isEmpty ? nil : Double(values.reduce(0, +)) / Double(values.count)
            let isInRange = date >= start && date <= end
            return HeatmapDay(date: date, value: avg, isInRange: isInRange)
        }
    }

    private var topMoodTriggers: [(String, Int)] {
        var counts: [String: Int] = [:]
        for session in filteredSessions {
            for trigger in session.moodTriggers ?? [] {
                counts[trigger, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }.prefix(6).map { ($0.key, $0.value) }
    }

    private var analysisRefreshKey: String {
        "\(sessions.count)-\(profiles.count)-\(selectedRange.rawValue)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Picker(String(localized: "Range"), selection: $selectedRange) {
                    ForEach(InsightsRange.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                Text(
                    String.localizedStringWithFormat(
                        String(localized: "Showing the last %lld days of activity."),
                        Int64(selectedRange.days)
                    )
                )
                .font(AnchorTheme.Typography.caption)
                .anchorSecondaryText()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(InsightsFilter.allCases) { filter in
                            Button {
                                activeFilter = filter
                            } label: {
                                Text(filter.label)
                                    .font(AnchorTheme.Typography.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(
                                                activeFilter == filter
                                                    ? AnchorTheme.Colors.sageLeaf.opacity(0.18)
                                                    : AnchorTheme.Colors.warmStone)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                activeFilter == filter
                                                    ? AnchorTheme.Colors.sageLeaf
                                                    : AnchorTheme.Colors.warmSand.opacity(0.4),
                                                lineWidth: 1)
                                    )
                                    .foregroundColor(AnchorTheme.Colors.quietInk)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(activeFilter == filter ? [.isSelected] : [])
                        }
                    }
                }

                // Stats cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(
                        title: String(localized: "Sessions"), value: String(totalSessionCount),
                        icon: "bubble.left.fill")
                    StatCard(
                        title: String(localized: "Minutes"), value: String(totalMinutes),
                        icon: "clock.fill")
                    StatCard(
                        title: String(localized: "Streak"),
                        value: String.localizedStringWithFormat(
                            String(localized: "%lldd"), Int64(streakDays)),
                        icon: "flame.fill"
                    )
                    StatCard(
                        title: String(localized: "Voice Stress"),
                        value: voiceStressAverage.map { String(Int($0)) } ?? String(localized: "—"),
                        icon: "waveform.path.ecg"
                    )
                }

                if totalSessionCount > 0 && activeFilter.showsSessions {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "This Week vs Last Week"))
                            .font(AnchorTheme.Typography.headline)
                            .anchorPrimaryText()

                        ComparisonRow(
                            title: String(localized: "Avg Mood"),
                            thisValue: thisWeekStats.avgMoodText,
                            lastValue: lastWeekStats.avgMoodText,
                            delta: deltaText(
                                current: thisWeekStats.avgMood, previous: lastWeekStats.avgMood),
                            deltaColor: deltaColor(
                                current: thisWeekStats.avgMood, previous: lastWeekStats.avgMood)
                        )

                        ComparisonRow(
                            title: String(localized: "Sessions"),
                            thisValue: "\(thisWeekStats.sessionCount)",
                            lastValue: "\(lastWeekStats.sessionCount)",
                            delta: countDeltaText(
                                current: thisWeekStats.sessionCount,
                                previous: lastWeekStats.sessionCount),
                            deltaColor: countDeltaColor(
                                current: thisWeekStats.sessionCount,
                                previous: lastWeekStats.sessionCount)
                        )

                        ComparisonRow(
                            title: String(localized: "Days Active"),
                            thisValue: "\(thisWeekStats.daysActive)",
                            lastValue: "\(lastWeekStats.daysActive)",
                            delta: countDeltaText(
                                current: thisWeekStats.daysActive,
                                previous: lastWeekStats.daysActive),
                            deltaColor: countDeltaColor(
                                current: thisWeekStats.daysActive,
                                previous: lastWeekStats.daysActive)
                        )

                        Text(
                            String(localized: "Mood averages only include sessions with check-ins.")
                        )
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()
                    }
                    .anchorCard()
                }

                if activeFilter.showsMood {
                    MoodChartView(
                        sessions: sessionsWithMood,
                        selectedRange: $moodChartRange
                    )
                }

                if !heatmapDays.isEmpty && activeFilter.showsMood {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "Mood Heatmap"))
                            .font(AnchorTheme.Typography.headline)
                            .anchorPrimaryText()

                        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) {
                                    symbol in
                                    Text(String(symbol.prefix(1)))
                                        .font(AnchorTheme.Typography.smallCaption)
                                        .frame(maxWidth: .infinity)
                                        .anchorSecondaryText()
                                }
                            }

                            LazyVGrid(columns: columns, spacing: 6) {
                                ForEach(heatmapDays) { day in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(heatmapColor(day.value, inRange: day.isInRange))
                                        .frame(height: 16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(
                                                    AnchorTheme.Colors.warmSand.opacity(
                                                        day.isToday ? 0.8 : 0), lineWidth: 1)
                                        )
                                        .accessibilityLabel(day.accessibilityLabel)
                                }
                            }
                        }

                        Text(String(localized: "Daily average mood over the last month."))
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                    }
                    .anchorCard()
                }

                // Averages
                if let avgBefore = averageMoodBefore, let avgAfter = averageMoodAfter,
                    activeFilter.showsMood
                {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "Average Mood Shift"))
                            .font(AnchorTheme.Typography.headline)
                            .anchorPrimaryText()

                        HStack(spacing: 32) {
                            VStack(spacing: 4) {
                                Text(String(format: "%.1f", avgBefore))
                                    .font(AnchorTheme.Typography.heading(size: 28))
                                    .anchorPrimaryText()
                                Text(String(localized: "Before"))
                                    .font(AnchorTheme.Typography.caption)
                                    .anchorSecondaryText()
                            }

                            Image(systemName: "arrow.right")
                                .font(.title3)
                                .anchorSecondaryText()
                                .accessibilityHidden(true)

                            VStack(spacing: 4) {
                                Text(String(format: "%.1f", avgAfter))
                                    .font(AnchorTheme.Typography.heading(size: 28))
                                    .foregroundColor(AnchorTheme.Colors.sageLeaf)
                                Text(String(localized: "After"))
                                    .font(AnchorTheme.Typography.caption)
                                    .anchorSecondaryText()
                            }

                            Spacer()

                            let diff = avgAfter - avgBefore
                            VStack(spacing: 4) {
                                Text(
                                    diff >= 0
                                        ? "+\(String(format: "%.1f", diff))"
                                        : String(format: "%.1f", diff)
                                )
                                .font(AnchorTheme.Typography.heading(size: 24))
                                .foregroundColor(
                                    diff >= 0
                                        ? AnchorTheme.Colors.sageLeaf : AnchorTheme.Colors.crisisRed
                                )
                                Text(String(localized: "Change"))
                                    .font(AnchorTheme.Typography.caption)
                                    .anchorSecondaryText()
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            {
                                let beforeText = String(format: "%.1f", avgBefore)
                                let afterText = String(format: "%.1f", avgAfter)
                                let changeText = String(format: "%.1f", abs(avgAfter - avgBefore))
                                let changeWord =
                                    avgAfter >= avgBefore
                                    ? String(localized: "plus") : String(localized: "minus")
                                return String.localizedStringWithFormat(
                                    String(
                                        localized: "Average mood: %@ before, %@ after, change %@ %@"
                                    ),
                                    beforeText,
                                    afterText,
                                    changeWord,
                                    changeText
                                )
                            }())

                        Text(
                            String(
                                localized:
                                    "Averages are calculated from sessions with mood check-ins.")
                        )
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()
                    }
                    .anchorCard()
                }

                if activeFilter.showsTriggers {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "Mood Triggers"))
                            .font(AnchorTheme.Typography.headline)
                            .anchorPrimaryText()

                        if topMoodTriggers.isEmpty {
                            Text(String(localized: "No mood triggers captured yet."))
                                .font(AnchorTheme.Typography.subheadline)
                                .anchorSecondaryText()
                        } else {
                            FlowLayout(spacing: 8) {
                                ForEach(topMoodTriggers, id: \.0) { item in
                                    Text(
                                        String.localizedStringWithFormat(
                                            String(localized: "%@ · %lld"),
                                            MoodTriggerTag.label(for: item.0),
                                            Int64(item.1)
                                        )
                                    )
                                    .font(AnchorTheme.Typography.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AnchorTheme.Colors.warmStone)
                                    .foregroundColor(AnchorTheme.Colors.quietInk)
                                    .cornerRadius(14)
                                }
                            }
                        }
                    }
                    .anchorCard()
                }

                // Sessions per week chart
                if filteredSessions.count >= 2 && activeFilter.showsSessions {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "Session Frequency"))
                            .font(AnchorTheme.Typography.headline)
                            .anchorPrimaryText()

                        Chart(weeklySessionCounts, id: \.weekStart) { item in
                            BarMark(
                                x: .value("Week", item.weekStart, unit: .weekOfYear),
                                y: .value("Sessions", item.count)
                            )
                            .foregroundStyle(AnchorTheme.Colors.sageLeaf.gradient)
                            .cornerRadius(4)
                        }
                        .frame(height: 150)

                        Text(String(localized: "Weekly session counts within this range."))
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                    }
                    .anchorCard()
                }

                // Pattern Analysis
                if let analysis = analysis, activeFilter.showsMood {
                    // Mood Impact by Topic
                    if !analysis.topicMoodCorrelations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "Mood Impact by Topic"))
                                .font(AnchorTheme.Typography.headline)
                                .anchorPrimaryText()

                            Chart {
                                ForEach(
                                    analysis.topicMoodCorrelations.sorted(by: {
                                        $0.value > $1.value
                                    }), id: \.key
                                ) { topic, impact in
                                    BarMark(
                                        x: .value("Impact", impact),
                                        y: .value("Topic", topic)
                                    )
                                    .foregroundStyle(
                                        impact > 0
                                            ? AnchorTheme.Colors.sageLeaf
                                            : AnchorTheme.Colors.pulsePink
                                    )
                                    .annotation(position: .trailing) {
                                        Text(String(format: "%+.1f", impact))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .chartXAxisLabel(String(localized: "Avg Mood Shift"))
                            .frame(
                                height: max(200, CGFloat(analysis.topicMoodCorrelations.count * 40))
                            )

                            Text(
                                String(
                                    localized: "Average mood change when discussing these topics.")
                            )
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                        }
                        .anchorCard()
                    }

                    // Mood by Time of Day
                    if !analysis.timeOfDayMood.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "Mood by Time of Day"))
                                .font(AnchorTheme.Typography.headline)
                                .anchorPrimaryText()

                            Chart {
                                ForEach(
                                    analysis.timeOfDayMood.sorted(by: { $0.key < $1.key }),
                                    id: \.key
                                ) { hour, mood in
                                    LineMark(
                                        x: .value("Hour", hour),
                                        y: .value("Avg Shift", mood)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .symbol(by: .value("Hour", hour))
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: 3)) { value in
                                    AxisValueLabel(format: .dateTime.hour())
                                }
                            }
                            .frame(height: 200)

                            Text(String(localized: "Average mood shift by hour of day."))
                                .font(AnchorTheme.Typography.caption)
                                .anchorSecondaryText()
                        }
                        .anchorCard()
                    }

                    if !analysis.topicFrequency.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "Topic Frequency"))
                                .font(AnchorTheme.Typography.headline)
                                .anchorPrimaryText()

                            if let topTopic = analysis.topicFrequency.first {
                                Text(
                                    String.localizedStringWithFormat(
                                        String(
                                            localized: "You've discussed %@ in %lld of your last %lld sessions."
                                        ),
                                        topTopic.topic,
                                        Int64(topTopic.count),
                                        Int64(analysis.totalSessionsAnalyzed)
                                    )
                                )
                                .font(AnchorTheme.Typography.subheadline)
                                .anchorSecondaryText()
                            }

                            Chart(analysis.topicFrequency.prefix(6), id: \.topic) { item in
                                BarMark(
                                    x: .value("Topic", item.topic),
                                    y: .value("Count", item.count)
                                )
                                .foregroundStyle(AnchorTheme.Colors.etherBlue.gradient)
                                .annotation(position: .top) {
                                    Text("\(item.count)")
                                        .font(.caption2)
                                        .foregroundColor(AnchorTheme.Colors.quietInkSecondary)
                                }
                            }
                            .frame(height: 200)

                            Text(
                                String(localized: "Most frequently discussed topics in recent sessions.")
                            )
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                        }
                        .anchorCard()
                    }

                    if !analysis.effectiveStrategies.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "Coping Strategy Effectiveness"))
                                .font(AnchorTheme.Typography.headline)
                                .anchorPrimaryText()

                            Chart(analysis.effectiveStrategies.prefix(6), id: \.strategy) { item in
                                if let averageShift = item.averageMoodShift {
                                    BarMark(
                                        x: .value("Strategy", item.strategy),
                                        y: .value("Avg Shift", averageShift)
                                    )
                                    .foregroundStyle(
                                        averageShift >= 0
                                            ? AnchorTheme.Colors.sageLeaf
                                            : AnchorTheme.Colors.pulsePink
                                    )
                                }
                            }
                            .frame(height: 210)

                            Text(
                                String(localized: "Average mood shift in sessions where each strategy was explored.")
                            )
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                        }
                        .anchorCard()
                    }

                    if !analysis.riskyPatterns.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "Risk Signals"))
                                .font(AnchorTheme.Typography.headline)
                                .anchorPrimaryText()

                            Text(
                                String.localizedStringWithFormat(
                                    String(localized: "Average mood shift: %.1f • Positive-session rate: %lld%%"),
                                    analysis.moodTrend.averageShift,
                                    Int64((analysis.moodTrend.positiveShiftRate * 100).rounded())
                                )
                            )
                            .font(AnchorTheme.Typography.subheadline)
                            .anchorSecondaryText()

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(analysis.riskyPatterns, id: \.self) { pattern in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(AnchorTheme.Colors.crisisRed)
                                            .padding(.top, 2)
                                            .accessibilityHidden(true)
                                        Text(pattern)
                                            .font(AnchorTheme.Typography.bodyText)
                                            .anchorSecondaryText()
                                    }
                                }
                            }
                        }
                        .anchorCard()
                    }
                }

                // Empty state
                if sessionsWithMood.isEmpty && activeFilter.showsMood {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48))
                            .foregroundColor(AnchorTheme.Colors.warmSand)
                            .accessibilityHidden(true)

                        Text(String(localized: "No mood data yet"))
                            .font(AnchorTheme.Typography.headline)
                            .anchorPrimaryText()

                        Text(
                            String(
                                localized:
                                    "Complete a few sessions with mood check-ins to see your trends here."
                            )
                        )
                        .font(AnchorTheme.Typography.subheadline)
                        .anchorSecondaryText()
                        .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical)
        }
        .task(id: analysisRefreshKey) {
            analysis = PatternAnalyzer.analyze(
                sessions: filteredSessions,
                profile: profiles.first
            )
        }
        .navigationTitle(String(localized: "Insights"))
        .navigationBarTitleDisplayMode(.large)
        .anchorScreenBackground()
    }

    private var weeklySessionCounts: [WeeklyCount] {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]
        for session in filteredSessions {
            let weekStart =
                calendar.dateInterval(of: .weekOfYear, for: session.timestamp)?.start
                ?? session.timestamp
            counts[weekStart, default: 0] += 1
        }
        return counts.map { WeeklyCount(weekStart: $0.key, count: $0.value) }
            .sorted { $0.weekStart < $1.weekStart }
            .suffix(8)
            .map { $0 }
    }

    private func weeklyStats(for sessions: [Session]) -> WeeklyStats {
        let calendar = Calendar.current
        let days = Set(sessions.map { calendar.startOfDay(for: $0.timestamp) })
        let values = sessions.compactMap { $0.moodAfter ?? $0.moodBefore }
        let avg = values.isEmpty ? nil : Double(values.reduce(0, +)) / Double(values.count)
        return WeeklyStats(sessionCount: sessions.count, daysActive: days.count, avgMood: avg)
    }

    private func deltaText(current: Double?, previous: Double?) -> String {
        guard let current, let previous else { return "—" }
        let diff = current - previous
        return diff >= 0 ? "+\(String(format: "%.1f", diff))" : String(format: "%.1f", diff)
    }

    private func deltaColor(current: Double?, previous: Double?) -> Color {
        guard let current, let previous else { return AnchorTheme.Colors.quietInkSecondary }
        return current >= previous ? AnchorTheme.Colors.sageLeaf : AnchorTheme.Colors.crisisRed
    }

    private func countDeltaText(current: Int, previous: Int) -> String {
        let diff = current - previous
        return diff >= 0 ? "+\(diff)" : "\(diff)"
    }

    private func countDeltaColor(current: Int, previous: Int) -> Color {
        current >= previous ? AnchorTheme.Colors.sageLeaf : AnchorTheme.Colors.crisisRed
    }

    private func heatmapColor(_ value: Double?, inRange: Bool) -> Color {
        guard inRange else { return AnchorTheme.Colors.warmStone.opacity(0.2) }
        guard let value else { return AnchorTheme.Colors.warmStone }
        switch value {
        case ..<2: return AnchorTheme.Colors.crisisRed.opacity(0.35)
        case 2..<3: return AnchorTheme.Colors.warmSand
        case 3..<4: return AnchorTheme.Colors.sageLeaf.opacity(0.55)
        default: return AnchorTheme.Colors.sageLeaf
        }
    }
}

private struct MoodDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Int
    let type: MoodType

    enum MoodType {
        case before
        case after

        var label: String {
            switch self {
            case .before: return "Before"
            case .after: return "After"
            }
        }
    }
}

private enum InsightsRange: Int, CaseIterable, Identifiable, Hashable {
    case last7 = 7
    case last30 = 30
    case last90 = 90

    var id: Int { rawValue }

    var days: Int { rawValue }

    var label: String {
        switch self {
        case .last7: return String(localized: "7D")
        case .last30: return String(localized: "30D")
        case .last90: return String(localized: "90D")
        }
    }
}

private struct WeeklyCount {
    let weekStart: Date
    let count: Int
}

private enum InsightsFilter: CaseIterable, Identifiable {
    case all
    case mood
    case sessions
    case triggers

    var id: String { label }

    var label: String {
        switch self {
        case .all: return String(localized: "All")
        case .mood: return String(localized: "Mood")
        case .sessions: return String(localized: "Sessions")
        case .triggers: return String(localized: "Triggers")
        }
    }

    var showsMood: Bool {
        self == .all || self == .mood
    }

    var showsSessions: Bool {
        self == .all || self == .sessions
    }

    var showsTriggers: Bool {
        self == .all || self == .triggers
    }
}

private struct WeeklyStats {
    let sessionCount: Int
    let daysActive: Int
    let avgMood: Double?

    var avgMoodText: String {
        guard let avgMood else { return "—" }
        return String(format: "%.1f", avgMood)
    }
}

private struct HeatmapDay: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double?
    let isInRange: Bool

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var accessibilityLabel: String {
        let dateLabel = date.formatted(date: .abbreviated, time: .omitted)
        if let value {
            let valueText = String(format: "%.1f", value)
            return String.localizedStringWithFormat(
                String(localized: "%@, average mood %@"),
                dateLabel,
                valueText
            )
        }
        return String.localizedStringWithFormat(
            String(localized: "%@, no mood data"),
            dateLabel
        )
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AnchorTheme.Colors.sageLeaf)
                .accessibilityHidden(true)
            Text(value)
                .font(AnchorTheme.Typography.heading(size: 22))
                .anchorPrimaryText()
            Text(title)
                .font(AnchorTheme.Typography.smallCaption)
                .anchorSecondaryText()
        }
        .frame(maxWidth: .infinity)
        .anchorCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String.localizedStringWithFormat(
                String(localized: "%@: %@"),
                title,
                value
            )
        )
    }
}

private struct ComparisonRow: View {
    let title: String
    let thisValue: String
    let lastValue: String
    let delta: String
    let deltaColor: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()
                Text(
                    String.localizedStringWithFormat(
                        String(localized: "%@ now"),
                        thisValue
                    )
                )
                .font(AnchorTheme.Typography.bodyText)
                .anchorPrimaryText()
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(
                    String.localizedStringWithFormat(
                        String(localized: "Last week: %@"),
                        lastValue
                    )
                )
                .font(AnchorTheme.Typography.smallCaption)
                .anchorSecondaryText()
                Text(delta)
                    .font(AnchorTheme.Typography.caption)
                    .foregroundColor(deltaColor)
            }
        }
    }
}

#Preview {
    NavigationStack {
        InsightsView()
            .modelContainer(for: [Session.self, UserSettings.self], inMemory: true)
    }
}
