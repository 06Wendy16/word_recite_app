import Foundation
import SwiftUI

// MARK: - Date 扩展
extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    var isPast: Bool {
        self < Date()
    }
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    func timeAgo() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)天前"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)分钟前"
        } else {
            return "刚刚"
        }
    }
    
    func daysUntil() -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: self)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }
}

// MARK: - String 扩展
extension String {
    var isEnglishWord: Bool {
        // 检查是否包含英文字母
        let hasLetters = self.rangeOfCharacter(from: .letters) != nil
        // 检查是否主要是字母（允许少量标点）
        let letterCount = self.filter { $0.isLetter }.count
        let totalCount = self.filter { $0.isLetter || $0 == "'" || $0 == "-" }.count
        let ratio = totalCount > 0 ? Double(letterCount) / Double(totalCount) : 0
        
        return hasLetters && ratio > 0.7 && self.count >= 2 && self.count <= 30
    }
    
    func extractEnglishWords() -> [String] {
        // 使用正则表达式提取英文单词
        let pattern = "[a-zA-Z]+(?:'[a-zA-Z]+)?"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let range = NSRange(self.startIndex..., in: self)
        let matches = regex.matches(in: self, options: [], range: range)
        
        return matches.compactMap { match in
            guard let range = Range(match.range, in: self) else { return nil }
            let word = String(self[range]).lowercased()
            return word.isEnglishWord ? word : nil
        }.removingDuplicates()
    }
}

// MARK: - Array 扩展
extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - View 扩展
extension View {
    func cardStyle() -> some View {
        self
            .background(AppColors.cardBackground)
            .cornerRadius(AppLayout.largeCornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(AppFonts.body.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.primary)
            .cornerRadius(AppLayout.mediumCornerRadius)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(AppFonts.body.bold())
            .foregroundColor(AppColors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.primary.opacity(0.1))
            .cornerRadius(AppLayout.mediumCornerRadius)
    }
}

// MARK: - UIImage 扩展
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func compressed(quality: CGFloat = 0.7) -> Data? {
        self.jpegData(compressionQuality: quality)
    }
}
