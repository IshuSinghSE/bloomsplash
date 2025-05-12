# Keep annotations
-keepattributes *Annotation*

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

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
