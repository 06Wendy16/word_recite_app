package com.wordmaster.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.wordmaster.data.entity.StudyStatistics
import com.wordmaster.data.entity.TodayTask
import com.wordmaster.data.repository.ArticleRepository
import com.wordmaster.data.repository.WordRepository
import com.wordmaster.utils.EbbinghausService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.Calendar
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val wordRepository: WordRepository,
    private val articleRepository: ArticleRepository,
    private val ebbinghausService: EbbinghausService
) : ViewModel() {
    
    private val _todayTask = MutableStateFlow(TodayTask())
    val todayTask: StateFlow<TodayTask> = _todayTask.asStateFlow()
    
    private val _statistics = MutableStateFlow(StudyStatistics())
    val statistics: StateFlow<StudyStatistics> = _statistics.asStateFlow()
    
    /** 数据库是否为空（需要导入单词）*/
    val needsImport: StateFlow<Boolean> = statistics.map { it.totalWords == 0 }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(), false)
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    init {
        loadTodayTask()
        loadStatistics()
    }
    
    private fun loadTodayTask() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val (due, new, total) = ebbinghausService.getTodayReviewStats()
                _todayTask.value = TodayTask(
                    dueWords = due,
                    newWords = new,
                    totalTasks = total
                )
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    private fun loadStatistics() {
        viewModelScope.launch {
            try {
                val totalWords = wordRepository.getWordCount()
                val masteredWords = wordRepository.getMasteredWordCount()
                val todayReviewed = wordRepository.getTodayReviewedCount()
                val (due, new, _) = ebbinghausService.getTodayReviewStats()
                
                _statistics.value = StudyStatistics(
                    totalWords = totalWords,
                    masteredWords = masteredWords,
                    learningWords = totalWords - masteredWords,
                    todayReviewed = todayReviewed,
                    wordsToReview = due,
                    newWords = new
                )
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
    
    fun refresh() {
        loadTodayTask()
        loadStatistics()
    }
}
