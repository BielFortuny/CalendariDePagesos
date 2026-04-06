import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'avui_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 1; // Avui by default

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final List<Widget> pages = <Widget>[
      _PlaceholderSection(
        label: strings.calendar,
        subtitle: strings.comingSoon,
      ),
      const AvuiPage(),
      _PlaceholderSection(label: strings.tips, subtitle: strings.comingSoon),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: pages[_currentIndex],
      bottomNavigationBar: _CustomBottomNavBar(
        currentIndex: _currentIndex,
        labels: <String>[strings.calendar, strings.today, strings.tips],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  static const Duration _animationDuration = Duration(milliseconds: 220);
  static const Curve _animationCurve = Curves.easeOutCubic;

  final int currentIndex;
  final List<String> labels;
  final ValueChanged<int> onTap;

  const _CustomBottomNavBar({
    required this.currentIndex,
    required this.labels,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Duration duration = MediaQuery.of(context).accessibleNavigation
        ? Duration.zero
        : _animationDuration;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.primary, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNavItem(
              context: context,
              duration: duration,
              index: 0,
              icon: Icons.calendar_month_outlined,
              label: labels[0],
            ),
            _buildNavItem(
              context: context,
              duration: duration,
              index: 1,
              icon: Icons.calendar_today_outlined,
              label: labels[1],
            ),
            _buildNavItem(
              context: context,
              duration: duration,
              index: 2,
              icon: Icons
                  .auto_awesome_outlined, // Placeholder for "Consells" (head with ?)
              label: labels[2],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required Duration duration,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: isSelected ? 1 : 0),
            duration: duration,
            curve: _animationCurve,
            builder: (context, value, child) {
              final Color foregroundColor = Color.lerp(
                colorScheme.primary,
                colorScheme.onPrimary,
                value,
              )!;
              final Color backgroundColor = Color.lerp(
                Colors.transparent,
                colorScheme.primary,
                value,
              )!;
              final Color indicatorColor = Color.lerp(
                Colors.transparent,
                colorScheme.onPrimary.withAlpha(200),
                value,
              )!;

              return Container(
                color: backgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Transform.translate(
                  offset: Offset(0, -1.5 * value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 3,
                        child: Center(
                          child: Container(
                            width: 10 + (16 * value),
                            height: 2,
                            decoration: BoxDecoration(
                              color: indicatorColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(icon, color: foregroundColor, size: 25 + value),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          color: foregroundColor,
                          fontSize: 15,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlaceholderSection extends StatelessWidget {
  const _PlaceholderSection({required this.label, required this.subtitle});

  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
