import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'core.dart';
import 'api.dart';

void _go(BuildContext c, Widget w) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => w));

void _err(BuildContext c, Object e) => ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(content: Text(e.toString()), backgroundColor: C.danger),
    );

PreferredSizeWidget _bar(String title) => AppBar(
      backgroundColor: C.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: C.text),
      title: Text(title, style: T.h2),
    );

InputDecoration _dec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: T.body.copyWith(color: C.text2),
      filled: true,
      fillColor: C.surface,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.border)),
    );

class ScoreRing extends StatelessWidget {
  final int score;
  final Risk risk;
  const ScoreRing(this.score, this.risk, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 88,
        height: 88,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 88,
            height: 88,
            child: CircularProgressIndicator(
                value: score / 100, strokeWidth: 8, color: risk.fg, backgroundColor: C.border),
          ),
          Text('$score', style: T.h1.copyWith(color: risk.fg)),
        ]),
      );
}

Risk _riskFromApi(String s) {
  switch (s) {
    case 'danger':
      return Risk.danger;
    case 'warn':
      return Risk.warn;
    default:
      return Risk.safe;
  }
}

// ================= Тексеру tab (hub) =================
class CheckHub extends StatelessWidget {
  const CheckHub({super.key});
  @override
  Widget build(BuildContext context) {
    Widget card(IconData ic, String t, String d, Widget page) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppCard(
            onTap: () => _go(context, page),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: C.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(ic, color: C.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: T.body.copyWith(fontWeight: FontWeight.w600)),
                Text(d, style: T.small),
              ])),
              const Icon(LucideIcons.chevronRight, color: C.text2),
            ]),
          ),
        );
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Тексеру', style: T.h1),
      const SizedBox(height: 8),
      Text('Не тексергіңіз келетінін таңдаңыз', style: T.small),
      const SizedBox(height: 24),
      card(LucideIcons.phone, 'Нөмір', 'Алаяқ нөмірін базадан тексеру', const NumberCheckScreen()),
      card(LucideIcons.link, 'Сілтеме', 'Фишинг сайтын ашпай тұрып анықтау', const LinkCheckScreen()),
      card(LucideIcons.messageSquare, 'Мәтін', 'SMS немесе чаттағы алаяқтық белгілері', const MessageCheckScreen()),
    ]);
  }
}

// ================= Number check =================
class NumberCheckScreen extends StatefulWidget {
  const NumberCheckScreen({super.key});
  @override
  State<NumberCheckScreen> createState() => _NumberCheckState();
}

class _NumberCheckState extends State<NumberCheckScreen> {
  final ctrl = TextEditingController();
  bool loading = false;
  Map<String, dynamic>? result;

  Future<void> _check() async {
    setState(() {
      loading = true;
      result = null;
    });
    try {
      final phone = normalizePhone(ctrl.text.trim());
      final r = await Api.checkNumber(phone);
      if (mounted) setState(() => result = r);
    } catch (e) {
      if (mounted) _err(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = result;
    final risk = r == null ? null : _riskFromApi(r['risk_level']);
    return Scaffold(
      appBar: _bar('Нөмірді тексеру'),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        TextField(
            controller: ctrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneMask()],
            style: T.body,
            decoration: _dec('7XX XXX XX XX').copyWith(prefixText: '+7  ')),
        const SizedBox(height: 16),
        AppButton('Тексеру', onTap: loading ? null : _check),
        const SizedBox(height: 24),
        if (loading) const Center(child: CircularProgressIndicator(color: C.primary)),
        if (r != null && risk != null)
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RiskBadge(risk,
                  text: risk == Risk.danger
                      ? 'Алаяқ болуы мүмкін'
                      : risk == Risk.warn
                          ? 'Тексерілмеген нөмір'
                          : 'Қауіпсіз'),
              const SizedBox(height: 12),
              Text(
                  risk == Risk.safe
                      ? 'Бұл нөмірге шағым жоқ'
                      : '${r['report_count']} адам шағымданған',
                  style: T.body),
              if ((r['top_category'] as String?)?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                Chip(label: Text(r['top_category'], style: T.caption)),
              ],
              if (risk != Risk.safe) ...[
                const SizedBox(height: 16),
                AppButton('Шағым жіберу',
                    kind: BtnKind.secondary,
                    onTap: () => showReportSheet(context, normalizePhone(ctrl.text.trim()))),
              ],
            ]),
          ),
      ]),
    );
  }
}

/// +7 dep bastalatyn nomirdi '7XX XXX XX XX' turinde formattaidy.
class PhoneMask extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nw) {
    var d = nw.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 10) d = d.substring(0, 10);
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 3 || i == 6 || i == 8) b.write(' ');
      b.write(d[i]);
    }
    final s = b.toString();
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

// ================= Report bottom sheet =================
void showReportSheet(BuildContext context, String phone) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ReportSheet(phone: phone),
      ),
    );

class ReportSheet extends StatefulWidget {
  final String phone;
  const ReportSheet({required this.phone, super.key});
  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  static const cats = ['Жалған банк', 'Қауіпсіз шот', 'Инвестиция', 'Полиция атынан', 'Жалған сатып алушы'];
  final commentCtrl = TextEditingController();
  String? cat;
  bool sent = false, loading = false;

  Future<void> _send() async {
    setState(() => loading = true);
    try {
      await Api.reportNumber(widget.phone, cat!, commentCtrl.text.trim());
      if (mounted) setState(() => sent = true);
    } catch (e) {
      if (mounted) _err(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: sent
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 16),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: C.safeBg, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.check, size: 36, color: C.safe),
                ),
                const SizedBox(height: 16),
                Text('Рахмет!', style: T.h1),
                const SizedBox(height: 8),
                Text('Шағымыңыз базаға қосылды. Сіз басқаларды қорғадыңыз.',
                    style: T.small, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                AppButton('Жабу', onTap: () => Navigator.pop(context)),
                const SizedBox(height: 16),
              ])
            : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Шағым жіберу', style: T.h2),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final c in cats)
                    GestureDetector(
                      onTap: () => setState(() => cat = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: cat == c ? C.primary : C.bg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: cat == c ? C.primary : C.border),
                        ),
                        child: Text(c,
                            style: T.small.copyWith(color: cat == c ? Colors.white : C.text)),
                      ),
                    ),
                ]),
                const SizedBox(height: 16),
                TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    style: T.body,
                    decoration: _dec('Түсініктеме (міндетті емес)')),
                const SizedBox(height: 16),
                loading
                    ? const Center(child: CircularProgressIndicator(color: C.primary))
                    : AppButton('Жіберу', onTap: cat == null ? null : _send),
                const SizedBox(height: 16),
              ]),
      );
}

// ================= Link checker =================
class LinkCheckScreen extends StatefulWidget {
  const LinkCheckScreen({super.key});
  @override
  State<LinkCheckScreen> createState() => _LinkCheckState();
}

class _LinkCheckState extends State<LinkCheckScreen> {
  final ctrl = TextEditingController();
  bool loading = false;
  Risk? risk;
  List<String> reasons = [];

  Future<void> _check() async {
    setState(() {
      loading = true;
      risk = null;
    });
    try {
      final r = await Api.checkUrl(ctrl.text.trim());
      if (mounted) {
        setState(() {
          risk = _riskFromApi(r['risk_level']);
          reasons = List<String>.from(r['reasons'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) _err(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = risk;
    return Scaffold(
      appBar: _bar('Сілтемені тексеру'),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        TextField(
          controller: ctrl,
          style: T.body,
          keyboardType: TextInputType.url,
          decoration: _dec('Сілтемені қойыңыз').copyWith(
            suffixIcon: IconButton(
              icon: const Icon(LucideIcons.clipboardPaste, color: C.primary),
              onPressed: () async {
                final d = await Clipboard.getData('text/plain');
                if (d?.text != null) setState(() => ctrl.text = d!.text!);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppButton('Тексеру', onTap: loading || ctrl.text.trim().isEmpty ? null : _check),
        const SizedBox(height: 24),
        if (loading)
          const Center(child: CircularProgressIndicator(color: C.primary))
        else if (v == null)
          AppCard(
            child: Row(children: [
              const Icon(LucideIcons.share2, color: C.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text('Kaspi чатынан сілтемені бөлісіңіз: «Бөлісу» → Qalqan',
                    style: T.small.copyWith(color: C.text)),
              ),
            ]),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: v.bg, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Icon(
                  v == Risk.safe
                      ? LucideIcons.shieldCheck
                      : v == Risk.warn
                          ? LucideIcons.alertCircle
                          : LucideIcons.shieldAlert,
                  size: 40,
                  color: v.fg),
              const SizedBox(height: 8),
              Text(
                  v == Risk.safe
                      ? 'Сілтеме қауіпсіз'
                      : v == Risk.warn
                          ? 'Сақ болыңыз'
                          : 'Қауіпті сілтеме',
                  style: T.h2.copyWith(color: v.fg)),
              const SizedBox(height: 8),
              Text(ctrl.text.trim(),
                  style: T.small.copyWith(color: C.text),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(height: 24),
          Text('Себептері', style: T.h2),
          const SizedBox(height: 8),
          for (final r in reasons)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(v == Risk.safe ? LucideIcons.checkCircle : LucideIcons.alertCircle,
                  color: v.fg),
              title: Text(r, style: T.body),
            ),
          const SizedBox(height: 16),
          if (v == Risk.danger) ...[
            AppButton('Сілтемені ашпаңыз', kind: BtnKind.danger, onTap: () => Navigator.pop(context)),
            const SizedBox(height: 16),
          ],
        ],
      ]),
    );
  }
}

// ================= Message checker =================
/// Backend jauabyndagy "signs" (aiaktyk belgisinin ataular) osy keste arkyly
/// matinnin ishinen tabylып, kyzylmen belgilenedi. Skorlaudy backend beredi.
const _signKeywords = {
  'Асығыс талап': ['шұғыл', 'дереу', '30 минут', 'срочно', 'немедленно', 'в течение'],
  'Код / карта деректерін сұрау': ['смс-код', 'sms код', 'cvv', 'пин', 'pin', 'cvc', 'құпия'],
  'Ресми емес сілтеме': ['http', 'www.', 'bit.ly', '.kz/', 'tinyurl'],
  '«Қауіпсіз шот» схемасы': ['қауіпсіз шот', 'безопасный счет', 'безопасный счёт'],
  'Жалған ұтыс / сыйлық': ['ұтып', 'ұтыс', 'сыйлық', 'выиграл', 'приз', 'бонус'],
  'Ресми органнан болып көрсету': ['полиция', 'прокуратура', 'қауіпсіздік қызметі', 'служба безопасности', 'сот'],
};

class MessageCheckScreen extends StatefulWidget {
  const MessageCheckScreen({super.key});
  @override
  State<MessageCheckScreen> createState() => _MessageCheckState();
}

class _MessageCheckState extends State<MessageCheckScreen> {
  final ctrl = TextEditingController();
  bool loading = false, done = false;
  int score = 0;
  Risk risk = Risk.safe;
  List<String> signs = [];
  List<List<int>> ranges = [];

  Future<void> _check() async {
  setState(() {
    loading = true;
    done = false;
  });

  try {
    final r = await Api.checkText(ctrl.text);
    final low = ctrl.text.toLowerCase();
    final found = List<String>.from(r['signs'] ?? []);
    final rr = <List<int>>[];
    for (final title in found) {
      final keywords =
          _signKeywords[title] ?? const <String>[];
      for (final String k in keywords) {
        int i = low.indexOf(k);
        while (i != -1) {
          rr.add([
            i,
            i + k.length,
          ]);
          i = low.indexOf(
            k,
            i + k.length,
          );
        }
      }
    }
    rr.sort(
      (a, b) => a[0].compareTo(b[0]),
    );
    final merged = <List<int>>[];
    for (final x in rr) {
      if (merged.isNotEmpty &&
          x[0] <= merged.last[1]) {
        merged.last[1] =
            max(merged.last[1], x[1]);
      } else {
        merged.add(x);
      }
    }
    if (mounted) {
      setState(() {
        score = r['score'] ?? 0;
        risk = _riskFromApi(r['risk_level']);
        signs = found;
        ranges = merged;
        done = true;
      });
    }
  } catch (e) {
    if (mounted) {
      _err(context, e);
    }
  } finally {
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }
}

  Widget _highlighted() {
    final text = ctrl.text;
    final spans = <InlineSpan>[];
    var pos = 0;
    for (final r in ranges) {
      if (r[0] > pos) spans.add(TextSpan(text: text.substring(pos, r[0])));
      spans.add(TextSpan(
          text: text.substring(r[0], r[1]),
          style: const TextStyle(backgroundColor: C.dangerBg, color: C.danger, fontWeight: FontWeight.w600)));
      pos = r[1];
    }
    if (pos < text.length) spans.add(TextSpan(text: text.substring(pos)));
    return RichText(text: TextSpan(style: T.body, children: spans));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _bar('Мәтінді тексеру'),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          TextField(
              controller: ctrl,
              maxLines: 6,
              style: T.body,
              onChanged: (_) => setState(() => done = false),
              decoration: _dec('Хабарламаны қойыңыз')),
          const SizedBox(height: 16),
          AppButton('Тексеру', onTap: loading || ctrl.text.trim().isEmpty ? null : _check),
          const SizedBox(height: 24),
          if (loading) const Center(child: CircularProgressIndicator(color: C.primary)),
          if (done) ...[
            AppCard(
              child: Row(children: [
                ScoreRing(score, risk),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  RiskBadge(risk),
                  const SizedBox(height: 8),
                  Text(
                      signs.isEmpty
                          ? 'Алаяқтық белгілері табылмады'
                          : '${signs.length} алаяқтық белгісі табылды',
                      style: T.small.copyWith(color: C.text)),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
            AppCard(child: SizedBox(width: double.infinity, child: _highlighted())),
            if (signs.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Алаяқтық белгілері', style: T.h2),
              const SizedBox(height: 8),
              for (final s in signs)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.alertTriangle, color: C.danger),
                  title: Text(s, style: T.body),
                ),
            ],
          ],
        ]),
      );
}