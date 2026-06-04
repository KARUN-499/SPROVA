// ignore_for_file: inference_failure_on_function_invocation

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sprova/features/admin/app_colors.dart';
import 'package:sprova/features/admin/admin_widgets.dart';

class EnrollmentsView extends StatefulWidget {
  final SupabaseClient sb;
  const EnrollmentsView({super.key, required this.sb});
  @override
  State<EnrollmentsView> createState() => _EnrollmentsViewState();
}

class _EnrollmentsViewState extends State<EnrollmentsView> {
  List<Map<String, dynamic>> _enrollments = [];
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
          .from('enrollments')
          .select()
          .order('enrolled_at', ascending: false);
      if (mounted) {
        setState(() {
          _enrollments = List<Map<String, dynamic>>.from(res);
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
        child: CircularProgressIndicator(
          color: AppColors.amber,
          strokeWidth: 2,
        ),
      );

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AdminStatPill(label: 'TOTAL', value: '${_enrollments.length}'),
              Container(width: 1, height: 24, color: AppColors.line),
              AdminStatPill(
                label: 'COMPLETED',
                value:
                    '${_enrollments.where((e) => e['payment_status'] == 'completed').length}',
              ),
              Container(width: 1, height: 24, color: AppColors.line),
              AdminStatPill(
                label: 'SEATS LEFT',
                value:
                    '${15 - _enrollments.where((e) => e['payment_status'] == 'completed').length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.amber,
            backgroundColor: AppColors.card,
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _enrollments.length,
              itemBuilder: (_, i) {
                final e = _enrollments[i];
                final email = (e['user_email'] as String?) ?? '';
                final track = (e['track'] as String?) ?? 'Unknown';

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: widget.sb
                      .from('submissions')
                      .select()
                      .eq('user_email', email)
                      .eq('week', 1),
                  builder: (context, snapshot) {
                    final subCount = snapshot.data?.length ?? 0;
                    final isLow = subCount < 4;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isLow
                            ? AppColors.red.withOpacity(0.2)
                            : AppColors.card,
                        border: Border.all(
                          color: isLow ? AppColors.red : AppColors.line,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          email,
                          style: const TextStyle(
                            color: AppColors.txt,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'Track: $track | Submissions (W1): $subCount',
                          style: const TextStyle(
                            color: AppColors.txt3,
                            fontSize: 11,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.txt4,
                        ),
                        onTap: () => _openDetails(context, email),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _openDetails(BuildContext context, String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubmissionDetailsView(sb: widget.sb, email: email),
    );
  }
}

class SubmissionDetailsView extends StatefulWidget {
  final SupabaseClient sb;
  final String email;
  const SubmissionDetailsView({
    super.key,
    required this.sb,
    required this.email,
  });
  @override
  State<SubmissionDetailsView> createState() => _SubmissionDetailsViewState();
}

class _SubmissionDetailsViewState extends State<SubmissionDetailsView> {
  List<Map<String, dynamic>> _subs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await widget.sb
          .from('submissions')
          .select()
          .eq('user_email', widget.email)
          .order('submitted_at');
      setState(() {
        _subs = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.8,
    maxChildSize: 0.95,
    builder: (_, scroll) => Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.email,
                  style: const TextStyle(
                    color: AppColors.txt,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.txt3),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.amber),
                  )
                : ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.all(20),
                    itemCount: _subs.length,
                    itemBuilder: (_, i) {
                      final s = _subs[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Day ${s['day']}',
                              style: const TextStyle(
                                color: AppColors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (s['content'] as String?) ?? '',
                              style: const TextStyle(
                                color: AppColors.txt2,
                                fontSize: 13,
                              ),
                            ),
                            if (s['ai_feedback'] != null) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'AI FEEDBACK:',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                (s['ai_feedback'] as String?) ?? '',
                                style: const TextStyle(
                                  color: AppColors.txt3,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
