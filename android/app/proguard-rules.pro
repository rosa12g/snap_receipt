# Keep all ML Kit classes (text recognition, barcode, etc.)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep Play Services vision dependencies (sometimes used internally)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep Firebase ML model loaders (used dynamically)
-keep class com.google.firebase.ml.** { *; }
-dontwarn com.google.firebase.ml.**

# Keep annotations
-keepattributes *Annotation*

# Flutter-related keeps
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
