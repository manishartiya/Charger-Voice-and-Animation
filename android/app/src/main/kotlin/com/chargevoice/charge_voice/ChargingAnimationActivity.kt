package com.chargevoice.charge_voice

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.WindowManager

/** A separate, dismissible Flutter screen; does not unlock or dismiss the keyguard. */
class ChargingAnimationActivity : MainActivity() {
    private val handler = Handler(Looper.getMainLooper())
    private val dismiss = Runnable { finish() }
    private var nativeFrameReady = false
    override fun onFlutterUiDisplayed() { super.onFlutterUiDisplayed(); nativeFrameReady = true; revealAnimation() }
    private fun revealAnimation() {
        if (!flutterFrameReady || !nativeFrameReady) return
        cover?.let { (it.parent as? android.view.ViewGroup)?.removeView(it) }; cover = null
    }
    private var cover: android.view.View? = null
    private val openedAt = android.os.SystemClock.elapsedRealtime()
    override fun provideFlutterEngine(context: Context): io.flutter.embedding.engine.FlutterEngine {
        ChargingWarmEngine.attached = true
        return ChargingWarmEngine.prepare(context)
    }
    override fun getRenderMode() = io.flutter.embedding.android.RenderMode.texture
    override fun shouldDestroyEngineWithHost() = false
    fun sendSession() {
        flutterEngine?.let { engine -> io.flutter.plugin.common.MethodChannel(engine.dartExecutor.binaryMessenger, "charge_voice/control").invokeMethod("showCharging", mapOf(
            "requestId" to (intent.getStringExtra("requestId") ?: "preview-$openedAt"),
            "style" to AnimationStyles.valid(intent.getStringExtra("style")), "preview" to preview,
            "seconds" to PlaybackOptions.duration(ChargeStore(this).prefs.getInt("animationSeconds", 20))
        )) }
    }
    private fun showImmediateCover() {
        val root = android.widget.FrameLayout(this)
        root.setBackgroundResource(R.drawable.charging_start)
        val style = AnimationStyles.valid(intent.getStringExtra("style"))
        ChargingWarmEngine.image(style)?.let { bitmap ->
            val artwork = android.widget.ImageView(this).apply {
                setImageBitmap(bitmap)
                scaleType = if (style in setOf("pikachu", "eevee")) android.widget.ImageView.ScaleType.FIT_CENTER else android.widget.ImageView.ScaleType.CENTER_CROP
            }
            root.addView(artwork, android.widget.FrameLayout.LayoutParams(-1, -1))
        }
        val label = android.widget.TextView(this).apply {
            text = "${BatteryState.read(this@ChargingAnimationActivity).level.coerceAtLeast(0)}%"
            textSize = 60f; setTextColor(android.graphics.Color.WHITE); gravity = android.view.Gravity.CENTER
            setShadowLayer(16f, 0f, 0f, android.graphics.Color.BLACK)
        }
        root.addView(label, android.widget.FrameLayout.LayoutParams(-1, -2, android.view.Gravity.BOTTOM).apply { bottomMargin = (resources.displayMetrics.heightPixels * (if (style == "eevee") .48 else .2)).toInt() })
        var startY = 0f
        root.setOnTouchListener { _, event ->
            if (event.action == android.view.MotionEvent.ACTION_DOWN) startY = event.y
            if (event.action == android.view.MotionEvent.ACTION_UP && startY > root.height * .55 && startY - event.y > 60 * resources.displayMetrics.density) finish()
            true
        }
        addContentView(root, android.view.ViewGroup.LayoutParams(-1, -1)); cover = root
    }
    override fun onResume() { super.onResume(); sendSession() }
    private var registered = false
    private var flutterFrameReady = false
    private val preview get() = intent.getBooleanExtra("preview", false)
    private val batteryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (!preview && (!BatteryState.read(context).plugged || !ChargeStore(context).enabled)) finish()
        }
    }
    override fun getInitialRoute(): String {
        val style = AnimationStyles.valid(intent.getStringExtra("style"))
        val seconds = PlaybackOptions.duration(ChargeStore(this).prefs.getInt("animationSeconds", 20))
        return "/charging?style=$style&preview=$preview&seconds=$seconds"
    }
    @Suppress("DEPRECATION")
    override fun onCreate(savedInstanceState: Bundle?) {
        // Set lock-screen window behavior before Flutter begins attaching a view.
        if (Build.VERSION.SDK_INT >= 27) { setShowWhenLocked(true); setTurnScreenOn(true) }
        else window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        super.onCreate(savedInstanceState)
        window.setBackgroundDrawableResource(R.drawable.charging_start)
        showImmediateCover()
        sendSession()
        if (Build.VERSION.SDK_INT >= 30) {
            window.insetsController?.hide(android.view.WindowInsets.Type.systemBars())
            window.insetsController?.systemBarsBehavior = android.view.WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        } else {
            window.decorView.systemUiVisibility = android.view.View.SYSTEM_UI_FLAG_FULLSCREEN or android.view.View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or android.view.View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        }
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED).apply {
            addAction(Intent.ACTION_POWER_DISCONNECTED); addAction(ChargingService.SETTINGS_CHANGED)
        }
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(batteryReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        else registerReceiver(batteryReceiver, filter)
        registered = true
        handler.postDelayed(dismiss, PlaybackOptions.duration(ChargeStore(this).prefs.getInt("animationSeconds", 20)) * 1000L)
    }
    fun onAnimationFrameReady(requestId: String?) {
        if (requestId != (intent.getStringExtra("requestId") ?: "preview-$openedAt")) return
        if (flutterFrameReady) return
        flutterFrameReady = true
        revealAnimation()
        val request = intent.getStringExtra("requestId")?.toLongOrNull() ?: openedAt
        val latency = android.os.SystemClock.elapsedRealtime() - request
        android.util.Log.i("ChargeAnimation", "Animated frame ready in $latency ms")
        ChargeStore(this).prefs.edit().putLong("animationLatencyMs", latency).apply()
        acknowledgeVisible()
    }
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) acknowledgeVisible()
    }
    private fun acknowledgeVisible() {
        if (!flutterFrameReady || !hasWindowFocus()) return
        val power = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        if (!power.isInteractive) return
        ChargeStore(this).prefs.edit()
            .putString("animationShown", intent.getStringExtra("requestId") ?: "preview")
            .putString("animationStatus", if (preview) "Preview displayed" else "Charging screen displayed")
            .remove("animationError").apply()
    }
    override fun onDestroy() {
        handler.removeCallbacks(dismiss)
        if (registered) unregisterReceiver(batteryReceiver)
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        flutterEngine?.let { io.flutter.plugin.common.MethodChannel(it.dartExecutor.binaryMessenger, "charge_voice/control").setMethodCallHandler(null) }
        super.onDestroy()
        ChargingWarmEngine.attached = false
        if (!ChargeStore(this).enabled) ChargingWarmEngine.release()
    }
}
