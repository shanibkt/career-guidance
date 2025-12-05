import 'package:flutter/material.dart';
import '../../../models/job_filter.dart';

class JobFilterWidget extends StatefulWidget {
  final ScrollController scrollController;
  final Function(JobSearchFilter) onApplyFilter;

  const JobFilterWidget({
    super.key,
    required this.scrollController,
    required this.onApplyFilter,
  });

  @override
  State<JobFilterWidget> createState() => _JobFilterWidgetState();
}

class _JobFilterWidgetState extends State<JobFilterWidget> {
  String? _selectedJobType;
  String? _selectedExperience;
  String? _selectedCountry;
  String? _selectedDatePosted;
  String? _salaryMin;
  String? _salaryMax;
  List<String> _selectedSkills = [];
  final TextEditingController _skillController = TextEditingController();

  final List<String> jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Temporary',
    'Freelance'
  ];
  final List<String> experienceLevels = ['Entry', 'Mid', 'Senior', 'Executive'];
  final List<String> countries = [
    'US',
    'UK',
    'Canada',
    'Australia',
    'India',
    'Germany',
    'France'
  ];
  final List<String> dateOptions = [
    ('all', 'Anytime'),
    ('7', 'Last 7 days'),
    ('30', 'Last 30 days'),
    ('90', 'Last 90 days'),
  ]
      .map((e) => e.$1)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Job Type
            Text(
              'Job Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: jobTypes.map((type) {
                final isSelected = _selectedJobType == type;
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedJobType = selected ? type : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Experience Level
            Text(
              'Experience Level',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: experienceLevels.map((level) {
                final isSelected = _selectedExperience == level;
                return FilterChip(
                  label: Text(level),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedExperience = selected ? level : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Salary Range
            Text(
              'Salary Range (USD)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Min',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    onChanged: (value) => _salaryMin = value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Max',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    onChanged: (value) => _salaryMax = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Location/Country
            Text(
              'Country',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCountry,
              hint: const Text('Select country'),
              items: countries.map((country) {
                return DropdownMenuItem(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCountry = value);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Date Posted
            Text(
              'Date Posted',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedDatePosted ?? 'all',
              items: [
                const DropdownMenuItem(value: 'all', child: Text('Anytime')),
                const DropdownMenuItem(value: '7', child: Text('Last 7 days')),
                const DropdownMenuItem(value: '30', child: Text('Last 30 days')),
                const DropdownMenuItem(value: '90', child: Text('Last 90 days')),
              ],
              onChanged: (value) {
                setState(() => _selectedDatePosted = value ?? 'all');
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Skills
            Text(
              'Required Skills',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _skillController,
              decoration: InputDecoration(
                hintText: 'Add skill and press Enter',
                border: const OutlineInputBorder(),
                suffixIcon: _skillController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addSkill,
                      )
                    : null,
              ),
              onSubmitted: (_) => _addSkill(),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _selectedSkills.map((skill) {
                return Chip(
                  label: Text(skill),
                  onDeleted: () {
                    setState(() => _selectedSkills.remove(skill));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_selectedSkills.contains(skill)) {
      setState(() {
        _selectedSkills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedJobType = null;
      _selectedExperience = null;
      _selectedCountry = null;
      _selectedDatePosted = 'all';
      _salaryMin = null;
      _salaryMax = null;
      _selectedSkills.clear();
      _skillController.clear();
    });
  }

  void _applyFilters() {
    final filter = JobSearchFilter(
      jobType: _selectedJobType,
      experienceLevel: _selectedExperience,
      country: _selectedCountry?.toLowerCase(),
      datePosted: _selectedDatePosted ?? 'all',
      salaryMin: _salaryMin,
      salaryMax: _salaryMax,
      skills: _selectedSkills.isEmpty ? null : _selectedSkills,
    );

    widget.onApplyFilter(filter);
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }
}
