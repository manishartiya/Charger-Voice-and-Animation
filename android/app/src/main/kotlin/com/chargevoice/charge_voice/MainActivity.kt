package com.chargevoice.charge_voice

import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

open class MainActivity : FlutterActivity() {
    companion object { @Volatile var visible = false }
    private lateinit var store: ChargeStore
    private var preview: VoiceSpeaker? = null
    private var soundResult: MethodChannel.Result? = null
    private var soundSlot = "connect"
    private var languageEngine: TextToSpeech? = null
    private var languageResult: MethodChannel.Result? = null
    private val languageHandler = android.os.Handler(android.os.Looper.getMainLooper())
    private val languageTimeout = Runnable { languageResult?.error("VOICE_TIMEOUT", "Speech engine did not respond. Check system voice settings.", null); languageResult = null; languageEngine?.shutdown(); languageEngine = null }
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        store = ChargeStore(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "charge_voice/control").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "snapshot" -> {
                        val battery = BatteryState.read(this)
                        result.success(mapOf(
                            "energy" to EnergyStats.snapshot(this, battery),
                            "showTimeEstimate" to store.prefs.getBoolean("showTimeEstimate", true),
                            "level" to battery.level, "plugged" to battery.plugged, "source" to battery.source,
                            "temperature" to battery.temperature, "enabled" to (store.enabled && ChargingService.running),
                            "notifications" to (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).areNotificationsEnabled(),
                            "batteryExempt" to (getSystemService(POWER_SERVICE) as PowerManager).isIgnoringBatteryOptimizations(packageName),
                            "announceConnect" to store.prefs.getBoolean("announceConnect", true),
                            "repeatFull" to store.prefs.getBoolean("repeatFull", true),
                            "autoAnimation" to store.prefs.getBoolean("autoAnimation", true),
                            "animationStyle" to store.prefs.getString("animationStyle", "neon"),
                            "overlayAllowed" to Settings.canDrawOverlays(this),
                            "animationError" to store.prefs.getString("animationError", ""),
                            "animationLatencyMs" to store.prefs.getLong("animationLatencyMs", -1),
                            "animationStatus" to store.prefs.getString("animationStatus", "Not tested yet"),
                            "manufacturer" to Build.MANUFACTURER,
                            "animationSeconds" to PlaybackOptions.duration(store.prefs.getInt("animationSeconds", 20)),
                            "portGlow" to store.prefs.getBoolean("portGlow", true),
                            "portStyle" to store.prefs.getString("portStyle", "streams"),
                            "portColor" to store.prefs.getString("portColor", "theme"),
                            "portSize" to store.prefs.getFloat("portSize", 1f).toDouble(),
                            "portIntensity" to store.prefs.getFloat("portIntensity", .7f).toDouble(),
                            "portSpeed" to store.prefs.getFloat("portSpeed", 1f).toDouble(),
                            "portOffset" to store.prefs.getFloat("portOffset", .5f).toDouble(),
                            "portPosition" to store.prefs.getString("portPosition", "bottom"),
                            "voiceLanguage" to store.prefs.getString("voiceLanguage", "en-US"),
                            "voiceLanguageName" to java.util.Locale.forLanguageTag(store.prefs.getString("voiceLanguage", "en-US")!!).displayName,
                            "sounds" to SoundLibrary.snapshot(this),
                            "speechRate" to store.prefs.getFloat("speechRate", .95f).toDouble(),
                            "volume" to store.prefs.getFloat("volume", 1f).toDouble(),
                            "voiceError" to store.prefs.getString("voiceError", ""), "history" to store.history()
                        ))
                    }
                    "setEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        if (enabled) {
                            store.enabled = true
                            try { ChargingService.start(this) } catch (e: RuntimeException) { store.enabled = false; throw e }
                        } else {
                            store.enabled = false; store.resetSession(); stopService(Intent(this, ChargingService::class.java))
                            sendBroadcast(Intent(ChargingService.SETTINGS_CHANGED).setPackage(packageName))
                        }
                        result.success(null)
                    }
                    "testVoice" -> {
                        if (preview == null) preview = VoiceSpeaker(this)
                        preview?.speak("50 percent charge done.", false)
                        result.success(null)
                    }
                    "settings" -> {
                        val edit = store.prefs.edit()
                        call.argument<Boolean>("showTimeEstimate")?.let { edit.putBoolean("showTimeEstimate", it) }
                        call.argument<Number>("animationSeconds")?.let { require(it.toInt() in PlaybackOptions.durations); edit.putInt("animationSeconds", it.toInt()) }
                        call.argument<Boolean>("portGlow")?.let { edit.putBoolean("portGlow", it) }
                        call.argument<String>("portStyle")?.let { require(it in setOf("streams", "ripple", "flame", "lightning", "bubbles", "wave")); edit.putString("portStyle", it) }
                        call.argument<String>("portColor")?.let { require(it in setOf("theme", "violet", "cyan", "pink", "gold", "mint", "rainbow")); edit.putString("portColor", it) }
                        call.argument<Number>("portSize")?.let { require(it.toFloat().isFinite()); edit.putFloat("portSize", it.toFloat().coerceIn(.7f, 1.4f)) }
                        call.argument<Number>("portIntensity")?.let { require(it.toFloat().isFinite()); edit.putFloat("portIntensity", it.toFloat().coerceIn(.4f, 1f)) }
                        call.argument<Number>("portSpeed")?.let { require(it.toFloat().isFinite()); edit.putFloat("portSpeed", it.toFloat().coerceIn(.5f, 1.5f)) }
                        call.argument<Number>("portOffset")?.let { require(it.toFloat().isFinite()); edit.putFloat("portOffset", it.toFloat().coerceIn(.15f, .85f)) }
                        call.argument<String>("portPosition")?.let { require(it in setOf("bottom", "top", "left", "right")); edit.putString("portPosition", it) }
                        call.argument<String>("voiceLanguage")?.let { require(java.util.Locale.forLanguageTag(it).language.isNotEmpty()); edit.putString("voiceLanguage", it) }
                        call.argument<Boolean>("announceConnect")?.let { edit.putBoolean("announceConnect", it) }
                        call.argument<Boolean>("repeatFull")?.let { edit.putBoolean("repeatFull", it) }
                        call.argument<Boolean>("autoAnimation")?.let { edit.putBoolean("autoAnimation", it) }
                        call.argument<String>("animationStyle")?.let {
                            require(it in AnimationStyles.names) { "Unknown charging animation." }
                            edit.putString("animationStyle", it)
                        }
                        call.argument<Number>("speechRate")?.let { edit.putFloat("speechRate", it.toFloat().coerceIn(.6f, 1.3f)) }
                        call.argument<Number>("volume")?.let { edit.putFloat("volume", it.toFloat().coerceIn(.2f, 1f)) }
                        edit.apply()
                        ChargingWarmEngine.prepareImage(this, AnimationStyles.valid(store.prefs.getString("animationStyle", "neon")))
                        sendBroadcast(Intent(ChargingService.SETTINGS_CHANGED).setPackage(packageName))
                        result.success(null)
                    }
                    "languages" -> {
                        check(languageResult == null) { "Language list is already loading." }
                        languageResult = result
                        languageHandler.postDelayed(languageTimeout, 12_000L)
                        languageEngine = TextToSpeech(this) { status -> runOnUiThread {
                            languageHandler.removeCallbacks(languageTimeout)
                            val reply = languageResult; languageResult = null
                            if (status == TextToSpeech.SUCCESS) {
                                val locales = languageEngine?.availableLanguages.orEmpty().sortedBy { it.displayName }
                                reply?.success(locales.map { mapOf("tag" to it.toLanguageTag(), "name" to "${it.displayName} / ${it.getDisplayName(it)}", "translated" to SpeechText.hasTemplate(it.toLanguageTag())) })
                            } else reply?.error("NO_VOICE", "Install a text-to-speech engine in system voice settings.", null)
                            languageEngine?.shutdown(); languageEngine = null
                        } }
                    }
                    "pickSound" -> {
                        check(soundResult == null) { "An audio picker is already open." }
                        val slot = call.argument<String>("slot") ?: "connect"
                        require(PlaybackOptions.validSlot(slot))
                        soundSlot = slot; soundResult = result
                        try { startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).setType("audio/*").addCategory(Intent.CATEGORY_OPENABLE), 52) }
                        catch (e: Exception) { soundResult = null; throw e }
                    }
                    "soundSettings" -> {
                        val slot = call.argument<String>("slot") ?: "connect"
                        require(PlaybackOptions.validSlot(slot))
                        val seconds = call.argument<Number>("seconds")?.toInt() ?: 5
                        require(seconds in PlaybackOptions.durations)
                        store.prefs.edit().putInt("soundSeconds_$slot", seconds).apply(); result.success(null)
                    }
                    "removeSound" -> { SoundLibrary.remove(this, call.argument<String>("slot") ?: "connect"); result.success(null) }
                    "testSound" -> {
                        val slot = call.argument<String>("slot") ?: "connect"; require(PlaybackOptions.validSlot(slot))
                        if (preview == null) preview = VoiceSpeaker(this)
                        preview?.speak(if (slot == "connect") "Charger connected. Battery is at ${BatteryState.read(this).level.coerceAtLeast(0)} percent." else "$slot percent charge done.")
                        result.success(null)
                    }
                    "stopPreview" -> { preview?.stop(); result.success(null) }
                    "previewAnimation" -> {
                        val style = call.argument<String>("style") ?: store.prefs.getString("animationStyle", "neon")
                        ChargingWarmEngine.prepareImage(this, AnimationStyles.valid(style))
                        startActivity(Intent(this, ChargingAnimationActivity::class.java).putExtra("style", style).putExtra("preview", true))
                        result.success(null)
                    }
                    "closeAnimation" -> { result.success(null); if (this is ChargingAnimationActivity) finish() }
                    "chargingHostReady" -> { if (this is ChargingAnimationActivity) sendSession(); result.success(null) }
                    "animationReady" -> { if (this is ChargingAnimationActivity) onAnimationFrameReady(call.argument<String>("requestId")); result.success(null) }
                    "phonePermissions" -> {
                        val intent = if (Build.MANUFACTURER.equals("xiaomi", true) || Build.MANUFACTURER.equals("redmi", true))
                            Intent("miui.intent.action.APP_PERM_EDITOR").setComponent(android.content.ComponentName("com.miui.securitycenter", "com.miui.permcenter.permissions.PermissionsEditorActivity"))
                                .putExtra("extra_pkgname", packageName)
                        else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                        try { startActivity(intent) }
                        catch (_: RuntimeException) { startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))) }
                        result.success(null)
                    }
                    "overlaySettings" -> {
                        openSettings(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
                        result.success(null)
                    }
                    "requestNotifications" -> {
                        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            if (permissionResult != null) result.error("BUSY", "Notification permission request is already open.", null)
                            else { permissionResult = result; requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 41) }
                        } else result.success(true)
                    }
                    "batteryUsage" -> { openSettings(Intent(Intent.ACTION_POWER_USAGE_SUMMARY)); result.success(null) }
                    "clearHistory" -> { store.prefs.edit().remove("history").apply(); result.success(null) }
                    "batterySettings" -> { openSettings(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))); result.success(null) }
                    "notificationSettings" -> {
                        val intent = if (Build.VERSION.SDK_INT >= 26) Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                        openSettings(intent); result.success(null)
                    }
                    "voiceSettings" -> { preview?.close(); preview = null; openSettings(Intent("com.android.settings.TTS_SETTINGS")); result.success(null) }
                    "installVoice" -> { preview?.close(); preview = null; openSettings(Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA)); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) { result.error("ANDROID_ERROR", e.localizedMessage ?: "Android could not complete the action.", null) }
        }
    }
    @Deprecated("Android result bridge")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 52) return
        val reply = soundResult ?: return
        val slot = soundSlot
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) { soundResult = null; reply.success(false); return }
        Thread {
            var failure: String? = null
            try { SoundLibrary.import(applicationContext, uri, slot) } catch (e: Exception) { failure = e.localizedMessage }
            runOnUiThread {
                if (soundResult === reply) {
                    soundResult = null
                    if (failure == null) reply.success(true) else reply.error("AUDIO_IMPORT", failure, null)
                }
            }
        }.start()
    }
    private fun openSettings(intent: Intent) {
        try { startActivity(intent) }
        catch (_: android.content.ActivityNotFoundException) { startActivity(Intent(Settings.ACTION_SETTINGS)) }
    }
    override fun onResume() {
        super.onResume()
        visible = true
        if (::store.isInitialized && store.enabled && !ChargingService.running) {
            try { ChargingService.start(this) }
            catch (_: RuntimeException) { store.error("Unable to resume monitoring. Turn Charging voice off and on again.") }
        }
    }
    override fun onPause() { preview?.stop(); visible = false; super.onPause() }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 41) { permissionResult?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED); permissionResult = null }
    }
    override fun onDestroy() { languageHandler.removeCallbacks(languageTimeout); languageEngine?.shutdown(); languageResult?.success(emptyList<Any>()); languageResult = null; soundResult?.success(false); soundResult = null; preview?.close(); permissionResult?.success(false); permissionResult = null; super.onDestroy() }
}
