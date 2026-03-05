//
//  AnchorApp.swift
//  Anchor
//
//  Created by Mohammad Elhaj on 07/02/2026.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct AnchorApp: App {
    init() {
        FontRegistrar.registerFonts()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    @StateObject private var voiceStateController = VoiceStateController()
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var deepLinkRouter = DeepLinkRouter()
    @State private var showingSplash = true

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Session.self,
            UserSettings.self,
            UserProfile.self,
            FlaggedResponse.self,
        ])
        // Enable complete file protection for encryption at rest.
        let storeURL = URL.applicationSupportDirectory.appending(path: "Anchor.store")
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            // Set NSFileProtectionComplete on the store file
            let fileURL = storeURL
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: fileURL.path(percentEncoded: false)
            )
            return container
        } catch {
            if shouldRecoverFromMigrationError(error) {
                purgeStoreFiles(at: storeURL)
                do {
                    let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                    return container
                } catch {
                    fatalError("Could not recreate ModelContainer after migration reset: \(error)")
                }
            } else {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(voiceStateController)
                    .environmentObject(networkMonitor)
                    .environment(deepLinkRouter)

                if showingSplash {
                    SplashView {
                        showingSplash = false
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .onOpenURL { url in
                deepLinkRouter.handle(url)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

private func shouldRecoverFromMigrationError(_ error: Error) -> Bool {
    let nsError = error as NSError
    if nsError.domain == NSCocoaErrorDomain && nsError.code == 134110 {
        return true
    }
    if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError,
       underlying.domain == NSCocoaErrorDomain,
       underlying.code == 134110 {
        return true
    }
    return false
}

private func purgeStoreFiles(at storeURL: URL) {
    let fm = FileManager.default
    let walURL = storeURL.appendingPathExtension("wal")
    let shmURL = storeURL.appendingPathExtension("shm")

    let backupSuffix = ISO8601DateFormatter().string(from: Date())
        .replacingOccurrences(of: ":", with: "-")
    let backupURL = storeURL.deletingLastPathComponent()
        .appendingPathComponent("Anchor.store.backup-\(backupSuffix)")

    if fm.fileExists(atPath: storeURL.path(percentEncoded: false)) {
        do {
            try fm.moveItem(at: storeURL, to: backupURL)
        } catch {
            try? fm.removeItem(at: storeURL)
        }
    }

    [walURL, shmURL].forEach { url in
        if fm.fileExists(atPath: url.path(percentEncoded: false)) {
            try? fm.removeItem(at: url)
        }
    }

    UserDefaults.standard.set(true, forKey: "AnchorDidResetStore")
}
