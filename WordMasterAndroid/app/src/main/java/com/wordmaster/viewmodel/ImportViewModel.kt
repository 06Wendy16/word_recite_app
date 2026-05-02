package com.wordmaster.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.wordmaster.data.repository.WordRepository
import com.wordmaster.utils.ArticleFolder
import com.wordmaster.utils.ArticleImportService
import com.wordmaster.utils.ImportProgress
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ImportViewModel @Inject constructor(
    private val articleImportService: ArticleImportService,
    private val wordRepository: WordRepository
) : ViewModel() {

    private val _availableFolders = MutableStateFlow<List<ArticleFolder>>(emptyList())
    val availableFolders: StateFlow<List<ArticleFolder>> = _availableFolders.asStateFlow()

    private val _selectedFolders = MutableStateFlow<Set<String>>(emptySet())
    val selectedFolders: StateFlow<Set<String>> = _selectedFolders.asStateFlow()

    private val _isScanning = MutableStateFlow(false)
    val isScanning: StateFlow<Boolean> = _isScanning.asStateFlow()

    private val _isImporting = MutableStateFlow(false)
    val isImporting: StateFlow<Boolean> = _isImporting.asStateFlow()

    private val _importResult = MutableStateFlow<ImportResult?>(null)
    val importResult: StateFlow<ImportResult?> = _importResult.asStateFlow()

    val importProgress: StateFlow<ImportProgress> = articleImportService.importProgress

    /** 是否需要自动导入（数据库为空且扫描到文件夹）*/
    private val _shouldAutoImport = MutableStateFlow(false)
    val shouldAutoImport: StateFlow<Boolean> = _shouldAutoImport.asStateFlow()

    init {
        scanFolders()
    }

    fun scanFolders() {
        viewModelScope.launch {
            _isScanning.value = true
            _shouldAutoImport.value = false
            try {
                val folders = articleImportService.scanArticleFolders()
                _availableFolders.value = folders
                _selectedFolders.value = folders.map { it.name }.toSet()

                // 数据库为空时，标记需要自动导入
                val wordCount = wordRepository.getWordCount()
                if (wordCount == 0 && folders.isNotEmpty()) {
                    _shouldAutoImport.value = true
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                _isScanning.value = false
            }
        }
    }

    fun toggleFolderSelection(folderName: String) {
        val current = _selectedFolders.value.toMutableSet()
        if (current.contains(folderName)) {
            current.remove(folderName)
        } else {
            current.add(folderName)
        }
        _selectedFolders.value = current
    }

    fun selectAll() {
        _selectedFolders.value = _availableFolders.value.map { it.name }.toSet()
    }

    fun deselectAll() {
        _selectedFolders.value = emptySet()
    }

    fun startImport() {
        val foldersToImport = _availableFolders.value.filter { _selectedFolders.value.contains(it.name) }
        if (foldersToImport.isEmpty()) return

        viewModelScope.launch {
            _isImporting.value = true
            _importResult.value = null
            articleImportService.resetProgress()

            try {
                articleImportService.importArticleFolders(foldersToImport)
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                _isImporting.value = false
                val progress = articleImportService.importProgress.value
                _importResult.value = ImportResult(
                    success = progress.isComplete && progress.errorMessage == null,
                    articlesImported = progress.totalArticlesImported,
                    wordsImported = progress.totalWordsImported,
                    errorMessage = progress.errorMessage
                )
            }
        }
    }

    fun clearResult() {
        _importResult.value = null
        articleImportService.resetProgress()
    }
}

data class ImportResult(
    val success: Boolean,
    val articlesImported: Int,
    val wordsImported: Int,
    val errorMessage: String?
)
