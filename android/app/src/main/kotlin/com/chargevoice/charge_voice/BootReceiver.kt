package com.chargevoice.charge_voice

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED && intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) return
        val store = ChargeStore(context)
        if (!store.enabled) return
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) store.resetSession()
        try { ChargingService.start(context) }
        catch (_: RuntimeException) { store.error("Android paused background monitoring. Open Charge Voice to resume.") }
    }
}
