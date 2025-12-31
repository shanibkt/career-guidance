import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/job.dart';
import '../../../providers/job_provider.dart';
import '../../../services/local/storage_service.dart';

class PersonalizedJobsWidget extends StatefulWidget {
  const PersonalizedJobsWidget({super.key});

  @override
  State<PersonalizedJobsWidget> createState() => _PersonalizedJobsWidgetState();
}

class _PersonalizedJobsWidgetState extends State<PersonalizedJobsWidget> {
  String? _careerTitle;
  List<String>? _userSkills;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPersonalizedJobs();
  }

  Future<void> _loadPersonalizedJobs() async {
    final selected = await StorageService.loadSelectedCareer();
    final careerTitle = selected?['careerTitle'] as String?;

    // Load user skills from profile if available
    final profile = await StorageService.loadProfile();
    final skills = profile?['skills'] as List<String>? ?? [];

    setState(() {
      _careerTitle = careerTitle;
      _userSkills = skills;
      _isLoading = false;
    });

    if (mounted && _careerTitle != null) {
      // ignore: use_build_context_synchronously
      context.read<JobProvider>().getPersonalizedJobs(
        _careerTitle,
        _userSkills,
      );
    }
  }

  Future<void> _openJobUrl(BuildContext context, Job job) async {
    // Validate URL
    if (job.url == null || job.url!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job URL is not available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      // Parse and validate URL
      final uri = Uri.tryParse(job.url!);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid job URL'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening job posting...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Launch URL in external browser
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot open job URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobProvider>(
      builder: (context, provider, _) {
        if (_isLoading || provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.personalizedJobs.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildPersonalizedJobsList(context, provider);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'No Personalized Jobs Found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _careerTitle == null
                  ? 'Complete your profile to see personalized recommendations'
                  : 'Add more skills to get better job matches',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_careerTitle == null)
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/reg_profile'),
                icon: const Icon(Icons.person),
                label: const Text('Complete Profile'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                icon: const Icon(Icons.edit),
                label: const Text('Update Profile'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedJobsList(
    BuildContext context,
    JobProvider provider,
  ) {
    return RefreshIndicator(
      onRefresh: () => provider.getPersonalizedJobs(_careerTitle, _userSkills),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personalized for you',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_careerTitle != null)
                Chip(
                  label: Text(_careerTitle!),
                  backgroundColor: Colors.blue[50],
                ),
              const SizedBox(height: 16),
            ],
          ),

          // Jobs List
          ...provider.personalizedJobs.asMap().entries.map((entry) {
            final index = entry.key;
            final job = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPersonalizedJobCard(context, job, provider, index),
            );
          }).toList(),

          if (provider.personalizedJobs.length > 3)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to full jobs search
                    Navigator.pushNamed(context, '/jobs');
                  },
                  child: const Text('View All Jobs'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedJobCard(
    BuildContext context,
    Job job,
    JobProvider provider,
    int index,
  ) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.blue[50]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rank Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#${index + 1} Match',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (job.matchPercentage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${job.matchPercentage!.toStringAsFixed(0)}% Match',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Job Title
              Text(
                job.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Company
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      job.company,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      job.location,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Job Details Row
              Row(
                children: [
                  if (job.jobType != null)
                    Chip(
                      label: Text(job.jobType!),
                      backgroundColor: Colors.blue[50],
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  if (job.experienceLevel != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Chip(
                        label: Text(job.experienceLevel!),
                        backgroundColor: Colors.orange[50],
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Salary Info
              if (job.salaryMin != null && job.salaryMax != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${job.salaryCurrency} ${job.salaryMin} - ${job.salaryMax} per year',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Skills Match
              if (job.requiredSkills.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required Skills',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: job.requiredSkills.take(5).map((skill) {
                        final hasSkill = _userSkills?.contains(skill) ?? false;
                        return Chip(
                          label: Text(skill),
                          backgroundColor: hasSkill
                              ? Colors.green[50]
                              : Colors.grey[100],
                          labelStyle: TextStyle(
                            color: hasSkill ? Colors.green : Colors.grey,
                          ),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                        );
                      }).toList(),
                    ),
                    if (job.requiredSkills.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '+${job.requiredSkills.length - 5} more',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => provider.toggleSaveJob(job),
                      icon: Icon(
                        job.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                      ),
                      label: Text(job.isSaved ? 'Saved' : 'Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openJobUrl(context, job),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('View Job'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
