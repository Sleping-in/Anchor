//
//  AnchorShortcutsProvider.swift
//  Anchor
//
//  Registers Siri phrases so users can say
//  "Hey Siri, start a session with Anchor" etc.
//

import AppIntents

struct AnchorShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartSessionIntent(),
            phrases: [
                "Start a session with \(.applicationName)",
                "Check in with \(.applicationName)",
                "Talk to \(.applicationName)",
            ],
            shortTitle: "Start Session",
            systemImageName: "mic.fill"
        )

        AppShortcut(
            intent: StartBreathingIntent(),
            phrases: [
                "Breathe with \(.applicationName)",
                "Start breathing with \(.applicationName)",
            ],
            shortTitle: "Breathing Exercise",
            systemImageName: "wind"
        )

        AppShortcut(
            intent: LogMoodIntent(),
            phrases: [
                "Log my mood in \(.applicationName)",
                "How am I feeling in \(.applicationName)",
            ],
            shortTitle: "Log Mood",
            systemImageName: "heart.fill"
        )
    }
}
