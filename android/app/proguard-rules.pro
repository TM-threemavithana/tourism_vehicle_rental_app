# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep flutter and dart classes
-keep class io.flutter.** { *; }
-keep class androidx.** { *; }

# Remove debug logs in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Remove ViewRootImpl touch hint logs
-assumenosideeffects class android.view.ViewRootImpl {
    *** setFrameRateCategory(...);
}

# Remove WindowOnBackDispatcher warnings
-dontwarn android.window.OnBackInvokedDispatcher
-dontwarn android.window.OnBackInvokedCallback

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep image picker and compression classes
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.example.flutter_image_compress.** { *; }
