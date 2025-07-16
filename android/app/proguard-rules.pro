# Keep Play Core SplitCompat and SplitInstall classes for deferred components
# Keep Flutter's PlayStoreSplitApplication and related classes
# Keep annotations

# Suppress R8 warnings for missing Play Core classes (auto-generated)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Keep javax.annotation.Nullable
-dontwarn javax.annotation.Nullable
-keep class javax.annotation.Nullable { *; }

# Keep Conscrypt classes
-dontwarn org.conscrypt.**
-keep class org.conscrypt.** { *; }

# Keep OkHttp classes
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class io.flutter.** { *; }

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
