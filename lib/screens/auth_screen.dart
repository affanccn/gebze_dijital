import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_strings.dart';
import 'auth_service.dart';
import 'report_common.dart' show kReportNeighborhoods;

/// Gebze Belediyesi - Giriş / Kayıt (telefon + şifre)
/// Dosya yolu: lib/screens/auth_screen.dart

class _C {
  static const navy = Color(0xFF0A2A66);
  static const orange = Color(0xFFFF7A00);
  static const bg = Color(0xFFF1F5FD);
  static const field = Color(0xFFE9EFFE);
  static const textDark = Color(0xFF0A1F44);
  static const textMuted = Color(0xFF5F6F8A);
  static const danger = Color(0xFFE5231B);
}

const String _kBodyFont = 'system-ui';
const List<String> _kBodyFontFallback = [
  '-apple-system',
  'Segoe UI',
  'Roboto',
  'Helvetica Neue',
  'Noto Sans',
  'Liberation Sans',
  'Arial',
  'sans-serif',
];

Widget _withFont(BuildContext context, Widget child) {
  final base = Theme.of(context);
  return Theme(
    data: base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: _kBodyFont,
        fontFamilyFallback: _kBodyFontFallback,
      ),
    ),
    child: child,
  );
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'gorsel/gebze_logo.png',
      height: 76,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_rounded, color: _C.orange, size: 44),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GEBZE',
                  style: TextStyle(
                      fontSize: 28,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: _C.navy)),
              Text('BELEDİYESİ',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _C.navy,
                      letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final bool required;
  const _Label(this.text, {this.trailing, this.required = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            TextSpan(
              text: text,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark),
              children: [
                if (required)
                  const TextSpan(
                      text: ' *', style: TextStyle(color: _C.danger)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

InputDecoration _dec({String? hint, Widget? suffix}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _C.textMuted, fontSize: 14),
      filled: true,
      fillColor: _C.field,
      suffixIcon: suffix,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.navy, width: 1.4),
      ),
    );

final _phoneFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9 +]')),
];

Widget _softButton(String text, VoidCallback onTap) => Material(
      color: const Color(0xFFF6F7FA),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _C.textMuted),
          ),
        ),
      ),
    );

Widget _card({required Widget child}) => Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.fromLTRB(26, 30, 26, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _C.navy.withAlpha(22),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

Widget _errorRow(String text) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 16, color: _C.danger),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: _C.danger,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

Widget _eyeButton(bool hide, VoidCallback onTap) => IconButton(
      icon: Icon(
        hide ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        color: _C.textMuted,
        size: 20,
      ),
      onPressed: onTap,
    );

Widget _spinner() => const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
    );

// ───────────────────────── Giriş ─────────────────────────

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login(String lang) async {
    if (_busy) return;
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = at(lang, 'err_required'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signIn(_email.text, _pass.text);
      if (!mounted) return;
      // Misafir olarak açılmış ana sayfanın üstündeyse kapat. Kök ekransa
      // AuthGate oturumu görüp ana sayfaya kendisi geçer.
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = at(lang, authErrorKey(e));
      });
    }
  }

  void _forgot(String lang) {
    final c = TextEditingController(text: _email.text.trim());
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: const Icon(Icons.lock_reset_rounded, color: _C.navy, size: 44),
        title: Text(at(lang, 'forgot_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(at(lang, 'forgot_msg'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 14),
            TextField(
              controller: c,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: _dec(hint: at(lang, 'email_hint')),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(at(lang, 'close')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _C.navy),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);
              try {
                await ref.read(authServiceProvider).sendReset(c.text);
                nav.pop();
                messenger.showSnackBar(
                    SnackBar(content: Text(at(lang, 'reset_sent'))));
              } catch (e) {
                nav.pop();
                messenger.showSnackBar(
                    SnackBar(content: Text(at(lang, authErrorKey(e)))));
              }
            },
            child: Text(at(lang, 'send')),
          ),
        ],
      ),
    );
  }

  void _guest() {
    ref.read(guestModeProvider.notifier).state = true;
    // Üyelik uyarısından açıldıysa geri dön; kök ekransa AuthGate geçişi yapar.
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return _withFont(
      context,
      Scaffold(
        backgroundColor: _C.bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: _Logo()),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        at(lang, 'login_title'),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB4B9C6),
                            letterSpacing: 0.4),
                      ),
                    ),
                    _Label(at(lang, 'email')),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: _dec(hint: at(lang, 'email_hint')),
                    ),
                    _Label(
                      at(lang, 'password'),
                      trailing: GestureDetector(
                        onTap: () => _forgot(lang),
                        child: Text(
                          at(lang, 'forgot'),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _C.orange),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _pass,
                      obscureText: _hide,
                      onSubmitted: (_) => _login(lang),
                      decoration: _dec(
                        suffix: _eyeButton(
                            _hide, () => setState(() => _hide = !_hide)),
                      ),
                    ),
                    if (_error != null) _errorRow(_error!),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _busy ? null : () => _login(lang),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        child: _busy ? _spinner() : Text(at(lang, 'login')),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        at(lang, 'or'),
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB4B9C6)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _softButton(
                      at(lang, 'go_register'),
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _guest,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.orange,
                          side: const BorderSide(color: _C.orange, width: 1.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w800),
                        ),
                        child: Text(at(lang, 'guest')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Kayıt ─────────────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  String? _hood;
  bool _kvkk = false;
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _register(String lang) async {
    if (_busy) return;
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _hood == null ||
        _pass.text.isEmpty) {
      setState(() => _error = at(lang, 'err_required'));
      return;
    }
    if (!isValidEmail(_email.text)) {
      setState(() => _error = at(lang, 'err_email'));
      return;
    }
    if (_phone.text.trim().isNotEmpty && normalizePhone(_phone.text) == null) {
      setState(() => _error = at(lang, 'err_phone'));
      return;
    }
    if (_pass.text != _pass2.text) {
      setState(() => _error = at(lang, 'err_match'));
      return;
    }
    if (!_kvkk) {
      setState(() => _error = at(lang, 'err_kvkk'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).register(
            fullName: _name.text,
            email: _email.text,
            phone: _phone.text,
            neighborhood: _hood!,
            password: _pass.text,
            language: lang,
          );
      if (!mounted) return;
      // Kayıt sonrası oturum otomatik açılır: kayıt ekranını kapat; giriş
      // ekranı da (misafir akışından) üstteyse onu da kapat.
      final nav = Navigator.of(context);
      nav.pop();
      if (nav.canPop()) nav.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = at(lang, authErrorKey(e));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return _withFont(
      context,
      Scaffold(
        backgroundColor: _C.bg,
        appBar: AppBar(
          backgroundColor: _C.bg,
          foregroundColor: _C.navy,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: _Logo()),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        at(lang, 'register_title'),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB4B9C6),
                            letterSpacing: 0.4),
                      ),
                    ),
                    _Label(at(lang, 'full_name')),
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _dec(),
                    ),
                    _Label(at(lang, 'email')),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: _dec(hint: at(lang, 'email_hint')),
                    ),
                    _Label(at(lang, 'phone'), required: false),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: _phoneFormatters,
                      maxLength: 16,
                      textInputAction: TextInputAction.next,
                      decoration: _dec(hint: at(lang, 'phone_hint')),
                    ),
                    _Label(at(lang, 'neighborhood')),
                    DropdownButtonFormField<String>(
                      initialValue: _hood,
                      isExpanded: true,
                      decoration: _dec(),
                      items: kReportNeighborhoods
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _hood = v),
                    ),
                    _Label(at(lang, 'password')),
                    TextField(
                      controller: _pass,
                      obscureText: _hide,
                      textInputAction: TextInputAction.next,
                      decoration: _dec(
                        suffix: _eyeButton(
                            _hide, () => setState(() => _hide = !_hide)),
                      ),
                    ),
                    _Label(at(lang, 'password2')),
                    TextField(
                      controller: _pass2,
                      obscureText: _hide,
                      onSubmitted: (_) => _register(lang),
                      decoration: _dec(),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => setState(() => _kvkk = !_kvkk),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _kvkk,
                              activeColor: _C.navy,
                              onChanged: (v) =>
                                  setState(() => _kvkk = v ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              at(lang, 'kvkk'),
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.35,
                                  color: _C.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) _errorRow(_error!),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _busy ? null : () => _register(lang),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        child: _busy ? _spinner() : Text(at(lang, 'create')),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _softButton(
                      at(lang, 'have_account'),
                      () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}