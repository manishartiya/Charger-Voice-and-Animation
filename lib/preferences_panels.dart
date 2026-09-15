import 'port_glow.dart';
import 'charging_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _accent = Color(0xFFB8A4FF);
const _hint = Color(0xFFABA4BF);
const _channel = MethodChannel('charge_voice/control');
const _durations = [5, 10, 15, 20];

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF211D35),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class EffectPreferences extends StatelessWidget {
  const EffectPreferences({
    super.key,
    required this.data,
    required this.onSetting,
  });
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onSetting;
  @override
  Widget build(BuildContext context) => SettingsCard(
    children: [
      const Text(
        'Your charging scene',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      const Text(
        'Choose how long the full-screen effect stays.',
        style: TextStyle(color: _hint, fontSize: 12),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: [
          for (final seconds in _durations)
            ChoiceChip(
              label: Text('$seconds sec'),
              selected: (data['animationSeconds'] ?? 20) == seconds,
              onSelected: (_) => onSetting({'animationSeconds': seconds}),
            ),
        ],
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Charging-port glow'),
        subtitle: const Text(
          'Energy radiates from the socket edge of your screen.',
          style: TextStyle(color: _hint, fontSize: 12),
        ),
        value: data['portGlow'] != false,
        onChanged: (v) => onSetting({'portGlow': v}),
      ),
      if (data['portGlow'] != false) ...[
        const Text('Socket edge', style: TextStyle(color: _hint, fontSize: 12)),
        Wrap(
          spacing: 6,
          children: [
            for (final edge in ['bottom', 'top', 'left', 'right'])
              ChoiceChip(
                label: Text('${edge[0].toUpperCase()}${edge.substring(1)}'),
                selected: (data['portPosition'] ?? 'bottom') == edge,
                onSelected: (_) => onSetting({'portPosition': edge}),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 175,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0xFF38275C), Color(0xFF100E1C)],
                      radius: 1.2,
                    ),
                  ),
                ),
                const Positioned(
                  top: 14,
                  left: 16,
                  child: Text(
                    'LIVE PORT PREVIEW',
                    style: TextStyle(
                      color: _hint,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                PortGlow(
                  options: PortGlowOptions.fromData(data),
                  position: data['portPosition'] as String? ?? 'bottom',
                  themeColor: ChargeStyle.parse(
                    data['animationStyle'] as String?,
                  ).color,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Glow style', style: TextStyle(fontWeight: FontWeight.w600)),
        Wrap(
          spacing: 6,
          children: [
            for (final style in portStyles.entries)
              ChoiceChip(
                label: Text(style.value),
                selected: PortGlowOptions.fromData(data).style == style.key,
                onSelected: (_) => onSetting({'portStyle': style.key}),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Glow color', style: TextStyle(fontWeight: FontWeight.w600)),
        Wrap(
          spacing: 6,
          children: [
            for (final color in portColors.entries)
              ChoiceChip(
                label: Text(color.value),
                selected: PortGlowOptions.fromData(data).color == color.key,
                onSelected: (_) => onSetting({'portColor': color.key}),
              ),
          ],
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Fine-tune your glow'),
          subtitle: const Text(
            'Size, brightness, speed & alignment',
            style: TextStyle(color: _hint, fontSize: 12),
          ),
          children: [
            _glowChoices('Size', 'portSize', 1, {
              'Compact': .7,
              'Medium': 1,
              'Wide': 1.4,
            }),
            _glowChoices('Brightness', 'portIntensity', .7, {
              'Soft': .4,
              'Balanced': .7,
              'Vivid': 1,
            }),
            _glowChoices('Motion speed', 'portSpeed', 1, {
              'Slow': .5,
              'Normal': 1,
              'Fast': 1.5,
            }),
            _glowChoices('Socket alignment', 'portOffset', .5, {
              'Start': .25,
              'Center': .5,
              'End': .75,
            }),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Start and end move along the selected edge, from left to right or top to bottom.',
                style: TextStyle(color: _hint, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    ],
  );
  Widget _glowChoices(
    String title,
    String key,
    num fallback,
    Map<String, num> values,
  ) => Align(
    alignment: Alignment.centerLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: _hint, fontSize: 12)),
        Wrap(
          spacing: 6,
          children: [
            for (final entry in values.entries)
              ChoiceChip(
                label: Text(entry.key),
                selected: (data[key] ?? fallback) == entry.value,
                onSelected: (_) => onSetting({key: entry.value}),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

class VoiceLanguagePanel extends StatefulWidget {
  const VoiceLanguagePanel({
    super.key,
    required this.data,
    required this.onChanged,
  });
  final Map<String, dynamic> data;
  final Future<void> Function() onChanged;
  @override
  State<VoiceLanguagePanel> createState() => _VoiceLanguagePanelState();
}

class _VoiceLanguagePanelState extends State<VoiceLanguagePanel> {
  bool busy = false;
  String? error;
  Future<void> choose() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final languages =
          await _channel.invokeListMethod<dynamic>('languages') ?? [];
      if (!mounted) return;
      if (languages.isEmpty) {
        setState(
          () => error =
              'No voices found. Open system voice settings to install voice data.',
        );
        return;
      }
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => LanguagePicker(
          languages: languages,
          selected: widget.data['voiceLanguage'] as String? ?? 'en-US',
        ),
      );
      if (result != null) {
        await _channel.invokeMethod<void>('settings', {
          'voiceLanguage': result,
        });
        await widget.onChanged();
      }
    } on PlatformException catch (e) {
      if (mounted) setState(() => error = e.message);
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => error = 'Install the Android app to select speech voices.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SettingsCard(
    children: [
      const Row(
        children: [
          Icon(Icons.translate_rounded, color: _accent),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Voice language',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        widget.data['voiceLanguageName'] as String? ??
            'English (United States)',
        style: const TextStyle(fontSize: 17),
      ),
      const SizedBox(height: 6),
      const Text(
        'Japanese, Hindi and more. Choose from the languages supported by your speech engine. Some voices need a download.',
        style: TextStyle(color: _hint, fontSize: 12, height: 1.5),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: busy ? null : choose,
        icon: const Icon(Icons.language),
        label: Text(busy ? 'Loading voices…' : 'Choose language'),
      ),
      if (error != null)
        Text(
          error!,
          style: const TextStyle(color: Color(0xFFFFC889), fontSize: 12),
        ),
    ],
  );
}

class LanguagePicker extends StatefulWidget {
  const LanguagePicker({
    super.key,
    required this.languages,
    required this.selected,
  });
  final List<dynamic> languages;
  final String selected;
  @override
  State<LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<LanguagePicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.languages
        .where(
          (e) => '${e['name']} ${e['tag']}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: Column(
            children: [
              const Text(
                'Find your voice',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search language',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => query = v),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No matching languages'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item['name'] as String),
                            subtitle: Text(
                              item['translated'] == true
                                  ? 'Translated charging announcements'
                                  : 'Speaks the percentage in this language',
                            ),
                            trailing: item['tag'] == widget.selected
                                ? const Icon(Icons.check_circle, color: _accent)
                                : null,
                            onTap: () =>
                                Navigator.pop(context, item['tag'] as String),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SoundAssignments extends StatefulWidget {
  const SoundAssignments({
    super.key,
    required this.data,
    required this.onChanged,
  });
  final Map<String, dynamic> data;
  final Future<void> Function() onChanged;
  @override
  State<SoundAssignments> createState() => _SoundAssignmentsState();
}

class _SoundAssignmentsState extends State<SoundAssignments> {
  String slot = 'connect';
  bool busy = false;
  String? error;
  Future<void> run(String method, [Map<String, dynamic>? args]) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await _channel.invokeMethod<dynamic>(method, {'slot': slot, ...?args});
      await widget.onChanged();
    } on PlatformException catch (e) {
      if (mounted) setState(() => error = e.message);
    } on MissingPluginException {
      if (mounted) {
        setState(() => error = 'Custom audio is available in the Android app.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sounds = widget.data['sounds'] as Map? ?? {};
    final sound = sounds[slot] as Map? ?? {};
    final custom = sound['custom'] == true;
    return SettingsCard(
      children: [
        const Row(
          children: [
            Icon(Icons.library_music_rounded, color: _accent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Your charging sounds',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Give each moment its own sound. A custom clip replaces the voice for that event.',
          style: TextStyle(color: _hint, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          children: [
            for (final key in [
              'connect',
              for (var i = 10; i <= 100; i += 10) '$i',
            ])
              ChoiceChip(
                label: Text(key == 'connect' ? 'Plug in' : '$key%'),
                selected: slot == key,
                onSelected: busy
                    ? null
                    : (_) => setState(() {
                        slot = key;
                        error = null;
                      }),
              ),
          ],
        ),
        const Divider(height: 28, color: Colors.white12),
        Text(
          slot == 'connect' ? 'When charger connects' : 'At $slot% charge',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          sound['name'] as String? ?? 'Built-in voice',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _accent),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: busy ? null : () => run('pickSound'),
              icon: const Icon(Icons.audio_file_outlined),
              label: Text(custom ? 'Replace sound' : 'Add sound'),
            ),
            IconButton(
              onPressed: busy ? null : () => run('testSound'),
              tooltip: 'Preview selected sound',
              icon: const Icon(Icons.play_arrow_rounded),
            ),
            IconButton(
              onPressed: () => run('stopPreview'),
              tooltip: 'Stop sound preview',
              icon: const Icon(Icons.stop_rounded),
            ),
          ],
        ),
        if (custom) ...[
          const SizedBox(height: 6),
          const Text(
            'Play for up to',
            style: TextStyle(color: _hint, fontSize: 12),
          ),
          Wrap(
            spacing: 6,
            children: [
              for (final sec in _durations)
                ChoiceChip(
                  label: Text('$sec s'),
                  selected: (sound['seconds'] ?? 5) == sec,
                  onSelected: busy
                      ? null
                      : (_) => run('soundSettings', {'seconds': sec}),
                ),
            ],
          ),
          TextButton.icon(
            onPressed: busy ? null : () => run('removeSound'),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Use built-in voice'),
          ),
        ],
        if (slot == '100')
          const Text(
            'With full-charge reminders on, this sound restarts every 10 seconds. Longer clips are cut at the next reminder.',
            style: TextStyle(color: _hint, fontSize: 11, height: 1.5),
          ),
        if (slot == 'connect')
          const Text(
            'Enable “Announce when connected” below to play this event.',
            style: TextStyle(color: _hint, fontSize: 11),
          ),
        const SizedBox(height: 6),
        const Text(
          'Audio files up to 20 MB. Short clips stop at their end. Files are saved privately on your phone.',
          style: TextStyle(color: _hint, fontSize: 11, height: 1.4),
        ),
        if (busy) const LinearProgressIndicator(),
        if (error != null)
          Text(
            error!,
            style: const TextStyle(color: Color(0xFFFFC889), fontSize: 12),
          ),
      ],
    );
  }
}
