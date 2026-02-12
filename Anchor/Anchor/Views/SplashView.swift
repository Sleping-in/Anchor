//
//  SplashView.swift
//  Anchor
//
//  Animated splash screen shown on app launch.
//

import SwiftUI

struct SplashView: View {
    @State private var orbVisible = false
    @State private var textVisible = false
    @State private var finished = false
    @State private var finishTask: Task<Void, Never>?

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            AnchorTheme.Colors.softParchment
                .ignoresSafeArea()

            VStack(spacing: 28) {
                OrbView(state: .idle, size: 140)
                    .opacity(orbVisible ? 1 : 0)
                    .scaleEffect(orbVisible ? 1 : 0.6)

                VStack(spacing: 6) {
                    Text(String(localized: "Anchor"))
                        .font(AnchorTheme.Typography.heading(size: 36, weight: .semibold))
                        .foregroundColor(AnchorTheme.Colors.sageLeaf)

                    Text(String(localized: "Your safe space to talk"))
                        .font(AnchorTheme.Typography.body(size: 16, weight: .regular))
                        .foregroundColor(AnchorTheme.Colors.quietInkSecondary)
                }
                .opacity(textVisible ? 1 : 0)
                .offset(y: textVisible ? 0 : 12)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                orbVisible = true
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.4)) {
                textVisible = true
            }
            finishTask?.cancel()
            finishTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation(.easeInOut(duration: 0.4)) {
                    finished = true
                }
                try? await Task.sleep(nanoseconds: 400_000_000)
                onFinished()
            }
        }
        .onDisappear {
            finishTask?.cancel()
            finishTask = nil
        }
        .opacity(finished ? 0 : 1)
    }
}

#Preview {
    SplashView { }
}
