package com.chargevoice.charge_voice

import java.util.Locale
import java.text.NumberFormat

/** Templates, rather than English spoken with a different accent. */
object SpeechText {
    private val templates = mapOf(
        "en" to arrayOf("Charger connected. Battery is at %d percent.", "%d percent charge done.", "Please unplug your charger."),
        "ja" to arrayOf("充電器が接続されました。バッテリーは%dパーセントです。", "%dパーセント充電されました。", "充電器を外してください。"),
        "hi" to arrayOf("चार्जर जुड़ गया है। बैटरी %d प्रतिशत है।", "%d प्रतिशत चार्ज हो गया है।", "कृपया चार्जर निकाल दें।"),
        "es" to arrayOf("Cargador conectado. Batería al %d por ciento.", "Carga al %d por ciento.", "Desconecta el cargador."),
        "fr" to arrayOf("Chargeur connecté. Batterie à %d pour cent.", "Charge à %d pour cent.", "Veuillez débrancher le chargeur."),
        "de" to arrayOf("Ladegerät angeschlossen. Akku bei %d Prozent.", "%d Prozent geladen.", "Bitte das Ladegerät trennen."),
        "ko" to arrayOf("충전기가 연결되었습니다. 배터리는 %d퍼센트입니다.", "%d퍼센트 충전되었습니다.", "충전기를 분리해 주세요."),
        "zh" to arrayOf("充电器已连接。电量为百分之%d。", "已充电百分之%d。", "请拔下充电器。"),
        "pt" to arrayOf("Carregador conectado. Bateria em %d por cento.", "%d por cento carregado.", "Desconecte o carregador."),
        "it" to arrayOf("Caricatore collegato. Batteria al %d per cento.", "Carica al %d per cento.", "Scollega il caricatore."),
        "ru" to arrayOf("Зарядное устройство подключено. Заряд батареи %d процентов.", "Заряжено на %d процентов.", "Отключите зарядное устройство."),
        "ar" to arrayOf("تم توصيل الشاحن. البطارية %d بالمئة.", "تم الشحن بنسبة %d بالمئة.", "يرجى فصل الشاحن."),
        "bn" to arrayOf("চার্জার সংযুক্ত। ব্যাটারি %d শতাংশ।", "%d শতাংশ চার্জ হয়েছে।", "চার্জার খুলে দিন।"),
        "ta" to arrayOf("சார்ஜர் இணைக்கப்பட்டது. பேட்டரி %d சதவீதம்.", "%d சதவீதம் சார்ஜ் ஆனது.", "சார்ஜரை அகற்றவும்."),
        "te" to arrayOf("ఛార్జర్ కనెక్ట్ అయింది. బ్యాటరీ %d శాతం.", "%d శాతం ఛార్జ్ అయింది.", "ఛార్జర్ తీసివేయండి."),
        "mr" to arrayOf("चार्जर जोडला आहे. बॅटरी %d टक्के आहे.", "%d टक्के चार्ज झाले.", "कृपया चार्जर काढा."),
        "tr" to arrayOf("Şarj cihazı bağlandı. Pil yüzde %d.", "Yüzde %d şarj oldu.", "Lütfen şarj cihazını çıkarın."),
        "id" to arrayOf("Pengisi daya terhubung. Baterai %d persen.", "Terisi %d persen.", "Cabut pengisi daya.")
    )
    fun hasTemplate(tag: String) = Locale.forLanguageTag(tag).language in templates
    fun translate(text: String, tag: String): String {
        val locale = Locale.forLanguageTag(tag)
        val level = Regex("\\d+").find(text)?.value?.toIntOrNull() ?: return text
        val template = templates[locale.language]
            ?: return NumberFormat.getPercentInstance(locale).format(level / 100.0)
        val connected = text.startsWith("Charger connected")
        val phrase = String.format(locale, template[if (connected) 0 else 1], level)
        return if (!connected && level == 100) "$phrase ${template[2]}" else phrase
    }
}
