import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yazi_stili/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    final f1 = GoogleFonts.unifrakturMaguntia(); // Risale Kapak Gotik
    final f2 = GoogleFonts.unifrakturCook(fontWeight: FontWeight.bold); // Risale Kapak Kitabe
    final f3 = GoogleFonts.pirataOne(); // Blackletter
    final f4 = GoogleFonts.grenzeGotisch(); // Textura
    final f5 = GoogleFonts.medievalSharp(); // Old
    final f6 = GoogleFonts.amiri(); // Risale Hat (Sülüs/Nesih)
    final f7 = GoogleFonts.reemKufi(); // Risale Hat (Kufi)
    final f8 = GoogleFonts.arefRuqaa(); // Risale Hat (Rika)
    final f9 = GoogleFonts.cinzelDecorative(); // Saray Varaklı
    final f10 = GoogleFonts.abrilFatface(); // Taş Baskı
    final f11 = GoogleFonts.specialElite(); // Daktilo
    final f12 = GoogleFonts.greatVibes(); // Zarif El Yazısı

    expect(f1.fontFamily, isNotNull);
    expect(f2.fontFamily, isNotNull);
    expect(f3.fontFamily, isNotNull);
    expect(f4.fontFamily, isNotNull);
    expect(f5.fontFamily, isNotNull);
    expect(f6.fontFamily, isNotNull);
    expect(f7.fontFamily, isNotNull);
    expect(f8.fontFamily, isNotNull);
    expect(f9.fontFamily, isNotNull);
    expect(f10.fontFamily, isNotNull);
    expect(f11.fontFamily, isNotNull);
    expect(f12.fontFamily, isNotNull);

    await tester.pumpWidget(const YaziStiliApp());
    expect(find.text('DRAFT'), findsOneWidget);
    expect(find.text('ÖNİZLEME'), findsWidgets);
  });
}
