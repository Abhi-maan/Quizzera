//
//  QuizScreenView.swift
//  Quizzera
//
//  Created on 2026-04-27.
//  Core gameplay — timer, question cards, answers, confidence, streak, skip.
//

import SwiftUI

struct QuizScreenView: View {

    @ObservedObject var viewModel: QuizViewModel
    @EnvironmentObject var userData: UserDataViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var questionTransitionId = UUID()
    @State private var showResult = false

    var body: some View {
        ZStack {
            Color.quizzeraBg.ignoresSafeArea()

            if viewModel.quizFinished {
                // Navigate to result
                Color.clear
                    .onAppear {
                        showResult = true
                    }
            } else if let question = viewModel.currentQuestion {
                VStack(spacing: 0) {
                    // Top bar
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Progress bar
                    progressBar
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Timer + Score
                            timerAndScoreRow
                                .padding(.top, 20)

                            // Question card
                            questionCard(question)
                                .id(questionTransitionId)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))

                            // Confidence picker (phase 2)
                            if viewModel.answerPhase == .confidence {
                                confidencePicker
                                    .transition(.scale.combined(with: .opacity))
                            }

                            // Answer options
                            answerOptions(question)
                                .padding(.top, 4)

                            // Skip button
                            if viewModel.answerPhase == .answering {
                                skipButton
                                    .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }

                // Streak toast overlay
                if let toast = viewModel.streakToast {
                    streakToastView(toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showResult) {
            ResultScreenView(
                result: viewModel.buildResult(playerName: userData.playerName)
            )
            .environmentObject(userData)
        }
        .onChange(of: viewModel.currentIndex) { _, _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                questionTransitionId = UUID()
            }
        }
        .onChange(of: showResult) { _, newValue in
            // When Result screen is dismissed (Play Again tapped), restart the same quiz
            if !newValue && viewModel.quizFinished {
                viewModel.startQuiz(category: viewModel.category)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.bounce)

            Spacer()

            // Question counter
            Text(viewModel.questionCounterText)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(Color.cardBg)
                        .overlay(
                            Capsule().stroke(Color.electricPurple.opacity(0.3), lineWidth: 1)
                        )
                )

            Spacer()

            // Streak indicator
            if viewModel.currentStreak >= 2 {
                HStack(spacing: 3) {
                    Text("🔥")
                        .font(.system(size: 14))
                    Text("\(viewModel.currentStreak)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(Color.orange.opacity(0.15))
                )
                .transition(.scale.combined(with: .opacity))
            } else {
                Color.clear.frame(width: 36, height: 36)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.08))

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.electricPurple, .neonGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * viewModel.progressFraction)
                    .animation(.spring(response: 0.4), value: viewModel.progressFraction)
            }
        }
        .frame(height: 5)
    }

    // MARK: - Timer & Score Row

    private var timerAndScoreRow: some View {
        HStack(spacing: 20) {
            Spacer()

            // Circular timer
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 5)
                    .frame(width: 68, height: 68)

                Circle()
                    .trim(from: 0, to: viewModel.timerFraction)
                    .stroke(
                        viewModel.timerDanger ? Color.dangerRed : Color.neonGreen,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 68, height: 68)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.05), value: viewModel.timerFraction)

                VStack(spacing: 1) {
                    Text("\(Int(viewModel.timeRemaining))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.timerDanger ? .dangerRed : .white)
                        .contentTransition(.numericText())

                    Text("sec")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            // Score display
            VStack(spacing: 4) {
                Text("SCORE")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(2)

                Text("\(viewModel.totalScore)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.neonGreen)
                    .contentTransition(.numericText())

                // Timer bonus indicator
                if viewModel.answerPhase == .answering {
                    Text("+\(viewModel.currentTimerBonus) pts")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(bonusColor)
                        .contentTransition(.numericText())
                }
            }

            Spacer()
        }
    }

    private var bonusColor: Color {
        switch viewModel.currentTimerBonus {
        case 15: return .neonGreen
        case 10: return .quizzeraGold
        case 5:  return .orange
        default: return .dangerRed
        }
    }

    // MARK: - Question Card

    private func questionCard(_ question: Question) -> some View {
        VStack(spacing: 12) {
            // Difficulty badge
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: question.difficulty.iconName)
                        .font(.system(size: 10))
                    Text(question.difficulty.rawValue)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundColor(.electricPurple.opacity(0.8))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(Color.electricPurple.opacity(0.12))
                )

                Spacer()

                Image(systemName: question.category.iconName)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }

            Text(question.text)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.electricPurple.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .electricPurple.opacity(0.08), radius: 12, y: 4)
        )
    }

    // MARK: - Answer Options

    private func answerOptions(_ question: Question) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                answerButton(
                    index: index,
                    text: option,
                    correctIndex: question.correctIndex
                )
            }
        }
    }

    private func answerButton(index: Int, text: String, correctIndex: Int) -> some View {
        let isSelected = viewModel.selectedAnswerIndex == index
        let isCorrect = index == correctIndex
        let revealed = viewModel.answerRevealed

        let bgColor: Color = {
            if revealed {
                if isCorrect { return Color.neonGreen.opacity(0.2) }
                if isSelected && !isCorrect { return Color.dangerRed.opacity(0.2) }
            }
            if isSelected && !revealed { return Color.electricPurple.opacity(0.25) }
            return Color.cardBg
        }()

        let borderColor: Color = {
            if revealed {
                if isCorrect { return .neonGreen.opacity(0.6) }
                if isSelected && !isCorrect { return .dangerRed.opacity(0.6) }
            }
            if isSelected && !revealed { return .electricPurple.opacity(0.5) }
            return Color.white.opacity(0.06)
        }()

        let textColor: Color = {
            if revealed && isCorrect { return .neonGreen }
            if revealed && isSelected && !isCorrect { return .dangerRed }
            return .white.opacity(0.9)
        }()

        return Button {
            viewModel.selectAnswer(at: index)
        } label: {
            HStack(spacing: 14) {
                // Option letter
                Text(optionLetter(index))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected || (revealed && isCorrect) ? .white : .white.opacity(0.5))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle().fill(
                            isSelected || (revealed && isCorrect)
                                ? (revealed && isCorrect ? Color.neonGreen.opacity(0.4) : Color.electricPurple.opacity(0.4))
                                : Color.white.opacity(0.06)
                        )
                    )

                Text(text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Result icon
                if revealed {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.neonGreen)
                            .transition(.scale.combined(with: .opacity))
                    } else if isSelected {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.dangerRed)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(bgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(borderColor, lineWidth: 1.5)
                    )
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: revealed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.bounce)
        .disabled(viewModel.answerPhase != .answering && viewModel.answerPhase != .confidence)
    }

    // MARK: - Confidence Picker

    private var confidencePicker: some View {
        VStack(spacing: 12) {
            Text("How confident are you?")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            HStack(spacing: 12) {
                ForEach(ConfidenceLevel.allCases, id: \.rawValue) { level in
                    Button {
                        viewModel.selectConfidence(level)
                    } label: {
                        VStack(spacing: 4) {
                            Text(level.emoji)
                                .font(.system(size: 26))
                            Text(level.rawValue)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cardBg)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.electricPurple.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.bounce)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.quizzeraBg.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.neonGreen.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Skip Button

    private var skipButton: some View {
        Button {
            viewModel.skipQuestion()
        } label: {
            HStack(spacing: 6) {
                Text("⚡")
                    .font(.system(size: 14))
                Text("Skip")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(viewModel.skipAvailable ? .quizzeraGold : .white.opacity(0.2))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(viewModel.skipAvailable ? Color.quizzeraGold.opacity(0.12) : Color.white.opacity(0.04))
                    .overlay(
                        Capsule()
                            .stroke(
                                viewModel.skipAvailable ? Color.quizzeraGold.opacity(0.3) : Color.white.opacity(0.06),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.bounce)
        .disabled(!viewModel.skipAvailable)
        .opacity(viewModel.skipAvailable ? 1.0 : 0.4)
        .animation(.easeInOut(duration: 0.3), value: viewModel.skipAvailable)
    }

    // MARK: - Streak Toast

    private func streakToastView(_ text: String) -> some View {
        VStack {
            Text(text)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .orange.opacity(0.4), radius: 10, y: 4)
                )
                .padding(.top, 80)

            Spacer()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private func optionLetter(_ index: Int) -> String {
        ["A", "B", "C", "D"][index]
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QuizScreenView(viewModel: {
            let vm = QuizViewModel()
            vm.startQuiz(category: .generalKnowledge)
            return vm
        }())
        .environmentObject(UserDataViewModel())
    }
}
