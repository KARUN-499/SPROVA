// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bg = Color(0xFF0D0D0F);
const _card = Color(0xFF141417);
const _card2 = Color(0xFF1A1A1E);
const _line = Color(0xFF232327);
const _line2 = Color(0xFF2C2C32);
const _amber = Color(0xFFE8780A);
const _amberD = Color(0xFF7A3D08);
const _txt = Color(0xFFF0EDE8);
const _txt2 = Color(0xFFCDCAC4);
const _txt3 = Color(0xFF8A8680);
const _txt4 = Color(0xFF555250);
const _green = Color(0xFF3ECF8E);
const _greenD = Color(0xFF0D2A1C);
const _red = Color(0xFFEF4444);
const _redD = Color(0xFF2A0A0A);
const _yellow = Color(0xFFEAB308);
const _yellowD = Color(0xFF1A1200);

const _adminEmail = 'karun@gmail.com';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _sb = Supabase.instance.client;
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final email = _sb.auth.currentUser?.email ?? '';
    if (email != _adminEmail) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: Text('Access denied.', style: TextStyle(color: _txt3))),
      );
    }
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildNav(),
            _buildTabs(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildNav() => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _line))),
    child: Row(
      children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(color: _amber, borderRadius: BorderRadius.circular(6)),
          child: const Center(child: Text('S', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900))),
        ),
        const SizedBox(width: 8),
        const Text('Sprova', style: TextStyle(color: _txt, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFF1A0800), borderRadius: BorderRadius.circular(4)),
          child: const Text('ADMIN', style: TextStyle(color: _amber, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .8)),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () async { await _sb.auth.signOut(); if (mounted) Navigator.pop(context); },
          child: const Text('Sign out', style: TextStyle(color: _txt4, fontSize: 12)),
        ),
      ],
    ),
  );

  Widget _buildTabs() {
    final tabs = ['Exercises', 'Students', 'Submissions', 'Enrollments', 'Settings'];
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _line))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (i) {
            final active = _tab == i;
            return GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: active ? _amber : Colors.transparent, width: 2)),
                ),
                child: Text(tabs[i], style: TextStyle(color: active ? _amber : _txt3, fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case 1: return _StudentsView(sb: _sb);
      case 2: return _SubmissionsView(sb: _sb);
      case 3: return _EnrollmentsView(sb: _sb);
      case 4: return _SettingsView(sb: _sb);
      default: return _ExercisesView(sb: _sb);
    }
  }
}

// ── EXERCISES ──────────────────────────────────────────────────────────────────
class _ExercisesView extends StatefulWidget {
  final SupabaseClient sb;
  const _ExercisesView({required this.sb});
  @override
  State<_ExercisesView> createState() => _ExercisesViewState();
}

class _ExercisesViewState extends State<_ExercisesView> {
  List<Map<String, dynamic>> _lessons = [];
  bool _loading = true;
  int _filterWeek = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await widget.sb.from('lessons').select().order('week').order('day');
    if (mounted) setState(() { _lessons = List<Map<String, dynamic>>.from(res); _loading = false; });
  }

  List<Map<String, dynamic>> get _filtered => _filterWeek == 0
      ? _lessons
      : _lessons.where((l) => (l['week'] as int?) == _filterWeek).toList();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
        child: Row(
          children: [
            ...List.generate(5, (i) {
              final label = i == 0 ? 'All' : 'W$i';
              final active = _filterWeek == i;
              return GestureDetector(
                onTap: () => setState(() => _filterWeek = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? _amber : _card,
                    border: Border.all(color: active ? _amber : _line),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(label, style: TextStyle(color: active ? Colors.black : _txt3, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              );
            }),
            const Spacer(),
            GestureDetector(
              onTap: () => _openForm(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: _amber, borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, color: Colors.black, size: 16),
                    SizedBox(width: 4),
                    Text('Add Exercise', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      if (_loading)
        const Expanded(child: Center(child: CircularProgressIndicator(color: _amber, strokeWidth: 2)))
      else if (_filtered.isEmpty)
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.assignment_outlined, color: _txt4, size: 40),
                const SizedBox(height: 12),
                const Text('No exercises yet', style: TextStyle(color: _txt3, fontSize: 14)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _openForm(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: _amber, borderRadius: BorderRadius.circular(7)),
                    child: const Text('Add first exercise', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        )
      else
        Expanded(
          child: RefreshIndicator(
            color: _amber, backgroundColor: _card, onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final l = _filtered[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: _card, border: Border.all(color: _line), borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: const Color(0xFF1C1208), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A2010))),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('W${l['week']}D${l['day']}', style: const TextStyle(color: _amber, fontSize: 9, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    title: Text((l['title'] as String?) ?? '', style: const TextStyle(color: _txt, fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: Builder(builder: (_) {
                      final c = (l['content_md'] as String?) ?? '';
                      return Text(c.length > 60 ? '${c.substring(0, 60)}…' : c, style: const TextStyle(color: _txt4, fontSize: 11));
                    }),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (l['track'] != null)
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _card2, borderRadius: BorderRadius.circular(4)),
                            child: Text(l['track'] as String, style: const TextStyle(color: _txt3, fontSize: 9)),
                          ),
                        IconButton(icon: const Icon(Icons.edit_outlined, color: _txt3, size: 18), onPressed: () => _openForm(context, lesson: l)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: _red, size: 18), onPressed: () => _confirmDelete(context, l['id'] as String)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
    ],
  );

  void _openForm(BuildContext context, {Map<String, dynamic>? lesson}) =>
      showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (_) => _ExerciseForm(sb: widget.sb, lesson: lesson, onSaved: _load));

  void _confirmDelete(BuildContext context, String id) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: _card,
      title: const Text('Delete exercise?', style: TextStyle(color: _txt)),
      content: const Text('This cannot be undone.', style: TextStyle(color: _txt3)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _txt3))),
        TextButton(
          onPressed: () async { await widget.sb.from('lessons').delete().eq('id', id); if (context.mounted) Navigator.pop(context); _load(); },
          child: const Text('Delete', style: TextStyle(color: _red)),
        ),
      ],
    ),
  );
}

// ── EXERCISE FORM ──────────────────────────────────────────────────────────────
class _ExerciseForm extends StatefulWidget {
  final SupabaseClient sb;
  final Map<String, dynamic>? lesson;
  final VoidCallback onSaved;
  const _ExerciseForm({required this.sb, this.lesson, required this.onSaved});
  @override
  State<_ExerciseForm> createState() => _ExerciseFormState();
}

class _ExerciseFormState extends State<_ExerciseForm> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  int _week = 1, _day = 1;
  String? _track;
  bool _saving = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    if (widget.lesson != null) {
      final l = widget.lesson!;
      _title.text = (l['title'] as String?) ?? '';
      _content.text = (l['content_md'] as String?) ?? '';
      _week = (l['week'] as int?) ?? 1;
      _day = (l['day'] as int?) ?? 1;
      _track = l['track'] as String?;
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) { setState(() => _err = 'Title required'); return; }
    if (_content.text.trim().isEmpty) { setState(() => _err = 'Content required'); return; }
    setState(() { _saving = true; _err = null; });
    try {
      final data = {'week': _week, 'day': _day, 'title': _title.text.trim(), 'content_md': _content.text.trim(), 'track': _track};
      if (widget.lesson != null) {
        await widget.sb.from('lessons').update(data).eq('id', widget.lesson!['id'] as String);
      } else {
        await widget.sb.from('lessons').insert(data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _err = e.toString(); });
    }
  }

  @override
  void dispose() { _title.dispose(); _content.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .9, maxChildSize: .97, minChildSize: .5,
    builder: (_, scroll) => Container(
      decoration: const BoxDecoration(color: _card, borderRadius: BorderRadius.vertical(top: Radius.circular(20)), border: Border(top: BorderSide(color: _line))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 10), width: 32, height: 3, decoration: BoxDecoration(color: _line2, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.lesson != null ? 'Edit Exercise' : 'New Exercise', style: const TextStyle(color: _txt, fontSize: 16, fontWeight: FontWeight.w800)),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: _txt4, size: 20)),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(20, 12, 20, 0), child: Divider(color: _line)),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const _FL('WEEK'), const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(color: _bg, border: Border.all(color: _line), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(child: DropdownButton<int>(
                          value: _week, dropdownColor: _card, style: const TextStyle(color: _txt, fontSize: 13),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: List.generate(4, (i) => DropdownMenuItem(value: i + 1, child: Text('Week ${i + 1}'))),
                          onChanged: (v) => setState(() => _week = v ?? 1),
                        )),
                      ),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const _FL('DAY OF WEEK'), const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(color: _bg, border: Border.all(color: _line), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(child: DropdownButton<int>(
                          value: _day, dropdownColor: _card, style: const TextStyle(color: _txt, fontSize: 13),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: List.generate(7, (i) => DropdownMenuItem(value: i + 1, child: Text('Day ${i + 1}'))),
                          onChanged: (v) => setState(() => _day = v ?? 1),
                        )),
                      ),
                    ])),
                  ],
                ),
                const SizedBox(height: 14),
                const _FL('TRACK (empty = all tracks)'), const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(color: _bg, border: Border.all(color: _line), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(child: DropdownButton<String?>(
                    value: _track, dropdownColor: _card, style: const TextStyle(color: _txt, fontSize: 13),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All tracks')),
                      DropdownMenuItem(value: 'Digital Product', child: Text('Digital Product')),
                      DropdownMenuItem(value: 'Physical Product', child: Text('Physical Product')),
                      DropdownMenuItem(value: 'Local Business', child: Text('Local Business')),
                      DropdownMenuItem(value: 'No-Code', child: Text('No-Code')),
                    ],
                    onChanged: (v) => setState(() => _track = v),
                  )),
                ),
                const SizedBox(height: 14),
                const _FL('EXERCISE TITLE'), const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(color: _bg, border: Border.all(color: _line), borderRadius: BorderRadius.circular(8)),
                  child: TextField(controller: _title, style: const TextStyle(color: _txt, fontSize: 13),
                    decoration: const InputDecoration(hintText: 'e.g. Talk to 5 real customers', hintStyle: TextStyle(color: _txt4), border: InputBorder.none, contentPadding: EdgeInsets.all(14))),
                ),
                const SizedBox(height: 14),
                const _FL('EXERCISE CONTENT'), const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(color: _bg, border: Border.all(color: _line), borderRadius: BorderRadius.circular(8)),
                  child: TextField(controller: _content, maxLines: 8, style: const TextStyle(color: _txt, fontSize: 13, height: 1.6),
                    decoration: const InputDecoration(hintText: 'Write the full exercise instructions...', hintStyle: TextStyle(color: _txt4), border: InputBorder.none, contentPadding: EdgeInsets.all(14))),
                ),
                if (_err != null) ...[const SizedBox(height: 8), Text(_err!, style: const TextStyle(color: _red, fontSize: 12))],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: _amber, disabledBackgroundColor: _line2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)), elevation: 0),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : Text(widget.lesson != null ? 'Save Changes' : 'Publish Exercise', style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ── STUDENTS ───────────────────────────────────────────────────────────────────
class _StudentsView extends StatefulWidget {
  final SupabaseClient sb;
  const _StudentsView({required this.sb});
  @override
  State<_StudentsView> createState() => _StudentsViewState();
}

class _StudentsViewState extends State<_StudentsView> {
  List<Map<String, dynamic>> _students = [];
  Map<String, int> _subCounts = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final enrollments = await widget.sb.from('enrollments').select().eq('payment_status', 'completed').order('enrolled_at', ascending: false);
    final submissions = await widget.sb.from('submissions').select('user_email, day');
    final counts = <String, int>{};
    for (final s in submissions) { final email = s['user_email'] as String? ?? ''; counts[email] = (counts[email] ?? 0) + 1; }
    if (mounted) setState(() { _students = List<Map<String, dynamic>>.from(enrollments); _subCounts = counts; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _amber, strokeWidth: 2));
   final today = DateTime.now();
    final atRisk = _students.where((s) {
      final count = _subCounts[s['user_email']] ?? 0;
      final enrolled = DateTime.tryParse(s['enrolled_at'] as String? ?? '') ?? today;
      final daysSinceEnroll = today.difference(enrolled).inDays;
      final expectedMin = (daysSinceEnroll - 1).clamp(0, 30);
      return count < expectedMin;
    }).toList();
    final onTrack = _students.where((s) {
      final count = _subCounts[s['user_email']] ?? 0;
      final enrolled = DateTime.tryParse(s['enrolled_at'] as String? ?? '') ?? today;
      final daysSinceEnroll = today.difference(enrolled).inDays;
      final expectedMin = (daysSinceEnroll - 1).clamp(0, 30);
      return count >= expectedMin;
    }).toList();
    
    return RefreshIndicator(
      color: _amber, backgroundColor: _card, onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            _StatPill('TOTAL', '${_students.length}', _amber),
            const SizedBox(width: 10),
            _StatPill('ON TRACK', '${onTrack.length}', _green),
            const SizedBox(width: 10),
            _StatPill('AT RISK', '${atRisk.length}', _red),
          ]),
          const SizedBox(height: 20),
          if (atRisk.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _redD, border: Border.all(color: _red.withOpacity(.3)), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: _red, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('${atRisk.length} student${atRisk.length > 1 ? 's' : ''} falling behind', style: const TextStyle(color: _red, fontSize: 12, fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 12),
            ...atRisk.map((s) => _StudentCard(s: s, subCount: _subCounts[s['user_email']] ?? 0, atRisk: true, onViewSubs: () => _viewSubs(context, s['user_email'] as String))),
            const SizedBox(height: 20),
          ],
          if (onTrack.isNotEmpty) ...[
            const Text('ON TRACK', style: TextStyle(color: _txt4, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 3)),
            const SizedBox(height: 10),
            ...onTrack.map((s) => _StudentCard(s: s, subCount: _subCounts[s['user_email']] ?? 0, atRisk: false, onViewSubs: () => _viewSubs(context, s['user_email'] as String))),
          ],
        ],
      ),
    );
  }

  void _viewSubs(BuildContext context, String email) =>
      showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (_) => _StudentSubsSheet(sb: widget.sb, email: email));
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> s;
  final int subCount;
  final bool atRisk;
  final VoidCallback onViewSubs;
  const _StudentCard({required this.s, required this.subCount, required this.atRisk, required this.onViewSubs});

  @override
  Widget build(BuildContext context) {
    final email = (s['user_email'] as String?) ?? '';
    final track = (s['track'] as String?) ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: atRisk ? _redD : _card, border: Border.all(color: atRisk ? _red.withOpacity(.3) : _line), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: atRisk ? _red.withOpacity(.15) : _greenD, shape: BoxShape.circle, border: Border.all(color: atRisk ? _red.withOpacity(.4) : _green.withOpacity(.3))),
            child: Center(child: Icon(atRisk ? Icons.warning_amber_rounded : Icons.check_rounded, color: atRisk ? _red : _green, size: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(email, style: const TextStyle(color: _txt, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            Row(children: [
              Text(track, style: const TextStyle(color: _amber, fontSize: 11)),
              const Text(' · ', style: TextStyle(color: _txt4)),
              Text('$subCount / 7 submissions', style: TextStyle(color: atRisk ? _red : _green, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ])),
          GestureDetector(
            onTap: onViewSubs,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: _card2, border: Border.all(color: _line2), borderRadius: BorderRadius.circular(6)),
              child: const Text('View', style: TextStyle(color: _txt3, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── STUDENT SUBMISSIONS SHEET ──────────────────────────────────────────────────
class _StudentSubsSheet extends StatefulWidget {
  final SupabaseClient sb;
  final String email;
  const _StudentSubsSheet({required this.sb, required this.email});
  @override
  State<_StudentSubsSheet> createState() => _StudentSubsSheetState();
}

class _StudentSubsSheetState extends State<_StudentSubsSheet> {
  List<Map<String, dynamic>> _subs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.sb.from('submissions').select().eq('user_email', widget.email).order('day').then((res) {
      if (mounted) setState(() { _subs = List<Map<String, dynamic>>.from(res); _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .85, maxChildSize: .95, minChildSize: .4,
    builder: (_, scroll) => Container(
      decoration: const BoxDecoration(color: _card, borderRadius: BorderRadius.vertical(top: Radius.circular(20)), border: Border(top: BorderSide(color: _line))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 10), width: 32, height: 3, decoration: BoxDecoration(color: _line2, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Submissions', style: TextStyle(color: _txt, fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(widget.email, style: const TextStyle(color: _txt3, fontSize: 11), overflow: TextOverflow.ellipsis),
                ])),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: _txt4, size: 20)),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(20, 10, 20, 0), child: Divider(color: _line)),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _amber, strokeWidth: 2))
                : _subs.isEmpty
                ? const Center(child: Text('No submissions yet.', style: TextStyle(color: _txt3)))
                : ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: _subs.length,
                    itemBuilder: (_, i) {
                      final s = _subs[i];
                      final date = s['submitted_at'] != null ? DateTime.parse(s['submitted_at'] as String).toLocal() : null;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: _bg, border: Border.all(color: _line), borderRadius: BorderRadius.circular(10)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFF1C1208), borderRadius: BorderRadius.circular(4)),
                              child: Text('Day ${s['day']}', style: const TextStyle(color: _amber, fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                            const Spacer(),
                            if (date != null) Text('${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: _txt4, fontSize: 10)),
                          ]),
                          const SizedBox(height: 10),
                          Text((s['content'] as String?) ?? '', style: const TextStyle(color: _txt2, fontSize: 13, height: 1.65)),
                        ]),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}

// ── SUBMISSIONS VIEW ───────────────────────────────────────────────────────────
class _SubmissionsView extends StatefulWidget {
  final SupabaseClient sb;
  const _SubmissionsView({required this.sb});
  @override
  State<_SubmissionsView> createState() => _SubmissionsViewState();
}

class _SubmissionsViewState extends State<_SubmissionsView> {
  List<Map<String, dynamic>> _subs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await widget.sb.from('submissions').select().order('submitted_at', ascending: false);
    if (mounted) setState(() { _subs = List<Map<String, dynamic>>.from(res); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _amber, strokeWidth: 2));
    if (_subs.isEmpty) return const Center(child: Text('No submissions yet.', style: TextStyle(color: _txt3)));
    return RefreshIndicator(
      color: _amber, backgroundColor: _card, onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: _subs.length,
        itemBuilder: (_, i) {
          final s = _subs[i];
          final date = s['submitted_at'] != null ? DateTime.parse(s['submitted_at'] as String).toLocal() : null;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _card, border: Border.all(color: _line), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF1C1208), borderRadius: BorderRadius.circular(4)),
                  child: Text('Day ${s['day']}', style: const TextStyle(color: _amber, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text((s['user_email'] as String?) ?? '', style: const TextStyle(color: _txt3, fontSize: 11), overflow: TextOverflow.ellipsis)),
                if (date != null) Text('${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: _txt4, fontSize: 10)),
              ]),
              const SizedBox(height: 10),
              Text((s['content'] as String?) ?? '', style: const TextStyle(color: _txt2, fontSize: 13, height: 1.6)),
            ]),
          );
        },
      ),
    );
  }
}

// ── ENROLLMENTS VIEW ───────────────────────────────────────────────────────────
class _EnrollmentsView extends StatefulWidget {
  final SupabaseClient sb;
  const _EnrollmentsView({required this.sb});
  @override
  State<_EnrollmentsView> createState() => _EnrollmentsViewState();
}

class _EnrollmentsViewState extends State<_EnrollmentsView> {
  List<Map<String, dynamic>> _enrollments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await widget.sb.from('enrollments').select().order('enrolled_at', ascending: false);
    if (mounted) setState(() { _enrollments = List<Map<String, dynamic>>.from(res); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _amber, strokeWidth: 2));
    final completed = _enrollments.where((e) => e['payment_status'] == 'completed').length;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _card, border: Border.all(color: _line), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatPill('TOTAL', '${_enrollments.length}', _amber),
              Container(width: 1, height: 24, color: _line),
              _StatPill('PAID', '$completed', _green),
              Container(width: 1, height: 24, color: _line),
              _StatPill('SEATS LEFT', '${15 - completed}', completed >= 12 ? _red : _amber),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            color: _amber, backgroundColor: _card, onRefresh: _load,
            child: _enrollments.isEmpty
                ? const Center(child: Text('No enrollments yet.', style: TextStyle(color: _txt3)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _enrollments.length,
                    itemBuilder: (_, i) {
                      final e = _enrollments[i];
                      final paid = e['payment_status'] == 'completed';
                      final date = e['enrolled_at'] != null ? DateTime.parse(e['enrolled_at'] as String).toLocal() : null;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: _card, border: Border.all(color: _line), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(color: paid ? _greenD : _card2, borderRadius: BorderRadius.circular(8), border: Border.all(color: paid ? _green.withOpacity(.3) : _line2)),
                              child: Center(child: Icon(paid ? Icons.check_rounded : Icons.pending_outlined, color: paid ? _green : _txt4, size: 18)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text((e['user_email'] as String?) ?? '', style: const TextStyle(color: _txt, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                              Row(children: [
                                Text((e['track'] as String?) ?? '', style: const TextStyle(color: _amber, fontSize: 11)),
                                const Text(' · ', style: TextStyle(color: _txt4)),
                                Text('Rs. ${((e['amount_paid'] as int? ?? 0) / 100).round()}', style: const TextStyle(color: _txt3, fontSize: 11)),
                              ]),
                            ])),
                            if (date != null) Text('${date.day}/${date.month}', style: const TextStyle(color: _txt4, fontSize: 11)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

// ── SETTINGS VIEW ──────────────────────────────────────────────────────────────
class _SettingsView extends StatefulWidget {
  final SupabaseClient sb;
  const _SettingsView({required this.sb});
  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  final _demoDayCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _msg;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await widget.sb.from('settings').select();
    if (mounted) {
      for (final row in res) {
        if (row['key'] == 'demo_day') _demoDayCtrl.text = row['value'] as String? ?? '';
        if (row['key'] == 'cohort_start') _startDateCtrl.text = row['value'] as String? ?? '';
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _msg = null; });
    await widget.sb.from('settings').upsert({'key': 'cohort_start', 'value': _startDateCtrl.text.trim()});
    await widget.sb.from('settings').upsert({'key': 'demo_day', 'value': _demoDayCtrl.text.trim()});
    if (mounted) setState(() { _saving = false; _msg = '✓ Saved successfully'; });
  }

  @override
  void dispose() { _demoDayCtrl.dispose(); _startDateCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => _loading
      ? const Center(child: CircularProgressIndicator(color: _amber, strokeWidth: 2))
      : ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const _FL('COHORT SETTINGS'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _card, border: Border.all(color: _line), borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cohort Start Date', style: TextStyle(color: _txt, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Format: YYYY-MM-DD  (e.g. 2026-06-20)', style: TextStyle(color: _txt4, fontSize: 11)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(color: _bg, border: Border.all(color: _line), borderRadius: BorderRadius.circular(8)),
                    child: TextField(
                      controller: _startDateCtrl,
                      style: const TextStyle(color: _txt, fontSize: 14),
                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), hintText: 'e.g. 2026-06-20', hintStyle: TextStyle(color: _txt4)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Demo Day Date', style: TextStyle(color: _txt, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Format: YYYY-MM-DD  (e.g. 2026-07-19)', style: TextStyle(color: _txt4, fontSize: 11)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(color: _bg, border: Border.all(color: _line), borderRadius: BorderRadius.circular(8)),
                    child: TextField(
                      controller: _demoDayCtrl,
                      style: const TextStyle(color: _txt, fontSize: 14),
                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), hintText: 'e.g. 2026-07-19', hintStyle: TextStyle(color: _txt4)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 44,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: _amber, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('Save Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                  if (_msg != null) ...[
                    const SizedBox(height: 10),
                    Text(_msg!, style: const TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ],
        );
}

// ── SHARED ─────────────────────────────────────────────────────────────────────
class _FL extends StatelessWidget {
  final String text;
  const _FL(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: _txt4, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2));
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatPill(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: _txt4, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
    ]),
  );
}