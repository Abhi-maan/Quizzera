//
//  HomeScreenView.swift
//  Quizzera
//
//  Created on 2026-04-27.
//  Home hub — stats, category picker, XP badges, navigation.
//

import SwiftUI

struct HomeScreenView: View {

    @EnvironmentObject var userData: UserDataViewModel
    @StateObject private var quizVM = QuizViewModel()

    @State private var selectedCategory: Category = .generalKnowledge
    @State private var showNameEntry = false
    @State private var nameInput = ""
    @State private var navigateToQuiz = false
    @State private var navigateToLeaderboard = false

    // Animations
    @State private var headerVisible = false
    @State private var statsVisible = false
    @State private var categoryVisible = false
    @State private var buttonsVisible = false

    var body: some View {
        ZStack {
            // Background
            Color.quizzeraBg.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    // MARK: - Header
                    headerSection
                        .opacity(headerVisible ? 1 : 0)
                        .offset(y: headerVisible ? 0 : 20)

                    // MARK: - Stats Cards
                    statsSection
                        .opacity(statsVisible ? 1 : 0)
                        .offset(y: statsVisible ? 0 : 20)

                    // MARK: - Category Picker
                    categorySection
                        .opacity(categoryVisible ? 1 : 0)
                        .offset(y: categoryVisible ? 0 : 20)

                    // MARK: - XP Badge
                    xpBadgeSection
                        .opacity(categoryVisible ? 1 : 0)

                    // MARK: - Action Buttons
                    actionButtons
                        .opacity(buttonsVisible ? 1 : 0)
                        .offset(y: buttonsVisible ? 0 : 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }

            // Name entry overlay
            if showNameEntry {
                nameEntryOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToQuiz) {
            QuizScreenView(viewModel: quizVM)
                .environmentObject(userData)
        }
        .navigationDestination(isPresented: $navigateToLeaderboard) {
            LeaderboardScreenView()
                .environmentObject(userData)
        }
        .onAppear {
            if !userData.hasLaunched {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3)) {
                    showNameEntry = true
                }
            }
            animateIn()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))

                    Text(userData.playerName.isEmpty ? "Quizzer" : userData.playerName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Spacer()

                // Profile icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.electricPurple, .electricPurple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Text(String(userData.playerName.prefix(1)).uppercased())
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .shadow(color: .electricPurple.opacity(0.4), radius: 8)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Best Score",
                value: "\(userData.bestScore)",
                icon: "trophy.fill",
                color: .quizzeraGold
            )

            StatCard(
                title: "Quizzes",
                value: "\(userData.totalQuizzes)",
                icon: "gamecontroller.fill",
                color: .electricPurple
            )

            StatCard(
                title: "Accuracy",
                value: userData.accuracyString,
                icon: "target",
                color: .neonGreen
            )
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose Category")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Category.allCases) { category in
                    CategoryCard(
                        category: category,
                        isSelected: selectedCategory == category,
                        xpLevel: userData.xp(for: category).level
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }

    // MARK: - XP Badge Section

    private var xpBadgeSection: some View {
        let xpData = userData.xp(for: selectedCategory)

        return VStack(spacing: 10) {
            HStack {
                Text(selectedCategory.label)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                HStack(spacing: 4) {
                    Text(xpData.level.emoji)
                    Text(xpData.level.rawValue)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.neonGreen)
                }
            }

            // XP progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.electricPurple, .neonGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * xpData.progressToNext, height: 8)
                        .animation(.spring(response: 0.5), value: xpData.progressToNext)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(xpData.xp) XP")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                if xpData.level != .legendary {
                    Text("Next: \(nextLevelName(from: xpData.level))")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                } else {
                    Text("MAX LEVEL")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.quizzeraGold)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.electricPurple.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 14) {
            // Start Quiz button
            Button {
                quizVM.startQuiz(category: selectedCategory)
                navigateToQuiz = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Start Quiz")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [.electricPurple, Color(red: 100/255, green: 40/255, blue: 200/255)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .electricPurple.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(GlowButtonStyle())

            // Leaderboard button
            Button {
                navigateToLeaderboard = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Leaderboard")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [.electricPurple.opacity(0.5), .neonGreen.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
            }
            .buttonStyle(.bounce)
        }
    }

    // MARK: - Name Entry Overlay

    private var nameEntryOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: 24) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.electricPurple, .neonGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 6) {
                    Text("Welcome to Quizzera!")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("What should we call you?")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }

                TextField("Enter your name", text: $nameInput)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.electricPurple.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)

                Button {
                    let name = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    userData.saveName(name)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showNameEntry = false
                    }
                } label: {
                    Text("Let's Go!")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.electricPurple, .neonGreen.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.bounce)
                .opacity(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.electricPurple.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .electricPurple.opacity(0.2), radius: 20)
            )
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Helpers

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good Morning ☀️"
        case 12..<17: return "Good Afternoon 🌤️"
        case 17..<21: return "Good Evening 🌅"
        default:      return "Night Owl 🦉"
        }
    }

    private func nextLevelName(from level: XPLevel) -> String {
        switch level {
        case .novice:     return "Apprentice"
        case .apprentice: return "Scholar"
        case .scholar:    return "Master"
        case .master:     return "Legendary"
        case .legendary:  return "—"
        }
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
            headerVisible = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            statsVisible = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35)) {
            categoryVisible = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5)) {
            buttonsVisible = true
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: Category
    let isSelected: Bool
    let xpLevel: XPLevel

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: category.iconName)
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(isSelected ? .neonGreen : .white.opacity(0.6))
                .frame(height: 30)

            Text(category.label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            // XP level badge
            Text("\(xpLevel.emoji) \(xpLevel.rawValue)")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.electricPurple.opacity(0.25) : Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected
                                ? Color.electricPurple.opacity(0.6)
                                : Color.white.opacity(0.06),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
        )
        .shadow(color: isSelected ? .electricPurple.opacity(0.2) : .clear, radius: 8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeScreenView()
            .environmentObject(UserDataViewModel())
    }
}
