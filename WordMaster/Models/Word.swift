import Foundation

// MARK: - Word 模型
struct Word: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var phonetic: String?
    var partOfSpeech: String?
    var definition: String?
    var exampleSentence: String?
    var imageData: Data?
    var articleId: String?
    var createdAt: Date
    var lastReviewedAt: Date?
    var nextReviewDate: Date?
    var reviewCount: Int
    var masteryLevel: Int
    var isMastered: Bool
    
    init(
        id: UUID = UUID(),
        text: String,
        phonetic: String? = nil,
        partOfSpeech: String? = nil,
        definition: String? = nil,
        exampleSentence: String? = nil,
        imageData: Data? = nil,
        articleId: String? = nil,
        createdAt: Date = Date(),
        lastReviewedAt: Date? = nil,
        nextReviewDate: Date? = nil,
        reviewCount: Int = 0,
        masteryLevel: Int = 0,
        isMastered: Bool = false
    ) {
        self.id = id
        self.text = text
        self.phonetic = phonetic
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.exampleSentence = exampleSentence
        self.imageData = imageData
        self.articleId = articleId
        self.createdAt = createdAt
        self.lastReviewedAt = lastReviewedAt
        self.nextReviewDate = nextReviewDate
        self.reviewCount = reviewCount
        self.masteryLevel = masteryLevel
        self.isMastered = isMastered
    }
    
    // 从数据库行创建
    init?(from row: [String: Any]) {
        guard let idString = row["id"] as? String,
              let id = UUID(uuidString: idString),
              let text = row["text"] as? String,
              let createdAtTimestamp = row["created_at"] as? Double else {
            return nil
        }
        
        self.id = id
        self.text = text
        self.phonetic = row["phonetic"] as? String
        self.partOfSpeech = row["partOfSpeech"] as? String
        self.definition = row["definition"] as? String
        self.exampleSentence = row["exampleSentence"] as? String
        self.imageData = row["imageData"] as? Data
        self.articleId = row["articleId"] as? String
        self.createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
        
        if let lastReviewed = row["lastReviewedAt"] as? Double {
            self.lastReviewedAt = Date(timeIntervalSince1970: lastReviewed)
        } else {
            self.lastReviewedAt = nil
        }
        
        if let nextReview = row["nextReviewDate"] as? Double {
            self.nextReviewDate = Date(timeIntervalSince1970: nextReview)
        } else {
            self.nextReviewDate = nil
        }
        
        self.reviewCount = (row["reviewCount"] as? Int) ?? 0
        self.masteryLevel = (row["masteryLevel"] as? Int) ?? 0
        self.isMastered = (row["isMastered"] as? Int) ?? 0 == 1
    }
}

// MARK: - ReviewResult 枚举
enum ReviewResult: String, Codable {
    case remember = "remember"
    case forgot = "forgot"
}

// MARK: - ReviewRecord 模型
struct ReviewRecord: Identifiable, Codable {
    let id: UUID
    let wordId: UUID
    let reviewedAt: Date
    let result: ReviewResult
    let responseTime: TimeInterval
    
    init(
        id: UUID = UUID(),
        wordId: UUID,
        reviewedAt: Date = Date(),
        result: ReviewResult,
        responseTime: TimeInterval = 0
    ) {
        self.id = id
        self.wordId = wordId
        self.reviewedAt = reviewedAt
        self.result = result
        self.responseTime = responseTime
    }
}
