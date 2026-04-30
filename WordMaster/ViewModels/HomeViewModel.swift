import Foundation
import Combine

// MARK: - HomeViewModel
class HomeViewModel: ObservableObject {
    @Published var todayReviewWords: [Word] = []
    @Published var todayNewWords: [Word] = []
    @Published var recentArticles: [Article] = []
    @Published var statistics: (total: Int, mastered: Int, todayReviewed: Int, streak: Int) = (0, 0, 0, 0)
    @Published var isLoading: Bool = false
    
    init() {
        loadData()
    }
    
    func loadData() {
        isLoading = true
        
        // 获取今日复习单词
        todayReviewWords = EbbinghausService.shared.getWordsForReview().filter { $0.reviewCount > 0 }
        
        // 获取今日新单词（限制数量）
        let allWords = DatabaseService.shared.getAllWords()
        todayNewWords = allWords.filter { $0.reviewCount == 0 }.prefix(10).map { $0 }
        
        // 获取最近短文
        recentArticles = Array(DatabaseService.shared.getAllArticles().prefix(3))
        
        // 获取统计数据
        statistics = DatabaseService.shared.getStatistics()
        
        isLoading = false
    }
    
    var totalTodayTasks: Int {
        return todayReviewWords.count + min(todayNewWords.count, 10)
    }
    
    var reviewProgress: Double {
        guard statistics.totalWords > 0 else { return 0 }
        return Double(statistics.mastered) / Double(statistics.totalWords)
    }
}
