# Charge Voice

A Flutter Android app that speaks your battery percentage when a charger is connected and announces charging milestones at **10%, 20%, 30%, …, 100%**, including while the screen is off.

Version **1.4.2** refreshes the app in midnight violet, lavender, and peach; adds sliding/fading transitions across five tabs; expands to **17 charging scenes**; and adds a Battery section with remaining-time estimates and access to Android's per-app battery report.

## Eevee image fix in 1.4.2

Uses the user's supplied moonlit Eevee artwork unchanged. Corrects the case-sensitive asset filename to `assets/characters/eevee.png`. The Eevee scene preserves the complete portrait without the old cutout padding or zoom; charging text sits in the sky, the lower artwork stays visible, and the picker thumbnail focuses on the characters. The native startup cover uses the same image and keeps its percentage above the characters. Other scenes retain their previous framing.

The image-only APK is built from `build/eevee_hotfix` to exclude the unfinished chat dependencies and source. The original chat work remains in the main workspace. Flutter analysis and all 19 tests passed; the Eevee preview rendered successfully. [Preview](docs/previews/animation-eevee.png).

## New in 1.4.1

**Effects ? Your charging scene ? Charging-port glow** now has six selectable styles: Energy streams, Pulse rings, Flame jet, Lightning, Floating bubbles, and Aurora ribbon. Choose Match scene, Violet, Ice blue, Pink, Gold, Mint, or animated Rainbow colors. Fine-tune size (Compact/Medium/Wide), brightness (Soft/Balanced/Vivid), motion speed (Slow/Normal/Fast), and socket alignment (Start/Center/End) on any of the four edges. A live preview uses the same painter as the charging screen. Choices persist through Android preferences; disabling glow removes the port effect. Reduced-motion and hidden-screen settings pause its animation.

[Port-glow design preview](docs/previews/port-glow-styles.png). Version 1.4.1 adds three Flutter checks for settings-to-screen propagation, all styles/edges with reduced motion, and glow-off behavior.

## New in 1.4

- Shin-chan, Pikachu, Eevee, and Doraemon join the character scenes. Supernova, Comet Trails, and Prism Bloom add procedural effects. [Artwork sources and prompts](docs/artwork-v14.md).
- The large circular footer is replaced by flowing port-light trails and a compact animated light bar. There is no close icon, dismiss button, or on-screen countdown text.
- **Swipe upward from the lower part of the charging screen to dismiss.** Android Back, unplugging, and the selected 5/10/15/20-second timeout also close it.
- Monitoring prewarms and reuses a dedicated Flutter engine. A native charging cover with the cached selected artwork bridges startup; a gradient/bolt view covers cold starts. The native cover stays until a new-session Flutter frame and artwork are ready. The hidden charging engine pauses UI tickers and polling. Faster starts still depend on Android, the display waking, and memory pressure; there is no universal millisecond guarantee.
- **Battery** shows time until full when plugged in and estimated battery time left when unplugged. Android's charge-time estimate is preferred. A coarse fallback requires at least 2% movement over two minutes, resets on power-mode changes, reverse readings or reboot, and rejects stale data. This is whole-phone trend estimation, not per-app attribution. Dashboard estimates can be turned off.
- **View app battery usage** opens Android's real battery report. Ordinary third-party apps cannot directly read the protected per-app battery accounting figures, so this app does not invent app percentages or substitute screen time for energy use.
- The app no longer requests notification permission when monitoring starts. Android's notification settings can hide the monitor card. A silent foreground-service notification is still registered as Android requires; its lock-screen visibility is secret. On Android 13+, denied notification permission hides it from the notification drawer, but Android can retain its Active apps/Task Manager entry. No animation is put in a notification.

Platform references: [notification behavior](https://developer.android.com/develop/ui/compose/notifications/notification-permission), [charge-time estimate](https://developer.android.com/reference/android/os/BatteryManager#computeChargeTimeRemaining()), [protected battery accounting permission](https://developer.android.com/reference/android/Manifest.permission#BATTERY_STATS), and [Flutter engine prewarming](https://docs.flutter.dev/add-to-app/android/add-flutter-screen).

## New controls in 1.3

- **Effects → Your charging scene**: choose 5, 10, 15, or 20 seconds. Enable charging-port glow and select the screen edge nearest your socket (bottom, top, left, or right). This is an on-screen effect, not a hardware socket light.
- Six Demon Slayer effects now include bundled character images: Tanjiro (Water and Hinokami), Rengoku, Zenitsu, Muichiro, and Shinobu. Artwork slowly pans and zooms beneath animated particles, edge lighting, and port pulses. System bars hide during the effect and can be revealed by swiping. Character thumbnails appear in the picker.
- **Voice → Choose language**: searches languages reported by the installed Android speech engine, including Japanese when supported. Full announcement templates cover English, Japanese, Hindi, Spanish, French, German, Korean, Chinese, Portuguese, Italian, Russian, Arabic, Bengali, Tamil, Telugu, Marathi, Turkish, and Indonesian. Other supported languages speak the localized numeric percentage. Missing voice data is reported with the existing install/settings shortcuts.
- **Voice → Your charging sounds**: choose Plug in or any milestone from 10% to 100%, then add an audio file. Each event retains its own file and 5/10/15/20-second maximum duration. Preview, stop, replace, or restore built-in speech independently. Short files end naturally; files are not looped to fill the limit.
- Custom audio replaces speech for that event. With full-charge repeats enabled, the 100% clip restarts every 10 seconds, cutting longer clips at the next reminder. Unplugging or stopping monitoring stops playback. Failed playback falls back to the selected voice. Phone media volume and audio focus apply.
- Files are chosen through Android's document picker and copied into private app storage (20 MB maximum each); no broad storage or microphone permission is needed. Removing a sound deletes its private copy. Original user files are unchanged.
- The Dashboard displays the real **battery temperature in °C** (not an estimated CPU temperature). The bottom menu animates the selected icon and its background.

Character assets and their generation prompts are documented in [artwork notes](docs/character-artwork.md).

## Install and use

1. Copy `dist/charge-voice.apk` to your Android phone and open it to install. Allow installation from your file manager if Android asks.
2. Open **Charge Voice** and enable **Charging voice** on the Dashboard. Notification permission is optional; leave it disabled to hide the notification card.
3. Tap **Hear a preview**. Speech uses Android's text-to-speech engine; you do not need to provide recordings. Keep **media volume** audible.
4. For best background reliability, open the app's battery settings and select **Unrestricted**. Some manufacturers also require enabling Auto-start.
5. Lock the phone and connect a charger. Example: “Charger connected. Battery is at 43 percent.” At the next checkpoint: “50 percent charge done.”

Use the Voice tab to change speech speed, announcement volume, or connection announcements. Milestone speech remains enabled whenever monitoring is on. Activity shows recent speech completion callbacks and custom sound start events; it keeps the last 50 events, stored locally. A completion callback means the TTS engine completed playback; it cannot confirm that you heard the audio.

## Charging animations

Open **Effects** and choose **Water Breathing**, **Flame Breathing**, **Thunder Breathing**, **Mist Breathing**, **Butterfly Dance**, or **Hinokami**, alongside **Neon Pulse**, **Orbit**, **Liquid Glow**, and **Aurora**. The six anime effects combine bundled character illustrations with Flutter motion and particles; they are not character videos. Your selection is saved. The live picker and full-screen charging view share the same Flutter renderer. **Full-screen preview** works without a charger or special permission.

Start with the **Sleep-mode setup** card in Effects. Enable monitoring and automatic animations, then grant display-over-other-apps permission. On Xiaomi/MIUI, open **Phone permissions** and allow **Show on Lock screen** and **Display pop-up windows while running in the background**. These permissions were initially denied on the connected Xiaomi and prevented the charging screen from appearing. The card now reports missing permissions or a blocked launch instead of silently skipping the animation.

Animation connection detection is independent of persisted speech milestones, so a restarted service can show the animation while already connected. The charging activity configures its lock-screen behavior before Flutter attaches and survives the temporary stopped state during a sleeping-screen transition. Display success is acknowledged only after Flutter renders a frame, the activity gains focus, and the display is interactive. A bounded startup wake lock covers this transition.

Enable **Show when plugged in** and Charging voice monitoring for automatic display. To show an effect while another app is open or the phone is locked, use **Allow display over other apps** in Effects and grant Android's permission. This permission is optional; speech monitoring works without it. Android permits background activity launches for apps with user-granted `SYSTEM_ALERT_WINDOW` permission, as described in [Android's background activity restrictions](https://developer.android.com/guide/components/activities/secure-bal). Some manufacturers require an additional lock-screen/background pop-up permission, and some devices do not support this permission.

The effect opens in a separate Flutter activity, requests screen-on/show-when-locked, and keeps the screen awake for the selected 5, 10, 15, or 20 seconds. It does **not** unlock the phone or dismiss its keyguard. Close it with an upward swipe from the lower part of the screen or Android Back; automatic effects also close on unplug or when monitoring is disabled. Animations respect the system's reduced-motion setting.

## Full-charge repeating voice

**Voice → 100% charge reminder** is enabled by default. On reaching 100%, the selected full-charge sound or announcement plays; every 10 seconds afterward the app says **“100 percent charge done. Please unplug your charger.”** If connected already at 100%, the connection announcement plays first, followed by the same 10-second reminders.

Repeats stop on unplug, a battery reading below 100%, disabling the reminder, or stopping monitoring. Duplicate battery broadcasts do not restart the countdown. A delayed callback or busy speech engine skips missed repetitions instead of queuing a burst. Android scheduling/audio restrictions can delay or prevent playback; this is not a hard real-time alarm.

The service holds a timeout-limited partial wake-lock lease **only while plugged in at 100% with repeats enabled**, renewed on each tick. This keeps the CPU available for the 10-second cadence without holding the screen on. The lease is released when repeating stops and expires if callbacks stall. [Android Handler timers use uptime and are delayed by deep sleep](https://developer.android.com/reference/android/os/Handler).

## What is included

- Midnight violet, lavender and peach Material 3 dashboard, animated battery gauge, live battery/source/temperature readings.
- Native Android foreground service independent of the Flutter screen and Dart lifecycle.
- Event-driven monitoring of battery and power broadcasts, without continuous polling in the background.
- Short, timeout-limited partial wake lock for speech; audio focus is released when speech finishes. Full-charge repeating additionally uses the bounded CPU wake-lock lease described above.
- Multilingual text-to-speech, preferring an installed offline voice; missing voice/engine and muted media messages with settings shortcuts.
- Persistent notification with a **Turn off** action; sticky service restart and opt-in monitoring restoration after reboot/unlock.
- Persisted preferences and per-session milestone state; no duplicate milestone speech from unchanged levels or fluctuations. The optional 100% reminder deliberately repeats.
- No account, microphone access, analytics, or backend. Offline speech needs installed offline data for the selected language. A system engine may require a voice download initially.

The built APK supports **Android 7.0 (API 24) and later**, targets Android API 36, and includes ARM32, ARM64, and x86-64 architectures.

## Behavior and limits

Monitoring starts after the user enables it, and continues when the app is backgrounded or removed from Recents under normal Android behavior. Android force-stop, the system's Stop control, aggressive manufacturer battery management, disabled autostart, Do Not Disturb, or muted media can stop/prevent announcements. Reopen the app to resume after force-stop. It cannot speak while the device is powered off.

Connecting at a checkpoint announces the actual battery level once; at 100%, reminders then repeat if enabled. If Android skips readings (for example 49% → 51%), the latest crossed checkpoint is spoken. If it jumps over several checkpoints, only the most recent one is spoken; old milestones are not queued in a burst. Disconnecting starts a fresh session for the next charge. Failed/interrupted milestone speech is surfaced in the app. Full-charge reminders continue attempting playback on their 10-second schedule while eligible.

Android 14+ requires a foreground-service type. This app declares `specialUse` with a description of its user-enabled charging voice monitoring use case. See [Android foreground service types](https://developer.android.com/develop/background-work/services/fgs/service-types). System voice integration follows [Android TextToSpeech](https://developer.android.com/reference/android/speech/tts/TextToSpeech) and [voice data installation](https://developer.android.com/reference/android/speech/tts/TextToSpeech.Engine).

The release build uses the local **development signing key** for direct installation. Configure your own release/upload signing key before store publication. Google Play distribution also requires the applicable foreground-service declaration/review. No publishing is configured or performed.

## Build

Built with Flutter 3.41.4 / Dart 3.11.1, Kotlin, and the Android SDK. The Flutter interface talks to Android through `charge_voice/control`; no third-party background-service or speech plugin is required.

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Build output: `build/app/outputs/flutter-apk/app-release.apk`.

Native policy tests (use the JDK configured in Android Studio):

```powershell
cd android
./gradlew.bat :app:testDebugUnitTest
```

## Verification

For **1.4.1 (build 6)**, Flutter analysis is clean and **19 Flutter tests pass**. The release APK signature verified and installation on the connected Xiaomi succeeded. The app opened, monitoring resumed as a foreground service, and notification permission remained denied. The new port controls and a selected Flame jet rendered on the device ([screenshot](docs/device/v141-effects.png)). A launch-triggered charging frame logged 220 ms; this is one observed startup, not a physical-cable or sleep-to-screen timing guarantee. Native preference persistence is implemented in SharedPreferences; settings propagation and reopening the charging widget are covered in Flutter tests.

Historical 1.4 build validation:

- Flutter static analysis: clean.
- **16 Flutter tests passed**, including navigation/transitions, narrow layouts, all 17 scenes, swipe dismissal, cached-session updates, language and sound settings, estimate formatting, and battery-report navigation.
- **32 Kotlin tests passed**, including connection/milestone policy, full-charge timing, valid styles, language templates, sound selection, and charge/discharge trend validation.
- Version **1.4.0 (build 5)** release APK compiled and its signature verified (about 63 MB).
- Actual Flutter UI previews were rendered in `docs/previews/`, using sample battery data.
- The connected Xiaomi disconnected before the v1.4 installation command. **V1.4 startup latency, swipe dismissal on hardware, and notification visibility have not yet been measured/verified on this phone.** No sub-second hardware guarantee is claimed.

Earlier device evidence: v1.2 on a Xiaomi 220333QBI / Android 13 woke from sleep and displayed its Aurora animation after an ADB-simulated charger connection. See [device capture](docs/device/chargevoice-sleep.png). Version 1.3 was also installed successfully. Those earlier results do not validate the v1.4 startup changes. Real battery readings were restored after previous simulations.

### Device acceptance check

1. Install, enable monitoring, choose notification visibility, set unrestricted battery usage, and confirm the voice preview is audible.
2. Lock the screen; unplug and reconnect. Confirm the current percentage is spoken once.
3. Confirm the next 10% checkpoint is spoken, and no repeats occur while staying at that level.
4. Remove the app from Recents and repeat. Reboot, unlock once, and repeat.
5. Turn monitoring off and verify speech stops and its foreground notification disappears.
6. Test missing voice data, muted volume, and notification denial to check recovery messages.
7. Choose each effect and preview it. Test all four durations and socket edges. Grant display-over-apps permission, lock the phone, and reconnect: confirm the saved effect appears once and dismisses after the selected duration or on unplug. Deny the permission and confirm speech still works and Effects explains the setup requirement.
8. Simulate/charge to 100%, listen for at least three reminders 10 seconds apart, send duplicate 100% readings, then unplug. Confirm repetition stops. Repeat using the Voice toggle and a drop to 99%.
9. Select Japanese, install its voice data if needed, and test the voice. Confirm the words are Japanese and the percentage is correct. Test another language and return to your preferred language.
10. Import different audio files for connection and 50%. Set a 5-second limit on a file longer than 5 seconds; preview it and confirm playback stops. Test automatic connection/50% events, stopping monitoring, removing a sound, and a short file ending naturally. Test a 15-second 100% file with repeat enabled: it should restart at each 10-second deadline.

On a development phone/emulator, battery broadcasts can be simulated through `adb shell dumpsys battery`. Always restore real readings with `adb shell dumpsys battery reset` afterward. This changes reported battery state only; it does not physically charge the device.

```powershell
adb shell dumpsys battery unplug
adb shell dumpsys battery set level 9
adb shell dumpsys battery set ac 1
adb shell dumpsys battery set level 10
# Wait for speech, then try 20, 30, ... 100; repeat a level to check deduplication.
adb shell dumpsys battery reset
```

### Render design previews

```powershell
flutter test tool/capture_preview.dart --dart-define=FLUTTER_SDK=D:/Softwares/flutter
```

Replace the SDK path for your machine. This is a development preview tool; the installed app always reads the real device battery.

Speech engine discovery uses [Android TextToSpeech available languages](https://developer.android.com/reference/android/speech/tts/TextToSpeech#getAvailableLanguages()). A language being listed does not guarantee its voice data is installed or that offline playback is supported.


For v1.4 acceptance, also test bottom-up dismissal before and after the animated frame appears, two consecutive connections with different styles, notification denial with monitoring still running, and the battery report shortcut. Do not confuse an ADB-simulated power event with a physical cable replug.

Eevee hotfix 1.4.2 (build 7): APK signature verified, bundled image SHA-256 matches the supplied file, and installation on the connected Xiaomi succeeded on 2026-09-15.
