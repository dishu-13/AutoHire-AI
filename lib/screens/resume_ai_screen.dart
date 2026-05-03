import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart';

import '../models/resume_result.dart';
import '../services/app_state.dart';
import '../widgets/modern_ui.dart';

class ResumeAiScreen extends StatefulWidget {
  const ResumeAiScreen({super.key});

  @override
  State<ResumeAiScreen> createState() => _ResumeAiScreenState();
}

class _ResumeAiScreenState extends State<ResumeAiScreen> {
  late final TextEditingController _resumeController;
  late final TextEditingController _jobDescriptionController;
  String _templateStyle = 'Modern ATS';
  String _mode = 'Editor';

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
    _resumeController = TextEditingController(text: state.profile.resumeText);
    _jobDescriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _resumeController.dispose();
    _jobDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return ListView(
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
                    '${_wordCount(_resumeController.text)} words',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: state.resumeResult == null
                            ? null
                            : () => state.exportTailoredResumePdf(),
                        style: _heroButtonStyle(),
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _pickResumeText,
                        style: _heroButtonStyle(),
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload'),
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
            const SizedBox(height: 22),
            _modeContent(state),
          ],
        );
      },
    );
  }

  Widget _modeContent(AppState state) {
    switch (_mode) {
      case 'Preview':
        return _ResumePreviewCard(text: _resumeController.text);
      case 'AI Tailor':
        return Column(
          children: [
            TextField(
              controller: _jobDescriptionController,
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
              initialValue: _templateStyle,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.article_outlined),
                labelText: 'Template style',
              ),
              items: _styles
                  .map(
                    (style) => DropdownMenuItem(
                      value: style,
                      child: Text(style),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _templateStyle = value);
                }
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: state.isTailoringResume
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      state.tailorResume(
                        resumeText: _resumeController.text,
                        targetJobDescription: _jobDescriptionController.text,
                        templateStyle: _templateStyle,
                      );
                    },
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
            if (state.resumeResult != null) ...[
              const SizedBox(height: 16),
              _ResumeResultCard(result: state.resumeResult!),
            ],
          ],
        );
      case 'Analyze':
        return state.resumeResult == null
            ? const EmptyActionCard(
                icon: Icons.analytics_outlined,
                title: 'No analysis yet',
                message: 'Tailor your resume to see ATS score and suggestions.',
              )
            : _ResumeResultCard(result: state.resumeResult!);
      case 'Editor':
      default:
        return ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ModernIconBox(icon: Icons.description_outlined),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Resume',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text('${_wordCount(_resumeController.text)} words'),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _resumeController,
                minLines: 9,
                maxLines: 14,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Resume text',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
            ],
          ),
        );
    }
  }

  ButtonStyle _heroButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: 0.16),
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
    );
  }

  int _wordCount(String value) {
    return value.trim().isEmpty ? 0 : value.trim().split(RegExp(r'\s+')).length;
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
      final text = _decodeResumeFile(file.name, bytes);

      if (text.trim().isEmpty) {
        _showUploadMessage(
          'Could not read text from this file. Paste the resume text or upload a text-based file.',
        );
        return;
      }

      setState(() {
        _resumeController.text = text;
      });
      _showUploadMessage('Resume uploaded from ${file.name}');
    } catch (error) {
      _showUploadMessage('Could not upload this file: $error');
    }
  }

  String _decodeResumeFile(String fileName, List<int>? bytes) {
    if (bytes == null || bytes.isEmpty) return '';
    final name = fileName.toLowerCase();
    if (name.endsWith('.docx')) {
      return _extractDocxText(bytes);
    }
    if (name.endsWith('.pdf')) {
      return _extractSimplePdfText(bytes);
    }
    return _readableOrEmpty(
      _cleanUploadedText(utf8.decode(bytes, allowMalformed: true)),
    );
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

  static const _tabs = ['Editor', 'Preview', 'AI Tailor', 'Analyze'];

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

class _ResumePreviewCard extends StatelessWidget {
  const _ResumePreviewCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const EmptyActionCard(
        icon: Icons.description_outlined,
        title: 'No resume text',
        message: 'Upload or paste your resume in the editor first.',
      );
    }

    return ModernCard(
      child: SelectableText(
        text,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
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
      child: Padding(
        padding: EdgeInsets.zero,
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
