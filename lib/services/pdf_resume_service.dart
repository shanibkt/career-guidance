import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class PdfResumeService {
  /// Generate a professional PDF resume
  static Future<pw.Document> generateResumePdf({
    required String name,
    required String title,
    required String email,
    required String phone,
    required String location,
    required String linkedin,
    required String summary,
    required List<String> skills,
    required List<dynamic> experiences,
    required List<dynamic> education,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header Section
          _buildHeader(name, title, email, phone, location, linkedin),
          pw.SizedBox(height: 20),

          // Summary Section
          if (summary.isNotEmpty) ...[
            _buildSectionTitle('Professional Summary'),
            pw.SizedBox(height: 8),
            pw.Text(
              summary,
              style: pw.TextStyle(
                fontSize: 11,
                lineSpacing: 1.5,
                color: PdfColors.grey800,
              ),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 20),
          ],

          // Skills Section
          if (skills.isNotEmpty) ...[
            _buildSectionTitle('Skills'),
            pw.SizedBox(height: 8),
            _buildSkills(skills),
            pw.SizedBox(height: 20),
          ],

          // Experience Section
          if (experiences.isNotEmpty) ...[
            _buildSectionTitle('Work Experience'),
            pw.SizedBox(height: 8),
            ...experiences.map((exp) => _buildExperience(exp)),
          ],

          // Education Section
          if (education.isNotEmpty) ...[
            _buildSectionTitle('Education'),
            pw.SizedBox(height: 8),
            ...education.map((edu) => _buildEducation(edu)),
          ],
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(
    String name,
    String title,
    String email,
    String phone,
    String location,
    String linkedin,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue700, width: 2),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            name,
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              color: PdfColors.blue700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              if (email.isNotEmpty) ...[
                _buildContactItem(email, '📧'),
                pw.SizedBox(width: 16),
              ],
              if (phone.isNotEmpty) ...[
                _buildContactItem(phone, '📱'),
                pw.SizedBox(width: 16),
              ],
              if (location.isNotEmpty) ...[_buildContactItem(location, '📍')],
            ],
          ),
          if (linkedin.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            _buildContactItem(linkedin, '🔗'),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildContactItem(String text, String emoji) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(emoji, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(width: 4),
        pw.Text(
          text,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue500, width: 1.5),
        ),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static pw.Widget _buildSkills(List<String> skills) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills
          .where((skill) => skill.trim().isNotEmpty)
          .map(
            (skill) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColors.blue200, width: 1),
              ),
              child: pw.Text(
                skill,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.blue900,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _buildExperience(dynamic experience) {
    final role = _getField(experience, 'role');
    final company = _getField(experience, 'company');
    final period = _getField(experience, 'period');
    final description = _getField(experience, 'description');

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      role,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      company,
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.blue700,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Text(
                period,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              description,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
                lineSpacing: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildEducation(dynamic education) {
    final degree = _getField(education, 'degree');
    final institution = _getField(education, 'institution');
    final year = _getField(education, 'year');

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  degree,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  institution,
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.blue700),
                ),
              ],
            ),
          ),
          pw.Text(
            year,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  static String _getField(dynamic obj, String field) {
    if (obj is Map) {
      return obj[field]?.toString() ?? '';
    }
    // Handle class objects with getters
    try {
      switch (field) {
        case 'role':
          return obj.role?.toString() ?? '';
        case 'company':
          return obj.company?.toString() ?? '';
        case 'period':
          return obj.period?.toString() ?? '';
        case 'description':
          return obj.description?.toString() ?? '';
        case 'degree':
          return obj.degree?.toString() ?? '';
        case 'institution':
          return obj.institution?.toString() ?? '';
        case 'year':
          return obj.year?.toString() ?? '';
        default:
          return '';
      }
    } catch (e) {
      return '';
    }
  }

  /// Save PDF to device
  static Future<File> savePdfToDevice(pw.Document pdf, String filename) async {
    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Share PDF
  static Future<void> sharePdf(pw.Document pdf, String filename) async {
    await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
  }

  /// Print PDF
  static Future<void> printPdf(pw.Document pdf) async {
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
