// ignore_for_file: unused_local_variable, unnecessary_underscores, curly_braces_in_flow_control_structures, prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sprova/features/auth/login_screen.dart';
import 'package:sprova/prompts.dart';

const _bg = Color(0xFF0D0D0F);
const _card = Color(0xFF141417);
const _card2 = Color(0xFF1A1A1E);
const _line = Color(0xFF232327);
const _line2 = Color(0xFF2C2C32);
const _amber = Color(0xFFE8780A);
const _amberL = Color(0xFFFFA040);
const _amberD = Color(0xFF7A3D08);
const _txt = Color(0xFFF0EDE8);
const _txt2 = Color(0xFFCDCAC4);
const _txt3 = Color(0xFF8A8680);
const _txt4 = Color(0xFF555250);
const _green = Color(0xFF3ECF8E);
const _greenD = Color(0xFF0D2A1C);
const _red = Color(0xFFEF4444);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _sb = Supabase.instance.client;
  Map<String, dynamic>? _enrollment;
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _submissions = [];
  bool _loading = true;
  String? _error;
  int _tab = 0;

  bool get _bypassAuth => false;
  String get _bypassEmail => _sb.auth.currentUser?.email ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final user = _sb.auth.currentUser;
    if (user == null) {
      _goLogin();
      return;
    }
    final email = user.email ?? '';
    try {
      final e = await _sb
          .from('enrollments')
          .select()
          .eq('user_email', email)
          .eq('payment_status', 'completed')
          .maybeSingle();
      final track = (e?['track'] as String?) ?? 'No-Code';
      final l = await _sb
          .from('lessons')
          .select()
          .or('track.eq.$track,track.is.null')
          .eq('week', _week.clamp(1, 4))
          .order('day');
      final subs = await _sb
          .from('submissions')
          .select('day')
          .eq('user_email', email);
      if (mounted)
        setState(() {
          _enrollment = e ?? {'track': track, 'user_email': email};
          _lessons = List<Map<String, dynamic>>.from(l);
          _submissions = List<Map<String, dynamic>>.from(subs);
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  void _goLogin() => Navigator.pushReplacement<void, void>(
    context,
    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
  );

  int get _day =>
      (DateTime.now().difference(DateTime.parse("2026-05-20")).inDays + 1)
          .clamp(1, 30);
  int get _week => ((_day - 1) ~/ 7) + 1;
  int get _dow => ((_day - 1) % 7) + 1;
  int get _left => DateTime.parse(
    "2026-06-19",
  ).difference(DateTime.now()).inDays.clamp(0, 30);
  double get _pct => (_day - 1) / 30;

  String get _theme => [
    'Kill bad assumptions',
    'Build the right thing',
    'Get your first rupee',
    "Prove it's a business",
  ][(_week - 1).clamp(0, 3)];

  String get _promptText {
    final track = _track.replaceAll(' Product', '').replaceAll(' Business', '');
    final trackKey = prompts.keys.contains(track) ? track : 'Digital';
    return prompts[trackKey]?[_week] ?? 'No prompt available for this week.';
  }

  Map<String, dynamic>? get _todayLesson {
    try {
      return _lessons.firstWhere((l) => (l['day'] as int?) == _dow);
    } catch (_) {
      return null;
    }
  }

  String get _email => _sb.auth.currentUser?.email ?? '';
  String get _track => (_enrollment?['track'] as String?) ?? 'Unknown';

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(
          child: CircularProgressIndicator(color: _amber, strokeWidth: 2),
        ),
      );
    if (_error != null) return _Err(msg: _error!, onRetry: _load);

    final wide = MediaQuery.of(context).size.width > 680;

    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton(
        onPressed: _openMentor,
        backgroundColor: _green,
        elevation: 0,
        child: const Icon(
          Icons.smart_toy_outlined,
          color: Colors.black,
          size: 22,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Nav(
              onSignOut: () async {
                await _sb.auth.signOut();
                _goLogin();
              },
            ),
            Expanded(
              child: Row(
                children: [
                  if (wide)
                    _Sidebar(
                      tab: _tab,
                      track: _track,
                      email: _email,
                      day: _day,
                      pct: _pct,
                      left: _left,
                      onTab: (i) => setState(() => _tab = i),
                    ),
                  Expanded(child: _body()),
                ],
              ),
            ),
            if (!wide)
              _BottomBar(tab: _tab, onTab: (i) => setState(() => _tab = i)),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (_tab) {
      case 1:
        return _ExercisePage(
          lesson: _todayLesson,
          day: _day,
          dow: _dow,
          email: _email,
          sb: _sb,
          alreadySubmitted: _submissions.any((s) => (s['day'] as int?) == _dow),
        );
      case 2:
        return _ProgressPage(
          day: _day,
          week: _week,
          left: _left,
          pct: _pct,
          theme: _theme,
          lessons: _lessons,
          dow: _dow,
          submittedCount: _submissions.length,
        );
      default:
        return _HomePage(
          day: _day,
          week: _week,
          left: _left,
          pct: _pct,
          theme: _theme,
          track: _track,
          todayLesson: _todayLesson,
          onExercise: () => setState(() => _tab = 1),
          onProgress: () => setState(() => _tab = 2),
        );
    }
  }

  void _openMentor() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MentorSheet(todayLesson: _todayLesson),
  );
}

// ── Nav ────────────────────────────────────────────────────────────────────────
class _Nav extends StatelessWidget {
  final VoidCallback onSignOut;
  const _Nav({required this.onSignOut});
  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _line)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
                    fontSize: 13,
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
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _greenD,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'COHORT 1',
                style: TextStyle(
                  color: _green,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onSignOut,
          child: const Text(
            'Sign out',
            style: TextStyle(color: _txt4, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

// ── Sidebar ────────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int tab, day, left;
  final double pct;
  final String track, email;
  final void Function(int) onTab;
  const _Sidebar({
    required this.tab,
    required this.track,
    required this.email,
    required this.day,
    required this.pct,
    required this.left,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 200,
    decoration: const BoxDecoration(
      border: Border(right: BorderSide(color: _line)),
    ),
    child: Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text(
                    'MENU',
                    style: TextStyle(
                      color: _txt4,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  active: tab == 0,
                  onTap: () => onTab(0),
                ),
                _NavItem(
                  icon: Icons.assignment_rounded,
                  label: "Today's Exercise",
                  active: tab == 1,
                  onTap: () => onTab(1),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Progress',
                  active: tab == 2,
                  onTap: () => onTab(2),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _card,
              border: Border.all(color: _line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      track,
                      style: const TextStyle(
                        color: _amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  email.length > 22 ? '${email.substring(0, 22)}…' : email,
                  style: const TextStyle(color: _txt4, fontSize: 10),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Day $day / 30',
                      style: const TextStyle(color: _txt3, fontSize: 10),
                    ),
                    Text(
                      '${(pct * 100).round()}%',
                      style: const TextStyle(
                        color: _amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: _line2,
                    valueColor: const AlwaysStoppedAnimation<Color>(_amber),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$left days to Demo Day',
                  style: const TextStyle(color: _txt4, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Bottom Bar ─────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int tab;
  final void Function(int) onTab;
  const _BottomBar({required this.tab, required this.onTab});
  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: _line)),
    ),
    child: Row(
      children: [
        _BarItem(
          icon: Icons.home_rounded,
          label: 'Home',
          active: tab == 0,
          onTap: () => onTab(0),
        ),
        _BarItem(
          icon: Icons.assignment_rounded,
          label: 'Exercise',
          active: tab == 1,
          onTap: () => onTab(1),
        ),
        _BarItem(
          icon: Icons.bar_chart_rounded,
          label: 'Progress',
          active: tab == 2,
          onTap: () => onTab(2),
        ),
      ],
    ),
  );
}

// ── Home Page ──────────────────────────────────────────────────────────────────
class _HomePage extends StatelessWidget {
  final int day, week, left;
  final double pct;
  final String theme, track;
  final Map<String, dynamic>? todayLesson;
  final VoidCallback onExercise, onProgress;

  const _HomePage({
    required this.day,
    required this.week,
    required this.left,
    required this.pct,
    required this.theme,
    required this.track,
    required this.todayLesson,
    required this.onExercise,
    required this.onProgress,
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _card,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAY $day OF 30  ·  WEEK $week',
                        style: const TextStyle(
                          color: _txt3,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        theme,
                        style: const TextStyle(
                          color: _txt,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.3,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1208),
                    border: Border.all(color: const Color(0xFF3A2010)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$left',
                        style: const TextStyle(
                          color: _amber,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const Text(
                        'days left',
                        style: TextStyle(
                          color: _amberD,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(pct * 100).round()}% complete',
                  style: const TextStyle(color: _txt4, fontSize: 11),
                ),
                Text(
                  'Day $day / 30',
                  style: const TextStyle(color: _txt4, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: _line2,
                valueColor: const AlwaysStoppedAnimation<Color>(_amber),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      Row(
        children: [
          _Q(
            value: 'Week $week',
            label: 'CURRENT',
            sub: theme.split(' ').take(2).join(' '),
          ),
          const SizedBox(width: 10),
          _Q(value: track, label: 'TRACK', sub: 'Cohort 1'),
          const SizedBox(width: 10),
          _Q(value: 'Jun 19', label: 'DEMO DAY', sub: '$left days away'),
        ],
      ),
      const SizedBox(height: 24),

      const _Label("TODAY'S TASK"),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: onExercise,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _card,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: todayLesson != null
              ? _TodayTask(lesson: todayLesson!)
              : const _NoTask(),
        ),
      ),
      const SizedBox(height: 24),

      const _Label('NEXT LIVE SESSION'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF12121C),
                border: Border.all(color: const Color(0xFF28283C)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  Icons.video_call_rounded,
                  color: Color(0xFF8080FF),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Friday with Karun',
                    style: TextStyle(
                      color: _txt,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '2 hours · WhatsApp link before session',
                    style: TextStyle(color: _txt3, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: _line2),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Text(
                'Remind me',
                style: TextStyle(
                  color: _txt3,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      const _Label('DEMO DAY'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1208),
          border: Border.all(color: const Color(0xFF3A2010)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'June 19, 2026',
                    style: TextStyle(
                      color: _amber,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Public. Everyone posts their outcome.\nNo exceptions.',
                    style: TextStyle(color: _amberD, fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'DELIVER:',
                    style: TextStyle(
                      color: _amberD,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...[
                    '5-min recorded pitch',
                    'Revenue or documented reason why not',
                    'Month 2 plan',
                  ].map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: _amberD,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s,
                            style: const TextStyle(
                              color: _amberD,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$left',
                  style: const TextStyle(
                    color: _amber,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const Text(
                  'days\naway',
                  style: TextStyle(color: _amberD, fontSize: 11, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _greenD,
          border: Border.all(color: _green.withOpacity(.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.smart_toy_outlined, color: _green, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Stuck? Tap the green button anytime to ask your AI Mentor.',
                style: TextStyle(color: _green, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _TodayTask extends StatelessWidget {
  final Map<String, dynamic> lesson;
  const _TodayTask({required this.lesson});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _amber,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'DAY ${lesson['day'] ?? 1}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded, color: _txt4, size: 12),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        (lesson['title'] as String?) ?? 'Exercise',
        style: const TextStyle(
          color: _txt,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 6),
      Builder(
        builder: (_) {
          final c = (lesson['content_md'] as String?) ?? '';
          return Text(
            c.length > 100 ? '${c.substring(0, 100)}…' : c,
            style: const TextStyle(color: _txt3, fontSize: 12, height: 1.65),
          );
        },
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _amber,
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Text(
          'Start Exercise →',
          style: TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

class _NoTask extends StatelessWidget {
  const _NoTask();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.hourglass_top_rounded, color: _txt4, size: 24),
      SizedBox(height: 10),
      Text(
        'No exercise yet',
        style: TextStyle(
          color: _txt2,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: 5),
      Text(
        'Karun will publish today\'s task soon.\nCheck WhatsApp for the update.',
        style: TextStyle(color: _txt3, fontSize: 12, height: 1.65),
      ),
    ],
  );
}

// ── Exercise Page ──────────────────────────────────────────────────────────────
class _ExercisePage extends StatefulWidget {
  final Map<String, dynamic>? lesson;
  final int day, dow;
  final String email;
  final SupabaseClient sb;
  final bool alreadySubmitted;
  const _ExercisePage({
    required this.lesson,
    required this.day,
    required this.dow,
    required this.email,
    required this.sb,
    required this.alreadySubmitted,
  });
  @override
  State<_ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<_ExercisePage> {
  final _ctrl = TextEditingController();
  bool _saving = false;
  bool _done = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    if (widget.alreadySubmitted) _done = true;
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      setState(() => _err = 'Write something first');
      return;
    }
    setState(() {
      _saving = true;
      _err = null;
    });
    try {
      final submission = await widget.sb.from('submissions').insert({
        'user_email': widget.email,
        'lesson_id': widget.lesson?['id'],
        'day': widget.dow,
        'content': text,
        'submitted_at': DateTime.now().toIso8601String(),
      }).single();

      if (mounted)
        setState(() {
          _saving = false;
          _done = true;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _saving = false;
          _err = 'Failed to submit. Try again.';
        });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        'DAY ${widget.day} EXERCISE',
        style: const TextStyle(
          color: _txt4,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        "Today's Task",
        style: TextStyle(
          color: _txt,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 20),

      if (widget.lesson == null)
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _card,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            children: [
              Icon(Icons.hourglass_top_rounded, color: _txt4, size: 32),
              SizedBox(height: 12),
              Text(
                'Not published yet',
                style: TextStyle(
                  color: _txt2,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Karun will publish today\'s exercise soon.\nCheck WhatsApp for the announcement.',
                style: TextStyle(color: _txt3, fontSize: 12, height: 1.7),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
      else ...[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1208),
            border: Border.all(color: const Color(0xFF3A2010)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'DAY ${widget.lesson!['day'] ?? widget.dow}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.access_time_rounded,
                    color: _amberD,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Due today',
                    style: TextStyle(color: _amberD, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                (widget.lesson!['title'] as String?) ?? '',
                style: const TextStyle(
                  color: _amberL,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                (widget.lesson!['content_md'] as String?) ?? '',
                style: const TextStyle(
                  color: _txt2,
                  fontSize: 13,
                  height: 1.75,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_done)
          _FeedbackView(email: widget.email, day: widget.dow, sb: widget.sb)
        else ...[
          const _Label('YOUR SUBMISSION'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _card,
              border: Border.all(color: _line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _ctrl,
              maxLines: 7,
              style: const TextStyle(color: _txt, fontSize: 13, height: 1.7),
              decoration: const InputDecoration(
                hintText:
                    'Write your answer, findings, or observations here...',
                hintStyle: TextStyle(color: _txt4),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          if (_err != null) ...[
            const SizedBox(height: 8),
            Text(_err!, style: const TextStyle(color: _red, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                disabledBackgroundColor: _line2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ],
    ],
  );
}

// ── Progress Page ──────────────────────────────────────────────────────────────
class _ProgressPage extends StatelessWidget {
  final int day, week, left, dow, submittedCount;
  final double pct;
  final String theme;
  final List<Map<String, dynamic>> lessons;

  const _ProgressPage({
    required this.day,
    required this.week,
    required this.left,
    required this.pct,
    required this.theme,
    required this.lessons,
    required this.dow,
    required this.submittedCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = lessons.length;
    final themes = [
      'Kill bad assumptions',
      'Build the right thing',
      'Get your first rupee',
      "Prove it's a business",
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'PROGRESS',
          style: TextStyle(
            color: _txt4,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your Journey',
          Style: TextStyle(
            color: _txt,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            _Big('$day', 'days in', 'of 30'),
            const SizedBox(width: 10),
            _Big('$left', 'days left', 'to Demo Day'),
            const SizedBox(width: 10),
            _Big('W$week', 'current', 'week'),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _card,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _PB('Cohort progress', '${(pct * 100).round()}%', pct),
              const SizedBox(height: 16),
              _PB('Weeks done', '${week - 1} / 4', (week - 1) / 4),
              const SizedBox(height: 16),
              _PB(
                'Exercises submitted',
                submittedCount == 0
                    ? '0 / ${total == 0 ? 7 : total}'
                    : '$submittedCount / ${total == 0 ? 7 : total}',
                total == 0 ? 0 : submittedCount / (total == 0 ? 7 : total),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const _Label('WEEK BREAKDOWN'),
        const SizedBox(height: 10),
        ...List.generate(4, (i) {
          final w = i + 1;
          final active = w == week;
          final past = w < week;
          return Container(
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF1C1208) : _card,
              border: Border.all(
                color: active
                    ? _amber
                    : past
                    ? _amberD
                    : _line,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: past
                        ? _amber
                        : active
                        ? const Color(0xFF2A1A08)
                        : _card2,
                    border: Border.all(
                      color: past
                          ? _amber
                          : active
                          ? _amber
                          : _line2,
                    ),
                  ),
                  child: Center(
                    child: past
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.black,
                          )
                        : Text(
                            '$w',
                            style: TextStyle(
                              color: active ? _amber : _txt4,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WEEK $w',
                        style: TextStyle(
                          color: active
                              ? _amberD
                              : past
                              ? _amberD
                              : _txt4,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        themes[i],
                        style: TextStyle(
                          color: active
                              ? _txt
                              : past
                              ? _txt2
                              : _txt3,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (active)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'NOW',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                if (past)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: _amberD,
                    size: 16,
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── AI Mentor Sheet ────────────────────────────────────────────────────────────
class _MentorSheet extends StatefulWidget {
  final Map<String, dynamic>? todayLesson;
  const _MentorSheet({this.todayLesson});
  @override
  State<_MentorSheet> createState() => _MentorSheetState();
}

class _MentorSheetState extends State<_MentorSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _response;
  String? _err;

  Future<void> _ask() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _response = null;
      _err = null;
    });
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'ai-mentor',
        body: {'question': q, 'context': widget.todayLesson?['title'] ?? ''},
      );
      final data = res.data as Map<String, dynamic>;
      if (data['error'] != null) throw Exception(data['error']);
      setState(() {
        _response = data['response'] as String?;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _err = 'Could not reach AI Mentor. Try again.';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .88,
    maxChildSize: .95,
    minChildSize: .5,
    builder: (_, scroll) => Container(
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: _line2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _greenD,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _green.withOpacity(.3)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.smart_toy_outlined,
                      color: _green,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Mentor',
                        style: TextStyle(
                          color: _txt,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Direct, honest feedback',
                        style: TextStyle(color: _txt3, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close_rounded,
                    color: _txt4,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Divider(color: _line),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                if (widget.todayLesson != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1208),
                      border: Border.all(color: _amberD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Context: ${widget.todayLesson!['title'] ?? "today's exercise"}",
                      style: const TextStyle(color: _amberD, fontSize: 11),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: _bg,
                    border: Border.all(color: _line),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    maxLines: 4,
                    style: const TextStyle(
                      color: _txt,
                      fontSize: 13,
                      height: 1.65,
                    ),
                    decoration: const InputDecoration(
                      hintText:
                          'Ask anything...\n\n"My customer said no. What do I do?"',
                      hintStyle: TextStyle(color: _txt4),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _ask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      disabledBackgroundColor: _line2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Ask',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                if (_err != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _err!,
                    style: const TextStyle(color: _red, fontSize: 12),
                  ),
                ],
                if (_response != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bg,
                      border: Border.all(color: _line),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _greenD,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.smart_toy_outlined,
                                  color: _green,
                                  size: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Mentor',
                              style: TextStyle(
                                color: _green,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _response!,
                          style: const TextStyle(
                            color: _txt2,
                            fontSize: 13,
                            height: 1.75,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _FeedbackView extends StatelessWidget {
  final String email;
  final int day;
  final SupabaseClient sb;

  const _FeedbackView({
    required this.email,
    required this.day,
    required this.sb,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: sb
          .from('submissions')
          .select()
          .eq('user_email', email)
          .eq('day', day)
          .single(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _amber, strokeWidth: 2),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text('No feedback yet', style: TextStyle(color: _txt3)),
          );
        }
        final data = snapshot.data!;
        final feedback =
            data['ai_feedback'] as String? ?? 'No AI feedback available.';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bg,
            border: Border.all(color: _green.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.smart_toy_outlined, color: _green, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'AI Feedback',
                    style: TextStyle(
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                feedback,
                style: const TextStyle(
                  color: _txt2,
                  fontSize: 13,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1C1208) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: active ? _amber : _txt4, size: 17),
          const SizedBox(width: 9),
          Text(
            label,
            style: TextStyle(
              color: active ? _amber : _txt3,
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class _BarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _BarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? _amber : _txt4, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: active ? _amber : _txt4,
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _txt4,
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 3,
    ),
  );
}

class _Q extends StatelessWidget {
  final String value, label, sub;
  const _Q({required this.value, required this.label, required this.sub});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _txt4,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _txt,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(sub, style: const TextStyle(color: _txt4, fontSize: 10)),
        ],
      ),
    ),
  );
}

class _Big extends StatelessWidget {
  final String value, label, sub;
  const _Big(this.value, this.label, this.sub);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _amber,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: _txt2,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(sub, style: const TextStyle(color: _txt4, fontSize: 10)),
        ],
      ),
    ),
  );
}

class _PB extends StatelessWidget {
  final String label, val;
  final double v;
  const _PB(this.label, this.val, this.v);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _txt3, fontSize: 13)),
          Text(
            val,
            style: const TextStyle(
              color: _amber,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: v.clamp(0.0, 1.0),
          backgroundColor: _line2,
          valueColor: const AlwaysStoppedAnimation<Color>(_amber),
          minHeight: 5,
        ),
      ),
    ],
  );
}

class _Err extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _Err({required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: _txt4, size: 36),
            const SizedBox(height: 12),
            Text(
              msg,
              style: const TextStyle(color: _txt3, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _a = Tween(
      begin: 1.0,
      end: .25,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Opacity(
      opacity: _a.value,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
      ),
    ),
  );
}