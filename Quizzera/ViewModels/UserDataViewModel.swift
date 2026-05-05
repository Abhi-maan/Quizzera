//
//  UserDataViewModel.swift
//  Quizzera
//
//  Created on 2026-04-27.
//  Persistence layer — UserDefaults for user data, leaderboard, XP, streaks, score history.
//

import SwiftUI
import Combine

// MARK: - Score History Entry

/// Lightweight record of a completed quiz for the score history chart.
struct ScoreHistoryEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let score: Int
    let maxScore: Int
    let category: Category
    let correctCount: Int
    let totalQuestions: Int

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        score: Int,
        maxScore: Int,
        category: Category,
        correctCount: Int,
        totalQuestions: Int
    ) {
        self.id = id
        self.date = date
        self.score = score
        self.maxScore = maxScore
        self.category = category
        self.correctCount = correctCount
        self.totalQuestions = totalQuestions
    }

    /// Score as a percentage (0.0–1.0) for the sparkline chart.
    var scoreFraction: Double {
        guard maxScore > 0 else { return 0 }
        return Double(score) / Double(maxScore)
    }
}

/// Manages all persisted user data via UserDefaults.
@MainActor
final class UserDataViewModel: ObservableObject {

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let playerName       = "quizzera_playerName"
        static let hasLaunched      = "quizzera_hasLaunched"
        static let bestScore        = "quizzera_bestScore"
        static let totalQuizzes     = "quizzera_totalQuizzes"
        static let totalCorrect     = "quizzera_totalCorrect"
        static let totalAnswered    = "quizzera_totalAnswered"
        static let leaderboard      = "quizzera_leaderboard"
        static let categoryXP       = "quizzera_categoryXP"
        static let currentSessionId = "quizzera_currentSessionId"
        static let dailyStreak      = "quizzera_dailyStreak"
        static let lastPlayDate     = "quizzera_lastPlayDate"
        static let scoreHistory     = "quizzera_scoreHistory"
    }

    // MARK: - Published State

    /// The player's display name.
    @Published var playerName: String {
        didSet { UserDefaults.standard.set(playerName, forKey: Keys.playerName) }
    }

    /// Whether this is the first app launch (triggers name entry).
    @Published var hasLaunched: Bool {
        didSet { UserDefaults.standard.set(hasLaunched, forKey: Keys.hasLaunched) }
    }

    /// Highest single-quiz score ever achieved.
    @Published var bestScore: Int {
        didSet { UserDefaults.standard.set(bestScore, forKey: Keys.bestScore) }
    }

    /// Total number of quizzes completed.
    @Published var totalQuizzes: Int {
        didSet { UserDefaults.standard.set(totalQuizzes, forKey: Keys.totalQuizzes) }
    }

    /// Total correct answers across all quizzes.
    @Published var totalCorrect: Int {
        didSet { UserDefaults.standard.set(totalCorrect, forKey: Keys.totalCorrect) }
    }

    /// Total questions answered across all quizzes.
    @Published var totalAnswered: Int {
        didSet { UserDefaults.standard.set(totalAnswered, forKey: Keys.totalAnswered) }
    }

    /// Top 5 leaderboard entries.
    @Published var leaderboard: [LeaderboardEntry] = []

    /// XP data per category.
    @Published var categoryXPData: [Category: CategoryXP] = [:]

    /// ID of the most recently completed quiz (for highlighting in leaderboard).
    @Published var currentSessionId: UUID? = nil

    /// Number of consecutive days the user has played.
    @Published var dailyStreak: Int {
        didSet { UserDefaults.standard.set(dailyStreak, forKey: Keys.dailyStreak) }
    }

    /// Date the user last completed a quiz.
    @Published var lastPlayDate: Date? {
        didSet {
            if let date = lastPlayDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Keys.lastPlayDate)
            }
        }
    }

    /// Score history for the sparkline chart (last 10 entries).
    @Published var scoreHistory: [ScoreHistoryEntry] = []

    // MARK: - Computed

    /// Overall accuracy percentage across all quizzes.
    var accuracyPercent: Double {
        guard totalAnswered > 0 else { return 0 }
        return (Double(totalCorrect) / Double(totalAnswered)) * 100
    }

    /// Formatted accuracy string.
    var accuracyString: String {
        String(format: "%.0f%%", accuracyPercent)
    }

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard

        self.playerName    = defaults.string(forKey: Keys.playerName) ?? ""
        self.hasLaunched   = defaults.bool(forKey: Keys.hasLaunched)
        self.bestScore     = defaults.integer(forKey: Keys.bestScore)
        self.totalQuizzes  = defaults.integer(forKey: Keys.totalQuizzes)
        self.totalCorrect  = defaults.integer(forKey: Keys.totalCorrect)
        self.totalAnswered = defaults.integer(forKey: Keys.totalAnswered)
        self.dailyStreak   = defaults.integer(forKey: Keys.dailyStreak)

        // Load last play date
        let lastPlayTimestamp = defaults.double(forKey: Keys.lastPlayDate)
        if lastPlayTimestamp > 0 {
            self.lastPlayDate = Date(timeIntervalSince1970: lastPlayTimestamp)
        } else {
            self.lastPlayDate = nil
        }

        // Load leaderboard
        if let data = defaults.data(forKey: Keys.leaderboard),
           let decoded = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) {
            self.leaderboard = decoded
        }

        // Load category XP
        if let data = defaults.data(forKey: Keys.categoryXP),
           let decoded = try? JSONDecoder().decode([String: CategoryXP].self, from: data) {
            var xpMap: [Category: CategoryXP] = [:]
            for (key, value) in decoded {
                if let cat = Category(rawValue: key) {
                    xpMap[cat] = value
                }
            }
            self.categoryXPData = xpMap
        }

        // Load score history
        if let data = defaults.data(forKey: Keys.scoreHistory),
           let decoded = try? JSONDecoder().decode([ScoreHistoryEntry].self, from: data) {
            self.scoreHistory = decoded
        }

        // Ensure all categories have an entry
        for cat in Category.allCases {
            if categoryXPData[cat] == nil {
                categoryXPData[cat] = CategoryXP(category: cat)
            }
        }
    }

    // MARK: - Save Player Name

    /// Save the player's name and mark as launched.
    func saveName(_ name: String) {
        playerName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        hasLaunched = true
    }

    // MARK: - Record Quiz Result

    /// Process and persist a completed quiz result.
    func recordResult(_ result: QuizResult) {
        // Update aggregate stats
        totalQuizzes += 1
        totalCorrect += result.correctCount
        totalAnswered += result.totalQuestions - result.skippedCount

        // Update best score
        if result.totalScore > bestScore {
            bestScore = result.totalScore
        }

        // Add to leaderboard
        let entry = LeaderboardEntry(
            playerName: result.playerName,
            score: result.totalScore,
            category: result.category,
            date: result.date
        )
        currentSessionId = entry.id

        leaderboard.append(entry)
        leaderboard.sort() // uses Comparable (descending by score)
        if leaderboard.count > 5 {
            leaderboard = Array(leaderboard.prefix(5))
        }
        saveLeaderboard()

        // Update category XP
        let xpGained = calculateXP(for: result)
        addXP(xpGained, to: result.category)

        // Update daily streak
        updateDailyStreak()

        // Record score history
        addScoreHistoryEntry(for: result)
    }

    // MARK: - Daily Streak

    /// Update the daily play streak based on last play date.
    private func updateDailyStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastPlayDate {
            let lastDay = calendar.startOfDay(for: lastDate)

            if calendar.isDate(lastDay, inSameDayAs: today) {
                // Already played today — no change
            } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                      calendar.isDate(lastDay, inSameDayAs: yesterday) {
                // Played yesterday — increment streak
                dailyStreak += 1
            } else {
                // Missed a day — reset streak
                dailyStreak = 1
            }
        } else {
            // First time playing
            dailyStreak = 1
        }

        lastPlayDate = Date()
    }

    // MARK: - Score History

    /// Add a score history entry and persist (keep last 10).
    private func addScoreHistoryEntry(for result: QuizResult) {
        let entry = ScoreHistoryEntry(
            score: result.totalScore,
            maxScore: result.maxPossibleScore,
            category: result.category,
            correctCount: result.correctCount,
            totalQuestions: result.totalQuestions
        )
        scoreHistory.append(entry)

        // Keep only the last 10 entries
        if scoreHistory.count > 10 {
            scoreHistory = Array(scoreHistory.suffix(10))
        }

        saveScoreHistory()
    }

    /// Save score history to UserDefaults.
    private func saveScoreHistory() {
        if let data = try? JSONEncoder().encode(scoreHistory) {
            UserDefaults.standard.set(data, forKey: Keys.scoreHistory)
        }
    }

    // MARK: - Leaderboard Persistence

    /// Save leaderboard to UserDefaults.
    private func saveLeaderboard() {
        if let data = try? JSONEncoder().encode(leaderboard) {
            UserDefaults.standard.set(data, forKey: Keys.leaderboard)
        }
    }

    // MARK: - Category XP

    /// Get the XP data for a specific category.
    func xp(for category: Category) -> CategoryXP {
        categoryXPData[category] ?? CategoryXP(category: category)
    }

    /// Calculate XP earned from a quiz result.
    private func calculateXP(for result: QuizResult) -> Int {
        var xp = result.correctCount * 5  // 5 XP per correct answer
        xp += result.totalScore / 3       // bonus from speed points

        // Streak bonus
        if result.streak >= 5 { xp += 10 }
        if result.streak >= 8 { xp += 15 }
        if result.streak == 10 { xp += 25 }

        // Perfect score bonus
        if result.correctCount == result.totalQuestions {
            xp += 20
        }

        return xp
    }

    /// Add XP to a specific category and persist.
    private func addXP(_ amount: Int, to category: Category) {
        var current = categoryXPData[category] ?? CategoryXP(category: category)
        current.xp += amount
        categoryXPData[category] = current
        saveCategoryXP()
    }

    /// Save all category XP data to UserDefaults.
    private func saveCategoryXP() {
        var encoded: [String: CategoryXP] = [:]
        for (cat, xp) in categoryXPData {
            encoded[cat.rawValue] = xp
        }
        if let data = try? JSONEncoder().encode(encoded) {
            UserDefaults.standard.set(data, forKey: Keys.categoryXP)
        }
    }

    // MARK: - Reset (Debug)

    /// Clear all persisted data. Useful for testing.
    func resetAllData() {
        let defaults = UserDefaults.standard
        for key in [Keys.playerName, Keys.hasLaunched, Keys.bestScore,
                    Keys.totalQuizzes, Keys.totalCorrect, Keys.totalAnswered,
                    Keys.leaderboard, Keys.categoryXP, Keys.dailyStreak,
                    Keys.lastPlayDate, Keys.scoreHistory] {
            defaults.removeObject(forKey: key)
        }

        playerName = ""
        hasLaunched = false
        bestScore = 0
        totalQuizzes = 0
        totalCorrect = 0
        totalAnswered = 0
        leaderboard = []
        currentSessionId = nil
        dailyStreak = 0
        lastPlayDate = nil
        scoreHistory = []

        categoryXPData = [:]
        for cat in Category.allCases {
            categoryXPData[cat] = CategoryXP(category: cat)
        }
    }
}
