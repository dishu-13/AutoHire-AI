class Job {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.url,
    required this.description,
    required this.category,
    required this.publishedAt,
    this.source = 'Live portal',
    this.salary,
    this.salaryMin,
    this.salaryMax,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String url;
  final String description;
  final String category;
  final DateTime publishedAt;
  final String source;
  final String? salary;
  final int? salaryMin;
  final int? salaryMax;

  String get salaryLabel {
    if (salary != null && salary!.trim().isNotEmpty) {
      return salary!;
    }
    if (salaryMin != null && salaryMax != null) {
      return '\$${salaryMin! ~/ 1000}k - \$${salaryMax! ~/ 1000}k';
    }
    if (salaryMin != null) {
      return 'From \$${salaryMin! ~/ 1000}k';
    }
    if (salaryMax != null) {
      return 'Up to \$${salaryMax! ~/ 1000}k';
    }
    return 'Salary not listed';
  }

  String get postedLabel {
    final age = DateTime.now().difference(publishedAt);
    if (age.inHours < 24) return 'Today';
    if (age.inDays == 1) return 'Yesterday';
    if (age.inDays < 30) return '${age.inDays}d ago';
    final months = (age.inDays / 30).floor();
    return '${months}mo ago';
  }

  bool get isIndiaFriendly {
    final text = _searchText;
    if (text.contains('india') || text.contains('inr')) return true;
    if (text.contains('apac') ||
        text.contains('asia') ||
        text.contains('worldwide') ||
        text.contains('anywhere') ||
        text.contains('global')) {
      return !_hasRestrictedRegion(text);
    }
    if (text.contains('remote')) {
      return !_hasRestrictedRegion(text);
    }
    return false;
  }

  bool get hasFastHiringSignal {
    final text = _searchText;
    const signals = [
      'urgent',
      'immediate',
      'quick',
      'screening call',
      'hiring',
      'contract',
      'freelance',
      'client',
      'feedback',
      'within a week',
      'within a couple',
      'join immediately',
      'start immediately',
    ];
    return signals.any(text.contains);
  }

  String get _searchText {
    return [
      title,
      company,
      location,
      description,
      category,
      source,
      salary ?? '',
    ].join(' ').toLowerCase();
  }

  factory Job.fromRemotive(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? json['url']?.toString() ?? '';
    final salaryText = json['salary']?.toString();
    final salaryRange = _parseSalaryRange(salaryText);

    return Job(
      id: id,
      title: json['title']?.toString() ?? 'Untitled role',
      company: json['company_name']?.toString() ?? 'Unknown company',
      location: json['candidate_required_location']?.toString() ?? 'Remote',
      url: json['url']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      publishedAt:
          DateTime.tryParse(json['publication_date']?.toString() ?? '') ??
              DateTime.now(),
      source: 'Remotive',
      salary: salaryText,
      salaryMin: salaryRange.$1,
      salaryMax: salaryRange.$2,
    );
  }

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled role',
      company: map['company']?.toString() ?? 'Unknown company',
      location: map['location']?.toString() ?? 'Remote',
      url: map['url']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'General',
      publishedAt: _asDateTime(map['publishedAt']) ?? DateTime.now(),
      source: map['source']?.toString() ?? 'Live portal',
      salary: map['salary']?.toString(),
      salaryMin: _asInt(map['salaryMin']),
      salaryMax: _asInt(map['salaryMax']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'location': location,
      'url': url,
      'description': description,
      'category': category,
      'publishedAt': publishedAt.toIso8601String(),
      'source': source,
      'salary': salary,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
    };
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      final converted = value?.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      return null;
    }
    return null;
  }

  static (int?, int?) _parseSalaryRange(String? salary) {
    if (salary == null || salary.trim().isEmpty) {
      return (null, null);
    }

    final matches = RegExp(r'(\d{2,3})(?:[,.]\d{3})?k?', caseSensitive: false)
        .allMatches(salary.replaceAll(',', ''))
        .map((match) => int.tryParse(match.group(1) ?? ''))
        .whereType<int>()
        .map((value) => value < 1000 ? value * 1000 : value)
        .toList();

    if (matches.isEmpty) {
      return (null, null);
    }

    matches.sort();
    return (matches.first, matches.length > 1 ? matches.last : null);
  }

  static bool _hasRestrictedRegion(String text) {
    const restricted = [
      'usa only',
      'us only',
      'u.s. only',
      'united states only',
      'united states residents',
      'located in the usa',
      'located in the us',
      'us-based',
      'u.s.-based',
      'united states-based',
      'canada only',
      'europe only',
      'eu only',
      'uk only',
      'latin america only',
      'north america only',
    ];
    return restricted.any(text.contains);
  }
}
