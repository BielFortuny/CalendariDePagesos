import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_settings.dart';
import '../data/field_work_cache_store.dart';
import '../data/field_work_data.dart';
import '../data/field_work_service.dart';
import '../data/moon_data.dart';
import '../data/moon_service.dart';
import '../data/saint_data.dart';
import '../data/saint_service.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'settings_page.dart';

class AvuiPage extends StatefulWidget {
  const AvuiPage({
    super.key,
    this.moonService = const MoonService(),
    this.saintService = const SaintService(),
    this.fieldWorkService,
  });

  final MoonService moonService;
  final SaintService saintService;
  final FieldWorkService? fieldWorkService;

  @override
  State<AvuiPage> createState() => _AvuiPageState();
}

class _AvuiPageState extends State<AvuiPage> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late Future<MoonData> _moonFuture;
  late Future<SaintData> _saintFuture;
  late Future<FieldWorkData> _fieldWorkFuture;
  AppLanguage? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _moonFuture = widget.moonService.loadCurrentMoonData();
    _saintFuture = widget.saintService.loadCurrentSaintData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final AppLanguage language = AppSettingsScope.settingsOf(context).language;

    if (_currentLanguage == language) {
      return;
    }

    _currentLanguage = language;
    _fieldWorkFuture = _fieldWorkService.loadCurrentFieldWorkData(
      language: language,
    );
  }

  late final FieldWorkService _fieldWorkService =
      widget.fieldWorkService ??
      FieldWorkService(
        cacheStore: FieldWorkCacheStore(),
        moonService: widget.moonService,
      );

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Animation<double> _fade(double begin, double end, bool reduceMotion) {
    if (reduceMotion) {
      return const AlwaysStoppedAnimation<double>(1);
    }

    return CurvedAnimation(
      parent: _entryController,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  Animation<Offset> _slide(
    double begin,
    double end,
    bool reduceMotion, {
    double offset = 0.06,
  }) {
    if (reduceMotion) {
      return const AlwaysStoppedAnimation<Offset>(Offset.zero);
    }

    return Tween<Offset>(begin: Offset(0, offset), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  void _refreshMoonData() {
    setState(() {
      _moonFuture = widget.moonService.loadCurrentMoonData();
    });
  }

  void _refreshSaintData() {
    setState(() {
      _saintFuture = widget.saintService.loadCurrentSaintData();
    });
  }

  void _refreshFieldWorkData() {
    setState(() {
      _fieldWorkFuture = _fieldWorkService.loadCurrentFieldWorkData(
        language: AppSettingsScope.settingsOf(context).language,
      );
    });
  }

  Widget _buildMoonCardContent() {
    return FutureBuilder<MoonData>(
      future: _moonFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _MoonCardLoading();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _MoonCardError(onRetry: _refreshMoonData);
        }

        return _MoonCardBody(
          moonData: snapshot.data!,
          onRefresh: _refreshMoonData,
        );
      },
    );
  }

  Widget _buildSaintHeaderSubtitle() {
    final AppStrings strings = AppStrings.of(context);
    final _TodayPalette palette = _TodayPalette.fromContext(context);

    return FutureBuilder<SaintData>(
      future: _saintFuture,
      builder: (context, snapshot) {
        String headline = strings.loadingSaints;

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            headline = snapshot.data!.headline;
          } else {
            headline = strings.saintUnavailable;
          }
        }

        return Text(
          headline,
          style: GoogleFonts.newsreader(
            fontSize: 20,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
            color: palette.secondaryText,
          ),
        );
      },
    );
  }

  Widget _buildSaintCardContent() {
    final AppStrings strings = AppStrings.of(context);

    return FutureBuilder<SaintData>(
      future: _saintFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SaintCardLoading();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _SaintCardError(onRetry: _refreshSaintData);
        }

        final SaintData saintData = snapshot.data!;

        return Column(
          children: [
            const SizedBox(height: 8),
            for (final SaintEntry entry in saintData.entries)
              _buildSaintRow(
                entry.title,
                strings.countryLabel(entry.countryCode),
              ),
            const SizedBox(height: 8),
            Text(
              saintData.contextLabelFor(strings),
              textAlign: TextAlign.center,
              style: GoogleFonts.newsreader(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: _TodayPalette.fromContext(context).tertiaryText,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _refreshSaintData,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(strings.update),
              style: TextButton.styleFrom(
                foregroundColor: _TodayPalette.fromContext(
                  context,
                ).secondaryText,
                textStyle: GoogleFonts.newsreader(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildFieldWorkSectionContent() {
    final AppStrings strings = AppStrings.of(context);
    final _TodayPalette palette = _TodayPalette.fromContext(context);

    return FutureBuilder<FieldWorkData>(
      future: _fieldWorkFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _FieldWorkSectionLoading();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _FieldWorkSectionError(onRetry: _refreshFieldWorkData);
        }

        final FieldWorkData fieldWorkData = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fieldWorkData.weatherSummary,
              style: GoogleFonts.newsreader(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.35,
                color: palette.fieldSecondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fieldWorkData.lunarSummary,
              style: GoogleFonts.newsreader(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: palette.fieldSecondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fieldWorkData.sourceLabel,
              style: GoogleFonts.newsreader(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: palette.fieldTertiaryText,
              ),
            ),
            const SizedBox(height: 24),
            for (int index = 0; index < fieldWorkData.tasks.length; index += 1)
              _buildTimelineItem(
                title: fieldWorkData.tasks[index].title,
                description: fieldWorkData.tasks[index].description,
                isLast: index == fieldWorkData.tasks.length - 1,
              ),
            const SizedBox(height: 32),
            _buildProverbBox(fieldWorkData.proverb),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _refreshFieldWorkData,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(strings.updateData),
                style: TextButton.styleFrom(
                  foregroundColor: palette.fieldSecondaryText,
                  textStyle: GoogleFonts.newsreader(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final bool reduceMotion = MediaQuery.of(context).accessibleNavigation;
    final AppStrings strings = AppStrings.of(context);
    final _TodayPalette palette = _TodayPalette.fromContext(context);

    final Animation<double> headerFade = _fade(0.00, 0.24, reduceMotion);
    final Animation<Offset> headerSlide = _slide(
      0.00,
      0.24,
      reduceMotion,
      offset: 0.08,
    );
    final Animation<double> moonCardFade = _fade(0.16, 0.44, reduceMotion);
    final Animation<Offset> moonCardSlide = _slide(0.16, 0.44, reduceMotion);
    final Animation<double> saintsCardFade = _fade(0.30, 0.58, reduceMotion);
    final Animation<Offset> saintsCardSlide = _slide(0.30, 0.58, reduceMotion);
    final Animation<double> campSectionFade = _fade(0.44, 0.78, reduceMotion);
    final Animation<Offset> campSectionSlide = _slide(
      0.44,
      0.78,
      reduceMotion,
      offset: 0.04,
    );

    return Scaffold(
      backgroundColor: palette.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: palette.appBarBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, color: palette.primaryText),
          onPressed: () {},
        ),
        title: Text(
          strings.todayUppercase,
          style: GoogleFonts.newsreader(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: palette.primaryText,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: palette.primaryText),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: palette.backgroundGradient),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AnimatedReveal(
                  opacity: headerFade,
                  position: headerSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.formatHeadlineDate(today),
                        style: GoogleFonts.newsreader(
                          fontSize: 48,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                          color: palette.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSaintHeaderSubtitle(),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ScaleTransition(
                          scale: headerFade,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 2,
                            width: 40,
                            color: palette.divider,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Moon Phase Card
                _AnimatedReveal(
                  opacity: moonCardFade,
                  position: moonCardSlide,
                  child: _buildCard(
                    title: strings.moonPhaseSection,
                    child: _buildMoonCardContent(),
                  ),
                ),
                const SizedBox(height: 24),

                // Saints Card
                _AnimatedReveal(
                  opacity: saintsCardFade,
                  position: saintsCardSlide,
                  child: _buildCard(
                    title: strings.saintsOfDaySection,
                    titleIcon: Icons.auto_awesome,
                    child: _buildSaintCardContent(),
                  ),
                ),
                const SizedBox(height: 24),

                // Bottom Section (Feines del Camp)
                _AnimatedReveal(
                  opacity: campSectionFade,
                  position: campSectionSlide,
                  child: Container(
                    width: double.infinity,
                    color: palette.fieldBackground,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              strings.fieldWorkSection,
                              style: GoogleFonts.newsreader(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: palette.fieldLabelText,
                              ),
                            ),
                            ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 0.5,
                                sigmaY: 0.5,
                              ),
                              child: Opacity(
                                opacity: palette.fieldDecorationOpacity,
                                child: Image.asset(
                                  'assets/imatges/fotoarbre.png',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildFieldWorkSectionContent(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    IconData? titleIcon,
    required Widget child,
  }) {
    final _TodayPalette palette = _TodayPalette.fromContext(context);

    return Container(
      width: double.infinity,
      color: palette.cardBackground,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 8,
              left: 24,
              right: 24,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, size: 18, color: palette.primaryText),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: GoogleFonts.newsreader(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: palette.tertiaryText,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: child,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSaintRow(String name, String role) {
    final _TodayPalette palette = _TodayPalette.fromContext(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: GoogleFonts.newsreader(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: palette.primaryText,
                height: 1.2,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '................................',
                maxLines: 1,
                overflow: TextOverflow.clip,
                softWrap: false,
                textAlign: TextAlign.center,
                style: GoogleFonts.newsreader(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: palette.outline.withAlpha(140),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              role,
              textAlign: TextAlign.right,
              style: GoogleFonts.newsreader(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: palette.secondaryText,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String description,
    bool isLast = false,
  }) {
    final _TodayPalette palette = _TodayPalette.fromContext(context);
    final double bottomPadding = isLast ? 32 : 44;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vertical Line
          Container(
            width: 5,
            decoration: BoxDecoration(
              color: palette.fieldAccent,
              borderRadius: BorderRadius.circular(999),
            ),
            margin: const EdgeInsets.only(right: 14, top: 4, bottom: 4),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.newsreader(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: palette.fieldPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.newsreader(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: palette.fieldSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProverbBox(String proverb) {
    final AppStrings strings = AppStrings.of(context);
    final _TodayPalette palette = _TodayPalette.fromContext(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: palette.fieldOutline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '"$proverb"',
            textAlign: TextAlign.left,
            style: GoogleFonts.newsreader(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: palette.fieldPrimaryText,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              strings.proverbAttribution,
              textAlign: TextAlign.right,
              style: GoogleFonts.newsreader(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: palette.fieldTertiaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayPalette {
  const _TodayPalette({
    required this.scaffoldBackground,
    required this.appBarBackground,
    required this.backgroundGradient,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.divider,
    required this.cardBackground,
    required this.outline,
    required this.fieldBackground,
    required this.fieldPrimaryText,
    required this.fieldSecondaryText,
    required this.fieldTertiaryText,
    required this.fieldLabelText,
    required this.fieldAccent,
    required this.fieldOutline,
    required this.fieldDecorationOpacity,
  });

  final Color scaffoldBackground;
  final Color appBarBackground;
  final LinearGradient backgroundGradient;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color divider;
  final Color cardBackground;
  final Color outline;
  final Color fieldBackground;
  final Color fieldPrimaryText;
  final Color fieldSecondaryText;
  final Color fieldTertiaryText;
  final Color fieldLabelText;
  final Color fieldAccent;
  final Color fieldOutline;
  final double fieldDecorationOpacity;

  static _TodayPalette fromContext(BuildContext context) {
    return fromSettings(AppSettingsScope.settingsOf(context));
  }

  static _TodayPalette fromSettings(AppSettings settings) {
    if (settings.highContrast) {
      return _TodayPalette(
        scaffoldBackground: AppColors.neutralScale[9],
        appBarBackground: AppColors.neutralScale[9],
        backgroundGradient: const LinearGradient(
          colors: <Color>[
            Color(0xFFFFFCF6),
            Color(0xFFF3EAD6),
            Color(0xFFE6D6B1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        primaryText: AppColors.tertiaryScale[0],
        secondaryText: AppColors.tertiaryScale[2].withAlpha(190),
        tertiaryText: AppColors.tertiaryScale[1].withAlpha(210),
        divider: AppColors.tertiaryScale[0],
        cardBackground: Colors.white,
        outline: AppColors.primaryScale[4],
        fieldBackground: AppColors.tertiaryScale[0],
        fieldPrimaryText: Colors.white,
        fieldSecondaryText: Colors.white.withAlpha(220),
        fieldTertiaryText: Colors.white.withAlpha(180),
        fieldLabelText: Colors.white.withAlpha(170),
        fieldAccent: AppColors.secondaryScale[2],
        fieldOutline: Colors.white.withAlpha(90),
        fieldDecorationOpacity: 0.18,
      );
    }

    return _TodayPalette(
      scaffoldBackground: AppColors.neutral,
      appBarBackground: AppColors.neutral,
      backgroundGradient: const LinearGradient(
        colors: <Color>[
          Color(0xFF142436),
          Color(0xFF6FAC97),
          Color(0xFFE6F5DF),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        stops: <double>[0.0, 0.5, 1.0],
      ),
      primaryText: AppColors.primary,
      secondaryText: AppColors.primary.withAlpha(150),
      tertiaryText: AppColors.primary.withAlpha(200),
      divider: AppColors.primary,
      cardBackground: AppColors.neutralSoft,
      outline: AppColors.outline,
      fieldBackground: AppColors.primary,
      fieldPrimaryText: AppColors.neutral,
      fieldSecondaryText: AppColors.neutral.withAlpha(210),
      fieldTertiaryText: AppColors.neutral.withAlpha(170),
      fieldLabelText: AppColors.neutral.withAlpha(150),
      fieldAccent: AppColors.secondaryScale[8],
      fieldOutline: AppColors.outline.withAlpha(100),
      fieldDecorationOpacity: 0.42,
    );
  }
}

class _AnimatedReveal extends StatelessWidget {
  const _AnimatedReveal({
    required this.opacity,
    required this.position,
    required this.child,
  });

  final Animation<double> opacity;
  final Animation<Offset> position;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: position, child: child),
    );
  }
}

class _MoonCardLoading extends StatelessWidget {
  const _MoonCardLoading();

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final _TodayPalette palette = _TodayPalette.fromContext(context);

    return Column(
      children: [
        const SizedBox(height: 24),
        SizedBox(
          width: 96,
          height: 96,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: palette.primaryText,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          strings.moonLoading,
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: palette.primaryText,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MoonCardError extends StatelessWidget {
  const _MoonCardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final _TodayPalette palette = _TodayPalette.fromContext(context);

    return Column(
      children: [
        const SizedBox(height: 16),
        Icon(Icons.error_outline, size: 54, color: palette.secondaryText),
        const SizedBox(height: 12),
        Text(
          strings.moonLoadErrorTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: palette.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.moonLoadErrorBody,
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: palette.secondaryText,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16),
          label: Text(strings.retry),
          style: TextButton.styleFrom(foregroundColor: palette.primaryText),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SaintCardLoading extends StatelessWidget {
  const _SaintCardLoading();

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final _TodayPalette palette = _TodayPalette.fromContext(context);

    return Column(
      children: [
        const SizedBox(height: 24),
        SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: palette.primaryText,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          strings.saintsLoading,
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: palette.primaryText,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SaintCardError extends StatelessWidget {
  const _SaintCardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final _TodayPalette palette = _TodayPalette.fromContext(context);

    return Column(
      children: [
        const SizedBox(height: 18),
        Icon(Icons.cloud_off_outlined, size: 50, color: palette.secondaryText),
        const SizedBox(height: 12),
        Text(
          strings.saintsLoadErrorTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: palette.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.saintsLoadErrorBody,
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.3,
            color: palette.secondaryText,
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16),
          label: Text(strings.retry),
          style: TextButton.styleFrom(foregroundColor: palette.primaryText),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FieldWorkSectionLoading extends StatelessWidget {
  const _FieldWorkSectionLoading();

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final _TodayPalette palette = _TodayPalette.fromContext(context);

    return Column(
      children: [
        const SizedBox(height: 24),
        SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: palette.fieldPrimaryText,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          strings.fieldWorkLoading,
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: palette.fieldPrimaryText,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _FieldWorkSectionError extends StatelessWidget {
  const _FieldWorkSectionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final _TodayPalette palette = _TodayPalette.fromContext(context);

    return Column(
      children: [
        const SizedBox(height: 18),
        Icon(
          Icons.cloud_off_outlined,
          size: 50,
          color: palette.fieldTertiaryText,
        ),
        const SizedBox(height: 12),
        Text(
          strings.fieldWorkLoadErrorTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: palette.fieldPrimaryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.fieldWorkLoadErrorBody,
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.3,
            color: palette.fieldSecondaryText,
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16),
          label: Text(strings.retry),
          style: TextButton.styleFrom(
            foregroundColor: palette.fieldPrimaryText,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _MoonCardBody extends StatelessWidget {
  const _MoonCardBody({required this.moonData, required this.onRefresh});

  final MoonData moonData;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final _TodayPalette palette = _TodayPalette.fromContext(context);

    return Column(
      children: [
        const SizedBox(height: 16),
        _MoonPhaseDisc(phaseLabel: moonData.phaseLabel, size: 96),
        const SizedBox(height: 16),
        Text(
          strings.moonPhaseLabel(moonData.phaseLabel),
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: palette.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.moonVisibility(moonData.illuminationPercentage),
          style: GoogleFonts.newsreader(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: palette.secondaryText,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          moonData.localObservationLabelFor(strings),
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.25,
            color: palette.primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          moonData.sourceLabelFor(strings),
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.3,
            color: palette.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.my_location_outlined, size: 16),
          label: Text(strings.update),
          style: TextButton.styleFrom(
            foregroundColor: palette.secondaryText,
            textStyle: GoogleFonts.newsreader(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _MoonPhaseDisc extends StatelessWidget {
  const _MoonPhaseDisc({required this.phaseLabel, required this.size});

  final String phaseLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: SvgPicture.asset(
          _assetForPhaseLabel(phaseLabel),
          width: size,
          height: size,
        ),
      ),
    );
  }

  String _assetForPhaseLabel(String label) {
    switch (label) {
      case 'Lluna Nova':
        return 'assets/imatges/lluna_nova.svg';
      case 'Lluna Creixent':
        return 'assets/imatges/lluna_creixent.svg';
      case 'Quart Creixent':
        return 'assets/imatges/quart_creixent.svg';
      case 'Lluna Gibosa Creixent':
        return 'assets/imatges/lluna_gibosa_creixent.svg';
      case 'Lluna Plena':
        return 'assets/imatges/lluna_plena.svg';
      case 'Lluna Gibosa Minvant':
        return 'assets/imatges/lluna_gibosa_minvant.svg';
      case 'Quart Minvant':
        return 'assets/imatges/quart_minvant.svg';
      case 'Lluna Minvant':
        return 'assets/imatges/lluna_minvant.svg';
      default:
        return 'assets/imatges/lluna_creixent.svg';
    }
  }
}
