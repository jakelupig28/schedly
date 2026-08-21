package com.schedly.schedly

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.schedly.app/native"
    private val NOTIFICATION_CHANNEL_ID = "schedly_downloads"
    private val NOTIFICATION_ID = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "renderPdfToImages" -> {
                    val pdfPath = call.argument<String>("pdfPath")
                    if (pdfPath != null) {
                        java.util.concurrent.Executors.newSingleThreadExecutor().execute {
                            val file = File(pdfPath)
                            if (file.exists()) {
                                val imagePaths = mutableListOf<String>()
                                try {
                                    val fileDescriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                                    val pdfRenderer = PdfRenderer(fileDescriptor)
                                    val pageCount = pdfRenderer.pageCount
                                    val outputDir = File(cacheDir, "pdf_renders").apply { mkdirs() }

                                    for (i in 0 until minOf(pageCount, 2)) {
                                        val page = pdfRenderer.openPage(i)
                                        val maxDim = maxOf(page.width, page.height)
                                        val scale = if (maxDim > 0) (2200f / maxDim).coerceIn(1.8f, 3.0f) else 2.2f
                                        val width = (page.width * scale).toInt()
                                        val height = (page.height * scale).toInt()
                                        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                                        bitmap.eraseColor(android.graphics.Color.WHITE)
                                        page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_PRINT)
                                        page.close()

                                        val outputFile = File(outputDir, "pdf_page_${System.currentTimeMillis()}_$i.jpg")
                                        val out = FileOutputStream(outputFile)
                                        bitmap.compress(Bitmap.CompressFormat.JPEG, 95, out)
                                        out.flush()
                                        out.close()
                                        bitmap.recycle()
                                        imagePaths.add(outputFile.absolutePath)
                                    }
                                    pdfRenderer.close()
                                    fileDescriptor.close()
                                    runOnUiThread { result.success(imagePaths) }
                                } catch (e: Exception) {
                                    runOnUiThread { result.error("PDF_ERROR", e.message, null) }
                                }
                            } else {
                                runOnUiThread { result.error("FILE_NOT_FOUND", "PDF file does not exist", null) }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGS", "pdfPath is required", null)
                    }
                }
                "showDownloadingNotification" -> {
                    val title = call.argument<String>("title") ?: "Downloading Schedule..."
                    val message = call.argument<String>("message") ?: "Rendering high-resolution poster for your gallery."
                    showDownloadingNotification(title, message)
                    result.success(true)
                }
                "scanMediaFile" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        try {
                            android.media.MediaScannerConnection.scanFile(
                                this,
                                arrayOf(filePath),
                                arrayOf("image/png")
                            ) { _, _ -> }

                            val mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                            val fileUri = android.net.Uri.fromFile(java.io.File(filePath))
                            mediaScanIntent.data = fileUri
                            sendBroadcast(mediaScanIntent)
                        } catch (_: Exception) {}
                    }
                    result.success(true)
                }
                "showDownloadFinishedNotification" -> {
                    val title = call.argument<String>("title") ?: "Download Complete"
                    val message = call.argument<String>("message") ?: "Schedule wallpaper saved to your Gallery."
                    showDownloadFinishedNotification(title, message)
                    result.success(true)
                }
                "updateWidgetData" -> {
                    val dataJson = call.argument<String>("data")
                    if (dataJson != null) {
                        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                        prefs.edit().putString("flutter.schedly_widget_data", dataJson).apply()
                    }

                    // Update all widgets
                    val widgetManager = AppWidgetManager.getInstance(this)
                    val widgetIds = widgetManager.getAppWidgetIds(
                        ComponentName(this, ScheduleAppWidgetProvider::class.java)
                    )
                    for (id in widgetIds) {
                        ScheduleAppWidgetProvider.updateAppWidget(this, widgetManager, id)
                    }
                    result.success(true)
                }
                "requestAppPermissions" -> {
                    val permissionsToRequest = mutableListOf<String>()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        permissionsToRequest.add(android.Manifest.permission.POST_NOTIFICATIONS)
                        permissionsToRequest.add(android.Manifest.permission.READ_MEDIA_IMAGES)
                    } else {
                        permissionsToRequest.add(android.Manifest.permission.READ_EXTERNAL_STORAGE)
                        permissionsToRequest.add(android.Manifest.permission.WRITE_EXTERNAL_STORAGE)
                    }
                    permissionsToRequest.add(android.Manifest.permission.CAMERA)

                    val notGranted = permissionsToRequest.filter {
                        androidx.core.content.ContextCompat.checkSelfPermission(this, it) != android.content.pm.PackageManager.PERMISSION_GRANTED
                    }

                    if (notGranted.isNotEmpty()) {
                        androidx.core.app.ActivityCompat.requestPermissions(
                            this,
                            notGranted.toTypedArray(),
                            1002
                        )
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Schedly Downloads"
            val descriptionText = "Notifications for schedule download progress and updates"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showDownloadingNotification(title: String, message: String) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setProgress(0, 0, true) // Indeterminate progress bar
            .setContentIntent(pendingIntent)

        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    private fun showDownloadFinishedNotification(title: String, message: String) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setProgress(0, 0, false)
            .setContentIntent(pendingIntent)

        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }
}
