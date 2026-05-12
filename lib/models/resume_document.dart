class ResumeDocument {
  const ResumeDocument({
    required this.name,
    required this.headline,
    required this.email,
    required this.phone,
    required this.location,
    required this.links,
    required this.summary,
    required this.skills,
    required this.experiences,
    required this.projects,
    required this.education,
    required this.certifications,
  });

  final String name;
  final String headline;
  final String email;
  final String phone;
  final String location;
  final List<String> links;
  final String summary;
  final List<String> skills;
  final List<ResumeExperience> experiences;
  final List<ResumeProject> projects;
  final List<ResumeEducation> education;
  final List<String> certifications;

  bool get hasContent {
    return [
      name,
      headline,
      email,
      phone,
      location,
      summary,
      ...links,
      ...skills,
      ...certifications,
      ...experiences.map((item) => item.toPlainText()),
      ...projects.map((item) => item.toPlainText()),
      ...education.map((item) => item.toPlainText()),
    ].any((value) => value.trim().isNotEmpty);
  }

  int get wordCount {
    final text = toPlainText();
    return text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
  }

  String toPlainText() {
    final lines = <String>[
      if (name.trim().isNotEmpty) name.trim(),
      if (headline.trim().isNotEmpty) headline.trim(),
      [
        email.trim(),
        phone.trim(),
        location.trim(),
        ...links.map((item) => item.trim()),
      ].where((item) => item.isNotEmpty).join(' | '),
      '',
      if (summary.trim().isNotEmpty) ...[
        'SUMMARY',
        summary.trim(),
        '',
      ],
      if (skills.isNotEmpty) ...[
        'SKILLS',
        skills.join(', '),
        '',
      ],
      if (experiences.isNotEmpty) ...[
        'EXPERIENCE',
        ...experiences.expand((item) => [item.toPlainText(), '']),
      ],
      if (projects.isNotEmpty) ...[
        'PROJECTS',
        ...projects.expand((item) => [item.toPlainText(), '']),
      ],
      if (education.isNotEmpty) ...[
        'EDUCATION',
        ...education.expand((item) => [item.toPlainText(), '']),
      ],
      if (certifications.isNotEmpty) ...[
        'CERTIFICATIONS',
        ...certifications,
      ],
    ];

    return lines
        .where((line) => line.trim().isNotEmpty || line.isEmpty)
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  factory ResumeDocument.blank({
    String name = '',
    String email = '',
  }) {
    return ResumeDocument(
      name: name,
      headline: '',
      email: email,
      phone: '',
      location: '',
      links: const [],
      summary: '',
      skills: const [],
      experiences: const [],
      projects: const [],
      education: const [],
      certifications: const [],
    );
  }

  factory ResumeDocument.sample({
    String name = '',
    String email = '',
  }) {
    return ResumeDocument(
      name: name.isEmpty ? 'Your Name' : name,
      headline: 'Flutter Developer | Firebase | Mobile Apps',
      email: email.isEmpty ? 'you@email.com' : email,
      phone: '+91 00000 00000',
      location: 'India',
      links: const ['linkedin.com/in/yourname', 'github.com/yourname'],
      summary:
          'Mobile app developer focused on building fast, reliable Flutter apps with Firebase, REST APIs, clean UI, and production-ready Android releases.',
      skills: const [
        'Flutter',
        'Dart',
        'Firebase',
        'REST APIs',
        'Provider',
        'Android',
        'Git',
      ],
      experiences: const [
        ResumeExperience(
          role: 'Flutter Developer',
          company: 'Company Name',
          period: '2024 - Present',
          location: 'Remote',
          bullets: [
            'Built and shipped Flutter screens with responsive Material 3 UI.',
            'Integrated Firebase Auth, Firestore, API calls, and local storage.',
            'Improved app responsiveness by reducing rebuilds and caching expensive calculations.',
          ],
        ),
      ],
      projects: const [
        ResumeProject(
          name: 'AutoHire AI',
          tech: 'Flutter, Firebase, AI, PDF',
          bullets: [
            'Created a job discovery and resume tailoring app with saved jobs and application tracking.',
            'Implemented PDF export, job search, and resume analysis flows.',
          ],
        ),
      ],
      education: const [
        ResumeEducation(
          degree: 'Degree / Course',
          school: 'Institute Name',
          period: '2021 - 2025',
          details: 'Relevant coursework, achievements, or CGPA',
        ),
      ],
      certifications: const ['Firebase fundamentals', 'Flutter development'],
    );
  }

  factory ResumeDocument.fromPlainText({
    required String text,
    String fallbackName = '',
    String fallbackEmail = '',
  }) {
    final cleaned = text
        .replaceAll(RegExp(r'\u0000+'), ' ')
        .replaceAll(RegExp(r'[^\S\r\n]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    final lines = cleaned
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final email =
        RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+').firstMatch(cleaned)?.group(0) ??
            fallbackEmail;
    final phone = RegExp(r'(?:\+?\d[\d\s().-]{7,}\d)')
            .firstMatch(cleaned)
            ?.group(0)
            ?.trim() ??
        '';
    final links = RegExp(
      r'(?:https?://)?(?:www\.)?(?:linkedin\.com|github\.com|behance\.net|dribbble\.com|[\w-]+\.[a-z]{2,})(?:/[^\s,;]*)?',
      caseSensitive: false,
    )
        .allMatches(cleaned)
        .map((match) => match.group(0) ?? '')
        .where((item) => item.isNotEmpty && !item.contains('@'))
        .toSet()
        .take(4)
        .toList();

    final firstLine = lines.isEmpty ? fallbackName : lines.first;
    final name = _looksLikeHeader(firstLine) ? fallbackName : firstLine;
    final headline = lines.length > 1 && lines[1].length <= 90 ? lines[1] : '';

    return ResumeDocument(
      name: name.isEmpty ? fallbackName : name,
      headline: headline,
      email: email,
      phone: phone,
      location: '',
      links: links,
      summary: cleaned,
      skills: _guessSkills(cleaned),
      experiences: const [],
      projects: const [],
      education: const [],
      certifications: const [],
    );
  }

  static bool _looksLikeHeader(String value) {
    final lower = value.toLowerCase();
    return lower.contains('@') ||
        lower.contains('resume') ||
        lower.contains('curriculum') ||
        lower.length > 60;
  }

  static List<String> _guessSkills(String text) {
    const known = [
      'Flutter',
      'Dart',
      'Firebase',
      'Android',
      'REST API',
      'Python',
      'Java',
      'Kotlin',
      'SQL',
      'Git',
      'Provider',
      'Figma',
      'React',
      'Node.js',
      'Excel',
      'Analytics',
    ];
    final lower = text.toLowerCase();
    return known
        .where((skill) => lower.contains(skill.toLowerCase()))
        .take(12)
        .toList();
  }
}

class ResumeExperience {
  const ResumeExperience({
    required this.role,
    required this.company,
    required this.period,
    required this.location,
    required this.bullets,
  });

  final String role;
  final String company;
  final String period;
  final String location;
  final List<String> bullets;

  String toPlainText() {
    return [
      [role, company].where((item) => item.trim().isNotEmpty).join(' - '),
      [period, location].where((item) => item.trim().isNotEmpty).join(' | '),
      ...bullets
          .where((item) => item.trim().isNotEmpty)
          .map((item) => '- ${item.trim()}'),
    ].where((line) => line.trim().isNotEmpty).join('\n');
  }
}

class ResumeProject {
  const ResumeProject({
    required this.name,
    required this.tech,
    required this.bullets,
  });

  final String name;
  final String tech;
  final List<String> bullets;

  String toPlainText() {
    return [
      [name, tech].where((item) => item.trim().isNotEmpty).join(' - '),
      ...bullets
          .where((item) => item.trim().isNotEmpty)
          .map((item) => '- ${item.trim()}'),
    ].where((line) => line.trim().isNotEmpty).join('\n');
  }
}

class ResumeEducation {
  const ResumeEducation({
    required this.degree,
    required this.school,
    required this.period,
    required this.details,
  });

  final String degree;
  final String school;
  final String period;
  final String details;

  String toPlainText() {
    return [
      [degree, school].where((item) => item.trim().isNotEmpty).join(' - '),
      period,
      details,
    ].where((line) => line.trim().isNotEmpty).join('\n');
  }
}
