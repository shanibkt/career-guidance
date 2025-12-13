import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/job.dart';
import '../../../models/job_filter.dart';
import '../../../providers/job_provider.dart';
import '../../../services/local/storage_service.dart';
import '../widgets/job_filter_widget.dart';

class JobFinderPage extends StatefulWidget {
  const JobFinderPage({super.key});

  @override
  State<JobFinderPage> createState() => _JobFinderPageState();
}

class _JobFinderPageState extends State<JobFinderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  late JobProvider jobProvider;
  String? _careerTitle;
  List<String>? _userSkills;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    jobProvider = context.read<JobProvider>();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    debugPrint('🔍 JobFinder: Loading user data...');
    final selected = await StorageService.loadSelectedCareer();
    debugPrint('🔍 JobFinder: Selected career data: $selected');
    final careerTitle = selected?['careerName'] as String?;
    debugPrint('🔍 JobFinder: Career title: $careerTitle');
    // Load user skills from profile if available
    final profile = await StorageService.loadProfile();
    final skillsData = profile?['skills'];
    final skills = skillsData != null
        ? (skillsData is List ? skillsData.cast<String>() : <String>[])
        : <String>[];
    debugPrint('🔍 JobFinder: User skills: $skills');

    setState(() {
      _careerTitle = careerTitle;
      _userSkills = skills;
    });

    // Load personalized jobs
    if (_careerTitle != null) {
      debugPrint('🔍 JobFinder: Loading personalized jobs for: $_careerTitle');
      jobProvider.getPersonalizedJobs(_careerTitle, _userSkills);
    } else {
      debugPrint('⚠️ JobFinder: No career title, skipping personalized jobs');
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search query')),
      );
      return;
    }

    final filter = JobSearchFilter(query: query);
    jobProvider.searchJobs(filter);
    _tabController.animateTo(1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Job Finder'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.star), text: 'For You'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
            Tab(icon: Icon(Icons.bookmark), text: 'Saved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // For You Tab - Personalized Jobs
          _buildPersonalizedTab(),
          // Search Tab
          _buildSearchTab(),
          // Saved Tab
          _buildSavedTab(),
        ],
      ),
    );
  }

  Widget _buildPersonalizedTab() {
    return Consumer<JobProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.personalizedJobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No personalized jobs found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching for jobs or update your profile',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              jobProvider.getPersonalizedJobs(_careerTitle, _userSkills),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.personalizedJobs.length,
            itemBuilder: (context, index) {
              return _buildJobCard(provider.personalizedJobs[index], provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchTab() {
    return Consumer<JobProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search jobs (e.g., Flutter Developer)',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _performSearch(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _performSearch,
                          icon: const Icon(Icons.search),
                          label: const Text('Search'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.tune),
                        tooltip: 'Filters',
                        onPressed: () => _showFilterDialog(provider),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Results
            if (provider.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (provider.errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${provider.errorMessage}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          provider.clearError();
                          _performSearch();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (provider.jobs.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No jobs found. Try a different search.'),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _performSearch,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        provider.jobs.length + (provider.hasNextPage ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.jobs.length) {
                        // Load more button
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: provider.isLoadingMore
                              ? const CircularProgressIndicator()
                              : Center(
                                  child: ElevatedButton(
                                    onPressed: () => provider.loadMore(),
                                    child: const Text('Load More'),
                                  ),
                                ),
                        );
                      }
                      return _buildJobCard(provider.jobs[index], provider);
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSavedTab() {
    return Consumer<JobProvider>(
      builder: (context, provider, _) {
        // Load saved jobs on first build using post-frame callback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!provider.isLoading &&
              provider.savedJobs.isEmpty &&
              provider.errorMessage == null) {
            provider.loadSavedJobs();
          }
        });

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.savedJobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No saved jobs yet'),
                const SizedBox(height: 8),
                const Text('Save jobs to view them here'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadSavedJobs(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.savedJobs.length,
            itemBuilder: (context, index) {
              return _buildJobCard(provider.savedJobs[index], provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildJobCard(Job job, JobProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        job.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.company,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job.location,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    job.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                    color: job.isSaved ? Colors.blue : null,
                  ),
                  onPressed: () => provider.toggleSaveJob(job),
                ),
              ],
            ),
            const Divider(height: 16),
            if (job.matchPercentage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${job.matchPercentage!.toStringAsFixed(0)}% Match',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (job.jobType != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Chip(
                  label: Text(job.jobType!),
                  backgroundColor: Colors.blue[50],
                ),
              ),
            if (job.salaryMin != null && job.salaryMax != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${job.salaryCurrency} ${job.salaryMin} - ${job.salaryMax}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (job.url != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Opening: ${job.url}'),
                            action: SnackBarAction(
                              label: 'Copy URL',
                              onPressed: () {
                                // Copy to clipboard logic
                              },
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('View Job'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => provider.applyForJob(job),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(JobProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => JobFilterWidget(
          scrollController: scrollController,
          onApplyFilter: (filter) {
            provider.searchJobs(filter);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
