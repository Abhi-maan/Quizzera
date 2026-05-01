//
//  ResultScreenView.swift
//  Quizzera
//
//  Created on 2026-04-27.
//  Results — animated score, badge, breakdown, confidence insights, review.
//

import SwiftUI

struct ResultScreenView: View {

    let result: QuizResult
    @EnvironmentObject var userData: UserDataViewModel
    @Environment(\.dismiss) private var dismiss

    // Animation state
    @State private var animatedScore: Int = 0
    @State private var badgeVisible = false
    @State private var statsVisible = false
    @State private var insightVisible = false
    @State private var buttonsVisible = false
    @State private var showReview = false
    @State private var confettiActive = false
    @State private var navigateHome = false

    var body: some View {
        ZStack {
            Color.quizzeraBg.ignoresSafeArea()

            // Confetti layer
            if confettiActive {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    // Score circle
                    scoreSection
                        .padding(.top, 40)

                    // Performance badge
                    if badgeVisible {
                        badgeSection
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Stats breakdown
                    if statsVisible {
                        breakdownSection
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Confidence insight
                    if insightVisible {
                        confidenceInsight
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Action buttons
                    if buttonsVisible {
                        actionButtons
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showReview) {
            ReviewAnswersView(answers: result.answers)
        }
        .navigationDestination(isPresented: $navigateHome) {
            HomeScreenView()
                .environmentObject(userData)
        }
        .onAppear {
            userData.recordResult(result)
            startAnimations()
        }
    }

    // MARK: - Score Section

    private var scoreSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 8)
                    .frame(width: 160, height: 160)

                // Score ring
                Circle()
                    .trim(from: 0, to: Double(animatedScore) / Double(max(result.maxPossibleScore, 1)))
                    .stroke(
                        LinearGradient(
                            colors: [.electricPurple, .neonGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                // Score number
                VStack(spacing: 2) {
                    Text("\(animatedScore)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())

                    Text("POINTS")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(3)
                }
            }
            .shadow(color: .electricPurple.opacity(0.3), radius: 20)

            Text("\(result.correctCount)/\(result.totalQuestions) Correct")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Badge Section

    private var badgeSection: some View {
        VStack(spacing: 8) {
            Text(result.performanceBadge.rawValue)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(badgeGradient)
                .shadow(color: badgeShadowColor.opacity(0.5), radius: 12)

            if result.streak >= 3 {
                Text("Best Streak: \(result.streak) 🔥")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(badgeShadowColor.opacity(0.3), lineWidth: 1.5)
                )
        )
    }

    private var badgeGradient: LinearGradient {
        switch result.performanceBadge {
        case .legendary:
            return LinearGradient(colors: [.quizzeraGold, .orange], startPoint: .leading, endPoint: .trailing)
        case .knowledgeUnlocked:
            return LinearGradient(colors: [.neonGreen, .cyan], startPoint: .leading, endPoint: .trailing)
        case .gettingSharp:
            return LinearGradient(colors: [.electricPurple, .blue], startPoint: .leading, endPoint: .trailing)
        case .keepLearning:
            return LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
        }
    }

    private var badgeShadowColor: Color {
        switch result.performanceBadge {
        case .legendary:        return .quizzeraGold
        case .knowledgeUnlocked: return .neonGreen
        case .gettingSharp:     return .electricPurple
        case .keepLearning:     return .white.opacity(0.3)
        }
    }

    // MARK: - Breakdown Section

    private var breakdownSection: some View {
        VStack(spacing: 16) {
            Text("Breakdown")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                BreakdownCard(label: "Correct", value: "\(result.correctCount)", color: .neonGreen, icon: "checkmark.circle.fill")
                BreakdownCard(label: "Wrong", value: "\(result.wrongCount)", color: .dangerRed, icon: "xmark.circle.fill")
                BreakdownCard(label: "Skipped", value: "\(result.skippedCount)", color: .quizzeraGold, icon: "forward.fill")
            }

            // Accuracy bar
            VStack(spacing: 8) {
                HStack {
                    Text("Accuracy")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text(String(format: "%.0f%%", result.accuracyPercent))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.neonGreen)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.white.opacity(0.08))

                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [.electricPurple, .neonGreen],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * (result.accuracyPercent / 100))
                    }
                }
                .frame(height: 8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.cardBg)
            )
        }
    }

    // MARK: - Confidence Insight

    private var confidenceInsight: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "brain")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.electricPurple)
                Text("Confidence Insight")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }

            Text(result.confidenceResults.insightText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Confidence breakdown mini-stats
            if hasConfidenceData {
                HStack(spacing: 10) {
                    if result.confidenceResults.totalConfident > 0 {
                        ConfidenceMiniStat(
                            emoji: "😎",
                            count: result.confidenceResults.totalConfident,
                            correct: result.confidenceResults.confidentAndCorrect
                        )
                    }
                    if result.confidenceResults.totalUnsure > 0 {
                        ConfidenceMiniStat(
                            emoji: "🤔",
                            count: result.confidenceResults.totalUnsure,
                            correct: result.confidenceResults.unsureAndCorrect
                        )
                    }
                    if result.confidenceResults.totalGuessed > 0 {
                        ConfidenceMiniStat(
                            emoji: "😅",
                            count: result.confidenceResults.totalGuessed,
                            correct: result.confidenceResults.guessedAndCorrect
                        )
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.electricPurple.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var hasConfidenceData: Bool {
        let r = result.confidenceResults
        return r.totalConfident > 0 || r.totalUnsure > 0 || r.totalGuessed > 0
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 14) {
            // Review Answers
            Button {
                showReview = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Review Answers")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.electricPurple.opacity(0.4), lineWidth: 1.5)
                        )
                )
            }
            .buttonStyle(.bounce)

            HStack(spacing: 14) {
                // Play Again
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .bold))
                        Text("Play Again")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.electricPurple, Color(red: 100/255, green: 40/255, blue: 200/255)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(GlowButtonStyle())

                // Home
                Button {
                    navigateHome = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Home")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.cardBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.bounce)
            }
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Animate score counter
        let duration = 1.5
        let steps = 60
        let increment = max(result.totalScore / steps, 1)
        var current = 0

        Timer.scheduledTimer(withTimeInterval: duration / Double(steps), repeats: true) { timer in
            current += increment
            if current >= result.totalScore {
                current = result.totalScore
                timer.invalidate()
            }
            withAnimation(.none) {
                animatedScore = current
            }
        }

        // Stagger other sections
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.8)) {
            badgeVisible = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.2)) {
            statsVisible = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.5)) {
            insightVisible = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.8)) {
            buttonsVisible = true
        }

        // Confetti for legendary
        if result.performanceBadge.showConfetti {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation { confettiActive = true }
            }
        }
    }
}

// MARK: - Breakdown Card

struct BreakdownCard: View {
    let label: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Confidence Mini Stat

struct ConfidenceMiniStat: View {
    let emoji: String
    let count: Int
    let correct: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 20))
            Text("\(correct)/\(count)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("correct")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
        )
    }
}

// MARK: - Review Answers View

struct ReviewAnswersView: View {
    let answers: [AnswerRecord]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.quizzeraBg.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.bounce)

                        Spacer()

                        Text("Review Answers")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Spacer()
                        Color.clear.frame(width: 36, height: 36)
                    }
                    .padding(.top, 8)

                    ForEach(Array(answers.enumerated()), id: \.element.id) { index, answer in
                        ReviewCard(index: index + 1, answer: answer)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Review Card

struct ReviewCard: View {
    let index: Int
    let answer: AnswerRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Question header
            HStack {
                Text("Q\(index)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.electricPurple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.electricPurple.opacity(0.15)))

                Spacer()

                // Status badge
                if answer.isSkipped {
                    StatusBadge(text: "Skipped", color: .quizzeraGold)
                } else if answer.isCorrect {
                    StatusBadge(text: "+\(answer.pointsEarned) pts", color: .neonGreen)
                } else {
                    StatusBadge(text: "Wrong", color: .dangerRed)
                }
            }

            // Question text
            Text(answer.question.text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            // Your answer
            if !answer.isSkipped, let selected = answer.selectedIndex {
                HStack(spacing: 8) {
                    Image(systemName: answer.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(answer.isCorrect ? .neonGreen : .dangerRed)
                        .font(.system(size: 14))

                    Text("Your answer: \(answer.question.options[selected])")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(answer.isCorrect ? .neonGreen.opacity(0.8) : .dangerRed.opacity(0.8))
                }
            }

            // Correct answer (if wrong or skipped)
            if !answer.isCorrect {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.neonGreen.opacity(0.6))
                        .font(.system(size: 14))

                    Text("Correct: \(answer.question.correctAnswer)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.neonGreen.opacity(0.6))
                }
            }

            // Confidence + time
            if let confidence = answer.confidence {
                HStack(spacing: 12) {
                    Text(confidence.label)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))

                    Text("·")
                        .foregroundColor(.white.opacity(0.2))

                    Text(String(format: "%.1fs", answer.timeSpent))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            answer.isCorrect
                                ? Color.neonGreen.opacity(0.1)
                                : (answer.isSkipped ? Color.quizzeraGold.opacity(0.1) : Color.dangerRed.opacity(0.1)),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    let colors: [Color] = [.quizzeraGold, .neonGreen, .electricPurple, .orange, .pink, .cyan]
    let particleCount = 50

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { i in
                    ConfettiPiece(
                        color: colors[i % colors.count],
                        screenSize: geo.size
                    )
                }
            }
        }
    }
}

struct ConfettiPiece: View {
    let color: Color
    let screenSize: CGSize

    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1

    private let shape: Int = Int.random(in: 0...2) // 0=circle, 1=rect, 2=triangle

    var body: some View {
        Group {
            switch shape {
            case 0:
                Circle().fill(color).frame(width: 8, height: 8)
            case 1:
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 6, height: 12)
            default:
                Rectangle().fill(color).frame(width: 8, height: 8)
                    .rotationEffect(.degrees(45))
            }
        }
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .position(position)
        .opacity(opacity)
        .onAppear {
            let startX = CGFloat.random(in: 0...screenSize.width)
            position = CGPoint(x: startX, y: -20)

            let endX = startX + CGFloat.random(in: -100...100)
            let endY = screenSize.height + 50

            let duration = Double.random(in: 2.0...4.0)
            let delay = Double.random(in: 0...0.8)

            withAnimation(.easeIn(duration: duration).delay(delay)) {
                position = CGPoint(x: endX, y: endY)
                rotation = Double.random(in: 360...1080)
            }

            withAnimation(.easeIn(duration: 0.5).delay(delay + duration - 0.5)) {
                opacity = 0
                scale = 0.3
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ResultScreenView(
            result: QuizResult(
                playerName: "Deepanshu",
                category: .technology,
                totalQuestions: 10,
                correctCount: 10,
                wrongCount: 0,
                skippedCount: 0,
                totalScore: 140,
                maxPossibleScore: 150,
                streak: 10,
                answers: [],
                confidenceResults: ConfidenceReport()
            )
        )
        .environmentObject(UserDataViewModel())
    }
}
