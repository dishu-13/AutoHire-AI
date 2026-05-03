import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/application_record.dart';
import '../services/app_state.dart';
import '../widgets/modern_ui.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key, this.onBrowseJobs});

  final VoidCallback? onBrowseJobs;

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  ApplicationStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final records = state.timeline.where((record) {
          return _filter == null || record.status == _filter;
        }).toList();

        return ModernPage(
          children: [
            Text(
              'Your journey',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ModernColors.muted,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Applications',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 22),
            _StatusTabs(
              selected: _filter,
              onSelected: (status) => setState(() => _filter = status),
            ),
            const SizedBox(height: 28),
            if (records.isEmpty)
              EmptyActionCard(
                icon: Icons.inbox_outlined,
                title: 'No applications yet',
                message: 'Apply to jobs to track them here',
                actionLabel: 'Browse Jobs',
                onAction: widget.onBrowseJobs,
              )
            else
              ...records.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _TrackedApplicationCard(record: record),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.selected,
    required this.onSelected,
  });

  final ApplicationStatus? selected;
  final ValueChanged<ApplicationStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = <({String label, ApplicationStatus? value})>[
      (label: 'All', value: null),
      (label: 'Applied', value: ApplicationStatus.applied),
      (label: 'Interview', value: ApplicationStatus.interviewing),
      (label: 'Offer', value: ApplicationStatus.offer),
      (label: 'Rejected', value: ApplicationStatus.rejected),
    ];

    return ModernCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: tabs.map((tab) {
          final active = selected == tab.value;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => onSelected(tab.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: ModernColors.purple.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tab.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? ModernColors.purple : ModernColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TrackedApplicationCard extends StatelessWidget {
  const _TrackedApplicationCard({required this.record});

  final ApplicationRecord record;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final formatter = DateFormat('MMM d');
    final theme = Theme.of(context);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ModernIconBox(icon: Icons.task_alt),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.jobTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.company,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatter.format(record.updatedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ModernColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }
}
