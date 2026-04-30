package com.wordmaster.data.repository

import com.wordmaster.data.entity.ReviewRecord
import com.wordmaster.data.entity.Word
import com.wordmaster.data.local.WordDao
import com.wordmaster.data.local.ReviewRecordDao
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WordRepository @Inject constructor(
    private val wordDao: WordDao,
    private val reviewRecordDao: ReviewRecordDao
) {
    fun getAllWords(): Flow<List<Word>> = wordDao.getAllWords()
    
    fun getWordsByArticle(articleId: String): Flow<List<Word>> = 
        wordDao.getWordsByArticle(articleId)
    
    fun getWordsForReview(): Flow<List<Word>> = 
        wordDao.getWordsForReview(System.currentTimeMillis())
    
    fun getNewWords(): Flow<List<Word>> = wordDao.getNewWords()
    
    suspend fun getWordById(wordId: String): Word? = wordDao.getWordById(wordId)
    
    suspend fun getWordByText(text: String): Word? = wordDao.getWordByText(text)
    
    suspend fun saveWord(word: Word) = wordDao.insertWord(word)
    
    suspend fun saveWords(words: List<Word>) = wordDao.insertWords(words)
    
    suspend fun updateWord(word: Word) = wordDao.updateWord(word)
    
    suspend fun deleteWord(word: Word) = wordDao.deleteWord(word)
    
    suspend fun getWordCount(): Int = wordDao.getWordCount()
    
    suspend fun getMasteredWordCount(): Int = wordDao.getMasteredWordCount()
    
    suspend fun getTodayReviewedCount(): Int {
        val startOfDay = getStartOfDay()
        return wordDao.getTodayReviewedCount(startOfDay)
    }
    
    suspend fun saveReviewRecord(record: ReviewRecord) = 
        reviewRecordDao.insertRecord(record)
    
    fun getReviewRecordsByWord(wordId: String): Flow<List<ReviewRecord>> = 
        reviewRecordDao.getRecordsByWord(wordId)
    
    private fun getStartOfDay(): Long {
        val calendar = java.util.Calendar.getInstance()
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar.set(java.util.Calendar.MINUTE, 0)
        calendar.set(java.util.Calendar.SECOND, 0)
        calendar.set(java.util.Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }
}
