//
//  UserDataViewModel.swift
//  Quizzera
//
//  Created on 2026-04-27.
//  Persistence layer — UserDefaults for user data, leaderboard, XP.
//

import SwiftUI
import Combine

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
                    Keys.leaderboard, Keys.categoryXP] {
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

        categoryXPData = [:]
        for cat in Category.allCases {
            categoryXPData[cat] = CategoryXP(category: cat)
        }
    }
}
