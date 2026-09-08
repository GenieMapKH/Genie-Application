# ML Kit
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.common.** { *; }
-keep class com.google.android.datatransport.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Google Sign-In / Credential Manager
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.signin.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class androidx.credentials.** { *; }

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.firebase.** { *; }

# Keep Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**