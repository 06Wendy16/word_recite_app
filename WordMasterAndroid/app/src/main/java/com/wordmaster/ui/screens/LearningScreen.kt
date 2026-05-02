package com.wordmaster.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.wordmaster.R
import com.wordmaster.data.entity.Word
import com.wordmaster.ui.theme.AccentRed
import com.wordmaster.ui.theme.SecondaryGreen
import com.wordmaster.viewmodel.LearningViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LearningScreen(
    onBackClick: () -> Unit,
    onComplete: () -> Unit,
    viewModel: LearningViewModel = hiltViewModel()
) {
    val words by viewModel.words.collectAsState()
    val currentWordIndex by viewModel.currentWordIndex.collectAsState()
    val showAnswer by viewModel.showAnswer.collectAsState()
    val currentWord by viewModel.currentWord.collectAsState()
    val isCompleted by viewModel.isCompleted.collectAsState()
    
    if (isCompleted) {
        LearningCompleteScreen(onComplete = onComplete)
        return
    }
    
    if (words.isEmpty()) {
        EmptyLearningScreen(onBackClick = onBackClick)
        return
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        text = "学习单词 (${currentWordIndex + 1}/${words.size})",
                        style = MaterialTheme.typography.displaySmall
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "返回")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // 进度条
            LinearProgressIndicator(
                progress = { (currentWordIndex + 1).toFloat() / words.size },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp)
                    .clip(RoundedCornerShape(3.dp))
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // 单词卡片
            currentWord?.let { word ->
                WordCard(
                    word = word,
                    showAnswer = showAnswer,
                    onShowAnswer = { viewModel.showAnswer() },
                    modifier = Modifier.weight(1f)
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // 操作按钮
            if (showAnswer) {
                AnswerButtons(
                    onRemember = { viewModel.markWord(remembered = true) },
                    onForgot = { viewModel.markWord(remembered = false) }
                )
            } else {
                ShowAnswerButton(onClick = { viewModel.showAnswer() })
            }
        }
    }
}

@Composable
fun WordCard(
    word: Word,
    showAnswer: Boolean,
    onShowAnswer: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(enabled = !showAnswer, onClick = onShowAnswer),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // 单词
            Text(
                text = word.text,
                style = MaterialTheme.typography.displayLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            
            // 音标
            word.phonetic?.let { phonetic ->
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = phonetic,
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }
            
            // 答案区域
            AnimatedVisibility(
                visible = showAnswer,
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Spacer(modifier = Modifier.height(32.dp))
                    
                    Divider(modifier = Modifier.width(100.dp))
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // 词性
                    word.partOfSpeech?.let { pos ->
                        Text(
                            text = pos,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.secondary
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                    
                    // 释义
                    word.definition?.let { definition ->
                        Text(
                            text = definition,
                            style = MaterialTheme.typography.titleLarge,
                            textAlign = TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                    }
                    
                    // 词族
                    word.wordFamily?.let { family ->
                        Text(
                            text = "词族: $family",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.tertiary,
                            textAlign = TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                    
                    // 例句
                    word.exampleSentence?.let { example ->
                        Text(
                            text = "例句: $example",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
            
            if (!showAnswer) {
                Spacer(modifier = Modifier.height(24.dp))
                Text(
                    text = "点击查看释义",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                )
            }
        }
    }
}

@Composable
fun ShowAnswerButton(onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp),
        shape = RoundedCornerShape(16.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.primary
        )
    ) {
        Text(
            text = stringResource(R.string.show_answer),
            style = MaterialTheme.typography.bodyLarge
        )
    }
}

@Composable
fun AnswerButtons(
    onRemember: () -> Unit,
    onForgot: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Button(
            onClick = onForgot,
            modifier = Modifier
                .weight(1f)
                .height(56.dp),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = AccentRed.copy(alpha = 0.1f),
                contentColor = AccentRed
            )
        ) {
            Text(
                text = stringResource(R.string.forgot),
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Bold
            )
        }
        
        Button(
            onClick = onRemember,
            modifier = Modifier
                .weight(1f)
                .height(56.dp),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = SecondaryGreen
            )
        ) {
            Text(
                text = stringResource(R.string.remember),
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun LearningCompleteScreen(onComplete: () -> Unit) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "🎉",
                style = MaterialTheme.typography.displayLarge
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "学习完成！",
                style = MaterialTheme.typography.displayMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "已完成本次学习任务",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
            )
            Spacer(modifier = Modifier.height(32.dp))
            Button(
                onClick = onComplete,
                modifier = Modifier.width(200.dp)
            ) {
                Text("返回")
            }
        }
    }
}

@Composable
fun EmptyLearningScreen(onBackClick: () -> Unit) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.Close,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "暂无单词",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = onBackClick) {
                Text("返回")
            }
        }
    }
}
