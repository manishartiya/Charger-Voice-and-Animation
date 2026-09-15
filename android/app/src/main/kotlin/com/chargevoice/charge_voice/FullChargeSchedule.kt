package com.chargevoice.charge_voice

/** Monotonic deadlines are preserved across duplicate battery broadcasts. */
class FullChargeSchedule {
    companion object { const val INTERVAL_MS = 10_000L }
    var nextAt: Long? = null
        private set
    fun update(eligible: Boolean, now: Long) {
        if (!eligible) nextAt = null
        else if (nextAt == null) nextAt = now + INTERVAL_MS
    }
    fun takeDue(now: Long): Boolean {
        val deadline = nextAt ?: return false
        if (now < deadline) return false
        // Never replay a burst of overdue reminders after a delayed callback.
        nextAt = now + INTERVAL_MS
        return true
    }
}
