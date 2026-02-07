//
//  ContentView.swift
//  Anchor
//
//  Created by Mohammad Elhaj on 07/02/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Session.self, UserSettings.self], inMemory: true)
}
