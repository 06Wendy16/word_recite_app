import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @StateObject private var viewModel = ArticleViewModel()
    @State private var showLearningView = false
    @State private var currentImageIndex = 0
    
    var words: [Word] {
        DatabaseService.shared.getWords(forArticle: article.id.uuidString)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppLayout.cardSpacing) {
                // 图片浏览区域
                ImageBrowserView(
                    imagesPaths: article.imagesPaths,
                    currentIndex: $currentImageIndex
                )
                
                // 短文信息
                ArticleInfoSection(article: article, wordCount: words.count)
                
                // 单词列表
                if words.isEmpty {
                    EmptyWordListCard(onStartLearning: {
                        showLearningView = true
                    })
                } else {
                    WordListSection(words: words) {
                        showLearningView = true
                    }
                }
                
                // 开始学习按钮
                if !words.isEmpty {
                    Button(action: { showLearningView = true }) {
                        Text(article.progress > 0 ? "继续学习" : "开始学习")
                            .primaryButtonStyle()
                    }
                    .padding(.top, AppLayout.smallSpacing)
                }
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.vertical, AppLayout.verticalPadding)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLearningView) {
            WordLearningView(words: words, articleId: article.id.uuidString)
        }
    }
}

// MARK: - 图片浏览器
struct ImageBrowserView: View {
    let imagesPaths: [String]
    @Binding var currentIndex: Int
    
    var body: some View {
        VStack(spacing: AppLayout.smallSpacing) {
            TabView(selection: $currentIndex) {
                ForEach(Array(imagesPaths.enumerated()), id: \.offset) { index, path in
                    if let image = UIImage(contentsOfFile: path) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(AppLayout.mediumCornerRadius)
                            .tag(index)
                    } else {
                        RoundedRectangle(cornerRadius: AppLayout.mediumCornerRadius)
                            .fill(AppColors.primary.opacity(0.1))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(AppColors.primary)
                            )
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 300)
            
            // 页码指示器
            if imagesPaths.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<imagesPaths.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? AppColors.primary : AppColors.primary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }
}

// MARK: - 短文信息区
struct ArticleInfoSection: View {
    let article: Article
    let wordCount: Int
    
    var body: some View {
        HStack(spacing: AppLayout.cardSpacing) {
            InfoStatView(icon: "doc.text", value: "\(article.imagesPaths.count)", label: "图片")
            InfoStatView(icon: "character.book.closed", value: "\(wordCount)", label: "单词")
            InfoStatView(icon: "chart.line.uptrend.xyaxis", value: "\(Int(article.progress * 100))%", label: "进度")
        }
        .padding(AppLayout.componentPadding)
        .cardStyle()
    }
}

struct InfoStatView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.primary)
            
            Text(value)
                .font(AppFonts.subtitle.bold())
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(AppFonts.small)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 单词列表
struct WordListSection: View {
    let words: [Word]
    let onStartLearning: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallSpacing) {
            HStack {
                Text("本短文单词")
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: onStartLearning) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                        Text("学习")
                    }
                    .font(AppFonts.caption.bold())
                    .foregroundColor(AppColors.primary)
                }
            }
            
            ForEach(words.prefix(5)) { word in
                WordRow(word: word)
            }
            
            if words.count > 5 {
                Text("还有 \(words.count - 5) 个单词...")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.vertical, 8)
            }
        }
        .padding(AppLayout.componentPadding)
        .cardStyle()
    }
}

struct WordRow: View {
    let word: Word
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(word.text)
                    .font(AppFonts.body.bold())
                    .foregroundColor(AppColors.textPrimary)
                
                if let definition = word.definition {
                    Text(definition)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // 掌握状态指示
            if word.isMastered {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.secondary)
            } else if word.reviewCount > 0 {
                MasteryIndicator(level: word.masteryLevel)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MasteryIndicator: View {
    let level: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(index < level ? AppColors.secondary : AppColors.secondary.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - 空单词列表
struct EmptyWordListCard: View {
    let onStartLearning: () -> Void
    
    var body: some View {
        VStack(spacing: AppLayout.componentPadding) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textSecondary)
            
            Text("暂无单词")
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.textPrimary)
            
            Text("点击下方按钮开始学习，或在「添加」页面导入新单词")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: onStartLearning) {
                Text("手动添加单词")
                    .secondaryButtonStyle()
            }
        }
        .padding(AppLayout.componentPadding)
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: Article(title: "短文1"))
    }
}
