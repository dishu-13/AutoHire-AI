import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xml/xml.dart';

import '../models/resume_document.dart';
import '../models/resume_result.dart';
import '../services/app_state.dart';
import '../widgets/modern_ui.dart';

class ResumeAiScreen extends StatefulWidget {
  const ResumeAiScreen({super.key});

  @override
  State<ResumeAiScreen> createState() => _ResumeAiScreenState();
}

class _ResumeAiScreenState extends State<ResumeAiScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _headlineController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _linksController;
  late final TextEditingController _summaryController;
  late final TextEditingController _skillsController;
  late final TextEditingController _certificationsController;
  late final TextEditingController _jobDescriptionController;

  final List<_ExperienceControllers> _experiences = [];
  final List<_ProjectControllers> _projects = [];
  final List<_EducationControllers> _education = [];

  String _templateStyle = 'Modern ATS';
  String _mode = 'Builder';

  static const _styles = [
    'Modern ATS',
    'Technical',
    'Executive',
    'Compact',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _nameController = TextEditingController();
    _headlineController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _linksController = TextEditingController();
    _summaryController = TextEditingController();
    _skillsController = TextEditingController();
    _certificationsController = TextEditingController();
    _jobDescriptionController = TextEditingController();

    final document = state.profile.resumeText.trim().isEmpty
        ? ResumeDocument.blank(
            name: state.profile.name,
            email: state.profile.email,
          )
        : ResumeDocument.fromPlainText(
            text: state.profile.resumeText,
            fallbackName: state.profile.name,
            fallbackEmail: state.profile.email,
          );
    _applyDocument(document);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _linksController.dispose();
    _summaryController.dispose();
    _skillsController.dispose();
    _certificationsController.dispose();
    _jobDescriptionController.dispose();
    for (final item in _experiences) {
      item.dispose();
    }
    for (final item in _projects) {
      item.dispose();
    }
    for (final item in _education) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final document = _document;
        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
          children: [
            PurpleHero(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resume',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${document.wordCount} words - $_templateStyle',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: document.hasContent
                              ? () => _exportResume(state)
                              : null,
                          style: _heroButtonStyle(),
                          icon: const Icon(Icons.download),
                          label: const Text('Export PDF'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _pickResumeText,
                          style: _heroButtonStyle(),
                          icon: const Icon(Icons.upload),
                          label: const Text('Upload'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ResumeTabs(
                    selected: _mode,
                    onSelected: (value) => setState(() => _mode = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _modeContent(state, document),
          ],
        );
      },
    );
  }

  Widget _modeContent(AppState state, ResumeDocument document) {
    switch (_mode) {
      case 'Preview':
        return Column(
          children: [
            _TemplatePicker(
              value: _templateStyle,
              styles: _styles,
              onChanged: (value) => setState(() => _templateStyle = value),
            ),
            const SizedBox(height: 12),
            _ResumePreviewCard(
              document: document,
              templateStyle: _templateStyle,
            ),
          ],
        );
      case 'AI Tailor':
        return _AiTailorPanel(
          state: state,
          document: document,
          jobDescriptionController: _jobDescriptionController,
          templateStyle: _templateStyle,
          styles: _styles,
          onTemplateChanged: (value) => setState(() => _templateStyle = value),
          onTailor: () => _tailorResume(state),
          onUseResult: state.resumeResult == null
              ? null
              : () {
                  _applyDocument(
                    ResumeDocument.fromPlainText(
                      text: state.resumeResult!.optimizedResume,
                      fallbackName: _nameController.text,
                      fallbackEmail: _emailController.text,
                    ),
                  );
                  setState(() => _mode = 'Builder');
                  _showUploadMessage('AI output loaded into the builder.');
                },
          onExportResult: state.resumeResult == null
              ? null
              : () => state.exportTailoredResumePdf(
                    templateStyle: _templateStyle,
                  ),
        );
      case 'Analyze':
        return _AnalyzePanel(
          document: document,
          result: state.resumeResult,
        );
      case 'Builder':
      default:
        return _builderContent(state, document);
    }
  }

  Widget _builderContent(AppState state, ResumeDocument document) {
    return Column(
      children: [
        _TemplatePicker(
          value: _templateStyle,
          styles: _styles,
          onChanged: (value) => setState(() => _templateStyle = value),
        ),
        const SizedBox(height: 12),
        _BuilderActions(
          onSave: () => _saveResume(state),
          onSample: () {
            _applyDocument(
              ResumeDocument.sample(
                name: _nameController.text,
                email: _emailController.text,
              ),
            );
            setState(() {});
          },
          onExport: document.hasContent ? () => _exportResume(state) : null,
        ),
        const SizedBox(height: 12),
        _FormCard(
          title: 'Contact',
          icon: Icons.person_outline,
          children: [
            _textField(_nameController, 'Full name', Icons.badge_outlined),
            _textField(
              _headlineController,
              'Headline / target role',
              Icons.work_outline,
            ),
            _textField(_emailController, 'Email', Icons.mail_outline),
            _textField(_phoneController, 'Phone', Icons.phone_outlined),
            _textField(_locationController, 'Location', Icons.place_outlined),
            _textField(
              _linksController,
              'Links',
              Icons.link,
              helperText: 'Separate LinkedIn, GitHub, or portfolio by line.',
              minLines: 2,
              maxLines: 3,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _FormCard(
          title: 'Summary & Skills',
          icon: Icons.auto_awesome,
          children: [
            _textField(
              _summaryController,
              'Professional summary',
              Icons.notes_outlined,
              minLines: 5,
              maxLines: 8,
            ),
            _textField(
              _skillsController,
              'Skills',
              Icons.tune,
              helperText: 'Separate skills by comma or line.',
              minLines: 3,
              maxLines: 5,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ExperienceSection(
          items: _experiences,
          onChanged: () => setState(() {}),
          onAdd: () => setState(() {
            _experiences.add(_ExperienceControllers());
          }),
          onRemove: (index) => setState(() {
            _experiences.removeAt(index).dispose();
          }),
        ),
        const SizedBox(height: 12),
        _ProjectSection(
          items: _projects,
          onChanged: () => setState(() {}),
          onAdd: () => setState(() {
            _projects.add(_ProjectControllers());
          }),
          onRemove: (index) => setState(() {
            _projects.removeAt(index).dispose();
          }),
        ),
        const SizedBox(height: 12),
        _EducationSection(
          items: _education,
          onChanged: () => setState(() {}),
          onAdd: () => setState(() {
            _education.add(_EducationControllers());
          }),
          onRemove: (index) => setState(() {
            _education.removeAt(index).dispose();
          }),
        ),
        const SizedBox(height: 12),
        _FormCard(
          title: 'Certifications',
          icon: Icons.verified_outlined,
          children: [
            _textField(
              _certificationsController,
              'Certifications / awards',
              Icons.workspace_premium_outlined,
              helperText: 'One certification, award, or achievement per line.',
              minLines: 3,
              maxLines: 6,
            ),
          ],
        ),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? helperText,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        textInputAction:
            maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixIcon: Icon(icon),
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }

  ButtonStyle _heroButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: 0.16),
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
    );
  }

  ResumeDocument get _document {
    return ResumeDocument(
      name: _nameController.text.trim(),
      headline: _headlineController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      location: _locationController.text.trim(),
      links: _splitLines(_linksController.text),
      summary: _summaryController.text.trim(),
      skills: _splitFlexible(_skillsController.text),
      experiences: _experiences
          .map((item) => item.toModel())
          .where((item) => item.toPlainText().trim().isNotEmpty)
          .toList(),
      projects: _projects
          .map((item) => item.toModel())
          .where((item) => item.toPlainText().trim().isNotEmpty)
          .toList(),
      education: _education
          .map((item) => item.toModel())
          .where((item) => item.toPlainText().trim().isNotEmpty)
          .toList(),
      certifications: _splitLines(_certificationsController.text),
    );
  }

  void _applyDocument(ResumeDocument document) {
    _nameController.text = document.name;
    _headlineController.text = document.headline;
    _emailController.text = document.email;
    _phoneController.text = document.phone;
    _locationController.text = document.location;
    _linksController.text = document.links.join('\n');
    _summaryController.text = document.summary;
    _skillsController.text = document.skills.join(', ');
    _certificationsController.text = document.certifications.join('\n');

    for (final item in _experiences) {
      item.dispose();
    }
    for (final item in _projects) {
      item.dispose();
    }
    for (final item in _education) {
      item.dispose();
    }
    _experiences
      ..clear()
      ..addAll(document.experiences.map(_ExperienceControllers.fromModel));
    _projects
      ..clear()
      ..addAll(document.projects.map(_ProjectControllers.fromModel));
    _education
      ..clear()
      ..addAll(document.education.map(_EducationControllers.fromModel));
  }

  Future<void> _saveResume(AppState state) async {
    final document = _document;
    await state.updateProfile(
      name: document.name,
      email: document.email,
      resumeText: document.toPlainText(),
    );
    _showUploadMessage('Resume saved.');
  }

  Future<void> _exportResume(AppState state) async {
    final document = _document;
    if (!document.hasContent) {
      _showUploadMessage('Add resume details before exporting.');
      return;
    }
    await state.exportResumeDocumentPdf(
      document: document,
      templateStyle: _templateStyle,
    );
  }

  Future<void> _tailorResume(AppState state) async {
    final document = _document;
    final resumeText = document.toPlainText();
    if (resumeText.trim().isEmpty) {
      _showUploadMessage('Create or upload your resume first.');
      return;
    }
    FocusScope.of(context).unfocus();
    await state.updateProfile(
      name: document.name,
      email: document.email,
      resumeText: resumeText,
    );
    await state.tailorResume(
      resumeText: resumeText,
      targetJobDescription: _jobDescriptionController.text,
      templateStyle: _templateStyle,
    );
  }

  List<String> _splitFlexible(String value) {
    return value
        .split(RegExp(r'[\n,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> _splitLines(String value) {
    return value
        .split(RegExp(r'\r?\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _pickResumeText() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());

      _showUploadMessage('Reading file...');
      final text = await _decodeResumeFileAsync(file.name, file.path, bytes);

      if (text.trim().isEmpty) {
        _showUploadMessage(
          'Could not read text from this file. Paste the resume text or upload a text-based file.',
        );
        return;
      }

      _applyDocument(
        ResumeDocument.fromPlainText(
          text: text,
          fallbackName: _nameController.text,
          fallbackEmail: _emailController.text,
        ),
      );
      setState(() => _mode = 'Builder');
      _showUploadMessage('Resume uploaded from ${file.name}');
    } catch (error) {
      _showUploadMessage('Could not upload this file: $error');
    }
  }

  Future<String> _decodeResumeFileAsync(
    String fileName,
    String? filePath,
    List<int>? bytes,
  ) async {
    if (bytes == null || bytes.isEmpty) return '';
    final name = fileName.toLowerCase();
    if (name.endsWith('.docx') || name.endsWith('.doc')) {
      return _extractDocxText(bytes);
    }
    if (name.endsWith('.pdf')) {
      return _extractRealPdfText(bytes);
    }
    if (name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg')) {
      if (filePath != null) {
        return await _extractImageText(filePath);
      }
    }
    return _readableOrEmpty(
      _cleanUploadedText(utf8.decode(bytes, allowMalformed: true)),
    );
  }

  String _extractRealPdfText(List<int> bytes) {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();
      return _readableOrEmpty(_cleanUploadedText(text));
    } catch (_) {
      return _extractSimplePdfText(bytes);
    }
  }

  Future<String> _extractImageText(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      return _readableOrEmpty(_cleanUploadedText(recognizedText.text));
    } catch (_) {
      return '';
    }
  }

  String _extractDocxText(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final document = archive.findFile('word/document.xml');
      final content = document?.content;
      if (content == null) return '';
      final contentBytes = List<int>.from(content);

      final xml = XmlDocument.parse(
        utf8.decode(contentBytes, allowMalformed: true),
      );
      final text = xml.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local == 't')
          .map((element) => element.innerText)
          .join(' ');
      return _readableOrEmpty(_cleanUploadedText(text));
    } catch (_) {
      return '';
    }
  }

  String _extractSimplePdfText(List<int> bytes) {
    try {
      final raw = latin1.decode(bytes, allowInvalid: true);
      final matches = RegExp(r'\(([^()]*)\)\s*Tj')
          .allMatches(raw)
          .map((match) => match.group(1) ?? '')
          .where((value) => value.trim().length > 2)
          .toList();
      if (matches.isNotEmpty) {
        return _readableOrEmpty(_cleanUploadedText(matches.join(' ')));
      }
      return _readableOrEmpty(_cleanUploadedText(raw));
    } catch (_) {
      return '';
    }
  }

  String _cleanUploadedText(String value) {
    return value
        .replaceAll(RegExp(r'\u0000+'), ' ')
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), ' ')
        .replaceAll(RegExp(r'[^\S\r\n]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  String _readableOrEmpty(String text) {
    final letters = RegExp(r'[A-Za-z]').allMatches(text).length;
    if (letters < 20) return '';
    final readable =
        RegExp(r'[A-Za-z0-9\s.,;:()@/#&+\-]').allMatches(text).length;
    final ratio = readable / text.length.clamp(1, text.length);
    return ratio > 0.55 ? text : '';
  }

  void _showUploadMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ResumeTabs extends StatelessWidget {
  const _ResumeTabs({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  static const _tabs = ['Builder', 'Preview', 'AI Tailor', 'Analyze'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF3C1CB4).withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: _tabs.map((tab) {
          final active = selected == tab;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelected(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({
    required this.value,
    required this.styles,
    required this.onChanged,
  });

  final String value;
  final List<String> styles;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.dashboard_customize_outlined),
          labelText: 'Resume template',
        ),
        items: styles
            .map(
              (style) => DropdownMenuItem(
                value: style,
                child: Text(style),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _BuilderActions extends StatelessWidget {
  const _BuilderActions({
    required this.onSave,
    required this.onSample,
    required this.onExport,
  });

  final VoidCallback onSave;
  final VoidCallback onSample;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSample,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Sample'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Export PDF',
          onPressed: onExport,
          icon: const Icon(Icons.picture_as_pdf_outlined),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ModernIconBox(icon: icon, size: 42),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ExperienceSection extends StatelessWidget {
  const _ExperienceSection({
    required this.items,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_ExperienceControllers> items;
  final VoidCallback onChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Experience',
      icon: Icons.business_center_outlined,
      children: [
        if (items.isEmpty)
          const _InlineEmptyText('Add your latest role first.'),
        ...List.generate(
          items.length,
          (index) => _ExperienceEditor(
            item: items[index],
            index: index,
            onChanged: onChanged,
            onRemove: () => onRemove(index),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add experience'),
          ),
        ),
      ],
    );
  }
}

class _ProjectSection extends StatelessWidget {
  const _ProjectSection({
    required this.items,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_ProjectControllers> items;
  final VoidCallback onChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Projects',
      icon: Icons.code_outlined,
      children: [
        if (items.isEmpty) const _InlineEmptyText('Add portfolio projects.'),
        ...List.generate(
          items.length,
          (index) => _ProjectEditor(
            item: items[index],
            index: index,
            onChanged: onChanged,
            onRemove: () => onRemove(index),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add project'),
          ),
        ),
      ],
    );
  }
}

class _EducationSection extends StatelessWidget {
  const _EducationSection({
    required this.items,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_EducationControllers> items;
  final VoidCallback onChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Education',
      icon: Icons.school_outlined,
      children: [
        if (items.isEmpty) const _InlineEmptyText('Add education details.'),
        ...List.generate(
          items.length,
          (index) => _EducationEditor(
            item: items[index],
            index: index,
            onChanged: onChanged,
            onRemove: () => onRemove(index),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add education'),
          ),
        ),
      ],
    );
  }
}

class _ExperienceEditor extends StatelessWidget {
  const _ExperienceEditor({
    required this.item,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  final _ExperienceControllers item;
  final int index;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _NestedEditor(
      title: 'Role ${index + 1}',
      onRemove: onRemove,
      children: [
        _smallField(item.role, 'Role', onChanged),
        _smallField(item.company, 'Company', onChanged),
        Row(
          children: [
            Expanded(child: _smallField(item.period, 'Dates', onChanged)),
            const SizedBox(width: 8),
            Expanded(child: _smallField(item.location, 'Location', onChanged)),
          ],
        ),
        _smallField(item.bullets, 'Impact bullets', onChanged, minLines: 3),
      ],
    );
  }
}

class _ProjectEditor extends StatelessWidget {
  const _ProjectEditor({
    required this.item,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  final _ProjectControllers item;
  final int index;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _NestedEditor(
      title: 'Project ${index + 1}',
      onRemove: onRemove,
      children: [
        _smallField(item.name, 'Project name', onChanged),
        _smallField(item.tech, 'Tech stack', onChanged),
        _smallField(item.bullets, 'Project bullets', onChanged, minLines: 3),
      ],
    );
  }
}

class _EducationEditor extends StatelessWidget {
  const _EducationEditor({
    required this.item,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  final _EducationControllers item;
  final int index;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _NestedEditor(
      title: 'Education ${index + 1}',
      onRemove: onRemove,
      children: [
        _smallField(item.degree, 'Degree / course', onChanged),
        _smallField(item.school, 'School / institute', onChanged),
        _smallField(item.period, 'Dates', onChanged),
        _smallField(item.details, 'Details', onChanged, minLines: 2),
      ],
    );
  }
}

class _NestedEditor extends StatelessWidget {
  const _NestedEditor({
    required this.title,
    required this.onRemove,
    required this.children,
  });

  final String title;
  final VoidCallback onRemove;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }
}

Widget _smallField(
  TextEditingController controller,
  String label,
  VoidCallback onChanged, {
  int minLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines == 1 ? 1 : 5,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(labelText: label),
    ),
  );
}

class _InlineEmptyText extends StatelessWidget {
  const _InlineEmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _ResumePreviewCard extends StatelessWidget {
  const _ResumePreviewCard({
    required this.document,
    required this.templateStyle,
  });

  final ResumeDocument document;
  final String templateStyle;

  @override
  Widget build(BuildContext context) {
    if (!document.hasContent) {
      return const EmptyActionCard(
        icon: Icons.description_outlined,
        title: 'No resume yet',
        message: 'Add details in the builder or upload an existing resume.',
      );
    }

    final accent = _templateAccent(templateStyle);
    final compact = templateStyle == 'Compact';
    return ModernCard(
      padding: EdgeInsets.all(compact ? 14 : 18),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 12 : 16),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  bottom: BorderSide(color: accent, width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.name.isEmpty ? 'Your Name' : document.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  if (document.headline.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      document.headline,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    [
                      document.email,
                      document.phone,
                      document.location,
                      ...document.links,
                    ].where((item) => item.isNotEmpty).join(' | '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _PreviewSection(
              title: 'Summary',
              accent: accent,
              child: Text(document.summary),
            ),
            if (document.skills.isNotEmpty)
              _PreviewSection(
                title: 'Skills',
                accent: accent,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: document.skills
                      .map((skill) => Chip(label: Text(skill)))
                      .toList(),
                ),
              ),
            if (document.experiences.isNotEmpty)
              _PreviewSection(
                title: 'Experience',
                accent: accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: document.experiences
                      .map((item) => _PreviewBlock(text: item.toPlainText()))
                      .toList(),
                ),
              ),
            if (document.projects.isNotEmpty)
              _PreviewSection(
                title: 'Projects',
                accent: accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: document.projects
                      .map((item) => _PreviewBlock(text: item.toPlainText()))
                      .toList(),
                ),
              ),
            if (document.education.isNotEmpty)
              _PreviewSection(
                title: 'Education',
                accent: accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: document.education
                      .map((item) => _PreviewBlock(text: item.toPlainText()))
                      .toList(),
                ),
              ),
            if (document.certifications.isNotEmpty)
              _PreviewSection(
                title: 'Certifications',
                accent: accent,
                child: Text(document.certifications.join('\n')),
              ),
          ],
        ),
      ),
    );
  }

  Color _templateAccent(String value) {
    switch (value) {
      case 'Technical':
        return ModernColors.teal;
      case 'Executive':
        return const Color(0xFF17324D);
      case 'Compact':
        return ModernColors.ink;
      default:
        return ModernColors.purple;
    }
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({
    required this.title,
    required this.accent,
    required this.child,
  });

  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _PreviewBlock extends StatelessWidget {
  const _PreviewBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SelectableText(text),
    );
  }
}

class _AiTailorPanel extends StatelessWidget {
  const _AiTailorPanel({
    required this.state,
    required this.document,
    required this.jobDescriptionController,
    required this.templateStyle,
    required this.styles,
    required this.onTemplateChanged,
    required this.onTailor,
    required this.onUseResult,
    required this.onExportResult,
  });

  final AppState state;
  final ResumeDocument document;
  final TextEditingController jobDescriptionController;
  final String templateStyle;
  final List<String> styles;
  final ValueChanged<String> onTemplateChanged;
  final VoidCallback onTailor;
  final VoidCallback? onUseResult;
  final VoidCallback? onExportResult;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModernCard(
          child: Column(
            children: [
              TextField(
                controller: jobDescriptionController,
                minLines: 7,
                maxLines: 10,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Target job description',
                  prefixIcon: Icon(Icons.fact_check_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: templateStyle,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.article_outlined),
                  labelText: 'Template style',
                ),
                items: styles
                    .map(
                      (style) => DropdownMenuItem(
                        value: style,
                        child: Text(style),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onTemplateChanged(value);
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: state.isTailoringResume || !document.hasContent
                    ? null
                    : onTailor,
                icon: state.isTailoringResume
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: const Text('Tailor Resume'),
              ),
              if (state.resumeError != null) ...[
                const SizedBox(height: 12),
                _ResumeBanner(message: state.resumeError!),
              ],
            ],
          ),
        ),
        if (state.resumeResult != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUseResult,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Use Output'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onExportResult,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Export AI PDF'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ResumeResultCard(result: state.resumeResult!),
        ],
      ],
    );
  }
}

class _AnalyzePanel extends StatelessWidget {
  const _AnalyzePanel({
    required this.document,
    required this.result,
  });

  final ResumeDocument document;
  final ResumeResult? result;

  @override
  Widget build(BuildContext context) {
    final completed = [
      document.summary.trim().isNotEmpty,
      document.skills.length >= 5,
      document.experiences.isNotEmpty,
      document.projects.isNotEmpty,
      document.education.isNotEmpty,
    ].where((item) => item).length;
    final score = ((completed / 5) * 100).round();

    return Column(
      children: [
        ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Resume readiness',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  _ScoreBadge(score: score),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: score / 100),
              const SizedBox(height: 12),
              _CheckLine(
                done: document.summary.trim().isNotEmpty,
                label: 'Professional summary',
              ),
              _CheckLine(done: document.skills.length >= 5, label: '5+ skills'),
              _CheckLine(
                  done: document.experiences.isNotEmpty, label: 'Experience'),
              _CheckLine(done: document.projects.isNotEmpty, label: 'Projects'),
              _CheckLine(
                  done: document.education.isNotEmpty, label: 'Education'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        result == null
            ? const EmptyActionCard(
                icon: Icons.analytics_outlined,
                title: 'No ATS analysis yet',
                message:
                    'Use AI Tailor with a job description to get match insights.',
              )
            : _ResumeResultCard(result: result!),
      ],
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.done, required this.label});

  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: done ? ModernColors.mint : Theme.of(context).colorScheme.outline,
      ),
      title: Text(label),
    );
  }
}

class _ResumeResultCard extends StatelessWidget {
  const _ResumeResultCard({required this.result});

  final ResumeResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Optimized output',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _ScoreBadge(score: result.atsScore),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: result.atsScore / 100),
          if (result.keywords.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.keywords
                  .take(12)
                  .map((keyword) => Chip(label: Text(keyword)))
                  .toList(),
            ),
          ],
          if (result.suggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...result.suggestions.map(
              (suggestion) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(suggestion),
              ),
            ),
          ],
          const Divider(height: 28),
          SelectableText(
            result.optimizedResume,
            style: theme.textTheme.bodyMedium,
          ),
          if (result.coverLetter.trim().isNotEmpty) ...[
            const Divider(height: 28),
            Text(
              'Cover letter',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(result.coverLetter),
          ],
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$score/100',
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperienceControllers {
  _ExperienceControllers({
    String role = '',
    String company = '',
    String period = '',
    String location = '',
    String bullets = '',
  })  : role = TextEditingController(text: role),
        company = TextEditingController(text: company),
        period = TextEditingController(text: period),
        location = TextEditingController(text: location),
        bullets = TextEditingController(text: bullets);

  factory _ExperienceControllers.fromModel(ResumeExperience item) {
    return _ExperienceControllers(
      role: item.role,
      company: item.company,
      period: item.period,
      location: item.location,
      bullets: item.bullets.join('\n'),
    );
  }

  final TextEditingController role;
  final TextEditingController company;
  final TextEditingController period;
  final TextEditingController location;
  final TextEditingController bullets;

  ResumeExperience toModel() {
    return ResumeExperience(
      role: role.text.trim(),
      company: company.text.trim(),
      period: period.text.trim(),
      location: location.text.trim(),
      bullets: _splitControllerLines(bullets),
    );
  }

  void dispose() {
    role.dispose();
    company.dispose();
    period.dispose();
    location.dispose();
    bullets.dispose();
  }
}

class _ProjectControllers {
  _ProjectControllers({
    String name = '',
    String tech = '',
    String bullets = '',
  })  : name = TextEditingController(text: name),
        tech = TextEditingController(text: tech),
        bullets = TextEditingController(text: bullets);

  factory _ProjectControllers.fromModel(ResumeProject item) {
    return _ProjectControllers(
      name: item.name,
      tech: item.tech,
      bullets: item.bullets.join('\n'),
    );
  }

  final TextEditingController name;
  final TextEditingController tech;
  final TextEditingController bullets;

  ResumeProject toModel() {
    return ResumeProject(
      name: name.text.trim(),
      tech: tech.text.trim(),
      bullets: _splitControllerLines(bullets),
    );
  }

  void dispose() {
    name.dispose();
    tech.dispose();
    bullets.dispose();
  }
}

class _EducationControllers {
  _EducationControllers({
    String degree = '',
    String school = '',
    String period = '',
    String details = '',
  })  : degree = TextEditingController(text: degree),
        school = TextEditingController(text: school),
        period = TextEditingController(text: period),
        details = TextEditingController(text: details);

  factory _EducationControllers.fromModel(ResumeEducation item) {
    return _EducationControllers(
      degree: item.degree,
      school: item.school,
      period: item.period,
      details: item.details,
    );
  }

  final TextEditingController degree;
  final TextEditingController school;
  final TextEditingController period;
  final TextEditingController details;

  ResumeEducation toModel() {
    return ResumeEducation(
      degree: degree.text.trim(),
      school: school.text.trim(),
      period: period.text.trim(),
      details: details.text.trim(),
    );
  }

  void dispose() {
    degree.dispose();
    school.dispose();
    period.dispose();
    details.dispose();
  }
}

List<String> _splitControllerLines(TextEditingController controller) {
  return controller.text
      .split(RegExp(r'\r?\n'))
      .map((item) => item.trim().replaceFirst(RegExp(r'^[-*]\s*'), ''))
      .where((item) => item.isNotEmpty)
      .toList();
}
