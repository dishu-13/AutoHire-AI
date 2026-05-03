import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/job.dart';
import 'modern_ui.dart';

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.isSaved,
    required this.isTracked,
    required this.onSave,
    required this.onTrack,
    required this.onView,
    this.matchScore,
  });

  final Job job;
  final bool isSaved;
  final bool isTracked;
  final VoidCallback onSave;
  final VoidCallback onTrack;
  final VoidCallback onView;
  final int? matchScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = _stripHtml(job.description);

    return ModernCard(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernIconBox(
                  icon: Icons.work_outline,
                  background: ModernColors.softPurple,
                  color: theme.colorScheme.primary,
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.company,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (matchScore != null && matchScore! > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: matchScore! >= 70
                          ? Colors.green.withOpacity(0.2)
                          : matchScore! >= 50
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$matchScore% Match',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: matchScore! >= 70
                            ? Colors.green.shade700
                            : matchScore! >= 50
                                ? Colors.orange.shade700
                                : Colors.red.shade700,
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: isSaved ? 'Remove saved job' : 'Save job',
                  onPressed: onSave,
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _JobPill(icon: Icons.place_outlined, label: job.location),
                _JobPill(icon: Icons.sell_outlined, label: job.salaryLabel),
                _JobPill(icon: Icons.schedule, label: job.postedLabel),
                _JobPill(icon: Icons.category_outlined, label: job.category),
                _JobPill(icon: Icons.public, label: job.source),
                if (job.isIndiaFriendly)
                  const _JobPill(
                      icon: Icons.flag_outlined, label: 'India-friendly'),
                if (job.hasFastHiringSignal)
                  const _JobPill(
                      icon: Icons.bolt_outlined, label: 'Fast signal'),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.article_outlined),
                label: const Text('View details'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openUrl(job.url),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Apply'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isTracked ? null : onTrack,
                    icon: Icon(
                      isTracked ? Icons.check_circle : Icons.add_task,
                    ),
                    label: Text(isTracked ? 'Tracked' : 'Track'),
                  ),
                ),
              ],
            ),
          ],
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
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _JobPill extends StatelessWidget {
  const _JobPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
