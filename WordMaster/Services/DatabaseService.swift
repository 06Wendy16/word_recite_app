import Foundation
import SQLite

// MARK: - DatabaseService
class DatabaseService {
    static let shared = DatabaseService()
    
    private var db: Connection?
    
    // 表定义
    private let wordsTable = Table("words")
    private let articlesTable = Table("articles")
    private let reviewRecordsTable = Table("review_records")
    
    // Words 表列
    private let wordId = Expression<String>("id")
    private let wordText = Expression<String>("text")
    private let wordPhonetic = Expression<String?>("phonetic")
    private let wordPartOfSpeech = Expression<String?>("partOfSpeech")
    private let wordDefinition = Expression<String?>("definition")
    private let wordExampleSentence = Expression<String?>("exampleSentence")
    private let wordImageData = Expression<Data?>("imageData")
    private let wordArticleId = Expression<String?>("articleId")
    private let wordCreatedAt = Expression<Double>("created_at")
    private let wordLastReviewedAt = Expression<Double?>("lastReviewedAt")
    private let wordNextReviewDate = Expression<Double?>("nextReviewDate")
    private let wordReviewCount = Expression<Int>("reviewCount")
    private let wordMasteryLevel = Expression<Int>("masteryLevel")
    private let wordIsMastered = Expression<Int>("isMastered")
    
    // Articles 表列
    private let articleId = Expression<String>("id")
    private let articleTitle = Expression<String>("title")
    private let articleImagesPaths = Expression<String>("imagesPaths")
    private let articleWordIds = Expression<String>("wordIds")
    private let articleCreatedAt = Expression<Double>("created_at")
    private let articleProgress = Expression<Double>("progress")
    private let articleIsCompleted = Expression<Int>("isCompleted")
    
    // ReviewRecords 表列
    private let recordId = Expression<String>("id")
    private let recordWordId = Expression<String>("wordId")
    private let recordReviewedAt = Expression<Double>("reviewedAt")
    private let recordResult = Expression<String>("result")
    private let recordResponseTime = Expression<Double>("responseTime")
    
    private init() {}
    
    // MARK: - 数据库初始化
    func initializeDatabase() {
        do {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dbPath = documentDirectory.appendingPathComponent("wordmaster.sqlite3").path
            db = try Connection(dbPath)
            
            // 创建表
            try createTables()
            
            // 导入短文文件夹
            importArticlesFromFolder()
            
        } catch {
            print("数据库初始化失败: \(error)")
        }
    }
    
    private func createTables() throws {
        // Words 表
        try db?.run(wordsTable.create(ifNotExists: true) { t in
            t.column(wordId, primaryKey: true)
            t.column(wordText)
            t.column(wordPhonetic)
            t.column(wordPartOfSpeech)
            t.column(wordDefinition)
            t.column(wordExampleSentence)
            t.column(wordImageData)
            t.column(wordArticleId)
            t.column(wordCreatedAt)
            t.column(wordLastReviewedAt)
            t.column(wordNextReviewDate)
            t.column(wordReviewCount, defaultValue: 0)
            t.column(wordMasteryLevel, defaultValue: 0)
            t.column(wordIsMastered, defaultValue: 0)
        })
        
        // Articles 表
        try db?.run(articlesTable.create(ifNotExists: true) { t in
            t.column(articleId, primaryKey: true)
            t.column(articleTitle)
            t.column(articleImagesPaths)
            t.column(articleWordIds)
            t.column(articleCreatedAt)
            t.column(articleProgress, defaultValue: 0.0)
            t.column(articleIsCompleted, defaultValue: 0)
        })
        
        // ReviewRecords 表
        try db?.run(reviewRecordsTable.create(ifNotExists: true) { t in
            t.column(recordId, primaryKey: true)
            t.column(recordWordId)
            t.column(recordReviewedAt)
            t.column(recordResult)
            t.column(recordResponseTime)
        })
        
        // 创建索引
        try db?.run(wordsTable.createIndex(wordArticleId, ifNotExists: true))
        try db?.run(wordsTable.createIndex(wordNextReviewDate, ifNotExists: true))
        try db?.run(reviewRecordsTable.createIndex(recordWordId, ifNotExists: true))
    }
    
    // MARK: - 从文件夹导入短文
    private func importArticlesFromFolder() {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        // 获取已存在的文章数量
        let existingArticles = getAllArticles()
        if !existingArticles.isEmpty { return }
        
        // 查找短文文件夹
        let parentDirectory = documentsPath.deletingLastPathComponent()
        
        // 尝试从应用支持文件夹导入
        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? documentsPath
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: appSupportDir, includingPropertiesForKeys: nil)
            
            for folder in contents {
                let folderName = folder.lastPathComponent
                if folderName.hasPrefix("短文") {
                    let articleNumber = String(folderName.dropFirst(2))
                    let images = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                        .filter { ["jpg", "jpeg", "png"].contains($0.pathExtension.lowercased()) }
                        .sorted { $0.lastPathComponent < $1.lastPathComponent }
                    
                    let imagePaths = images.map { $0.path }
                    
                    let article = Article(
                        title: "短文\(articleNumber)",
                        imagesPaths: imagePaths
                    )
                    
                    saveArticle(article)
                }
            }
        } catch {
            print("导入短文失败: \(error)")
        }
    }
    
    // MARK: - Words 操作
    func saveWord(_ word: Word) {
        do {
            let insert = wordsTable.insert(or: .replace,
                wordId <- word.id.uuidString,
                wordText <- word.text,
                wordPhonetic <- word.phonetic,
                wordPartOfSpeech <- word.partOfSpeech,
                wordDefinition <- word.definition,
                wordExampleSentence <- word.exampleSentence,
                wordImageData <- word.imageData,
                wordArticleId <- word.articleId,
                wordCreatedAt <- word.createdAt.timeIntervalSince1970,
                wordLastReviewedAt <- word.lastReviewedAt?.timeIntervalSince1970,
                wordNextReviewDate <- word.nextReviewDate?.timeIntervalSince1970,
                wordReviewCount <- word.reviewCount,
                wordMasteryLevel <- word.masteryLevel,
                wordIsMastered <- (word.isMastered ? 1 : 0)
            )
            try db?.run(insert)
        } catch {
            print("保存单词失败: \(error)")
        }
    }
    
    func getAllWords() -> [Word] {
        var words: [Word] = []
        do {
            guard let db = db else { return [] }
            for row in try db.prepare(wordsTable) {
                let dict: [String: Any] = [
                    "id": row[wordId],
                    "text": row[wordText],
                    "phonetic": row[wordPhonetic] as Any,
                    "partOfSpeech": row[wordPartOfSpeech] as Any,
                    "definition": row[wordDefinition] as Any,
                    "exampleSentence": row[wordExampleSentence] as Any,
                    "imageData": row[wordImageData] as Any,
                    "articleId": row[wordArticleId] as Any,
                    "created_at": row[wordCreatedAt],
                    "lastReviewedAt": row[wordLastReviewedAt] as Any,
                    "nextReviewDate": row[wordNextReviewDate] as Any,
                    "reviewCount": row[wordReviewCount],
                    "masteryLevel": row[wordMasteryLevel],
                    "isMastered": row[wordIsMastered]
                ]
                if let word = Word(from: dict) {
                    words.append(word)
                }
            }
        } catch {
            print("获取单词列表失败: \(error)")
        }
        return words
    }
    
    func getWords(forArticle articleIdValue: String) -> [Word] {
        return getAllWords().filter { $0.articleId == articleIdValue }
    }
    
    func getWordsForReview() -> [Word] {
        let now = Date().timeIntervalSince1970
        return getAllWords().filter { word in
            guard let nextReview = word.nextReviewDate else { return true }
            return nextReview.timeIntervalSince1970 <= now
        }
    }
    
    func getWord(by id: UUID) -> Word? {
        return getAllWords().first { $0.id == id }
    }
    
    func deleteWord(_ word: Word) {
        do {
            let wordToDelete = wordsTable.filter(wordId <- word.id.uuidString)
            try db?.run(wordToDelete.delete())
        } catch {
            print("删除单词失败: \(error)")
        }
    }
    
    // MARK: - Articles 操作
    func saveArticle(_ article: Article) {
        do {
            let imagesPathsData = try JSONEncoder().encode(article.imagesPaths)
            let wordIdsData = try JSONEncoder().encode(article.wordIds)
            
            let insert = articlesTable.insert(or: .replace,
                articleId <- article.id.uuidString,
                articleTitle <- article.title,
                articleImagesPaths <- String(data: imagesPathsData, encoding: .utf8) ?? "[]",
                articleWordIds <- String(data: wordIdsData, encoding: .utf8) ?? "[]",
                articleCreatedAt <- article.createdAt.timeIntervalSince1970,
                articleProgress <- article.progress,
                articleIsCompleted <- (article.isCompleted ? 1 : 0)
            )
            try db?.run(insert)
        } catch {
            print("保存短文失败: \(error)")
        }
    }
    
    func getAllArticles() -> [Article] {
        var articles: [Article] = []
        do {
            guard let db = db else { return [] }
            for row in try db.prepare(articlesTable.order(articleCreatedAt)) {
                let dict: [String: Any] = [
                    "id": row[articleId],
                    "title": row[articleTitle],
                    "imagesPaths": row[articleImagesPaths],
                    "wordIds": row[articleWordIds],
                    "created_at": row[articleCreatedAt],
                    "progress": row[articleProgress],
                    "isCompleted": row[articleIsCompleted]
                ]
                if let article = Article(from: dict) {
                    articles.append(article)
                }
            }
        } catch {
            print("获取短文列表失败: \(error)")
        }
        return articles
    }
    
    func getArticle(by id: UUID) -> Article? {
        return getAllArticles().first { $0.id == id }
    }
    
    func updateArticleProgress(_ article: Article, progress: Double) {
        var updatedArticle = article
        updatedArticle.progress = progress
        updatedArticle.isCompleted = progress >= 1.0
        saveArticle(updatedArticle)
    }
    
    // MARK: - 统计
    func getStatistics() -> (totalWords: Int, masteredWords: Int, todayReviewed: Int, streak: Int) {
        let words = getAllWords()
        let totalWords = words.count
        let masteredWords = words.filter { $0.isMastered }.count
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayReviewed = words.filter { word in
            guard let lastReviewed = word.lastReviewedAt else { return false }
            return lastReviewed >= today
        }.count
        
        return (totalWords, masteredWords, todayReviewed, calculateStreak())
    }
    
    private func calculateStreak() -> Int {
        // 简化版：检查过去7天是否有学习记录
        return getAllWords().filter { $0.reviewCount > 0 }.count > 0 ? 1 : 0
    }
}
