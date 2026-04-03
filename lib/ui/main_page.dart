import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'avui_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 1; // Avui by default

  final List<Widget> _pages = [
    const Center(child: Text('Calendari')),
    const AvuiPage(),
    const Center(child: Text('Consells')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: _pages[_currentIndex],
      bottomNavigationBar: _CustomBottomNavBar(
        currentIndex: _currentIndex,
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
  final ValueChanged<int> onTap;

  const _CustomBottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Duration duration = MediaQuery.of(context).accessibleNavigation
        ? Duration.zero
        : _animationDuration;

    return SafeArea(
      child: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: AppColors.neutral,
          border: Border(top: BorderSide(color: AppColors.primary, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNavItem(
              duration: duration,
              index: 0,
              icon: Icons.calendar_month_outlined,
              label: 'Calendari',
            ),
            _buildNavItem(
              duration: duration,
              index: 1,
              icon: Icons.calendar_today_outlined,
              label: 'Avui',
            ),
            _buildNavItem(
              duration: duration,
              index: 2,
              icon: Icons
                  .auto_awesome_outlined, // Placeholder for "Consells" (head with ?)
              label: 'Consells',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required Duration duration,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

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
                AppColors.primary,
                AppColors.neutral,
                value,
              )!;
              final Color backgroundColor = Color.lerp(
                Colors.transparent,
                AppColors.primary,
                value,
              )!;
              final Color indicatorColor = Color.lerp(
                Colors.transparent,
                AppColors.neutral.withAlpha(200),
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
