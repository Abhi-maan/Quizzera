//
//  TriviaAPIService.swift
//  Quizzera
//
//  Created on 2026-05-03.
//  Networking layer — fetches questions from OpenTDB API.
//

import Foundation

// MARK: - Question Source

/// Tracks whether questions came from the API or local fallback.
enum QuestionSource: String {
    case api     = "Live"
    case offline = "Offline"

    var emoji: String {
        switch self {
        case .api:     return "🌐"
        case .offline: return "📦"
        }
    }

    var label: String {
        "\(emoji) \(rawValue)"
    }
}

// MARK: - OpenTDB Response Models

/// Root response from the Open Trivia Database API.
struct OpenTDBResponse: Codable {
    let responseCode: Int
    let results: [OpenTDBQuestion]

    enum CodingKeys: String, CodingKey {
        case responseCode = "response_code"
        case results
    }
}

/// A single question from the OpenTDB API.
struct OpenTDBQuestion: Codable {
    let category: String
    let type: String
    let difficulty: String
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]

    enum CodingKeys: String, CodingKey {
        case category, type, difficulty, question
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }
}

// MARK: - API Errors

/// Errors that can occur during API question fetching.
enum TriviaAPIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case badResponseCode(Int)
    case decodingError(Error)
    case noResults
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidURL:             return "Invalid API URL"
        case .networkError(let e):    return "Network error: \(e.localizedDescription)"
        case .badResponseCode(let c): return "API returned code \(c)"
        case .decodingError(let e):   return "Decoding error: \(e.localizedDescription)"
        case .noResults:              return "No questions returned"
        case .rateLimited:            return "API rate limited — try again shortly"
        }
    }
}

// MARK: - Trivia API Service

/// Fetches quiz questions from the Open Trivia Database (opentdb.com).
/// Uses async/await with URLSession. Thread-safe via actor isolation.
actor TriviaAPIService {

    /// Shared singleton instance.
    static let shared = TriviaAPIService()

    private init() {}

    // MARK: - Category Mapping

    /// Maps app categories to OpenTDB category IDs.
    private func openTDBCategoryId(for category: Category) -> Int {
        switch category {
        case .generalKnowledge: return 9
        case .technology:       return 18  // Science: Computers
        case .science:          return 17  // Science & Nature
        case .sports:           return 21  // Sports
        }
    }

    /// Maps OpenTDB difficulty strings to app Difficulty enum.
    private func mapDifficulty(_ string: String) -> Difficulty {
        switch string.lowercased() {
        case "easy":   return .easy
        case "medium": return .medium
        case "hard":   return .hard
        default:       return .medium
        }
    }

    // MARK: - Fetch Questions

    /// Fetch questions from OpenTDB for the given category and difficulty.
    /// - Parameters:
    ///   - category: The quiz category to fetch.
    ///   - difficulty: The desired difficulty level.
    ///   - amount: Number of questions to fetch (default 10).
    /// - Returns: An array of `Question` models ready for the quiz.
    /// - Throws: `TriviaAPIError` on failure.
    func fetchQuestions(
        category: Category,
        difficulty: Difficulty,
        amount: Int = 10
    ) async throws -> [Question] {

        let categoryId = openTDBCategoryId(for: category)
        let difficultyStr = difficulty.rawValue.lowercased()

        guard let url = URL(string:
            "https://opentdb.com/api.php?amount=\(amount)&category=\(categoryId)&difficulty=\(difficultyStr)&type=multiple"
        ) else {
            throw TriviaAPIError.invalidURL
        }

        // Configure request with timeout
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw TriviaAPIError.networkError(error)
        }

        // Validate HTTP status
        if let httpResponse = response as? HTTPURLResponse {
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 429 {
                    throw TriviaAPIError.rateLimited
                }
                throw TriviaAPIError.badResponseCode(httpResponse.statusCode)
            }
        }

        // Decode response
        let apiResponse: OpenTDBResponse
        do {
            apiResponse = try JSONDecoder().decode(OpenTDBResponse.self, from: data)
        } catch {
            throw TriviaAPIError.decodingError(error)
        }

        // Check response code (0 = success, 1 = no results, 5 = rate limit)
        switch apiResponse.responseCode {
        case 0:  break // success
        case 5:  throw TriviaAPIError.rateLimited
        default: throw TriviaAPIError.noResults
        }

        guard !apiResponse.results.isEmpty else {
            throw TriviaAPIError.noResults
        }

        // Map to app Question models
        return apiResponse.results.map { apiQ in
            mapToQuestion(apiQ, category: category)
        }
    }

    // MARK: - Mapping

    /// Convert an OpenTDB question to an app Question model.
    private func mapToQuestion(_ apiQ: OpenTDBQuestion, category: Category) -> Question {
        // Decode HTML entities in all text fields
        let questionText = apiQ.question.decodingHTMLEntities()
        let correct = apiQ.correctAnswer.decodingHTMLEntities()
        let incorrects = apiQ.incorrectAnswers.map { $0.decodingHTMLEntities() }

        // Build options array with correct answer inserted at random position
        var options = incorrects
        let correctIndex = Int.random(in: 0...options.count)
        options.insert(correct, at: correctIndex)

        return Question(
            text: questionText,
            options: options,
            correctIndex: correctIndex,
            category: category,
            difficulty: mapDifficulty(apiQ.difficulty)
        )
    }
}

// MARK: - HTML Entity Decoding

extension String {
    /// Decodes common HTML entities found in OpenTDB responses.
    func decodingHTMLEntities() -> String {
        var result = self

        // Common HTML entities
        let entities: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#039;", "'"),
            ("&apos;", "'"),
            ("&laquo;", "«"),
            ("&raquo;", "»"),
            ("&ldquo;", "\u{201C}"),
            ("&rdquo;", "\u{201D}"),
            ("&lsquo;", "\u{2018}"),
            ("&rsquo;", "\u{2019}"),
            ("&ndash;", "\u{2013}"),
            ("&mdash;", "\u{2014}"),
            ("&hellip;", "…"),
            ("&eacute;", "é"),
            ("&Eacute;", "É"),
            ("&uuml;", "ü"),
            ("&ouml;", "ö"),
            ("&auml;", "ä"),
            ("&ntilde;", "ñ"),
            ("&shy;", ""),
        ]

        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Handle numeric entities like &#123; and &#x1A;
        // Decimal: &#NNN;
        while let range = result.range(of: "&#\\d+;", options: .regularExpression) {
            let entityStr = String(result[range])
            let numberStr = entityStr.dropFirst(2).dropLast(1)
            if let codePoint = UInt32(numberStr),
               let scalar = Unicode.Scalar(codePoint) {
                result.replaceSubrange(range, with: String(Character(scalar)))
            } else {
                break
            }
        }

        // Hex: &#xHHH;
        while let range = result.range(of: "&#x[0-9a-fA-F]+;", options: .regularExpression) {
            let entityStr = String(result[range])
            let hexStr = entityStr.dropFirst(3).dropLast(1)
            if let codePoint = UInt32(hexStr, radix: 16),
               let scalar = Unicode.Scalar(codePoint) {
                result.replaceSubrange(range, with: String(Character(scalar)))
            } else {
                break
            }
        }

        return result
    }
}
