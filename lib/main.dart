import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const YaziStiliApp());
}

class YaziStiliApp extends StatelessWidget {
  const YaziStiliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akıllı İçerik Üretim ve Paylaşım Platformu',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090C16),
        primaryColor: const Color(0xFF7F00FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7F00FF),
          secondary: Color(0xFF00F2FE),
          surface: Color(0xFF11162B),
        ),
        useMaterial3: true,
      ),
      home: const ContentStudioScreen(),
    );
  }
}

class ContentStudioScreen extends StatefulWidget {
  const ContentStudioScreen({super.key});

  @override
  State<ContentStudioScreen> createState() => _ContentStudioScreenState();
}

class _ContentStudioScreenState extends State<ContentStudioScreen> {
  // GlobalKeys for RepaintBoundary (Card Image Rendering)
  final GlobalKey _mainCardRenderKey = GlobalKey();
  final GlobalKey _previewCardRenderKey = GlobalKey();

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _bodyController;

  // Card Background Color state (Zemin Rengi & Kontrast Seçimi)
  Color _cardBgColor = const Color(0xFF0F1428); // Derin Lacivert (Varsayılan)

  // Typography state
  String _selectedTitleFont = 'Risale Kapak (Gotik)';
  String _selectedBodyFont = 'Risale Hat (Sülüs)';
  String? _customLoadedFont;
  String? _customFontDisplayName;
  Uint8List? _customCardImageBytes;
  String? _loadedFileName;
  String? _loadedFileType;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _hasTextGlow = false;
  TextAlign _textAlign = TextAlign.left;

  // Frame styling state
  bool _hasShadow = true;
  double _borderThickness = 2.0; // 1.5, 3.0, 5.0
  double _borderRadius = 20.0; // 12.0, 20.0, 32.0

  // Text Color state (Yazı Rengi Seçimi)
  Color _selectedTextColor = Colors.white;

  // Text Color Swatches (Yazı Rengi Paleti)
  final List<Color> _textColorSwatches = [
    Colors.white,              // Saf Beyaz
    const Color(0xFFFFD700),   // Altın Sarısı
    const Color(0xFFFFF176),   // Güneş Sarısı
    const Color(0xFF00F2FE),   // Neon Camgöbeği (Cyan)
    const Color(0xFF00FF88),   // Zümrüt Yeşili
    const Color(0xFFFF7B00),   // Turuncu
    const Color(0xFFFF5252),   // Mercan Kırmızı
    const Color(0xFFFF4081),   // Canlı Pembe
    const Color(0xFFD8B4FE),   // Lavanta Moru
    const Color(0xFF94A3B8),   // Gümüş Gri
  ];

  // Palette & Color state
  int _activeGradientIndex = 0;
  Color _selectedAccentColor = const Color(0xFF00F2FE);
  bool _useGradientBorder = true;

  // Bottom Nav
  int _currentNavIndex = 0;

  // Preset Gradients
  final List<List<Color>> _presetGradients = [
    [const Color(0xFF00F2FE), const Color(0xFF7F00FF), const Color(0xFFFF007F)], // Cyber Neon
    [const Color(0xFFFF0844), const Color(0xFFFFB199), const Color(0xFFFF7B00)], // Sunset
    [const Color(0xFF00F5A0), const Color(0xFF00D9F5), const Color(0xFF4FACFE)], // Emerald
    [const Color(0xFFE6C875), const Color(0xFFFF7B00), const Color(0xFFFF007F)], // Luxury Gold
    [const Color(0xFF8A2387), const Color(0xFFE94057), const Color(0xFFF27121)], // Passion
  ];

  // Palette Swatches
  final List<Color> _paletteSwatches = [
    const Color(0xFF00F2FE), // Cyan
    const Color(0xFF4FACFE), // Ocean
    const Color(0xFF7F00FF), // Violet
    const Color(0xFFE100FF), // Magenta
    const Color(0xFFFF007F), // Fuchsia
    const Color(0xFFFF7B00), // Orange
    const Color(0xFF00FF88), // Emerald
    const Color(0xFFFFD700), // Gold
  ];

  // Curated Font Options (14 distinct aesthetic varieties)
  static const List<String> _fontOptions = [
    'Risale Kapak (Gotik)',
    'Risale Kapak (Kitabe)',
    'Risale Hat (Sülüs)',
    'Risale Hat (Kufi)',
    'Risale Hat (Rika)',
    'Blackletter',
    'Textura',
    'Old English',
    'Saray Varaklı',
    'Taş Baskı Kapak',
    'Daktilo Nostalji',
    'Zarif El Yazısı',
    'Modern Sade',
    'Açık & Okunaklı',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'Bismillah Her Hayrın Başıdır');
    _bodyController = TextEditingController(
      text:
          'Bismillah her hayrın başıdır. Biz dahi başta ona başlarız. Bil ey nefsim! Şu mübarek kelime İslâm nişanı olduğu gibi, bütün mevcudatın lisan-ı haliyle vird-i zebânıdır.',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // --- KART OLARAK GÖRSEL PAYLAŞIMI (IMAGE CARD SHARING) ---
  Future<void> _shareCardAsImage({GlobalKey? targetKey}) async {
    try {
      _showToast('Kart görseli hazırlanıyor (Ultra HD)...');
      final key = targetKey ?? _mainCardRenderKey;

      // Small delay to ensure render tree has completed layout
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _showToast('Kart alanı bulunamadı');
        return;
      }

      // Render as 3.0x pixel ratio image (crisp 4K/HD quality)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showToast('Görsel verisi oluşturulamadı');
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final fileName = 'yazi_stili_kart_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // Kart paylaşımında başlık olmasın kuralı gereğince sadece gövde metni eklenir
      await Share.shareXFiles(
        [XFile(file.path)],
        text: _bodyController.text,
      );
    } catch (e) {
      _showToast('Paylaşım hatası: $e');
    }
  }

  // --- DOSYA YÜKLENDİ BİLGİLENDİRME MODALI (KULLANICI GERİ BİLDİRİMİ) ---
  void _showFileLoadedModal({
    required String title,
    required String fileName,
    required String description,
    required IconData icon,
    required Color iconColor,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF10152B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F2FE).withOpacity(0.2),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor.withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: iconColor, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B223D),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, size: 14, color: Color(0xFF00F2FE)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          fileName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00F2FE),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Kapat'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.remove_red_eye, size: 16),
                        label: Text(actionLabel ?? 'Karta Bak'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F2FE),
                          foregroundColor: const Color(0xFF090D1A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (onAction != null) {
                            onAction();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- DOSYA SEÇ BUTONU VE İŞLEYİCİSİ (FILE PICKER) ---
  Future<void> _pickLocalFile() async {
    try {
      _showToast('Dosya yöneticisi açılıyor...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final fileName = file.name;
      final ext = file.extension?.toLowerCase() ?? '';

      // Byte verisi alma
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (ext == 'ttf' || ext == 'otf') {
        // TTF / OTF Font Dosyası
        if (bytes != null) {
          final cleanName = fileName.replaceAll(RegExp(r'\.(ttf|otf)$', caseSensitive: false), '');
          final fontName = 'OzelFont_${DateTime.now().millisecondsSinceEpoch}';
          final fontLoader = FontLoader(fontName);
          fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
          await fontLoader.load();

          setState(() {
            _customLoadedFont = fontName;
            _customFontDisplayName = cleanName;
            _selectedTitleFont = fontName;
            _selectedBodyFont = fontName;
            _loadedFileName = fileName;
            _loadedFileType = 'font';
          });

          _showFileLoadedModal(
            title: '🎉 Font Karta Uygulandı!',
            fileName: fileName,
            description: 'Seçtiğiniz font başarıyla yüklendi ve karttaki yazılarınız artık bu özel font ile görünüyor. Hemen aşağıdaki kartta görebilir veya Önizleme yapabilirsiniz.',
            icon: Icons.font_download_rounded,
            iconColor: const Color(0xFF00F2FE),
            actionLabel: 'Önizle',
            onAction: _openPreviewModal,
          );
        } else {
          _showToast('Font dosyası okunamadı');
        }
      } else if (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'webp') {
        // Görsel / Fotoğraf Dosyası
        if (bytes != null) {
          setState(() {
            _customCardImageBytes = bytes;
            _loadedFileName = fileName;
            _loadedFileType = 'image';
          });

          _showFileLoadedModal(
            title: '🖼️ Resim Karta Eklendi!',
            fileName: fileName,
            description: 'Seçtiğiniz görsel, kartınızın arka planına başarıyla yerleştirildi. Yazılarınız görsel üzerinde şık ve okunaklı şekilde parlayacaktır.',
            icon: Icons.image_rounded,
            iconColor: const Color(0xFF00F2FE),
            actionLabel: 'Önizle',
            onAction: _openPreviewModal,
          );
        }
      } else if (ext == 'txt' || ext == 'md') {
        // Metin Dosyası
        String content = '';
        if (bytes != null) {
          content = String.fromCharCodes(bytes);
        } else if (file.path != null) {
          content = await File(file.path!).readAsString();
        }

        if (content.isNotEmpty) {
          setState(() {
            _bodyController.text = content;
            _loadedFileName = fileName;
            _loadedFileType = 'text';
          });

          _showFileLoadedModal(
            title: '📄 Metin Karta Aktarıldı!',
            fileName: fileName,
            description: 'Metin dosyasındaki içerik doğrudan kartınızın içerisine aktarıldı. Artık dilediğiniz gibi düzenleyebilir ve kart olarak paylaşabilirsiniz.',
            icon: Icons.text_snippet_rounded,
            iconColor: const Color(0xFF00F2FE),
            actionLabel: 'Önizle',
            onAction: _openPreviewModal,
          );
        }
      } else if (ext == 'zip' || ext == 'rar' || ext == '7z') {
        // Sıkıştırılmış Arşiv Uyarısı
        _showFileLoadedModal(
          title: '📦 Sıkıştırılmış Arşiv Dosyası',
          fileName: fileName,
          description: 'Seçtiğiniz dosya bir ZIP/RAR arşividir. İnternetten veya font sitelerinden indirilen font paketleri genellikle ZIP içinde gelir.\n\n👉 Lütfen telefonunuzun "Dosyalar" (Files) uygulamasında bu ZIP dosyasına basıp "Çıkart / Ayıkla" yapın, ardından içinden çıkan .ttf veya .otf dosyasını seçin.',
          icon: Icons.folder_zip_rounded,
          iconColor: Colors.amberAccent,
          actionLabel: 'Tekrar Seç',
          onAction: _pickLocalFile,
        );
      } else {
        _showFileLoadedModal(
          title: 'ℹ️ Dosya Seçildi',
          fileName: fileName,
          description: 'Seçilen dosya formatı: .$ext\nUygulamamız şu dosya türlerini doğrudan karta işleyebilir:\n• .ttf / .otf (Özel Yazı Fontu)\n• .jpg / .png (Kart Arka Plan Görseli)\n• .txt (Metin Belgesi)',
          icon: Icons.info_outline_rounded,
          iconColor: Colors.white70,
          actionLabel: 'Tamam',
        );
      }
    } catch (e) {
      _showToast('Dosya seçme hatası: $e');
    }
  }

  // --- KART ZEMİNİ SEÇİCİ NOKTASI ---
  Widget _buildCardBgDot(Color color, String name, Color defaultTextColor) {
    final isSelected = _cardBgColor.value == color.value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _cardBgColor = color;
          // Açık Parşömen seçilirse yazı otomatik kontrastlı koyu renge geçer
          if (color == const Color(0xFFFAF7EE)) {
            _selectedTextColor = const Color(0xFF1E2433);
          } else if (_selectedTextColor == const Color(0xFF1E2433)) {
            _selectedTextColor = Colors.white;
          }
        });
        _showToast('Kart Zemini: $name');
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: const Color(0xFF00F2FE), width: 2.5)
              : Border.all(color: Colors.white24, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(color: const Color(0xFF00F2FE).withOpacity(0.6), blurRadius: 6),
                ]
              : null,
        ),
        child: isSelected
            ? Center(
                child: Icon(
                  Icons.check,
                  size: 13,
                  color: color == const Color(0xFFFAF7EE) ? Colors.black87 : Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  TextStyle _getTitleStyle({double? fontSize, bool isTablet = false}) {
    final size = fontSize ?? (isTablet ? 30.0 : 24.0);
    TextStyle base;
    if (_selectedTitleFont == _customLoadedFont || _selectedTitleFont.startsWith('OzelFont_')) {
      base = TextStyle(fontFamily: _selectedTitleFont, fontSize: size, fontWeight: FontWeight.bold);
    } else {
      switch (_selectedTitleFont) {
        case 'Risale Kapak (Gotik)':
        case 'Gotik':
        case 'Gotik Fraktur':
        case 'UnifrakturMaguntia':
          base = GoogleFonts.unifrakturMaguntia(fontSize: size * 1.15, fontWeight: FontWeight.bold);
          break;
        case 'Risale Kapak (Kitabe)':
        case 'UnifrakturCook':
          base = GoogleFonts.unifrakturCook(fontSize: size * 1.15, fontWeight: FontWeight.bold);
          break;
        case 'Risale Hat (Sülüs)':
        case 'Amiri':
          base = GoogleFonts.amiri(fontSize: size * 1.05, fontWeight: FontWeight.bold);
          break;
        case 'Risale Hat (Kufi)':
        case 'Reem Kufi':
          base = GoogleFonts.reemKufi(fontSize: size * 1.0, fontWeight: FontWeight.bold);
          break;
        case 'Risale Hat (Rika)':
        case 'Aref Ruqaa':
          base = GoogleFonts.arefRuqaa(fontSize: size * 1.1, fontWeight: FontWeight.bold);
          break;
        case 'Blackletter':
        case 'Pirata One':
          base = GoogleFonts.pirataOne(fontSize: size * 1.1, fontWeight: FontWeight.bold);
          break;
        case 'Textura':
        case 'Grenze Gotisch':
          base = GoogleFonts.grenzeGotisch(fontSize: size * 1.15, fontWeight: FontWeight.bold);
          break;
        case 'Old English':
        case 'Old':
        case 'MedievalSharp':
          base = GoogleFonts.medievalSharp(fontSize: size * 1.05, fontWeight: FontWeight.bold);
          break;
        case 'Saray Varaklı':
        case 'Cinzel Decorative':
          base = GoogleFonts.cinzelDecorative(fontSize: size, fontWeight: FontWeight.bold);
          break;
        case 'Taş Baskı Kapak':
        case 'Abril Fatface':
          base = GoogleFonts.abrilFatface(fontSize: size * 1.05, fontWeight: FontWeight.bold);
          break;
        case 'Daktilo Nostalji':
        case 'Special Elite':
          base = GoogleFonts.specialElite(fontSize: size * 0.95, fontWeight: FontWeight.bold);
          break;
        case 'Zarif El Yazısı':
        case 'Great Vibes':
          base = GoogleFonts.greatVibes(fontSize: size * 1.3, fontWeight: FontWeight.bold);
          break;
        case 'Modern Sade':
        case 'Inter':
          base = GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.bold);
          break;
        case 'Açık & Okunaklı':
        case 'Roboto':
          base = GoogleFonts.roboto(fontSize: size, fontWeight: FontWeight.bold);
          break;
        case 'Poppins':
          base = GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.bold);
          break;
        case 'Space Grotesk':
          base = GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: FontWeight.bold);
          break;
        case 'Playfair Display':
          base = GoogleFonts.playfairDisplay(fontSize: size, fontWeight: FontWeight.bold);
          break;
        case 'Plus Jakarta Sans':
          base = GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: FontWeight.bold);
          break;
        case 'Montserrat':
        default:
          base = GoogleFonts.montserrat(fontSize: size, fontWeight: FontWeight.w800);
      }
    }

    return base.copyWith(
      color: _selectedTextColor == const Color(0xFFE2E8F0) ? Colors.white : _selectedTextColor,
      shadows: _hasTextGlow
          ? [
              Shadow(
                color: _selectedTextColor.withOpacity(0.9),
                blurRadius: 16,
              ),
              Shadow(
                color: _presetGradients[_activeGradientIndex][1].withOpacity(0.7),
                blurRadius: 24,
              ),
            ]
          : null,
    );
  }

  TextStyle _getBodyStyle({double? fontSize, bool isTablet = false}) {
    // Okunabilirliği artırmak için yazı boyutu netleştirildi
    final size = fontSize ?? (isTablet ? 19.0 : 16.5);
    TextStyle base;
    if (_selectedBodyFont == _customLoadedFont || _selectedBodyFont.startsWith('OzelFont_')) {
      base = TextStyle(fontFamily: _selectedBodyFont, fontSize: size);
    } else {
      switch (_selectedBodyFont) {
        case 'Risale Kapak (Gotik)':
        case 'Gotik':
        case 'Gotik Fraktur':
        case 'UnifrakturMaguntia':
          base = GoogleFonts.unifrakturMaguntia(fontSize: size * 1.15);
          break;
        case 'Risale Kapak (Kitabe)':
        case 'UnifrakturCook':
          base = GoogleFonts.unifrakturCook(fontSize: size * 1.15);
          break;
        case 'Risale Hat (Sülüs)':
        case 'Amiri':
          base = GoogleFonts.amiri(fontSize: size * 1.05);
          break;
        case 'Risale Hat (Kufi)':
        case 'Reem Kufi':
          base = GoogleFonts.reemKufi(fontSize: size * 1.0);
          break;
        case 'Risale Hat (Rika)':
        case 'Aref Ruqaa':
          base = GoogleFonts.arefRuqaa(fontSize: size * 1.1);
          break;
        case 'Blackletter':
        case 'Pirata One':
          base = GoogleFonts.pirataOne(fontSize: size * 1.05);
          break;
        case 'Textura':
        case 'Grenze Gotisch':
          base = GoogleFonts.grenzeGotisch(fontSize: size * 1.15);
          break;
        case 'Old English':
        case 'Old':
        case 'MedievalSharp':
          base = GoogleFonts.medievalSharp(fontSize: size * 1.05);
          break;
        case 'Saray Varaklı':
        case 'Cinzel Decorative':
          base = GoogleFonts.cinzelDecorative(fontSize: size * 0.95);
          break;
        case 'Taş Baskı Kapak':
        case 'Abril Fatface':
          base = GoogleFonts.abrilFatface(fontSize: size * 1.0);
          break;
        case 'Daktilo Nostalji':
        case 'Special Elite':
          base = GoogleFonts.specialElite(fontSize: size * 0.95);
          break;
        case 'Zarif El Yazısı':
        case 'Great Vibes':
          base = GoogleFonts.greatVibes(fontSize: size * 1.25);
          break;
        case 'Modern Sade':
        case 'Inter':
          base = GoogleFonts.inter(fontSize: size);
          break;
        case 'Açık & Okunaklı':
        case 'Roboto':
          base = GoogleFonts.roboto(fontSize: size);
          break;
        case 'Plus Jakarta Sans':
          base = GoogleFonts.plusJakartaSans(fontSize: size);
          break;
        case 'Montserrat':
          base = GoogleFonts.montserrat(fontSize: size);
          break;
        case 'Open Sans':
        default:
          base = GoogleFonts.openSans(fontSize: size);
      }
    }

    return base.copyWith(
      color: _selectedTextColor,
      fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: _isUnderline ? TextDecoration.underline : TextDecoration.none,
      decorationColor: _selectedTextColor,
      height: 1.6,
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E243A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _cycleThickness() {
    setState(() {
      if (_borderThickness == 1.5) {
        _borderThickness = 3.0;
      } else if (_borderThickness == 3.0) {
        _borderThickness = 5.0;
      } else {
        _borderThickness = 1.5;
      }
    });
    _showToast('Çerçeve Kalınlığı: ${_borderThickness}px');
  }

  void _cycleCorner() {
    setState(() {
      if (_borderRadius == 12.0) {
        _borderRadius = 20.0;
      } else if (_borderRadius == 20.0) {
        _borderRadius = 32.0;
      } else {
        _borderRadius = 12.0;
      }
    });
    _showToast('Köşe Kavis Derecesi: ${_borderRadius.toInt()}px');
  }

  void _cycleAlignment() {
    setState(() {
      if (_textAlign == TextAlign.left) {
        _textAlign = TextAlign.center;
        _showToast('Metin Hizalama: Orta');
      } else if (_textAlign == TextAlign.center) {
        _textAlign = TextAlign.right;
        _showToast('Metin Hizalama: Sağ');
      } else {
        _textAlign = TextAlign.left;
        _showToast('Metin Hizalama: Sol');
      }
    });
  }

  void _toggleCase() {
    final current = _bodyController.text;
    if (current == current.toUpperCase()) {
      _bodyController.text = current.toLowerCase();
      _showToast('Küçük harfe dönüştürüldü');
    } else {
      _bodyController.text = current.toUpperCase();
      _showToast('BÜYÜK HARFE dönüştürüldü');
    }
    setState(() {});
  }

  void _openAIModal() {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101426),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 640 : double.infinity),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00F2FE), Color(0xFF7F00FF)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '✦ AI SİHİRBAZ',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'İçeriği Yapay Zeka ile İyileştir',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  _buildAIOption(
                    title: '🚀 Teknoloji & Dijital Mimari',
                    subtitle: 'Gelecek odaklı, profesyonel ve yenilikçi metin.',
                    onTap: () {
                      setState(() {
                        _titleController.text = 'Dijital Dünyanızın\nYeni Mimarisi';
                        _bodyController.text =
                            'Geleceğin teknolojisini bugünden inşa edin. Akıllı içerik algoritmaları, kusursuz tipografi ve büyüleyici görsel estetik ile markanızı bir adım öne taşıyın.';
                      });
                      Navigator.pop(context);
                      _showToast('Teknoloji teması uygulandı!');
                    },
                  ),
                  _buildAIOption(
                    title: '✨ Minimal & Lüks Vizyon',
                    subtitle: 'Zarif, prestijli ve sofistike tasarım dili.',
                    onTap: () {
                      setState(() {
                        _titleController.text = 'Zarafetin\nSessiz Gücü';
                        _bodyController.text =
                            'Sadelik en yüksek gelişmişlik düzeyidir. Minimalist dokunuşlar, saf renk uyumu ve kusursuz tipografik dengeyle tasarımda mükemmeli yakalayın.';
                        _selectedTitleFont = 'Playfair Display';
                        _activeGradientIndex = 3; // Gold
                      });
                      Navigator.pop(context);
                      _showToast('Lüks vizyon teması uygulandı!');
                    },
                  ),
                  _buildAIOption(
                    title: '📈 Başarı & Motivasyon',
                    subtitle: 'Eyleme geçirici, dinamik ve ilham verici ton.',
                    onTap: () {
                      setState(() {
                        _titleController.text = 'Sınırları Aş,\nİz Bırak';
                        _bodyController.text =
                            'Büyük başarılar cesur adımlarla başlar. Kendi hikayeni yaz, vizyonunu dünyayla paylaş ve yarının standartlarını bugünden belirle!';
                        _activeGradientIndex = 1; // Sunset
                      });
                      Navigator.pop(context);
                      _showToast('Motivasyon teması uygulandı!');
                    },
                  ),
                  _buildAIOption(
                    title: '📜 Gotik Kaligrafi (Blackletter & Textura)',
                    subtitle: 'Gotik, Blackletter, Textura ve Old stilleri ile asil altın dokunuş.',
                    onTap: () {
                      setState(() {
                        _selectedTitleFont = 'Gotik';
                        _selectedBodyFont = 'Gotik';
                        _selectedTextColor = const Color(0xFFFFD700);
                        _activeGradientIndex = 3; // Luxury Gold
                        _useGradientBorder = true;
                      });
                      Navigator.pop(context);
                      _showToast('Gotik kaligrafi stili uygulandı!');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAIOption({required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF171E36),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }

  void _openTemplatesModal() {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101426),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 640 : double.infinity),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hazır Tasarım Şablonları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildThemeOption(
                    name: 'Siber Neon',
                    desc: 'Montserrat + Open Sans (Cyan & Mor)',
                    colors: [const Color(0xFF00F2FE), const Color(0xFF7F00FF)],
                    onApply: () {
                      setState(() {
                        _selectedTitleFont = 'Montserrat';
                        _selectedBodyFont = 'Open Sans';
                        _activeGradientIndex = 0;
                        _useGradientBorder = true;
                        _hasShadow = true;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  _buildThemeOption(
                    name: 'Gün Batımı Ateşi',
                    desc: 'Poppins + Inter (Turuncu & Fuşya)',
                    colors: [const Color(0xFFFF0844), const Color(0xFFFF7B00)],
                    onApply: () {
                      setState(() {
                        _selectedTitleFont = 'Poppins';
                        _selectedBodyFont = 'Inter';
                        _activeGradientIndex = 1;
                        _useGradientBorder = true;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  _buildThemeOption(
                    name: 'Zümrüt Biyosistem',
                    desc: 'Space Grotesk + Plus Jakarta (Yeşil & Mavi)',
                    colors: [const Color(0xFF00F5A0), const Color(0xFF00D9F5)],
                    onApply: () {
                      setState(() {
                        _selectedTitleFont = 'Space Grotesk';
                        _selectedBodyFont = 'Plus Jakarta Sans';
                        _activeGradientIndex = 2;
                        _useGradientBorder = true;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  _buildThemeOption(
                    name: 'Zarif Altın',
                    desc: 'Playfair Display + Montserrat (Altın Işıma)',
                    colors: [const Color(0xFFE6C875), const Color(0xFFFF7B00)],
                    onApply: () {
                      setState(() {
                        _selectedTitleFont = 'Playfair Display';
                        _selectedBodyFont = 'Montserrat';
                        _activeGradientIndex = 3;
                        _useGradientBorder = true;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  _buildThemeOption(
                    name: '📜 Gotik & Tarihi Koleksiyon',
                    desc: 'Gotik, Blackletter, Textura ve Old Yazı Stilleri',
                    colors: [const Color(0xFFE6C875), const Color(0xFFFFD700)],
                    onApply: () {
                      setState(() {
                        _selectedTitleFont = 'Gotik';
                        _selectedBodyFont = 'Gotik';
                        _selectedTextColor = const Color(0xFFFFD700);
                        _activeGradientIndex = 3;
                        _useGradientBorder = true;
                      });
                      Navigator.pop(context);
                      _showToast('Gotik koleksiyon teması uygulandı!');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption({
    required String name,
    required String desc,
    required List<Color> colors,
    required VoidCallback onApply,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF171E36),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                Text(desc, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF232D50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Uygula', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // --- AYARLAR BÖLÜMÜ / HAKKINDA: NİHAT YAZGAN ---
  void _openSettingsModal() {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1326),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 640 : double.infinity),
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00F2FE), Color(0xFF7F00FF)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'UYGULAMA AYARLARI',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ==========================================
                  // HAKKINDA: NİHAT YAZGAN ÖZEL BÖLÜMÜ
                  // ==========================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1E2648),
                          Color(0xFF141932),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00F2FE).withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F2FE).withOpacity(0.18),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00F2FE), Color(0xFF7F00FF)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7F00FF).withOpacity(0.6),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'NY',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'HAKKINDA:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF00F2FE),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.verified, size: 15, color: Color(0xFF00F2FE)),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'NİHAT YAZGAN',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Akıllı İçerik Üretim ve Paylaşım Platformu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Tercihler & Özelleştirme',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),

                  // Setting 1
                  _buildSettingTile(
                    icon: Icons.image_rounded,
                    title: 'Kart Olarak Görsel Paylaşımı',
                    subtitle: 'İçerikleri 4K PNG kartı olarak sosyal medyaya aktar',
                    trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF00F2FE), size: 22),
                    onTap: () => _showToast('Görsel kart paylaşımı aktif'),
                  ),
                  // Setting 2
                  _buildSettingTile(
                    icon: Icons.devices_rounded,
                    title: 'Telefon & Tablet Modu',
                    subtitle: 'Geniş ekranlar için otomatik optimize arayüz',
                    trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF00F2FE), size: 22),
                    onTap: () => _showToast('Telefon ve tablet uyumluluğu aktif'),
                  ),
                  // Setting 3
                  _buildSettingTile(
                    icon: Icons.cloud_done_rounded,
                    title: 'Otomatik Taslak Kaydı',
                    subtitle: 'Düzenlemeler anında hafızaya alınır',
                    trailing: const Icon(Icons.toggle_on_rounded, color: Color(0xFF00F2FE), size: 32),
                    onTap: () => _showToast('Otomatik taslak kaydı devrede'),
                  ),
                  // Setting 4: Sorularla Risale Font İndirme Sayfası
                  _buildSettingTile(
                    icon: Icons.font_download_rounded,
                    title: 'Sorularla Risale Font İndirme Sayfası',
                    subtitle: 'Transkripsiyon, Osmanlıca ve kapak fontları indirme rehberi',
                    trailing: const Icon(Icons.open_in_new_rounded, color: Color(0xFF00F2FE), size: 18),
                    onTap: _openSorularlaRisaleFontDialog,
                  ),
                  // Setting 5
                  _buildSettingTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Sürüm & Lisans',
                    subtitle: 'v1.0.0 • Pro Studio Edition',
                    trailing: const Text('GÜNCEL', style: TextStyle(color: Color(0xFF00F2FE), fontSize: 11, fontWeight: FontWeight.bold)),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF151B33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF222B50),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF00F2FE)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  // --- SORULARLA RİSALE FONT İNDİRME SAYFASI VE REHBERİ ---
  void _openSorularlaRisaleFontDialog() {
    const String fontUrl = 'https://sorularlarisale.com/kategori/risalelerde-kullanilan-fontlar';
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1428),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00F2FE), width: 1.5),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00F2FE).withOpacity(0.25), blurRadius: 20),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2346),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_download_rounded, color: Color(0xFF00F2FE), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sorularla Risale Fontları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('İndirme Sayfası ve Rehberi', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161C36),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📌 Risale-i Nur Font Çeşitleri:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00F2FE), fontSize: 13),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '1. Transkripsiyon Fontları (Â, Î, Û, Ḥ, Ṣ gibi özel harfler)\n'
                        '2. Orijinal Risale Kapak Fontları (Gotik & Kitabe stilleri)\n'
                        '3. Osmanlıca & Arapça Hat Yazı Tipleri (Nesih, Sülüs, Rika)\n\n'
                        '💡 Uygulamamızda bu font çeşitlerinin en seçkinleri (Risale Kapak Gotik, Kitabe, Sülüs, Kufi, Textura, Blackletter) doğrudan yüklü ve kullanıma hazırdır.',
                        style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0E1B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.link, size: 16, color: Color(0xFF00F2FE)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fontUrl,
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Bağlantıyı Kopyala', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F2FE),
                          foregroundColor: const Color(0xFF090D1A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: fontUrl));
                          _showToast('Sorularla Risale indirme linki kopyalandı!');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Paylaş', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Share.share('Sorularla Risale Font İndirme Sayfası:\n$fontUrl');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- RİSALE & HİKMET KÜTÜPHANESİ (LIBRARY MODAL) ---
  void _openLibraryModal() {
    int selectedTab = 0; // 0: Vecizeler, 1: Kapak & Kitabe, 2: Font Rehberi

    final List<Map<String, String>> vecizeler = [
      {
        'title': 'Birinci Söz',
        'book': 'Sözler',
        'text': 'Bismillah her hayrın başıdır. Biz dahi başta ona başlarız. Bil ey nefsim! Şu mübarek kelime İslâm nişanı olduğu gibi, bütün mevcudatın lisan-ı haliyle vird-i zebânıdır.',
      },
      {
        'title': 'İman ve Kuvvet',
        'book': 'Yirmi Üçüncü Söz',
        'text': 'İman hem nurdur, hem kuvvettir. Hakikî imanı elde eden adam, kâinata meydan okuyabilir ve imanın kuvvetine göre hâdisatın tazyikatından kurtulabilir.',
      },
      {
        'title': 'Güzel Gören Güzel Düşünür',
        'book': 'Mektubat',
        'text': 'Güzel gören güzel düşünür. Güzel düşünen, hayatından lezzet alır.',
      },
      {
        'title': 'Helâl Dairesi',
        'book': 'Asa-yı Musa',
        'text': 'Helâl dairesi geniştir, keyfe kâfi gelir. Harama girmeye hiç lüzum yoktur.',
      },
      {
        'title': 'Cennet ve Cehennem',
        'book': 'Mektubat',
        'text': 'Cennet ucuz değil, cehennem dahi lüzumsuz değil.',
      },
      {
        'title': 'Kader ve Rıza',
        'book': 'Kader Risalesi',
        'text': 'Kaderi tenkit eden, başını örse vurur kırar. Rahmete itiraz eden, rahmetten mahrum kalır.',
      },
      {
        'title': 'Rıza-yı İlâhî',
        'book': 'İhlas Risalesi',
        'text': 'Amelinizde rıza-yı İlâhî olmalı. Eğer O razı olsa, bütün dünya küsse ehemmiyeti yok.',
      },
      {
        'title': 'Muhabbet Fedaileri',
        'book': 'Tarihçe-i Hayat',
        'text': 'Biz muhabbet fedaileriyiz; husumete vaktimiz yoktur.',
      },
      {
        'title': 'Göz Penceresi',
        'book': 'Altıncı Söz',
        'text': 'Göz bir hassedir ki, ruh bu âlemi o pencere ile seyreder.',
      },
      {
        'title': 'Bahara Müjde',
        'book': 'Mektubat',
        'text': 'Her kışın bir baharı, her gecenin bir neharı vardır.',
      },
    ];

    final List<Map<String, String>> kapakYazilari = [
      {
        'title': 'Risale-i Nur Külliyatı',
        'book': 'Kapak Kitabesi',
        'text': 'Haza Kitab-ı Müstetab: Risale-i Nur Külliyatı • Bediüzzaman Said Nursi',
      },
      {
        'title': 'Mu\'cizat-ı Kur\'aniye',
        'book': 'Yirmi Beşinci Söz',
        'text': 'Yirmi Beşinci Söz • Mu\'cizat-ı Kur\'aniye Risalesi',
      },
      {
        'title': 'Asa-yı Musa',
        'book': 'Asa-yı Musa Kapağı',
        'text': 'Asa-yı Musa • Meyve Risalesi ve Hüccetü\'l-Bâliğa',
      },
      {
        'title': 'Mektubat-ı Nebeviyye',
        'book': 'Mektubat',
        'text': 'Mektubat • Risale-i Nur Külliyatından Hakikat Çeşmesi',
      },
      {
        'title': 'Lem\'alar Kitabesi',
        'book': 'Lem\'alar',
        'text': 'Lem\'alar • İhlas, Uhuvvet ve Hastalar Risalesi',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.sizeOf(context).height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF0F1428),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFF00F2FE), width: 1.5)),
              ),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF7F00FF)]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Risale & Hikmet Kütüphanesi',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                'Hazır vecizeler, kapak kitabeleri ve font rehberi',
                                style: TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Segment buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        _buildLibraryTabBtn(
                          label: 'Vecizeler',
                          icon: Icons.format_quote_rounded,
                          isSelected: selectedTab == 0,
                          onTap: () => setModalState(() => selectedTab = 0),
                        ),
                        const SizedBox(width: 6),
                        _buildLibraryTabBtn(
                          label: 'Kapak & Kitabe',
                          icon: Icons.auto_stories_rounded,
                          isSelected: selectedTab == 1,
                          onTap: () => setModalState(() => selectedTab = 1),
                        ),
                        const SizedBox(width: 6),
                        _buildLibraryTabBtn(
                          label: 'Font Rehberi',
                          icon: Icons.cloud_download_rounded,
                          isSelected: selectedTab == 2,
                          onTap: () => setModalState(() => selectedTab = 2),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),

                  // Content list
                  Expanded(
                    child: selectedTab == 2
                        ? _buildLibraryFontGuideView()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: selectedTab == 0 ? vecizeler.length : kapakYazilari.length,
                            itemBuilder: (context, idx) {
                              final item = selectedTab == 0 ? vecizeler[idx] : kapakYazilari[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161C36),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF222B50),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item['book']!,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF00F2FE),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item['title']!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      item['text']!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.92),
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.copy, size: 14),
                                          label: const Text('Kopyala', style: TextStyle(fontSize: 11)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white70,
                                            side: const BorderSide(color: Colors.white24),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: item['text']!));
                                            _showToast('Vecize panoya kopyalandı!');
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.check_circle_outline, size: 14),
                                          label: const Text('Karta Uygula', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF00F2FE),
                                            foregroundColor: const Color(0xFF090D1A),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _bodyController.text = item['text']!;
                                              _titleController.text = item['title']!;
                                              _selectedTitleFont = 'Risale Kapak (Gotik)';
                                              _selectedBodyFont = 'Risale Hat (Sülüs)';
                                              _selectedTextColor = Colors.white;
                                            });
                                            Navigator.pop(context);
                                            _showToast('Vecize karta uygulandı!');
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLibraryTabBtn({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF222B50) : const Color(0xFF141930),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF00F2FE) : Colors.white10,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? const Color(0xFF00F2FE) : Colors.white60),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF00F2FE) : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryFontGuideView() {
    const String fontUrl = 'https://sorularlarisale.com/kategori/risalelerde-kullanilan-fontlar';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161C36),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.font_download_rounded, color: Color(0xFF00F2FE), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Sorularla Risale Fontları Hakkında',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Risale-i Nur eserlerinde ve orijinal kapaklarında kullanılan başlıca font kategorileri:\n\n'
                '• Transkripsiyon Fontları: Osmanlıca ve Arapça özel harfleri (şapkalı â, î, û, dat, tı, zı, ayın, hemze) doğru gösterir.\n'
                '• Risale Kapak Fontları: Orijinal cilt kapaklarındaki Gotik Fraktur ve Kitabe hatları.\n'
                '• Klasik Hat Fontları: Sülüs, Nesih, Rika ve Kufi dijital hatları.\n\n'
                'Uygulamamız Google Fonts entegrasyonu ile bu fontların tamamını internete ihtiyaç duymadan cihazınızda anında render eder.',
                style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1022),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.link, size: 14, color: Color(0xFF00F2FE)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fontUrl,
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('İndirme Sayfası Linkini Kopyala', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00F2FE),
                        foregroundColor: const Color(0xFF090D1A),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: fontUrl));
                        _showToast('Sorularla Risale indirme linki kopyalandı!');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.share, size: 14),
                    label: const Text('Paylaş', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    ),
                    onPressed: () {
                      Share.share('Sorularla Risale Font İndirme Sayfası:\n$fontUrl');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openPreviewModal() {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: isTablet ? 80 : 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1326),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2A3356)),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedAccentColor.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00F2FE), Color(0xFF7F00FF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'CANLI ÖNİZLEME',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Paylaşım Kartı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Rendered Card Mockup wrapped in RepaintBoundary for image capture
                    // KULLANICI TALEBİ: "kart paylaşım ekranında başlık kısmı olmasın"
                    RepaintBoundary(
                      key: _previewCardRenderKey,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: _cardBgColor,
                          image: _customCardImageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_customCardImageBytes!),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withOpacity(0.55),
                                    BlendMode.darken,
                                  ),
                                )
                              : null,
                          borderRadius: BorderRadius.circular(_borderRadius),
                          border: Border.all(
                            color: _selectedAccentColor,
                            width: _borderThickness,
                          ),
                          boxShadow: _hasShadow
                              ? [
                                  BoxShadow(
                                    color: _selectedAccentColor.withOpacity(0.35),
                                    blurRadius: 20,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          _bodyController.text,
                          style: _getBodyStyle(fontSize: isTablet ? 17 : 15, isTablet: isTablet),
                          textAlign: _textAlign,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==========================================
                    // KART OLARAK PAYLAŞ (GÖRSEL - ULTRA HD PNG)
                    // ==========================================
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.image_rounded, size: 20),
                        label: const Text(
                          'KART OLARAK PAYLAŞ (GÖRSEL)',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F2FE),
                          foregroundColor: const Color(0xFF090D1A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 6,
                          shadowColor: const Color(0xFF00F2FE).withOpacity(0.5),
                        ),
                        onPressed: () {
                          _shareCardAsImage(targetKey: _previewCardRenderKey);
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: 15),
                            label: const Text('Metni Kopyala', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                text: _bodyController.text,
                              ));
                              _showToast('Metin panoya kopyalandı!');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.text_snippet_outlined, size: 15),
                            label: const Text('Metin Olarak Paylaş', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: () {
                              Share.share(_bodyController.text);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isTablet = screenSize.width >= 600;

    return Scaffold(
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7F00FF).withOpacity(0.18),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F2FE).withOpacity(0.15),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 780 : double.infinity),
                child: Column(
                  children: [
                    // Top App Bar
                    _buildTopAppBar(isTablet),

                    // Scrollable Content Studio Area
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 16,
                          vertical: isTablet ? 14 : 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Editable Title Area
                            _buildEditableTitleSection(isTablet),

                            const SizedBox(height: 14),

                            // Yüklenen Özel Dosya / Font / Resim Gösterge Bandı (Canlı Kart Üzerinde)
                            _buildActiveCustomFileBanner(isTablet),

                            // Dynamic Live Card (Wrapped in RepaintBoundary for card sharing)
                            RepaintBoundary(
                              key: _mainCardRenderKey,
                              child: _buildLiveCard(isTablet),
                            ),

                            const SizedBox(height: 18),

                            // Floating / Dock Toolbar (replicating the image overlay panel)
                            _buildFloatingToolbarDock(isTablet),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Navigation Bar
                    _buildBottomNavigationBar(isTablet),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Top App Bar ---
  Widget _buildTopAppBar([bool isTablet = false]) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 10 : 6,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white70),
            onPressed: () => _showToast('Geri dönüldü'),
          ),
          const SizedBox(width: 4),
          // Draft pill badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF161B30),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 12, color: Color(0xFF00F2FE)),
                SizedBox(width: 5),
                Text('DRAFT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              ],
            ),
          ),
          const Spacer(),
          // Dosya Seç Butonu (Kullanıcı talebi: dosya seç butonu)
          InkWell(
            onTap: _pickLocalFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF161E38),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.6)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open_rounded, size: 14, color: Color(0xFF00F2FE)),
                  SizedBox(width: 4),
                  Text(
                    'DOSYA SEÇ',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00F2FE)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Preview button
          InkWell(
            onTap: _openPreviewModal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FACFE), Color(0xFF7F00FF)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7F00FF).withOpacity(0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text('ÖNİZLEME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20, color: Colors.white70),
            onPressed: _openSettingsModal,
          ),
        ],
      ),
    );
  }

  // --- Editable Title Section ---
  Widget _buildEditableTitleSection([bool isTablet = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: TextField(
        controller: _titleController,
        style: _getTitleStyle(isTablet: isTablet),
        maxLines: null,
        cursorColor: _selectedAccentColor,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Başlık Yazınız...',
          hintStyle: TextStyle(color: Colors.white60),
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // --- Aktif Özel Dosya / Font / Resim Gösterge Bandı ---
  Widget _buildActiveCustomFileBanner([bool isTablet = false]) {
    if (_customFontDisplayName == null && _customCardImageBytes == null && _loadedFileName == null) {
      return const SizedBox.shrink();
    }

    final isFont = _customFontDisplayName != null;
    final isImage = _customCardImageBytes != null;

    String title;
    String subtitle;
    IconData icon;
    Color accentColor;

    if (isImage) {
      title = 'Özel Arka Plan Resmi Aktif';
      subtitle = _loadedFileName ?? 'Seçilen Görsel Karta Uygulandı';
      icon = Icons.image_rounded;
      accentColor = const Color(0xFF00F2FE);
    } else if (isFont) {
      title = 'Özel Font Karta Uygulandı';
      subtitle = '${_customFontDisplayName!} (Canlı Karta Aktif)';
      icon = Icons.font_download_rounded;
      accentColor = const Color(0xFF7F00FF);
    } else {
      title = 'Özel Metin Belgesi Yüklendi';
      subtitle = _loadedFileName ?? 'Metin Karta Aktarıldı';
      icon = Icons.text_snippet_rounded;
      accentColor = Colors.tealAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131936),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'KARTTA AKTİF',
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                if (isImage) {
                  _customCardImageBytes = null;
                  _showToast('Özel arka plan resmi kaldırıldı');
                } else if (isFont) {
                  _customLoadedFont = null;
                  _customFontDisplayName = null;
                  _selectedTitleFont = 'Risale Kapak (Gotik)';
                  _selectedBodyFont = 'Risale Hat (Sülüs)';
                  _showToast('Özel font kaldırıldı, varsayılana dönüldü');
                } else {
                  _loadedFileName = null;
                  _loadedFileType = null;
                  _showToast('Bildirim kapatıldı');
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, size: 12, color: Colors.redAccent),
                  SizedBox(width: 3),
                  Text(
                    'Kaldır',
                    style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Dynamic Live Card ---
  Widget _buildLiveCard([bool isTablet = false]) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        boxShadow: _hasShadow
            ? [
                BoxShadow(
                  color: _selectedAccentColor.withOpacity(0.4),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_borderRadius),
          gradient: _useGradientBorder
              ? LinearGradient(
                  colors: _presetGradients[_activeGradientIndex],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _useGradientBorder ? null : _selectedAccentColor,
        ),
        padding: EdgeInsets.all(_borderThickness),
        child: Container(
          decoration: BoxDecoration(
            color: _cardBgColor,
            image: _customCardImageBytes != null
                ? DecorationImage(
                    image: MemoryImage(_customCardImageBytes!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.55),
                      BlendMode.darken,
                    ),
                  )
                : null,
            borderRadius: BorderRadius.circular(_borderRadius - _borderThickness),
          ),
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Body text field (Karenin içi temiz: biçimlendirme araçları dock paneline taşındı)
              TextField(
                controller: _bodyController,
                style: _getBodyStyle(isTablet: isTablet),
                textAlign: _textAlign,
                maxLines: null,
                cursorColor: _selectedTextColor,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'İçeriğinizi buraya yazın...',
                  hintStyle: TextStyle(color: Colors.white60),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Mini Rich Toolbar inside card ---
  Widget _buildMiniRichToolbar([bool isTablet = false]) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8, vertical: isTablet ? 6 : 4),
      decoration: BoxDecoration(
        color: const Color(0xFF161C36),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bold
          _buildMiniToolbarBtn(
            label: 'A',
            isBold: true,
            isActive: _isBold,
            onTap: () => setState(() => _isBold = !_isBold),
          ),
          // Italic
          _buildMiniToolbarBtn(
            label: 'I',
            isItalic: true,
            isActive: _isItalic,
            onTap: () => setState(() => _isItalic = !_isItalic),
          ),
          // Underline
          _buildMiniToolbarBtn(
            label: 'U',
            isUnderline: true,
            isActive: _isUnderline,
            onTap: () => setState(() => _isUnderline = !_isUnderline),
          ),
          // Case
          _buildMiniToolbarBtn(
            label: 'Aa',
            isActive: false,
            onTap: _toggleCase,
          ),
          Container(width: 1, height: 16, color: Colors.white24),
          // Bullet list
          _buildMiniToolbarIcon(
            icon: Icons.format_list_bulleted,
            onTap: () {
              setState(() {
                _bodyController.text = '• ${_bodyController.text.replaceAll('\n', '\n• ')}';
              });
            },
          ),
          // Number list
          _buildMiniToolbarIcon(
            icon: Icons.format_list_numbered,
            onTap: () {
              final lines = _bodyController.text.split('\n');
              final numbered = lines.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');
              setState(() {
                _bodyController.text = numbered;
              });
            },
          ),
          // Alignment
          _buildMiniToolbarIcon(
            icon: _textAlign == TextAlign.left
                ? Icons.format_align_left
                : _textAlign == TextAlign.center
                    ? Icons.format_align_center
                    : Icons.format_align_right,
            onTap: _cycleAlignment,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniToolbarBtn({
    required String label,
    bool isBold = false,
    bool isItalic = false,
    bool isUnderline = false,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? _selectedAccentColor.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
            color: isActive ? _selectedAccentColor : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniToolbarIcon({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Icon(icon, size: 16, color: Colors.white70),
      ),
    );
  }

  // --- Floating Toolbar Dock (Mirroring the horizontal tool overlay) ---
  Widget _buildFloatingToolbarDock([bool isTablet = false]) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10152C).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF283256)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 18 : 14, vertical: isTablet ? 14 : 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // 1. YAZI BİÇİMİ (Karenin içinden dock alanına taşınan biçimlendirme)
            _buildDockSection(
              title: 'YAZI BİÇİMİ',
              child: Row(
                children: [
                  _buildDockIconButton(
                    label: 'B',
                    isActive: _isBold,
                    onTap: () {
                      setState(() => _isBold = !_isBold);
                      _showToast(_isBold ? 'Kalın (Bold) Açık' : 'Kalın Kapalı');
                    },
                  ),
                  const SizedBox(width: 5),
                  _buildDockIconButton(
                    label: 'I',
                    isItalic: true,
                    isActive: _isItalic,
                    onTap: () {
                      setState(() => _isItalic = !_isItalic);
                      _showToast(_isItalic ? 'İtalik Açık' : 'İtalik Kapalı');
                    },
                  ),
                  const SizedBox(width: 5),
                  _buildDockIconButton(
                    label: 'U',
                    isUnderline: true,
                    isActive: _isUnderline,
                    onTap: () {
                      setState(() => _isUnderline = !_isUnderline);
                      _showToast(_isUnderline ? 'Altı Çizili Açık' : 'Altı Çizili Kapalı');
                    },
                  ),
                  const SizedBox(width: 5),
                  _buildDockIconButton(
                    label: 'Aa',
                    isActive: false,
                    onTap: _toggleCase,
                  ),
                  const SizedBox(width: 5),
                  _buildDockSvgOrIcon(
                    icon: _textAlign == TextAlign.left
                        ? Icons.format_align_left
                        : _textAlign == TextAlign.center
                            ? Icons.format_align_center
                            : Icons.format_align_right,
                    onTap: _cycleAlignment,
                  ),
                  const SizedBox(width: 5),
                  _buildDockIconButton(
                    label: 'T',
                    hasGlow: true,
                    isActive: _hasTextGlow,
                    onTap: () {
                      setState(() => _hasTextGlow = !_hasTextGlow);
                      _showToast(_hasTextGlow ? 'Yazı Parlaması Açık' : 'Yazı Parlaması Kapalı');
                    },
                  ),
                ],
              ),
              sublabel: 'Kalın • İtalik • Hizala',
            ),

            _buildDockDivider(),

            // 2. YAZI RENGİ SEÇİMİ (Kullanıcı talebi: Yazı rengi seçme)
            _buildDockSection(
              title: 'YAZI RENGİ',
              child: Row(
                children: _textColorSwatches.map((c) {
                  final isSelected = _selectedTextColor.value == c.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTextColor = c;
                      });
                      _showToast('Yazı Rengi Değiştirildi');
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2.5)
                            : Border.all(color: Colors.white24, width: 1),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: c.withOpacity(0.8),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Center(
                              child: Icon(
                                Icons.check,
                                size: 13,
                                color: (c == Colors.white ||
                                        c == const Color(0xFFFFD700) ||
                                        c == const Color(0xFFFFF176) ||
                                        c == const Color(0xFF00FF88) ||
                                        c == const Color(0xFF00F2FE))
                                    ? Colors.black87
                                    : Colors.white,
                              ),
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              sublabel: 'Metin Rengi Seçimi',
            ),

            _buildDockDivider(),

            // 2. KART ZEMİNİ (Kullanıcı talebi: Lacivert ekran okunmuyor / Zemin & Kontrast)
            _buildDockSection(
              title: 'KART ZEMİNİ',
              child: Row(
                children: [
                  _buildCardBgDot(const Color(0xFF0F1428), 'Derin Lacivert', Colors.white),
                  _buildCardBgDot(const Color(0xFF070913), 'Asil Gece', Colors.white),
                  _buildCardBgDot(const Color(0xFFFAF7EE), 'Açık Parşömen', const Color(0xFF1E2433)),
                  _buildCardBgDot(const Color(0xFF051C14), 'Zümrüt Yeşil', const Color(0xFFFFD700)),
                  _buildCardBgDot(const Color(0xFF22080D), 'Bordo Cilt', const Color(0xFFFFD700)),
                ],
              ),
              sublabel: 'Zemin & Kontrast',
            ),

            _buildDockDivider(),

            // 3. DÜZENLEME & DOSYA SEÇ
            _buildDockSection(
              title: 'DÜZENLEME',
              child: Row(
                children: [
                  _buildDockSvgOrIcon(
                    icon: Icons.edit_outlined,
                    onTap: () => _showToast('Düzenleme aktif'),
                  ),
                  const SizedBox(width: 6),
                  _buildDockSvgOrIcon(
                    icon: Icons.folder_open_rounded,
                    iconColor: const Color(0xFF00F2FE),
                    onTap: _pickLocalFile,
                  ),
                  const SizedBox(width: 6),
                  _buildDockSvgOrIcon(
                    icon: Icons.format_clear,
                    onTap: () {
                      setState(() {
                        _isBold = false;
                        _isItalic = false;
                        _isUnderline = false;
                        _hasTextGlow = false;
                        _textAlign = TextAlign.left;
                      });
                      _showToast('Biçimlendirme temizlendi');
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildDockSvgOrIcon(
                    icon: Icons.auto_awesome,
                    iconColor: const Color(0xFF00F2FE),
                    onTap: _openAIModal,
                  ),
                ],
              ),
              sublabel: 'Düzenle • Dosya Seç',
            ),

            _buildDockDivider(),

            // 4. ÇERÇEVE PALETİ
            _buildDockSection(
              title: 'ÇERÇEVE PALETİ',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gradient preview bar
                  InkWell(
                    onTap: () {
                      setState(() {
                        _activeGradientIndex = (_activeGradientIndex + 1) % _presetGradients.length;
                        _useGradientBorder = true;
                        _selectedAccentColor = _presetGradients[_activeGradientIndex][0];
                      });
                      _showToast('Gradyan Geçişi Değiştirildi');
                    },
                    child: Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: _presetGradients[_activeGradientIndex]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Swatches
                  Row(
                    children: _paletteSwatches.map((c) {
                      final isSelected = _selectedAccentColor.value == c.value;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAccentColor = c;
                            _useGradientBorder = false;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            _buildDockDivider(),

            // 5. YAZI STİLİ (Zengin Font Çeşitleri & Dosya Seç)
            _buildDockSection(
              title: 'YAZI STİLİ',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Title Font dropdown
                      _buildFontDropdown(
                        value: _selectedTitleFont,
                        items: [
                          ..._fontOptions,
                          if (_customLoadedFont != null && !_fontOptions.contains(_customLoadedFont))
                            _customLoadedFont!,
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedTitleFont = val);
                            _showToast('Başlık Fontu: $val');
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      // Font Rehberi Butonu
                      InkWell(
                        onTap: _openSorularlaRisaleFontDialog,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 26,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B2346),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_download_outlined, size: 12, color: Color(0xFF00F2FE)),
                              SizedBox(width: 3),
                              Text('Font Rehberi', style: TextStyle(fontSize: 10, color: Color(0xFF00F2FE), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Body Font dropdown
                      _buildFontDropdown(
                        value: _selectedBodyFont,
                        items: [
                          ..._fontOptions,
                          if (_customLoadedFont != null && !_fontOptions.contains(_customLoadedFont))
                            _customLoadedFont!,
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedBodyFont = val);
                            _showToast('Metin Fontu: $val');
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      // Dosya Seç Butonu
                      InkWell(
                        onTap: _pickLocalFile,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 26,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B2346),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder_open_rounded, size: 12, color: Color(0xFF00F2FE)),
                              SizedBox(width: 3),
                              Text('Dosya Seç', style: TextStyle(fontSize: 10, color: Color(0xFF00F2FE), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              sublabel: 'Risale & Gotik Stiller',
            ),

            _buildDockDivider(),

            // 5. ÇERÇEVELEME
            _buildDockSection(
              title: 'ÇERÇEVELEME',
              child: Row(
                children: [
                  _buildFrameActionBtn(
                    icon: Icons.blur_on,
                    label: 'Gölge',
                    isActive: _hasShadow,
                    onTap: () {
                      setState(() => _hasShadow = !_hasShadow);
                      _showToast(_hasShadow ? 'Gölge Açık' : 'Gölge Kapalı');
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFrameActionBtn(
                    icon: Icons.line_weight,
                    label: 'Kalınlık',
                    isActive: _borderThickness > 1.5,
                    onTap: _cycleThickness,
                  ),
                  const SizedBox(width: 8),
                  _buildFrameActionBtn(
                    icon: Icons.rounded_corner,
                    label: 'Köşe',
                    isActive: _borderRadius > 12,
                    onTap: _cycleCorner,
                  ),
                ],
              ),
            ),

            _buildDockDivider(),

            // 6. PAYLAŞIM (KART OLARAK GÖRSEL PAYLAŞIM VE SOSYAL MEDYA)
            _buildDockSection(
              title: 'PAYLAŞIM',
              child: Row(
                children: [
                  // Özel Kart Olarak Görsel Paylaşım Butonu
                  InkWell(
                    onTap: () => _shareCardAsImage(targetKey: _mainCardRenderKey),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00F2FE), Color(0xFF7F00FF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F2FE).withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('KART PAYLAŞ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSocialBtn(
                    icon: Icons.facebook,
                    color: const Color(0xFF1877F2),
                    onTap: () => _shareCardAsImage(targetKey: _mainCardRenderKey),
                  ),
                  const SizedBox(width: 6),
                  _buildSocialBtn(
                    icon: Icons.alternate_email,
                    color: Colors.white,
                    onTap: () => _shareCardAsImage(targetKey: _mainCardRenderKey),
                  ),
                  const SizedBox(width: 6),
                  _buildSocialBtn(
                    icon: Icons.camera_alt_outlined,
                    color: const Color(0xFFE1306C),
                    onTap: () => _shareCardAsImage(targetKey: _mainCardRenderKey),
                  ),
                  const SizedBox(width: 6),
                  _buildSocialBtn(
                    icon: Icons.play_arrow_rounded,
                    color: const Color(0xFFFF0000),
                    onTap: () => _shareCardAsImage(targetKey: _mainCardRenderKey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockSection({required String title, required Widget child, String? sublabel}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        child,
        if (sublabel != null) ...[
          const SizedBox(height: 2),
          Text(sublabel, style: const TextStyle(fontSize: 9, color: Colors.white38)),
        ],
      ],
    );
  }

  Widget _buildDockDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 1,
      height: 48,
      color: Colors.white12,
    );
  }

  Widget _buildDockIconButton({
    required String label,
    bool isItalic = false,
    bool isUnderline = false,
    bool hasGlow = false,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF242E52) : const Color(0xFF161B32),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? _selectedAccentColor : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
            decorationColor: isActive ? _selectedAccentColor : Colors.white70,
            color: isActive ? _selectedAccentColor : Colors.white70,
            shadows: hasGlow
                ? [
                    Shadow(color: _selectedAccentColor, blurRadius: 10),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDockSvgOrIcon({required IconData icon, Color? iconColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF161B32),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, size: 16, color: iconColor ?? Colors.white70),
      ),
    );
  }

  Widget _buildFontDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : items.first;
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B32),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white70),
          dropdownColor: const Color(0xFF161B32),
          style: const TextStyle(fontSize: 11, color: Colors.white),
          items: items.map((f) {
            String label = f;
            if (f == _customLoadedFont) {
              label = '⭐ ${_customFontDisplayName ?? 'Özel Font'}';
            }
            return DropdownMenuItem(value: f, child: Text(label));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFrameActionBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF242E52) : const Color(0xFF161B32),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? _selectedAccentColor : Colors.white10,
              ),
            ),
            child: Icon(icon, size: 16, color: isActive ? _selectedAccentColor : Colors.white70),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54)),
      ],
    );
  }

  Widget _buildSocialBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF161B32),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  // --- Bottom Navigation Bar ---
  Widget _buildBottomNavigationBar([bool isTablet = false]) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0C1022),
        border: Border(top: BorderSide(color: Color(0xFF1A223E))),
      ),
      padding: EdgeInsets.symmetric(vertical: isTablet ? 10 : 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavTab(index: 0, label: 'Anasayfa', icon: Icons.home_rounded),
          _buildNavTab(index: 1, label: 'Kütüphane', icon: Icons.menu_book_rounded),
          _buildNavTab(index: 2, label: 'Şablonlar', icon: Icons.dashboard_customize_outlined),
          _buildNavTab(index: 3, label: 'Ayarlar', icon: Icons.settings_rounded),
        ],
      ),
    );
  }

  Widget _buildNavTab({required int index, required String label, required IconData icon}) {
    final isActive = _currentNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _currentNavIndex = index);
        if (index == 1) {
          _openLibraryModal();
        } else if (index == 2) {
          _openTemplatesModal();
        } else if (index == 3) {
          _openSettingsModal();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? const Color(0xFF00F2FE) : Colors.white60,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? const Color(0xFF00F2FE) : Colors.white60,
              ),
            ),
            const SizedBox(height: 2),
            if (isActive)
              Container(
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFF00F2FE),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF00F2FE), blurRadius: 4),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
