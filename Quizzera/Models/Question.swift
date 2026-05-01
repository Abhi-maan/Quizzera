//
//  Question.swift
//  Quizzera
//
//  Created on 2026-04-27.
//

import Foundation

/// Represents a single quiz question with multiple choice answers.
struct Question: Identifiable, Codable {
    let id: UUID
    let text: String
    let options: [String]
    let correctIndex: Int
    let category: Category
    let difficulty: Difficulty

    init(
        id: UUID = UUID(),
        text: String,
        options: [String],
        correctIndex: Int,
        category: Category,
        difficulty: Difficulty
    ) {
        self.id = id
        self.text = text
        self.options = options
        self.correctIndex = correctIndex
        self.category = category
        self.difficulty = difficulty
    }

    /// Returns the correct answer string.
    var correctAnswer: String {
        options[correctIndex]
    }
}

/// Quiz category types available in the app.
enum Category: String, Codable, CaseIterable, Identifiable {
    case generalKnowledge = "General Knowledge"
    case technology = "Technology"
    case science = "Science"
    case sports = "Sports"

    var id: String { rawValue }

    /// SF Symbol icon name for each category.
    var iconName: String {
        switch self {
        case .generalKnowledge: return "brain.head.profile"
        case .technology:       return "desktopcomputer"
        case .science:          return "atom"
        case .sports:           return "sportscourt"
        }
    }

    /// Short display label.
    var label: String { rawValue }

    /// Color accent per category for visual distinction.
    var accentHue: Double {
        switch self {
        case .generalKnowledge: return 0.75  // purple
        case .technology:       return 0.55  // cyan
        case .science:          return 0.30  // green
        case .sports:           return 0.08  // orange
        }
    }
}

/// Question difficulty levels.
enum Difficulty: String, Codable, CaseIterable {
    case easy   = "Easy"
    case medium = "Medium"
    case hard   = "Hard"

    /// Point multiplier based on difficulty.
    var multiplier: Double {
        switch self {
        case .easy:   return 1.0
        case .medium: return 1.5
        case .hard:   return 2.0
        }
    }

    /// SF Symbol for difficulty indicator.
    var iconName: String {
        switch self {
        case .easy:   return "star"
        case .medium: return "star.leadinghalf.filled"
        case .hard:   return "star.fill"
        }
    }
}
