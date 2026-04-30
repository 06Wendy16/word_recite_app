package com.wordmaster.utils

import com.wordmaster.data.entity.ReviewRecord
import com.wordmaster.data.entity.ReviewResult
import com.wordmaster.data.entity.Word
import com.wordmaster.data.repository.WordRepository
import kotlinx.coroutines.flow.first
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class EbbinghausService @Inject constructor(
    private val wordRepository: WordRepository
) {
    companion object {
        // 复习时间节点（毫秒）
        val REVIEW_INTERVALS = listOf(
            20 * 60 * 1000L,      // 20分钟
            60 * 60 * 1000L,      // 1小时
            24 * 60 * 60 * 1000L, // 1天
            3 * 24 * 60 * 60 * 1000L,  // 3天
            7 * 24 * 60 * 60 * 1000L,  // 7天
            14 * 24 * 60 * 60 * 1000L, // 14天
            30 * 24 * 60 * 60 * 1000L  // 30天
        )
    }
    
    /**
     * 计算下次复习时间
     */
    fun calculateNextReviewDate(word: Word, remembered: Boolean): Long {
        val newMasteryLevel: Int
        val interval: Long
        
        if (remembered) {
            // 答对了，增加记忆等级
            newMasteryLevel = minOf(word.masteryLevel + 1, REVIEW_INTERVALS.size - 1)
            interval = REVIEW_INTERVALS[newMasteryLevel]
        } else {
            // 答错了，重置记忆等级
            newMasteryLevel = 1
            interval = REVIEW_INTERVALS[0] // 20分钟后再次复习
        }
        
        return System.currentTimeMillis() + interval
    }
    
    /**
     * 获取复习间隔描述
     */
    fun getIntervalDescription(masteryLevel: Int): String {
        val intervals = listOf(
            "20分钟",
            "1小时",
            "1天",
            "3天",
            "7天",
            "14天",
            "30天"
        )
        val index = minOf(masteryLevel, intervals.size - 1)
        return intervals[index]
    }
    
    /**
     * 获取复习进度描述
     */
    fun getProgressDescription(word: Word): String {
        return when {
            word.reviewCount == 0 -> "新单词"
            word.isMastered -> "已掌握"
            else -> "复习中 (${word.masteryLevel}/${REVIEW_INTERVALS.size})"
        }
    }
    
    /**
     * 获取需要复习的单词
     */
    suspend fun getWordsForReview(): List<Word> {
        return wordRepository.getWordsForReview().first()
    }
    
    /**
     * 获取今日复习统计
     */
    suspend fun getTodayReviewStats(): Triple<Int, Int, Int> {
        val words = wordRepository.getAllWords().first()
        val now = System.currentTimeMillis()
        
        val dueCount = words.count { word ->
            if (word.reviewCount == 0) return@count false
            val nextReview = word.nextReviewDate ?: return@count false
            nextReview <= now
        }
        
        val newCount = words.count { it.reviewCount == 0 }
        
        return Triple(dueCount, newCount, dueCount + minOf(newCount, 10))
    }
    
    /**
     * 更新单词复习状态
     */
    suspend fun recordReview(word: Word, remembered: Boolean) {
        val newMasteryLevel = if (remembered) {
            minOf(word.masteryLevel + 1, REVIEW_INTERVALS.size - 1)
        } else {
            1
        }
        
        val updatedWord = word.copy(
            reviewCount = word.reviewCount + 1,
            lastReviewedAt = System.currentTimeMillis(),
            nextReviewDate = calculateNextReviewDate(word, remembered),
            masteryLevel = newMasteryLevel,
            isMastered = newMasteryLevel >= REVIEW_INTERVALS.size - 1
        )
        
        wordRepository.updateWord(updatedWord)
        
        // 记录复习历史
        val record = ReviewRecord(
            wordId = word.id,
            result = if (remembered) ReviewResult.REMEMBER.name else ReviewResult.FORGOT.name
        )
        wordRepository.saveReviewRecord(record)
    }
    
    /**
     * 预估完全掌握需要的时间
     */
    fun estimateTimeToMastery(word: Word): String {
        val remainingLevels = REVIEW_INTERVALS.size - 1 - word.masteryLevel
        var totalDays = 0.0
        
        for (i in 0 until remainingLevels) {
            val level = word.masteryLevel + i
            val interval = REVIEW_INTERVALS[minOf(level, REVIEW_INTERVALS.size - 1)]
            totalDays += interval / (24 * 60 * 60 * 1000.0)
        }
        
        return when {
            totalDays < 1 -> "不到1天"
            totalDays < 30 -> "约${totalDays.toInt()}天"
            else -> "约${(totalDays / 30).toInt()}个月"
        }
    }
}
