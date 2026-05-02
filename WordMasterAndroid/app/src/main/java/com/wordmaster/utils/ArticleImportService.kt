package com.wordmaster.utils

import android.content.Context
import android.net.Uri
import android.provider.MediaStore
import com.wordmaster.data.entity.Article
import com.wordmaster.data.entity.Word
import com.wordmaster.data.repository.ArticleRepository
import com.wordmaster.data.repository.WordRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 短文文件夹信息
 */
data class ArticleFolder(
    val name: String,
    val path: String,
    val imageCount: Int,
    val imagePaths: List<String>
)

/**
 * 导入进度信息
 */
data class ImportProgress(
    val currentFolder: Int = 0,
    val totalFolders: Int = 0,
    val currentImage: Int = 0,
    val totalImages: Int = 0,
    val currentFolderName: String = "",
    val isComplete: Boolean = false,
    val totalWordsImported: Int = 0,
    val totalArticlesImported: Int = 0,
    val errorMessage: String? = null
)

/**
 * 识别出的单词对（英文+中文释义）
 */
data class WordDefinition(
    val english: String,
    val chineseDefinition: String?
)

@Singleton
class ArticleImportService @Inject constructor(
    @ApplicationContext private val context: Context,
    private val articleRepository: ArticleRepository,
    private val wordRepository: WordRepository,
    private val ocrService: OCRService
) {
    private val _importProgress = MutableStateFlow(ImportProgress())
    val importProgress: StateFlow<ImportProgress> = _importProgress.asStateFlow()

    /**
     * 短文文件夹的基础路径（与 word_recite_app 同级的文件夹）
     */
    private fun getBaseFolder(): File {
        // 获取 word_recite_app 的父目录
        val appDir = context.getExternalFilesDir(null)?.parentFile?.parentFile?.parentFile
        return appDir ?: context.getExternalFilesDir(null)!!
    }

    /**
     * 扫描可用的短文文件夹
     */
    suspend fun scanArticleFolders(): List<ArticleFolder> = withContext(Dispatchers.IO) {
        val baseFolder = getBaseFolder()
        val wordReciteFolder = File(baseFolder, "word_recite_app")

        if (!wordReciteFolder.exists()) {
            return@withContext emptyList()
        }

        val folders = mutableListOf<ArticleFolder>()

        // 扫描所有短文文件夹（短文1 到 短文20）
        for (i in 1..20) {
            val folderName = "短文$i"
            val folderPath = File(wordReciteFolder, folderName)

            if (folderPath.exists() && folderPath.isDirectory) {
                val imageFiles = folderPath.listFiles { file ->
                    file.isFile && isImageFile(file.name)
                }?.sortedBy { it.name } ?: emptyList()

                if (imageFiles.isNotEmpty()) {
                    folders.add(
                        ArticleFolder(
                            name = folderName,
                            path = folderPath.absolutePath,
                            imageCount = imageFiles.size,
                            imagePaths = imageFiles.map { it.absolutePath }
                        )
                    )
                }
            }
        }

        folders
    }

    /**
     * 从图片中提取单词和释义
     */
    private suspend fun extractWordsFromImage(imagePath: String): List<WordDefinition> {
        val file = File(imagePath)
        if (!file.exists()) return emptyList()

        return try {
            val uri = Uri.fromFile(file)
            val result = ocrService.recognizeTextBlocksFromUri(uri)

            if (result.isSuccess) {
                val blocks = result.getOrNull() ?: emptyList()
                extractWordDefinitionPairs(blocks)
            } else {
                // 如果 OCR 失败，尝试只提取英文单词
                val result2 = ocrService.extractEnglishWordsFromUri(uri)
                if (result2.isSuccess) {
                    result2.getOrNull()?.map { WordDefinition(it, null) } ?: emptyList()
                } else {
                    emptyList()
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            emptyList()
        }
    }

    /**
     * 从文本块中提取英文-中文配对
     * 百词斩风格的图片通常是：上半部分是英文单词，下半部分是中文释义
     */
    private fun extractWordDefinitionPairs(blocks: List<TextBlock>): List<WordDefinition> {
        if (blocks.isEmpty()) return emptyList()

        // 收集所有文本行并按垂直位置排序
        val allLines = blocks.flatMap { block ->
            block.lines.map { line -> line.trim() }
        }.filter { it.isNotBlank() }

        if (allLines.isEmpty()) return emptyList()

        val pairs = mutableListOf<WordDefinition>()

        // 策略1：按行交替配对（假设格式为：单词行 + 释义行）
        var i = 0
        while (i < allLines.size) {
            val current = allLines[i].trim()

            // 如果当前行是英文，尝试找下一个中文行作为释义
            if (current.isPrimarilyEnglish() && current.isEnglishOnly()) {
                val english = current.lowercase()
                var chineseDef: String? = null

                // 找下一个非英文行作为释义
                for (j in i + 1 until minOf(i + 3, allLines.size)) {
                    val next = allLines[j].trim()
                    if (!next.isEnglishOnly() && next.containsChinese()) {
                        chineseDef = next
                        break
                    }
                }

                pairs.add(WordDefinition(english, chineseDef))
            }
            i++
        }

        // 如果策略1失败，尝试策略2：纯英文单词提取
        if (pairs.isEmpty()) {
            for (line in allLines) {
                val words = line.extractEnglishWords()
                for (word in words) {
                    // 检查下一行是否有中文释义
                    val lineIndex = allLines.indexOf(line)
                    var chineseDef: String? = null
                    if (lineIndex >= 0 && lineIndex + 1 < allLines.size) {
                        val nextLine = allLines[lineIndex + 1]
                        if (!nextLine.isEnglishOnly() && nextLine.containsChinese()) {
                            chineseDef = nextLine
                        }
                    }
                    pairs.add(WordDefinition(word.lowercase(), chineseDef))
                }
            }
        }

        // 去重
        return pairs.distinctBy { it.english.lowercase() }
    }

    /**
     * 导入选定的短文文件夹
     */
    suspend fun importArticleFolders(folders: List<ArticleFolder>) {
        var totalWords = 0
        var totalArticles = 0
        val totalImages = folders.sumOf { it.imageCount }
        var processedImages = 0

        _importProgress.value = ImportProgress(
            totalFolders = folders.size,
            totalImages = totalImages
        )

        for ((folderIndex, folder) in folders.withIndex()) {
            _importProgress.value = _importProgress.value.copy(
                currentFolder = folderIndex + 1,
                currentFolderName = folder.name,
                currentImage = 0
            )

            val allWordsInArticle = mutableListOf<Word>()

            // 处理每个图片
            for ((imageIndex, imagePath) in folder.imagePaths.withIndex()) {
                _importProgress.value = _importProgress.value.copy(
                    currentImage = imageIndex + 1,
                    currentFolder = folderIndex + 1
                )

                val wordDefs = extractWordsFromImage(imagePath)

                for (def in wordDefs) {
                    val word = Word(
                        text = def.english.lowercase(),
                        definition = def.chineseDefinition,
                        imagePath = imagePath,
                        // articleId 稍后设置
                        createdAt = System.currentTimeMillis()
                    )
                    allWordsInArticle.add(word)
                }

                processedImages++
            }

            // 如果该文章有提取到单词，创建文章记录
            if (allWordsInArticle.isNotEmpty()) {
                // 去重（同篇文章中相同单词只保留一个）
                val uniqueWords = allWordsInArticle.distinctBy { it.text.lowercase() }

                // 先保存单词
                wordRepository.saveWords(uniqueWords)

                // 获取保存后单词的 ID
                val savedWords = uniqueWords.mapNotNull { word ->
                    wordRepository.getWordByText(word.text)?.let { saved ->
                        saved.copy(imagePath = word.imagePath) // 保留第一张图片路径
                    }
                }

                // 创建文章
                val article = Article(
                    title = folder.name,
                    imagePaths = Article.fromImagePathsList(folder.imagePaths),
                    wordIds = Article.fromWordIdsList(savedWords.map { it.id }),
                    folderPath = folder.path,
                    createdAt = System.currentTimeMillis()
                )

                articleRepository.saveArticle(article)

                // 更新单词的 articleId
                for (word in savedWords) {
                    val updatedWord = word.copy(articleId = article.id)
                    wordRepository.updateWord(updatedWord)
                }

                totalWords += savedWords.size
                totalArticles++
            }
        }

        _importProgress.value = _importProgress.value.copy(
            isComplete = true,
            totalWordsImported = totalWords,
            totalArticlesImported = totalArticles
        )
    }

    /**
     * 导入所有扫描到的短文文件夹
     */
    suspend fun importAllArticles() {
        val folders = scanArticleFolders()
        if (folders.isNotEmpty()) {
            importArticleFolders(folders)
        }
    }

    /**
     * 重置导入进度
     */
    fun resetProgress() {
        _importProgress.value = ImportProgress()
    }

    /**
     * 检查是否为图片文件
     */
    private fun isImageFile(fileName: String): Boolean {
        val ext = fileName.substringAfterLast('.', "").lowercase()
        return ext in listOf("jpg", "jpeg", "png", "gif", "bmp", "webp")
    }
}
