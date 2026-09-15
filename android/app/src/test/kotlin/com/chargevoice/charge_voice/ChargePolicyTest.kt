package com.chargevoice.charge_voice

import org.junit.Assert.*
import org.junit.Test

class ChargePolicyTest {
    @Test fun announcesConnectionAtActualPercentage() {
        assertEquals("Charger connected. Battery is at 43 percent.", ChargePolicy().update(43, true, true))
    }
    @Test fun announcesAllTenMilestonesIncludingFull() {
        val policy = ChargePolicy()
        policy.update(3, true, true)
        val spoken = (4..100).mapNotNull { policy.update(it, true, true) }
        assertEquals(10, spoken.size)
        (1..9).forEach { assertEquals("${it * 10} percent charge done.", spoken[it - 1]) }
        assertEquals("100 percent charge done. Your battery is fully charged.", spoken.last())
    }
    @Test fun duplicateAndFluctuatingReadingsDoNotRepeat() {
        val policy = ChargePolicy()
        policy.update(49, true, true)
        assertEquals("50 percent charge done.", policy.update(50, true, true))
        assertNull(policy.update(50, true, true))
        assertNull(policy.update(49, true, true))
        assertNull(policy.update(50, true, true))
    }
    @Test fun reconnectStartsNewSession() {
        val policy = ChargePolicy()
        policy.update(49, true, true); policy.update(50, true, true)
        assertNull(policy.update(49, false, true))
        assertEquals("Charger connected. Battery is at 49 percent.", policy.update(49, true, true))
        assertEquals("50 percent charge done.", policy.update(50, true, true))
    }
    @Test fun skippedReadingsAnnounceLatestCrossedCheckpoint() {
        val policy = ChargePolicy()
        policy.update(48, true, true)
        assertEquals("50 percent charge done.", policy.update(51, true, true))
        assertEquals("80 percent charge done.", policy.update(83, true, true))
    }
    @Test fun restorationDoesNotRepeatCheckpoint() {
        val policy = ChargePolicy(true, 50)
        assertNull(policy.update(51, true, true))
        assertEquals("60 percent charge done.", policy.update(60, true, true))
    }
    @Test fun disabledConnectionSpeechStillTracksMilestones() {
        val policy = ChargePolicy()
        assertNull(policy.update(49, true, false))
        assertEquals("50 percent charge done.", policy.update(50, true, false))
    }
    @Test fun invalidReadingsAndDischargingAreSilent() {
        val policy = ChargePolicy()
        assertNull(policy.update(-1, true, true))
        assertNull(policy.update(101, true, true))
        assertFalse(policy.connected)
        (0..100).forEach { assertNull(policy.update(it, false, true)) }
    }
    @Test fun connectingAtCheckpointDoesNotDoubleSpeak() {
        val policy = ChargePolicy()
        assertEquals("Charger connected. Battery is at 100 percent.", policy.update(100, true, true))
        assertNull(policy.update(100, true, true))
    }
}
