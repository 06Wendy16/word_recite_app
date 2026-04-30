import Foundation
import UIKit
import Combine

// MARK: - AddWordViewModel
class AddWordViewModel: ObservableObject {
    @Published var selectedImages: [UIImage] = []
    @Published var recognizedWords: [String] = []
    @Published var wordDetails: [WordDetail] = []
    @Published var isProcessing: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccessMessage: Bool = false
    
    struct WordDetail: Identifiable {
        let id = UUID()
        var text: String
        var definition: String = ""
        var phonetic: String = ""
        var isSelected: Bool = true
    }
    
    // MARK: - 添加图片
    func addImage(_ image: UIImage) {
        selectedImages.append(image)
        processImages()
    }
    
    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
        if selectedImages.isEmpty {
            recognizedWords = []
            wordDetails = []
        } else {
            processImages()
        }
    }
    
    func clearAll() {
        selectedImages = []
        recognizedWords = []
        wordDetails = []
        errorMessage = nil
    }
    
    // MARK: - 处理图片识别
    private func processImages() {
        guard !selectedImages.isEmpty else { return }
        
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                let words = try await OCRService.shared.extractWordsFromMultipleImages(selectedImages)
                await MainActor.run {
                    self.recognizedWords = words
                    self.wordDetails = words.map { WordDetail(text: $0) }
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "图片识别失败，请重试"
                    self.isProcessing = false
                }
            }
        }
    }
    
    // MARK: - 更新单词详情
    func updateWordDetail(at index: Int, definition: String) {
        guard index < wordDetails.count else { return }
        wordDetails[index].definition = definition
    }
    
    func toggleWordSelection(at index: Int) {
        guard index < wordDetails.count else { return }
        wordDetails[index].isSelected.toggle()
    }
    
    // MARK: - 保存单词
    func saveSelectedWords() {
        let selectedWords = wordDetails.filter { $0.isSelected }
        
        guard !selectedWords.isEmpty else {
            errorMessage = "请至少选择一个单词"
            return
        }
        
        isLoading = true
        
        for wordDetail in selectedWords {
            let word = Word(
                text: wordDetail.text,
                definition: wordDetail.definition.isEmpty ? nil : wordDetail.definition,
                phonetic: wordDetail.phonetic.isEmpty ? nil : wordDetail.phonetic
            )
            DatabaseService.shared.saveWord(word)
        }
        
        isLoading = false
        showSuccessMessage = true
        
        // 清空状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showSuccessMessage = false
            self.clearAll()
        }
    }
    
    // MARK: - 手动添加单词
    func addManualWord(text: String, definition: String) {
        let word = Word(
            text: text,
            definition: definition.isEmpty ? nil : definition
        )
        DatabaseService.shared.saveWord(word)
        showSuccessMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showSuccessMessage = false
        }
    }
}
