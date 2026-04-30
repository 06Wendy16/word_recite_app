import SwiftUI

struct ProfileView: View {
    @State private var statistics: (total: Int, mastered: Int, todayReviewed: Int, streak: Int) = (0, 0, 0, 0)
    @State private var notificationEnabled = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppLayout.cardSpacing) {
                    // 用户信息卡片
                    UserInfoCard()
                    
                    // 学习统计
                    StatisticsSection(statistics: statistics)
                    
                    // 词汇量分布
                    VocabularyDistributionSection(
                        total: statistics.total,
                        mastered: statistics.mastered
                    )
                    
                    // 设置选项
                    SettingsSection(
                        notificationEnabled: $notificationEnabled,
                        onClearData: { }
                    )
                    
                    // 关于
                    AboutSection()
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.vertical, AppLayout.verticalPadding)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("我的")
            .onAppear {
                statistics = DatabaseService.shared.getStatistics()
            }
        }
    }
}

// MARK: - 用户信息卡片
struct UserInfoCard: View {
    var body: some View {
        HStack(spacing: AppLayout.componentPadding) {
            // 头像
            ZStack {
                Circle()
                    .fill(AppColors.primaryGradient)
                    .frame(width: 70, height: 70)
                
                Image(systemName: "person.fill")
                    .font(.title)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("学习者")
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("坚持学习，遇见更好的自己")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(AppLayout.componentPadding)
        .cardStyle()
    }
}

// MARK: - 统计区域
struct StatisticsSection: View {
    let statistics: (total: Int, mastered: Int, todayReviewed: Int, streak: Int)
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallSpacing) {
            Text("学习统计")
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppLayout.cardSpacing) {
                StatCard(
                    icon: "book.fill",
                    value: "\(statistics.total)",
                    label: "总词汇",
                    color: AppColors.primary
                )
                
                StatCard(
                    icon: "checkmark.seal.fill",
                    value: "\(statistics.mastered)",
                    label: "已掌握",
                    color: AppColors.secondary
                )
                
                StatCard(
                    icon: "calendar",
                    value: "\(statistics.todayReviewed)",
                    label: "今日复习",
                    color: AppColors.warning
                )
                
                StatCard(
                    icon: "flame.fill",
                    value: "\(statistics.streak)",
                    label: "连续天数",
                    color: AppColors.accent
                )
            }
        }
    }
}

struct StatCard: View {
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
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppLayout.componentPadding)
        .background(color.opacity(0.1))
        .cornerRadius(AppLayout.mediumCornerRadius)
    }
}

// MARK: - 词汇量分布
struct VocabularyDistributionSection: View {
    let total: Int
    let mastered: Int
    
    var learning: Int { total - mastered }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallSpacing) {
            Text("词汇掌握情况")
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 0) {
                if total > 0 {
                    // 已掌握
                    Rectangle()
                        .fill(AppColors.secondary)
                        .frame(width: CGFloat(mastered) / CGFloat(total) * 200)
                    
                    // 学习中
                    Rectangle()
                        .fill(AppColors.primary)
                        .frame(width: CGFloat(learning) / CGFloat(total) * 200)
                } else {
                    Rectangle()
                        .fill(AppColors.textSecondary.opacity(0.3))
                        .frame(width: 200)
                }
            }
            .frame(height: 20)
            .cornerRadius(10)
            
            HStack(spacing: AppLayout.componentPadding) {
                LegendItem(color: AppColors.secondary, label: "已掌握 (\(mastered))")
                LegendItem(color: AppColors.primary, label: "学习中 (\(learning))")
            }
            .font(AppFonts.small)
        }
        .padding(AppLayout.componentPadding)
        .cardStyle()
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - 设置区域
struct SettingsSection: View {
    @Binding var notificationEnabled: Bool
    let onClearData: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallSpacing) {
            Text("设置")
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 0) {
                // 通知设置
                Toggle(isOn: $notificationEnabled) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(AppColors.primary)
                            .frame(width: 24)
                        
                        Text("复习提醒")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                .padding(AppLayout.componentPadding)
                .tint(AppColors.primary)
                
                Divider()
                
                // 清除数据
                Button(action: onClearData) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(AppColors.accent)
                            .frame(width: 24)
                        
                        Text("清除学习数据")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.accent)
                        
                        Spacer()
                    }
                    .padding(AppLayout.componentPadding)
                }
            }
            .background(AppColors.cardBackground)
            .cornerRadius(AppLayout.mediumCornerRadius)
        }
    }
}

// MARK: - 关于区域
struct AboutSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallSpacing) {
            Text("关于")
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 0) {
                AboutRow(icon: "info.circle", title: "版本", value: "1.0.0")
                
                Divider()
                
                AboutRow(icon: "heart.fill", title: "艾宾浩斯", value: "遵循遗忘曲线")
            }
            .background(AppColors.cardBackground)
            .cornerRadius(AppLayout.mediumCornerRadius)
            
            Text("基于艾宾浩斯遗忘曲线理论，智能安排复习时间，科学对抗遗忘")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, 4)
        }
    }
}

struct AboutRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary)
                .frame(width: 24)
            
            Text(title)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppLayout.componentPadding)
    }
}

#Preview {
    ProfileView()
}
