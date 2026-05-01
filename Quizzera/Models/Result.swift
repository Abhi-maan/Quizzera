//
//  Result.swift
//  Quizzera
//
//  Created on 2026-04-27.
//

import Foundation

// MARK: - Quiz Result

/// Stores the complete result of a finished quiz session.
struct QuizResult: Identifiable, Codable {
    let id: UUID
    let playerName: String
    let category: Category
    let totalQuestions: Int
    let correctCount: Int
    let wrongCount: Int
    let skippedCount: Int
    let totalScore: Int
    let maxPossibleScore: Int
    let streak: Int
    let answers: [AnswerRecord]
    let confidenceResults: ConfidenceReport
    let date: Date

    init(
        id: UUID = UUID(),
        playerName: String,
        category: Category,
        totalQuestions: Int,
        correctCount: Int,
        wrongCount: Int,
        skippedCount: Int,
        totalScore: Int,
        maxPossibleScore: Int,
        streak: Int,
        answers: [AnswerRecord],
        confidenceResults: ConfidenceReport,
        date: Date = Date()
    ) {
        self.id = id
        self.playerName = playerName
        self.category = category
        self.totalQuestions = totalQuestions
        self.correctCount = correctCount
        self.wrongCount = wrongCount
        self.skippedCount = skippedCount
        self.totalScore = totalScore
        self.maxPossibleScore = maxPossibleScore
        self.streak = streak
        self.answers = answers
        self.confidenceResults = confidenceResults
        self.date = date
    }

    /// Accuracy as a percentage (0–100).
    var accuracyPercent: Double {
        let attempted = totalQuestions - skippedCount
        guard attempted > 0 else { return 0 }
        return (Double(correctCount) / Double(attempted)) * 100
    }

    /// Performance badge based on correct answer count.
    var performanceBadge: PerformanceBadge {
        switch correctCount {
        case 0...4:  return .keepLearning
        case 5...7:  return .gettingSharp
        case 8...9:  return .knowledgeUnlocked
        case 10:     return .legendary
        default:     return .keepLearning
        }
    }

    /// Formatted date string for display.
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Answer Record

/// Records a player's answer for a single question.
struct AnswerRecord: Identifiable, Codable {
    let id: UUID
    let question: Question
    let selectedIndex: Int?       // nil if skipped
    let isCorrect: Bool
    let isSkipped: Bool
    let timeSpent: Double         // seconds taken to answer
    let pointsEarned: Int
    let confidence: ConfidenceLevel?

    init(
        id: UUID = UUID(),
        question: Question,
        selectedIndex: Int?,
        isCorrect: Bool,
        isSkipped: Bool,
        timeSpent: Double,
        pointsEarned: Int,
        confidence: ConfidenceLevel?
    ) {
        self.id = id
        self.question = question
        self.selectedIndex = selectedIndex
        self.isCorrect = isCorrect
        self.isSkipped = isSkipped
        self.timeSpent = timeSpent
        self.pointsEarned = pointsEarned
        self.confidence = confidence
    }

    /// The player's selected answer text, or "Skipped" / "Time's Up".
    var selectedAnswerText: String {
        guard let idx = selectedIndex else {
            return isSkipped ? "Skipped" : "Time's Up"
        }
        return question.options[idx]
    }
}

// MARK: - Confidence Level

/// Player's self-assessed confidence before answer reveal.
enum ConfidenceLevel: String, Codable, CaseIterable {
    case guessed = "Guessed"
    case unsure  = "Unsure"
    case sure    = "Sure"

    var emoji: String {
        switch self {
        case .guessed: return "😅"
        case .unsure:  return "🤔"
        case .sure:    return "😎"
        }
    }

    var label: String {
        "\(emoji) \(rawValue)"
    }
}

// MARK: - Confidence Report

/// Aggregated confidence-vs-accuracy insights for the results screen.
struct ConfidenceReport: Codable {
    var totalConfident: Int      // times player chose "Sure"
    var confidentAndCorrect: Int // times "Sure" was actually correct
    var totalGuessed: Int        // times player chose "Guessed"
    var guessedAndCorrect: Int   // times "Guessed" was actually correct
    var totalUnsure: Int
    var unsureAndCorrect: Int

    init() {
        self.totalConfident = 0
        self.confidentAndCorrect = 0
        self.totalGuessed = 0
        self.guessedAndCorrect = 0
        self.totalUnsure = 0
        self.unsureAndCorrect = 0
    }

    /// Human-readable insight string for the results screen.
    var insightText: String {
        if totalConfident > 0 {
            let pct = Int((Double(confidentAndCorrect) / Double(totalConfident)) * 100)
            if pct >= 80 {
                return "You were confident \(totalConfident) time\(totalConfident == 1 ? "" : "s") and got \(confidentAndCorrect) right — great calibration! 🎯"
            } else if pct >= 50 {
                return "You felt sure \(totalConfident) time\(totalConfident == 1 ? "" : "s") but got \(confidentAndCorrect) right — room to improve!"
            } else {
                return "Confidence was high but accuracy was low — trust your gut less? 🤷"
            }
        }
        if totalGuessed > 0 && guessedAndCorrect > 0 {
            return "You guessed \(totalGuessed) time\(totalGuessed == 1 ? "" : "s") and still got \(guessedAndCorrect) right — lucky streak! 🍀"
        }
        return "Complete more quizzes to see confidence insights!"
    }
}

// MARK: - Performance Badge

/// Badge awarded based on quiz score.
enum PerformanceBadge: String, Codable {
    case keepLearning     = "Keep Learning 📖"
    case gettingSharp     = "Getting Sharp ⚡"
    case knowledgeUnlocked = "Knowledge Unlocked 🧠"
    case legendary        = "LEGENDARY 🏆"

    /// Whether this badge triggers confetti animation.
    var showConfetti: Bool {
        self == .legendary
    }
}

// MARK: - Leaderboard Entry

/// A single entry in the leaderboard, persisted in UserDefaults.
struct LeaderboardEntry: Identifiable, Codable, Comparable {
    let id: UUID
    let playerName: String
    let score: Int
    let category: Category
    let date: Date

    init(
        id: UUID = UUID(),
        playerName: String,
        score: Int,
        category: Category,
        date: Date = Date()
    ) {
        self.id = id
        self.playerName = playerName
        self.score = score
        self.category = category
        self.date = date
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    /// Sort by score descending.
    static func < (lhs: LeaderboardEntry, rhs: LeaderboardEntry) -> Bool {
        lhs.score > rhs.score
    }
}

// MARK: - Category XP

/// Tracks experience points and level for a specific category.
struct CategoryXP: Codable {
    var xp: Int
    var category: Category

    init(xp: Int = 0, category: Category) {
        self.xp = xp
        self.category = category
    }

    /// Current XP level based on accumulated points.
    var level: XPLevel {
        switch xp {
        case 0..<50:    return .novice
        case 50..<150:  return .apprentice
        case 150..<300: return .scholar
        case 300..<500: return .master
        default:        return .legendary
        }
    }

    /// Progress fraction toward next level (0.0–1.0).
    var progressToNext: Double {
        let thresholds = [0, 50, 150, 300, 500]
        let currentIdx = level.index
        guard currentIdx < thresholds.count - 1 else { return 1.0 }
        let low = thresholds[currentIdx]
        let high = thresholds[currentIdx + 1]
        return Double(xp - low) / Double(high - low)
    }
}

/// XP level tiers for each category.
enum XPLevel: String, Codable, CaseIterable {
    case novice     = "Novice"
    case apprentice = "Apprentice"
    case scholar    = "Scholar"
    case master     = "Master"
    case legendary  = "Legendary"

    var emoji: String {
        switch self {
        case .novice:     return "🌱"
        case .apprentice: return "📘"
        case .scholar:    return "🎓"
        case .master:     return "👑"
        case .legendary:  return "🏆"
        }
    }

    /// Index used for XP threshold calculations.
    var index: Int {
        switch self {
        case .novice:     return 0
        case .apprentice: return 1
        case .scholar:    return 2
        case .master:     return 3
        case .legendary:  return 4
        }
    }
}
