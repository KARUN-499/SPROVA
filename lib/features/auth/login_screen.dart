// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sprova/features/enrollment/presentation/track_payment_screen.dart';

const _bg = Color(0xFF0A0906);
const _surf = Color(0xFF0F0D0B);
const _surf2 = Color(0xFF141210);
const _border = Color(0xFF1E1C1A);
const _amber = Color(0xFFE8780A);
const _txt = Color(0xFFECE8E3);
const _txt2 = Color(0xFFCCC8C4);
const _txt3 = Color(0xFFAA9E90);
const _dim = Color(0xFF3A3835);
const _muted = Color(0xFF555250);
const _red = Color(0xFFEF4444);
const _green = Color(0xFF3ECF8E);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // Login
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  bool _loginLoading = false;
  bool _loginObscure = true;
  String? _loginError;

  // Signup
  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPhone = TextEditingController();
  final _signupPass = TextEditingController();
  final _signupPass2 = TextEditingController();
  bool _signupLoading = false;
  bool _signupObscure = true;
  bool _signupObscure2 = true;
  String? _signupError;
  String? _signupSuccess;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _loginEmail.dispose();
    _loginPass.dispose();
    _signupName.dispose();
    _signupEmail.dispose();
    _signupPhone.dispose();
    _signupPass.dispose();
    _signupPass2.dispose();
    super.dispose();
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<void> _login() async {
    final email = _loginEmail.text.trim();
    final pass = _loginPass.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _loginError = 'Enter a valid email');
      return;
    }
    if (pass.isEmpty) {
      setState(() => _loginError = 'Enter your password');
      return;
    }
    setState(() {
      _loginLoading = true;
      _loginError = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: pass,
      );
      // Navigate to track+payment screen directly for fast UX
      // main.dart auth listener also fires as backup
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const TrackPaymentScreen()),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _loginError = _friendlyError(e.message);
        _loginLoading = false;
      });
    } catch (_) {
      setState(() {
        _loginError = 'Something went wrong. Try again.';
        _loginLoading = false;
      });
    }
  }

  // ── Signup ─────────────────────────────────────────────────────────────────
  Future<void> _signup() async {
    final name = _signupName.text.trim();
    final email = _signupEmail.text.trim();
    final phone = _signupPhone.text.trim();
    final pass = _signupPass.text;
    final pass2 = _signupPass2.text;

    if (name.isEmpty) {
      setState(() => _signupError = 'Enter your name');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _signupError = 'Enter a valid email');
      return;
    }
    if (phone.isNotEmpty && phone.length < 10) {
      setState(() => _signupError = 'Enter a valid 10-digit mobile number');
      return;
    }
    if (pass.length < 8) {
      setState(() => _signupError = 'Password must be at least 8 characters');
      return;
    }
    if (pass != pass2) {
      setState(() => _signupError = 'Passwords do not match');
      return;
    }

    setState(() {
      _signupLoading = true;
      _signupError = null;
      _signupSuccess = null;
    });

    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: pass,
        data: {
          'full_name': name,
          if (phone.isNotEmpty) 'phone': '+91$phone',
        },
      );

      // If Supabase email confirmation is OFF, the user is signed in immediately
      // and main.dart listener fires. If confirmation is ON, show the message.
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        // Already signed in — main.dart handles navigation
        return;
      }

      setState(() {
        _signupLoading = false;
        _signupSuccess =
            'Account created! Check your email to confirm, then log in.';
      });
    } on AuthException catch (e) {
      setState(() {
        _signupError = _friendlyError(e.message);
        _signupLoading = false;
      });
    } catch (_) {
      setState(() {
        _signupError = 'Something went wrong. Try again.';
        _signupLoading = false;
      });
    }
  }

  // ── Forgot password ────────────────────────────────────────────────────────
  Future<void> _forgotPassword() async {
    final email = _loginEmail.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _loginError = 'Enter your email above first');
      return;
    }
    setState(() {
      _loginLoading = true;
      _loginError = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      setState(() => _loginLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset link sent to your email'),
            backgroundColor: _surf2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      setState(() {
        _loginError = 'Failed to send reset email.';
        _loginLoading = false;
      });
    }
  }

  String _friendlyError(String msg) {
    if (msg.contains('Invalid login')) return 'Wrong email or password';
    if (msg.contains('Email not confirmed'))
      return 'Please confirm your email first';
    if (msg.contains('User already registered'))
      return 'Account already exists. Log in instead.';
    if (msg.contains('Password should be'))
      return 'Password must be at least 8 characters';
    return msg;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Nav
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _amber,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sprova',
                    style: TextStyle(
                      color: _txt,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 40),
                child: Column(
                  children: [
                    const Text(
                      'Welcome to Sprova',
                      style: TextStyle(
                        color: _txt,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Build a startup in 30 days.',
                      style: TextStyle(color: _txt3, fontSize: 14),
                    ),
                    const SizedBox(height: 32),

                    // Tab bar
                    Container(
                      decoration: BoxDecoration(
                        color: _surf,
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TabBar(
                        controller: _tabCtrl,
                        indicator: BoxDecoration(
                          color: _amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.black,
                        unselectedLabelColor: _txt3,
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Log In'),
                          Tab(text: 'Sign Up'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      // signup form is taller due to extra fields
                      height: 520,
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [_loginForm(), _signupForm()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Login form ─────────────────────────────────────────────────────────────
  Widget _loginForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Label('EMAIL'),
      const SizedBox(height: 7),
      _Field(ctrl: _loginEmail, hint: 'you@example.com', type: TextInputType.emailAddress),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _Label('PASSWORD'),
          GestureDetector(
            onTap: _forgotPassword,
            child: const Text(
              'Forgot password?',
              style: TextStyle(color: _amber, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      _PasswordField(
        ctrl: _loginPass,
        hint: '••••••••',
        obscure: _loginObscure,
        onToggle: () => setState(() => _loginObscure = !_loginObscure),
      ),
      if (_loginError != null) ...[
        const SizedBox(height: 10),
        _ErrorBox(msg: _loginError!),
      ],
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _loginLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: _amber,
            disabledBackgroundColor: _surf2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: _loginLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                )
              : const Text(
                  'Log In',
                  style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w800),
                ),
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: GestureDetector(
          onTap: () => _tabCtrl.animateTo(1),
          child: RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 13, color: _txt3),
              children: [
                TextSpan(text: "Don't have an account? "),
                TextSpan(text: 'Sign up', style: TextStyle(color: _amber, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  // ── Signup form ────────────────────────────────────────────────────────────
  Widget _signupForm() {
    if (_signupSuccess != null) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2A1C),
              border: Border.all(color: _green.withOpacity(.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: _green, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _signupSuccess!,
                    style: const TextStyle(color: _green, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _tabCtrl.animateTo(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text(
                'Go to Log In',
                style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('FULL NAME'),
        const SizedBox(height: 7),
        _Field(ctrl: _signupName, hint: 'Karun Sharma', type: TextInputType.name),
        const SizedBox(height: 14),
        const _Label('EMAIL'),
        const SizedBox(height: 7),
        _Field(ctrl: _signupEmail, hint: 'you@example.com', type: TextInputType.emailAddress),
        const SizedBox(height: 14),
        const _Label('MOBILE NUMBER (OPTIONAL)'),
        const SizedBox(height: 7),
        _PhoneField(ctrl: _signupPhone),
        const SizedBox(height: 14),
        const _Label('PASSWORD'),
        const SizedBox(height: 7),
        _PasswordField(
          ctrl: _signupPass,
          hint: 'Min. 8 characters',
          obscure: _signupObscure,
          onToggle: () => setState(() => _signupObscure = !_signupObscure),
        ),
        const SizedBox(height: 14),
        const _Label('CONFIRM PASSWORD'),
        const SizedBox(height: 7),
        _PasswordField(
          ctrl: _signupPass2,
          hint: 'Repeat password',
          obscure: _signupObscure2,
          onToggle: () => setState(() => _signupObscure2 = !_signupObscure2),
        ),
        if (_signupError != null) ...[
          const SizedBox(height: 10),
          _ErrorBox(msg: _signupError!),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _signupLoading ? null : _signup,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber,
              disabledBackgroundColor: _surf2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _signupLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w800),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () => _tabCtrl.animateTo(0),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 13, color: _txt3),
                children: [
                  TextSpan(text: 'Already have an account? '),
                  TextSpan(text: 'Log in', style: TextStyle(color: _amber, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Micro widgets ──────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF555250),
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 2.5,
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType type;
  const _Field({required this.ctrl, required this.hint, this.type = TextInputType.text});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: type,
    autocorrect: false,
    textCapitalization: type == TextInputType.name ? TextCapitalization.words : TextCapitalization.none,
    style: const TextStyle(color: Color(0xFFECE8E3), fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF3A3835)),
      filled: true,
      fillColor: const Color(0xFF0F0D0B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E1C1A))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E1C1A))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE8780A), width: 1.5)),
    ),
  );
}

class _PhoneField extends StatelessWidget {
  final TextEditingController ctrl;
  const _PhoneField({required this.ctrl});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: TextInputType.phone,
    autocorrect: false,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
    style: const TextStyle(color: Color(0xFFECE8E3), fontSize: 14),
    decoration: InputDecoration(
      hintText: '9876543210',
      hintStyle: const TextStyle(color: Color(0xFF3A3835)),
      prefixText: '+91  ',
      prefixStyle: const TextStyle(color: Color(0xFFAA9E90), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF0F0D0B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E1C1A))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E1C1A))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE8780A), width: 1.5)),
    ),
  );
}

class _PasswordField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  const _PasswordField({required this.ctrl, required this.hint, required this.obscure, required this.onToggle});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    obscureText: obscure,
    autocorrect: false,
    style: const TextStyle(color: Color(0xFFECE8E3), fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF3A3835)),
      filled: true,
      fillColor: const Color(0xFF0F0D0B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E1C1A))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E1C1A))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE8780A), width: 1.5)),
      suffixIcon: GestureDetector(
        onTap: onToggle,
        child: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: const Color(0xFF555250),
          size: 18,
        ),
      ),
    ),
  );
}

class _ErrorBox extends StatelessWidget {
  final String msg;
  const _ErrorBox({required this.msg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF0E0606),
      border: Border.all(color: const Color(0xFF2A0808)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
        ),
      ],
    ),
  );
}
