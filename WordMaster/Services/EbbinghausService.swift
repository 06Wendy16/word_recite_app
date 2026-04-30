import Foundation

// MARK: - EbbinghausService
class EbbinghausService {
    static let shared = EbbinghausService()
    
    private init() {}
    
    // MARK: - 计算下次复习时间
    /// 根据艾宾浩斯遗忘曲线计算下次复习时间
    /// - Parameters:
    ///   - word: 单词
    ///   - remembered: 是否记住
    /// - Returns: 下次复习日期
    func calculateNextReviewDate(for word: Word, remembered: Bool) -> Date {
        let newMasteryLevel: Int
        let interval: TimeInterval
        
        if remembered {
            // 答对了，增加记忆等级
            newMasteryLevel = min(word.masteryLevel + 1, EbbinghausConstants.reviewIntervals.count - 1)
            interval = EbbinghausConstants.reviewIntervals[newMasteryLevel]
        } else {
            // 答错了，重置记忆等级
            newMasteryLevel = 1
            interval = EbbinghausConstants.reviewIntervals[0] // 20分钟后再次复习
        }
        
        return Date().addingTimeInterval(interval)
    }
    
    // MARK: - 获取复习间隔描述
    func getIntervalDescription(for masteryLevel: Int) -> String {
        let intervals = [
            "20分钟",
            "1小时",
            "1天",
            "3天",
            "7天",
            "14天",
            "30天"
        ]
        let index = min(masteryLevel, intervals.count - 1)
        return intervals[index]
    }
    
    // MARK: - 获取复习进度描述
    func getProgressDescription(for word: Word) -> String {
        if word.reviewCount == 0 {
            return "新单词"
        } else if word.isMastered {
            return "已掌握"
        } else {
            return "复习中 (\(word.masteryLevel)/\(EbbinghausConstants.reviewIntervals.count))"
        }
    }
    
    // MARK: - 获取需要复习的单词
    func getWordsForReview() -> [Word] {
        let words = DatabaseService.shared.getAllWords()
        let now = Date()
        
        return words.filter { word in
            // 新单词需要学习
            if word.reviewCount == 0 { return true }
            
            // 有预设复习时间且已到期
            if let nextReview = word.nextReviewDate {
                return nextReview <= now
            }
            
            return false
        }
    }
    
    // MARK: - 获取今日复习统计
    func getTodayReviewStats() -> (due: Int, new: Int, total: Int) {
        let words = DatabaseService.shared.getAllWords()
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let dueCount = words.filter { word in
            if word.reviewCount == 0 { return false }
            guard let nextReview = word.nextReviewDate else { return false }
            return nextReview <= now
        }.count
        
        let newCount = words.filter { $0.reviewCount == 0 }.count
        
        return (dueCount, newCount, dueCount + min(newCount, 10))
    }
    
    // MARK: - 更新单词复习状态
    func recordReview(for word: Word, remembered: Bool) {
        var updatedWord = word
        updatedWord.reviewCount += 1
        updatedWord.lastReviewedAt = Date()
        updatedWord.nextReviewDate = calculateNextReviewDate(for: word, remembered: remembered)
        
        if remembered {
            updatedWord.masteryLevel = min(word.masteryLevel + 1, EbbinghausConstants.reviewIntervals.count - 1)
        } else {
            updatedWord.masteryLevel = 1
        }
        
        // 当记忆等级达到最高时，标记为已掌握
        updatedWord.isMastered = updatedWord.masteryLevel >= EbbinghausConstants.reviewIntervals.count - 1
        
        DatabaseService.shared.saveWord(updatedWord)
        
        // 记录复习历史
        let record = ReviewRecord(
            wordId: word.id,
            result: remembered ? .remember : .forgot
        )
        // 可以在这里保存复习记录到数据库
    }
    
    // MARK: - 预估完全掌握需要的时间
    func estimateTimeToMastery(word: Word) -> String {
        let remainingLevels = EbbinghausConstants.reviewIntervals.count - 1 - word.masteryLevel
        var totalDays = 0.0
        
        for i in 0..<remainingLevels {
            let level = word.masteryLevel + i
            let interval = EbbinghausConstants.reviewIntervals[min(level, EbbinghausConstants.reviewIntervals.count - 1)]
            totalDays += interval / (24 * 60 * 60)
        }
        
        if totalDays < 1 {
            return "不到1天"
        } else if totalDays < 30 {
            return String(format: "约%.0f天", totalDays)
        } else {
            let months = totalDays / 30
            return String(format: "约%.1f个月", months)
        }
    }
}
