package com.chargevoice.charge_voice

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.util.Locale
import java.util.UUID

/** Keeps CPU awake only while initializing/speaking, with a hard timeout. */
class VoiceSpeaker(context: Context) {
    private val app = context.applicationContext
    private val store = ChargeStore(app)
    private val handler = Handler(Looper.getMainLooper())
    private val audio = app.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val attributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
    private val wake = (app.getSystemService(Context.POWER_SERVICE) as PowerManager)
        .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "charge_voice:speech").apply { setReferenceCounted(false) }
    private val custom = CustomSoundPlayer(app)
    private var activeLanguage = ""
    private var tts: TextToSpeech? = null
    private var ready = false
    private var closed = false
    private val pending = ArrayDeque<String>()
    private val utterances = mutableMapOf<String, String>()
    val isCustomPlaying get() = custom.isBusy
    val isBusy: Boolean get() = custom.isBusy || pending.isNotEmpty() || utterances.isNotEmpty()
    private var focus: AudioFocusRequest? = null
    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        if (change == AudioManager.AUDIOFOCUS_LOSS || change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) {
            handler.post { stop(); store.error("Speech interrupted by another audio app. Try the voice preview again.") }
        }
    }
    private val timeout = Runnable {
        stop()
        store.error("Voice took too long to respond. Check installed selected language voice data in Voice settings.")
        tts?.shutdown(); tts = null; ready = false
    }

    fun speak(text: String, allowCustom: Boolean = true) {
        if (closed) return
        val slot = PlaybackOptions.slot(text)
        if (allowCustom && slot != null && store.prefs.contains("soundFile_$slot")) {
            stop()
            if (custom.play(slot) { speak(text, false) }) return
        }
        val language = store.prefs.getString("voiceLanguage", "en-US") ?: "en-US"
        if (activeLanguage != language) {
            stop(); tts?.shutdown(); tts = null; ready = false; activeLanguage = language
        }
        speakLocalized(SpeechText.translate(text, language))
    }

    private fun speakLocalized(text: String) {
        if (closed) return
        wake.acquire(30_000L)
        handler.removeCallbacks(timeout)
        handler.postDelayed(timeout, 30_000L)
        if (ready) { enqueue(text); return }
        pending.addLast(text)
        if (tts != null) return
        tts = TextToSpeech(app) { status -> handler.post { initialized(status) } }
    }

    private fun initialized(status: Int) {
        if (closed) return
        val engine = tts ?: return
        if (status != TextToSpeech.SUCCESS) { fail("No working text-to-speech engine. Install an Android speech engine and selected language voice data."); return }
        val result = engine.setLanguage(Locale.forLanguageTag(activeLanguage))
        if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
            fail("selected language voice data is missing. Open Voice → Install voice data, then test again."); return
        }
        // Prefer an installed offline voice, retaining the system voice when suitable.
        val voices = engine.voices.orEmpty().filter { it.locale.language == Locale.forLanguageTag(activeLanguage).language && !it.isNetworkConnectionRequired && !it.features.orEmpty().contains("notInstalled") }
        if (engine.voice?.isNetworkConnectionRequired != false) {
            (voices.firstOrNull { it.locale == Locale.forLanguageTag(activeLanguage) } ?: voices.firstOrNull())?.let { engine.voice = it }
        }
        engine.setAudioAttributes(attributes)
        engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(id: String?) {}
            override fun onDone(id: String?) { handler.post {
                utterances.remove(id)?.let { store.log(it) }
                releaseIfIdle()
            } }
            @Deprecated("Android compatibility")
            override fun onError(id: String?) { speechError(id) }
            override fun onError(id: String?, errorCode: Int) { speechError(id) }
        })
        ready = true
        store.error("")
        while (pending.isNotEmpty()) enqueue(pending.removeFirst())
    }

    private fun speechError(id: String?) { handler.post {
        utterances.remove(id)
        store.error("Speech could not play. Check media volume and installed voice data, then test again.")
        releaseIfIdle()
    } }

    @Suppress("DEPRECATION")
    private fun enqueue(text: String) {
        if (utterances.isEmpty()) {
            val granted = if (Build.VERSION.SDK_INT >= 26) {
                val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                    .setAudioAttributes(attributes).setOnAudioFocusChangeListener(focusListener).build()
                focus = request
                audio.requestAudioFocus(request)
            } else audio.requestAudioFocus(focusListener, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
            if (granted != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                store.error("Another app has audio focus. Try again after the call or audio session.")
                releaseIfIdle(); return
            }
        }
        if (audio.getStreamVolume(AudioManager.STREAM_MUSIC) == 0) {
            store.error("Your media volume is muted. Turn it up to hear announcements.")
        } else store.error("")
        tts?.setSpeechRate(store.prefs.getFloat("speechRate", .95f))
        val id = UUID.randomUUID().toString()
        val params = Bundle().apply { putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, store.prefs.getFloat("volume", 1f)) }
        utterances[id] = text
        if (tts?.speak(text, TextToSpeech.QUEUE_ADD, params, id) != TextToSpeech.SUCCESS) speechError(id)
    }

    private fun fail(message: String) {
        store.error(message); pending.clear(); ready = false
        tts?.shutdown(); tts = null
        releaseIfIdle()
    }
    @Suppress("DEPRECATION")
    private fun releaseIfIdle() {
        if (utterances.isNotEmpty() || pending.isNotEmpty()) return
        handler.removeCallbacks(timeout)
        if (wake.isHeld) wake.release()
        if (Build.VERSION.SDK_INT >= 26) focus?.let { audio.abandonAudioFocusRequest(it) }
        else audio.abandonAudioFocus(focusListener)
        focus = null
    }
    fun stop() { custom.stop(); tts?.stop(); pending.clear(); utterances.clear(); releaseIfIdle() }
    fun close() { closed = true; stop(); tts?.shutdown(); tts = null }
}
