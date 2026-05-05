//
//  LeaderboardScreenView.swift
//  Quizzera
//
//  Created on 2026-04-27.
//  My Best Scores — top 5 personal scores with rank medals, current session highlight.
//

import SwiftUI

struct LeaderboardScreenView: View {

    @EnvironmentObject var userData: UserDataViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var headerVisible = false
    @State private var rowsVisible = false
    @State private var emptyVisible = false

    var body: some View {
        ZStack {
            Color.quizzeraBg.ignoresSafeArea()

            // Background glow
            VStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [.electricPurple.opacity(0.12), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 250
                        )
                    )
                    .frame(height: 300)
                    .offset(y: -80)

                Spacer()
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .opacity(headerVisible ? 1 : 0)
                    .offset(y: headerVisible ? 0 : 15)

                if userData.leaderboard.isEmpty {
                    emptyState
                        .opacity(emptyVisible ? 1 : 0)
                        .scaleEffect(emptyVisible ? 1 : 0.9)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 12) {
                            // Podium for top 3
                            if userData.leaderboard.count >= 3 {
                                podiumView
                                    .padding(.top, 16)
                                    .padding(.bottom, 8)
                            }

                            // All entries as list
                            ForEach(Array(userData.leaderboard.enumerated()), id: \.element.id) { index, entry in
                                LeaderboardRow(
                                    rank: index + 1,
                                    entry: entry,
                                    isCurrentSession: entry.id == userData.currentSessionId
                                )
                                .opacity(rowsVisible ? 1 : 0)
                                .offset(y: rowsVisible ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                        .delay(Double(index) * 0.1 + 0.3),
                                    value: rowsVisible
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { animateIn() }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.bounce)

            Spacer()

            VStack(spacing: 2) {
                Text("My Best Scores")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Your Top Performances")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            // Crown icon
            Image(systemName: "crown.fill")
                .font(.system(size: 18))
                .foregroundColor(.quizzeraGold)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.quizzeraGold.opacity(0.12)))
        }
    }

    // MARK: - Podium View

    private var podiumView: some View {
        let entries = userData.leaderboard

        return HStack(alignment: .bottom, spacing: 8) {
            // 2nd place
            if entries.count > 1 {
                PodiumCard(
                    rank: 2,
                    entry: entries[1],
                    height: 90,
                    isCurrentSession: entries[1].id == userData.currentSessionId
                )
            }

            // 1st place
            if entries.count > 0 {
                PodiumCard(
                    rank: 1,
                    entry: entries[0],
                    height: 120,
                    isCurrentSession: entries[0].id == userData.currentSessionId
                )
            }

            // 3rd place
            if entries.count > 2 {
                PodiumCard(
                    rank: 3,
                    entry: entries[2],
                    height: 70,
                    isCurrentSession: entries[2].id == userData.currentSessionId
                )
            }
        }
        .opacity(rowsVisible ? 1 : 0)
        .scaleEffect(rowsVisible ? 1 : 0.9)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.electricPurple.opacity(0.4), .white.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: 8) {
                Text("No Scores Yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                Text("Complete a quiz to see your\nscores on the board!")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }

            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                    Text("Start a Quiz")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.electricPurple, Color(red: 100/255, green: 40/255, blue: 200/255)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .electricPurple.opacity(0.4), radius: 10, y: 4)
            }
            .buttonStyle(GlowButtonStyle())
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Animate

    private func animateIn() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
            headerVisible = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25)) {
            rowsVisible = true
            emptyVisible = true
        }
    }
}

// MARK: - Podium Card

struct PodiumCard: View {
    let rank: Int
    let entry: LeaderboardEntry
    let height: CGFloat
    let isCurrentSession: Bool

    private var medalColor: Color {
        switch rank {
        case 1: return .quizzeraGold
        case 2: return Color(red: 192/255, green: 192/255, blue: 192/255)
        case 3: return Color(red: 205/255, green: 127/255, blue: 50/255)
        default: return .white.opacity(0.3)
        }
    }

    private var medalEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(medalColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(medalColor.opacity(0.5), lineWidth: rank == 1 ? 2 : 1)
                    )

                Text(String(entry.playerName.prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(medalColor)
            }

            Text(entry.playerName)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)

            // Podium block
            VStack(spacing: 6) {
                Text(medalEmoji)
                    .font(.system(size: rank == 1 ? 24 : 18))

                Text("\(entry.score)")
                    .font(.system(size: rank == 1 ? 20 : 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("pts")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                medalColor.opacity(0.15),
                                Color.cardBg
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(medalColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: .infinity)
        .overlay(
            isCurrentSession
                ? RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.neonGreen.opacity(0.4), lineWidth: 1.5)
                    .shadow(color: .neonGreen.opacity(0.2), radius: 6)
                    .padding(.top, 56)
                : nil
        )
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry
    let isCurrentSession: Bool

    private var rankColor: Color {
        switch rank {
        case 1: return .quizzeraGold
        case 2: return Color(red: 192/255, green: 192/255, blue: 192/255)
        case 3: return Color(red: 205/255, green: 127/255, blue: 50/255)
        default: return .white.opacity(0.4)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Text("#\(rank)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(rankColor)
            }

            // Name + category
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.playerName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    if isCurrentSession {
                        Text("YOU")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.neonGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(Color.neonGreen.opacity(0.15))
                            )
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: entry.category.iconName)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.35))

                    Text(entry.category.label)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))

                    Text("·")
                        .foregroundColor(.white.opacity(0.2))

                    Text(entry.formattedDate)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.score)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(rank <= 3 ? rankColor : .white)

                Text("pts")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCurrentSession ? Color.neonGreen.opacity(0.06) : Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isCurrentSession
                                ? Color.neonGreen.opacity(0.25)
                                : Color.white.opacity(0.04),
                            lineWidth: isCurrentSession ? 1.5 : 1
                        )
                )
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LeaderboardScreenView()
            .environmentObject({
                let vm = UserDataViewModel()
                // Add sample data
                let sampleResult = QuizResult(
                    playerName: "Deepanshu",
                    category: .technology,
                    totalQuestions: 10,
                    correctCount: 8,
                    wrongCount: 2,
                    skippedCount: 0,
                    totalScore: 110,
                    maxPossibleScore: 150,
                    streak: 5,
                    answers: [],
                    confidenceResults: ConfidenceReport()
                )
                vm.recordResult(sampleResult)
                return vm
            }())
    }
}
