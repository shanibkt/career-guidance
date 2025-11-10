// Flutter Mobile Resume Builder
// Single-file Flutter widget (lib/screens/resume_builder.dart)

import 'package:flutter/material.dart';

class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({Key? key}) : super(key: key);

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  final _nameController = TextEditingController(text: 'Jane Doe');
  final _titleController = TextEditingController(text: 'Software Engineer');
  final _emailController = TextEditingController(text: 'jane.doe@email.com');
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  final _summaryController = TextEditingController(
    text:
        'Passionate developer with experience in Flutter, React and backend integration.',
  );

  List<String> skills = ['Flutter', 'Dart', 'Firebase'];
  List<Experience> experiences = [
    Experience(
      role: 'Frontend Developer',
      company: 'Techify',
      period: '2022 - Present',
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  void addSkill() {
    setState(() => skills.add(''));
  }

  void addExperience() {
    setState(
      () => experiences.add(Experience(role: '', company: '', period: '')),
    );
  }

  void saveDraft() {
    // TODO: implement persistence (local DB or cloud)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Preview')));
  }

  void exportPdf() {
    // TODO: integrate printing or pdf package (e.g., printing, pdf)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export PDF (not implemented)')),
    );
  }

  void aiImproveSummary() {
    // Placeholder simple improvement — integrate real AI later
    setState(
      () => _summaryController.text =
          _summaryController.text +
          ' Enthusiastic team player focused on delivering impact.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Resume Builder',
          style: TextStyle(color: Color(0xFF3B3F8C)),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Card-like scrollable area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Personal Info
                          const SectionTitle(title: 'Personal Info'),
                          const SizedBox(height: 8),
                          ThemedTextField(
                            controller: _nameController,
                            hint: 'Full name',
                          ),
                          const SizedBox(height: 8),
                          ThemedTextField(
                            controller: _titleController,
                            hint: 'Job title',
                          ),
                          const SizedBox(height: 8),
                          ThemedTextField(
                            controller: _emailController,
                            hint: 'Email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 8),
                          ThemedTextField(
                            controller: _phoneController,
                            hint: 'Phone',
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 16),

                          // Summary
                          const SectionTitle(title: 'Professional Summary'),
                          const SizedBox(height: 8),
                          ThemedMultiLineField(
                            controller: _summaryController,
                            hint: 'Describe your experience and strengths',
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: aiImproveSummary,
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('AI Improve'),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Experience
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SectionTitle(title: 'Experience'),
                              TextButton.icon(
                                onPressed: addExperience,
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          Column(
                            children: experiences
                                .asMap()
                                .entries
                                .map(
                                  (entry) => ExperienceCard(
                                    key: ValueKey(entry.key),
                                    experience: entry.value,
                                    onChanged: (exp) => setState(
                                      () => experiences[entry.key] = exp,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),

                          const SizedBox(height: 12),

                          // Skills
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SectionTitle(title: 'Skills'),
                              TextButton.icon(
                                onPressed: addSkill,
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: skills
                                .asMap()
                                .entries
                                .map(
                                  (e) => SkillChip(
                                    key: ValueKey(e.key),
                                    index: e.key,
                                    value: e.value,
                                    onChanged: (val) {
                                      setState(() => skills[e.key] = val);
                                    },
                                    onRemove: () {
                                      setState(() => skills.removeAt(e.key));
                                    },
                                  ),
                                )
                                .toList(),
                          ),

                          const SizedBox(height: 18),

                          // Live preview
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _titleController.text,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${_emailController.text} • ${_phoneController.text}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Summary',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _summaryController.text,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Skills',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: skills
                                      .map(
                                        (s) => Chip(
                                          label: Text(s.isEmpty ? 'Skill' : s),
                                          backgroundColor: Colors.white24,
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom action row
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: saveDraft,
                      icon: const Icon(Icons.table_view),
                      label: const Text('Preview'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          153,
                          134,
                          134,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: exportPdf,
                      icon: const Icon(
                        Icons.download_outlined,
                        color: Color(0xFF3B3F8C),
                      ),
                      label: const Text(
                        'Export PDF',
                        style: TextStyle(color: Color(0xFF3B3F8C)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3B3F8C)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
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

class Experience {
  String role;
  String company;
  String period;

  Experience({required this.role, required this.company, required this.period});
}

class ExperienceCard extends StatefulWidget {
  final Experience experience;
  final ValueChanged<Experience> onChanged;

  const ExperienceCard({
    Key? key,
    required this.experience,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<ExperienceCard> {
  late TextEditingController role;
  late TextEditingController company;
  late TextEditingController period;

  @override
  void initState() {
    super.initState();
    role = TextEditingController(text: widget.experience.role);
    company = TextEditingController(text: widget.experience.company);
    period = TextEditingController(text: widget.experience.period);
  }

  @override
  void dispose() {
    role.dispose();
    company.dispose();
    period.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(
      Experience(role: role.text, company: company.text, period: period.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFF3F4FF),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ThemedTextField(
              controller: role,
              hint: 'Role',
              onChanged: (_) => _notify(),
            ),
            const SizedBox(height: 8),
            ThemedTextField(
              controller: company,
              hint: 'Company',
              onChanged: (_) => _notify(),
            ),
            const SizedBox(height: 8),
            ThemedTextField(
              controller: period,
              hint: 'Period',
              onChanged: (_) => _notify(),
            ),
          ],
        ),
      ),
    );
  }
}

class SkillChip extends StatefulWidget {
  final int index;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  const SkillChip({
    Key? key,
    required this.index,
    required this.value,
    required this.onChanged,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<SkillChip> createState() => _SkillChipState();
}

class _SkillChipState extends State<SkillChip> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              decoration: const InputDecoration.collapsed(hintText: 'Skill'),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: widget.onRemove,
            child: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    );
  }
}

class ThemedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const ThemedTextField({
    Key? key,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F8FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

class ThemedMultiLineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const ThemedMultiLineField({
    Key? key,
    required this.controller,
    required this.hint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F8FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}
