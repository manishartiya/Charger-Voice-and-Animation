package com.chargevoice.charge_voice

object PlaybackOptions {
    val durations = setOf(5, 10, 15, 20)
    fun duration(value: Int) = if (value in durations) value else 20
    fun validSlot(slot: String) = slot == "connect" || slot.toIntOrNull()?.let { it in 10..100 && it % 10 == 0 } == true
    fun slot(text: String): String? = if (text.startsWith("Charger connected")) "connect"
        else Regex("^(\\d+) percent charge done").find(text)?.groupValues?.get(1)?.takeIf { validSlot(it) }
}
