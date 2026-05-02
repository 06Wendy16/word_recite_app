package com.wordmaster.data.local

import androidx.room.*
import com.wordmaster.data.entity.Word
import com.wordmaster.data.entity.ReviewRecord
import kotlinx.coroutines.flow.Flow

@Dao
interface WordDao {
    @Query("SELECT * FROM words ORDER BY createdAt DESC")
    fun getAllWords(): Flow<List<Word>>
    
    @Query("SELECT * FROM words WHERE articleId = :articleId")
    fun getWordsByArticle(articleId: String): Flow<List<Word>>
    
    @Query("SELECT * FROM words WHERE nextReviewDate <= :currentTime OR nextReviewDate IS NULL")
    fun getWordsForReview(currentTime: Long = System.currentTimeMillis()): Flow<List<Word>>
    
    @Query("SELECT * FROM words WHERE id = :wordId")
    suspend fun getWordById(wordId: String): Word?
    
    @Query("SELECT * FROM words WHERE LOWER(text) = LOWER(:text) LIMIT 1")
    suspend fun getWordByText(text: String): Word?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertWord(word: Word)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertWords(words: List<Word>)
    
    @Update
    suspend fun updateWord(word: Word)
    
    @Delete
    suspend fun deleteWord(word: Word)
    
    @Query("SELECT COUNT(*) FROM words")
    suspend fun getWordCount(): Int
    
    @Query("SELECT COUNT(*) FROM words WHERE isMastered = 1")
    suspend fun getMasteredWordCount(): Int
    
    @Query("SELECT COUNT(*) FROM words WHERE lastReviewedAt >= :startOfDay")
    suspend fun getTodayReviewedCount(startOfDay: Long): Int
    
    @Query("SELECT * FROM words WHERE reviewCount = 0")
    fun getNewWords(): Flow<List<Word>>
}

@Dao
interface ReviewRecordDao {
    @Query("SELECT * FROM review_records WHERE wordId = :wordId ORDER BY reviewedAt DESC")
    fun getRecordsByWord(wordId: String): Flow<List<ReviewRecord>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRecord(record: ReviewRecord)
    
    @Query("SELECT * FROM review_records WHERE reviewedAt >= :startOfDay")
    suspend fun getTodayRecords(startOfDay: Long): List<ReviewRecord>
}
