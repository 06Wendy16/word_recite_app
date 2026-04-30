import Foundation
import UIKit

// MARK: - Article 模型
struct Article: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var imagesPaths: [String]
    var wordIds: [UUID]
    var createdAt: Date
    var progress: Double
    var isCompleted: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        imagesPaths: [String] = [],
        wordIds: [UUID] = [],
        createdAt: Date = Date(),
        progress: Double = 0.0,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.imagesPaths = imagesPaths
        self.wordIds = wordIds
        self.createdAt = createdAt
        self.progress = progress
        self.isCompleted = isCompleted
    }
    
    // 从数据库行创建
    init?(from row: [String: Any]) {
        guard let idString = row["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = row["title"] as? String,
              let createdAtTimestamp = row["created_at"] as? Double else {
            return nil
        }
        
        self.id = id
        self.title = title
        
        if let imagesPathsString = row["imagesPaths"] as? String {
            self.imagesPaths = (try? JSONDecoder().decode([String].self, from: Data(imagesPathsString.utf8))) ?? []
        } else {
            self.imagesPaths = []
        }
        
        if let wordIdsString = row["wordIds"] as? String {
            self.wordIds = (try? JSONDecoder().decode([UUID].self, from: Data(wordIdsString.utf8))) ?? []
        } else {
            self.wordIds = []
        }
        
        self.createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
        self.progress = (row["progress"] as? Double) ?? 0.0
        self.isCompleted = (row["isCompleted"] as? Int) ?? 0 == 1
    }
}

// MARK: - ArticleImage 模型
struct ArticleImage: Identifiable {
    let id: UUID
    let articleId: UUID
    let imagePath: String
    let order: Int
    
    init(
        id: UUID = UUID(),
        articleId: UUID,
        imagePath: String,
        order: Int
    ) {
        self.id = id
        self.articleId = articleId
        self.imagePath = imagePath
        self.order = order
    }
}
