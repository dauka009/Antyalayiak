import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'core.dart';
import 'api.dart';
import 'auth.dart';
import 'checks.dart';
import 'rest.dart';

// ---------- Splash ----------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final loggedIn = await Api.restoreSession();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => loggedIn ? const Shell() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.primary,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.shield, size: 72, color: Colors.white),
            const SizedBox(height: 16),
            Text('Qalqan', style: T.display.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Алаяқтан қорғайтын ақылды қалқан',
                style: T.small.copyWith(color: Colors.white70)),
          ]),
        ),
      );
}

// ---------- Shell (bottom nav) ----------
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    const pages = [HomeScreen(), CheckHub(), StatsScreen(), HistoryScreen(), ProfileScreen()];
    return Scaffold(
      body: SafeArea(child: pages[i]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        backgroundColor: C.surface,
        indicatorColor: C.primary.withOpacity(0.12),
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.home), label: 'Басты бет'),
          NavigationDestination(icon: Icon(LucideIcons.search), label: 'Тексеру'),
          NavigationDestination(icon: Icon(LucideIcons.shieldCheck), label: 'Қалқан'),
          NavigationDestination(icon: Icon(LucideIcons.history), label: 'Тарих'),
          NavigationDestination(icon: Icon(LucideIcons.user), label: 'Профиль'),
        ],
      ),
    );
  }
}

// ---------- Home ----------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<ApiTx>> future;

  @override
  void initState() {
    super.initState();
    future = Api.listTransactions();
  }

  Future<void> _refresh() async {
    setState(() => future = Api.listTransactions());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData ic, String t, Widget page) => Expanded(
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
            child: Column(children: [
              Icon(ic, color: C.primary),
              const SizedBox(height: 8),
              Text(t, textAlign: TextAlign.center, style: T.caption.copyWith(color: C.text)),
            ]),
          ),
        );

    return RefreshIndicator(
      onRefresh: _refresh,
      color: C.primary,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Сәлем!', style: T.h1),
        const SizedBox(height: 16),
        AppCard(
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: C.safeBg, shape: BoxShape.circle),
              child: const Icon(LucideIcons.shieldCheck, color: C.safe),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Қорғаныс қосулы ✓', style: T.h2),
              Text('Барлық қабаттар белсенді', style: T.small),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          tile(LucideIcons.phone, 'Нөмірді\nтексеру', const NumberCheckScreen()),
          const SizedBox(width: 16),
          tile(LucideIcons.link, 'Сілтемені\nтексеру', const LinkCheckScreen()),
          const SizedBox(width: 16),
          tile(LucideIcons.messageSquare, 'Мәтінді\nтексеру', const MessageCheckScreen()),
        ]),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Соңғы аударымдар', style: T.h2),
          TextButton(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const TransactionsScreen())),
            child: Text('Барлығы', style: T.small.copyWith(color: C.primary)),
          ),
        ]),
        FutureBuilder<List<ApiTx>>(
          future: future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(color: C.primary)),
              );
            }
            if (snap.hasError) {
              return AppCard(
                child: Column(children: [
                  Text('Транзакцияларды жүктеу мүмкін болмады', style: T.small),
                  const SizedBox(height: 8),
                  Text('${snap.error}', style: T.caption, textAlign: TextAlign.center),
                ]),
              );
            }
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: EmptyState('Транзакция әлі жоқ'),
              );
            }
            return Column(children: [
              for (final t in list.take(5))
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: AppCard(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => TxDetailScreen(tx: t))),
                    child: Row(children: [
                      Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t.recipient.isEmpty ? 'Белгісіз алушы' : t.recipient,
                            style: T.body.copyWith(fontWeight: FontWeight.w600)),
                        Text(t.city, style: T.small),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(tenge(t.amount.round()), style: T.body.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        RiskBadge(t.risk),
                      ]),
                    ]),
                  ),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}