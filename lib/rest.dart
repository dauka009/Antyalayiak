import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'core.dart';
import 'api.dart';
import 'auth.dart'; // OnboardingScreen (logout ushin)
import 'checks.dart'; // ScoreRing, showReportSheet

void _go(BuildContext c, Widget w) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => w));

void _err(BuildContext c, Object e) => ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(content: Text(e.toString()), backgroundColor: C.danger),
    );

PreferredSizeWidget _bar(String t, {List<Widget>? actions, PreferredSizeWidget? bottom}) => AppBar(
      backgroundColor: C.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: C.text),
      title: Text(t, style: T.h2),
      actions: actions,
      bottom: bottom,
    );

Widget _row(IconData ic, String title, {String? sub, Color color = C.primary, Widget? trailing, VoidCallback? onTap}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Row(children: [
          Icon(ic, color: color),
          const SizedBox(width: 16),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: T.body.copyWith(fontWeight: FontWeight.w600)),
            if (sub != null) Text(sub, style: T.small),
          ])),
          trailing ?? (onTap != null ? const Icon(LucideIcons.chevronRight, color: C.text2) : const SizedBox()),
        ]),
      ),
    );

// ================= States =================
class EmptyState extends StatelessWidget {
  final String text;
  const EmptyState(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.shieldCheck, size: 56, color: C.safe),
          const SizedBox(height: 16),
          Text(text, style: T.body.copyWith(color: C.text2), textAlign: TextAlign.center),
        ]),
      );
}

class ErrorState extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;
  const ErrorState(this.text, this.onRetry, {super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.wifiOff, size: 56, color: C.text2),
            const SizedBox(height: 16),
            Text(text, style: T.body, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            AppButton('Қайталау', onTap: onRetry),
          ]),
        ),
      );
}

// ================= Transactions =================
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsState();
}

class _TransactionsState extends State<TransactionsScreen> {
  Risk? filter;
  late Future<List<ApiTx>> future;

  @override
  void initState() {
    super.initState();
    future = Api.listTransactions();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _bar('Аударымдар'),
        body: Column(children: [
          SizedBox(
            height: 48,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
              for (final f in <Risk?>[null, Risk.safe, Risk.warn, Risk.danger])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f == null ? 'Барлығы' : f.label),
                    selected: filter == f,
                    onSelected: (_) => setState(() => filter = f),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: FutureBuilder<List<ApiTx>>(
              future: future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: C.primary));
                }
                if (snap.hasError) {
                  return ErrorState('${snap.error}',
                      () => setState(() => future = Api.listTransactions()));
                }
                final list = (snap.data ?? [])
                    .where((t) => filter == null || t.risk == filter)
                    .toList();
                if (list.isEmpty) return const EmptyState('Аударым табылмады');
                return ListView(padding: const EdgeInsets.all(20), children: [
                  for (final t in list)
                    _row(LucideIcons.arrowUpRight, t.recipient.isEmpty ? 'Белгісіз алушы' : t.recipient,
                        sub: t.city,
                        color: t.risk.fg,
                        trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(tenge(t.amount.round()), style: T.body.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          RiskBadge(t.risk),
                        ]),
                        onTap: () => _go(context, TxDetailScreen(tx: t))),
                ]);
              },
            ),
          ),
        ]),
      );
}

class TxDetailScreen extends StatefulWidget {
  final ApiTx tx;
  const TxDetailScreen({required this.tx, super.key});
  @override
  State<TxDetailScreen> createState() => _TxDetailState();
}

class _TxDetailState extends State<TxDetailScreen> {
  bool loading = false;

  Future<void> _decide(String action) async {
    setState(() => loading = true);
    try {
      await Api.decideTransaction(widget.tx.id, action);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _err(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  static const _icons = {
    'Сома әдеттегіден 5+ есе көп': LucideIcons.trendingUp,
    'Сома әдеттегіден 2+ есе көп': LucideIcons.trendingUp,
    'Жаңа алушы': LucideIcons.userPlus,
    'Жаңа құрылғы': LucideIcons.smartphone,
    'Түнгі уақыт': LucideIcons.moon,
  };

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    return Scaffold(
      appBar: _bar('Аударым'),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        AppCard(
          child: Row(children: [
            ScoreRing(tx.riskScore, tx.risk),
            const SizedBox(width: 16),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tenge(tx.amount.round()), style: T.h1),
              Text(tx.recipient.isEmpty ? 'Белгісіз алушы' : tx.recipient, style: T.small),
              Text(tx.city, style: T.small),
            ])),
          ]),
        ),
        const SizedBox(height: 24),
        Text(tx.risk == Risk.safe ? 'Талдау' : 'Неге күмәнді?', style: T.h2),
        const SizedBox(height: 12),
        if (tx.reasons.isEmpty)
          _row(LucideIcons.checkCircle, 'Әдеттегі сома және таныс алушы', color: C.safe)
        else
          for (final r in tx.reasons) _row(_icons[r] ?? LucideIcons.alertCircle, r, color: tx.risk.fg),
        if (tx.status != 'pending') ...[
          const SizedBox(height: 16),
          AppCard(
            child: Row(children: [
              Icon(tx.status == 'confirmed' ? LucideIcons.checkCircle : LucideIcons.shieldOff,
                  color: tx.status == 'confirmed' ? C.safe : C.danger),
              const SizedBox(width: 12),
              Text(tx.status == 'confirmed' ? 'Растадыңыз' : 'Аударым блокталды', style: T.body),
            ]),
          ),
        ] else if (tx.risk != Risk.safe) ...[
          const SizedBox(height: 16),
          if (loading)
            const Center(child: CircularProgressIndicator(color: C.primary))
          else ...[
            AppButton('Бұл мен', onTap: () => _decide('confirm')),
            const SizedBox(height: 16),
            AppButton('Бұл мен емес — блоктау', kind: BtnKind.danger, onTap: () => _decide('block')),
          ],
        ],
      ]),
    );
  }
}

// ================= History =================
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    Widget list(List<(IconData, String, String, Risk)> items) => items.isEmpty
        ? const EmptyState('Әзірге ескерту жоқ')
        : ListView(padding: const EdgeInsets.all(20), children: [
            for (final i in items)
              _row(i.$1, i.$2, sub: i.$3, color: i.$4.fg, trailing: RiskBadge(i.$4)),
          ]);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: _bar('Тарих',
            bottom: const TabBar(
                labelColor: C.primary,
                indicatorColor: C.primary,
                tabs: [Tab(text: 'Қоңыраулар'), Tab(text: 'Сілтемелер'), Tab(text: 'Аударымдар')])),
        body: TabBarView(children: [
          list(const [
            (LucideIcons.phoneIncoming, '+7 701 234 56 70', 'Бүгін, 14:02', Risk.danger),
            (LucideIcons.phoneIncoming, '+7 747 111 22 35', 'Кеше, 10:15', Risk.warn),
          ]),
          list(const []),
          FutureBuilder<List<ApiTx>>(
            future: Api.listTransactions(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: C.primary));
              }
              final rows = snap.data ?? [];
              return list([
                for (final t in rows)
                  (LucideIcons.arrowUpRight, t.recipient.isEmpty ? 'Белгісіз алушы' : t.recipient,
                      t.city, t.risk)
              ]);
            },
          ),
        ]),
      ),
    );
  }
}

// ================= Stats (Қалқан tab) =================
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const months = ['Сәу', 'Науб', 'Жел', 'Там', 'Қыр', 'Қаз'];
    const vals = [3, 5, 2, 7, 4, 9];
    const cats = [('Жалған банк', 0.4), ('Қауіпсіз шот', 0.25), ('Инвестиция', 0.2), ('Басқа', 0.15)];
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Қалқан', style: T.h1),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: C.primary, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Сіз сақтап қалдыңыз', style: T.small.copyWith(color: Colors.white70)),
          Text(tenge(1250000), style: T.display.copyWith(color: Colors.white)),
        ]),
      ),
      const SizedBox(height: 24),
      Text('Бұғатталған қауіптер', style: T.h2),
      const SizedBox(height: 12),
      AppCard(
        child: SizedBox(
          height: 160,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            for (var i = 0; i < months.length; i++)
              Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${vals[i]}', style: T.caption),
                const SizedBox(height: 4),
                Container(
                    width: 28,
                    height: vals[i] * 12.0,
                    decoration: BoxDecoration(color: C.primary, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 4),
                Text(months[i], style: T.caption),
              ]),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      Text('Алаяқтық түрлері', style: T.h2),
      const SizedBox(height: 12),
      AppCard(
        child: Column(children: [
          for (final c in cats)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(c.$1, style: T.small.copyWith(color: C.text)),
                  Text('${(c.$2 * 100).round()}%', style: T.small),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(value: c.$2, minHeight: 8, color: C.primary, backgroundColor: C.border)),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

// ================= Education =================
class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});
  static const items = [
    (LucideIcons.landmark, 'Жалған банк қызметкері',
        'Алаяқ банк атынан қоңырау шалып, «картаңыз бұғатталды» дейді. Банк ешқашан SMS-код, CVV немесе PIN сұрамайды. Қоңырауды тоқтатып, банктің ресми нөміріне өзіңіз хабарласыңыз.'),
    (LucideIcons.shieldAlert, '«Қауіпсіз шот» схемасы',
        'Сізге ақшаны «қауіпсіз шотқа» аудар дейді. Бұл әрқашан алдау. Ешбір банк немесе полиция мұндай талап қоймайды.'),
    (LucideIcons.link, 'Фишинг сілтемелер',
        'kaspi-pay.kz сияқты ұқсас домендерге сақ болыңыз. Сілтемені ашпай тұрып Qalqan арқылы тексеріңіз.'),
    (LucideIcons.trendingUp, 'Жалған инвестиция',
        '«Кепілдендірілген жоғары табыс» уәдесі алаяқтық белгісі. Лицензиясыз ұйымдарға ақша салмаңыз.'),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _bar('Қауіпсіздік кеңестері'),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          for (final i in items)
            _row(i.$1, i.$2, onTap: () => _go(context, ArticleScreen(i.$2, i.$3))),
        ]),
      );
}

class ArticleScreen extends StatelessWidget {
  final String title, body;
  const ArticleScreen(this.title, this.body, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _bar('Кеңес'),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(title, style: T.h1),
          const SizedBox(height: 16),
          Text(body, style: T.body),
        ]),
      );
}

// ================= Profile & Settings =================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        const SizedBox(height: 8),
        Center(
          child: Column(children: [
            const CircleAvatar(
                radius: 40,
                backgroundColor: C.primary,
                child: Icon(LucideIcons.user, size: 36, color: Colors.white)),
            const SizedBox(height: 12),
            Text(Api.phone ?? '', style: T.h2),
          ]),
        ),
        const SizedBox(height: 24),
        _row(LucideIcons.settings, 'Баптаулар', onTap: () => _go(context, const SettingsScreen())),
        _row(LucideIcons.arrowLeftRight, 'Аударымдар', onTap: () => _go(context, const TransactionsScreen())),
        _row(LucideIcons.bookOpen, 'Қауіпсіздік кеңестері', onTap: () => _go(context, const EducationScreen())),
        const SizedBox(height: 12),
        Text('Демо экрандар', style: T.caption),
        const SizedBox(height: 8),
        _row(LucideIcons.phoneIncoming, 'Қоңырау ескертуі (қауіпті)', onTap: () => _go(context, const CallOverlayScreen(danger: true))),
        _row(LucideIcons.phoneIncoming, 'Қоңырау ескертуі (белгісіз)', onTap: () => _go(context, const CallOverlayScreen(danger: false))),
        _row(LucideIcons.link2, 'Біріккен қауіп', onTap: () => _go(context, const CombinedRiskScreen())),
      ]);
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  bool notif = true, bio = true;
  double limit = 500000;
  String lang = 'kk';

  Widget _sw(String t, bool v, ValueChanged<bool> f) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          child: Row(children: [
            Expanded(child: Text(t, style: T.body)),
            Switch(value: v, activeColor: C.primary, onChanged: f),
          ]),
        ),
      );

  Future<void> _logout(BuildContext context) async {
    await Api.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _bar('Баптаулар'),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          _sw('Хабарламалар', notif, (v) => setState(() => notif = v)),
          _sw('Биометрия', bio, (v) => setState(() => bio = v)),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Аударым лимиті', style: T.body.copyWith(fontWeight: FontWeight.w600)),
              Text('Одан асса ескерту шығады: ${tenge(limit.round())}', style: T.small),
              Slider(value: limit, min: 50000, max: 2000000, divisions: 39, activeColor: C.primary, onChanged: (v) => setState(() => limit = v)),
            ]),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Тіл', style: T.body.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [ButtonSegment(value: 'kk', label: Text('Қазақша')), ButtonSegment(value: 'ru', label: Text('Русский'))],
                selected: {lang},
                onSelectionChanged: (s) => setState(() => lang = s.first),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          _row(LucideIcons.users, 'Сенімді алушылар', onTap: () {}),
          _row(LucideIcons.lock, 'Дербес деректер', onTap: () {}),
          const SizedBox(height: 12),
          AppButton('Шығу', kind: BtnKind.danger, onTap: () => showDialog(
                context: context,
                builder: (dCtx) => AlertDialog(
                  title: Text('Шығасыз ба?', style: T.h2),
                  content: Text('Қорғаныс өшірілуі мүмкін.', style: T.body),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Жоқ')),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(dCtx);
                          _logout(context);
                        },
                        child: const Text('Иә', style: TextStyle(color: C.danger))),
                  ],
                ),
              )),
        ]),
      );
}

// ================= Incoming call overlay (UI demo) =================
class CallOverlayScreen extends StatelessWidget {
  final bool danger;
  const CallOverlayScreen({required this.danger, super.key});
  @override
  Widget build(BuildContext context) {
    const demoPhone = '+77012345670';
    final r = danger ? Risk.danger : Risk.warn;
    return Scaffold(
      backgroundColor: C.text,
      body: Column(children: [
        Container(
          width: double.infinity,
          color: r.fg,
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: Text(danger ? '⚠️ Алаяқ болуы мүмкін — 240 шағым' : '⚠️ Тексерілмеген нөмір',
              style: T.h2.copyWith(color: Colors.white), textAlign: TextAlign.center),
        ),
        const Spacer(),
        const CircleAvatar(radius: 48, backgroundColor: Color(0xFF1E293B), child: Icon(LucideIcons.user, size: 48, color: Colors.white54)),
        const SizedBox(height: 16),
        Text('+7 701 234 56 70', style: T.h1.copyWith(color: Colors.white)),
        Text('Кіріс қоңырау...', style: T.small.copyWith(color: Colors.white60)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            AppButton('Қабылдамау', kind: BtnKind.danger, onTap: () => Navigator.pop(context)),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(backgroundColor: const Color(0xFF334155), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () => Navigator.pop(context),
                child: Text('Бәрібір жауап беру', style: T.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            TextButton(
                onPressed: () => showReportSheet(context, demoPhone),
                child: Text('Шағым жіберу', style: T.small.copyWith(color: Colors.white70))),
            const SizedBox(height: 24),
          ]),
        ),
      ]),
    );
  }
}

// ================= Combined risk =================
class CombinedRiskScreen extends StatelessWidget {
  const CombinedRiskScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const steps = [
      (LucideIcons.phone, 'Қоңырау', '10 минут бұрын, күмәнді нөмір'),
      (LucideIcons.link, 'Сілтеме', 'Фишинг домен ашылды'),
      (LucideIcons.arrowUpRight, 'Аударым', '450 000 ₸, жаңа алушы'),
    ];
    return Scaffold(
      appBar: _bar('Біріккен қауіп'),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: C.dangerBg, borderRadius: BorderRadius.circular(16)),
          child: Text('10 минут бұрын күмәнді нөмірмен сөйлестіңіз, енді жаңа алушыға үлкен сома аударып жатырсыз.',
              style: T.body.copyWith(color: C.danger, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < steps.length; i++) ...[
          Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: C.dangerBg, shape: BoxShape.circle),
              child: Icon(steps[i].$1, color: C.danger),
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(steps[i].$2, style: T.body.copyWith(fontWeight: FontWeight.w600)),
              Text(steps[i].$3, style: T.small),
            ]),
          ]),
          if (i < steps.length - 1) Padding(padding: const EdgeInsets.only(left: 23), child: Container(width: 2, height: 24, color: C.border)),
        ],
        const SizedBox(height: 32),
        AppButton('Блоктау', kind: BtnKind.danger, onTap: () => Navigator.pop(context)),
        const SizedBox(height: 16),
        AppButton('Бұл мен', kind: BtnKind.secondary, onTap: () => Navigator.pop(context)),
      ]),
    );
  }
}