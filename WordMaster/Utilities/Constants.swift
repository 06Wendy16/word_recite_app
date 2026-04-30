import SwiftUI

// MARK: - 颜色常量
struct AppColors {
    static let primary = Color(hex: "4A90E2")
    static let secondary = Color(hex: "50C878")
    static let accent = Color(hex: "FF6B6B")
    static let background = Color(hex: "F8F9FA")
    static let cardBackground = Color.white
    static let textPrimary = Color(hex: "2C3E50")
    static let textSecondary = Color(hex: "7F8C8D")
    static let warning = Color(hex: "F39C12")
    
    // 渐变色
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "4A90E2"), Color(hex: "7B68EE")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let successGradient = LinearGradient(
        colors: [Color(hex: "50C878"), Color(hex: "2ECC71")],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - 布局常量
struct AppLayout {
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 12
    static let cardSpacing: CGFloat = 12
    static let componentPadding: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    
    // 圆角
    static let largeCornerRadius: CGFloat = 16
    static let mediumCornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    
    // 卡片高度
    static let articleCardHeight: CGFloat = 120
    static let wordCardMinHeight: CGFloat = 200
}

// MARK: - 字体常量
struct AppFonts {
    static let largeTitle = Font.system(size: 28, weight: .bold)
    static let title = Font.system(size: 22, weight: .bold)
    static let subtitle = Font.system(size: 18, weight: .semibold)
    static let body = Font.system(size: 16, weight: .regular)
    static let caption = Font.system(size: 14, weight: .regular)
    static let small = Font.system(size: 12, weight: .regular)
}

// MARK: - 艾宾浩斯常量
struct EbbinghausConstants {
    // 复习时间节点（秒）
    static let reviewIntervals: [TimeInterval] = [
        20 * 60,                  // 20分钟
        60 * 60,                  // 1小时
        24 * 60 * 60,             // 1天
        3 * 24 * 60 * 60,         // 3天
        7 * 24 * 60 * 60,         // 7天
        14 * 24 * 60 * 60,        // 14天
        30 * 24 * 60 * 60         // 30天
    ]
    
    // 记忆等级对应的复习间隔索引
    static func intervalIndex(for masteryLevel: Int) -> Int {
        return min(masteryLevel, reviewIntervals.count - 1)
    }
}

// MARK: - Color 扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
