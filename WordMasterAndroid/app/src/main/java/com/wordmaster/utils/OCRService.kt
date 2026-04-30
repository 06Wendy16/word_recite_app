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

@Singleton
class OCRService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
    
    /**
     * 从 URI 识别文字
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
     * 从 Bitmap 识别文字
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
     * 识别并提取英文单词
     */
    suspend fun extractEnglishWordsFromUri(imageUri: Uri): Result<List<String>> {
        return when (val result = recognizeTextFromUri(imageUri)) {
            is Result.Success -> {
                val words = extractEnglishWords(result.getOrNull() ?: emptyList())
                Result.success(words)
            }
            is Result.Failure -> result
        }
    }
    
    /**
     * 识别并提取英文单词（从 Bitmap）
     */
    suspend fun extractEnglishWordsFromBitmap(bitmap: Bitmap): Result<List<String>> {
        return when (val result = recognizeTextFromBitmap(bitmap)) {
            is Result.Success -> {
                val words = extractEnglishWords(result.getOrNull() ?: emptyList())
                Result.success(words)
            }
            is Result.Failure -> result
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
        
        // 去重并排序
        return allWords.distinct().sorted()
    }
}

/**
     * 从字符串中提取英文单词的扩展函数
     */
fun String.extractEnglishWords(): List<String> {
    val wordRegex = Regex("[a-zA-Z]{2,}")
    return wordRegex.findAll(this)
        .map { it.value.lowercase() }
        .filter { it.length >= 2 }
        .toList()
}
