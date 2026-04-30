import SwiftUI

struct ReviewView: View {
    @StateObject private var viewModel = LearningViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showCompletionView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if viewModel.isCompleted || viewModel.words.isEmpty {
                    if viewModel.words.isEmpty {
                        EmptyReviewView()
                    } else {
                        ReviewCompletionView(
                            correctCount: viewModel.correctCount,
                            incorrectCount: viewModel.incorrectCount,
                            onDismiss: { dismiss() }
                        )
                    }
                } else if let word = viewModel.currentWord {
                    VStack(spacing: 0) {
                        // 复习模式提示
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundColor(AppColors.warning)
                            Text("复习模式")
                                .font(AppFonts.caption.bold())
                                .foregroundColor(AppColors.warning)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(AppColors.warning.opacity(0.1))
                        .cornerRadius(AppLayout.smallCornerRadius)
                        .padding(.top, AppLayout.smallSpacing)
                        
                        // 进度
                        HStack {
                            Text("\(viewModel.currentIndex + 1) / \(viewModel.words.count)")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Spacer()
                            
                            // 艾宾浩斯间隔提示
                            Text("下次复习: \(EbbinghausService.shared.getIntervalDescription(for: word.masteryLevel))")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.horizontal, AppLayout.horizontalPadding)
                        .padding(.top, 8)
                        
                        ProgressView(value: viewModel.progress)
                            .tint(AppColors.warning)
                            .padding(.horizontal, AppLayout.horizontalPadding)
                            .padding(.top, 4)
                        
                        Spacer()
                        
                        // 复习卡片
                        ReviewCard(
                            word: word,
                            isShowingAnswer: viewModel.isShowingAnswer,
                            onTap: { viewModel.toggleAnswer() }
                        )
                        .padding(.horizontal, AppLayout.horizontalPadding)
                        
                        Spacer()
                        
                        // 操作按钮
                        if viewModel.isShowingAnswer {
                            ReviewActionButtons(
                                onRemember: { viewModel.markAsRemembered() },
                                onForgot: { viewModel.markAsForgot() }
                            )
                            .padding(.horizontal, AppLayout.horizontalPadding)
                            .padding(.bottom, AppLayout.componentPadding)
                        } else {
                            Button(action: { viewModel.toggleAnswer() }) {
                                HStack {
                                    Image(systemName: "lightbulb")
                                    Text("想起来了？点击查看")
                                }
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(AppLayout.mediumCornerRadius)
                            }
                            .padding(.horizontal, AppLayout.horizontalPadding)
                            .padding(.bottom, AppLayout.componentPadding)
                        }
                    }
                }
            }
            .navigationTitle("复习")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.startReview()
            }
        }
    }
}

// MARK: - 复习卡片
struct ReviewCard: View {
    let word: Word
    let isShowingAnswer: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: AppLayout.componentPadding) {
            // 单词
            Text(word.text)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            // 复习次数
            HStack(spacing: 4) {
                Image(systemName: "repeat")
                    .font(.caption)
                Text("复习 \(word.reviewCount) 次")
                    .font(AppFonts.small)
            }
            .foregroundColor(AppColors.textSecondary)
            
            Rectangle()
                .fill(AppColors.warning.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 40)
            
            // 释义
            if isShowingAnswer {
                VStack(spacing: AppLayout.smallSpacing) {
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
                    }
                    
                    // 记忆等级
                    MasteryLevelView(level: word.masteryLevel)
                        .padding(.top, 8)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 30))
                        .foregroundColor(AppColors.warning)
                    
                    Text("点击回想释义")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textSecondary)
                }
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
                .stroke(AppColors.warning.opacity(0.3), lineWidth: 2)
        )
        .onTapGesture(perform: onTap)
        .animation(.easeInOut(duration: 0.3), value: isShowingAnswer)
    }
}

// MARK: - 记忆等级视图
struct MasteryLevelView: View {
    let level: Int
    let maxLevel = 7
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxLevel, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < level ? AppColors.secondary : AppColors.secondary.opacity(0.2))
                    .frame(width: 20, height: 6)
            }
        }
    }
}

// MARK: - 复习操作按钮
struct ReviewActionButtons: View {
    let onRemember: () -> Void
    let onForgot: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("你记住了吗？")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            HStack(spacing: AppLayout.cardSpacing) {
                Button(action: onForgot) {
                    VStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.title2)
                        Text("没记住")
                            .font(AppFonts.caption)
                    }
                    .foregroundColor(AppColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.accent.opacity(0.1))
                    .cornerRadius(AppLayout.mediumCornerRadius)
                }
                
                Button(action: onRemember) {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.title2)
                        Text("记住了")
                            .font(AppFonts.caption)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.secondary)
                    .cornerRadius(AppLayout.mediumCornerRadius)
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - 复习完成界面
struct ReviewCompletionView: View {
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
            
            Image(systemName: "star.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.warning)
            
            Text("复习完成！")
                .font(AppFonts.largeTitle)
                .foregroundColor(AppColors.textPrimary)
            
            Text("继续保持，下次记得更牢")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
            
            // 统计卡片
            HStack(spacing: 20) {
                ReviewStatCard(
                    icon: "brain.head.profile",
                    value: "\(correctCount)",
                    label: "记住",
                    color: AppColors.secondary
                )
                
                ReviewStatCard(
                    icon: "arrow.counterclockwise",
                    value: "\(incorrectCount)",
                    label: "再复习",
                    color: AppColors.accent
                )
            }
            .padding(.vertical, AppLayout.componentPadding)
            
            // 鼓励语
            if accuracy >= 0.8 {
                EncouragementView(
                    icon: "trophy.fill",
                    message: "表现优秀！",
                    subMessage: "正确率达到 \(Int(accuracy * 100))%"
                )
            } else if accuracy >= 0.5 {
                EncouragementView(
                    icon: "hand.thumbsup.fill",
                    message: "不错的开始！",
                    subMessage: "继续努力提高正确率"
                )
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("完成复习")
                    .primaryButtonStyle()
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.bottom, AppLayout.componentPadding)
        }
    }
}

struct ReviewStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(AppFonts.title.bold())
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(width: 100)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(AppLayout.mediumCornerRadius)
    }
}

struct EncouragementView: View {
    let icon: String
    let message: String
    let subMessage: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.warning)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(AppFonts.body.bold())
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subMessage)
                    .font(AppFonts.small)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(12)
        .background(AppColors.warning.opacity(0.1))
        .cornerRadius(AppLayout.mediumCornerRadius)
    }
}

// MARK: - 空复习界面
struct EmptyReviewView: View {
    var body: some View {
        VStack(spacing: AppLayout.componentPadding) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.secondary)
            
            Text("太棒了！")
                .font(AppFonts.largeTitle)
                .foregroundColor(AppColors.textPrimary)
            
            Text("当前没有需要复习的单词")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
            
            Text("去学习新单词吧")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
        }
    }
}

#Preview {
    ReviewView()
}
