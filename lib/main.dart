import 'port_glow.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'charging_animation.dart';
import 'cinematic_scene.dart';
import 'preferences_panels.dart';
import 'animated_dock.dart';
import 'battery_insights.dart';

const mint = Color(0xFFB8A4FF);
const background = Color(0xFF100E1C);
const surface = Color(0xFF211D35);
const muted = Color(0xFFABA4BF);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: background,
    ),
  );
  runApp(const ChargeVoiceApp());
}

class ChargeVoiceApp extends StatelessWidget {
  const ChargeVoiceApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Charge Voice',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: mint,
        brightness: Brightness.dark,
        primary: mint,
        surface: surface,
      ),
      useMaterial3: true,
      sliderTheme: const SliderThemeData(trackHeight: 4),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    ),
    onGenerateInitialRoutes: (route) => [
      MaterialPageRoute(builder: (_) => screenForRoute(route)),
    ],
    onGenerateRoute: (settings) =>
        MaterialPageRoute(builder: (_) => screenForRoute(settings.name ?? '/')),
  );

  Widget screenForRoute(String route) {
    final uri = Uri.parse(route);
    if (uri.path == '/charging') {
      return FullScreenCharging(
        style: ChargeStyle.parse(uri.queryParameters['style']),
        preview: uri.queryParameters['preview'] == 'true',
        seconds: int.tryParse(uri.queryParameters['seconds'] ?? '') ?? 20,
      );
    }
    return const ChargeHome();
  }
}

class ChargeHome extends StatefulWidget {
  const ChargeHome({super.key});
  @override
  State<ChargeHome> createState() => _ChargeHomeState();
}

class _ChargeHomeState extends State<ChargeHome> with WidgetsBindingObserver {
  static const channel = MethodChannel('charge_voice/control');
  Map<String, dynamic> data = {};
  Timer? timer;
  int page = 0;
  bool busy = false;
  bool loading = true;
  bool adjustingVoice = false;
  String? failure;
  bool get enabled => data['enabled'] == true;
  int get level => (data['level'] as num?)?.toInt() ?? -1;
  bool get plugged => data['plugged'] == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refresh();
    startPolling();
  }

  void startPolling() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
      startPolling();
    } else {
      timer?.cancel();
    }
  }

  Future<void> refresh() async {
    try {
      final result = await channel.invokeMapMethod<String, dynamic>('snapshot');
      if (adjustingVoice) return;
      if (mounted) {
        setState(() {
          data = result ?? {};
          loading = false;
          failure = null;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          failure = e.message;
          loading = false;
        });
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          failure = 'Battery monitoring is available on Android.';
          loading = false;
        });
      }
    }
  }

  Future<void> action(String method, [Map<String, dynamic>? args]) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await channel.invokeMethod<dynamic>(method, args);
      await refresh();
    } on PlatformException catch (e) {
      message(e.message ?? 'Unable to complete this action. Please try again.');
    } on MissingPluginException {
      message('Install the Android app to use voice announcements.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> toggle(bool value) async {
    await action('setEnabled', {'enabled': value});
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 360),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (current, previous) => Stack(
              fit: StackFit.expand,
              children: [
                for (final child in previous)
                  IgnorePointer(
                    child: ExcludeSemantics(
                      child: TickerMode(enabled: false, child: child),
                    ),
                  ),
                ?current,
              ],
            ),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(.07, .025),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: ListView(
              key: ValueKey(page),
              primary: false,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: mint,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: background,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'charge voice',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => showHelp(context),
                      tooltip: 'How it works',
                      icon: const Icon(
                        Icons.help_outline_rounded,
                        color: muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  page == 0
                      ? 'A little voice.\nA smarter charge.'
                      : page == 1
                      ? 'Make it\nsound like you.'
                      : page == 2
                      ? 'Every charge,\nheard.'
                      : page == 3
                      ? 'Give your charge\na little magic.'
                      : 'Know your power.\nPlan your day.',
                  style: const TextStyle(
                    fontSize: 36,
                    height: 1.12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  page == 0
                      ? 'Stay in the know. Even with your screen off.'
                      : page == 1
                      ? 'Your battery updates, your way.'
                      : page == 2
                      ? 'Your recent spoken battery updates.'
                      : page == 3
                      ? 'Anime, adventure and a little nostalgia. 17 scenes.'
                      : 'Your battery, with a little more perspective.',
                  style: const TextStyle(color: muted, fontSize: 14),
                ),
                const SizedBox(height: 26),
                if (failure != null) notice(failure!, Icons.info_outline),
                if (page == 0) ...dashboard(),
                if (page == 1) ...voiceSettings(),
                if (page == 2) ...history(),
                if (page == 3) ...animationSettings(),
                if (page == 4) BatteryInsights(data: data, onAction: action),
              ],
            ),
          ),
        ),
      ),
    ),
    bottomNavigationBar: AnimatedDock(
      selected: page,
      onSelected: (value) => setState(() => page = value),
    ),
  );

  List<Widget> dashboard() => [
    if (data['showTimeEstimate'] != false) ...[
      RemainingTimeCard(data: data),
      const SizedBox(height: 16),
    ],
    if (enabled && plugged && level == 100 && data['repeatFull'] != false)
      notice(
        'Fully charged! Voice reminders repeat every 10 seconds until you unplug. You can switch them off in Voice.',
        Icons.notifications_active_outlined,
      ),
    Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF38284F), Color(0xFF201C36)],
        ),
        border: Border.all(color: const Color(0xFF554568)),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 7, color: mint),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  loading
                      ? 'READING BATTERY'
                      : plugged
                      ? 'CONNECTED TO POWER'
                      : 'BATTERY STATUS',
                  style: const TextStyle(
                    color: mint,
                    fontSize: 10,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.battery_charging_full_rounded,
                color: mint,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            excludeSemantics: true,
            label: level < 0
                ? 'Battery level unavailable'
                : 'Battery $level percent',
            child: SizedBox(
              height: 220,
              width: 220,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: level < 0 ? 0 : level / 100),
                duration: const Duration(milliseconds: 850),
                builder: (context, value, child) =>
                    CustomPaint(painter: BatteryRing(value), child: child),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      plugged
                          ? Icons.bolt_rounded
                          : Icons.battery_5_bar_rounded,
                      color: mint,
                      size: 28,
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: level < 0 ? '—' : '$level',
                            style: const TextStyle(
                              fontSize: 68,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -4,
                            ),
                          ),
                          const TextSpan(
                            text: '%',
                            style: TextStyle(fontSize: 26, color: mint),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      plugged
                          ? (level == 100 ? 'Fully charged' : 'Plugged in')
                          : 'Unplugged',
                      style: const TextStyle(color: muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: metric('POWER SOURCE', data['source'] as String? ?? '—'),
              ),
              Container(width: 1, height: 32, color: Colors.white12),
              Expanded(
                child: metric(
                  'BATTERY TEMPERATURE',
                  data['temperature'] == null
                      ? '—'
                      : '${(data['temperature'] as num).toStringAsFixed(1)}°C',
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    panel(
      child: Row(
        children: [
          iconTile(Icons.volume_up_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Charging voice',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  enabled
                      ? 'Listening for your next charge'
                      : 'Turn on to hear battery updates',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: busy || loading || failure != null ? null : toggle,
            activeThumbColor: background,
            activeTrackColor: mint,
          ),
        ],
      ),
    ),
    const SizedBox(height: 24),
    const Row(
      children: [
        Expanded(
          child: Text(
            'Your charging checkpoints',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          'EVERY 10%',
          style: TextStyle(color: mint, fontSize: 10, letterSpacing: 1),
        ),
      ],
    ),
    const SizedBox(height: 12),
    panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 8,
              runSpacing: 10,
              children: List.generate(10, (i) {
                final checkpoint = (i + 1) * 10;
                final reached = level >= checkpoint;
                return Container(
                  width: (constraints.maxWidth - 32) / 5,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: reached
                        ? mint.withValues(alpha: .14)
                        : Colors.white.withValues(alpha: .035),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: reached
                          ? mint.withValues(alpha: .3)
                          : Colors.white10,
                    ),
                  ),
                  child: Text(
                    '$checkpoint%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: reached ? mint : muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 15),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.record_voice_over_outlined, size: 17, color: muted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '“50 percent charge done.” Just like that.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    FilledButton.icon(
      onPressed: busy ? null : () => action('testVoice'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.play_arrow_rounded),
      label: const Text(
        'Hear a preview',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    const SizedBox(height: 16),
    if (enabled && data['batteryExempt'] != true)
      panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.nightlight_outlined, color: mint, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Ready for screen-off charging')),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'For reliable background updates, set Charge Voice battery usage to Unrestricted in Android settings.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.5),
            ),
            TextButton(
              onPressed: () => action('batterySettings'),
              child: const Text('Open battery settings ↗'),
            ),
          ],
        ),
      ),
    TextButton.icon(
      onPressed: () => action('notificationSettings'),
      icon: const Icon(Icons.notifications_off_outlined),
      label: Text(
        data['notifications'] == false
            ? 'Notifications hidden'
            : 'Hide monitor notification',
      ),
    ),
    if (data['voiceError'] is String &&
        (data['voiceError'] as String).isNotEmpty)
      notice(data['voiceError'] as String, Icons.volume_off_outlined),
    const SizedBox(height: 6),
    const Text(
      'BUILT-IN VOICE  ·  NO RECORDINGS NEEDED',
      textAlign: TextAlign.center,
      style: TextStyle(color: muted, fontSize: 9, letterSpacing: 1.3),
    ),
  ];

  List<Widget> voiceSettings() => [
    VoiceLanguagePanel(data: data, onChanged: refresh),
    const SizedBox(height: 16),
    SoundAssignments(data: data, onChanged: refresh),
    const SizedBox(height: 16),
    panel(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('100% charge reminder'),
        subtitle: const Text(
          'Say “100 percent charge done” every 10 seconds while plugged in. Stops on unplug or below 100%.',
          style: TextStyle(color: muted, fontSize: 12, height: 1.5),
        ),
        value: data['repeatFull'] != false,
        onChanged: busy ? null : (v) => action('settings', {'repeatFull': v}),
      ),
    ),
    const SizedBox(height: 16),
    panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconTile(Icons.record_voice_over_rounded),
          const SizedBox(height: 18),
          const Text(
            'A voice, already built in.',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Charge Voice uses Android text-to-speech. Your selected language speaks updates automatically.',
            style: TextStyle(color: muted, height: 1.6),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => action('voiceSettings'),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('System voice settings'),
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    panel(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Announce when connected'),
            subtitle: const Text(
              '“Charger connected. Battery is at 42 percent.”',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            value: data['announceConnect'] != false,
            onChanged: busy
                ? null
                : (v) => action('settings', {'announceConnect': v}),
          ),
          const Divider(color: Colors.white10, height: 28),
          const Row(
            children: [
              Icon(Icons.flag_outlined, color: mint, size: 22),
              SizedBox(width: 12),
              Expanded(child: Text('Milestone announcements')),
              Text('10–100%', style: TextStyle(color: mint)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Speaks every 10% reached during a charge. Each checkpoint is announced once per charging session.',
            style: TextStyle(color: muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Speech speed',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          Slider(
            value: ((data['speechRate'] as num?)?.toDouble() ?? .95).clamp(
              .6,
              1.3,
            ),
            min: .6,
            max: 1.3,
            divisions: 7,
            label:
                '${((data['speechRate'] as num?)?.toDouble() ?? .95).toStringAsFixed(1)}×',
            onChangeStart: (_) => adjustingVoice = true,
            onChanged: (v) => setState(() => data['speechRate'] = v),
            onChangeEnd: (v) {
              adjustingVoice = false;
              action('settings', {'speechRate': v});
            },
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Relaxed', style: TextStyle(color: muted, fontSize: 12)),
              Text('Quick', style: TextStyle(color: muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Announcement volume',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          Slider(
            value: ((data['volume'] as num?)?.toDouble() ?? 1).clamp(.2, 1),
            min: .2,
            max: 1,
            divisions: 8,
            onChangeStart: (_) => adjustingVoice = true,
            onChanged: (v) => setState(() => data['volume'] = v),
            onChangeEnd: (v) {
              adjustingVoice = false;
              action('settings', {'volume': v});
            },
          ),
          const Text(
            'Uses your phone’s media volume. Silent media volume or Do Not Disturb can prevent audible updates.',
            style: TextStyle(color: muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),
    FilledButton.icon(
      onPressed: busy ? null : () => action('testVoice'),
      icon: const Icon(Icons.play_arrow_rounded),
      label: const Text('Test my voice'),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
    ),
    const SizedBox(height: 10),
    TextButton(
      onPressed: () => action('installVoice'),
      child: const Text('Missing a voice? Install voice data ↗'),
    ),
    if (data['voiceError'] is String &&
        (data['voiceError'] as String).isNotEmpty)
      notice(data['voiceError'] as String, Icons.info_outline),
  ];

  List<Widget> animationSettings() {
    final selected = ChargeStyle.parse(data['animationStyle'] as String?);
    return [
      EffectPreferences(
        data: data,
        onSetting: (args) => action('settings', args),
      ),
      const SizedBox(height: 18),
      panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.nightlight_outlined, color: mint),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sleep-mode setup',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${enabled ? '✓' : '○'} Charging monitor  ·  ${data['overlayAllowed'] == true ? '✓' : '○'} Display permission',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            const Text(
              'On Xiaomi, also allow “Show on Lock screen” and “Display pop-up windows while running in the background” under Other permissions.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 10),
            if (!enabled ||
                data['autoAnimation'] == false ||
                data['overlayAllowed'] != true)
              FilledButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        if (!enabled) await toggle(true);
                        await action('settings', {'autoAnimation': true});
                        if (data['overlayAllowed'] != true) {
                          await action('overlaySettings');
                        }
                      },
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Enable sleep-mode animations'),
              ),
            OutlinedButton.icon(
              onPressed: busy ? null : () => action('phonePermissions'),
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Phone permissions'),
            ),
            Text(
              'Last result: ${data['animationStatus'] ?? 'Not tested yet'}',
              style: const TextStyle(color: muted, fontSize: 11),
            ),
            if (data['animationError'] is String &&
                (data['animationError'] as String).isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                data['animationError'] as String,
                style: const TextStyle(
                  color: Color(0xFFFFC889),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 18),
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFF100E1C),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: selected.color.withValues(alpha: .3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: selected.color),
                const SizedBox(width: 8),
                Text(
                  'LIVE PREVIEW',
                  style: TextStyle(
                    color: selected.color,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${data['animationSeconds'] ?? 20} SEC',
                  style: TextStyle(color: muted, fontSize: 10),
                ),
              ],
            ),
            SizedBox(
              height: 230,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CinematicScene(
                  style: selected,
                  portGlow: data['portGlow'] != false,
                  portOptions: PortGlowOptions.fromData(data),
                  portPosition: data['portPosition'] as String? ?? 'bottom',
                ),
              ),
            ),
            Text(
              selected.title,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              selected.subtitle,
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: busy
                  ? null
                  : () => action('previewAnimation', {'style': selected.name}),
              style: FilledButton.styleFrom(
                backgroundColor: selected.color,
                foregroundColor: background,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.fullscreen_rounded),
              label: const Text('Full-screen preview'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Choose your charging universe',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 183,
        children:
            [
                  ...ChargeStyle.values.where((s) => s.hasArtwork),
                  ...ChargeStyle.values.where((s) => !s.hasArtwork),
                ]
                .map(
                  (style) => Semantics(
                    selected: selected == style,
                    child: InkWell(
                      key: ValueKey('style-${style.name}'),
                      onTap: busy
                          ? null
                          : () => action('settings', {
                              'animationStyle': style.name,
                            }),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF151A20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected == style
                                ? style.color
                                : Colors.white10,
                            width: selected == style ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: style.hasArtwork
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: Image.asset(
                                        'assets/characters/${style.name}.png',
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        alignment: style == ChargeStyle.eevee
                                            ? Alignment.bottomCenter
                                            : Alignment.topCenter,
                                        cacheWidth: 360,
                                      ),
                                    )
                                  : ChargingArt(
                                      style: style,
                                      animate: false,
                                      showLabel: false,
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      style.title,
                                      style: TextStyle(
                                        color: selected == style
                                            ? style.color
                                            : Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    selected == style
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: 17,
                                    color: style.color,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
      const SizedBox(height: 16),
      panel(
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show when plugged in'),
          subtitle: const Text(
            'Shows the selected effect for 20 seconds when Charging voice monitoring is on.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          value: data['autoAnimation'] != false,
          onChanged: busy
              ? null
              : (v) => action('settings', {'autoAnimation': v}),
        ),
      ),
      const SizedBox(height: 16),
      panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  data['overlayAllowed'] == true
                      ? Icons.check_circle_outline
                      : Icons.lock_outline,
                  color: mint,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Animations over the lock screen',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data['overlayAllowed'] == true
                  ? 'Permission is enabled. Your selected animation can appear when you plug in with the app in the background.'
                  : 'Allow “Display over other apps” so Android can open your animation when the app is in the background or the screen is locked.',
              style: const TextStyle(color: muted, fontSize: 12, height: 1.5),
            ),
            TextButton(
              onPressed: busy ? null : () => action('overlaySettings'),
              child: Text(
                data['overlayAllowed'] == true
                    ? 'Manage permission ↗'
                    : 'Allow display over other apps ↗',
              ),
            ),
            const Text(
              'Some phones also require a manufacturer lock-screen pop-up permission. The effect closes on unplug, Android Back, or after your selected duration.',
              style: TextStyle(color: muted, fontSize: 11, height: 1.5),
            ),
          ],
        ),
      ),
      if (data['animationError'] is String &&
          (data['animationError'] as String).isNotEmpty)
        notice(data['animationError'] as String, Icons.info_outline),
    ];
  }

  List<Widget> history() {
    final items = (data['history'] as List?) ?? [];
    return [
      if (items.isEmpty)
        panel(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                iconTile(Icons.spatial_audio_off_rounded),
                const SizedBox(height: 20),
                const Text(
                  'Your next charge starts the story.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Turn on Charging voice and plug in. Completed announcements will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      for (final raw in items) ...[
        panel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconTile(Icons.volume_up_outlined),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      raw['text'] as String? ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      formatTime((raw['time'] as num).toInt()),
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
      if (items.isNotEmpty)
        TextButton.icon(
          onPressed: () => action('clearHistory'),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Clear activity'),
        ),
      const SizedBox(height: 14),
      const Text(
        'Only the latest 50 announcements are saved on your device.',
        textAlign: TextAlign.center,
        style: TextStyle(color: muted, fontSize: 12),
      ),
    ];
  }

  String formatTime(int value) {
    final date = DateTime.fromMillisecondsSinceEpoch(value).toLocal();
    final now = DateTime.now();
    final day =
        date.year == now.year && date.month == now.month && date.day == now.day
        ? 'Today'
        : '${date.day}/${date.month}/${date.year}';
    return '$day · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget metric(String label, String value) => Column(
    children: [
      Text(
        label,
        style: const TextStyle(color: muted, fontSize: 9, letterSpacing: 1.2),
      ),
      const SizedBox(height: 7),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ],
  );
  Widget panel({required Widget child}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: .045)),
    ),
    child: child,
  );
  Widget iconTile(IconData icon) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: mint.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: mint, size: 24),
  );
  Widget notice(String text, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: mint, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: muted, height: 1.5),
            ),
          ),
        ],
      ),
    ),
  );
  void showHelp(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Plug in. Tune out.',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            const Text(
              '1. Turn on Charging voice.\n2. Hide the monitor notification in Android settings if you prefer.\n3. Keep media volume audible and test the voice.\n4. Set battery usage to Unrestricted for best reliability.\n5. Lock your phone and connect the charger.',
              style: TextStyle(height: 1.9),
            ),
            const SizedBox(height: 20),
            const Text(
              'You’ll hear your current percentage when connected, then updates at 10%, 20%, and every 10% up to 100%. No sound files or microphone access needed.',
              style: TextStyle(color: muted, height: 1.6),
            ),
            const SizedBox(height: 14),
            const Text(
              'The monitor uses a persistent Android notification and resumes after reboot once the phone is unlocked. Force-stopping the app or manufacturer battery restrictions can stop monitoring; reopen the app and enable it again. Offline speech requires an installed offline voice for your selected language.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    ),
  );
}

class BatteryRing extends CustomPainter {
  BatteryRing(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 13;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi * .75;
    const sweep = math.pi * 1.5;
    final track = Paint()
      ..color = const Color(0xFF493957)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, track);
    if (progress > 0) {
      final glow = Paint()
        ..color = mint.withValues(alpha: .16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 19
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
      canvas.drawArc(rect, start, sweep * progress, false, glow);
      canvas.drawArc(rect, start, sweep * progress, false, track..color = mint);
      final angle = start + sweep * progress;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        4,
        Paint()..color = Colors.white,
      );
    }
    for (var i = 0; i <= 40; i++) {
      final angle = start + sweep * i / 40;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius - 17),
        center + direction * (radius - 21),
        Paint()
          ..color = Colors.white.withValues(alpha: .13)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(BatteryRing oldDelegate) =>
      oldDelegate.progress != progress;
}
