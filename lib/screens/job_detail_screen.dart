import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/job.dart';
import '../services/app_state.dart';
import '../widgets/modern_ui.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final description = _stripHtml(job.description);

    return Scaffold(
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, child) {
            final saved = state.isJobSaved(job.id);
            final tracked = state.isTracked(job.id);

            return ModernPage(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Job details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: saved ? 'Remove saved job' : 'Save job',
                      onPressed: () => state.toggleSaveJob(job),
                      icon:
                          Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                PurpleHero(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ModernIconBox(
                            icon: Icons.work_outline,
                            background: Colors.white24,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  job.company,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.82),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DetailChip(
                            icon: Icons.place_outlined,
                            label: job.location,
                          ),
                          _DetailChip(
                            icon: Icons.sell_outlined,
                            label: job.salaryLabel,
                          ),
                          _DetailChip(
                            icon: Icons.schedule,
                            label: job.postedLabel,
                          ),
                          _DetailChip(icon: Icons.public, label: job.source),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Role overview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        description.isEmpty
                            ? 'No job description was provided by this source.'
                            : description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _openUrl(job.url),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Apply'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: tracked
                                  ? null
                                  : () => state.addToTracker(job),
                              icon: Icon(
                                tracked ? Icons.check_circle : Icons.add_task,
                              ),
                              label: Text(tracked ? 'Tracked' : 'Track'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 230),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
