import SwiftUI

struct ArticleListView: View {
    @StateObject private var viewModel = ArticleViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 筛选器
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppLayout.smallSpacing) {
                        ForEach(ArticleViewModel.FilterOption.allCases, id: \.self) { option in
                            FilterChip(
                                title: option.rawValue,
                                isSelected: viewModel.filterOption == option
                            ) {
                                viewModel.filterOption = option
                            }
                        }
                    }
                    .padding(.horizontal, AppLayout.horizontalPadding)
                    .padding(.vertical, AppLayout.smallSpacing)
                }
                
                // 短文列表
                if viewModel.filteredArticles.isEmpty {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "暂无短文",
                        message: "在「添加」页面导入图片来创建短文"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppLayout.cardSpacing) {
                            ForEach(viewModel.filteredArticles) { article in
                                NavigationLink(destination: ArticleDetailView(article: article)) {
                                    ArticleCard(
                                        article: article,
                                        wordCount: viewModel.getArticleWordCount(article)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, AppLayout.horizontalPadding)
                        .padding(.vertical, AppLayout.verticalPadding)
                    }
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("短文列表")
            .refreshable {
                viewModel.loadArticles()
            }
        }
    }
}

// MARK: - 筛选标签
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primary : AppColors.cardBackground)
                .cornerRadius(AppLayout.smallCornerRadius)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - 短文卡片
struct ArticleCard: View {
    let article: Article
    let wordCount: Int
    
    var body: some View {
        HStack(spacing: AppLayout.cardSpacing) {
            // 图片预览
            ArticleThumbnail(imagesPaths: article.imagesPaths)
            
            // 信息
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(article.title)
                        .font(AppFonts.subtitle)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    StatusBadge(progress: article.progress, isCompleted: article.isCompleted)
                }
                
                // 进度条
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(wordCount) 个单词")
                            .font(AppFonts.small)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(Int(article.progress * 100))%")
                            .font(AppFonts.small.bold())
                            .foregroundColor(AppColors.primary)
                    }
                    
                    ProgressView(value: article.progress)
                        .tint(progressColor)
                }
                
                // 图片数量
                HStack(spacing: 4) {
                    Image(systemName: "photo.stack")
                        .font(.caption)
                    Text("\(article.imagesPaths.count) 张图片")
                        .font(AppFonts.small)
                }
                .foregroundColor(AppColors.textSecondary)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppLayout.componentPadding)
        .frame(height: AppLayout.articleCardHeight)
        .cardStyle()
    }
    
    var progressColor: Color {
        if article.isCompleted {
            return AppColors.secondary
        } else if article.progress > 0 {
            return AppColors.primary
        } else {
            return AppColors.warning
        }
    }
}

// MARK: - 缩略图
struct ArticleThumbnail: View {
    let imagesPaths: [String]
    
    var body: some View {
        ZStack {
            if let firstPath = imagesPaths.first,
               let image = UIImage(contentsOfFile: firstPath) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                AppColors.primary.opacity(0.2)
            }
        }
        .frame(width: 80, height: 80)
        .cornerRadius(AppLayout.mediumCornerRadius)
        .overlay(
            Group {
                if imagesPaths.count > 1 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("+\(imagesPaths.count - 1)")
                                .font(AppFonts.small.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(4)
                                .padding(4)
                        }
                    }
                }
            }
        )
    }
}

// MARK: - 状态标签
struct StatusBadge: View {
    let progress: Double
    let isCompleted: Bool
    
    var body: some View {
        Text(statusText)
            .font(AppFonts.small)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .cornerRadius(AppLayout.smallCornerRadius)
    }
    
    var statusText: String {
        if isCompleted {
            return "已完成"
        } else if progress > 0 {
            return "学习中"
        } else {
            return "未开始"
        }
    }
    
    var statusColor: Color {
        if isCompleted {
            return AppColors.secondary
        } else if progress > 0 {
            return AppColors.primary
        } else {
            return AppColors.textSecondary
        }
    }
}

// MARK: - 空状态
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: AppLayout.componentPadding) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            
            Text(title)
                .font(AppFonts.title)
                .foregroundColor(AppColors.textPrimary)
            
            Text(message)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(AppLayout.componentPadding)
    }
}

#Preview {
    ArticleListView()
}
