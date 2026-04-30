package com.wordmaster

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.wordmaster.ui.screens.*
import com.wordmaster.ui.theme.WordMasterTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            WordMasterTheme {
                WordMasterApp()
            }
        }
    }
}

@Composable
fun WordMasterApp() {
    val navController = rememberNavController()
    
    val items = listOf(
        BottomNavItem.Home,
        BottomNavItem.Articles,
        BottomNavItem.Add,
        BottomNavItem.Profile
    )
    
    Scaffold(
        bottomBar = {
            NavigationBar {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentDestination = navBackStackEntry?.destination
                
                items.forEach { item ->
                    NavigationBarItem(
                        icon = { Icon(item.icon, contentDescription = item.label) },
                        label = { Text(item.label) },
                        selected = currentDestination?.hierarchy?.any { it.route == item.route } == true,
                        onClick = {
                            navController.navigate(item.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = BottomNavItem.Home.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(BottomNavItem.Home.route) {
                HomeScreen(
                    onNavigateToArticles = {
                        navController.navigate(BottomNavItem.Articles.route)
                    },
                    onNavigateToReview = {
                        navController.navigate("review")
                    },
                    onNavigateToStatistics = {
                        navController.navigate("statistics")
                    }
                )
            }
            
            composable(BottomNavItem.Articles.route) {
                ArticleListScreen(
                    onArticleClick = { articleId ->
                        navController.navigate("article_detail/$articleId")
                    }
                )
            }
            
            composable("article_detail/{articleId}") { backStackEntry ->
                val articleId = backStackEntry.arguments?.getString("articleId") ?: return@composable
                ArticleDetailScreen(
                    articleId = articleId,
                    onBackClick = { navController.popBackStack() },
                    onStartLearning = { id ->
                        navController.navigate("learning/$id")
                    }
                )
            }
            
            composable("learning/{articleId}") { backStackEntry ->
                val articleId = backStackEntry.arguments?.getString("articleId")
                LearningScreen(
                    onBackClick = { navController.popBackStack() },
                    onComplete = { navController.popBackStack() }
                )
            }
            
            composable("review") {
                LearningScreen(
                    onBackClick = { navController.popBackStack() },
                    onComplete = { navController.popBackStack() }
                )
            }
            
            composable(BottomNavItem.Add.route) {
                AddWordScreen()
            }
            
            composable(BottomNavItem.Profile.route) {
                ProfileScreen(
                    onNavigateToStatistics = {
                        navController.navigate("statistics")
                    },
                    onNavigateToSettings = {
                        navController.navigate("settings")
                    }
                )
            }
            
            composable("statistics") {
                StatisticsScreen(
                    onBackClick = { navController.popBackStack() }
                )
            }
            
            composable("settings") {
                // SettingsScreen
                Text("设置页面")
            }
        }
    }
}

sealed class BottomNavItem(
    val route: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
    val label: String
) {
    object Home : BottomNavItem("home", Icons.Default.Home, "首页")
    object Articles : BottomNavItem("articles", Icons.Default.Book, "短文")
    object Add : BottomNavItem("add", Icons.Default.Add, "添加")
    object Profile : BottomNavItem("profile", Icons.Default.Person, "我的")
}
