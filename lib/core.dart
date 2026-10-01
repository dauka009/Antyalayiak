import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Дизайн жүйесі: бір ғана шрифт (Inter), бекітілген түстер.
class C {
  static const primary = Color(0xFF2A5BFF);
  static const primaryDark = Color(0xFF1B3FCC);
  static const bg = Color(0xFFF6F8FC);
  static const surface = Colors.white;
  static const text = Color(0xFF0F172A);
  static const text2 = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const safe = Color(0xFF16A34A);
  static const safeBg = Color(0xFFDCFCE7);
  static const warn = Color(0xFFF59E0B);
  static const warnBg = Color(0xFFFEF3C7);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEE2E2);
}

class T {
  static TextStyle _s(double size, double lh, FontWeight w, [Color c = C.text]) =>
      GoogleFonts.inter(fontSize: size, height: lh / size, fontWeight: w, color: c);
  static final display = _s(32, 40, FontWeight.w700);
  static final h1 = _s(24, 32, FontWeight.w700);
  static final h2 = _s(20, 28, FontWeight.w600);
  static final body = _s(16, 24, FontWeight.w400);
  static final small = _s(14, 20, FontWeight.w400, C.text2);
  static final caption = _s(12, 16, FontWeight.w500, C.text2);
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: C.bg,
      colorScheme: ColorScheme.fromSeed(seedColor: C.primary),
      textTheme: GoogleFonts.interTextTheme().apply(bodyColor: C.text, displayColor: C.text),
    );

enum Risk { safe, warn, danger }

extension RiskX on Risk {
  Color get fg => [C.safe, C.warn, C.danger][index];
  Color get bg => [C.safeBg, C.warnBg, C.dangerBg][index];
  String get label => ['Қауіпсіз', 'Күмәнді', 'Қауіпті'][index];
}

class RiskBadge extends StatelessWidget {
  final Risk risk;
  final String? text;
  const RiskBadge(this.risk, {this.text, super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: risk.bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text ?? risk.label, style: T.caption.copyWith(color: risk.fg)),
      );
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const AppCard({required this.child, this.padding = const EdgeInsets.all(16), this.onTap, super.key});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), offset: Offset(0, 2), blurRadius: 12)],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}

enum BtnKind { primary, secondary, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final BtnKind kind;
  const AppButton(this.label, {this.onTap, this.kind = BtnKind.primary, super.key});
  @override
  Widget build(BuildContext context) {
    final filled = kind != BtnKind.secondary;
    final bg = kind == BtnKind.danger ? C.danger : C.primary;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: filled ? bg : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: filled ? BorderSide.none : const BorderSide(color: C.primary, width: 1.5),
          ),
        ),
        child: Text(label,
            style: T.body.copyWith(
                fontWeight: FontWeight.w600, color: filled ? Colors.white : C.primary)),
      ),
    );
  }
}

class Tx {
  final String name, time, city;
  final int amount;
  final Risk risk;
  const Tx(this.name, this.amount, this.time, this.city, this.risk);
}

const demoTx = [
  Tx('Белгісіз алушы', 450000, 'Бүгін, 02:14', 'Алматы', Risk.danger),
  Tx('Magnum', 12400, 'Бүгін, 12:30', 'Астана', Risk.safe),
  Tx('Kaspi Red', 85000, 'Кеше, 19:05', 'Астана', Risk.warn),
];

/// '7XX XXX XX XX' turindegi maskalangan nomirdi backend kutetin
/// '+7XXXXXXXXXX' turine keltiredi.
String normalizePhone(String masked) => '+7${masked.replaceAll(' ', '')}';

String tenge(int v) {
  final s = v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
  return '$s ₸';
}