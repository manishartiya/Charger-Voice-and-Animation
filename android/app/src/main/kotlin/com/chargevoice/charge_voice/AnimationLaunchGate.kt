package com.chargevoice.charge_voice

/** Animation connections are independent of persisted speech milestones. */
class AnimationLaunchGate {
    private var connected = false
    fun update(plugged: Boolean): Boolean {
        val shouldLaunch = plugged && !connected
        connected = plugged
        return shouldLaunch
    }
}
