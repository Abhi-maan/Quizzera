//
//  QuizData.swift
//  Quizzera
//
//  Created on 2026-04-27.
//  40 questions — 10 per category, mixed difficulties.
//

import Foundation

/// Central question bank for all quiz categories.
struct QuizData {

    /// Returns 10 shuffled questions for the given category.
    static func questions(for category: Category) -> [Question] {
        let pool: [Question]
        switch category {
        case .generalKnowledge: pool = generalKnowledgeQuestions
        case .technology:       pool = technologyQuestions
        case .science:          pool = scienceQuestions
        case .sports:           pool = sportsQuestions
        }
        return Array(pool.shuffled().prefix(10))
    }

    // MARK: - General Knowledge (10)

    static let generalKnowledgeQuestions: [Question] = [
        Question(
            text: "What is the capital of Australia?",
            options: ["Sydney", "Melbourne", "Canberra", "Perth"],
            correctIndex: 2,
            category: .generalKnowledge,
            difficulty: .easy
        ),
        Question(
            text: "Which planet is known as the Red Planet?",
            options: ["Venus", "Mars", "Jupiter", "Saturn"],
            correctIndex: 1,
            category: .generalKnowledge,
            difficulty: .easy
        ),
        Question(
            text: "How many continents are there on Earth?",
            options: ["5", "6", "7", "8"],
            correctIndex: 2,
            category: .generalKnowledge,
            difficulty: .easy
        ),
        Question(
            text: "Who painted the Mona Lisa?",
            options: ["Michelangelo", "Raphael", "Leonardo da Vinci", "Donatello"],
            correctIndex: 2,
            category: .generalKnowledge,
            difficulty: .easy
        ),
        Question(
            text: "What is the largest ocean on Earth?",
            options: ["Atlantic", "Indian", "Arctic", "Pacific"],
            correctIndex: 3,
            category: .generalKnowledge,
            difficulty: .medium
        ),
        Question(
            text: "In which year did World War II end?",
            options: ["1943", "1944", "1945", "1946"],
            correctIndex: 2,
            category: .generalKnowledge,
            difficulty: .medium
        ),
        Question(
            text: "What is the chemical symbol for gold?",
            options: ["Go", "Gd", "Au", "Ag"],
            correctIndex: 2,
            category: .generalKnowledge,
            difficulty: .medium
        ),
        Question(
            text: "Which country has the most natural lakes?",
            options: ["USA", "Brazil", "Canada", "Russia"],
            correctIndex: 2,
            category: .generalKnowledge,
            difficulty: .hard
        ),
        Question(
            text: "What is the smallest country in the world by area?",
            options: ["Monaco", "Nauru", "Vatican City", "San Marino"],
            correctIndex: 2,
            category: .generalKnowledge,
            difficulty: .hard
        ),
        Question(
            text: "Which language has the most native speakers worldwide?",
            options: ["English", "Spanish", "Hindi", "Mandarin Chinese"],
            correctIndex: 3,
            category: .generalKnowledge,
            difficulty: .hard
        )
    ]

    // MARK: - Technology (10)

    static let technologyQuestions: [Question] = [
        Question(
            text: "What does HTML stand for?",
            options: ["Hyper Text Markup Language", "High Tech Modern Language", "Hyper Transfer Markup Language", "Home Tool Markup Language"],
            correctIndex: 0,
            category: .technology,
            difficulty: .easy
        ),
        Question(
            text: "Who co-founded Apple Inc. alongside Steve Jobs?",
            options: ["Bill Gates", "Steve Wozniak", "Tim Cook", "Larry Page"],
            correctIndex: 1,
            category: .technology,
            difficulty: .easy
        ),
        Question(
            text: "What does CPU stand for?",
            options: ["Central Process Unit", "Central Processing Unit", "Computer Personal Unit", "Central Processor Utility"],
            correctIndex: 1,
            category: .technology,
            difficulty: .easy
        ),
        Question(
            text: "Which programming language is known as the 'language of the web'?",
            options: ["Python", "Java", "JavaScript", "C++"],
            correctIndex: 2,
            category: .technology,
            difficulty: .easy
        ),
        Question(
            text: "What year was the first iPhone released?",
            options: ["2005", "2006", "2007", "2008"],
            correctIndex: 2,
            category: .technology,
            difficulty: .medium
        ),
        Question(
            text: "What does API stand for?",
            options: ["Application Programming Interface", "Applied Program Integration", "Automated Process Interaction", "Application Process Interface"],
            correctIndex: 0,
            category: .technology,
            difficulty: .medium
        ),
        Question(
            text: "Which company developed the Android operating system?",
            options: ["Apple", "Microsoft", "Google", "Samsung"],
            correctIndex: 2,
            category: .technology,
            difficulty: .medium
        ),
        Question(
            text: "What does GPU stand for?",
            options: ["General Processing Unit", "Graphics Processing Unit", "Graphical Performance Utility", "Global Processing Unit"],
            correctIndex: 1,
            category: .technology,
            difficulty: .medium
        ),
        Question(
            text: "In which year was the World Wide Web invented by Tim Berners-Lee?",
            options: ["1985", "1989", "1991", "1993"],
            correctIndex: 1,
            category: .technology,
            difficulty: .hard
        ),
        Question(
            text: "What is the time complexity of binary search?",
            options: ["O(n)", "O(n²)", "O(log n)", "O(1)"],
            correctIndex: 2,
            category: .technology,
            difficulty: .hard
        )
    ]

    // MARK: - Science (10)

    static let scienceQuestions: [Question] = [
        Question(
            text: "What is the chemical formula for water?",
            options: ["CO2", "H2O", "NaCl", "O2"],
            correctIndex: 1,
            category: .science,
            difficulty: .easy
        ),
        Question(
            text: "What gas do plants absorb from the atmosphere?",
            options: ["Oxygen", "Nitrogen", "Carbon Dioxide", "Hydrogen"],
            correctIndex: 2,
            category: .science,
            difficulty: .easy
        ),
        Question(
            text: "How many bones are in the adult human body?",
            options: ["186", "196", "206", "216"],
            correctIndex: 2,
            category: .science,
            difficulty: .easy
        ),
        Question(
            text: "What is the speed of light approximately?",
            options: ["300,000 km/s", "150,000 km/s", "500,000 km/s", "1,000,000 km/s"],
            correctIndex: 0,
            category: .science,
            difficulty: .medium
        ),
        Question(
            text: "What is the powerhouse of the cell?",
            options: ["Nucleus", "Ribosome", "Mitochondria", "Golgi Apparatus"],
            correctIndex: 2,
            category: .science,
            difficulty: .easy
        ),
        Question(
            text: "Which element has the atomic number 1?",
            options: ["Helium", "Hydrogen", "Lithium", "Carbon"],
            correctIndex: 1,
            category: .science,
            difficulty: .medium
        ),
        Question(
            text: "What planet has the most moons in our solar system?",
            options: ["Jupiter", "Saturn", "Uranus", "Neptune"],
            correctIndex: 1,
            category: .science,
            difficulty: .medium
        ),
        Question(
            text: "What is the hardest natural substance on Earth?",
            options: ["Gold", "Iron", "Diamond", "Platinum"],
            correctIndex: 2,
            category: .science,
            difficulty: .medium
        ),
        Question(
            text: "What is the half-life of Carbon-14 approximately?",
            options: ["2,730 years", "5,730 years", "8,730 years", "11,730 years"],
            correctIndex: 1,
            category: .science,
            difficulty: .hard
        ),
        Question(
            text: "What particle is exchanged between quarks to mediate the strong force?",
            options: ["Photon", "W Boson", "Gluon", "Graviton"],
            correctIndex: 2,
            category: .science,
            difficulty: .hard
        )
    ]

    // MARK: - Sports (10)

    static let sportsQuestions: [Question] = [
        Question(
            text: "How many players are on a standard soccer team on the field?",
            options: ["9", "10", "11", "12"],
            correctIndex: 2,
            category: .sports,
            difficulty: .easy
        ),
        Question(
            text: "In which sport is the term 'love' used to mean zero?",
            options: ["Badminton", "Tennis", "Cricket", "Golf"],
            correctIndex: 1,
            category: .sports,
            difficulty: .easy
        ),
        Question(
            text: "How many rings are on the Olympic flag?",
            options: ["4", "5", "6", "7"],
            correctIndex: 1,
            category: .sports,
            difficulty: .easy
        ),
        Question(
            text: "Which country won the FIFA World Cup in 2022?",
            options: ["France", "Brazil", "Argentina", "Germany"],
            correctIndex: 2,
            category: .sports,
            difficulty: .easy
        ),
        Question(
            text: "What is the maximum score in a single frame of bowling?",
            options: ["10", "20", "30", "50"],
            correctIndex: 2,
            category: .sports,
            difficulty: .medium
        ),
        Question(
            text: "In basketball, how many points is a shot from beyond the arc worth?",
            options: ["1", "2", "3", "4"],
            correctIndex: 2,
            category: .sports,
            difficulty: .medium
        ),
        Question(
            text: "Which Grand Slam tennis tournament is played on clay?",
            options: ["Wimbledon", "US Open", "Australian Open", "French Open"],
            correctIndex: 3,
            category: .sports,
            difficulty: .medium
        ),
        Question(
            text: "Who holds the record for most goals in FIFA World Cup history?",
            options: ["Pelé", "Ronaldo", "Miroslav Klose", "Lionel Messi"],
            correctIndex: 2,
            category: .sports,
            difficulty: .hard
        ),
        Question(
            text: "What is the length of a marathon in miles?",
            options: ["24.2", "25.2", "26.2", "27.2"],
            correctIndex: 2,
            category: .sports,
            difficulty: .medium
        ),
        Question(
            text: "Which country has won the most Cricket World Cup titles?",
            options: ["India", "West Indies", "England", "Australia"],
            correctIndex: 3,
            category: .sports,
            difficulty: .hard
        )
    ]
}
