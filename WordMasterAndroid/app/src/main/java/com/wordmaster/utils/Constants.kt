package com.wordmaster.utils

object Constants {
    // 布局常量
    const val HORIZONTAL_PADDING = 16
    const val VERTICAL_PADDING = 12
    const val CARD_SPACING = 12
    const val COMPONENT_PADDING = 16
    const val SMALL_SPACING = 8
    
    // 圆角
    const val LARGE_CORNER_RADIUS = 16
    const val MEDIUM_CORNER_RADIUS = 12
    const val SMALL_CORNER_RADIUS = 8
    
    // 卡片高度
    const val ARTICLE_CARD_HEIGHT = 120
    const val WORD_CARD_MIN_HEIGHT = 200
    
    // 导航路由
    object Routes {
        const val HOME = "home"
        const val ARTICLES = "articles"
        const val ARTICLE_DETAIL = "article_detail/{articleId}"
        const val ADD_WORD = "add_word"
        const val LEARNING = "learning/{articleId}"
        const val REVIEW = "review"
        const val PROFILE = "profile"
        const val STATISTICS = "statistics"
        const val SETTINGS = "settings"
        
        fun articleDetail(articleId: String) = "article_detail/$articleId"
        fun learning(articleId: String) = "learning/$articleId"
    }
    
    // 底部导航项
    object BottomNavItems {
        const val HOME = "home"
        const val ARTICLES = "articles"
        const val ADD = "add"
        const val PROFILE = "profile"
    }
}

// 艾宾浩斯复习间隔（毫秒）
object EbbinghausIntervals {
    val INTERVALS = listOf(
        20 * 60 * 1000L,      // 20分钟
        60 * 60 * 1000L,      // 1小时
        24 * 60 * 60 * 1000L, // 1天
        3 * 24 * 60 * 60 * 1000L,  // 3天
        7 * 24 * 60 * 60 * 1000L,  // 7天
        14 * 24 * 60 * 60 * 1000L, // 14天
        30 * 24 * 60 * 60 * 1000L  // 30天
    )
}
