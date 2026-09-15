package com.chargevoice.charge_voice

/** A coarse observed trend; never attributes whole-phone drain to individual apps. */
class BatteryTrend(var startLevel: Int = -1, var startAt: Long = 0, var lastLevel: Int = -1,
                   var lastAt: Long = 0, var plugged: Boolean = false) {
    fun observe(level: Int, charging: Boolean, now: Long) {
        if (level !in 0..100) return
        val reversed = if (charging) level < lastLevel else level > lastLevel
        if (startLevel < 0 || plugged != charging || now < lastAt || now - startAt > 7_200_000L || reversed) {
            startLevel = level; startAt = now; lastLevel = level; lastAt = now; plugged = charging
        } else if (level != lastLevel) { lastLevel = level; lastAt = now }
    }
    fun remaining(now: Long): Long? {
        if (lastLevel !in 0..100 || now < lastAt) return null
        if (plugged && lastLevel == 100 || !plugged && lastLevel == 0) return 0
        val changed = if (plugged) lastLevel - startLevel else startLevel - lastLevel
        val elapsed = lastAt - startAt
        if (changed < 2 || elapsed < 120_000 || now - lastAt > 1_800_000) return null
        val left = if (plugged) 100 - lastLevel else lastLevel
        return (elapsed.toDouble() / changed * left).toLong().takeIf { it in 1..604_800_000L }
    }
}
