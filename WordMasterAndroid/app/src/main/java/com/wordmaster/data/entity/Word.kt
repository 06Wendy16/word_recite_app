package com.wordmaster.data.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(tableName = "words")
data class Word(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val text: String,
    val phonetic: String? = null,
    val partOfSpeech: String? = null,
    val definition: String? = null,
    val exampleSentence: String? = null,
    val wordFamily: String? = null,
    val imagePath: String? = null,
    val articleId: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val lastReviewedAt: Long? = null,
    val nextReviewDate: Long? = null,
    val reviewCount: Int = 0,
    val masteryLevel: Int = 0,
    val isMastered: Boolean = false
) {
    fun toDate(timestamp: Long?): Date? = timestamp?.let { Date(it) }
    
    companion object {
        fun fromDate(date: Date?): Long? = date?.time
    }
}

enum class ReviewResult {
    REMEMBER,
    FORGOT
}

@Entity(tableName = "review_records")
data class ReviewRecord(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val wordId: String,
    val reviewedAt: Long = System.currentTimeMillis(),
    val result: String, // "REMEMBER" or "FORGOT"
    val responseTime: Long = 0 // in milliseconds
)
