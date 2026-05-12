import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/resume_document.dart';
import '../models/resume_result.dart';

class PdfService {
  Future<void> exportResume({
    required ResumeResult result,
    required String candidateName,
    String templateStyle = 'Modern ATS',
  }) async {
    final document = ResumeDocument.fromPlainText(
      text: result.optimizedResume,
      fallbackName: candidateName,
    );

    await exportResumeDocument(
      document: document,
      templateStyle: templateStyle,
      fileName: 'tailored_resume.pdf',
      footer: [
        'ATS Score: ${result.atsScore}/100',
        if (result.keywords.isNotEmpty)
          'Keywords: ${result.keywords.join(', ')}',
      ].join('\n'),
    );
  }

  Future<void> exportResumeDocument({
    required ResumeDocument document,
    required String templateStyle,
    String? fileName,
    String? footer,
  }) async {
    final theme = _ResumePdfTheme.forStyle(templateStyle);
    final name = document.name.trim().isEmpty ? 'Resume' : document.name.trim();
    final pdf = pw.Document(title: '$name Resume', author: name);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: theme.margin,
          pageFormat: PdfPageFormat.a4,
        ),
        build: (context) => [
          _header(document, theme),
          pw.SizedBox(height: theme.sectionGap),
          if (document.summary.trim().isNotEmpty)
            _section(
              title: 'Summary',
              theme: theme,
              children: [
                pw.Text(
                  document.summary.trim(),
                  style: theme.bodyStyle,
                  textAlign: pw.TextAlign.justify,
                ),
              ],
            ),
          if (document.skills.isNotEmpty)
            _section(
              title: 'Skills',
              theme: theme,
              children: [_skills(document.skills, theme)],
            ),
          if (document.experiences.isNotEmpty)
            _section(
              title: 'Experience',
              theme: theme,
              children: document.experiences
                  .map((item) => _experience(item, theme))
                  .toList(),
            ),
          if (document.projects.isNotEmpty)
            _section(
              title: 'Projects',
              theme: theme,
              children: document.projects
                  .map((item) => _project(item, theme))
                  .toList(),
            ),
          if (document.education.isNotEmpty)
            _section(
              title: 'Education',
              theme: theme,
              children: document.education
                  .map((item) => _education(item, theme))
                  .toList(),
            ),
          if (document.certifications.isNotEmpty)
            _section(
              title: 'Certifications',
              theme: theme,
              children: [
                ...document.certifications.map(
                  (item) => _bullet(item, theme),
                ),
              ],
            ),
          if (footer != null && footer.trim().isNotEmpty) ...[
            pw.SizedBox(height: theme.sectionGap),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: theme.softAccent,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(footer.trim(), style: theme.smallStyle),
            ),
          ],
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: fileName ?? '${_fileSafe(name)}_resume.pdf',
    );
  }

  pw.Widget _header(ResumeDocument document, _ResumePdfTheme theme) {
    final contact = [
      document.email,
      document.phone,
      document.location,
      ...document.links,
    ].where((item) => item.trim().isNotEmpty).join(' | ');

    return pw.Container(
      padding: theme.headerPadding,
      decoration: pw.BoxDecoration(
        color: theme.headerFill,
        border: pw.Border(
          bottom: pw.BorderSide(color: theme.accent, width: 2),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            document.name.trim().isEmpty ? 'Your Name' : document.name.trim(),
            style: theme.nameStyle,
          ),
          if (document.headline.trim().isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(document.headline.trim(), style: theme.headlineStyle),
          ],
          if (contact.trim().isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(contact, style: theme.smallStyle),
          ],
        ],
      ),
    );
  }

  pw.Widget _section({
    required String title,
    required _ResumePdfTheme theme,
    required List<pw.Widget> children,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: theme.sectionGap),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title.toUpperCase(), style: theme.sectionStyle),
          pw.SizedBox(height: 5),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _skills(List<String> skills, _ResumePdfTheme theme) {
    if (theme.compact) {
      return pw.Text(skills.join(' | '), style: theme.bodyStyle);
    }

    return pw.Wrap(
      spacing: 5,
      runSpacing: 5,
      children: skills
          .map(
            (skill) => pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: pw.BoxDecoration(
                color: theme.softAccent,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(skill, style: theme.smallStyle),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _experience(ResumeExperience item, _ResumePdfTheme theme) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _lineHeader(
            left: [item.role, item.company]
                .where((value) => value.trim().isNotEmpty)
                .join(' - '),
            right: [item.period, item.location]
                .where((value) => value.trim().isNotEmpty)
                .join(' | '),
            theme: theme,
          ),
          ...item.bullets.map((bullet) => _bullet(bullet, theme)),
        ],
      ),
    );
  }

  pw.Widget _project(ResumeProject item, _ResumePdfTheme theme) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _lineHeader(left: item.name, right: item.tech, theme: theme),
          ...item.bullets.map((bullet) => _bullet(bullet, theme)),
        ],
      ),
    );
  }

  pw.Widget _education(ResumeEducation item, _ResumePdfTheme theme) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _lineHeader(
            left: [item.degree, item.school]
                .where((value) => value.trim().isNotEmpty)
                .join(' - '),
            right: item.period,
            theme: theme,
          ),
          if (item.details.trim().isNotEmpty)
            pw.Text(item.details.trim(), style: theme.bodyStyle),
        ],
      ),
    );
  }

  pw.Widget _lineHeader({
    required String left,
    required String right,
    required _ResumePdfTheme theme,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(left.trim(), style: theme.itemTitleStyle),
        ),
        if (right.trim().isNotEmpty)
          pw.Text(right.trim(), style: theme.smallStyle),
      ],
    );
  }

  pw.Widget _bullet(String text, _ResumePdfTheme theme) {
    if (text.trim().isEmpty) return pw.SizedBox.shrink();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('- ', style: theme.bodyStyle),
          pw.Expanded(child: pw.Text(text.trim(), style: theme.bodyStyle)),
        ],
      ),
    );
  }

  String _fileSafe(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}

class _ResumePdfTheme {
  const _ResumePdfTheme({
    required this.accent,
    required this.softAccent,
    required this.headerFill,
    required this.margin,
    required this.headerPadding,
    required this.nameStyle,
    required this.headlineStyle,
    required this.sectionStyle,
    required this.itemTitleStyle,
    required this.bodyStyle,
    required this.smallStyle,
    required this.sectionGap,
    required this.compact,
  });

  final PdfColor accent;
  final PdfColor softAccent;
  final PdfColor headerFill;
  final pw.EdgeInsets margin;
  final pw.EdgeInsets headerPadding;
  final pw.TextStyle nameStyle;
  final pw.TextStyle headlineStyle;
  final pw.TextStyle sectionStyle;
  final pw.TextStyle itemTitleStyle;
  final pw.TextStyle bodyStyle;
  final pw.TextStyle smallStyle;
  final double sectionGap;
  final bool compact;

  factory _ResumePdfTheme.forStyle(String style) {
    final normalized = style.toLowerCase();
    if (normalized.contains('compact')) {
      return _ResumePdfTheme._create(
        accent: const PdfColor.fromInt(0xFF111827),
        softAccent: const PdfColor.fromInt(0xFFF3F4F6),
        headerFill: PdfColors.white,
        margin: const pw.EdgeInsets.fromLTRB(30, 28, 30, 28),
        nameSize: 19,
        bodySize: 9.2,
        sectionGap: 8,
        compact: true,
      );
    }
    if (normalized.contains('executive')) {
      return _ResumePdfTheme._create(
        accent: const PdfColor.fromInt(0xFF17324D),
        softAccent: const PdfColor.fromInt(0xFFEAF1F8),
        headerFill: const PdfColor.fromInt(0xFFF7FAFD),
        margin: const pw.EdgeInsets.fromLTRB(42, 38, 42, 38),
        nameSize: 24,
        bodySize: 10.4,
        sectionGap: 13,
        compact: false,
      );
    }
    if (normalized.contains('technical')) {
      return _ResumePdfTheme._create(
        accent: const PdfColor.fromInt(0xFF0F766E),
        softAccent: const PdfColor.fromInt(0xFFE6FFFB),
        headerFill: const PdfColor.fromInt(0xFFF8FFFD),
        margin: const pw.EdgeInsets.fromLTRB(36, 34, 36, 34),
        nameSize: 22,
        bodySize: 10,
        sectionGap: 11,
        compact: false,
      );
    }
    return _ResumePdfTheme._create(
      accent: const PdfColor.fromInt(0xFF5B4DF3),
      softAccent: const PdfColor.fromInt(0xFFF0ECFF),
      headerFill: const PdfColor.fromInt(0xFFFAF9FF),
      margin: const pw.EdgeInsets.fromLTRB(36, 34, 36, 34),
      nameSize: 23,
      bodySize: 10.2,
      sectionGap: 12,
      compact: false,
    );
  }

  factory _ResumePdfTheme._create({
    required PdfColor accent,
    required PdfColor softAccent,
    required PdfColor headerFill,
    required pw.EdgeInsets margin,
    required double nameSize,
    required double bodySize,
    required double sectionGap,
    required bool compact,
  }) {
    return _ResumePdfTheme(
      accent: accent,
      softAccent: softAccent,
      headerFill: headerFill,
      margin: margin,
      headerPadding: compact
          ? const pw.EdgeInsets.only(bottom: 8)
          : const pw.EdgeInsets.all(12),
      nameStyle: pw.TextStyle(
        fontSize: nameSize,
        fontWeight: pw.FontWeight.bold,
        color: accent,
      ),
      headlineStyle: pw.TextStyle(
        fontSize: bodySize + 1.5,
        fontWeight: pw.FontWeight.bold,
      ),
      sectionStyle: pw.TextStyle(
        fontSize: bodySize + 1.2,
        fontWeight: pw.FontWeight.bold,
        color: accent,
        letterSpacing: 0.8,
      ),
      itemTitleStyle: pw.TextStyle(
        fontSize: bodySize + 0.4,
        fontWeight: pw.FontWeight.bold,
      ),
      bodyStyle: pw.TextStyle(fontSize: bodySize, lineSpacing: 2),
      smallStyle: pw.TextStyle(
        fontSize: bodySize - 1,
        color: PdfColors.grey700,
      ),
      sectionGap: sectionGap,
      compact: compact,
    );
  }
}
