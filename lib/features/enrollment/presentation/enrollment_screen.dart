// ignore_for_file: prefer_const_constructors, unused_element, deprecated_member_use, non_constant_identifier_names
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sprova/core/config/app_config.dart';
import 'package:sprova/features/auth/login_screen.dart';
import 'package:sprova/features/enrollment/presentation/track_payment_screen.dart';

// ── Palette ────────────────────────────────────────────────────────────────────
const _bg     = Color(0xFF0A0906);
const _surf   = Color(0xFF0F0D0B);
const _surf2  = Color(0xFF141210);
const _surf3  = Color(0xFF1A1814);
const _border = Color(0xFF1E1C1A);
const _border2= Color(0xFF252320);
const _amber  = Color(0xFFE8780A);
const _amberDim = Color(0xFF8A4A08);
const _text   = Color(0xFFECE8E3);
const _text2  = Color(0xFFCCC8C4);
const _text3  = Color(0xFFAA9E90);
const _dim    = Color(0xFF3A3835);
const _muted  = Color(0xFF555250);
const _green  = Color(0xFF5CC45F);
const _red    = Color(0xFFFF5555);

// ── EnrollmentScreen — pure landing/hero, no auth required ────────────────────
class EnrollmentScreen extends StatelessWidget {
  const EnrollmentScreen({super.key});

  void _onEnrollTap(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      // Not logged in → go to login, which after success routes to TrackPaymentScreen
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    } else {
      // Already logged in → go straight to track selection + payment
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const TrackPaymentScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _LandingNavbar(onEnrollTap: () => _onEnrollTap(context)),
            ),
            SliverToBoxAdapter(child: _UrgencyBanner()),
            SliverToBoxAdapter(child: _Hero(onEnrollTap: () => _onEnrollTap(context))),
            SliverToBoxAdapter(child: _SeatBar()),
            SliverToBoxAdapter(child: _StatsRow()),
            SliverToBoxAdapter(child: _TrustRow()),
            SliverToBoxAdapter(child: _WhatSection()),
            SliverToBoxAdapter(child: _ProgramStructure()),
            SliverToBoxAdapter(child: _SocialProof()),
            SliverToBoxAdapter(child: _LandingCTA(onTap: () => _onEnrollTap(context))),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }
}

// ── Landing Navbar (no sign-out — user may not be logged in) ──────────────────
class _LandingNavbar extends SliverPersistentHeaderDelegate {
  final VoidCallback onEnrollTap;
  const _LandingNavbar({required this.onEnrollTap});

  @override double get minExtent => 56;
  @override double get maxExtent => 56;
  @override bool shouldRebuild(_) => false;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _bg.withOpacity(0.97),
        border: const Border(bottom: BorderSide(color: _border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(color: _amber, borderRadius: BorderRadius.circular(6)),
                child: const Center(child: Text('S', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 8),
              const Text('Sprova', style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: .3)),
            ]),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _surf2, border: Border.all(color: _border2), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _PulseDot(),
                  const SizedBox(width: 5),
                  const Text('Cohort 1 open', style: TextStyle(color: _text2, fontSize: 10, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEnrollTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: _amber, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Enroll Now', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Urgency Banner ─────────────────────────────────────────────────────────────
class _UrgencyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0804),
        border: const Border(bottom: BorderSide(color: Color(0xFF1E1408))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _amber.withOpacity(.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _amber.withOpacity(.25)),
            ),
            child: const Text('COHORT 1', style: TextStyle(color: _amber, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 2)),
          ),
          const SizedBox(width: 10),
          Text(
            '${AppConfig.seatsRemaining} of ${AppConfig.totalSeats} seats left — closes ${AppConfig.cohortStartDate}',
            style: const TextStyle(color: _text3, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 10),
          _CountdownTimer(),
        ],
      ),
    );
  }
}

class _CountdownTimer extends StatefulWidget {
  @override State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    final target = DateTime.tryParse(AppConfig.cohortStartDate.replaceFirst('August 1, 2026', '2026-08-01')) ?? DateTime(2026, 8, 1);
    _remaining = target.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  @override void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative) return const SizedBox.shrink();
    final d = _remaining.inDays;
    final h = _remaining.inHours % 24;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    return Text(
      '${d}d ${h}h ${m}m ${s}s',
      style: const TextStyle(color: _amber, fontSize: 10, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final VoidCallback onEnrollTap;
  const _Hero({required this.onEnrollTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0804),
              border: Border.all(color: const Color(0xFF2E1A08)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('For Indian students aged 17–22', style: TextStyle(color: _amber, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Build a startup\nin 30 days.',
            style: TextStyle(color: _text, fontSize: 38, fontWeight: FontWeight.w900, height: 1.08, letterSpacing: -1.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'Not a course. Not a bootcamp.\nA 30-day cohort where you ship something real — or explain why you couldn\'t.',
            style: TextStyle(color: _text3, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 32),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: onEnrollTap,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(color: _amber, borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text(
                      'Join Cohort 1 — ₹${AppConfig.priceRupees}',
                      style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          const Center(
            child: Text('No refunds. Skin in the game is the point.', style: TextStyle(color: _muted, fontSize: 11)),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ── Seat Bar ──────────────────────────────────────────────────────────────────
class _SeatBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final filled = AppConfig.totalSeats - AppConfig.seatsRemaining;
    final pct = filled / AppConfig.totalSeats;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$filled/${AppConfig.totalSeats} seats filled', style: const TextStyle(color: _text3, fontSize: 12)),
              Text('${AppConfig.seatsRemaining} remaining', style: const TextStyle(color: _amber, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: _surf2,
              valueColor: const AlwaysStoppedAnimation(_amber),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: _surf, border: Border.all(color: _border), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            _Stat('30', 'Days'),
            _StatDivider(),
            _Stat('15', 'Max Seats'),
            _StatDivider(),
            _Stat('₹2,999', 'One-time'),
            _StatDivider(),
            _Stat('4', 'Tracks'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String val, label;
  const _Stat(this.val, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(val, style: const TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
    ]),
  );
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 28, color: _border);
}

// ── Trust Row ─────────────────────────────────────────────────────────────────
class _TrustRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: const [
          _TrustChip(icon: '🔒', label: 'Razorpay secured'),
          _TrustChip(icon: '📧', label: 'Welcome email'),
          _TrustChip(icon: '💬', label: 'WhatsApp group'),
          _TrustChip(icon: '🚀', label: 'Ship or explain'),
        ],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final String icon, label;
  const _TrustChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: _surf, border: Border.all(color: _border), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 11)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: _text3, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ── What Section ──────────────────────────────────────────────────────────────
class _WhatSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What is Sprova?', style: TextStyle(color: _text, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'A 30-day cohort-based program where Indian students aged 17–22 build a real startup — not a project, not an assignment. Something with a customer and a payment.',
            style: TextStyle(color: _text3, fontSize: 14, height: 1.65),
          ),
          const SizedBox(height: 24),
          _BentoCard(icon: '💸', title: 'Get a paying customer', desc: 'The program ends when you get paid — or you document why you couldn\'t.'),
          const SizedBox(height: 10),
          _BentoCard(icon: '🛠', title: 'Build in public', desc: 'Daily tasks. Real outreach. Real rejection. Real sales calls.'),
          const SizedBox(height: 10),
          _BentoCard(icon: '🤖', title: 'AI mentor on demand', desc: 'Ask questions, get feedback, unblock yourself at 2am.'),
          const SizedBox(height: 10),
          _BentoCard(icon: '👥', title: 'Cohort accountability', desc: '15 students max. Everyone ships or explains why.'),
        ],
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final String icon, title, desc;
  const _BentoCard({required this.icon, required this.title, required this.desc});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _surf, border: Border.all(color: _border), borderRadius: BorderRadius.circular(10)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(color: _text3, fontSize: 12, height: 1.5)),
      ])),
    ]),
  );
}

// ── Program Structure ─────────────────────────────────────────────────────────
class _ProgramStructure extends StatelessWidget {
  static const _weeks = [
    ['Week 1', 'Idea → Validation', 'Find a problem. Talk to 10 people. Pick your market.'],
    ['Week 2', 'Validation → Product', 'Build the simplest possible version. No code required.'],
    ['Week 3', 'Product → Sales', 'Outreach. Pitches. Handle objections. Get a yes or a no.'],
    ['Week 4', 'Sales → First Payment', 'Close. Deliver. Document. Submit your outcome.'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('The 30-Day Structure', style: TextStyle(color: _text, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          ..._weeks.asMap().entries.map((e) {
            final i = e.key;
            final w = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: i == 3 ? _amber : _surf2, shape: BoxShape.circle, border: Border.all(color: i == 3 ? _amber : _border)),
                    child: Center(child: Text('${i + 1}', style: TextStyle(color: i == 3 ? Colors.black : _muted, fontSize: 11, fontWeight: FontWeight.w800))),
                  ),
                  if (i < 3) Container(width: 1, height: 32, color: _border),
                ]),
                const SizedBox(width: 14),
                Expanded(child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(w[0], style: const TextStyle(color: _amber, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      const SizedBox(width: 8),
                      Text(w[1], style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 3),
                    Text(w[2], style: const TextStyle(color: _text3, fontSize: 12, height: 1.5)),
                    const SizedBox(height: 10),
                  ]),
                )),
              ]),
            );
          }),
        ],
      ),
    );
  }
}

// ── Social Proof ──────────────────────────────────────────────────────────────
class _SocialProof extends StatelessWidget {
  static const _quotes = [
    ['This is the push I needed. No fluff, just build.', 'Arjun S., Delhi', 'AS'],
    ['Finally something that treats us like founders, not students.', 'Priya M., Bengaluru', 'PM'],
    ['The accountability alone is worth ₹2,999.', 'Rahul K., Pune', 'RK'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Early feedback', style: TextStyle(color: _text, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ..._quotes.map((q) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _surf, border: Border.all(color: _border), borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('"${q[0]}"', style: const TextStyle(color: _text2, fontSize: 13, height: 1.55, fontStyle: FontStyle.italic)),
                const SizedBox(height: 10),
                Row(children: [
                  _Avatar(initials: q[2]),
                  const SizedBox(width: 8),
                  Text(q[1], style: const TextStyle(color: _muted, fontSize: 11)),
                ]),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});
  @override
  Widget build(BuildContext context) => Container(
    width: 26, height: 26,
    decoration: BoxDecoration(color: _surf3, shape: BoxShape.circle, border: Border.all(color: _border2)),
    child: Center(child: Text(initials, style: const TextStyle(color: _text3, fontSize: 9, fontWeight: FontWeight.w700))),
  );
}

// ── Landing CTA ───────────────────────────────────────────────────────────────
class _LandingCTA extends StatelessWidget {
  final VoidCallback onTap;
  const _LandingCTA({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
      child: Column(children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              'Join Cohort 1 — ₹${AppConfig.priceRupees}',
              style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('15 seats. No refunds. Starts August 1.', style: TextStyle(color: _muted, fontSize: 12)),
      ]),
    );
  }
}

// ── Pulse Dot ─────────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  @override State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _anim = Tween(begin: 1.0, end: .3).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Opacity(
      opacity: _anim.value,
      child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
    ),
  );
}
