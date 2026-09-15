package com.chargevoice.charge_voice

import org.junit.Assert.*
import org.junit.Test

class BatteryTrendTest {
    @Test fun learnsBeforeEstimating() {
        val t = BatteryTrend(); t.observe(80, false, 1000)
        assertNull(t.remaining(2000))
        t.observe(79, false, 181000); assertNull(t.remaining(181000))
        t.observe(78, false, 361000); assertEquals(14_040_000L, t.remaining(361000))
    }
    @Test fun chargingEstimatesOnlyRemainingCapacity() {
        val t = BatteryTrend(); t.observe(50, true, 1000); t.observe(52, true, 121000)
        assertEquals(2_880_000L, t.remaining(121000))
    }
    @Test fun directionAndPowerChangesResetLearning() {
        val t = BatteryTrend(); t.observe(50, false, 1000); t.observe(48, false, 121000)
        t.observe(49, false, 151000); assertNull(t.remaining(151000))
        t.observe(50, true, 181000); assertNull(t.remaining(181000))
    }
    @Test fun fastFakeReadingsDoNotProduceEstimate() {
        val t = BatteryTrend(); t.observe(70, false, 1000); t.observe(60, false, 1100)
        assertNull(t.remaining(1100))
    }
    @Test fun staleAndRebootReadingsReset() {
        val t = BatteryTrend(); t.observe(50, false, 1000); t.observe(48, false, 121000)
        assertNull(t.remaining(2_000_000))
        t.observe(47, false, 100); assertNull(t.remaining(100))
    }
    @Test fun endpointsAndInvalidReadings() {
        val t = BatteryTrend(); t.observe(-1, true, 1000); assertNull(t.remaining(1000))
        t.observe(100, true, 1000); assertEquals(0L, t.remaining(1000))
        t.observe(0, false, 2000); assertEquals(0L, t.remaining(2000))
    }
}
