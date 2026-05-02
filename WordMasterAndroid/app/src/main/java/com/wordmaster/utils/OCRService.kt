package com.wordmaster.utils

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.provider.MediaStore
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * 文本块，包含文字内容及其在图片中的位置信息
 */
data class TextBlock(
    val text: String,
    val boundingBox: android.graphics.Rect?,
    val lines: List<String>
)

@Singleton
class OCRService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    /**
     * 从 URI 识别文字（返回文本块）
     */
    suspend fun recognizeTextBlocksFromUri(imageUri: Uri): Result<List<TextBlock>> = withContext(Dispatchers.IO) {
        try {
            val bitmap = MediaStore.Images.Media.getBitmap(context.contentResolver, imageUri)
            recognizeTextBlocksFromBitmap(bitmap)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * 从 Bitmap 识别文字（返回文本块）
     */
    suspend fun recognizeTextBlocksFromBitmap(bitmap: Bitmap): Result<List<TextBlock>> =
        suspendCancellableCoroutine { continuation ->
            val image = InputImage.fromBitmap(bitmap, 0)

            recognizer.process(image)
                .addOnSuccessListener { visionText ->
                    val blocks = visionText.textBlocks.map { block ->
                        TextBlock(
                            text = block.text,
                            boundingBox = block.boundingBox,
                            lines = block.lines.map { it.text }
                        )
                    }
                    continuation.resume(Result.success(blocks))
                }
                .addOnFailureListener { e ->
                    continuation.resume(Result.failure(e))
                }
        }

    /**
     * 从 URI 识别文字（返回行列表）
     */
    suspend fun recognizeTextFromUri(imageUri: Uri): Result<List<String>> = withContext(Dispatchers.IO) {
        try {
            val bitmap = MediaStore.Images.Media.getBitmap(context.contentResolver, imageUri)
            recognizeTextFromBitmap(bitmap)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * 从 Bitmap 识别文字（返回行列表）
     */
    suspend fun recognizeTextFromBitmap(bitmap: Bitmap): Result<List<String>> =
        suspendCancellableCoroutine { continuation ->
            val image = InputImage.fromBitmap(bitmap, 0)

            recognizer.process(image)
                .addOnSuccessListener { visionText ->
                    val lines = visionText.textBlocks
                        .flatMap { it.lines }
                        .map { it.text }
                    continuation.resume(Result.success(lines))
                }
                .addOnFailureListener { e ->
                    continuation.resume(Result.failure(e))
                }
        }

    /**
     * 识别并提取英文单词（从 URI）
     */
    suspend fun extractEnglishWordsFromUri(imageUri: Uri): Result<List<String>> {
        return recognizeTextFromUri(imageUri).map { lines ->
            extractEnglishWords(lines)
        }
    }

    /**
     * 识别并提取英文单词（从 Bitmap）
     */
    suspend fun extractEnglishWordsFromBitmap(bitmap: Bitmap): Result<List<String>> {
        return recognizeTextFromBitmap(bitmap).map { lines ->
            extractEnglishWords(lines)
        }
    }

    /**
     * 从文本中提取英文单词
     */
    private fun extractEnglishWords(textLines: List<String>): List<String> {
        val allWords = mutableListOf<String>()

        for (line in textLines) {
            val words = line.extractEnglishWords()
            allWords.addAll(words)
        }

        return allWords.distinct().sorted()
    }

    /**
     * 从文本行中提取英文单词
     */
    fun extractEnglishWordsFromLines(lines: List<String>): List<String> {
        return extractEnglishWords(lines)
    }
}

/**
 * 从字符串中提取英文单词
 */
fun String.extractEnglishWords(): List<String> {
    val wordRegex = Regex("[a-zA-Z]{2,}")
    return wordRegex.findAll(this)
        .map { it.value.lowercase() }
        .filter { it.length >= 2 }
        .toList()
}

/**
 * 判断字符串是否包含中文字符
 */
fun String.containsChinese(): Boolean {
    return this.any { char ->
        Character.UnicodeBlock.of(char) == Character.UnicodeBlock.CJK_UNIFIED_IDEOGRAPHS ||
        Character.UnicodeBlock.of(char) == Character.UnicodeBlock.CJK_COMPATIBILITY_IDEOGRAPHS ||
        Character.UnicodeBlock.of(char) == Character.UnicodeBlock.GENERAL_PUNCTUATION
    }
}

/**
 * 判断字符串是否主要为英文
 */
fun String.isPrimarilyEnglish(): Boolean {
    val englishCount = this.count { it.isLetter() && it.lowercaseChar() in 'a'..'z' }
    val totalLetters = this.count { it.isLetter() }
    return totalLetters > 0 && englishCount.toFloat() / totalLetters > 0.7f
}

/**
 * 判断字符串是否全为英文单词（不含中文）
 */
fun String.isEnglishOnly(): Boolean {
    return this.all { !containsChineseChar(it) }
}

private fun containsChineseChar(c: Char): Boolean {
    return Character.UnicodeBlock.of(c) == Character.UnicodeBlock.CJK_UNIFIED_IDEOGRAPHS ||
           Character.UnicodeBlock.of(c) == Character.UnicodeBlock.CJK_COMPATIBILITY_IDEOGRAPHS ||
           Character.UnicodeBlock.of(c) == Character.UnicodeBlock.GENERAL_PUNCTUATION
}
