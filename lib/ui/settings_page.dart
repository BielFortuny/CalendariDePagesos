import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_settings.dart';
import '../data/app_version_info.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.versionLoader});

  final Future<AppVersionInfo> Function()? versionLoader;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  static const double _floatingButtonClearance = 88;

  late AppSettings _draftSettings;
  late final AnimationController _entryController;
  late final Future<AppVersionInfo> _versionFuture;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  final GlobalKey _bottomSaveButtonKey = GlobalKey();
  bool _hasInitializedDraft = false;
  bool _showFloatingSaveButton = false;
  bool _visibilityCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _scrollController.addListener(_updateFloatingSaveButtonVisibility);
    _versionFuture = (widget.versionLoader ?? AppVersionInfo.load)();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateFloatingSaveButtonVisibility)
      ..dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasInitializedDraft) {
      return;
    }

    _draftSettings = AppSettingsScope.of(context).settings;
    _hasInitializedDraft = true;
  }

  Future<void> _save() async {
    final AppSettingsController controller = AppSettingsScope.of(context);
    final AppStrings strings = AppStrings(_draftSettings.language);
    await controller.save(_draftSettings);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.settingsSavedSnackBar)));

    setState(() {});
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
    double offset = 0.04,
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

  void _scheduleFloatingButtonVisibilityCheck() {
    if (_visibilityCheckScheduled) {
      return;
    }

    _visibilityCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityCheckScheduled = false;

      if (!mounted) {
        return;
      }

      _updateFloatingSaveButtonVisibility();
    });
  }

  void _updateFloatingSaveButtonVisibility() {
    final BuildContext? viewportContext = _viewportKey.currentContext;
    final BuildContext? buttonContext = _bottomSaveButtonKey.currentContext;

    if (viewportContext == null || buttonContext == null) {
      return;
    }

    final RenderObject? viewportObject = viewportContext.findRenderObject();
    final RenderObject? buttonObject = buttonContext.findRenderObject();

    if (viewportObject is! RenderBox || buttonObject is! RenderBox) {
      return;
    }

    final Offset buttonTopLeft = buttonObject.localToGlobal(
      Offset.zero,
      ancestor: viewportObject,
    );
    final Offset buttonBottomRight = buttonObject.localToGlobal(
      buttonObject.size.bottomRight(Offset.zero),
      ancestor: viewportObject,
    );
    final double visibleBottom =
        viewportObject.size.height - _floatingButtonClearance;
    final bool buttonVisibleInViewport =
        buttonBottomRight.dy > 0 && buttonTopLeft.dy < visibleBottom;
    final bool canScroll =
        _scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0;
    final bool shouldShowFloatingButton = canScroll && !buttonVisibleInViewport;

    if (shouldShowFloatingButton == _showFloatingSaveButton) {
      return;
    }

    setState(() {
      _showFloatingSaveButton = shouldShowFloatingButton;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppSettingsController controller = AppSettingsScope.of(context);
    final AppSettings savedSettings = controller.settings;
    final bool hasChanges = _draftSettings != savedSettings;
    final bool highContrast = _draftSettings.highContrast;
    final bool reduceMotion = MediaQuery.of(context).accessibleNavigation;
    final AppStrings strings = AppStrings(_draftSettings.language);

    final Animation<double> headerFade = _fade(0.00, 0.18, reduceMotion);
    final Animation<Offset> headerSlide = _slide(
      0.00,
      0.18,
      reduceMotion,
      offset: 0.05,
    );
    final Animation<double> dividerFade = _fade(0.08, 0.24, reduceMotion);
    final Animation<Offset> dividerSlide = _slide(
      0.08,
      0.24,
      reduceMotion,
      offset: 0.025,
    );
    final Animation<double> fontSectionFade = _fade(0.12, 0.30, reduceMotion);
    final Animation<Offset> fontSectionSlide = _slide(0.12, 0.30, reduceMotion);
    final Animation<double> contrastSectionFade = _fade(
      0.22,
      0.40,
      reduceMotion,
    );
    final Animation<Offset> contrastSectionSlide = _slide(
      0.22,
      0.40,
      reduceMotion,
    );
    final Animation<double> notificationsSectionFade = _fade(
      0.32,
      0.52,
      reduceMotion,
    );
    final Animation<Offset> notificationsSectionSlide = _slide(
      0.32,
      0.52,
      reduceMotion,
    );
    final Animation<double> languageSectionFade = _fade(
      0.44,
      0.64,
      reduceMotion,
    );
    final Animation<Offset> languageSectionSlide = _slide(
      0.44,
      0.64,
      reduceMotion,
    );
    final Animation<double> aboutSectionFade = _fade(0.56, 0.78, reduceMotion);
    final Animation<Offset> aboutSectionSlide = _slide(
      0.56,
      0.78,
      reduceMotion,
    );
    final Animation<double> buttonFade = _fade(0.72, 1.0, reduceMotion);
    final Animation<Offset> buttonSlide = _slide(
      0.72,
      1.0,
      reduceMotion,
      offset: 0.03,
    );

    final Color pageColor = highContrast
        ? AppColors.neutralScale[9]
        : AppColors.neutral;
    final Color cardColor = highContrast
        ? AppColors.neutralScale[9]
        : const Color(0xFFFDFBF6);
    final Color softPanelColor = highContrast
        ? AppColors.neutralScale[9]
        : const Color(0xFFF8F4EA);
    final Color borderColor = highContrast
        ? AppColors.primaryScale[4]
        : AppColors.outline;
    final Color titleColor = highContrast
        ? AppColors.tertiaryScale[0]
        : AppColors.primary;
    final Color subtitleColor = highContrast
        ? AppColors.tertiaryScale[2]
        : AppColors.primary.withAlpha(150);
    final Color accentColor = highContrast
        ? AppColors.secondaryScale[2]
        : AppColors.secondary;

    _scheduleFloatingButtonVisibilityCheck();

    return Scaffold(
      backgroundColor: pageColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _PaperTexturePainter(
                  dotColor: titleColor.withAlpha(highContrast ? 34 : 24),
                  paperGlowColor: Colors.white.withAlpha(
                    highContrast ? 10 : 26,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              key: _viewportKey,
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SettingsReveal(
                        opacity: headerFade,
                        position: headerSlide,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: titleColor,
                                size: 20,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.settingsTitle,
                                    style: GoogleFonts.newsreader(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      height: 0.95,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    strings.settingsIntro,
                                    style: GoogleFonts.newsreader(
                                      fontSize: 18,
                                      fontStyle: FontStyle.italic,
                                      color: subtitleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SettingsReveal(
                        opacity: dividerFade,
                        position: dividerSlide,
                        child: Container(
                          width: double.infinity,
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: AppColors.tertiaryScale[6].withAlpha(
                            highContrast ? 180 : 140,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _SettingsReveal(
                        opacity: fontSectionFade,
                        position: fontSectionSlide,
                        child: _SettingsSection(
                          title: strings.fontSizeTitle,
                          titleColor: titleColor,
                          trailing: Text(
                            'Tt',
                            style: GoogleFonts.newsreader(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                          child: _SegmentedFontSizePicker(
                            value: _draftSettings.fontSize,
                            titleColor: titleColor,
                            borderColor: borderColor,
                            selectedColor: titleColor,
                            selectedTextColor: pageColor,
                            labelBuilder: strings.fontSizeLabel,
                            onChanged: (AppFontSize value) {
                              setState(() {
                                _draftSettings = _draftSettings.copyWith(
                                  fontSize: value,
                                );
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _SettingsReveal(
                        opacity: contrastSectionFade,
                        position: contrastSectionSlide,
                        child: _SettingsSection(
                          title: strings.highContrastTitle,
                          titleColor: titleColor,
                          child: _SwitchCard(
                            borderColor: borderColor,
                            accentColor: accentColor,
                            surfaceColor: softPanelColor,
                            titleColor: titleColor,
                            subtitleColor: subtitleColor,
                            value: _draftSettings.highContrast,
                            title: strings.highContrastTitle,
                            subtitle: strings.highContrastSubtitle,
                            onChanged: (bool value) {
                              setState(() {
                                _draftSettings = _draftSettings.copyWith(
                                  highContrast: value,
                                );
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _SettingsReveal(
                        opacity: notificationsSectionFade,
                        position: notificationsSectionSlide,
                        child: _SettingsSection(
                          title: strings.fieldNotificationsTitle,
                          titleColor: titleColor,
                          trailing: Icon(
                            Icons.spa_outlined,
                            color: accentColor,
                            size: 18,
                          ),
                          child: Column(
                            children: [
                              _CheckboxCard(
                                borderColor: borderColor,
                                surfaceColor: cardColor,
                                accentColor: accentColor,
                                titleColor: titleColor,
                                value: _draftSettings.sowingNotifications,
                                label: strings.sowingNotificationsLabel,
                                onChanged: (bool value) {
                                  setState(() {
                                    _draftSettings = _draftSettings.copyWith(
                                      sowingNotifications: value,
                                    );
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _CheckboxCard(
                                borderColor: borderColor,
                                surfaceColor: cardColor,
                                accentColor: accentColor,
                                titleColor: titleColor,
                                value: _draftSettings.weatherAlerts,
                                label: strings.weatherAlertsLabel,
                                onChanged: (bool value) {
                                  setState(() {
                                    _draftSettings = _draftSettings.copyWith(
                                      weatherAlerts: value,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _SettingsReveal(
                        opacity: languageSectionFade,
                        position: languageSectionSlide,
                        child: _SettingsSection(
                          title: strings.languageTitle,
                          titleColor: titleColor,
                          child: DropdownButtonFormField<AppLanguage>(
                            initialValue: _draftSettings.language,
                            isExpanded: true,
                            icon: Icon(
                              Icons.unfold_more_rounded,
                              color: titleColor,
                              size: 22,
                            ),
                            decoration: InputDecoration(
                              fillColor: cardColor,
                              contentPadding: const EdgeInsets.fromLTRB(
                                16,
                                20,
                                12,
                                20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                  color: titleColor,
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                  color: titleColor,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                  color: titleColor,
                                  width: 1.7,
                                ),
                              ),
                            ),
                            dropdownColor: pageColor,
                            iconEnabledColor: titleColor,
                            style: GoogleFonts.newsreader(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                            items: AppLanguage.values
                                .map(
                                  (AppLanguage language) =>
                                      DropdownMenuItem<AppLanguage>(
                                        value: language,
                                        child: Text(
                                          strings.languageOptionLabel(language),
                                        ),
                                      ),
                                )
                                .toList(growable: false),
                            onChanged: (AppLanguage? value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _draftSettings = _draftSettings.copyWith(
                                  language: value,
                                );
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _SettingsReveal(
                        opacity: aboutSectionFade,
                        position: aboutSectionSlide,
                        child: _SettingsSection(
                          title: strings.aboutCalendarTitle,
                          titleColor: titleColor,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<AppVersionInfo>(
                                  future: _versionFuture,
                                  builder:
                                      (
                                        BuildContext context,
                                        AsyncSnapshot<AppVersionInfo> snapshot,
                                      ) {
                                        final AppVersionInfo? versionInfo =
                                            snapshot.data;
                                        final String versionLine =
                                            versionInfo == null
                                            ? strings.appVersionLine(
                                                appName: strings.appTitle,
                                                version: '...',
                                                buildNumber: '',
                                              )
                                            : strings.appVersionLine(
                                                appName: versionInfo.appName,
                                                version: versionInfo.version,
                                                buildNumber:
                                                    versionInfo.buildNumber,
                                              );

                                        return Text(
                                          versionLine,
                                          style: GoogleFonts.newsreader(
                                            fontSize: 17,
                                            fontStyle: FontStyle.italic,
                                            color: subtitleColor,
                                          ),
                                        );
                                      },
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  strings.settingsAboutBody,
                                  style: GoogleFonts.newsreader(
                                    fontSize: 16,
                                    height: 1.35,
                                    color: titleColor.withAlpha(185),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      _SettingsReveal(
                        opacity: buttonFade,
                        position: buttonSlide,
                        child: KeyedSubtree(
                          key: _bottomSaveButtonKey,
                          child: _SaveChangesButton(
                            buttonKey: const ValueKey<String>(
                              'settings-save-bottom',
                            ),
                            titleColor: titleColor,
                            pageColor: pageColor,
                            reduceMotion: reduceMotion,
                            isSaving: controller.isSaving,
                            hasChanges: hasChanges,
                            saveLabel: strings.saveChanges,
                            savedLabel: strings.settingsAlreadySaved,
                            onPressed: controller.isSaving ? null : _save,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !_showFloatingSaveButton,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: AnimatedSlide(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      offset: _showFloatingSaveButton
                          ? Offset.zero
                          : const Offset(0, 1.1),
                      child: AnimatedOpacity(
                        key: const ValueKey<String>(
                          'settings-save-floating-opacity',
                        ),
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        opacity: _showFloatingSaveButton ? 1 : 0,
                        child: Container(
                          padding: const EdgeInsets.only(top: 28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                pageColor.withAlpha(0),
                                pageColor.withAlpha(highContrast ? 238 : 248),
                              ],
                            ),
                          ),
                          child: _SaveChangesButton(
                            buttonKey: const ValueKey<String>(
                              'settings-save-floating',
                            ),
                            titleColor: titleColor,
                            pageColor: pageColor,
                            reduceMotion: reduceMotion,
                            isSaving: controller.isSaving,
                            hasChanges: hasChanges,
                            saveLabel: strings.saveChanges,
                            savedLabel: strings.settingsAlreadySaved,
                            onPressed: controller.isSaving ? null : _save,
                            floating: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.titleColor,
    required this.child,
    this.trailing,
  });

  final String title;
  final Color titleColor;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.newsreader(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 0.98,
                  color: titleColor,
                ),
              ),
            ),
            if (trailing case final Widget trailingWidget) trailingWidget,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _SettingsReveal extends StatelessWidget {
  const _SettingsReveal({
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

class _SaveChangesButton extends StatelessWidget {
  const _SaveChangesButton({
    required this.titleColor,
    required this.pageColor,
    required this.reduceMotion,
    required this.isSaving,
    required this.hasChanges,
    required this.saveLabel,
    required this.savedLabel,
    required this.onPressed,
    this.buttonKey,
    this.floating = false,
  });

  final Color titleColor;
  final Color pageColor;
  final bool reduceMotion;
  final bool isSaving;
  final bool hasChanges;
  final String saveLabel;
  final String savedLabel;
  final VoidCallback? onPressed;
  final Key? buttonKey;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: buttonKey,
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: titleColor,
          foregroundColor: pageColor,
          disabledBackgroundColor: titleColor.withAlpha(120),
          elevation: floating ? 8 : null,
          shadowColor: floating ? titleColor.withAlpha(70) : null,
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: AnimatedSwitcher(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
                child: child,
              ),
            );
          },
          child: isSaving
              ? const SizedBox(
                  key: ValueKey<String>('saving'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  hasChanges ? saveLabel : savedLabel,
                  key: ValueKey<String>(hasChanges ? 'save' : 'saved'),
                  style: GoogleFonts.newsreader(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SegmentedFontSizePicker extends StatelessWidget {
  const _SegmentedFontSizePicker({
    required this.value,
    required this.onChanged,
    required this.titleColor,
    required this.borderColor,
    required this.selectedColor,
    required this.selectedTextColor,
    required this.labelBuilder,
  });

  final AppFontSize value;
  final ValueChanged<AppFontSize> onChanged;
  final Color titleColor;
  final Color borderColor;
  final Color selectedColor;
  final Color selectedTextColor;
  final String Function(AppFontSize) labelBuilder;

  double _previewFontSize(AppFontSize option) {
    switch (option) {
      case AppFontSize.petita:
        return 16.5;
      case AppFontSize.mitjana:
        return 19;
      case AppFontSize.gran:
        return 22;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: titleColor, width: 1.5),
      ),
      child: Row(
        children: AppFontSize.values
            .map((AppFontSize option) {
              final bool isSelected = option == value;

              return Expanded(
                child: Material(
                  color: isSelected ? selectedColor : Colors.transparent,
                  child: InkWell(
                    onTap: () => onChanged(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      constraints: const BoxConstraints(minHeight: 68),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        border: Border(
                          right: option == AppFontSize.values.last
                              ? BorderSide.none
                              : BorderSide(color: titleColor, width: 1.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          labelBuilder(option),
                          style: GoogleFonts.newsreader(
                            fontSize: _previewFontSize(option),
                            fontWeight: FontWeight.w800,
                            height: 1,
                            color: isSelected ? selectedTextColor : titleColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.borderColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final Color borderColor;
  final Color accentColor;
  final Color surfaceColor;
  final Color titleColor;
  final Color subtitleColor;
  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: surfaceColor),
        boxShadow: [
          BoxShadow(
            color: titleColor.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 5, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.newsreader(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.newsreader(
                        fontSize: 17,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _HeritageToggle(
              value: value,
              onChanged: onChanged,
              borderColor: titleColor,
              activeColor: accentColor,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class _HeritageToggle extends StatelessWidget {
  const _HeritageToggle({
    required this.value,
    required this.onChanged,
    required this.borderColor,
    required this.activeColor,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color borderColor;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 58,
        height: 60,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 38,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: borderColor.withAlpha(170),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    alignment: value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: value ? activeColor : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: borderColor.withAlpha(40),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 38,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: borderColor.withAlpha(value ? 120 : 210),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckboxCard extends StatelessWidget {
  const _CheckboxCard({
    required this.borderColor,
    required this.surfaceColor,
    required this.accentColor,
    required this.titleColor,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final Color borderColor;
  final Color surfaceColor;
  final Color accentColor;
  final Color titleColor;
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: value,
                onChanged: (bool? checked) => onChanged(checked ?? false),
                side: BorderSide(color: titleColor.withAlpha(150), width: 1.4),
                fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return accentColor;
                  }

                  return Colors.transparent;
                }),
                checkColor: Colors.white,
                visualDensity: VisualDensity.standard,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.newsreader(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  const _PaperTexturePainter({
    required this.dotColor,
    required this.paperGlowColor,
  });

  final Color dotColor;
  final Color paperGlowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paperWashPaint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          paperGlowColor,
          Colors.transparent,
          paperGlowColor.withAlpha((paperGlowColor.a * 255 * 0.65).round()),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paperWashPaint);

    final Paint dotPaint = Paint()
      ..color = dotColor
      ..isAntiAlias = true;
    final Paint secondaryDotPaint = Paint()
      ..color = dotColor.withAlpha((dotColor.a * 255 * 0.7).round())
      ..isAntiAlias = true;
    const double spacing = 18;
    const double radius = 1.05;

    for (double y = 12; y < size.height + spacing; y += spacing) {
      final bool isOddRow = (y / spacing).floor().isOdd;

      for (
        double x = isOddRow ? spacing * 0.8 : spacing * 0.3;
        x < size.width + spacing;
        x += spacing
      ) {
        canvas.drawCircle(Offset(x, y), radius, dotPaint);

        if (((x + y) / spacing).round().isEven) {
          canvas.drawCircle(
            Offset(x + 0.9, y + 0.7),
            radius * 0.45,
            secondaryDotPaint,
          );
        }
      }
    }

    final Paint washPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          paperGlowColor.withAlpha((paperGlowColor.a * 255 * 0.75).round()),
          Colors.transparent,
          paperGlowColor.withAlpha((paperGlowColor.a * 255 * 0.5).round()),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, washPaint);

    final Paint grainPaint = Paint()
      ..color = dotColor.withAlpha(
        math.max(((dotColor.a * 255).round() / 2).round(), 4),
      );

    for (double y = 18; y < size.height; y += 46) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 8),
        grainPaint..strokeWidth = 0.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.paperGlowColor != paperGlowColor;
  }
}
