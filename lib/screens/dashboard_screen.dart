import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/application_record.dart';
import '../services/app_state.dart';
import '../widgets/metric_tile.dart';
import '../widgets/modern_ui.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final applications = state.timeline;
        final savedJobs = state.savedJobs;
        final successPercent = (state.successRate * 100).round();

        final name = state.profile.name.trim().isEmpty
            ? 'there'
            : state.profile.name.trim().split(' ').first;

        return ModernPage(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good day,',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: ModernColors.muted,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PurpleHero(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your resume match avg',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.76),
                                  ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$successPercent%',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            successPercent >= 60
                                ? 'On track'
                                : 'Needs improvement',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: successPercent / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 680 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: columns == 4 ? 1.45 : 1.18,
                  children: [
                    MetricTile(
                      icon: Icons.near_me_outlined,
                      label: 'Applications',
                      value: applications.length.toString(),
                    ),
                    MetricTile(
                      icon: Icons.calendar_month_outlined,
                      label: 'Interviews',
                      value:
                          (state.statusCounts[ApplicationStatus.interviewing] ??
                                  0)
                              .toString(),
                      accent: ModernColors.amber,
                    ),
                    MetricTile(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Offers',
                      value: (state.statusCounts[ApplicationStatus.offer] ?? 0)
                          .toString(),
                      accent: ModernColors.mint,
                    ),
                    MetricTile(
                      icon: Icons.bookmark_outline,
                      label: 'Saved Jobs',
                      value: savedJobs.length.toString(),
                      accent: ModernColors.violet,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _AnalyticsPanel(state: state),
            const SizedBox(height: 24),
            Text(
              'Application timeline',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (applications.isEmpty)
              const EmptyActionCard(
                icon: Icons.work_outline,
                title: 'Start Your Search',
                message: 'Browse jobs and track applications here',
              )
            else
              ...applications.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ApplicationCard(record: record),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Saved jobs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (savedJobs.isEmpty)
              const Text('Saved jobs will appear here.')
            else
              ...savedJobs.take(8).map(
                    (job) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bookmark),
                      title: Text(job.title),
                      subtitle: Text(job.company),
                      trailing: Text(job.salaryLabel),
                    ),
                  ),
          ],
        );
      },
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = state.applications.length;

    return ModernCard(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pipeline analytics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            for (final status in ApplicationStatus.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StatusRow(
                  label: status.label,
                  count: state.statusCounts[status] ?? 0,
                  total: total,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.count,
    required this.total,
  });

  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              count.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: value),
      ],
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.record});

  final ApplicationRecord record;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = Theme.of(context);
    final formatter = DateFormat('MMM d, yyyy');

    return ModernCard(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.jobTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(record.company),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Application actions',
                  onSelected: (value) {
                    if (value == 'notes') {
                      _showNotesDialog(context, record);
                    }
                    if (value == 'delete') {
                      state.removeApplication(record);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'notes',
                      child: ListTile(
                        leading: Icon(Icons.notes),
                        title: Text('Notes'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ApplicationStatus>(
              key: ValueKey('${record.id}-${record.status.name}'),
              initialValue: record.status,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.flag_outlined),
                labelText: 'Status',
              ),
              items: ApplicationStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    ),
                  )
                  .toList(),
              onChanged: (status) {
                if (status != null) {
                  state.updateApplicationStatus(record, status);
                }
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Updated ${formatter.format(record.updatedAt)}'),
              ],
            ),
            if (record.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                record.notes,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showNotesDialog(
    BuildContext context,
    ApplicationRecord record,
  ) async {
    final controller = TextEditingController(text: record.notes);
    final state = context.read<AppState>();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Application notes'),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            alignLabelWithHint: true,
            labelText: 'Notes',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              state.updateApplicationNotes(record, controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
  }
}
