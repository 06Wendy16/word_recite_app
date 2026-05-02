package com.wordmaster.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.wordmaster.data.entity.Article
import com.wordmaster.data.repository.ArticleRepository
import com.wordmaster.data.repository.WordRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ArticleViewModel @Inject constructor(
    private val articleRepository: ArticleRepository,
    private val wordRepository: WordRepository
) : ViewModel() {
    
    private val _articles = MutableStateFlow<List<Article>>(emptyList())
    val articles: StateFlow<List<Article>> = _articles.asStateFlow()
    
    private val _selectedArticle = MutableStateFlow<Article?>(null)
    val selectedArticle: StateFlow<Article?> = _selectedArticle.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _filter = MutableStateFlow(ArticleFilter.ALL)
    val filter: StateFlow<ArticleFilter> = _filter.asStateFlow()
    
    init {
        loadArticles()
    }
    
    fun loadArticles() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val flow = when (_filter.value) {
                    ArticleFilter.ALL -> articleRepository.getAllArticles()
                    ArticleFilter.UNCOMPLETED -> articleRepository.getUncompletedArticles()
                    ArticleFilter.COMPLETED -> articleRepository.getCompletedArticles()
                }
                
                var isFirstLoad = true
                flow.collect { articleList ->
                    _articles.value = articleList
                    if (isFirstLoad) {
                        _isLoading.value = false
                        isFirstLoad = false
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
                _isLoading.value = false
            }
        }
    }
    
    fun setFilter(filter: ArticleFilter) {
        _filter.value = filter
        loadArticles()
    }
    
    fun selectArticle(articleId: String) {
        viewModelScope.launch {
            _selectedArticle.value = articleRepository.getArticleById(articleId)
        }
    }
    
    fun updateArticleProgress(article: Article, progress: Double) {
        viewModelScope.launch {
            articleRepository.updateArticleProgress(article, progress)
        }
    }
    
    fun importArticlesFromFolders(folderPaths: List<String>) {
        viewModelScope.launch {
            // 从文件夹导入短文的逻辑
            // 这里可以实现扫描文件夹并创建 Article 对象
        }
    }
}

enum class ArticleFilter {
    ALL,
    UNCOMPLETED,
    COMPLETED
}
