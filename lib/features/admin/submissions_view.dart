import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sprova/features/admin/app_colors.dart';

class SubmissionsView extends StatefulWidget {
  final SupabaseClient sb;
  const SubmissionsView({super.key, required this.sb});
  @override
  State<SubmissionsView> createState() => _SubmissionsViewState();
}

class _SubmissionsViewState extends State<SubmissionsView> {
  List<Map<String, dynamic>> _subs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.sb
          .from('submissions')
          .select()
          .order('submitted_at', ascending: false);
      if (mounted) {
        setState(() {
          _subs = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2),
      );
    if (_subs.isEmpty)
      return const Center(
        child: Text('No submissions yet.', style: TextStyle(color: AppColors.txt3)),
      );

    return RefreshIndicator(
      color: AppColors.amber,
      backgroundColor: AppColors.card,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: _subs.length,
        itemBuilder: (_, i) {
          final s = _subs[i];
          final email = (s['user_email'] as String?) ?? '';
          final day = (s['day'] as int?) ?? 0;
          final content = (s['content'] as String?) ?? '';
          final date = s['submitted_at'] != null
              ? DateTime.parse(s['submitted_at'] as String).toLocal()
              : null;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
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
                        color: const Color(0xFF1C1208),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Day $day',
                        style: const TextStyle(
                          color: AppColors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        email,
                        style: const TextStyle(color: AppColors.txt3, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (date != null)
                      Text(
                        '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppColors.txt4, fontSize: 10),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.txt2,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
