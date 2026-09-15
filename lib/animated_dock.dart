import 'package:flutter/material.dart';

class AnimatedDock extends StatelessWidget {
  const AnimatedDock({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final int selected;
  final ValueChanged<int> onSelected;
  static const labels = [
    'Dashboard',
    'Voice',
    'Activity',
    'Effects',
    'Battery',
  ];
  static const icons = [
    Icons.bolt_rounded,
    Icons.graphic_eq_rounded,
    Icons.history_rounded,
    Icons.auto_awesome_rounded,
    Icons.battery_saver_rounded,
  ];
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF201A36),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF504367)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: List.generate(
          5,
          (i) => Expanded(
            child: Semantics(
              selected: selected == i,
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == i
                        ? const Color(0xFFB8A4FF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: selected == i ? 1.12 : 1),
                        duration: const Duration(milliseconds: 300),
                        builder: (_, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: Icon(
                          icons[i],
                          size: 23,
                          color: selected == i
                              ? const Color(0xFF211638)
                              : const Color(0xFFC1B6D6),
                        ),
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected == i
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: selected == i
                                ? const Color(0xFF211638)
                                : const Color(0xFFC1B6D6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
