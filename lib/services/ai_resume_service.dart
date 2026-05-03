import '../models/resume_result.dart';

class AiResumeService {
  const AiResumeService();

  bool get isConfigured => true;

  Future<ResumeResult> tailorResume({
    required String resumeText,
    required String targetJobDescription,
    required String templateStyle,
  }) async {
    final resume = resumeText.trim();
    final jobDescription = targetJobDescription.trim();
    if (resume.isEmpty || jobDescription.isEmpty) {
      throw const AiResumeException(
        'Add both resume text and the target job description.',
      );
    }

    final keywords = _extractKeywords(jobDescription);
    final resumeLower = resume.toLowerCase();
    final matched = keywords
        .where((keyword) => resumeLower.contains(keyword.toLowerCase()))
        .toList();
    final missing = keywords
        .where((keyword) => !resumeLower.contains(keyword.toLowerCase()))
        .toList();
    final score = _scoreResume(
      resume: resume,
      keywords: keywords,
      matchedKeywords: matched,
    );

    return ResumeResult(
      optimizedResume: _buildOptimizedResume(
        resume: resume,
        templateStyle: templateStyle,
        keywords: keywords,
        matchedKeywords: matched,
        missingKeywords: missing,
      ),
      coverLetter: _buildCoverLetter(
        keywords: keywords,
        matchedKeywords: matched,
        missingKeywords: missing,
      ),
      atsScore: score,
      keywords: keywords,
      suggestions: _buildSuggestions(
        resume: resume,
        keywords: keywords,
        matchedKeywords: matched,
        missingKeywords: missing,
      ),
      generatedAt: DateTime.now(),
    );
  }

  int calculateMatchScore({
    required String resumeText,
    required String targetJobDescription,
  }) {
    final resume = resumeText.trim();
    final jobDescription = targetJobDescription.trim();
    if (resume.isEmpty || jobDescription.isEmpty) return 0;

    final keywords = _extractKeywords(jobDescription);
    if (keywords.isEmpty) return 0;

    final resumeLower = resume.toLowerCase();
    final matched = keywords
        .where((keyword) => resumeLower.contains(keyword.toLowerCase()))
        .toList();

    return _scoreResume(
      resume: resume,
      keywords: keywords,
      matchedKeywords: matched,
    );
  }

  List<String> _extractKeywords(String text) {
    final counts = <String, int>{};
    final words = RegExp(r"[a-zA-Z][a-zA-Z0-9.+#-]{2,}")
        .allMatches(text.toLowerCase())
        .map((match) => match.group(0) ?? '')
        .map(_normalizeKeyword)
        .where((word) => word.length >= 3)
        .where((word) => !_stopWords.contains(word));

    for (final word in words) {
      counts[word] = (counts[word] ?? 0) + 1;
    }

    final ranked = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });

    return ranked.take(18).map((entry) => _titleCase(entry.key)).toList();
  }

  int _scoreResume({
    required String resume,
    required List<String> keywords,
    required List<String> matchedKeywords,
  }) {
    final wordCount =
        resume.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final coverage =
        keywords.isEmpty ? 0.45 : matchedKeywords.length / keywords.length;
    final lengthScore = wordCount >= 450
        ? 1.0
        : wordCount >= 250
            ? 0.75
            : wordCount >= 120
                ? 0.48
                : 0.22;
    final structureScore = [
          'experience',
          'skills',
          'education',
          'projects',
          'summary',
        ].where((section) => resume.toLowerCase().contains(section)).length /
        5;

    final score =
        (38 + coverage * 42 + lengthScore * 12 + structureScore * 8).round();
    return score.clamp(35, 96).toInt();
  }

  String _buildOptimizedResume({
    required String resume,
    required String templateStyle,
    required List<String> keywords,
    required List<String> matchedKeywords,
    required List<String> missingKeywords,
  }) {
    final focusKeywords = keywords.take(10).join(', ');
    final matched =
        matchedKeywords.isEmpty ? 'None yet' : matchedKeywords.join(', ');
    final missing = missingKeywords.isEmpty
        ? 'No major missing keywords found'
        : missingKeywords.take(10).join(', ');

    return [
      resume,
      '',
      'TARGET ROLE ALIGNMENT',
      'Template style: $templateStyle',
      'Primary ATS keywords: $focusKeywords',
      'Already present: $matched',
      'Add proof points for: $missing',
      '',
      'TAILORED SUMMARY DRAFT',
      'Results-focused candidate aligned with this role through experience related to ${keywords.take(4).join(', ')}. Add one measurable achievement here that proves scope, impact, or speed.',
      '',
      'NEXT EDITS',
      '- Move the most relevant project or work experience to the top.',
      '- Add metrics such as revenue, users, time saved, cost reduced, or accuracy improved.',
      '- Repeat exact job-description keywords naturally in skills and experience bullets.',
    ].join('\n');
  }

  String _buildCoverLetter({
    required List<String> keywords,
    required List<String> matchedKeywords,
    required List<String> missingKeywords,
  }) {
    final strengths = matchedKeywords.isEmpty
        ? keywords.take(4).join(', ')
        : matchedKeywords.take(4).join(', ');
    final focus = missingKeywords.isEmpty
        ? keywords.take(3).join(', ')
        : missingKeywords.take(3).join(', ');

    return [
      'Dear Hiring Team,',
      '',
      'I am excited to apply for this role. My background connects strongly with the position through $strengths, and I am especially interested in contributing to work involving $focus.',
      '',
      'I would welcome the chance to discuss how my experience can support your team and create measurable impact.',
      '',
      'Sincerely,',
      'Your Name',
    ].join('\n');
  }

  List<String> _buildSuggestions({
    required String resume,
    required List<String> keywords,
    required List<String> matchedKeywords,
    required List<String> missingKeywords,
  }) {
    final wordCount =
        resume.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final suggestions = <String>[
      'Matched ${matchedKeywords.length} of ${keywords.length} important job-description keywords.',
    ];

    if (missingKeywords.isNotEmpty) {
      suggestions.add(
        'Add evidence for: ${missingKeywords.take(6).join(', ')}.',
      );
    }
    if (wordCount < 250) {
      suggestions.add(
          'Expand the resume with more achievement bullets and measurable results.');
    }
    if (!resume.toLowerCase().contains('skills')) {
      suggestions
          .add('Add a dedicated Skills section with exact role keywords.');
    }
    if (!RegExp(r'\d+%?').hasMatch(resume)) {
      suggestions.add(
          'Add numbers to prove impact, such as percentages, counts, or timelines.');
    }
    suggestions.add(
        'Keep formatting simple for ATS: clear headings, no tables, and standard bullets.');

    return suggestions;
  }

  String _normalizeKeyword(String value) {
    return value.replaceAll(RegExp(r'^[^a-z0-9]+|[^a-z0-9+#.-]+$'), '').trim();
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'[-_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part.length == 1
            ? part.toUpperCase()
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static const _stopWords = {
    'about',
    'after',
    'also',
    'and',
    'are',
    'based',
    'but',
    'can',
    'company',
    'experience',
    'for',
    'from',
    'have',
    'into',
    'job',
    'our',
    'role',
    'that',
    'the',
    'their',
    'this',
    'through',
    'using',
    'with',
    'will',
    'work',
    'you',
    'your',
  };
}

class AiResumeException implements Exception {
  const AiResumeException(this.message);

  final String message;

  @override
  String toString() => message;
}
