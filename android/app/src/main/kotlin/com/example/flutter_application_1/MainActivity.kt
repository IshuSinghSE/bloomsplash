package com.devindeed.bloomsplash

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.bloomsplash/media").setMethodCallHandler { call, result ->
            if (call.method == "saveImageToPictures") {
                val fileName = call.argument<String>("fileName") ?: "wallpaper.jpg"
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null) {
                    result.error("NO_BYTES", "No image bytes provided", null)
                    return@setMethodCallHandler
                }
                val savedPath = saveImageToPictures(applicationContext, fileName, bytes)
                if (savedPath != null) {
                    result.success(savedPath)
                } else {
                    result.error("SAVE_FAILED", "Failed to save image", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveImageToPictures(context: Context, fileName: String, bytes: ByteArray): String? {
        return try {
            val resolver = context.contentResolver
            val mimeType = "image/jpeg"
            val folderName = "BloomSplash"
            val relativePath = "Pictures/$folderName"
            val isApi29OrAbove = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

            if (isApi29OrAbove) {
                val contentValues = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                    put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                    put(MediaStore.Images.Media.RELATIVE_PATH, relativePath)
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }
                val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
                if (uri != null) {
                    resolver.openOutputStream(uri)?.use { it.write(bytes) }
                    contentValues.clear()
                    contentValues.put(MediaStore.Images.Media.IS_PENDING, 0)
                    resolver.update(uri, contentValues, null, null)
                    return uri.toString()
                }
            } else {
                // For Android 9 and below, save to Pictures/BloomSplash using legacy file APIs
                val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
                val bloomDir = java.io.File(picturesDir, folderName)
                if (!bloomDir.exists()) bloomDir.mkdirs()
                val file = java.io.File(bloomDir, fileName)
                file.outputStream().use { it.write(bytes) }
                // Notify MediaScanner
                context.sendBroadcast(
                    android.content.Intent(android.content.Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, android.net.Uri.fromFile(file))
                )
                return file.absolutePath
            }
            null
        } catch (e: Exception) {
            Log.e("BloomSplash", "Failed to save image: ", e)
            null
        }
    }
}
