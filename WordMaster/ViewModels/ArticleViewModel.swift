import Foundation
import Combine

// MARK: - ArticleViewModel
class ArticleViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var selectedArticle: Article?
    @Published var selectedArticleWords: [Word] = []
    @Published var filterOption: FilterOption = .all
    @Published var isLoading: Bool = false
    
    enum FilterOption: String, CaseIterable {
        case all = "全部"
        case notStarted = "未开始"
        case inProgress = "学习中"
        case completed = "已完成"
    }
    
    init() {
        loadArticles()
    }
    
    func loadArticles() {
        isLoading = true
        articles = DatabaseService.shared.getAllArticles()
        updateArticleProgress()
        isLoading = false
    }
    
    func updateArticleProgress() {
        for article in articles {
            let words = DatabaseService.shared.getWords(forArticle: article.id.uuidString)
            if !words.isEmpty {
                let masteredCount = words.filter { $0.isMastered }.count
                let progress = Double(masteredCount) / Double(words.count)
                DatabaseService.shared.updateArticleProgress(article, progress: progress)
            }
        }
        // 重新加载以更新UI
        articles = DatabaseService.shared.getAllArticles()
    }
    
    func selectArticle(_ article: Article) {
        selectedArticle = article
        selectedArticleWords = DatabaseService.shared.getWords(forArticle: article.id.uuidString)
    }
    
    var filteredArticles: [Article] {
        switch filterOption {
        case .all:
            return articles
        case .notStarted:
            return articles.filter { $0.progress == 0 }
        case .inProgress:
            return articles.filter { $0.progress > 0 && $0.progress < 1 }
        case .completed:
            return articles.filter { $0.isCompleted }
        }
    }
    
    func getArticleWordCount(_ article: Article) -> Int {
        return DatabaseService.shared.getWords(forArticle: article.id.uuidString).count
    }
}
