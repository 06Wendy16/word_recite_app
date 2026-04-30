import Foundation
import Combine

// MARK: - LearningViewModel
class LearningViewModel: ObservableObject {
    @Published var words: [Word] = []
    @Published var currentIndex: Int = 0
    @Published var isShowingAnswer: Bool = false
    @Published var isCompleted: Bool = false
    @Published var correctCount: Int = 0
    @Published var incorrectCount: Int = 0
    
    private var startTime: Date = Date()
    
    var currentWord: Word? {
        guard currentIndex < words.count else { return nil }
        return words[currentIndex]
    }
    
    var progress: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentIndex) / Double(words.count)
    }
    
    var remainingCount: Int {
        return max(0, words.count - currentIndex)
    }
    
    // MARK: - 学习模式
    func startLearning(words: [Word]) {
        self.words = words.shuffled()
        self.currentIndex = 0
        self.isShowingAnswer = false
        self.isCompleted = false
        self.correctCount = 0
        self.incorrectCount = 0
        self.startTime = Date()
    }
    
    func toggleAnswer() {
        isShowingAnswer.toggle()
    }
    
    func markAsRemembered() {
        guard let word = currentWord else { return }
        EbbinghausService.shared.recordReview(for: word, remembered: true)
        correctCount += 1
        moveToNext()
    }
    
    func markAsForgot() {
        guard let word = currentWord else { return }
        EbbinghausService.shared.recordReview(for: word, remembered: false)
        incorrectCount += 1
        moveToNext()
    }
    
    private func moveToNext() {
        if currentIndex < words.count - 1 {
            currentIndex += 1
            isShowingAnswer = false
        } else {
            isCompleted = true
        }
    }
    
    // MARK: - 复习模式
    func startReview() {
        let reviewWords = EbbinghausService.shared.getWordsForReview()
        startLearning(words: reviewWords)
    }
    
    // MARK: - 统计
    func getSessionStats() -> (duration: TimeInterval, correct: Int, incorrect: Int) {
        let duration = Date().timeIntervalSince(startTime)
        return (duration, correctCount, incorrectCount)
    }
}
