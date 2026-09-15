package com.chargevoice.charge_voice

import org.junit.Assert.*
import org.junit.Test

class PlaybackOptionsTest {
    @Test fun acceptedDurationsAndInvalidFallback() {
        for (seconds in listOf(5, 10, 15, 20)) assertEquals(seconds, PlaybackOptions.duration(seconds))
        for (seconds in listOf(-1, 0, 6, 100)) assertEquals(20, PlaybackOptions.duration(seconds))
    }
    @Test fun soundEventsStayIndependent() {
        assertEquals("connect", PlaybackOptions.slot("Charger connected. Battery is at 50 percent."))
        assertEquals("50", PlaybackOptions.slot("50 percent charge done."))
        assertEquals("100", PlaybackOptions.slot("100 percent charge done. Please unplug your charger."))
        assertNull(PlaybackOptions.slot("Battery is at 51 percent."))
        assertFalse(PlaybackOptions.validSlot("../sound"))
        assertFalse(PlaybackOptions.validSlot("0"))
        assertFalse(PlaybackOptions.validSlot("55"))
        for (level in 10..100 step 10) assertTrue(PlaybackOptions.validSlot("$level"))
    }
    @Test fun japaneseTemplatesAreTranslated() {
        assertEquals("充電器が接続されました。バッテリーは43パーセントです。", SpeechText.translate("Charger connected. Battery is at 43 percent.", "ja-JP"))
        assertEquals("50パーセント充電されました。", SpeechText.translate("50 percent charge done.", "ja-JP"))
        assertTrue(SpeechText.translate("100 percent charge done.", "ja-JP").contains("充電器を外してください"))
    }
    @Test fun unsupportedTemplateSpeaksLocalizedPercentage() {
        assertFalse(SpeechText.hasTemplate("nl-NL"))
        assertTrue(SpeechText.translate("50 percent charge done.", "nl-NL").contains("50"))
        assertFalse(SpeechText.translate("50 percent charge done.", "nl-NL").contains("charge done"))
    }
    @Test fun eachTemplatePreservesMilestoneAndFullReminder() {
        for (tag in listOf("en", "ja", "hi", "es", "fr", "de", "ko", "zh", "pt", "it", "ru", "ar", "bn", "ta", "te", "mr", "tr", "id")) {
            assertTrue(SpeechText.hasTemplate(tag))
            val fifty = SpeechText.translate("50 percent charge done.", tag)
            val full = SpeechText.translate("100 percent charge done.", tag)
            assertNotEquals(fifty, full)
            assertTrue(full.length > fifty.length)
        }
    }
}
