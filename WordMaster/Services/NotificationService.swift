import Foundation
import UserNotifications

// MARK: - NotificationService
class NotificationService {
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - 请求通知权限
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("通知权限已获取")
                self.scheduleReviewReminders()
            } else if let error = error {
                print("通知权限请求失败: \(error)")
            }
        }
    }
    
    // MARK: - 安排复习提醒
    func scheduleReviewReminders() {
        // 清除现有提醒
        center.removeAllPendingNotificationRequests()
        
        // 获取需要复习的单词
        let wordsToReview = EbbinghausService.shared.getWordsForReview()
        
        // 设置多个提醒时间点
        let reminderTimes = [
            ("09:00", "早晨学习"),
            ("14:00", "下午复习"),
            ("20:00", "晚间巩固")
        ]
        
        for (timeString, title) in reminderTimes {
            scheduleDailyReminder(at: timeString, title: title, wordCount: wordsToReview.count)
        }
    }
    
    private func scheduleDailyReminder(at timeString: String, title: String, wordCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "📚 单词复习提醒"
        content.body = wordCount > 0 ? "你有 \(wordCount) 个单词需要复习" : "今天还没有学习新单词哦"
        content.sound = .default
        content.badge = NSNumber(value: wordCount)
        
        // 解析时间
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return }
        
        var dateComponents = DateComponents()
        dateComponents.hour = components[0]
        dateComponents.minute = components[1]
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "review-\(timeString)", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("安排提醒失败: \(error)")
            }
        }
    }
    
    // MARK: - 发送即时提醒
    func sendImmediateReminder(wordCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "⏰ 复习时间到!"
        content.body = "你有 \(wordCount) 个单词等待复习，现在开始吧！"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "immediate-review", content: content, trigger: trigger)
        
        center.add(request)
    }
    
    // MARK: - 设置单词掌握提醒
    func scheduleMasteryNotification(for word: Word) {
        guard let nextReview = word.nextReviewDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎯 复习提醒"
        content.body = "「\(word.text)」需要复习啦"
        content.sound = .default
        
        let triggerDate = nextReview.addingTimeInterval(-300) // 提前5分钟提醒
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: word.id.uuidString, content: content, trigger: trigger)
        
        center.add(request)
    }
    
    // MARK: - 清除徽章
    func clearBadge() {
        center.setBadgeCount(0)
    }
    
    // MARK: - 获取通知设置状态
    func getNotificationStatus(completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
}
