package com.wayzlk.wayz

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.util.Log

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Disable verbose logging in release builds
        try {
            // Set log level to ERROR or higher to reduce noise
            Log.isLoggable("VRI", Log.ERROR)
            Log.isLoggable("WindowOnBackDispatcher", Log.ERROR)
        } catch (e: Exception) {
            // Ignore if logging configuration fails
        }
    }
}
