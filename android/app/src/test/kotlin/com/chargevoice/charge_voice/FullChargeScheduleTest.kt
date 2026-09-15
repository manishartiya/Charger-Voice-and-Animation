package com.chargevoice.charge_voice

import org.junit.Assert.*
import org.junit.Test

class FullChargeScheduleTest {
    @Test fun firstRepeatIsTenSecondsAfterFull() {
        val schedule = FullChargeSchedule()
        schedule.update(true, 1_000)
        assertEquals(11_000L, schedule.nextAt)
        assertFalse(schedule.takeDue(10_999))
        assertTrue(schedule.takeDue(11_000))
        assertEquals(21_000L, schedule.nextAt)
    }
    @Test fun repeatedBatteryBroadcastsDoNotPostponeReminder() {
        val schedule = FullChargeSchedule()
        schedule.update(true, 0)
        (1L..9L).forEach { schedule.update(true, it * 1000) }
        assertTrue(schedule.takeDue(10_000))
        assertFalse(schedule.takeDue(10_000))
    }
    @Test fun unplugOrDisabledOrBelowFullCancels() {
        val schedule = FullChargeSchedule()
        schedule.update(true, 0)
        schedule.update(false, 5_000)
        assertNull(schedule.nextAt)
        assertFalse(schedule.takeDue(10_000))
    }
    @Test fun reconnectStartsFreshTenSecondCountdown() {
        val schedule = FullChargeSchedule()
        schedule.update(true, 0)
        schedule.update(false, 5_000)
        schedule.update(true, 9_000)
        assertFalse(schedule.takeDue(10_000))
        assertTrue(schedule.takeDue(19_000))
    }
    @Test fun repeatsAtEachTenSecondDeadline() {
        val schedule = FullChargeSchedule()
        schedule.update(true, 0)
        (1L..100L).forEach {
            assertFalse(schedule.takeDue(it * 10_000 - 1))
            assertTrue(schedule.takeDue(it * 10_000))
        }
    }
    @Test fun delayedCallbacksDoNotCreateABurst() {
        val schedule = FullChargeSchedule()
        schedule.update(true, 0)
        assertTrue(schedule.takeDue(65_000))
        assertFalse(schedule.takeDue(65_001))
        assertEquals(75_000L, schedule.nextAt)
    }
    @Test fun inactiveScheduleNeverSpeaks() {
        val schedule = FullChargeSchedule()
        schedule.update(false, 0)
        assertFalse(schedule.takeDue(100_000))
    }
}
