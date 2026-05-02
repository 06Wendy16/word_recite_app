package com.wordmaster.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.rememberAsyncImagePainter
import com.wordmaster.R
import com.wordmaster.ui.theme.SecondaryGreen
import com.wordmaster.viewmodel.ImportViewModel
import java.io.File

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ImportScreen(
    onBackClick: () -> Unit,
    onImportComplete: () -> Unit,
    viewModel: ImportViewModel = hiltViewModel()
) {
    val availableFolders by viewModel.availableFolders.collectAsState()
    val selectedFolders by viewModel.selectedFolders.collectAsState()
    val isScanning by viewModel.isScanning.collectAsState()
    val isImporting by viewModel.isImporting.collectAsState()
    val importProgress by viewModel.importProgress.collectAsState()
    val importResult by viewModel.importResult.collectAsState()

    // 导入完成后弹窗
    importResult?.let { result ->
        ImportResultDialog(
            result = result,
            onDismiss = {
                viewModel.clearResult()
                if (result.success) {
                    onImportComplete()
                }
            }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.import_articles),
                        style = MaterialTheme.typography.displaySmall
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
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
        ) {
            if (isScanning) {
                // 扫描中
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        CircularProgressIndicator()
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "正在扫描短文文件夹...",
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                }
            } else if (isImporting) {
                // 导入中 - 显示进度
                ImportingProgress(
                    progress = importProgress,
                    modifier = Modifier.fillMaxSize()
                )
            } else if (availableFolders.isEmpty()) {
                // 没有找到文件夹
                EmptyImportView(
                    onScanClick = { viewModel.scanFolders() },
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                // 文件夹列表
                FolderList(
                    folders = availableFolders,
                    selectedFolders = selectedFolders,
                    onToggle = { viewModel.toggleFolderSelection(it) },
                    onSelectAll = { viewModel.selectAll() },
                    onDeselectAll = { viewModel.deselectAll() },
                    onStartImport = { viewModel.startImport() },
                    modifier = Modifier.fillMaxSize()
                )
            }
        }
    }
}

@Composable
fun FolderList(
    folders: List<com.wordmaster.utils.ArticleFolder>,
    selectedFolders: Set<String>,
    onToggle: (String) -> Unit,
    onSelectAll: () -> Unit,
    onDeselectAll: () -> Unit,
    onStartImport: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        // 头部信息
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = "发现 ${folders.size} 个短文",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "将使用 OCR 识别图片中的英文单词",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                )
            }
        }

        // 全选/取消全选
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "选择要导入的短文",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Row {
                TextButton(onClick = onSelectAll) {
                    Text("全选")
                }
                TextButton(onClick = onDeselectAll) {
                    Text("取消")
                }
            }
        }

        // 文件夹列表
        LazyColumn(
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(folders) { folder ->
                FolderCard(
                    folder = folder,
                    isSelected = selectedFolders.contains(folder.name),
                    onToggle = { onToggle(folder.name) }
                )
            }
        }

        // 导入按钮
        Button(
            onClick = onStartImport,
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
                .height(56.dp),
            enabled = selectedFolders.isNotEmpty(),
            shape = RoundedCornerShape(16.dp)
        ) {
            Icon(Icons.Default.Download, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "开始导入 ${selectedFolders.size} 个短文",
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}

@Composable
fun FolderCard(
    folder: com.wordmaster.utils.ArticleFolder,
    isSelected: Boolean,
    onToggle: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onToggle),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected)
                MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
            else MaterialTheme.colorScheme.surface
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // 复选框
            Checkbox(
                checked = isSelected,
                onCheckedChange = { onToggle() }
            )

            Spacer(modifier = Modifier.width(8.dp))

            // 缩略图
            if (folder.imagePaths.isNotEmpty()) {
                val firstImage = folder.imagePaths.first()
                androidx.compose.foundation.Image(
                    painter = rememberAsyncImagePainter(File(firstImage)),
                    contentDescription = null,
                    modifier = Modifier
                        .size(64.dp)
                        .clip(RoundedCornerShape(8.dp)),
                    contentScale = ContentScale.Crop
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .clip(RoundedCornerShape(8.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Image,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f)
                    )
                }
            }

            Spacer(modifier = Modifier.width(12.dp))

            // 信息
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = folder.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "${folder.imageCount} 张图片",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }

            Icon(
                imageVector = if (isSelected) Icons.Default.CheckCircle else Icons.Default.Circle,
                contentDescription = null,
                tint = if (isSelected) SecondaryGreen else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f)
            )
        }
    }
}

@Composable
fun ImportingProgress(
    progress: com.wordmaster.utils.ImportProgress,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // 进度指示器
        CircularProgressIndicator(
            modifier = Modifier.size(80.dp),
            strokeWidth = 6.dp
        )

        Spacer(modifier = Modifier.height(32.dp))

        Text(
            text = "正在导入...",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = progress.currentFolderName.ifEmpty { "准备中" },
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
        )

        Spacer(modifier = Modifier.height(16.dp))

        // 进度条
        val totalImages = progress.totalImages.coerceAtLeast(1)
        val currentTotal = ((progress.currentFolder - 1) * (totalImages / progress.totalFolders.coerceAtLeast(1))) + progress.currentImage
        val overallProgress = currentTotal.toFloat() / totalImages

        LinearProgressIndicator(
            progress = { overallProgress },
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp)
                .clip(RoundedCornerShape(4.dp)),
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "第 ${progress.currentImage}/${progress.totalImages.coerceAtLeast(1)} 张图片",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
        )
    }
}

@Composable
fun EmptyImportView(
    onScanClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.FolderOff,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "未找到短文文件夹",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "请确保图片已放入 word_recite_app/短文文件夹",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
            )
            Spacer(modifier = Modifier.height(24.dp))
            Button(onClick = onScanClick) {
                Icon(Icons.Default.Refresh, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("重新扫描")
            }
        }
    }
}

@Composable
fun ImportResultDialog(
    result: com.wordmaster.viewmodel.ImportResult,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        icon = {
            if (result.success) {
                Icon(
                    Icons.Default.CheckCircle,
                    contentDescription = null,
                    tint = SecondaryGreen,
                    modifier = Modifier.size(48.dp)
                )
            } else {
                Icon(
                    Icons.Default.Error,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.error,
                    modifier = Modifier.size(48.dp)
                )
            }
        },
        title = {
            Text(
                text = if (result.success) "导入成功！" else "导入失败",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column {
                if (result.success) {
                    Text(
                        text = "已成功导入 ${result.articlesImported} 个短文，共 ${result.wordsImported} 个单词。",
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "现在可以去「短文」页面查看，或开始学习。",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                } else {
                    Text(
                        text = result.errorMessage ?: "导入过程中出现错误",
                        style = MaterialTheme.typography.bodyLarge
                    )
                }
            }
        },
        confirmButton = {
            Button(onClick = onDismiss) {
                Text(if (result.success) "开始学习" else "关闭")
            }
        }
    )
}
