import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ThemeShowcasePage extends StatelessWidget {
  const ThemeShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Text(
                  'Terra i Sol',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.neutralSoft,
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            const double spacing = 16;
                            final int columns = _columnCount(
                              constraints.maxWidth,
                            );
                            final double cardWidth = columns == 1
                                ? constraints.maxWidth
                                : (constraints.maxWidth -
                                          (spacing * (columns - 1))) /
                                      columns;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: <Widget>[
                                SizedBox(
                                  width: cardWidth,
                                  child: const _PaletteCard(
                                    name: 'Primary',
                                    hexCode: '#3D2B1F',
                                    backgroundColor: AppColors.primary,
                                    tones: AppColors.primaryScale,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _TypographyCard(
                                    label: 'Headline',
                                    family: 'Newsreader',
                                    sampleStyle: theme.textTheme.displayLarge,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: const _ButtonsCard(),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: const _SearchCard(),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: const _PaletteCard(
                                    name: 'Secondary',
                                    hexCode: '#2D4B2D',
                                    backgroundColor: AppColors.secondary,
                                    tones: AppColors.secondaryScale,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _TypographyCard(
                                    label: 'Body',
                                    family: 'Newsreader',
                                    sampleStyle: theme.textTheme.displayMedium
                                        ?.copyWith(
                                          color: AppColors.primary.withOpacity(
                                            0.82,
                                          ),
                                        ),
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: const _ReadingRhythmCard(),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: const _NavigationCard(),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: const _PaletteCard(
                                    name: 'Tertiary',
                                    hexCode: '#1A1A1A',
                                    backgroundColor: AppColors.tertiary,
                                    tones: AppColors.tertiaryScale,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _TypographyCard(
                                    label: 'Label',
                                    family: 'Newsreader',
                                    sampleStyle: theme.textTheme.displayMedium
                                        ?.copyWith(
                                          fontSize: 72,
                                          color: AppColors.primary.withOpacity(
                                            0.78,
                                          ),
                                        ),
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: const _SingleActionCard(),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: const _ChipCard(),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: const _PaletteCard(
                                    name: 'Neutral',
                                    hexCode: '#F5F1E6',
                                    backgroundColor: AppColors.neutral,
                                    headerColor: AppColors.primary,
                                    tones: AppColors.neutralScale,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: const _ActionStripCard(),
                                ),
                              ],
                            );
                          },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _columnCount(double width) {
    if (width >= 1180) {
      return 4;
    }
    if (width >= 760) {
      return 2;
    }
    return 1;
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.name,
    required this.hexCode,
    required this.backgroundColor,
    required this.tones,
    this.headerColor = AppColors.neutral,
  });

  final String name;
  final String hexCode;
  final Color backgroundColor;
  final Color headerColor;
  final List<Color> tones;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = Theme.of(
      context,
    ).textTheme.titleMedium!.copyWith(color: headerColor);

    return Container(
      height: 190,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(color: backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(name, style: textStyle)),
              Text(hexCode, style: textStyle),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 44,
            child: Row(
              children: tones
                  .map(
                    (Color color) => Expanded(child: ColoredBox(color: color)),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.label,
    this.meta,
    this.minHeight = 190,
  });

  final Widget child;
  final String? label;
  final String? meta;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.neutralSoft,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (label != null || meta != null)
            Row(
              children: <Widget>[
                if (label != null)
                  Expanded(
                    child: Text(
                      label!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primary.withOpacity(0.75),
                      ),
                    ),
                  ),
                if (meta != null)
                  Text(
                    meta!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary.withOpacity(0.58),
                    ),
                  ),
              ],
            ),
          if (label != null || meta != null) const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _TypographyCard extends StatelessWidget {
  const _TypographyCard({
    required this.label,
    required this.family,
    required this.sampleStyle,
  });

  final String label;
  final String family;
  final TextStyle? sampleStyle;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      label: label,
      meta: family,
      child: SizedBox(
        height: 116,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Aa', style: sampleStyle),
          ),
        ),
      ),
    );
  }
}

class _ButtonsCard extends StatelessWidget {
  const _ButtonsCard();

  @override
  Widget build(BuildContext context) {
    final TextStyle? labelStyle = Theme.of(context).textTheme.labelLarge;

    return _SectionCard(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double buttonWidth = (constraints.maxWidth - 12) / 2;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Primary'),
                ),
              ),
              SizedBox(
                width: buttonWidth,
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Secondary'),
                ),
              ),
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tertiary,
                    foregroundColor: AppColors.neutral,
                    textStyle: labelStyle,
                  ),
                  onPressed: () {},
                  child: const Text('Inverted'),
                ),
              ),
              SizedBox(
                width: buttonWidth,
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Outlined'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      child: Center(
        child: TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Search',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
      ),
    );
  }
}

class _ReadingRhythmCard extends StatelessWidget {
  const _ReadingRhythmCard();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _MeasureBar(color: AppColors.primary, widthFactor: 0.74),
            SizedBox(height: 16),
            _MeasureBar(color: AppColors.secondary, widthFactor: 0.88),
            SizedBox(height: 16),
            _MeasureBar(color: AppColors.tertiary, widthFactor: 0.58),
          ],
        ),
      ),
    );
  }
}

class _MeasureBar extends StatelessWidget {
  const _MeasureBar({required this.color, required this.widthFactor});

  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.tertiary.withOpacity(0.05)),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            child: ColoredBox(color: color),
          ),
        ),
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  const _NavigationCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.neutralStrong.withOpacity(0.24),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _NavButton(icon: Icons.home_outlined, selected: true),
              SizedBox(width: 14),
              _NavButton(icon: Icons.search_rounded),
              SizedBox(width: 14),
              _NavButton(icon: Icons.person_outline_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, this.selected = false});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
      ),
      child: Icon(
        icon,
        color: selected ? AppColors.neutral : AppColors.primary,
      ),
    );
  }
}

class _SingleActionCard extends StatelessWidget {
  const _SingleActionCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Center(
        child: Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(color: AppColors.tertiary),
          child: const Icon(Icons.edit_outlined, color: AppColors.neutral),
        ),
      ),
    );
  }
}

class _ChipCard extends StatelessWidget {
  const _ChipCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(color: AppColors.primary),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.primaryHighlight,
              ),
              const SizedBox(width: 10),
              Text(
                'Label',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primaryHighlight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionStripCard extends StatelessWidget {
  const _ActionStripCard();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      child: Center(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _ActionTile(
              icon: Icons.auto_awesome_outlined,
              backgroundColor: AppColors.primary,
            ),
            _ActionTile(
              icon: Icons.agriculture_outlined,
              backgroundColor: AppColors.secondary,
            ),
            _ActionTile(
              icon: Icons.sell_outlined,
              backgroundColor: AppColors.tertiary,
            ),
            _ActionTile(
              icon: Icons.delete_outline,
              backgroundColor: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.backgroundColor});

  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(color: backgroundColor),
      child: Icon(icon, color: AppColors.neutral, size: 22),
    );
  }
}
