import 'dart:convert';
import 'package:flutter/material.dart';

class ResumeViewer extends StatelessWidget {
  final String? resumeDataJson;

  const ResumeViewer({super.key, this.resumeDataJson});

  Map<String, dynamic>? _parseResumeData() {
    if (resumeDataJson == null || resumeDataJson!.isEmpty) return null;
    try {
      return jsonDecode(resumeDataJson!);
    } catch (e) {
      print('Error parsing resume data: $e');
      return null;
    }
  }

  List<dynamic> _parseJsonArray(dynamic value) {
    if (value == null) return [];
    if (value is List) return value;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        return decoded is List ? decoded : [];
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (resumeDataJson == null || resumeDataJson!.isEmpty) {
      return const Center(
        child: Text(
          'No resume data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final resumeData = _parseResumeData();
    if (resumeData == null) {
      return const Center(
        child: Text(
          'Error loading resume data',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeaderSection(resumeData),
          const Divider(height: 40),

          // Contact Information
          if (resumeData['email'] != null || resumeData['phone'] != null)
            _buildContactSection(resumeData),

          // Professional Summary
          if (resumeData['professional_summary'] != null &&
              resumeData['professional_summary'].toString().isNotEmpty)
            _buildProfessionalSummary(resumeData),

          // Skills
          if (_parseJsonArray(resumeData['skills']).isNotEmpty)
            _buildSkillsSection(resumeData),

          // Experience
          if (_parseJsonArray(resumeData['experiences']).isNotEmpty)
            _buildExperienceSection(resumeData),

          // Education
          if (_parseJsonArray(resumeData['education']).isNotEmpty)
            _buildEducationSection(resumeData),

          // Certifications
          if (_parseJsonArray(resumeData['certifications']).isNotEmpty)
            _buildCertificationsSection(resumeData),

          // Projects
          if (_parseJsonArray(resumeData['projects']).isNotEmpty)
            _buildProjectsSection(resumeData),

          // Languages
          if (_parseJsonArray(resumeData['languages']).isNotEmpty)
            _buildLanguagesSection(resumeData),

          // Achievements
          if (_parseJsonArray(resumeData['achievements']).isNotEmpty)
            _buildAchievementsSection(resumeData),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data['full_name'] ?? 'Applicant Name',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        if (data['job_title'] != null && data['job_title'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              data['job_title'],
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF5C6BC0),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (data['location'] != null && data['location'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  data['location'],
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContactSection(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              if (data['email'] != null && data['email'].toString().isNotEmpty)
                _buildContactItem(Icons.email, data['email']),
              if (data['phone'] != null && data['phone'].toString().isNotEmpty)
                _buildContactItem(Icons.phone, data['phone']),
              if (data['linkedin'] != null && data['linkedin'].toString().isNotEmpty)
                _buildContactItem(Icons.link, data['linkedin']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF5C6BC0)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalSummary(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Professional Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data['professional_summary'],
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(Map<String, dynamic> data) {
    final skills = _parseJsonArray(data['skills']);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skills',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map((skill) => Chip(
                      label: Text(skill.toString()),
                      backgroundColor: const Color(0xFFE8EAF6),
                      labelStyle: const TextStyle(
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.w500,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceSection(Map<String, dynamic> data) {
    final experiences = _parseJsonArray(data['experiences']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Work Experience',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          ...experiences.map((exp) {
            final expMap = exp is Map ? exp : {};
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expMap['JobTitle'] ?? expMap['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (expMap['Company'] != null || expMap['company'] != null)
                    Text(
                      expMap['Company'] ?? expMap['company'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF5C6BC0),
                      ),
                    ),
                  if (expMap['Duration'] != null || expMap['duration'] != null)
                    Text(
                      expMap['Duration'] ?? expMap['duration'] ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  if (expMap['Description'] != null || expMap['description'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        expMap['Description'] ?? expMap['description'] ?? '',
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEducationSection(Map<String, dynamic> data) {
    final education = _parseJsonArray(data['education']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Education',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          ...education.map((edu) {
            final eduMap = edu is Map ? edu : {};
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eduMap['Degree'] ?? eduMap['degree'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (eduMap['Institution'] != null || eduMap['institution'] != null)
                    Text(
                      eduMap['Institution'] ?? eduMap['institution'] ?? '',
                      style: const TextStyle(fontSize: 15),
                    ),
                  if (eduMap['Year'] != null || eduMap['year'] != null)
                    Text(
                      eduMap['Year'] ?? eduMap['year'] ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCertificationsSection(Map<String, dynamic> data) {
    final certifications = _parseJsonArray(data['certifications']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Certifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          ...certifications.map((cert) {
            final certMap = cert is Map ? cert : {};
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified, size: 18, color: Color(0xFF5C6BC0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          certMap['Name'] ?? certMap['name'] ?? cert.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (certMap['Issuer'] != null || certMap['issuer'] != null)
                          Text(
                            certMap['Issuer'] ?? certMap['issuer'] ?? '',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildProjectsSection(Map<String, dynamic> data) {
    final projects = _parseJsonArray(data['projects']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Projects',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          ...projects.map((project) {
            final projMap = project is Map ? project : {};
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    projMap['Name'] ?? projMap['name'] ?? project.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (projMap['Description'] != null || projMap['description'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        projMap['Description'] ?? projMap['description'] ?? '',
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLanguagesSection(Map<String, dynamic> data) {
    final languages = _parseJsonArray(data['languages']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Languages',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: languages.map((lang) {
              final langMap = lang is Map ? lang : {};
              return Text(
                '• ${langMap['Language'] ?? langMap['language'] ?? lang.toString()}${langMap['Proficiency'] != null ? ' (${langMap['Proficiency']})' : ''}',
                style: const TextStyle(fontSize: 15),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(Map<String, dynamic> data) {
    final achievements = _parseJsonArray(data['achievements']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Achievements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          ...achievements.map((achievement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.star, size: 18, color: Color(0xFFFFA000)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      achievement.toString(),
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
