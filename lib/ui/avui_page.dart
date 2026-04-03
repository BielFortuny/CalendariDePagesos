import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class AvuiPage extends StatefulWidget {
  const AvuiPage({super.key});

  @override
  State<AvuiPage> createState() => _AvuiPageState();
}

class _AvuiPageState extends State<AvuiPage> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _moonFloatController;
  late final Animation<double> _moonFloatAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _moonFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    _moonFloatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(
        parent: _moonFloatController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _moonFloatController.dispose();
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

  @override
  Widget build(BuildContext context) {
    const String moonPhaseLabel = 'Lluna Creixent';
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
                        'Dilluns, 14\nd\'Octubre',
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
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        AnimatedBuilder(
                          animation: _moonFloatAnimation,
                          child: Image.asset(
                            _moonAssetForLabel(moonPhaseLabel),
                            width: 96,
                            height: 96,
                            fit: BoxFit.contain,
                          ),
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                reduceMotion ? 0 : _moonFloatAnimation.value,
                              ),
                              child: child,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          moonPhaseLabel,
                          style: GoogleFonts.newsreader(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Visibilitat: 72%',
                          style: GoogleFonts.newsreader(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary.withAlpha(180),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
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

  String _moonAssetForLabel(String label) {
    switch (label) {
      case 'Lluna Nova':
        return 'assets/imatges/llunanova.png';
      case 'Lluna Plena':
        return 'assets/imatges/llunaplena.png';
      case 'Quart Creixent':
        return 'assets/imatges/cuartcreixent.png';
      case 'Quart Minvant':
      case 'Lluna Minvant':
        return 'assets/imatges/quartminvant.png';
      case 'Lluna Creixent':
      default:
        return 'assets/imatges/llunacreixent.png';
    }
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
