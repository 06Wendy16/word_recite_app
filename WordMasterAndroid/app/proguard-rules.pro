# ProGuard rules for WordMaster

# Keep Room entities
-keep class com.wordmaster.data.entity.** { *; }

# Keep ViewModels
-keep class * extends androidx.lifecycle.ViewModel { *; }
