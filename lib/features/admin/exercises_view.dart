import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sprova/features/admin/app_colors.dart';
import 'package:sprova/features/admin/admin_widgets.dart';

class ExercisesView extends StatefulWidget {
  final SupabaseClient sb;
  const ExercisesView({super.key, required this.sb});
  @override
  State<ExercisesView> createState() => _ExercisesViewState();
}

class _ExercisesViewState extends State<ExercisesView> {
  List<Map<String, dynamic>> _lessons = [];
  bool _loading = true;
  int _filterWeek = 0; // 0=all

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.sb
          .from('lessons')
          .select()
          .order('week')
          .order('day');
      if (mounted) {
        setState(() {
          _lessons = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered => _filterWeek == 0
      ? _lessons
      : _lessons.where((l) => (l['week'] as int?) == _filterWeek).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              ...List.generate(5, (i) {
                final label = i == 0 ? 'All' : 'W$i';
                final active = _filterWeek == i;
                return GestureDetector(
                  onTap: () => setState(() => _filterWeek = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: active ? AppColors.amber : AppColors.card,
                      border: Border.all(color: active ? AppColors.amber : AppColors.line),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: active ? Colors.black : AppColors.txt3,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              GestureDetector(
                onTap: () => _openForm(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded, color: Colors.black, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Add Exercise',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_loading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2),
            ),
          )
        else if (_filtered.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assignment_outlined, color: AppColors.txt4, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'No exercises yet',
                    style: TextStyle(color: AppColors.txt3, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _openForm(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Text(
                        'Add first exercise',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              color: AppColors.amber,
              backgroundColor: AppColors.card,
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final l = _filtered[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1208),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF3A2010)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'W${l['week']}D${l['day']}',
                              style: const TextStyle(
                                color: AppColors.amber,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      title: Text(
                        (l['title'] as String?) ?? '',
                        style: const TextStyle(
                          color: AppColors.txt,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        (l['content_md'] as String? ?? '').length > 60
                            ? '${(l['content_md'] as String).substring(0, 60)}…'
                            : (l['content_md'] as String? ?? ''),
                        style: const TextStyle(color: AppColors.txt4, fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (l['track'] != null)
                            Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.card2,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l['track'] as String,
                                style: const TextStyle(
                                  color: AppColors.txt3,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.txt3,
                              size: 18,
                            ),
                            onPressed: () => _openForm(context, lesson: l),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.red,
                              size: 18,
                            ),
                            onPressed: () =>
                                _confirmDelete(context, l['id'] as String),
                          ),
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
  }

  void _openForm(BuildContext context, {Map<String, dynamic>? lesson}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ExerciseForm(sb: widget.sb, lesson: lesson, onSaved: _load),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete exercise?', style: TextStyle(color: AppColors.txt)),
        content: const Text(
          'This cannot be undone.',
          style: TextStyle(color: AppColors.txt3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.txt3)),
          ),
          TextButton(
            onPressed: () async {
              await widget.sb.from('lessons').delete().eq('id', id);
              if (context.mounted) Navigator.pop(context);
              await _load();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class ExerciseForm extends StatefulWidget {
  final SupabaseClient sb;
  final Map<String, dynamic>? lesson;
  final VoidCallback onSaved;
  const ExerciseForm({super.key, required this.sb, this.lesson, required this.onSaved});
  @override
  State<ExerciseForm> createState() => _ExerciseFormState();
}

class _ExerciseFormState extends State<ExerciseForm> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  int _week = 1;
  int _day = 1;
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
    if (_title.text.trim().isEmpty) {
      setState(() => _err = 'Title required');
      return;
    }
    if (_content.text.trim().isEmpty) {
      setState(() => _err = 'Content required');
      return;
    }
    setState(() {
      _saving = true;
      _err = null;
    });
    try {
      final data = {
        'week': _week,
        'day': _day,
        'title': _title.text.trim(),
        'content_md': _content.text.trim(),
        'track': _track,
      };
      if (widget.lesson != null) {
        await widget.sb
            .from('lessons')
            .update(data)
            .eq('id', widget.lesson!['id'] as String);
      } else {
        await widget.sb.from('lessons').insert(data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        setState(() {
          _saving = false;
          _err = e.toString();
        });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .9,
      maxChildSize: .97,
      minChildSize: .5,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.line2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.lesson != null ? 'Edit Exercise' : 'New Exercise',
                    style: const TextStyle(
                      color: AppColors.txt,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.txt4,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Divider(color: AppColors.line),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AdminFLabel(text: 'WEEK'),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                border: Border.all(color: AppColors.line),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _week,
                                  dropdownColor: AppColors.card,
                                  style: const TextStyle(
                                    color: AppColors.txt,
                                    fontSize: 13,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  items: List.generate(
                                    4,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text('Week ${i + 1}'),
                                    ),
                                  ),
                                  onChanged: (v) =>
                                      setState(() => _week = v ?? 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AdminFLabel(text: 'DAY OF WEEK'),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                border: Border.all(color: AppColors.line),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _day,
                                  dropdownColor: AppColors.card,
                                  style: const TextStyle(
                                    color: AppColors.txt,
                                    fontSize: 13,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  items: List.generate(
                                    7,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text('Day ${i + 1}'),
                                    ),
                                  ),
                                  onChanged: (v) =>
                                      setState(() => _day = v ?? 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const AdminFLabel(text: 'TRACK (leave empty = all tracks)'),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _track,
                        dropdownColor: AppColors.card,
                        style: const TextStyle(color: AppColors.txt, fontSize: 13),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('All tracks'),
                          ),
                          DropdownMenuItem(
                            value: 'Digital Product',
                            child: Text('Digital Product'),
                          ),
                          DropdownMenuItem(
                            value: 'Physical Product',
                            child: Text('Physical Product'),
                          ),
                          DropdownMenuItem(
                            value: 'Local Business',
                            child: Text('Local Business'),
                          ),
                          DropdownMenuItem(
                            value: 'No-Code',
                            child: Text('No-Code'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _track = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const AdminFLabel(text: 'EXERCISE TITLE'),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _title,
                      style: const TextStyle(color: AppColors.txt, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Talk to 5 real customers',
                        hintStyle: TextStyle(color: AppColors.txt4),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const AdminFLabel(text: 'EXERCISE CONTENT'),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _content,
                      maxLines: 8,
                      style: const TextStyle(
                        color: AppColors.txt,
                        fontSize: 13,
                        height: 1.6,
                      ),
                      decoration: const InputDecoration(
                        hintText:
                            'Write the full exercise instructions here...',
                        hintStyle: TextStyle(color: AppColors.txt4),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  if (_err != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _err!,
                      style: const TextStyle(color: AppColors.red, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        disabledBackgroundColor: AppColors.line2,
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
                          : Text(
                              widget.lesson != null
                                  ? 'Save Changes'
                                  : 'Publish Exercise',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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
}
