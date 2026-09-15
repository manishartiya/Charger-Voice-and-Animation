package com.chargevoice.charge_voice

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

/** Retains one charging renderer while monitoring is enabled. No background polling. */
object ChargingWarmEngine {
    private var engine: FlutterEngine? = null
    var attached = false
    private var imageStyle = ""
    private var image: Bitmap? = null
    private val loader = java.util.concurrent.Executors.newSingleThreadExecutor()
    fun prepare(context: Context): FlutterEngine {
        engine?.let { return it }
        val prefs = ChargeStore(context).prefs
        val style = AnimationStyles.valid(prefs.getString("animationStyle", "neon"))
        val seconds = PlaybackOptions.duration(prefs.getInt("animationSeconds", 20))
        return FlutterEngine(context.applicationContext).also {
            engine = it
            it.navigationChannel.setInitialRoute("/charging?style=$style&seconds=$seconds")
            it.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        }
    }
    fun prepareImage(context: Context, style: String) {
        if (imageStyle == style) return
        imageStyle = style; image = null
        val app = context.applicationContext
        loader.execute {
            val decoded = runCatching { app.assets.open("flutter_assets/assets/characters/$style.png").use { BitmapFactory.decodeStream(it) } }.getOrNull()
            Handler(Looper.getMainLooper()).post { if (imageStyle == style) image = decoded }
        }
    }
    fun image(style: String): Bitmap? = if (imageStyle == style) image else null
    fun release() {
        if (attached) return
        engine?.destroy(); engine = null; image = null; imageStyle = ""
    }
}
