// ignore_for_file: prefer_const_constructors, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sprova/core/config/app_config.dart';
import 'package:sprova/features/enrollment/data/repositories/enrollment_repository.dart';
import 'package:sprova/features/enrollment/data/sources/razorpay_service.dart';
import 'package:sprova/features/enrollment/data/sources/supabase_enrollment_source.dart';
import 'package:sprova/features/enrollment/domain/entities/enrollment.dart';
import 'package:sprova/features/enrollment/presentation/enrollment_cubit.dart';
import 'package:sprova/features/enrollment/presentation/enrollment_state.dart';
import 'package:sprova/features/dashboard/dashboard_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _bg     = Color(0xFF0A0906);
const _surf   = Color(0xFF0F0D0B);
const _surf2  = Color(0xFF141210);
const _surf3  = Color(0xFF1A1814);
const _border = Color(0xFF1E1C1A);
const _border2= Color(0xFF252320);
const _amber  = Color(0xFFE8780A);
const _text   = Color(0xFFECE8E3);
const _text2  = Color(0xFFCCC8C4);
const _text3  = Color(0xFFAA9E90);
const _dim    = Color(0xFF3A3835);
const _muted  = Color(0xFF555250);
const _green  = Color(0xFF5CC45F);

// ── TrackPaymentScreen — shown after login ─────────────────────────────────────
class TrackPaymentScreen extends StatefulWidget {
  const TrackPaymentScreen({super.key});
  @override
  State<TrackPaymentScreen> createState() => _TrackPaymentScreenState();
}

class _TrackPaymentScreenState extends State<TrackPaymentScreen> {
  late final EnrollmentCubit _cubit;
  late final EnrollmentRepository _repository;

  String get _sessionEmail =>
      Supabase.instance.client.auth.currentSession?.user.email ?? '';

  @override
  void initState() {
    super.initState();
    final sb = Supabase.instance.client;
    final rp = RazorpayService();
    final es = SupabaseEnrollmentSource(sb);
    _repository = EnrollmentRepository(razorpayService: rp, enrollmentSource: es);
    _cubit = EnrollmentCubit(_repository);
    _repository.setPaymentCallbacks(
      onSuccess: (pid, oid, sig) => _cubit.onPaymentSuccess(oid, pid, sig, _sessionEmail),
      onError: _cubit.onPaymentError,
      onExternalWallet: _cubit.onExternalWallet,
    );
  }

  @override
  void dispose() {
    _cubit.dispose();
    _repository.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<EnrollmentState>(
      valueListenable: _cubit,
      builder: (context, state, _) {
        final selectedTrack = state is EnrollmentInitial
            ? state.selectedTrack
            : state is EnrollmentPaymentProcessing
            ? state.track
            : null;

        final isLoading   = state is EnrollmentLoading;
        final isProcessing = state is EnrollmentPaymentProcessing;
        final isSuccess   = state is EnrollmentSuccess;
        final isError     = state is EnrollmentError;
        final trackChosen = _cubit.currentTrack != null;
        final btnEnabled  = trackChosen && !isProcessing && !isLoading && !isSuccess;

        if (isSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
                (_) => false,
              );
            }
          });
        }

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Column(
              children: [
                // ── Navbar ───────────────────────────────────────────────────
                _Navbar(onSignOut: _signOut),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Logged-in email chip ────────────────────────────
                        _EmailChip(email: _sessionEmail),
                        const SizedBox(height: 28),

                        // ── Section header ──────────────────────────────────
                        const Text(
                          'Choose your track',
                          style: TextStyle(color: _text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.4),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pick the type of startup you want to build. You can change this with Karun before Day 1.',
                          style: TextStyle(color: _text3, fontSize: 13, height: 1.55),
                        ),
                        const SizedBox(height: 20),

                        // ── Track selector ──────────────────────────────────
                        _TrackSelector(selected: selectedTrack, onSelect: _cubit.selectTrack),
                        const SizedBox(height: 28),

                        // ── What's included ─────────────────────────────────
                        _IncludedBox(),
                        const SizedBox(height: 28),

                        // ── Error message ───────────────────────────────────
                        if (isError)
                          _ErrorBox(msg: (state as EnrollmentError).message),

                        // ── Pay button ──────────────────────────────────────
                        _PayButton(
                          loading: isLoading || isProcessing,
                          enabled: btnEnabled,
                          trackChosen: trackChosen,
                          onTap: _cubit.startEnrollment,
                        ),
                        const SizedBox(height: 14),

                        // ── No refund notice ────────────────────────────────
                        _NoRefundNotice(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Navbar ────────────────────────────────────────────────────────────────────
class _Navbar extends StatelessWidget {
  final VoidCallback onSignOut;
  const _Navbar({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.arrow_back_ios_new, color: _text3, size: 16),
            ),
            const SizedBox(width: 12),
            Row(children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(color: _amber, borderRadius: BorderRadius.circular(5)),
                child: const Center(child: Text('S', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900))),
              ),
              const SizedBox(width: 7),
              const Text('Sprova', style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
          ]),
          GestureDetector(
            onTap: onSignOut,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: _surf2, border: Border.all(color: _border), borderRadius: BorderRadius.circular(6)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.logout, color: _muted, size: 12),
                SizedBox(width: 5),
                Text('Sign Out', style: TextStyle(color: _text3, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Email Chip ────────────────────────────────────────────────────────────────
class _EmailChip extends StatelessWidget {
  final String email;
  const _EmailChip({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surf,
        border: Border.all(color: const Color(0xFF1A2E1A)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SIGNED IN AS', style: TextStyle(color: _muted, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
          const SizedBox(height: 2),
          Text(email, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

// ── Track Selector ────────────────────────────────────────────────────────────
class _TrackSelector extends StatelessWidget {
  final TrackType? selected;
  final void Function(TrackType) onSelect;
  const _TrackSelector({this.selected, required this.onSelect});

  static const _tracks = [
    [TrackType.digitalProduct, '💻', 'Digital Product',  'SaaS, app, newsletter, info product — anything that lives online.'],
    [TrackType.physicalProduct,'📦', 'Physical Product', 'A product you can ship in a box. Sell before you manufacture.'],
    [TrackType.localBusiness,  '📍', 'Local Business',   'A service in your city. Tutoring, delivery, events, cleaning.'],
    [TrackType.noCode,         '⚡', 'No-Code',          'Notion, Glide, Carrd, WhatsApp. Zero code required.'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _tracks.map((d) {
        final track = d[0] as TrackType;
        final icon  = d[1] as String;
        final name  = d[2] as String;
        final desc  = d[3] as String;
        final sel   = selected == track;

        return GestureDetector(
          onTap: () => onSelect(track),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFF130B03) : _surf,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? _amber : _border),
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF1E1004) : _surf2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sel ? const Color(0xFF2E1A08) : _border2),
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 15))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: TextStyle(color: sel ? _amber : _text2, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: _muted, fontSize: 11, height: 1.4)),
              ])),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 17, height: 17,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel ? _amber : Colors.transparent,
                  border: Border.all(color: sel ? _amber : const Color(0xFF2A2825), width: 1.5),
                ),
                child: sel ? const Icon(Icons.check, size: 10, color: Colors.black) : null,
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── What's Included ───────────────────────────────────────────────────────────
class _IncludedBox extends StatelessWidget {
  static const _items = [
    ['🗓', '30 days of daily tasks and check-ins'],
    ['🤖', 'AI mentor available 24/7'],
    ['💬', 'Private WhatsApp cohort group'],
    ['📋', 'Outcome certificate (shipped or explained)'],
    ['🎯', 'Direct access to Karun for 1-on-1 feedback'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surf, border: Border.all(color: _border), borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("What's included", style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        ..._items.map((i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Text(i[0], style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 10),
            Expanded(child: Text(i[1], style: const TextStyle(color: _text2, fontSize: 12, height: 1.4))),
          ]),
        )),
      ]),
    );
  }
}

// ── Pay Button ────────────────────────────────────────────────────────────────
class _PayButton extends StatelessWidget {
  final bool loading, enabled, trackChosen;
  final VoidCallback onTap;
  const _PayButton({required this.loading, required this.enabled, required this.trackChosen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = !trackChosen
        ? 'Select a track above ↑'
        : 'Pay ₹${AppConfig.priceRupees} & Join Cohort →';

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? _amber : const Color(0xFF111111),
          disabledBackgroundColor: const Color(0xFF111111),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text(label, style: TextStyle(color: enabled ? Colors.black : const Color(0xFF444440), fontSize: 14, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

// ── No Refund Notice ──────────────────────────────────────────────────────────
class _NoRefundNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0A06),
        border: Border.all(color: const Color(0xFF1E1408)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('⚠', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('No refund policy', style: TextStyle(color: Color(0xFFAA7A30), fontSize: 12, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text(
            'All payments are final. ₹2,999 is not a course fee — it is your commitment device. The skin in the game is the point. If you have questions before paying, DM Karun first.',
            style: TextStyle(color: Color(0xFF8A6A3A), fontSize: 11.5, height: 1.65),
          ),
        ])),
      ]),
    );
  }
}

// ── Error Box ─────────────────────────────────────────────────────────────────
class _ErrorBox extends StatelessWidget {
  final String msg;
  const _ErrorBox({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0606),
        border: Border.all(color: const Color(0xFF2A0808)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 14),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12))),
      ]),
    );
  }
}
