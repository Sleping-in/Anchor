//
//  MoodChartView.swift
//  Anchor
//
//  Longitudinal mood chart with 7-day, 30-day, and all-time ranges.
//

import Charts
import SwiftUI

struct MoodChartView: View {
    enum Range: String, CaseIterable, Identifiable {
        case last7
        case last30
        case allTime

        var id: String { rawValue }

        var label: String {
            switch self {
            case .last7: return String(localized: "7D")
            case .last30: return String(localized: "30D")
            case .allTime: return String(localized: "All")
            }
        }
    }

    let sessions: [Session]
    @Binding var selectedRange: Range

    private var filteredSessions: [Session] {
        let ordered = sessions.sorted { $0.timestamp < $1.timestamp }
        switch selectedRange {
        case .allTime:
            return ordered
        case .last7:
            let cutoff =
                Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? .distantPast
            return ordered.filter { $0.timestamp >= cutoff }
        case .last30:
            let cutoff =
                Calendar.current.date(byAdding: .day, value: -29, to: Date()) ?? .distantPast
            return ordered.filter { $0.timestamp >= cutoff }
        }
    }

    private var points: [MoodPoint] {
        filteredSessions.flatMap { session -> [MoodPoint] in
            var result: [MoodPoint] = []
            if let before = session.moodBefore {
                result.append(
                    MoodPoint(
                        date: session.timestamp,
                        value: before,
                        type: .before,
                        sessionID: session.id
                    )
                )
            }
            if let after = session.moodAfter {
                result.append(
                    MoodPoint(
                        date: session.timestamp,
                        value: after,
                        type: .after,
                        sessionID: session.id
                    )
                )
            }
            return result
        }
    }

    private var crisisSessions: [Session] {
        filteredSessions.filter(\.crisisDetected)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Mood Over Time"))
                    .font(AnchorTheme.Typography.headline)
                    .anchorPrimaryText()
                Spacer()
                Picker(String(localized: "Mood Range"), selection: $selectedRange) {
                    ForEach(Range.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 210)
            }

            if points.isEmpty {
                Text(String(localized: "No mood check-ins in this range yet."))
                    .font(AnchorTheme.Typography.subheadline)
                    .anchorSecondaryText()
            } else {
                Chart {
                    ForEach(crisisSessions) { session in
                        RuleMark(x: .value("Session Date", session.timestamp))
                            .foregroundStyle(AnchorTheme.Colors.crisisRed.opacity(0.18))
                            .lineStyle(StrokeStyle(lineWidth: 1))
                    }

                    ForEach(points) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Mood", point.value)
                        )
                        .foregroundStyle(by: .value("Type", point.type.label))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Mood", point.value)
                        )
                        .foregroundStyle(by: .value("Type", point.type.label))
                    }
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            Text(MoodEmoji.emoji(for: value.as(Int.self) ?? 3))
                        }
                    }
                }
                .chartForegroundStyleScale([
                    "Before": AnchorTheme.Colors.warmSand,
                    "After": AnchorTheme.Colors.sageLeaf,
                ])
                .frame(height: 230)

                Text(
                    String(
                        localized:
                            "Red vertical markers indicate sessions where crisis keywords were detected."
                    )
                )
                .font(AnchorTheme.Typography.caption)
                .anchorSecondaryText()
            }
        }
        .anchorCard()
    }
}

private struct MoodPoint: Identifiable {
    enum Kind {
        case before
        case after

        var label: String {
            switch self {
            case .before: return "Before"
            case .after: return "After"
            }
        }
    }

    let date: Date
    let value: Int
    let type: Kind
    let sessionID: UUID

    var id: String {
        "\(sessionID.uuidString)-\(type.label)"
    }
}

