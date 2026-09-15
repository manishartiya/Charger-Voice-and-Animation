package com.chargevoice.charge_voice

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import org.json.JSONArray
import org.json.JSONObject

class ChargeStore(context: Context) {
    val prefs = context.getSharedPreferences("charge_voice", Context.MODE_PRIVATE)
    var enabled: Boolean
        get() = prefs.getBoolean("enabled", false)
        set(value) { prefs.edit().putBoolean("enabled", value).apply() }
    fun error(message: String) { prefs.edit().putString("voiceError", message).apply() }
    fun history(): List<Map<String, Any>> {
        val array = runCatching { JSONArray(prefs.getString("history", "[]")) }.getOrDefault(JSONArray())
        return (0 until array.length()).map { i ->
            val item = array.getJSONObject(i)
            mapOf("text" to item.getString("text"), "time" to item.getLong("time"))
        }
    }
    fun log(text: String) {
        val array = JSONArray()
        array.put(JSONObject().put("text", text).put("time", System.currentTimeMillis()))
        history().take(49).forEach { array.put(JSONObject(it)) }
        prefs.edit().putString("history", array.toString()).apply()
    }
    fun savePolicy(policy: ChargePolicy) {
        prefs.edit().putBoolean("connected", policy.connected).putInt("highest", policy.highest).apply()
    }
    fun resetSession() { prefs.edit().remove("connected").remove("highest").apply() }
}

data class BatteryState(val level: Int, val plugged: Boolean, val source: String, val temperature: Double?) {
    companion object {
        fun read(context: Context) = from(context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED)))
        fun from(intent: Intent?): BatteryState {
            val raw = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
            val level = if (raw >= 0 && scale > 0) ((raw * 100L) / scale).toInt().coerceIn(0, 100) else -1
            val power = intent?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) ?: 0
            val source = when (power) {
                BatteryManager.BATTERY_PLUGGED_AC -> "Wall charger"
                BatteryManager.BATTERY_PLUGGED_USB -> "USB"
                BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Wireless"
                0 -> "On battery"
                else -> "Connected"
            }
            val temp = if (intent?.hasExtra(BatteryManager.EXTRA_TEMPERATURE) == true)
                intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) / 10.0 else null
            return BatteryState(level, power != 0, source, temp)
        }
    }
}
