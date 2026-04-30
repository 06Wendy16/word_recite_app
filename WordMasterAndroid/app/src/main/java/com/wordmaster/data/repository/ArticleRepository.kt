package com.wordmaster.data.repository

import com.wordmaster.data.entity.Article
import com.wordmaster.data.local.ArticleDao
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ArticleRepository @Inject constructor(
    private val articleDao: ArticleDao
) {
    fun getAllArticles(): Flow<List<Article>> = articleDao.getAllArticles()
    
    fun getUncompletedArticles(): Flow<List<Article>> = articleDao.getUncompletedArticles()
    
    fun getCompletedArticles(): Flow<List<Article>> = articleDao.getCompletedArticles()
    
    suspend fun getArticleById(articleId: String): Article? = articleDao.getArticleById(articleId)
    
    suspend fun saveArticle(article: Article) = articleDao.insertArticle(article)
    
    suspend fun saveArticles(articles: List<Article>) = articleDao.insertArticles(articles)
    
    suspend fun updateArticle(article: Article) = articleDao.updateArticle(article)
    
    suspend fun deleteArticle(article: Article) = articleDao.deleteArticle(article)
    
    suspend fun getArticleCount(): Int = articleDao.getArticleCount()
    
    suspend fun updateArticleProgress(article: Article, progress: Double) {
        val updatedArticle = article.copy(
            progress = progress,
            isCompleted = progress >= 1.0
        )
        articleDao.updateArticle(updatedArticle)
    }
}
