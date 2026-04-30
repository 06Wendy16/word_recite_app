package com.wordmaster.data.entity

data class StudyStatistics(
    val totalWords: Int = 0,
    val masteredWords: Int = 0,
    val learningWords: Int = 0,
    val todayReviewed: Int = 0,
    val todayLearned: Int = 0,
    val streakDays: Int = 0,
    val wordsToReview: Int = 0,
    val newWords: Int = 0
)

data class TodayTask(
    val dueWords: Int = 0,
    val newWords: Int = 0,
    val totalTasks: Int = 0
)
