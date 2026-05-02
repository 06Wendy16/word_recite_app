package com.wordmaster.data.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.encodeToJsonElement
import java.util.Date
import java.util.UUID

@Entity(tableName = "articles")
data class Article(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val imagePaths: String = "[]", // JSON array of image paths
    val wordIds: String = "[]", // JSON array of word UUIDs
    val createdAt: Long = System.currentTimeMillis(),
    val progress: Double = 0.0,
    val isCompleted: Boolean = false,
    val folderPath: String? = null // 原始文件夹路径
) {
    fun getImagePathsList(): List<String> {
        return try {
            Json.decodeFromString(ListSerializer(String.serializer()), imagePaths)
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    fun getWordIdsList(): List<String> {
        return try {
            Json.decodeFromString(ListSerializer(String.serializer()), wordIds)
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    companion object {
        fun fromImagePathsList(paths: List<String>): String {
            return Json.encodeToString(ListSerializer(String.serializer()), paths)
        }
        
        fun fromWordIdsList(ids: List<String>): String {
            return Json.encodeToString(ListSerializer(String.serializer()), ids)
        }
    }
}
