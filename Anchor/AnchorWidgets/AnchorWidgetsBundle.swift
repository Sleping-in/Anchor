import WidgetKit
import SwiftUI

@main
struct AnchorWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MoodStreakWidget()
        WeeklyMoodTrendWidget()
        QuickCheckInWidget()
        BreathingShortcutWidget()
        LockScreenWidget()
        AnchorSessionLiveActivity()
    }
}
