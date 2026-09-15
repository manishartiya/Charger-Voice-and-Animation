package com.chargevoice.charge_voice

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings

class ChargingService : Service() {
    companion object {
        const val STOP = "com.chargevoice.charge_voice.STOP"
        const val SETTINGS_CHANGED = "com.chargevoice.charge_voice.SETTINGS_CHANGED"
        @Volatile var running = false
        fun start(context: Context) {
            val intent = Intent(context, ChargingService::class.java)
            if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(intent) else context.startService(intent)
        }
    }
    private lateinit var store: ChargeStore
    private lateinit var speaker: VoiceSpeaker
    private lateinit var policy: ChargePolicy
    private var registered = false
    private val handler = Handler(Looper.getMainLooper())
    private val animationGate = AnimationLaunchGate()
    private lateinit var launchWake: PowerManager.WakeLock
    private var launchCheck: Runnable? = null
    private val fullCharge = FullChargeSchedule()
    private lateinit var reminderWake: PowerManager.WakeLock
    private val reminder: Runnable = Runnable {
        val battery = BatteryState.read(this)
        val now = SystemClock.elapsedRealtime()
        fullCharge.update(reminderEligible(battery), now)
        if (fullCharge.takeDue(now) && (!speaker.isBusy || speaker.isCustomPlaying)) speaker.speak("100 percent charge done. Please unplug your charger.")
        refreshReminder(battery)
    }
    private fun reminderEligible(battery: BatteryState) = store.enabled && battery.plugged && battery.level == 100 && store.prefs.getBoolean("repeatFull", true)
    private fun refreshReminder(battery: BatteryState) {
        val now = SystemClock.elapsedRealtime()
        if (fullCharge.nextAt != null && !reminderEligible(battery)) speaker.stop()
        fullCharge.update(reminderEligible(battery), now)
        handler.removeCallbacks(reminder)
        val deadline = fullCharge.nextAt
        if (deadline == null) {
            if (reminderWake.isHeld) reminderWake.release()
        } else {
            // Handler timers pause in deep sleep. Keep CPU awake only during the
            // user-enabled full-charge reminder, while external power is present.
            // Renew a bounded lease each tick so a stuck callback cannot leak it.
            reminderWake.acquire(30_000L)
            handler.postDelayed(reminder, (deadline - now).coerceAtLeast(1L))
        }
    }
    private fun showAnimation() {
        if (!store.prefs.getBoolean("autoAnimation", true)) return
        if (!MainActivity.visible && !Settings.canDrawOverlays(this)) {
            store.prefs.edit().putString("animationError", "Animation could not open: allow Display over other apps in Effects. Xiaomi phones also need Show on Lock screen and Display pop-up windows while running in the background.")
                .putString("animationStatus", "Permission needed").apply()
            return
        }
        try {
            launchCheck?.let { handler.removeCallbacks(it) }
            launchWake.acquire(12_000L)
            val requestId = SystemClock.elapsedRealtime().toString()
            store.prefs.edit().putString("animationRequest", requestId)
                .putString("animationStatus", "Waiting for charging screen").apply()
            startActivity(Intent(this, ChargingAnimationActivity::class.java)
                .putExtra("requestId", requestId)
                .putExtra("style", store.prefs.getString("animationStyle", "neon"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP))
            // Android/OEMs can reject startActivity without throwing. Success is
            // acknowledged only after a focused activity renders its Flutter UI.
            launchCheck = Runnable {
                if (store.prefs.getString("animationShown", "") != requestId) {
                    store.prefs.edit().putString("animationStatus", "Phone blocked charging screen")
                        .putString("animationError", "The phone did not show the charging screen. Open Phone permissions and allow Show on Lock screen and Display pop-up windows while running in the background. Also allow Display over other apps.").apply()
                }
                if (launchWake.isHeld) launchWake.release()
            }.also { handler.postDelayed(it, 10_000L) }
        } catch (_: RuntimeException) {
            store.prefs.edit().putString("animationError", "Android blocked the charging screen. Check display-over-apps and lock-screen permissions.").apply()
        }
    }
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (!store.enabled) return
            if (intent.action == SETTINGS_CHANGED) {
                val battery = BatteryState.read(context)
                if (!reminderEligible(battery) && battery.level == 100) speaker.stop()
                refreshReminder(battery)
                (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify(11, notification(battery))
                return
            }
            if (intent.action == Intent.ACTION_POWER_DISCONNECTED) {
                animationGate.update(false)
                policy.update(0, false, false); store.savePolicy(policy); speaker.stop()
                refreshReminder(BatteryState(0, false, "On battery", null))
                return
            }
            val observed = if (intent.action == Intent.ACTION_BATTERY_CHANGED) BatteryState.from(intent) else BatteryState.read(context)
            // POWER_CONNECTED is authoritative even if the sticky level update
            // has not yet caught up with the cable event.
            val battery = if (intent.action == Intent.ACTION_POWER_CONNECTED) observed.copy(plugged = true) else observed
            EnergyStats.snapshot(context, battery)
            val newConnection = animationGate.update(battery.plugged)
            val text = policy.update(battery.level, battery.plugged, store.prefs.getBoolean("announceConnect", true))
            store.savePolicy(policy)
            if (!battery.plugged) speaker.stop()
            if (text != null) speaker.speak(text)
            refreshReminder(battery)
            if (newConnection) showAnimation()
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify(11, notification(battery))
        }
    }
    override fun onCreate() {
        super.onCreate()
        store = ChargeStore(this)
        speaker = VoiceSpeaker(this)
        launchWake = (getSystemService(POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "charge_voice:animation_start").apply { setReferenceCounted(false) }
        reminderWake = (getSystemService(POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "charge_voice:full_reminder").apply { setReferenceCounted(false) }
        policy = ChargePolicy(store.prefs.getBoolean("connected", false), store.prefs.getInt("highest", -1))
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel("monitor", "Charging voice monitor", NotificationManager.IMPORTANCE_LOW).apply {
            description = "Background charging monitor. Can be hidden in notification settings."; setSound(null, null); lockscreenVisibility = Notification.VISIBILITY_SECRET
        })
        if (Build.VERSION.SDK_INT >= 34) startForeground(11, notification(BatteryState.read(this)), ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        else startForeground(11, notification(BatteryState.read(this)))
        running = true
        // Prepare after foreground registration, before the next physical plug-in.
        handler.post {
            if (store.enabled && store.prefs.getBoolean("autoAnimation", true)) {
                ChargingWarmEngine.prepare(this)
                ChargingWarmEngine.prepareImage(this, AnimationStyles.valid(store.prefs.getString("animationStyle", "neon")))
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_BATTERY_CHANGED); addAction(Intent.ACTION_POWER_CONNECTED); addAction(Intent.ACTION_POWER_DISCONNECTED)
            addAction(SETTINGS_CHANGED)
        }
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        else registerReceiver(receiver, filter)
        registered = true
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == STOP || !store.enabled) {
            store.enabled = false; store.resetSession(); stopSelf(); return START_NOT_STICKY
        }
        return START_STICKY
    }
    @Suppress("DEPRECATION")
    private fun notification(battery: BatteryState): Notification {
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val stop = PendingIntent.getService(this, 1, Intent(this, ChargingService::class.java).setAction(STOP), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, "monitor") else Notification.Builder(this)
        val text = when {
            reminderEligible(battery) -> "Fully charged · Voice reminder every 10 seconds"
            battery.plugged -> "Battery ${battery.level}% · Announcing every 10%"
            else -> "Ready for your next charge · Screen-off voice enabled"
        }
        return builder.setContentTitle("Charge Voice is listening").setContentText(text).setSmallIcon(R.drawable.ic_charge_notification)
            .setColor(0xFFB8A4FF.toInt()).setContentIntent(open).setOngoing(true).setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_SERVICE).setVisibility(Notification.VISIBILITY_SECRET)
            .addAction(Notification.Action.Builder(null, "Turn off", stop).build()).build()
    }
    override fun onDestroy() {
        running = false
        handler.removeCallbacks(reminder)
        launchCheck?.let { handler.removeCallbacks(it) }
        if (launchWake.isHeld) launchWake.release()
        if (reminderWake.isHeld) reminderWake.release()
        if (registered) unregisterReceiver(receiver)
        speaker.close()
        ChargingWarmEngine.release()
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
    override fun onBind(intent: Intent?): IBinder? = null
}
