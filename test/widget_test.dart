import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:calendari_de_pagesos/main.dart';

void main() {
  testWidgets('shows the Terra i Sol design system', (
    WidgetTester tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(const CalendariDePagesosApp());

    expect(find.text('Terra i Sol'), findsOneWidget);
    expect(find.text('#3D2B1F'), findsOneWidget);
    expect(find.text('Outlined'), findsOneWidget);
  });
}
