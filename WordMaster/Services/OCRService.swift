import Foundation
import Vision
import UIKit

// MARK: - OCRService
class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    // MARK: - 识别图片中的文字
    func recognizeText(from image: UIImage, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRError.invalidImage))
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.success([]))
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            completion(.success(recognizedStrings))
        }
        
        // 配置请求
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - 识别并提取英文单词
    func extractEnglishWords(from image: UIImage, completion: @escaping (Result<[String], Error>) -> Void) {
        recognizeText(from: image) { result in
            switch result {
            case .success(let textLines):
                // 从识别的文本中提取英文单词
                var allWords: [String] = []
                
                for line in textLines {
                    let words = line.extractEnglishWords()
                    allWords.append(contentsOf: words)
                }
                
                // 去重
                let uniqueWords = Array(Set(allWords))
                completion(.success(uniqueWords.sorted()))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - 异步版本
    func extractEnglishWords(from image: UIImage) async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            extractEnglishWords(from: image) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - 批量处理多张图片
    func extractWordsFromMultipleImages(_ images: [UIImage], completion: @escaping (Result<[String], Error>) -> Void) {
        let group = DispatchGroup()
        var allWords: [String] = []
        var lastError: Error?
        
        for image in images {
            group.enter()
            extractEnglishWords(from: image) { result in
                switch result {
                case .success(let words):
                    allWords.append(contentsOf: words)
                case .failure(let error):
                    lastError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if let error = lastError, allWords.isEmpty {
                completion(.failure(error))
            } else {
                let uniqueWords = Array(Set(allWords))
                completion(.success(uniqueWords.sorted()))
            }
        }
    }
}

// MARK: - OCR 错误类型
enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无法处理图片"
        case .recognitionFailed:
            return "文字识别失败"
        }
    }
}
