package com.wordmaster.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.wordmaster.data.entity.Article
import com.wordmaster.data.entity.Word
import com.wordmaster.data.repository.ArticleRepository
import com.wordmaster.data.repository.WordRepository
import com.wordmaster.utils.EbbinghausService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class LearningViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val wordRepository: WordRepository,
    private val articleRepository: ArticleRepository,
    private val ebbinghausService: EbbinghausService
) : ViewModel() {
    
    private val articleId: String? = savedStateHandle["articleId"]
    
    private val _words = MutableStateFlow<List<Word>>(emptyList())
    val words: StateFlow<List<Word>> = _words.asStateFlow()
    
    private val _currentWordIndex = MutableStateFlow(0)
    val currentWordIndex: StateFlow<Int> = _currentWordIndex.asStateFlow()
    
    private val _showAnswer = MutableStateFlow(false)
    val showAnswer: StateFlow<Boolean> = _showAnswer.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _isCompleted = MutableStateFlow(false)
    val isCompleted: StateFlow<Boolean> = _isCompleted.asStateFlow()
    
    val currentWord: StateFlow<Word?> = combine(_words, _currentWordIndex) { words, index ->
        words.getOrNull(index)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(), null)
    
    init {
        loadWords()
    }
    
    private fun loadWords() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val wordFlow = if (articleId != null) {
                    wordRepository.getWordsByArticle(articleId)
                } else {
                    wordRepository.getWordsForReview()
                }
                
                wordFlow.collect { wordList ->
                    _words.value = wordList
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    fun showAnswer() {
        _showAnswer.value = true
    }
    
    fun hideAnswer() {
        _showAnswer.value = false
    }
    
    fun markWord(remembered: Boolean) {
        viewModelScope.launch {
            currentWord.value?.let { word ->
                ebbinghausService.recordReview(word, remembered)
                
                // 更新文章进度
                articleId?.let { id ->
                    val article = articleRepository.getArticleById(id)
                    article?.let {
                        val progress = (_currentWordIndex.value + 1).toDouble() / _words.value.size
                        articleRepository.updateArticleProgress(it, progress)
                    }
                }
                
                // 移动到下一个单词
                if (_currentWordIndex.value < _words.value.size - 1) {
                    _currentWordIndex.value += 1
                    _showAnswer.value = false
                } else {
                    _isCompleted.value = true
                }
            }
        }
    }
    
    fun skipWord() {
        if (_currentWordIndex.value < _words.value.size - 1) {
            _currentWordIndex.value += 1
            _showAnswer.value = false
        }
    }
    
    fun previousWord() {
        if (_currentWordIndex.value > 0) {
            _currentWordIndex.value -= 1
            _showAnswer.value = false
        }
    }
}
