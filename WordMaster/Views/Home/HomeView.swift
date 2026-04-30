import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var appState: AppState
    @State private var showReviewView = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppLayout.cardSpacing) {
                    // 复习提醒横幅
                    if viewModel.totalTodayTasks > 0 {
                        ReviewBanner(
                            reviewCount: viewModel.todayReviewWords.count,
                            newCount: viewModel.todayNewWords.count
                        ) {
                            showReviewView = true
                        }
                    }
                    
                    // 学习进度卡片
                    ProgressCard(
                        total: viewModel.statistics.total,
                        mastered: viewModel.statistics.mastered,
                        streak: viewModel.statistics.streak
                    )
                    
                    // 今日任务卡片
                    TodayTasksCard(
                        reviewCount: viewModel.todayReviewWords.count,
                        newCount: viewModel.todayNewWords.count
                    ) {
                        showReviewView = true
                    }
                    
                    // 快捷操作
                    QuickActionsSection()
                    
                    // 最近短文
                    if !viewModel.recentArticles.isEmpty {
                        RecentArticlesSection(articles: viewModel.recentArticles)
                    }
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.vertical, AppLayout.verticalPadding)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("单词记忆")
            .refreshable {
                viewModel.loadData()
                appState.updateTodayStats()
            }
            .sheet(isPresented: $showReviewView) {
                ReviewView()
            }
        }
    }
}

// MARK: - 复习横幅
struct ReviewBanner: View {
    let reviewCount: Int
    let newCount: Int
    let onStartReview: () -> Void
    
    var body: some View {
        Button(action: onStartReview) {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日学习任务")
                        .font(AppFonts.subtitle)
                        .foregroundColor(.white)
                    
                    Text("\(reviewCount)个待复习 · \(newCount)个新单词")
                        .font(AppFonts.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
            }
            .padding(AppLayout.componentPadding)
            .background(AppColors.primaryGradient)
            .cornerRadius(AppLayout.largeCornerRadius)
        }
    }
}

// MARK: - 进度卡片
struct ProgressCard: View {
    let total: Int
    let mastered: Int
    let streak: Int
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(mastered) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: AppLayout.smallSpacing) {
            HStack {
                Text("学习进度")
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(AppFonts.caption.bold())
                    .foregroundColor(AppColors.primary)
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.primary.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.primaryGradient)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                StatItem(icon: "book.fill", value: "\(total)", label: "总词汇")
                Spacer()
                StatItem(icon: "checkmark.seal.fill", value: "\(mastered)", label: "已掌握")
                Spacer()
                StatItem(icon: "flame.fill", value: "\(streak)", label: "连续天数")
            }
        }
        .padding(AppLayout.componentPadding)
        .cardStyle()
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary)
            
            Text(value)
                .font(AppFonts.subtitle.bold())
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(AppFonts.small)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - 今日任务卡片
struct TodayTasksCard: View {
    let reviewCount: Int
    let newCount: Int
    let onStartReview: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallSpacing) {
            Text("今日任务")
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: AppLayout.cardSpacing) {
                TaskButton(
                    icon: "arrow.clockwise",
                    title: "复习",
                    count: reviewCount,
                    color: AppColors.warning
                ) {
                    onStartReview()
                }
                
                TaskButton(
                    icon: "plus.circle",
                    title: "新词",
                    count: newCount,
                    color: AppColors.secondary
                ) {
                    onStartReview()
                }
            }
        }
        .padding(AppLayout.componentPadding)
        .cardStyle()
    }
}

struct TaskButton: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Text("\(title) \(count)")
                    .font(AppFonts.caption.bold())
                    .foregroundColor(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - 快捷操作
struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallSpacing) {
            Text("快捷操作")
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: AppLayout.cardSpacing) {
                QuickActionButton(icon: "camera.fill", title: "拍照识词", color: AppColors.primary) {
                    // 跳转到添加页面
                }
                
                QuickActionButton(icon: "photo.fill", title: "相册选图", color: AppColors.secondary) {
                    // 跳转到添加页面
                }
                
                QuickActionButton(icon: "list.bullet", title: "词库管理", color: AppColors.accent) {
                    // 跳转到词库管理
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(AppFonts.small)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .cornerRadius(AppLayout.mediumCornerRadius)
        }
    }
}

// MARK: - 最近短文
struct RecentArticlesSection: View {
    let articles: [Article]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallSpacing) {
            HStack {
                Text("最近短文")
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: ArticleListView()) {
                    Text("查看全部")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.primary)
                }
            }
            
            ForEach(articles) { article in
                NavigationLink(destination: ArticleDetailView(article: article)) {
                    RecentArticleRow(article: article)
                }
            }
        }
    }
}

struct RecentArticleRow: View {
    let article: Article
    
    var body: some View {
        HStack(spacing: 12) {
            // 缩略图
            if let firstImagePath = article.imagesPaths.first,
               let image = UIImage(contentsOfFile: firstImagePath) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.primary.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "doc.text")
                            .foregroundColor(AppColors.primary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(AppFonts.body.bold())
                    .foregroundColor(AppColors.textPrimary)
                
                ProgressView(value: article.progress)
                    .tint(article.isCompleted ? AppColors.secondary : AppColors.primary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppLayout.smallSpacing)
        .cardStyle()
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
