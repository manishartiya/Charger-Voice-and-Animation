package com.chargevoice.charge_voice

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import java.io.File
import java.util.UUID

object SoundLibrary {
    val slots = listOf("connect") + (10..100 step 10).map { it.toString() }
    fun snapshot(context: Context): Map<String, Any> {
        val prefs = ChargeStore(context).prefs
        return slots.associateWith { slot -> mapOf(
            "name" to prefs.getString("soundName_$slot", "Built-in voice"),
            "custom" to prefs.contains("soundFile_$slot"),
            "seconds" to PlaybackOptions.duration(prefs.getInt("soundSeconds_$slot", 5))
        ) }
    }
    fun import(context: Context, uri: Uri, slot: String) {
        require(PlaybackOptions.validSlot(slot))
        val prefs = ChargeStore(context).prefs
        var displayName = "Custom audio"
        context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) displayName = it.getString(0) ?: displayName
        }
        val target = File(context.filesDir, "charge_sound_${UUID.randomUUID()}")
        try {
            val input = context.contentResolver.openInputStream(uri) ?: error("Cannot read this audio file.")
            input.use { source -> target.outputStream().use { output ->
                val buffer = ByteArray(8192); var total = 0L
                while (true) {
                    val count = source.read(buffer); if (count < 0) break
                    total += count; require(total <= 20 * 1024 * 1024) { "Choose an audio file smaller than 20 MB." }
                    output.write(buffer, 0, count)
                }
                require(total > 0) { "This audio file is empty." }
            } }
            val old = prefs.getString("soundFile_$slot", null)
            check(prefs.edit().putString("soundFile_$slot", target.name).putString("soundName_$slot", displayName).commit())
            old?.let { File(context.filesDir, it).delete() }
        } catch (e: Exception) { target.delete(); throw e }
    }
    fun remove(context: Context, slot: String) {
        require(PlaybackOptions.validSlot(slot))
        val prefs = ChargeStore(context).prefs
        val old = prefs.getString("soundFile_$slot", null)
        prefs.edit().remove("soundFile_$slot").remove("soundName_$slot").apply()
        old?.let { File(context.filesDir, it).delete() }
    }
}
