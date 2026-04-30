import SwiftUI

@main
struct WordMasterApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        // 初始化数据库
        DatabaseService.shared.initializeDatabase()
        
        // 请求通知权限
        NotificationService.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// 全局应用状态
class AppState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var todayReviewCount: Int = 0
    @Published var todayNewWordsCount: Int = 0
    
    enum Tab: Int {
        case home = 0
        case articles = 1
        case add = 2
        case profile = 3
    }
    
    init() {
        updateTodayStats()
    }
    
    func updateTodayStats() {
        let words = DatabaseService.shared.getAllWords()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        todayReviewCount = words.filter { word in
            guard let nextReview = word.nextReviewDate else { return false }
            return nextReview <= Date() && nextReview >= today
        }.count
        
        todayNewWordsCount = words.filter { word in
            word.reviewCount == 0
        }.count
    }
}

// SceneDelegate 支持
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }
}
