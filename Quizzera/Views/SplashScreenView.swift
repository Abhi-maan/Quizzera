//
//  SplashScreenView.swift
//  Quizzera
//
//  Created on 2026-04-27.
//  Animated splash with logo, app name, and tagline.
//

import SwiftUI

struct SplashScreenView: View {

    // MARK: - Animation State

    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var iconRotation: Double = -30
    @State private var titleOffset: CGFloat = 40
    @State private var titleOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var particlesVisible: Bool = false

    var body: some View {
        ZStack {
            // Background
            Color.quizzeraBg
                .ignoresSafeArea()

            // Subtle radial gradient backdrop
            RadialGradient(
                colors: [
                    Color.electricPurple.opacity(0.15),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 300
            )
            .ignoresSafeArea()
            .scaleEffect(pulseScale)

            // Floating particles
            if particlesVisible {
                FloatingParticlesView()
                    .transition(.opacity)
            }

            VStack(spacing: 24) {
                Spacer()

                // Logo icon
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.electricPurple, .neonGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 130, height: 130)
                        .shadow(color: .electricPurple.opacity(0.6), radius: glowRadius)
                        .scaleEffect(pulseScale)

                    // Icon background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.electricPurple.opacity(0.3),
                                    Color.cardBg
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    // Brain + bolt icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.electricPurple, .neonGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .neonGreen.opacity(0.4), radius: 8)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                .rotationEffect(.degrees(iconRotation))

                // App name
                VStack(spacing: 8) {
                    Text("Quizzera")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .electricPurple.opacity(0.5), radius: 12)

                    // Tagline
                    Text("Learn. Test. Master.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.neonGreen.opacity(0.9))
                        .opacity(taglineOpacity)
                        .tracking(4)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)

                Spacer()

                // Loading dots
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        LoadingDot(delay: Double(i) * 0.2)
                    }
                }
                .opacity(taglineOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Animation Sequence

    private func startAnimations() {
        // Phase 1: Icon appears with spring
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
            iconScale = 1.0
            iconOpacity = 1.0
            iconRotation = 0
        }

        // Phase 2: Glow expands
        withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
            glowRadius = 20
        }

        // Phase 3: Title slides up
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) {
            titleOffset = 0
            titleOpacity = 1.0
        }

        // Phase 4: Tagline fades in
        withAnimation(.easeIn(duration: 0.4).delay(1.0)) {
            taglineOpacity = 1.0
        }

        // Phase 5: Particles appear
        withAnimation(.easeIn(duration: 0.5).delay(0.8)) {
            particlesVisible = true
        }

        // Continuous pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.0)) {
            pulseScale = 1.05
        }
    }
}

// MARK: - Loading Dot

struct LoadingDot: View {
    let delay: Double
    @State private var animating = false

    var body: some View {
        Circle()
            .fill(Color.electricPurple)
            .frame(width: 8, height: 8)
            .scaleEffect(animating ? 1.0 : 0.4)
            .opacity(animating ? 1.0 : 0.3)
            .animation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
                .delay(delay),
                value: animating
            )
            .onAppear {
                animating = true
            }
    }
}

// MARK: - Floating Particles

struct FloatingParticlesView: View {
    let particleCount = 15

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<particleCount, id: \.self) { i in
                FloatingParticle(
                    screenSize: geo.size,
                    index: i
                )
            }
        }
        .ignoresSafeArea()
    }
}

struct FloatingParticle: View {
    let screenSize: CGSize
    let index: Int

    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0

    private var size: CGFloat {
        CGFloat.random(in: 2...6)
    }

    private var color: Color {
        [Color.electricPurple, .neonGreen, .white.opacity(0.5)].randomElement()!
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .position(position)
            .opacity(opacity)
            .blur(radius: size > 4 ? 1 : 0)
            .onAppear {
                let startX = CGFloat.random(in: 0...screenSize.width)
                let startY = CGFloat.random(in: 0...screenSize.height)
                position = CGPoint(x: startX, y: startY)

                let duration = Double.random(in: 3...6)
                let delay = Double.random(in: 0...2)

                withAnimation(.easeIn(duration: 0.5).delay(delay)) {
                    opacity = Double.random(in: 0.2...0.6)
                }

                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    position = CGPoint(
                        x: startX + CGFloat.random(in: -40...40),
                        y: startY + CGFloat.random(in: -60...60)
                    )
                }
            }
    }
}

// MARK: - Preview

#Preview {
    SplashScreenView()
}
