//
//  ShareCardView.swift
//  Quizzera
//
//  Created on 2026-05-03.
//  Instagram-story-style share card for quiz results.
//

import SwiftUI

/// A beautifully designed card view that renders quiz results
/// as a shareable image (Instagram story style).
struct ShareCardView: View {
    let result: QuizResult

    var body: some View {
        VStack(spacing: 0) {
            // Top branding area
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.electricPurple, .neonGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Quizzera")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Text("Learn. Test. Master.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.neonGreen.opacity(0.8))
                    .tracking(3)
            }
            .padding(.top, 32)
            .padding(.bottom, 20)

            // Score circle
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.electricPurple, .neonGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 6
                    )
                    .frame(width: 130, height: 130)
                    .shadow(color: .electricPurple.opacity(0.4), radius: 12)

                // Score ring fill
                Circle()
                    .trim(from: 0, to: Double(result.totalScore) / Double(max(result.maxPossibleScore, 1)))
                    .stroke(
                        LinearGradient(
                            colors: [.electricPurple, .neonGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(result.totalScore)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("POINTS")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(3)
                }
            }
            .padding(.vertical, 16)

            // Badge
            Text(result.performanceBadge.rawValue)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: badgeColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.bottom, 20)

            // Stats grid
            HStack(spacing: 0) {
                shareStatItem(
                    value: "\(result.correctCount)/\(result.totalQuestions)",
                    label: "Correct",
                    color: .neonGreen
                )

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1, height: 50)

                shareStatItem(
                    value: String(format: "%.0f%%", result.accuracyPercent),
                    label: "Accuracy",
                    color: .electricPurple
                )

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1, height: 50)

                shareStatItem(
                    value: "\(result.streak)🔥",
                    label: "Best Streak",
                    color: .orange
                )
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
            )
            .padding(.horizontal, 20)

            // Category + Difficulty
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: result.category.iconName)
                        .font(.system(size: 12))
                    Text(result.category.label)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 16)

            // CTA
            VStack(spacing: 6) {
                Text("Challenge your friends! 🎯")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                Text("quizzera.app")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.electricPurple.opacity(0.6))
            }
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .frame(width: 340)
        .background(
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 20/255, green: 10/255, blue: 40/255),
                        Color(red: 10/255, green: 10/255, blue: 20/255),
                        Color.quizzeraBg
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Subtle decorative elements
                VStack {
                    HStack {
                        Circle()
                            .fill(Color.electricPurple.opacity(0.08))
                            .frame(width: 120, height: 120)
                            .offset(x: -40, y: -20)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.neonGreen.opacity(0.05))
                            .frame(width: 100, height: 100)
                            .offset(x: 30, y: 20)
                    }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.electricPurple.opacity(0.4), .neonGreen.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }

    // MARK: - Helpers

    private func shareStatItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private var badgeColors: [Color] {
        switch result.performanceBadge {
        case .legendary:        return [.quizzeraGold, .orange]
        case .knowledgeUnlocked: return [.neonGreen, .cyan]
        case .gettingSharp:     return [.electricPurple, .blue]
        case .keepLearning:     return [.white.opacity(0.8), .white.opacity(0.5)]
        }
    }

    // MARK: - Render as Image

    /// Render this view as a UIImage for sharing.
    @MainActor
    static func renderAsImage(result: QuizResult) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCardView(result: result))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ShareCardView(
            result: QuizResult(
                playerName: "Abhimaan",
                category: .technology,
                totalQuestions: 10,
                correctCount: 8,
                wrongCount: 1,
                skippedCount: 1,
                totalScore: 110,
                maxPossibleScore: 150,
                streak: 5,
                answers: [],
                confidenceResults: ConfidenceReport()
            )
        )
    }
}
