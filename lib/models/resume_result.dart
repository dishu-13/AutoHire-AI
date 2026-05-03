class ResumeResult {
  const ResumeResult({
    required this.optimizedResume,
    required this.coverLetter,
    required this.atsScore,
    required this.keywords,
    required this.suggestions,
    required this.generatedAt,
  });

  final String optimizedResume;
  final String coverLetter;
  final int atsScore;
  final List<String> keywords;
  final List<String> suggestions;
  final DateTime generatedAt;

  factory ResumeResult.fromMap(Map<String, dynamic> map) {
    return ResumeResult(
      optimizedResume: map['optimizedResume']?.toString() ?? '',
      coverLetter: map['coverLetter']?.toString() ?? '',
      atsScore: int.tryParse(map['atsScore']?.toString() ?? '') ?? 70,
      keywords: _stringList(map['keywords']),
      suggestions: _stringList(map['suggestions']),
      generatedAt: DateTime.tryParse(map['generatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'optimizedResume': optimizedResume,
      'coverLetter': coverLetter,
      'atsScore': atsScore,
      'keywords': keywords,
      'suggestions': suggestions,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }
}
