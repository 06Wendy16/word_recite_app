package com.wordmaster.viewmodel

import android.graphics.Bitmap
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.wordmaster.data.entity.Word
import com.wordmaster.data.repository.WordRepository
import com.wordmaster.utils.OCRService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AddWordViewModel @Inject constructor(
    private val wordRepository: WordRepository,
    private val ocrService: OCRService
) : ViewModel() {
    
    private val _recognizedWords = MutableStateFlow<List<String>>(emptyList())
    val recognizedWords: StateFlow<List<String>> = _recognizedWords.asStateFlow()
    
    private val _selectedWords = MutableStateFlow<Set<String>>(emptySet())
    val selectedWords: StateFlow<Set<String>> = _selectedWords.asStateFlow()
    
    private val _isProcessing = MutableStateFlow(false)
    val isProcessing: StateFlow<Boolean> = _isProcessing.asStateFlow()
    
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()
    
    private val _savedWords = MutableStateFlow<List<Word>>(emptyList())
    val savedWords: StateFlow<List<Word>> = _savedWords.asStateFlow()
    
    fun processImage(uri: Uri) {
        viewModelScope.launch {
            _isProcessing.value = true
            _error.value = null
            
            try {
                val result = ocrService.extractEnglishWordsFromUri(uri)
                if (result.isSuccess) {
                    _recognizedWords.value = result.getOrNull() ?: emptyList()
                } else {
                    _error.value = "识别失败: ${result.exceptionOrNull()?.message}"
                }
            } catch (e: Exception) {
                _error.value = "处理图片时出错: ${e.message}"
            } finally {
                _isProcessing.value = false
            }
        }
    }
    
    fun processBitmap(bitmap: Bitmap) {
        viewModelScope.launch {
            _isProcessing.value = true
            _error.value = null
            
            try {
                val result = ocrService.extractEnglishWordsFromBitmap(bitmap)
                if (result.isSuccess) {
                    _recognizedWords.value = result.getOrNull() ?: emptyList()
                } else {
                    _error.value = "识别失败: ${result.exceptionOrNull()?.message}"
                }
            } catch (e: Exception) {
                _error.value = "处理图片时出错: ${e.message}"
            } finally {
                _isProcessing.value = false
            }
        }
    }
    
    fun toggleWordSelection(word: String) {
        val current = _selectedWords.value.toMutableSet()
        if (current.contains(word)) {
            current.remove(word)
        } else {
            current.add(word)
        }
        _selectedWords.value = current
    }
    
    fun selectAllWords() {
        _selectedWords.value = _recognizedWords.value.toSet()
    }
    
    fun deselectAllWords() {
        _selectedWords.value = emptySet()
    }
    
    fun saveSelectedWords(articleId: String? = null) {
        viewModelScope.launch {
            val wordsToSave = _selectedWords.value.map { wordText ->
                Word(
                    text = wordText,
                    articleId = articleId
                )
            }
            
            wordRepository.saveWords(wordsToSave)
            _savedWords.value = wordsToSave
            
            // 清空选择
            _selectedWords.value = emptySet()
            _recognizedWords.value = emptyList()
        }
    }
    
    fun clear() {
        _recognizedWords.value = emptyList()
        _selectedWords.value = emptySet()
        _error.value = null
    }
}
