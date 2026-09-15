package com.chargevoice.charge_voice

/** Pure state machine: no timers, no repeated announcements from sticky broadcasts. */
class ChargePolicy(var connected: Boolean = false, var highest: Int = -1) {
    fun update(level: Int, plugged: Boolean, announceConnect: Boolean): String? {
        if (level !in 0..100) return null
        if (!plugged) {
            connected = false
            highest = -1
            return null
        }
        val checkpoint = (level / 10) * 10
        if (!connected) {
            connected = true
            highest = checkpoint
            return if (announceConnect) "Charger connected. Battery is at $level percent." else null
        }
        if (checkpoint >= 10 && checkpoint > highest) {
            highest = checkpoint
            return if (checkpoint == 100) "100 percent charge done. Your battery is fully charged." else "$checkpoint percent charge done."
        }
        return null
    }
}
