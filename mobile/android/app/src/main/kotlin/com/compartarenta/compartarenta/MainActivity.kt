package com.compartarenta.compartarenta

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.OutputStream

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.compartarenta/public_documents"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "writeTextFile" -> {
                        val subDir = call.argument<String>("subDir") ?: "Compartarenta"
                        val fileName = call.argument<String>("fileName")
                        val content = call.argument<String>("content")
                        if (fileName.isNullOrBlank() || content == null) {
                            result.error(
                                "invalid_args",
                                "fileName and content are required",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        try {
                            val relativePath =
                                writeTextFileToDocuments(subDir, fileName, content)
                            result.success(relativePath)
                        } catch (e: Exception) {
                            result.error("write_failed", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun writeTextFileToDocuments(
        subDir: String,
        fileName: String,
        content: String,
    ): String {
        val relativeFolder = "${Environment.DIRECTORY_DOCUMENTS}/$subDir"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/json")
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativeFolder)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val collection =
                MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val uri =
                resolver.insert(collection, values)
                    ?: throw IllegalStateException("MediaStore insert failed")
            resolver.openOutputStream(uri)?.use { stream: OutputStream ->
                stream.write(content.toByteArray(Charsets.UTF_8))
            } ?: throw IllegalStateException("openOutputStream failed")
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return "$relativeFolder/$fileName"
        }

        @Suppress("DEPRECATION")
        val docsDir =
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
        val dir = File(docsDir, subDir)
        if (!dir.exists() && !dir.mkdirs()) {
            throw IllegalStateException("mkdirs failed for ${dir.absolutePath}")
        }
        val file = File(dir, fileName)
        file.writeText(content, Charsets.UTF_8)
        return "$relativeFolder/$fileName"
    }
}
