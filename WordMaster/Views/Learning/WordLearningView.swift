import SwiftUI

struct WordLearningView: View {
    let words: [Word]
    let articleId: String?
    @StateObject private var viewModel = LearningViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showCompletionView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if viewModel.isCompleted {
                    CompletionView(
                        correctCount: viewModel.correctCount,
                        incorrectCount: viewModel.incorrectCount,
                        onDismiss: { dismiss() }
                    )
                } else if let word = viewModel.currentWord {
                    VStack(spacing: 0) {
                        // 进度条
                        ProgressView(value: viewModel.progress)
                            .tint(AppColors.primary)
                            .padding(.horizontal, AppLayout.horizontalPadding)
                            .padding(.top, AppLayout.smallSpacing)
                        
                        // 进度文字
                        HStack {
                            Text("\(viewModel.currentIndex + 1) / \(viewModel.words.count)")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Spacer()
                            
                            Text("剩余 \(viewModel.remainingCount)")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.horizontal, AppLayout.horizontalPadding)
                        .padding(.top, 4)
                        
                        Spacer()
                        
                        // 单词卡片
                        WordCard(
                            word: word,
                            isShowingAnswer: viewModel.isShowingAnswer,
                            onTap: { viewModel.toggleAnswer() }
                        )
                        .padding(.horizontal, AppLayout.horizontalPadding)
                        
                        Spacer()
                        
                        // 操作按钮
                        if viewModel.isShowingAnswer {
                            LearningActionButtons(
                                onRemember: { viewModel.markAsRemembered() },
                                onForgot: { viewModel.markAsForgot() }
                            )
                            .padding(.horizontal, AppLayout.horizontalPadding)
                            .padding(.bottom, AppLayout.componentPadding)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            Button(action: { viewModel.toggleAnswer() }) {
                                Text("显示答案")
                                    .primaryButtonStyle()
                            }
                            .padding(.horizontal, AppLayout.horizontalPadding)
                            .padding(.bottom, AppLayout.componentPadding)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isShowingAnswer)
                } else {
                    EmptyLearningView()
                }
            }
            .navigationTitle("学习")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if !words.isEmpty {
                    viewModel.startLearning(words: words)
                }
            }
        }
    }
}

// MARK: - 单词卡片
struct WordCard: View {
    let word: Word
    let isShowingAnswer: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: AppLayout.componentPadding) {
            // 单词
            Text(word.text)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            // 音标
            if let phonetic = word.phonetic {
                Text(phonetic)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // 分割线
            Rectangle()
                .fill(AppColors.primary.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 40)
            
            // 释义区域
            if isShowingAnswer {
                VStack(spacing: AppLayout.smallSpacing) {
                    if let partOfSpeech = word.partOfSpeech {
                        Text(partOfSpeech)
                            .font(AppFonts.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(AppColors.primary)
                            .cornerRadius(AppLayout.smallCornerRadius)
                    }
                    
                    if let definition = word.definition {
                        Text(definition)
                            .font(AppFonts.subtitle)
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let example = word.exampleSentence {
                        Text(example)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                Text("点击卡片显示释义")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(AppLayout.componentPadding * 1.5)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.largeCornerRadius)
                .fill(AppColors.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.largeCornerRadius)
                .stroke(AppColors.primary.opacity(0.3), lineWidth: 2)
        )
        .onTapGesture(perform: onTap)
        .animation(.easeInOut(duration: 0.3), value: isShowingAnswer)
    }
}

// MARK: - 学习操作按钮
struct LearningActionButtons: View {
    let onRemember: () -> Void
    let onForgot: () -> Void
    
    var body: some View {
        HStack(spacing: AppLayout.cardSpacing) {
            Button(action: onForgot) {
                HStack {
                    Image(systemName: "xmark")
                    Text("不认识")
                }
                .font(AppFonts.body.bold())
                .foregroundColor(AppColors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.accent.opacity(0.1))
                .cornerRadius(AppLayout.mediumCornerRadius)
            }
            
            Button(action: onRemember) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("认识")
                }
                .font(AppFonts.body.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.secondary)
                .cornerRadius(AppLayout.mediumCornerRadius)
            }
        }
    }
}

// MARK: - 完成界面
struct CompletionView: View {
    let correctCount: Int
    let incorrectCount: Int
    let onDismiss: () -> Void
    
    var total: Int { correctCount + incorrectCount }
    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correctCount) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: AppLayout.componentPadding) {
            Spacer()
            
            Image(systemName: "party.popper.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.secondary)
            
            Text("太棒了！")
                .font(AppFonts.largeTitle)
                .foregroundColor(AppColors.textPrimary)
            
            Text("本次学习完成")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
            
            // 统计
            HStack(spacing: 40) {
                CompletionStatView(
                    icon: "checkmark.circle.fill",
                    value: "\(correctCount)",
                    label: "认识",
                    color: AppColors.secondary
                )
                
                CompletionStatView(
                    icon: "xmark.circle.fill",
                    value: "\(incorrectCount)",
                    label: "不认识",
                    color: AppColors.accent
                )
                
                CompletionStatView(
                    icon: "target",
                    value: "\(Int(accuracy * 100))%",
                    label: "正确率",
                    color: AppColors.primary
                )
            }
            .padding(.vertical, AppLayout.componentPadding)
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("完成")
                    .primaryButtonStyle()
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.bottom, AppLayout.componentPadding)
        }
    }
}

struct CompletionStatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(AppFonts.title.bold())
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(AppFonts.small)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - 空学习界面
struct EmptyLearningView: View {
    var body: some View {
        VStack(spacing: AppLayout.componentPadding) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary)
            
            Text("没有要学习的单词")
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.textPrimary)
            
            Text("去「添加」页面导入新单词吧")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

#Preview {
    WordLearningView(
        words: [
            Word(text: "hello", phonetic: "/həˈloʊ/", partOfSpeech: "n.", definition: "你好，问候"),
            Word(text: "world", phonetic: "/wɜːrld/", partOfSpeech: "n.", definition: "世界，地球")
        ],
        articleId: nil
    )
}
