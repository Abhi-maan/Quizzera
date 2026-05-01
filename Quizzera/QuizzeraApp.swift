//
//  QuizzeraApp.swift
//  Quizzera
//
//  Created on 2026-04-27.
//  Learn. Test. Master.
//

import SwiftUI

@main
struct QuizzeraApp: App {
    @StateObject private var userDataVM = UserDataViewModel()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.quizzeraBg
                    .ignoresSafeArea()

                if showSplash {
                    SplashScreenView()
                        .transition(.opacity.combined(with: .scale))
                } else {
                    NavigationStack {
                        HomeScreenView()
                    }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .environmentObject(userDataVM)
            .preferredColorScheme(.dark)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}

// MARK: - App Color Theme
extension Color {
    /// Electric Purple - Primary brand color
    static let electricPurple = Color(red: 123/255, green: 47/255, blue: 190/255)

    /// Neon Green - Accent color for highlights & correct answers
    static let neonGreen = Color(red: 57/255, green: 255/255, blue: 20/255)

    /// Near Black - Main background
    static let quizzeraBg = Color(red: 13/255, green: 13/255, blue: 13/255)

    /// Card Background - Elevated surface color
    static let cardBg = Color(red: 26/255, green: 26/255, blue: 46/255)

    /// Danger Red - Wrong answers & low timer
    static let dangerRed = Color(red: 255/255, green: 59/255, blue: 48/255)

    /// Gold - For legendary badge & highlights
    static let quizzeraGold = Color(red: 255/255, green: 215/255, blue: 0/255)
}

// MARK: - Bouncy Button Style
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Glow Button Style (for primary actions)
struct GlowButtonStyle: ButtonStyle {
    var color: Color = .electricPurple

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .shadow(color: color.opacity(configuration.isPressed ? 0.2 : 0.5), radius: 12, x: 0, y: 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BounceButtonStyle {
    static var bounce: BounceButtonStyle { BounceButtonStyle() }
}
