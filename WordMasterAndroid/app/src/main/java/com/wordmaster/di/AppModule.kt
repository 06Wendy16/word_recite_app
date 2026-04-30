package com.wordmaster.di

import android.content.Context
import com.wordmaster.data.local.AppDatabase
import com.wordmaster.data.local.ArticleDao
import com.wordmaster.data.local.ReviewRecordDao
import com.wordmaster.data.local.WordDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {
    
    @Provides
    @Singleton
    fun provideAppDatabase(@ApplicationContext context: Context): AppDatabase {
        return AppDatabase.getDatabase(context)
    }
    
    @Provides
    @Singleton
    fun provideWordDao(database: AppDatabase): WordDao {
        return database.wordDao()
    }
    
    @Provides
    @Singleton
    fun provideArticleDao(database: AppDatabase): ArticleDao {
        return database.articleDao()
    }
    
    @Provides
    @Singleton
    fun provideReviewRecordDao(database: AppDatabase): ReviewRecordDao {
        return database.reviewRecordDao()
    }
}
