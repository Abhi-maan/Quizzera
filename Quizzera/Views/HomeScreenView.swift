

import SwiftUI

struct HomeScreenView: View {

    @EnvironmentObject var userData: UserDataViewModel
    @StateObject private var quizVM = QuizViewModel()

    @State private var selectedCategory: Category = .generalKnowledge
    @State private var selectedDifficulty: Difficulty = .medium
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

                    // MARK: - Score History Sparkline
                    if !userData.scoreHistory.isEmpty {
                        sparklineSection
                            .opacity(statsVisible ? 1 : 0)
                            .offset(y: statsVisible ? 0 : 20)
                    }

                    // MARK: - Category Picker
                    categorySection
                        .opacity(categoryVisible ? 1 : 0)
                        .offset(y: categoryVisible ? 0 : 20)

                    // MARK: - Difficulty Picker
                    difficultySection
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

                // Daily streak badge
                if userData.dailyStreak >= 1 {
                    HStack(spacing: 5) {
                        Text("🔥")
                            .font(.system(size: 16))
                        Text("\(userData.dailyStreak)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.12))
                            .overlay(
                                Capsule()
                                    .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                            )
                    )
                    .transition(.scale.combined(with: .opacity))
                }

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

    // MARK: - Sparkline Section

    private var sparklineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.electricPurple)
                Text("Score Trend")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Text("Last \(userData.scoreHistory.count) quizzes")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
            }

            SparklineChart(entries: userData.scoreHistory)
                .frame(height: 60)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.electricPurple.opacity(0.1), lineWidth: 1)
                )
        )
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
                        HapticManager.selection()
                    }
                }
            }
        }
    }

    // MARK: - Difficulty Section

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Difficulty")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))

            HStack(spacing: 10) {
                ForEach(Difficulty.allCases) { difficulty in
                    DifficultyPill(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDifficulty = difficulty
                        }
                        HapticManager.selection()
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
                quizVM.startQuiz(category: selectedCategory, difficulty: selectedDifficulty)
                navigateToQuiz = true
                HapticManager.impact(.medium)
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

            // My Best Scores button
            Button {
                navigateToLeaderboard = true
                HapticManager.selection()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("My Best Scores")
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
                    HapticManager.notification(.success)
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

// MARK: - Difficulty Pill

struct DifficultyPill: View {
    let difficulty: Difficulty
    let isSelected: Bool

    private var difficultyColor: Color {
        switch difficulty {
        case .easy:   return .neonGreen
        case .medium: return .quizzeraGold
        case .hard:   return .dangerRed
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: difficulty.iconName)
                .font(.system(size: 12, weight: .semibold))

            Text(difficulty.rawValue)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .foregroundColor(isSelected ? .white : difficultyColor.opacity(0.7))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? difficultyColor.opacity(0.25) : Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? difficultyColor.opacity(0.6) : Color.white.opacity(0.06),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
        )
        .shadow(color: isSelected ? difficultyColor.opacity(0.2) : .clear, radius: 6)
    }
}

// MARK: - Sparkline Chart

struct SparklineChart: View {
    let entries: [ScoreHistoryEntry]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let maxScore = entries.map(\.score).max() ?? 1
            let minScore = entries.map(\.score).min() ?? 0
            let scoreRange = max(Double(maxScore - minScore), 1)

            ZStack {
                // Grid lines
                ForEach(0..<3) { i in
                    let y = height * CGFloat(i) / 2.0
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                }

                // Gradient fill under the line
                if entries.count >= 2 {
                    Path { path in
                        let points = chartPoints(width: width, height: height, maxScore: maxScore, minScore: minScore, scoreRange: scoreRange)
                        guard let first = points.first else { return }
                        path.move(to: CGPoint(x: first.x, y: height))
                        path.addLine(to: first)
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                        if let last = points.last {
                            path.addLine(to: CGPoint(x: last.x, y: height))
                        }
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [.electricPurple.opacity(0.2), .neonGreen.opacity(0.05), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Line
                    Path { path in
                        let points = chartPoints(width: width, height: height, maxScore: maxScore, minScore: minScore, scoreRange: scoreRange)
                        guard let first = points.first else { return }
                        path.move(to: first)
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [.electricPurple, .neonGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )

                    // Data points
                    ForEach(Array(chartPoints(width: width, height: height, maxScore: maxScore, minScore: minScore, scoreRange: scoreRange).enumerated()), id: \.offset) { _, point in
                        Circle()
                            .fill(Color.neonGreen)
                            .frame(width: 6, height: 6)
                            .shadow(color: .neonGreen.opacity(0.5), radius: 4)
                            .position(point)
                    }
                }

                // Score labels
                if let last = entries.last {
                    VStack {
                        HStack {
                            Spacer()
                            Text("\(last.score) pts")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.neonGreen)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private func chartPoints(width: CGFloat, height: CGFloat, maxScore: Int, minScore: Int, scoreRange: Double) -> [CGPoint] {
        guard entries.count >= 2 else { return [] }
        let padding: CGFloat = 8
        let usableWidth = width - padding * 2
        let usableHeight = height - padding * 2

        return entries.enumerated().map { index, entry in
            let x = padding + usableWidth * CGFloat(index) / CGFloat(entries.count - 1)
            let normalized = (Double(entry.score) - Double(minScore)) / scoreRange
            let y = padding + usableHeight * (1.0 - normalized)
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeScreenView()
            .environmentObject(UserDataViewModel())
    }
}
