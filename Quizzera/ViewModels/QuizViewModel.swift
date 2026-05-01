//
//  QuizViewModel.swift
//  Quizzera
//
//  Created on 2026-04-27.
//  Core game logic — timer, scoring, streaks, confidence, skip.
//

import SwiftUI
import Combine

/// Manages all quiz gameplay state and logic.
@MainActor
final class QuizViewModel: ObservableObject {

    // MARK: - Published State

    /// Current list of questions for this session.
    @Published var questions: [Question] = []

    /// Index of the current question (0-based).
    @Published var currentIndex: Int = 0

    /// Timer countdown value (15 → 0).
    @Published var timeRemaining: Double = 15.0

    /// Whether the timer is actively counting down.
    @Published var timerActive: Bool = false

    /// Total accumulated score.
    @Published var totalScore: Int = 0

    /// Current consecutive-correct streak.
    @Published var currentStreak: Int = 0

    /// Best streak achieved this session.
    @Published var bestStreak: Int = 0

    /// Whether the skip lifeline is still available.
    @Published var skipAvailable: Bool = true

    /// The index the player selected for the current question (nil = unanswered).
    @Published var selectedAnswerIndex: Int? = nil

    /// Whether the current answer has been revealed (correct/wrong shown).
    @Published var answerRevealed: Bool = false

    /// Whether the quiz is fully complete.
    @Published var quizFinished: Bool = false

    /// Current phase of the answer flow.
    @Published var answerPhase: AnswerPhase = .answering

    /// Selected confidence level for current question.
    @Published var selectedConfidence: ConfidenceLevel? = nil

    /// Streak toast message to display.
    @Published var streakToast: String? = nil

    /// All answer records for this session.
    @Published var answerRecords: [AnswerRecord] = []

    /// The selected category for this quiz.
    @Published var category: Category = .generalKnowledge

    // MARK: - Scoring Counters

    @Published var correctCount: Int = 0
    @Published var wrongCount: Int = 0
    @Published var skippedCount: Int = 0

    // MARK: - Confidence Tracking

    @Published var confidenceReport = ConfidenceReport()

    // MARK: - Constants

    static let totalTime: Double = 15.0
    static let questionCount: Int = 10

    // MARK: - Private

    private var timerCancellable: AnyCancellable?
    private var questionStartTime: Date = Date()

    // MARK: - Computed Properties

    /// Current question being displayed.
    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    /// Progress fraction (0.0–1.0) through the quiz.
    var progressFraction: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(questions.count)
    }

    /// Timer fraction remaining (1.0 → 0.0).
    var timerFraction: Double {
        timeRemaining / Self.totalTime
    }

    /// Whether the timer is in the danger zone (< 5 seconds).
    var timerDanger: Bool {
        timeRemaining < 5.0
    }

    /// Display string for question counter.
    var questionCounterText: String {
        "Q\(currentIndex + 1)/\(questions.count)"
    }

    /// Points earned for current answer based on time spent.
    var currentTimerBonus: Int {
        let elapsed = Self.totalTime - timeRemaining
        if elapsed <= 5 { return 15 }
        if elapsed <= 10 { return 10 }
        if elapsed <= 15 { return 5 }
        return 0
    }

    /// Maximum possible score if all answers were perfect (15 pts each).
    var maxPossibleScore: Int {
        questions.count * 15
    }

    // MARK: - Answer Phase

    /// Tracks the multi-step answer reveal flow.
    enum AnswerPhase: Equatable {
        case answering        // Player is selecting an answer
        case confidence       // Asking for confidence level
        case revealed         // Answer correctness shown
        case transitioning    // Brief pause before next question
    }

    // MARK: - Start Quiz

    /// Initialize and start a new quiz session for the given category.
    func startQuiz(category: Category) {
        self.category = category
        self.questions = QuizData.questions(for: category)
        self.currentIndex = 0
        self.totalScore = 0
        self.correctCount = 0
        self.wrongCount = 0
        self.skippedCount = 0
        self.currentStreak = 0
        self.bestStreak = 0
        self.skipAvailable = true
        self.selectedAnswerIndex = nil
        self.answerRevealed = false
        self.quizFinished = false
        self.answerPhase = .answering
        self.selectedConfidence = nil
        self.streakToast = nil
        self.answerRecords = []
        self.confidenceReport = ConfidenceReport()
        self.questionStartTime = Date()

        startTimer()
    }

    // MARK: - Timer

    /// Start the countdown timer using Combine.
    private func startTimer() {
        timeRemaining = Self.totalTime
        timerActive = true
        questionStartTime = Date()

        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.timerActive else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 0.05
                    if self.timeRemaining < 0 { self.timeRemaining = 0 }
                } else {
                    self.handleTimeout()
                }
            }
    }

    /// Stop the countdown timer.
    private func stopTimer() {
        timerActive = false
        timerCancellable?.cancel()
    }

    // MARK: - Answer Selection

    /// Called when the player taps an answer option.
    func selectAnswer(at index: Int) {
        guard answerPhase == .answering || answerPhase == .confidence else { return }

        selectedAnswerIndex = index

        // Stop timer on first selection only
        if answerPhase == .answering {
            stopTimer()
        }

        // Move to confidence phase
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            answerPhase = .confidence
        }
    }

    /// Called when the player selects their confidence level.
    func selectConfidence(_ level: ConfidenceLevel) {
        guard answerPhase == .confidence else { return }

        selectedConfidence = level
        revealAnswer()
    }

    /// Skip the confidence step and go straight to reveal (used for timeout).
    private func revealAnswer() {
        guard let question = currentQuestion,
              let selected = selectedAnswerIndex else { return }

        let isCorrect = selected == question.correctIndex
        let timeSpent = Self.totalTime - timeRemaining
        let points = isCorrect ? currentTimerBonus : 0

        // Update scores
        if isCorrect {
            totalScore += points
            correctCount += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            checkStreakToast()
        } else {
            wrongCount += 1
            currentStreak = 0
        }

        // Update confidence report
        if let conf = selectedConfidence {
            switch conf {
            case .sure:
                confidenceReport.totalConfident += 1
                if isCorrect { confidenceReport.confidentAndCorrect += 1 }
            case .unsure:
                confidenceReport.totalUnsure += 1
                if isCorrect { confidenceReport.unsureAndCorrect += 1 }
            case .guessed:
                confidenceReport.totalGuessed += 1
                if isCorrect { confidenceReport.guessedAndCorrect += 1 }
            }
        }

        // Record answer
        let record = AnswerRecord(
            question: question,
            selectedIndex: selected,
            isCorrect: isCorrect,
            isSkipped: false,
            timeSpent: timeSpent,
            pointsEarned: points,
            confidence: selectedConfidence
        )
        answerRecords.append(record)

        // Show result
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            answerRevealed = true
            answerPhase = .revealed
        }

        // Auto-advance after delay
        scheduleNextQuestion()
    }

    // MARK: - Timeout

    /// Called when the timer runs out without an answer.
    private func handleTimeout() {
        guard answerPhase == .answering else { return }

        stopTimer()

        guard let question = currentQuestion else { return }

        // Record as wrong (timed out)
        wrongCount += 1
        currentStreak = 0

        let record = AnswerRecord(
            question: question,
            selectedIndex: nil,
            isCorrect: false,
            isSkipped: false,
            timeSpent: Self.totalTime,
            pointsEarned: 0,
            confidence: nil
        )
        answerRecords.append(record)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            answerRevealed = true
            answerPhase = .revealed
        }

        scheduleNextQuestion()
    }

    // MARK: - Skip

    /// Use the skip lifeline on the current question.
    func skipQuestion() {
        guard skipAvailable, answerPhase == .answering else { return }

        stopTimer()
        skipAvailable = false

        guard let question = currentQuestion else { return }

        skippedCount += 1
        currentStreak = 0

        let record = AnswerRecord(
            question: question,
            selectedIndex: nil,
            isCorrect: false,
            isSkipped: true,
            timeSpent: Self.totalTime - timeRemaining,
            pointsEarned: 0,
            confidence: nil
        )
        answerRecords.append(record)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            answerRevealed = true
            answerPhase = .revealed
        }

        scheduleNextQuestion()
    }

    // MARK: - Navigation

    /// Schedule auto-advance to the next question after a delay.
    private func scheduleNextQuestion() {
        Task {
            try? await Task.sleep(for: .milliseconds(1200))
            await advanceToNext()
        }
    }

    /// Move to the next question or finish the quiz.
    private func advanceToNext() {
        let nextIndex = currentIndex + 1

        if nextIndex >= questions.count {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                quizFinished = true
            }
            return
        }

        // Reset for next question
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentIndex = nextIndex
            selectedAnswerIndex = nil
            answerRevealed = false
            answerPhase = .answering
            selectedConfidence = nil
            streakToast = nil
        }

        startTimer()
    }

    // MARK: - Streak Toasts

    /// Check and display streak milestone toasts.
    private func checkStreakToast() {
        switch currentStreak {
        case 3:
            streakToast = "3 in a row! 🔥"
        case 5:
            streakToast = "5 in a row! On fire! 🔥🔥"
        case 7:
            streakToast = "7 in a row! UNSTOPPABLE! 🔥🔥🔥"
        case 10:
            streakToast = "PERFECT STREAK! 💎🔥"
        default:
            if currentStreak > 2 {
                streakToast = "\(currentStreak) streak! 🔥"
            }
        }

        // Auto-dismiss toast
        if streakToast != nil {
            Task {
                try? await Task.sleep(for: .milliseconds(1500))
                withAnimation { streakToast = nil }
            }
        }
    }

    // MARK: - Build Result

    /// Compile the final quiz result from session data.
    func buildResult(playerName: String) -> QuizResult {
        QuizResult(
            playerName: playerName,
            category: category,
            totalQuestions: questions.count,
            correctCount: correctCount,
            wrongCount: wrongCount,
            skippedCount: skippedCount,
            totalScore: totalScore,
            maxPossibleScore: maxPossibleScore,
            streak: bestStreak,
            answers: answerRecords,
            confidenceResults: confidenceReport
        )
    }

    // MARK: - Cleanup

    deinit {
        timerCancellable?.cancel()
    }
}
