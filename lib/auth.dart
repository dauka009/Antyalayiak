import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'core.dart';
import 'api.dart';
import 'screens.dart'; // Shell

void _go(BuildContext c, Widget w) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => w));

void _err(BuildContext c, Object e) => ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(content: Text(e.toString()), backgroundColor: C.danger),
    );

PreferredSizeWidget _bar() => AppBar(
      backgroundColor: C.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: C.text),
    );

Widget _iconCircle(IconData ic, {Color bg = const Color(0x1F2A5BFF), Color fg = C.primary}) =>
    Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(ic, size: 56, color: fg),
    );

// ================= 1. Onboarding =================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends State<OnboardingScreen> {
  final ctrl = PageController();
  int page = 0;

  static const slides = [
    (LucideIcons.shieldCheck, 'Күмәнді аударымды алдын ала тоқтатамыз',
        'AI әр операцияны бағалап, қауіп болса бірден ескертеді.'),
    (LucideIcons.phoneIncoming, 'Белгісіз нөмірдің алаяқ екенін бірден көрсетеміз',
        'Қоңырау кезінде ортақ база мен AI нөмірді тексереді.'),
    (LucideIcons.link, 'Күдікті сілтемені ашпай тұрып тексеріңіз',
        'Kaspi немесе басқа чаттан келген сілтемені бөлісіп, тексеріңіз.'),
  ];

  void _finish() => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const RegisterScreen()));

  @override
  Widget build(BuildContext context) {
    final last = page == slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('Өткізу', style: T.small.copyWith(color: C.primary)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: ctrl,
                itemCount: slides.length,
                onPageChanged: (v) => setState(() => page = v),
                itemBuilder: (_, i) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _iconCircle(slides[i].$1),
                    const SizedBox(height: 40),
                    Text(slides[i].$2, textAlign: TextAlign.center, style: T.h1),
                    const SizedBox(height: 16),
                    Text(slides[i].$3, textAlign: TextAlign.center, style: T.body.copyWith(color: C.text2)),
                  ],
                ),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.all(4),
                  width: i == page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: i == page ? C.primary : C.border,
                      borderRadius: BorderRadius.circular(999)),
                ),
            ]),
            const SizedBox(height: 24),
            AppButton(last ? 'Бастау' : 'Келесі', onTap: () {
              if (last) {
                _finish();
              } else {
                ctrl.nextPage(
                    duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              }
            }),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}

// ================= 2. Registration =================
class PhoneFormatter extends TextInputFormatter {
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterScreen> {
  final ctrl = TextEditingController();
  bool agree = false, loading = false;
  bool get valid => ctrl.text.replaceAll(' ', '').length == 10 && agree;

  Future<void> _submit() async {
    setState(() => loading = true);
    final phone = normalizePhone(ctrl.text);
    try {
      final devCode = await Api.register(phone);
      if (!mounted) return;
      _go(context, OtpScreen(phone: phone, devCode: devCode));
    } catch (e) {
      if (mounted) _err(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _bar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 16),
              Text('Тіркелу', style: T.h1),
              const SizedBox(height: 8),
              Text('Телефон нөміріңізді енгізіңіз, SMS-код жібереміз.', style: T.small),
              const SizedBox(height: 32),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneFormatter()],
                onChanged: (_) => setState(() {}),
                style: T.body,
                decoration: InputDecoration(
                  prefixText: '+7  ',
                  prefixStyle: T.body,
                  hintText: '7XX XXX XX XX',
                  filled: true,
                  fillColor: C.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: C.border)),
                ),
              ),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Checkbox(
                  value: agree,
                  activeColor: C.primary,
                  onChanged: (v) => setState(() => agree = v ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                        'Пайдалану шарттарымен және дербес деректерді өңдеу саясатымен келісемін',
                        style: T.small),
                  ),
                ),
              ]),
              const Spacer(),
              loading
                  ? const Center(child: CircularProgressIndicator(color: C.primary))
                  : AppButton('Жалғастыру', onTap: valid ? _submit : null),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: Text('Аккаунт бар ма? Кіру',
                      style: T.small.copyWith(color: C.primary, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      );
}

// ================= 3. SMS OTP =================
class OtpScreen extends StatefulWidget {
  final String phone;
  final String devCode; // DEV GANA: shynaiy koldanuda mundai parametr bolmaidy
  const OtpScreen({required this.phone, required this.devCode, super.key});
  @override
  State<OtpScreen> createState() => _OtpState();
}

class _OtpState extends State<OtpScreen> {
  final ctrl = TextEditingController();
  final focus = FocusNode();
  Timer? timer;
  int left = 45;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    left = 45;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (left == 0) {
        t.cancel();
      } else {
        setState(() => left--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    ctrl.dispose();
    focus.dispose();
    super.dispose();
  }

  String get clock => '00:${left.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final code = ctrl.text;
    return Scaffold(
      appBar: _bar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16),
            Text('SMS-кодты енгізіңіз', style: T.h1),
            const SizedBox(height: 8),
            Text('Код ${widget.phone} нөміріне жіберілді', style: T.small),
            // DEV REJIM: backend hakyky SMS jibermeidi, sondyktan kodty osyndada korsetemiz.
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('DEV код: ${widget.devCode}',
                  style: T.caption.copyWith(color: C.warn, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => focus.requestFocus(),
              child: Stack(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  for (var i = 0; i < 6; i++)
                    Container(
                      width: 48,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: C.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: i == code.length ? C.primary : C.border,
                            width: i == code.length ? 2 : 1),
                      ),
                      child: Text(i < code.length ? code[i] : '', style: T.h2),
                    ),
                ]),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: ctrl,
                      focusNode: focus,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Center(
              child: left > 0
                  ? Text('Қайта жіберу: $clock', style: T.small)
                  : TextButton(
                      onPressed: () async {
                        setState(_start);
                        try {
                          await Api.register(widget.phone);
                        } catch (_) {}
                      },
                      child: Text('Кодты қайта жіберу',
                          style: T.small.copyWith(color: C.primary, fontWeight: FontWeight.w600)),
                    ),
            ),
            const Spacer(),
            AppButton('Растау',
                onTap: code.length == 6
                    ? () => _go(context, CreatePinScreen(phone: widget.phone, code: code))
                    : null),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}

// ================= 4. PIN pad + Create PIN =================
class PinPad extends StatelessWidget {
  final void Function(String key) onKey;
  const PinPad({required this.onKey, super.key});
  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '<'];
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      childAspectRatio: 1.6,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final k in keys)
          k.isEmpty
              ? const SizedBox()
              : InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onKey(k),
                  child: Center(
                      child: k == '<' ? const Icon(LucideIcons.delete) : Text(k, style: T.h1)),
                ),
      ],
    );
  }
}

/// SMS-koddy rastau MEN PIN kuru bir backend shakyruynda (verify-otp) bolady,
/// sondyktan bul ekran eki ret PIN suraidy da, sony /auth/verify-otp-ge jiberedi.
class CreatePinScreen extends StatefulWidget {
  final String phone, code;
  const CreatePinScreen({required this.phone, required this.code, super.key});
  @override
  State<CreatePinScreen> createState() => _CreatePinState();
}

class _CreatePinState extends State<CreatePinScreen> {
  String pin = '', first = '';
  bool confirm = false, error = false, loading = false;

  Future<void> _submit() async {
    setState(() => loading = true);
    try {
      await Api.verifyOtp(widget.phone, widget.code, pin);
      if (mounted) _go(context, const BiometricsScreen());
    } catch (e) {
      if (mounted) {
        _err(context, e);
        setState(() {
          pin = '';
          confirm = false;
          first = '';
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _key(String k) {
    if (loading) return;
    setState(() {
      error = false;
      if (k == '<') {
        if (pin.isNotEmpty) pin = pin.substring(0, pin.length - 1);
        return;
      }
      if (pin.length < 4) pin += k;
    });
    if (pin.length != 4) return;
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      if (!confirm) {
        setState(() {
          first = pin;
          pin = '';
          confirm = true;
        });
      } else if (pin == first) {
        _submit();
      } else {
        setState(() {
          pin = '';
          error = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _bar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              const SizedBox(height: 16),
              Text(confirm ? 'PIN кодты қайталаңыз' : 'PIN код құрыңыз', style: T.h1),
              const SizedBox(height: 8),
              Text(error ? 'PIN сәйкес келмеді, қайта енгізіңіз' : 'Қосымшаға кіру үшін 4 таңба',
                  style: T.small.copyWith(color: error ? C.danger : C.text2)),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < 4; i++)
                  Container(
                    margin: const EdgeInsets.all(8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: i < pin.length ? C.primary : C.border),
                  ),
              ]),
              const Spacer(),
              if (loading) const CircularProgressIndicator(color: C.primary),
              const SizedBox(height: 16),
              PinPad(onKey: _key),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      );
}

// ================= 5. Biometrics =================
class BiometricsScreen extends StatelessWidget {
  const BiometricsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              const Spacer(),
              _iconCircle(LucideIcons.fingerprint),
              const SizedBox(height: 40),
              Text('Биометрияны қосыңыз', style: T.h1, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text('Саусақ ізі немесе Face ID арқылы жылдам әрі қауіпсіз кіресіз.',
                  style: T.body.copyWith(color: C.text2), textAlign: TextAlign.center),
              const Spacer(),
              // TODO: local_auth pakети arkyly naqty biometriya kosu
              AppButton('Қосу', onTap: () => _go(context, const PermissionsScreen())),
              const SizedBox(height: 16),
              AppButton('Кейінірек',
                  kind: BtnKind.secondary, onTap: () => _go(context, const PermissionsScreen())),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      );
}

// ================= 6. Permissions =================
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});
  @override
  State<PermissionsScreen> createState() => _PermissionsState();
}

class _PermissionsState extends State<PermissionsScreen> {
  final on = [true, true, true];
  static const items = [
    (LucideIcons.phone, 'Қоңырау скринингі', 'Белгісіз нөмір қоңырау шалғанда алаяқ екенін тексеру үшін.'),
    (LucideIcons.bell, 'Хабарламалар', 'Күмәнді аударым туралы дереу ескерту жіберу үшін.'),
    (LucideIcons.layers, 'Басқа қосымшалардың үстінен көрсету', 'Қоңырау кезінде ескертуді экранға шығару үшін.'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _bar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 16),
              Text('Рұқсаттар', style: T.h1),
              const SizedBox(height: 8),
              Text('Қорғаныс толық жұмыс істеуі үшін мыналар керек.', style: T.small),
              const SizedBox(height: 24),
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppCard(
                    child: Row(children: [
                      Icon(items[i].$1, color: C.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(items[i].$2, style: T.body.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(items[i].$3, style: T.small),
                        ]),
                      ),
                      Switch(
                        value: on[i],
                        activeColor: C.primary,
                        // TODO: permission_handler arkyly naqty ruqsat surau
                        onChanged: (v) => setState(() => on[i] = v),
                      ),
                    ]),
                  ),
                ),
              const Spacer(),
              AppButton('Жалғастыру',
                  onTap: () => Navigator.pushAndRemoveUntil(
                      context, MaterialPageRoute(builder: (_) => const Shell()), (_) => false)),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      );
}

// ================= 7. Login (tirkelgen paidalanushyga) =================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final phoneCtrl = TextEditingController();
  String pin = '';
  bool loading = false;

  Future<void> _submit() async {
    setState(() => loading = true);
    try {
      await Api.login(normalizePhone(phoneCtrl.text), pin);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (_) => const Shell()), (_) => false);
      }
    } catch (e) {
      if (mounted) {
        _err(context, e);
        setState(() => pin = '');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _key(String k) {
    if (loading) return;
    setState(() {
      if (k == '<') {
        if (pin.isNotEmpty) pin = pin.substring(0, pin.length - 1);
        return;
      }
      if (pin.length < 4) pin += k;
    });
    if (pin.length == 4) _submit();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _bar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              const SizedBox(height: 16),
              Text('Кіру', style: T.h1),
              const SizedBox(height: 24),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneFormatter()],
                style: T.body,
                decoration: InputDecoration(
                  prefixText: '+7  ',
                  hintText: '7XX XXX XX XX',
                  filled: true,
                  fillColor: C.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: C.border)),
                ),
              ),
              const SizedBox(height: 24),
              Text('PIN кодты енгізіңіз', style: T.h2),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < 4; i++)
                  Container(
                    margin: const EdgeInsets.all(8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: i < pin.length ? C.primary : C.border),
                  ),
              ]),
              const Spacer(),
              if (loading) const CircularProgressIndicator(color: C.primary),
              const SizedBox(height: 16),
              PinPad(onKey: _key),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      );
}