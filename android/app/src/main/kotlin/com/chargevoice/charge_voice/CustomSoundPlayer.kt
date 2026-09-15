package com.chargevoice.charge_voice

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import java.io.File

class CustomSoundPlayer(context: Context) {
    private val app = context.applicationContext
    private val store = ChargeStore(app)
    private val handler = Handler(Looper.getMainLooper())
    private val audio = app.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private var player: MediaPlayer? = null
    private val prepareWake = (app.getSystemService(Context.POWER_SERVICE) as PowerManager)
        .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "charge_voice:audio_prepare").apply { setReferenceCounted(false) }
    private var focus: AudioFocusRequest? = null
    private val attributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build()
    private val focusListener = AudioManager.OnAudioFocusChangeListener { if (it < 0) handler.post { stop() } }
    private val timeout = Runnable { stop() }
    private var prepareTimeout: Runnable? = null
    val isBusy get() = player != null

    @Suppress("DEPRECATION")
    fun play(slot: String, onFailure: () -> Unit): Boolean {
        val name = store.prefs.getString("soundFile_$slot", null) ?: return false
        val file = File(app.filesDir, name)
        if (!file.isFile) { store.error("Custom sound is missing. Choose the file again."); return false }
        stop()
        try {
            val granted = if (Build.VERSION.SDK_INT >= 26) {
                val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK).setAudioAttributes(attributes).setOnAudioFocusChangeListener(focusListener).build()
                focus = request; audio.requestAudioFocus(request)
            } else audio.requestAudioFocus(focusListener, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
            if (granted != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) { stop(); return false }
            val mp = MediaPlayer(); player = mp
            prepareWake.acquire(15_000L)
            mp.setAudioAttributes(attributes)
            mp.setWakeMode(app, PowerManager.PARTIAL_WAKE_LOCK)
            val volume = store.prefs.getFloat("volume", 1f)
            mp.setVolume(volume, volume)
            mp.setDataSource(file.absolutePath)
            val fail = {
                stop(); store.error("This audio file could not play. Choose another sound. Using voice instead."); onFailure()
            }
            prepareTimeout = Runnable { if (player === mp) fail() }.also { handler.postDelayed(it, 10_000L) }
            mp.setOnPreparedListener {
                if (player === mp) {
                    prepareTimeout?.let { handler.removeCallbacks(it) }; prepareTimeout = null
                    try {
                        mp.start()
                        if (prepareWake.isHeld) prepareWake.release()
                        val seconds = PlaybackOptions.duration(store.prefs.getInt("soundSeconds_$slot", 5))
                        handler.postDelayed(timeout, seconds * 1000L)
                        if (audio.getStreamVolume(AudioManager.STREAM_MUSIC) == 0) store.error("Your media volume is muted.") else store.error("")
                        store.log("Custom sound: ${if (slot == "connect") "charger connected" else "$slot%"} (up to $seconds seconds)")
                    } catch (_: RuntimeException) { fail() }
                }
            }
            mp.setOnCompletionListener { if (player === mp) stop() }
            mp.setOnErrorListener { _, _, _ -> if (player === mp) fail(); true }
            mp.prepareAsync()
            return true
        } catch (_: Exception) { stop(); store.error("Sound could not play. Using voice instead."); return false }
    }
    @Suppress("DEPRECATION")
    fun stop() {
        handler.removeCallbacks(timeout)
        prepareTimeout?.let { handler.removeCallbacks(it) }; prepareTimeout = null
        player?.release(); player = null
        if (prepareWake.isHeld) prepareWake.release()
        if (Build.VERSION.SDK_INT >= 26) focus?.let { audio.abandonAudioFocusRequest(it) }
        else audio.abandonAudioFocus(focusListener)
        focus = null
    }
}
