import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/moon_data.dart';
import '../data/moon_service.dart';
import '../theme/app_theme.dart';

class AvuiPage extends StatefulWidget {
  const AvuiPage({super.key});

  @override
  State<AvuiPage> createState() => _AvuiPageState();
}

class _AvuiPageState extends State<AvuiPage> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  static const MoonService _moonService = MoonService();
  late Future<MoonData> _moonFuture;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _moonFuture = _moonService.loadCurrentMoonData();
  }

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

  static const List<String> _weekdayNames = <String>[
    'dilluns',
    'dimarts',
    'dimecres',
    'dijous',
    'divendres',
    'dissabte',
    'diumenge',
  ];

  static const List<String> _monthNames = <String>[
    'gener',
    'febrer',
    'març',
    'abril',
    'maig',
    'juny',
    'juliol',
    'agost',
    'setembre',
    'octubre',
    'novembre',
    'desembre',
  ];

  void _refreshMoonData() {
    setState(() {
      _moonFuture = _moonService.loadCurrentMoonData();
    });
  }

  String _formatCatalanHeadlineDate(DateTime date) {
    final String weekday = _capitalize(_weekdayNames[date.weekday - 1]);
    final String month = _monthNames[date.month - 1];
    const String vowels = 'aeiou';
    final String prefix = vowels.contains(month[0]) ? "d'" : 'de ';

    return '$weekday, ${date.day}\n$prefix$month';
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return '${value[0].toUpperCase()}${value.substring(1)}';
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

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final bool reduceMotion = MediaQuery.of(context).accessibleNavigation;

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
      backgroundColor: AppColors.neutral, // fallback
      appBar: AppBar(
        backgroundColor: AppColors.neutral,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primary),
          onPressed: () {},
        ),
        title: Text(
          'AVUI',
          style: GoogleFonts.newsreader(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF142436), // Deep navy/slate
              Color(0xFF6FAC97), // Mid teal
              Color(0xFFE6F5DF), // Bright soft green
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
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
                        _formatCatalanHeadlineDate(today),
                        style: GoogleFonts.newsreader(
                          fontSize: 48,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sant Calixt I, papa i màrtir',
                        style: GoogleFonts.newsreader(
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w400,
                          color: AppColors.primary.withAlpha(150),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ScaleTransition(
                          scale: headerFade,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 2,
                            width: 40,
                            color: AppColors.primary,
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
                    title: 'FASE DE LA LLUNA',
                    child: _buildMoonCardContent(),
                  ),
                ),
                const SizedBox(height: 24),

                // Saints Card
                _AnimatedReveal(
                  opacity: saintsCardFade,
                  position: saintsCardSlide,
                  child: _buildCard(
                    title: 'SANTS DEL DIA',
                    titleIcon: Icons.auto_awesome,
                    child: Column(
                      children: [
                        _buildSaintRow('Sant Calixt I', 'Papa'),
                        _buildSaintRow('Sant Gaudenci', 'Bisbe'),
                        _buildSaintRow('Santa\nFortunata', 'Verge i\nmàrtir'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bottom Section (Feines del Camp)
                _AnimatedReveal(
                  opacity: campSectionFade,
                  position: campSectionSlide,
                  child: Container(
                    width: double.infinity,
                    color: AppColors.primary, // Dark brown
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
                              'FEINES DEL CAMP',
                              style: GoogleFonts.newsreader(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: AppColors.neutral.withAlpha(150),
                              ),
                            ),
                            ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 0.5,
                                sigmaY: 0.5,
                              ),
                              child: Opacity(
                                opacity: 0.42,
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

                        // Timeline / Tasks
                        _buildTimelineItem(
                          title: 'Sembrar cebes',
                          description:
                              'És el moment òptim per a les varietats primerenques.\nPrepareu la terra amb fem ben compostat i manteniu la humitat constant però sense embassaments.',
                        ),
                        _buildTimelineItem(
                          title: 'Podar vinyes',
                          description:
                              'Inicieu la poda en verd per afavorir la circulació d\'aire.\nBusqueu els brots que no portin raïm i elimineu-los amb cura.',
                          isLast: true,
                        ),

                        const SizedBox(height: 32),

                        // Quote Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.outline.withAlpha(100),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '"Per Sant Calixt, el bon vi ja és vist."',
                                textAlign: TextAlign.left,
                                style: GoogleFonts.newsreader(
                                  fontSize: 20,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.neutral,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '— REFRANYER POPULAR',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.newsreader(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: AppColors.neutral.withAlpha(180),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                        // Placeholder for tractor image
                        Center(
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.neutral.withAlpha(20),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.agriculture_outlined,
                                size: 80,
                                color: AppColors.neutral.withAlpha(100),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
    return Container(
      width: double.infinity,
      color: AppColors.neutralSoft, // The light beige BG
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
                  Icon(titleIcon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: GoogleFonts.newsreader(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.primary.withAlpha(200),
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
                color: AppColors.primary,
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
                  color: AppColors.outline.withAlpha(140),
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
                color: AppColors.primary.withAlpha(150),
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
    final double bottomPadding = isLast ? 32 : 44;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vertical Line
          Container(
            width: 5,
            decoration: BoxDecoration(
              color: AppColors.secondaryScale[8],
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
                      color: AppColors.neutral,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.newsreader(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: AppColors.neutral.withAlpha(200),
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
    return Column(
      children: [
        const SizedBox(height: 24),
        const SizedBox(
          width: 96,
          height: 96,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Calculant les dades lunars...',
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
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
    return Column(
      children: [
        const SizedBox(height: 16),
        Icon(
          Icons.error_outline,
          size: 54,
          color: AppColors.primary.withAlpha(180),
        ),
        const SizedBox(height: 12),
        Text(
          'No s\'han pogut carregar les dades de la lluna.',
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Torna-ho a provar per recalcular la fase i la visibilitat local.',
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.primary.withAlpha(180),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Reintenta'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
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
    return Column(
      children: [
        const SizedBox(height: 16),
        _MoonPhaseDisc(
          phaseLabel: moonData.phaseLabel,
          size: 96,
        ),
        const SizedBox(height: 16),
        Text(
          moonData.phaseLabel,
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Visibilitat: ${moonData.illuminationPercentage}%',
          style: GoogleFonts.newsreader(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primary.withAlpha(180),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          moonData.localObservationLabel,
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.25,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          moonData.sourceLabel,
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.3,
            color: AppColors.primary.withAlpha(165),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.my_location_outlined, size: 16),
          label: const Text('Actualitza'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary.withAlpha(190),
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
