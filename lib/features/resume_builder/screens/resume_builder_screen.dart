import 'package:flutter/material.dart';

class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({super.key});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController(text: 'Jane Doe');
  final _titleController = TextEditingController(text: 'Software Engineer');
  final _emailController = TextEditingController(text: 'jane.doe@email.com');
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  final _locationController = TextEditingController(text: 'Mumbai, India');
  final _linkedinController = TextEditingController(
    text: 'linkedin.com/in/janedoe',
  );
  final _summaryController = TextEditingController(
    text:
        'Passionate software engineer with 3+ years of experience in mobile app development. Specialized in Flutter, React, and backend integration.',
  );

  List<String> skills = [
    'Flutter',
    'Dart',
    'Firebase',
    'React',
    'Node.js',
    'SQL',
  ];
  List<Experience> experiences = [
    Experience(
      role: 'Senior Flutter Developer',
      company: 'Techify Solutions',
      period: '2022 - Present',
      description:
          'Lead developer for mobile applications, managing team of 3 developers.',
    ),
    Experience(
      role: 'Frontend Developer',
      company: 'Digital Innovations',
      period: '2020 - 2022',
      description:
          'Developed responsive web applications using React and TypeScript.',
    ),
  ];

  List<Education> educationList = [
    Education(
      degree: 'B.Tech in Computer Science',
      institution: 'IIT Mumbai',
      year: '2016 - 2020',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // ATS Score Calculation
  Map<String, dynamic> calculateATSScore() {
    int score = 0;
    List<String> strengths = [];
    List<String> improvements = [];

    // Check contact information (20 points)
    if (_nameController.text.isNotEmpty && _nameController.text.length > 3) {
      score += 5;
      strengths.add('Name provided');
    } else {
      improvements.add('Add your full name');
    }

    if (_emailController.text.contains('@') &&
        _emailController.text.contains('.')) {
      score += 5;
      strengths.add('Valid email');
    } else {
      improvements.add('Add valid email address');
    }

    if (_phoneController.text.isNotEmpty &&
        _phoneController.text.length >= 10) {
      score += 5;
      strengths.add('Phone number provided');
    } else {
      improvements.add('Add phone number');
    }

    if (_locationController.text.isNotEmpty) {
      score += 5;
      strengths.add('Location mentioned');
    } else {
      improvements.add('Add your location');
    }

    // Check professional summary (15 points)
    if (_summaryController.text.isNotEmpty) {
      if (_summaryController.text.length > 100) {
        score += 15;
        strengths.add('Detailed professional summary');
      } else {
        score += 8;
        improvements.add(
          'Expand your professional summary (aim for 100+ characters)',
        );
      }
    } else {
      improvements.add('Add professional summary');
    }

    // Check skills (20 points)
    final validSkills = skills
        .where((s) => s.isNotEmpty && s.length > 2)
        .toList();
    if (validSkills.length >= 6) {
      score += 20;
      strengths.add('${validSkills.length} skills listed');
    } else if (validSkills.length >= 3) {
      score += 10;
      improvements.add('Add more skills (aim for at least 6)');
    } else {
      improvements.add('Add relevant skills');
    }

    // Check experience (25 points)
    final validExperiences = experiences
        .where((e) => e.role.isNotEmpty && e.company.isNotEmpty)
        .toList();

    if (validExperiences.length >= 2) {
      score += 15;
      strengths.add('${validExperiences.length} work experiences');

      // Check if experiences have descriptions
      final withDescriptions = validExperiences
          .where((e) => e.description.isNotEmpty && e.description.length > 50)
          .length;

      if (withDescriptions >= 2) {
        score += 10;
        strengths.add('Detailed job descriptions');
      } else {
        score += 5;
        improvements.add('Add detailed descriptions to all experiences');
      }
    } else if (validExperiences.length == 1) {
      score += 10;
      improvements.add('Add more work experiences');
    } else {
      improvements.add('Add work experience');
    }

    // Check education (15 points)
    final validEducation = educationList
        .where((e) => e.degree.isNotEmpty && e.institution.isNotEmpty)
        .toList();

    if (validEducation.isNotEmpty) {
      score += 15;
      strengths.add('Education background included');
    } else {
      improvements.add('Add education details');
    }

    // Check for action verbs and keywords (5 points)
    final actionVerbs = [
      'led',
      'developed',
      'managed',
      'created',
      'implemented',
      'designed',
      'built',
      'improved',
      'achieved',
      'delivered',
    ];
    final allText =
        '${_summaryController.text} ${experiences.map((e) => e.description).join(' ')}'
            .toLowerCase();

    final foundVerbs = actionVerbs
        .where((verb) => allText.contains(verb))
        .length;
    if (foundVerbs >= 3) {
      score += 5;
      strengths.add('Strong action verbs used');
    } else {
      improvements.add('Use more action verbs (led, developed, managed, etc.)');
    }

    // Ensure score is between 0-100
    score = score.clamp(0, 100);

    return {
      'score': score,
      'strengths': strengths,
      'improvements': improvements,
      'grade': score >= 80
          ? 'Excellent'
          : score >= 60
          ? 'Good'
          : score >= 40
          ? 'Fair'
          : 'Needs Improvement',
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _linkedinController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  void addSkill() {
    setState(() => skills.add('New Skill'));
  }

  void addExperience() {
    setState(
      () => experiences.add(
        Experience(role: '', company: '', period: '', description: ''),
      ),
    );
  }

  void addEducation() {
    setState(
      () => educationList.add(Education(degree: '', institution: '', year: '')),
    );
  }

  void removeExperience(int index) {
    setState(() => experiences.removeAt(index));
  }

  void removeEducation(int index) {
    setState(() => educationList.removeAt(index));
  }

  void showPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResumePreviewScreen(
          name: _nameController.text,
          title: _titleController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          location: _locationController.text,
          linkedin: _linkedinController.text,
          summary: _summaryController.text,
          skills: skills,
          experiences: experiences,
          education: educationList,
        ),
      ),
    );
  }

  void exportPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('PDF export feature coming soon!'),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void aiImproveSummary() {
    if (_summaryController.text.isEmpty) {
      _summaryController.text =
          'Dedicated professional with strong technical skills and proven track record of success.';
    } else {
      _summaryController.text =
          '${_summaryController.text} Demonstrated expertise in delivering scalable solutions and collaborating with cross-functional teams.';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF2D3142),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Resume Builder',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue.shade700,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Colors.blue.shade700,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                tabs: const [
                  Tab(text: 'Edit Details'),
                  Tab(text: 'Quick Preview'),
                  Tab(text: 'ATS Score'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEditTab(),
                  _buildPreviewTab(),
                  _buildATSScoreTab(),
                ],
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: showPreview,
                      icon: const Icon(Icons.visibility, size: 20),
                      label: const Text('Full Preview'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: exportPdf,
                      icon: Icon(
                        Icons.download,
                        size: 20,
                        color: Colors.blue.shade700,
                      ),
                      label: Text(
                        'Export PDF',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue.shade700, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Section
          _buildSectionHeader(
            'Personal Information',
            Icons.person,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _nameController,
            hint: 'Full Name',
            icon: Icons.badge,
          ),
          const SizedBox(height: 12),
          _buildModernTextField(
            controller: _titleController,
            hint: 'Job Title / Position',
            icon: Icons.work,
          ),
          const SizedBox(height: 12),
          _buildModernTextField(
            controller: _emailController,
            hint: 'Email Address',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildModernTextField(
            controller: _phoneController,
            hint: 'Phone Number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildModernTextField(
            controller: _locationController,
            hint: 'Location (City, Country)',
            icon: Icons.location_on,
          ),
          const SizedBox(height: 12),
          _buildModernTextField(
            controller: _linkedinController,
            hint: 'LinkedIn Profile',
            icon: Icons.link,
          ),

          const SizedBox(height: 32),

          // Professional Summary Section
          _buildSectionHeader(
            'Professional Summary',
            Icons.description,
            Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildModernTextArea(
            controller: _summaryController,
            hint: 'Write a compelling summary about your experience and skills',
            maxLines: 5,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: aiImproveSummary,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('AI Enhance'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple.shade700,
                backgroundColor: Colors.purple.shade50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Experience Section
          _buildSectionHeader(
            'Work Experience',
            Icons.business_center,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          ...experiences.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ExperienceCard(
                experience: entry.value,
                onChanged: (exp) =>
                    setState(() => experiences[entry.key] = exp),
                onDelete: () => removeExperience(entry.key),
              ),
            ),
          ),
          _buildAddButton('Add Experience', addExperience),

          const SizedBox(height: 32),

          // Education Section
          _buildSectionHeader('Education', Icons.school, Colors.green),
          const SizedBox(height: 16),
          ...educationList.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: EducationCard(
                education: entry.value,
                onChanged: (edu) =>
                    setState(() => educationList[entry.key] = edu),
                onDelete: () => removeEducation(entry.key),
              ),
            ),
          ),
          _buildAddButton('Add Education', addEducation),

          const SizedBox(height: 32),

          // Skills Section
          _buildSectionHeader('Skills', Icons.star, Colors.pink),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...skills.asMap().entries.map(
                (e) => SkillChip(
                  key: ValueKey(e.key),
                  value: e.value,
                  onChanged: (val) => setState(() => skills[e.key] = val),
                  onRemove: () => setState(() => skills.removeAt(e.key)),
                ),
              ),
              _buildAddSkillButton(),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildResumePreview(),
    );
  }

  Widget _buildATSScoreTab() {
    final atsData = calculateATSScore();
    final score = atsData['score'] as int;
    final grade = atsData['grade'] as String;
    final strengths = atsData['strengths'] as List<String>;
    final improvements = atsData['improvements'] as List<String>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: score >= 80
                    ? [Colors.green.shade600, Colors.green.shade400]
                    : score >= 60
                    ? [Colors.blue.shade600, Colors.blue.shade400]
                    : score >= 40
                    ? [Colors.orange.shade600, Colors.orange.shade400]
                    : [Colors.red.shade600, Colors.red.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:
                      (score >= 80
                              ? Colors.green
                              : score >= 60
                              ? Colors.blue
                              : score >= 40
                              ? Colors.orange
                              : Colors.red)
                          .withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Text(
                      'ATS Score',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 12,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          grade,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Your resume is ${score >= 80
                      ? 'excellent'
                      : score >= 60
                      ? 'good'
                      : score >= 40
                      ? 'fair'
                      : 'below average'} for ATS systems',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Strengths Section
          if (strengths.isNotEmpty) ...[
            _buildATSSection(
              'Strengths',
              Icons.check_circle,
              Colors.green,
              strengths,
              isStrength: true,
            ),
            const SizedBox(height: 20),
          ],

          // Improvements Section
          if (improvements.isNotEmpty) ...[
            _buildATSSection(
              'Areas to Improve',
              Icons.lightbulb,
              Colors.orange,
              improvements,
              isStrength: false,
            ),
            const SizedBox(height: 20),
          ],

          // Tips Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ATS Tips',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTip(
                  'Use industry-specific keywords from job descriptions',
                ),
                _buildTip('Keep formatting simple and clean'),
                _buildTip('Use standard section headings'),
                _buildTip('Include quantifiable achievements'),
                _buildTip('Avoid images, graphics, and complex tables'),
                _buildTip('Save as .docx or .pdf format'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildATSSection(
    String title,
    IconData icon,
    Color color,
    List<String> items, {
    required bool isStrength,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_right, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF4A5568),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumePreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isEmpty
                      ? 'Your Name'
                      : _nameController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _titleController.text.isEmpty
                      ? 'Job Title'
                      : _titleController.text,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (_emailController.text.isNotEmpty)
                      _buildContactChip(Icons.email, _emailController.text),
                    if (_phoneController.text.isNotEmpty)
                      _buildContactChip(Icons.phone, _phoneController.text),
                    if (_locationController.text.isNotEmpty)
                      _buildContactChip(
                        Icons.location_on,
                        _locationController.text,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                if (_summaryController.text.isNotEmpty) ...[
                  _buildPreviewSectionTitle('Professional Summary'),
                  const SizedBox(height: 8),
                  Text(
                    _summaryController.text,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Skills
                if (skills.isNotEmpty) ...[
                  _buildPreviewSectionTitle('Skills'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .where((s) => s.isNotEmpty)
                        .map(
                          (skill) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.blue.shade200,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              skill,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Experience
                if (experiences.isNotEmpty) ...[
                  _buildPreviewSectionTitle('Work Experience'),
                  const SizedBox(height: 16),
                  ...experiences.map((exp) => _buildPreviewExperience(exp)),
                ],

                // Education
                if (educationList.isNotEmpty) ...[
                  _buildPreviewSectionTitle('Education'),
                  const SizedBox(height: 16),
                  ...educationList.map((edu) => _buildPreviewEducation(edu)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _buildPreviewSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildPreviewExperience(Experience exp) {
    if (exp.role.isEmpty && exp.company.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6, right: 12),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.role,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exp.company} • ${exp.period}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (exp.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        exp.description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewEducation(Education edu) {
    if (edu.degree.isEmpty && edu.institution.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.degree,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${edu.institution} • ${edu.year}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blue.shade600, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextArea({
    required TextEditingController controller,
    required String hint,
    int maxLines = 4,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue.shade700,
        side: BorderSide(color: Colors.blue.shade300, style: BorderStyle.solid),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildAddSkillButton() {
    return InkWell(
      onTap: addSkill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.pink.shade300,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(20),
          color: Colors.pink.shade50,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 18, color: Colors.pink.shade700),
            const SizedBox(width: 4),
            Text(
              'Add Skill',
              style: TextStyle(
                color: Colors.pink.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Models
class Experience {
  String role;
  String company;
  String period;
  String description;

  Experience({
    required this.role,
    required this.company,
    required this.period,
    required this.description,
  });
}

class Education {
  String degree;
  String institution;
  String year;

  Education({
    required this.degree,
    required this.institution,
    required this.year,
  });
}

// Experience Card Widget
class ExperienceCard extends StatefulWidget {
  final Experience experience;
  final ValueChanged<Experience> onChanged;
  final VoidCallback onDelete;

  const ExperienceCard({
    super.key,
    required this.experience,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<ExperienceCard> {
  late TextEditingController roleController;
  late TextEditingController companyController;
  late TextEditingController periodController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    roleController = TextEditingController(text: widget.experience.role);
    companyController = TextEditingController(text: widget.experience.company);
    periodController = TextEditingController(text: widget.experience.period);
    descriptionController = TextEditingController(
      text: widget.experience.description,
    );
  }

  @override
  void dispose() {
    roleController.dispose();
    companyController.dispose();
    periodController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(
      Experience(
        role: roleController.text,
        company: companyController.text,
        period: periodController.text,
        description: descriptionController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.work,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Work Experience',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(roleController, 'Job Role', Icons.badge),
          const SizedBox(height: 12),
          _buildTextField(companyController, 'Company Name', Icons.business),
          const SizedBox(height: 12),
          _buildTextField(
            periodController,
            'Period (e.g., 2020 - 2023)',
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            descriptionController,
            'Description (responsibilities, achievements)',
            Icons.description,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => _notify(),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: Colors.orange.shade600),
        filled: true,
        fillColor: Colors.orange.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }
}

// Education Card Widget
class EducationCard extends StatefulWidget {
  final Education education;
  final ValueChanged<Education> onChanged;
  final VoidCallback onDelete;

  const EducationCard({
    super.key,
    required this.education,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<EducationCard> createState() => _EducationCardState();
}

class _EducationCardState extends State<EducationCard> {
  late TextEditingController degreeController;
  late TextEditingController institutionController;
  late TextEditingController yearController;

  @override
  void initState() {
    super.initState();
    degreeController = TextEditingController(text: widget.education.degree);
    institutionController = TextEditingController(
      text: widget.education.institution,
    );
    yearController = TextEditingController(text: widget.education.year);
  }

  @override
  void dispose() {
    degreeController.dispose();
    institutionController.dispose();
    yearController.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(
      Education(
        degree: degreeController.text,
        institution: institutionController.text,
        year: yearController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.school,
                  color: Colors.green.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Education',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            degreeController,
            'Degree / Certification',
            Icons.workspace_premium,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            institutionController,
            'Institution Name',
            Icons.account_balance,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            yearController,
            'Year (e.g., 2016 - 2020)',
            Icons.event,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      onChanged: (_) => _notify(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: Colors.green.shade600),
        filled: true,
        fillColor: Colors.green.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }
}

// Skill Chip Widget
class SkillChip extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  const SkillChip({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<SkillChip> createState() => _SkillChipState();
}

class _SkillChipState extends State<SkillChip> {
  late TextEditingController _controller;
  bool _isEditing = false;

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
    if (_isEditing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.pink.shade300, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100,
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: widget.onChanged,
                onSubmitted: (_) => setState(() => _isEditing = false),
                decoration: const InputDecoration.collapsed(
                  hintText: 'Skill name',
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => setState(() => _isEditing = false),
              child: Icon(Icons.check, size: 18, color: Colors.green.shade600),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade100, Colors.pink.shade200],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isEditing = true),
            child: Text(
              widget.value.isEmpty ? 'Tap to edit' : widget.value,
              style: TextStyle(
                color: Colors.pink.shade900,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onRemove,
            child: Icon(Icons.close, size: 16, color: Colors.pink.shade900),
          ),
        ],
      ),
    );
  }
}

// Full Resume Preview Screen
class ResumePreviewScreen extends StatelessWidget {
  final String name;
  final String title;
  final String email;
  final String phone;
  final String location;
  final String linkedin;
  final String summary;
  final List<String> skills;
  final List<Experience> experiences;
  final List<Education> education;

  const ResumePreviewScreen({
    super.key,
    required this.name,
    required this.title,
    required this.email,
    required this.phone,
    required this.location,
    required this.linkedin,
    required this.summary,
    required this.skills,
    required this.experiences,
    required this.education,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Resume Preview'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download as PDF coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Your Name' : name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title.isEmpty ? 'Job Title' : title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 20,
                      runSpacing: 12,
                      children: [
                        if (email.isNotEmpty)
                          _buildContactItem(Icons.email, email),
                        if (phone.isNotEmpty)
                          _buildContactItem(Icons.phone, phone),
                        if (location.isNotEmpty)
                          _buildContactItem(Icons.location_on, location),
                        if (linkedin.isNotEmpty)
                          _buildContactItem(Icons.link, linkedin),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary
                    if (summary.isNotEmpty) ...[
                      _buildSectionTitle('Professional Summary', Icons.person),
                      const SizedBox(height: 12),
                      Text(
                        summary,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Skills
                    if (skills.where((s) => s.isNotEmpty).isNotEmpty) ...[
                      _buildSectionTitle('Skills', Icons.star),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: skills
                            .where((s) => s.isNotEmpty)
                            .map(
                              (skill) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  skill,
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Experience
                    if (experiences.isNotEmpty) ...[
                      _buildSectionTitle('Work Experience', Icons.work),
                      const SizedBox(height: 20),
                      ...experiences.map((exp) => _buildExperienceItem(exp)),
                    ],

                    // Education
                    if (education.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSectionTitle('Education', Icons.school),
                      const SizedBox(height: 20),
                      ...education.map((edu) => _buildEducationItem(edu)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade700,
                  Colors.blue.shade100,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceItem(Experience exp) {
    if (exp.role.isEmpty && exp.company.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 16),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.role,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.business, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      exp.company,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      exp.period,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (exp.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    exp.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationItem(Education edu) {
    if (edu.degree.isEmpty && edu.institution.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 16),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.degree,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      edu.institution,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.event, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      edu.year,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
