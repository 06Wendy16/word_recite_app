package com.wordmaster.data.local

import androidx.room.*
import com.wordmaster.data.entity.Article
import kotlinx.coroutines.flow.Flow

@Dao
interface ArticleDao {
    @Query("SELECT * FROM articles ORDER BY createdAt ASC")
    fun getAllArticles(): Flow<List<Article>>
    
    @Query("SELECT * FROM articles WHERE id = :articleId")
    suspend fun getArticleById(articleId: String): Article?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertArticle(article: Article)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertArticles(articles: List<Article>)
    
    @Update
    suspend fun updateArticle(article: Article)
    
    @Delete
    suspend fun deleteArticle(article: Article)
    
    @Query("SELECT COUNT(*) FROM articles")
    suspend fun getArticleCount(): Int
    
    @Query("SELECT * FROM articles WHERE isCompleted = 0")
    fun getUncompletedArticles(): Flow<List<Article>>
    
    @Query("SELECT * FROM articles WHERE isCompleted = 1")
    fun getCompletedArticles(): Flow<List<Article>>
}
