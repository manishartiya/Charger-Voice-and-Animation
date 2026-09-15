package com.chargevoice.charge_voice

import org.junit.Assert.*
import org.junit.Test

class AnimationLaunchGateTest {
    @Test fun firstPlugInLaunches() {
        val gate = AnimationLaunchGate()
        assertFalse(gate.update(false))
        assertTrue(gate.update(true))
    }
    @Test fun batteryAndPowerBroadcastsDoNotDoubleLaunch() {
        val gate = AnimationLaunchGate()
        assertTrue(gate.update(true))
        repeat(100) { assertFalse(gate.update(true)) }
    }
    @Test fun reconnectLaunchesAgain() {
        val gate = AnimationLaunchGate()
        gate.update(true)
        gate.update(false)
        assertTrue(gate.update(true))
    }
    @Test fun serviceRestartIsIndependentOfPersistedSpeechConnection() {
        val speech = ChargePolicy(true, 50)
        assertNull(speech.update(52, true, true))
        assertTrue(AnimationLaunchGate().update(true))
    }
    @Test fun allSeventeenStylesAreAcceptedAndUnknownFallsBack() {
        assertEquals(17, AnimationStyles.names.size)
        AnimationStyles.names.forEach { assertEquals(it, AnimationStyles.valid(it)) }
        assertEquals("neon", AnimationStyles.valid("missing"))
    }
}
