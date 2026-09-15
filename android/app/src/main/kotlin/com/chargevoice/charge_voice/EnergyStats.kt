package com.chargevoice.charge_voice

import android.content.Context
import android.os.BatteryManager
import android.os.Build
import android.os.SystemClock

object EnergyStats {
    @Synchronized fun snapshot(context: Context, battery: BatteryState): Map<String, Any?> {
        val prefs = ChargeStore(context).prefs
        val now = SystemClock.elapsedRealtime()
        val boot = android.provider.Settings.Global.getInt(context.contentResolver, android.provider.Settings.Global.BOOT_COUNT, -1)
        val sameBoot = prefs.getInt("trendBoot", -2) == boot
        val trend = BatteryTrend(if (sameBoot) prefs.getInt("trendStartLevel", -1) else -1, prefs.getLong("trendStartAt", 0),
            prefs.getInt("trendLastLevel", -1), prefs.getLong("trendLastAt", 0), prefs.getBoolean("trendPlugged", false))
        val before = listOf(trend.startAt, trend.lastAt, trend.lastLevel.toLong())
        trend.observe(battery.level, battery.plugged, now)
        if (before != listOf(trend.startAt, trend.lastAt, trend.lastLevel.toLong())) {
            prefs.edit().putInt("trendBoot", boot).putInt("trendStartLevel", trend.startLevel).putLong("trendStartAt", trend.startAt)
                .putInt("trendLastLevel", trend.lastLevel).putLong("trendLastAt", trend.lastAt).putBoolean("trendPlugged", trend.plugged).apply()
        }
        val system = if (battery.plugged && Build.VERSION.SDK_INT >= 28) runCatching {
            (context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager).computeChargeTimeRemaining()
        }.getOrNull()?.takeIf { it > 0 } else null
        val remaining = if (battery.plugged && battery.level == 100) 0L else system ?: trend.remaining(now)
        return mapOf("remainingMs" to remaining,
            "estimateSource" to if (system != null) "Android estimate" else "Recent battery trend",
            "observedChange" to if (trend.startLevel < 0) 0 else kotlin.math.abs(trend.lastLevel - trend.startLevel),
            "observedMinutes" to if (trend.startLevel < 0) 0 else ((now - trend.startAt).coerceAtLeast(0) / 60000))
    }
}
