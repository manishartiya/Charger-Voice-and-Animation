package com.chargevoice.charge_voice

object AnimationStyles {
    val names = setOf("neon", "orbit", "liquid", "aurora", "water", "flame", "thunder", "mist", "insect", "sun", "shinchan", "pikachu", "eevee", "doraemon", "nova", "comet", "prism")
    fun valid(value: String?) = value?.takeIf { it in names } ?: "neon"
}
