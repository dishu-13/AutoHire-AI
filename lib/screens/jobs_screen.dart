import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';

import '../services/ai_resume_service.dart';
import '../services/app_state.dart';
import '../widgets/job_card.dart';
import '../widgets/modern_ui.dart';
import 'job_detail_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  late final TextEditingController _roleController;
  late final TextEditingController _locationController;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _roleController = TextEditingController(text: state.roleFilter);
    _locationController = TextEditingController(text: state.locationFilter);
  }

  @override
  void dispose() {
    _roleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final jobs = state.filteredJobs;

        return RefreshIndicator(
          onRefresh: state.refreshJobs,
          child: ModernPage(
            children: [
              _JobsHero(
                roleController: _roleController,
                jobCount: jobs.length,
                totalCount: state.jobs.length,
                onFilterTap: () {
                  setState(() => _showFilters = !_showFilters);
                },
              ),
              if (_showFilters) ...[
                const SizedBox(height: 12),
                _FilterPanel(
                  locationController: _locationController,
                  onClear: () {
                    state.clearJobFilters();
                    _roleController.clear();
                    _locationController.clear();
                  },
                ),
              ],
              if (state.jobsError != null) ...[
                const SizedBox(height: 12),
                _StatusBanner(message: state.jobsError!),
              ],
              if (state.isLoadingJobs) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 20),
              if (jobs.isNotEmpty)
                Text(
                  'Latest roles',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              if (jobs.isNotEmpty) const SizedBox(height: 10),
              if (jobs.isEmpty)
                EmptyActionCard(
                  icon: Icons.search,
                  title: 'No jobs found',
                  message:
                      'Try a different search or pull down to refresh from live portals',
                  actionLabel: 'Clear filters',
                  onAction: () {
                    state.clearJobFilters();
                    _roleController.clear();
                    _locationController.clear();
                  },
                )
              else
                ...jobs.map(
                  (job) {
                    final resumeText = state.profile.resumeText;
                    final matchScore = resumeText.isNotEmpty 
                        ? const AiResumeService().calculateMatchScore(
                            resumeText: resumeText, 
                            targetJobDescription: '${job.title} ${job.description} ${job.category}',
                          ) 
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: JobCard(
                        job: job,
                        isSaved: state.isJobSaved(job.id),
                        isTracked: state.isTracked(job.id),
                        matchScore: matchScore,
                        onSave: () => state.toggleSaveJob(job),
                        onTrack: () => state.addToTracker(job),
                        onView: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => JobDetailScreen(job: job),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
              const _JobBoardsSection(),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

class _JobsHero extends StatelessWidget {
  const _JobsHero({
    required this.roleController,
    required this.jobCount,
    required this.totalCount,
    required this.onFilterTap,
  });

  final TextEditingController roleController;
  final int jobCount;
  final int totalCount;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return PurpleHero(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
                      'Discover your next',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.76),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dream Job',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$jobCount roles',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$totalCount live',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SearchBox(roleController: roleController),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onFilterTap,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
            ),
            icon: const Icon(Icons.tune),
            label: const Text('Filters'),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.roleController});

  final TextEditingController roleController;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final query = roleController.text.trim();
    final suggestions = state.searchSuggestionsFor(query);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: roleController,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            hintText: 'Job title, company, skill...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Colors.white),
            ),
          ),
          onChanged: state.setRoleFilter,
          onSubmitted: (_) => state.refreshJobs(),
        ),
        if (query.isNotEmpty && suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map(
                  (suggestion) => ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      roleController.text = suggestion;
                      state.setRoleFilter(suggestion);
                      state.refreshJobs();
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.locationController,
    required this.onClear,
  });

  final TextEditingController locationController;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return ModernCard(
      child: Column(
        children: [
          TextField(
            controller: locationController,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.place_outlined),
              labelText: 'Location',
            ),
            onChanged: state.setLocationFilter,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.flag_outlined),
            title: const Text('India-friendly roles'),
            subtitle: const Text('India, APAC, worldwide, or open remote'),
            value: state.indiaFriendlyOnly,
            onChanged: state.setIndiaFriendlyOnly,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.bolt_outlined),
            title: const Text('Fast hiring signals'),
            subtitle: const Text('Urgent, client, contract, quick feedback'),
            value: state.fastHiringOnly,
            onChanged: state.setFastHiringOnly,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.payments_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Slider(
                  min: 0,
                  max: 3000000,
                  divisions: 30,
                  value: state.minimumSalary.toDouble(),
                  label: state.minimumSalary == 0
                      ? 'Any listed salary'
                      : 'INR ${(state.minimumSalary / 100000).round()}L+',
                  onChanged: (value) => state.setMinimumSalary(value.round()),
                ),
              ),
              SizedBox(
                width: 78,
                child: Text(
                  state.minimumSalary == 0
                      ? 'Any'
                      : 'INR ${(state.minimumSalary / 100000).round()}L+',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close),
              label: const Text('Clear filters'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobBoardsSection extends StatelessWidget {
  const _JobBoardsSection();

  static const _boards = [
    ('Toptal', 'https://toptal.com'),
    ('Skip The Drive', 'https://skipthedrive.com'),
    ('NoDesk', 'https://nodesk.co'),
    ('RemoteHabits', 'https://remotehabits.com'),
    ('Remotive', 'https://remotive.com'),
    ('Remote4Me', 'https://remote4me.com'),
    ('Pangian', 'https://pangian.com'),
    ('Remotees', 'https://remotees.com'),
    ('justremote', 'https://justremote.co'),
    ('Remotecrew', 'https://remotecrew.io'),
    ('Europe Remotely', 'https://europeremotely.com'),
    ('FlexJobs', 'https://flexjobs.com'),
    ('Remote.co', 'https://remote.co'),
    ('We Work Remotely', 'https://weworkremotely.com'),
    ('Remote OK', 'https://remoteok.com'),
    ('AngelList', 'https://angel.co'),
    ('LinkedIn', 'https://linkedin.com'),
    ('Freelancer', 'https://freelancer.com'),
    ('Working Nomads', 'https://workingnomads.com'),
    ('SimplyHired', 'https://simplyhired.com'),
    ('Jobspresso', 'https://jobspresso.co'),
    ('Virtual Vocations', 'https://virtualvocations.com'),
    ('Glassdoor', 'https://glassdoor.com'),
    ('Monster', 'https://monster.com'),
  ];

  static const _resumeBuilders = [
    ('Canva', 'https://canva.com'),
    ('Resume Genius', 'https://resumegenius.com'),
    ('Zety', 'https://zety.com'),
    ('Novoresume', 'https://novoresume.com'),
    ('Resume.com', 'https://resume.com'),
    ('VisualCV', 'https://visualcv.com'),
  ];

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore 30+ Job Boards',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _boards
                .map((b) => ActionChip(
                      label: Text(b.$1),
                      onPressed: () => launchUrl(Uri.parse(b.$2)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Resume Builders',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _resumeBuilders
                .map((b) => ActionChip(
                      label: Text(b.$1),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      onPressed: () => launchUrl(Uri.parse(b.$2)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
