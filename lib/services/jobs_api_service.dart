import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/job.dart';

class JobsApiService {
  JobsApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _remotiveUri = 'https://remotive.com/api/remote-jobs';
  static const _arbeitnowUri = 'https://www.arbeitnow.com/api/job-board-api';
  static const _museUri = 'https://www.themuse.com/api/public/jobs';
  static const _himalayasUri = 'https://himalayas.app/jobs/api/search';
  static const _jobicyUri = 'https://jobicy.com/api/v2/remote-jobs';
  static const _remoteOkUri = 'https://remoteok.com/api';
  static const _wwrRssUri = 'https://weworkremotely.com/remote-jobs.rss';
  static const _adzunaAppId = String.fromEnvironment('ADZUNA_APP_ID');
  static const _adzunaAppKey = String.fromEnvironment('ADZUNA_APP_KEY');

  Future<List<Job>> fetchJobs({
    String? search,
    String? category,
  }) async {
    final failures = <String>[];
    final results = await Future.wait([
      _guardedFetch(
        source: 'Himalayas',
        failures: failures,
        request: () => _fetchHimalayas(search: search, category: category),
      ),
      _guardedFetch(
        source: 'The Muse',
        failures: failures,
        request: () => _fetchMuse(search: search, category: category),
      ),
      _guardedFetch(
        source: 'Jobicy',
        failures: failures,
        request: () => _fetchJobicy(search: search, category: category),
      ),
      _guardedFetch(
        source: 'RemoteOK',
        failures: failures,
        request: () => _fetchRemoteOk(search: search, category: category),
      ),
      _guardedFetch(
        source: 'We Work Remotely',
        failures: failures,
        request: () => _fetchWeWorkRemotely(search: search, category: category),
      ),
      _guardedFetch(
        source: 'Remotive',
        failures: failures,
        request: () => _fetchRemotive(search: search, category: category),
      ),
      _guardedFetch(
        source: 'Arbeitnow',
        failures: failures,
        request: () => _fetchArbeitnow(search: search, category: category),
      ),
      if (_adzunaEnabled)
        _guardedFetch(
          source: 'Adzuna India',
          failures: failures,
          request: () => _fetchAdzunaIndia(search: search, category: category),
        ),
    ]);

    final jobs = _dedupe(results.expand((sourceJobs) => sourceJobs))
        .where((job) => _matchesSearch(job, search))
        .where((job) => _matchesCategory(job, category))
        .toList()
      ..sort(_compareJobs);

    if (jobs.isEmpty && failures.length == results.length) {
      throw const JobsApiException(
          'Live job sources are unavailable right now.');
    }

    return jobs.take(220).toList();
  }

  bool get _adzunaEnabled {
    return _adzunaAppId.trim().isNotEmpty && _adzunaAppKey.trim().isNotEmpty;
  }

  Future<List<Job>> _fetchRemotive({
    String? search,
    String? category,
  }) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      query['category'] = category.trim();
    }

    final uri = Uri.parse(_remotiveUri).replace(queryParameters: query);
    final response = await _get(uri);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['jobs'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Job.fromRemotive)
        .where((job) => job.url.isNotEmpty)
        .toList();
  }

  Future<List<Job>> _fetchArbeitnow({
    String? search,
    String? category,
  }) async {
    final response = await _get(Uri.parse(_arbeitnowUri));
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_jobFromArbeitnow)
        .where((job) => job.url.isNotEmpty)
        .where((job) => _matchesSearch(job, search))
        .where((job) => _matchesCategory(job, category))
        .toList();
  }

  Future<List<Job>> _fetchMuse({
    String? search,
    String? category,
  }) async {
    final query = <String, String>{
      'page': '1',
      'location': 'India',
      if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
    };

    final response =
        await _get(Uri.parse(_museUri).replace(queryParameters: query));
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['results'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_jobFromMuse)
        .where((job) => job.url.isNotEmpty)
        .where((job) => _matchesCategory(job, category))
        .toList();
  }

  Future<List<Job>> _fetchHimalayas({
    String? search,
    String? category,
  }) async {
    final query = <String, String>{
      'country': 'IN',
      'limit': '40',
      if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
    };

    final response =
        await _get(Uri.parse(_himalayasUri).replace(queryParameters: query));
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['jobs'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_jobFromHimalayas)
        .where((job) => job.url.isNotEmpty)
        .where((job) => _matchesCategory(job, category))
        .toList();
  }

  Future<List<Job>> _fetchJobicy({
    String? search,
    String? category,
  }) async {
    final query = <String, String>{
      'count': '40',
      'geo': 'apac',
      if (search != null && search.trim().isNotEmpty) 'tag': search.trim(),
    };

    final response =
        await _get(Uri.parse(_jobicyUri).replace(queryParameters: query));
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['jobs'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_jobFromJobicy)
        .where((job) => job.url.isNotEmpty)
        .where((job) => _matchesCategory(job, category))
        .toList();
  }

  Future<List<Job>> _fetchRemoteOk({
    String? search,
    String? category,
  }) async {
    final response = await _get(Uri.parse(_remoteOkUri));
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .where((json) => json['id'] != null && json['position'] != null)
        .map(_jobFromRemoteOk)
        .where((job) => job.url.isNotEmpty)
        .where((job) => _matchesSearch(job, search))
        .where((job) => _matchesCategory(job, category))
        .take(60)
        .toList();
  }

  Future<List<Job>> _fetchWeWorkRemotely({
    String? search,
    String? category,
  }) async {
    final response = await _get(Uri.parse(_wwrRssUri));
    final document = XmlDocument.parse(response.body);
    return document
        .findAllElements('item')
        .map(_jobFromWwrItem)
        .where((job) {
          return job.url.isNotEmpty &&
              _matchesSearch(job, search) &&
              _matchesCategory(job, category);
        })
        .take(60)
        .toList();
  }

  Future<List<Job>> _fetchAdzunaIndia({
    String? search,
    String? category,
  }) async {
    final query = <String, String>{
      'app_id': _adzunaAppId,
      'app_key': _adzunaAppKey,
      'results_per_page': '40',
      'where': 'India',
      'sort_by': 'date',
      if (search != null && search.trim().isNotEmpty) 'what': search.trim(),
      if (category != null && category.trim().isNotEmpty)
        'category': category.trim(),
    };

    final uri = Uri.https('api.adzuna.com', '/v1/api/jobs/in/search/1', query);
    final response = await _get(uri);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['results'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_jobFromAdzuna)
        .where((job) => job.url.isNotEmpty)
        .toList();
  }

  Future<http.Response> _get(Uri uri) async {
    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json, text/xml, application/rss+xml, */*',
        'User-Agent': 'SmartJobAssistant/1.0 (+https://firebase.google.com/)',
      },
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw JobsApiException(
        '${uri.host} returned ${response.statusCode}: ${response.reasonPhrase}',
      );
    }
    return response;
  }

  Future<List<Job>> _guardedFetch({
    required String source,
    required List<String> failures,
    required Future<List<Job>> Function() request,
  }) async {
    try {
      return await request();
    } catch (error) {
      failures.add('$source: $error');
      return const [];
    }
  }

  Job _jobFromArbeitnow(Map<String, dynamic> json) {
    final url = json['url']?.toString() ?? '';
    final slug = json['slug']?.toString();
    final tags = _stringList(json['tags']);
    final jobTypes = _stringList(json['job_types']);
    final rawLocation = json['location']?.toString().trim();
    final isRemote = json['remote'] == true;
    final location = [
      if (isRemote) 'Remote',
      if (rawLocation != null && rawLocation.isNotEmpty) rawLocation,
    ].join(' - ');
    final publishedAt = _dateFromUnixSeconds(json['created_at']);

    return Job(
      id: 'arbeitnow-${_stableId(slug?.isNotEmpty == true ? slug! : url)}',
      title: json['title']?.toString() ?? 'Untitled role',
      company: json['company_name']?.toString() ?? 'Unknown company',
      location: location.isEmpty ? 'Remote' : location,
      url: url,
      description: json['description']?.toString() ?? '',
      category: _firstNonEmpty([
        if (tags.isNotEmpty) tags.take(2).join(', '),
        if (jobTypes.isNotEmpty) jobTypes.first,
      ], fallback: 'General'),
      publishedAt: publishedAt ?? DateTime.now(),
      source: 'Arbeitnow',
    );
  }

  Job _jobFromMuse(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? json['short_name']?.toString() ?? '';
    final locations = (json['locations'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((item) => item['name']?.toString() ?? '')
        .where((item) => item.trim().isNotEmpty)
        .toList();
    final categories = (json['categories'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((item) => item['name']?.toString() ?? '')
        .where((item) => item.trim().isNotEmpty)
        .toList();
    final company = json['company'];
    final refs = json['refs'];

    return Job(
      id: 'muse-${_stableId(id)}',
      title: json['name']?.toString() ?? 'Untitled role',
      company: company is Map
          ? company['name']?.toString() ?? 'Unknown company'
          : 'Unknown company',
      location: locations.isEmpty ? 'India / Remote' : locations.join(', '),
      url: refs is Map ? refs['landing_page']?.toString() ?? '' : '',
      description: json['contents']?.toString() ?? '',
      category: categories.isEmpty ? 'General' : categories.take(2).join(', '),
      publishedAt:
          DateTime.tryParse(json['publication_date']?.toString() ?? '') ??
              DateTime.now(),
      source: 'The Muse India',
    );
  }

  Job _jobFromHimalayas(Map<String, dynamic> json) {
    final categories = _stringList(json['categories']);
    final seniority = _stringList(json['seniority']);
    final locations = _stringList(json['locationRestrictions']);
    final url =
        json['applicationLink']?.toString() ?? json['guid']?.toString() ?? '';
    final minSalary = _asInt(json['minSalary']);
    final maxSalary = _asInt(json['maxSalary']);
    final currency = json['currency']?.toString();
    final salary = _salaryLabel(currency, minSalary, maxSalary);

    return Job(
      id: 'himalayas-${_stableId(json['guid']?.toString() ?? url)}',
      title: json['title']?.toString() ?? 'Untitled role',
      company: json['companyName']?.toString() ?? 'Unknown company',
      location:
          locations.isEmpty ? 'Remote - India' : locations.take(3).join(', '),
      url: url,
      description:
          json['description']?.toString() ?? json['excerpt']?.toString() ?? '',
      category: _firstNonEmpty([
        if (categories.isNotEmpty) categories.take(2).join(', '),
        if (seniority.isNotEmpty) seniority.first,
      ], fallback: 'Remote'),
      publishedAt: _dateFromUnixSeconds(json['pubDate']) ?? DateTime.now(),
      source: 'Himalayas India',
      salary: salary,
      salaryMin: minSalary,
      salaryMax: maxSalary,
    );
  }

  Job _jobFromJobicy(Map<String, dynamic> json) {
    final industries = _stringList(json['jobIndustry']);
    final jobTypes = _stringList(json['jobType']);
    final location = json['jobGeo']?.toString() ?? 'Remote';

    return Job(
      id: 'jobicy-${_stableId(json['id']?.toString() ?? json['url']?.toString() ?? '')}',
      title: json['jobTitle']?.toString() ?? 'Untitled role',
      company: json['companyName']?.toString() ?? 'Unknown company',
      location: 'Remote - $location',
      url: json['url']?.toString() ?? '',
      description: json['jobDescription']?.toString() ??
          json['jobExcerpt']?.toString() ??
          '',
      category: _firstNonEmpty(
        [
          if (industries.isNotEmpty) industries.take(2).join(', '),
          if (jobTypes.isNotEmpty) jobTypes.first,
        ],
        fallback: 'Remote',
      ),
      publishedAt: DateTime.tryParse(json['pubDate']?.toString() ?? '') ??
          DateTime.now(),
      source: 'Jobicy APAC',
    );
  }

  Job _jobFromRemoteOk(Map<String, dynamic> json) {
    final tags = _stringList(json['tags']);
    final location = json['location']?.toString();
    final salaryMin = _asInt(json['salary_min']);
    final salaryMax = _asInt(json['salary_max']);

    return Job(
      id: 'remoteok-${_stableId(json['id']?.toString() ?? json['url']?.toString() ?? '')}',
      title: json['position']?.toString() ?? 'Untitled role',
      company: json['company']?.toString() ?? 'Unknown company',
      location: location == null || location.trim().isEmpty
          ? 'Remote'
          : 'Remote - $location',
      url: json['url']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: tags.isEmpty ? 'Remote' : tags.take(3).join(', '),
      publishedAt:
          DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      source: 'RemoteOK',
      salaryMin: salaryMin,
      salaryMax: salaryMax,
    );
  }

  Job _jobFromWwrItem(XmlElement item) {
    final title = _xmlText(item, 'title');
    final parts = title.split(':');
    final company = parts.length > 1 ? parts.first.trim() : 'Unknown company';
    final role = parts.length > 1 ? parts.skip(1).join(':').trim() : title;
    final region = _xmlText(item, 'region');
    final country = _xmlText(item, 'country');
    final location = _firstNonEmpty(
      [country, region, _xmlText(item, 'state')],
      fallback: 'Remote',
    );
    final category = _firstNonEmpty(
      [_xmlText(item, 'category'), _xmlText(item, 'type')],
      fallback: 'Remote',
    );
    final url = _xmlText(item, 'link');

    return Job(
      id: 'wwr-${_stableId(_xmlText(item, 'guid').isNotEmpty ? _xmlText(item, 'guid') : url)}',
      title: role.isEmpty ? 'Untitled role' : role,
      company: company,
      location: 'Remote - $location',
      url: url,
      description: _xmlText(item, 'description'),
      category: category,
      publishedAt: _parseDate(_xmlText(item, 'pubDate')) ?? DateTime.now(),
      source: 'We Work Remotely',
    );
  }

  Job _jobFromAdzuna(Map<String, dynamic> json) {
    final company = json['company'];
    final location = json['location'];
    final salaryMin = _asInt(json['salary_min']);
    final salaryMax = _asInt(json['salary_max']);

    return Job(
      id: 'adzuna-${_stableId(json['id']?.toString() ?? json['redirect_url']?.toString() ?? '')}',
      title: json['title']?.toString() ?? 'Untitled role',
      company: company is Map
          ? company['display_name']?.toString() ?? 'Unknown company'
          : 'Unknown company',
      location: location is Map
          ? location['display_name']?.toString() ?? 'India'
          : 'India',
      url: json['redirect_url']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: 'India Jobs',
      publishedAt: DateTime.tryParse(json['created']?.toString() ?? '') ??
          DateTime.now(),
      source: 'Adzuna India',
      salaryMin: salaryMin,
      salaryMax: salaryMax,
    );
  }

  int _compareJobs(Job a, Job b) {
    final byFit = _marketFitScore(b).compareTo(_marketFitScore(a));
    if (byFit != 0) return byFit;
    return b.publishedAt.compareTo(a.publishedAt);
  }

  int _marketFitScore(Job job) {
    final text = [
      job.title,
      job.company,
      job.location,
      job.category,
      job.description,
      job.source,
      job.salary ?? '',
    ].join(' ').toLowerCase();

    var score = 0;
    if (text.contains('india') || text.contains('inr')) score += 160;
    if (text.contains('apac') || text.contains('asia')) score += 80;
    if (text.contains('remote') || text.contains('worldwide')) score += 55;
    if (job.source.contains('Himalayas')) score += 45;
    if (job.source.contains('The Muse')) score += 40;
    if (job.source.contains('Jobicy')) score += 25;
    if (_mentionsFastHiring(text)) score += 30;

    final ageDays = DateTime.now().difference(job.publishedAt).inDays;
    if (ageDays <= 2) score += 45;
    if (ageDays <= 7) score += 30;
    if (ageDays <= 21) score += 15;
    return score;
  }

  bool _mentionsFastHiring(String text) {
    const phrases = [
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
    ];
    return phrases.any(text.contains);
  }

  List<Job> _dedupe(Iterable<Job> jobs) {
    final seen = <String>{};
    final unique = <Job>[];
    for (final job in jobs) {
      final key = [
        job.title.trim().toLowerCase(),
        job.company.trim().toLowerCase(),
        job.url.trim().toLowerCase(),
      ].join('|');
      if (seen.add(key)) {
        unique.add(job);
      }
    }
    return unique;
  }

  bool _matchesSearch(Job job, String? search) {
    final query = search?.trim().toLowerCase();
    if (query == null || query.isEmpty) return true;

    final terms =
        query.split(RegExp(r'\s+')).where((term) => term.length > 1).toList();
    if (terms.isEmpty) return true;

    final haystack = [
      job.title,
      job.company,
      job.location,
      job.category,
      job.description,
    ].join(' ').toLowerCase();
    return terms.every(haystack.contains);
  }

  bool _matchesCategory(Job job, String? category) {
    final query = category?.trim().toLowerCase();
    if (query == null || query.isEmpty) return true;
    return job.category.toLowerCase().contains(query);
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  DateTime? _dateFromUnixSeconds(dynamic value) {
    final seconds =
        value is int ? value : int.tryParse(value?.toString() ?? '');
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  DateTime? _parseDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    try {
      return HttpDate.parse(value);
    } catch (_) {
      return null;
    }
  }

  String _stableId(String value) {
    if (value.trim().isEmpty) {
      return DateTime.now().microsecondsSinceEpoch.toString();
    }
    final encoded =
        base64Url.encode(utf8.encode(value.trim())).replaceAll('=', '');
    final limit = encoded.length < 40 ? encoded.length : 40;
    return encoded.substring(0, limit);
  }

  String _xmlText(XmlElement element, String name) {
    return element.getElement(name)?.innerText.trim() ?? '';
  }

  String _firstNonEmpty(List<String> values, {required String fallback}) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return fallback;
  }

  String? _salaryLabel(String? currency, int? minSalary, int? maxSalary) {
    if (minSalary == null && maxSalary == null) return null;
    final prefix = currency == null || currency.isEmpty ? '' : '$currency ';
    if (minSalary != null && maxSalary != null) {
      return '$prefix$minSalary - $maxSalary';
    }
    if (minSalary != null) return 'From $prefix$minSalary';
    return 'Up to $prefix$maxSalary';
  }

  static List<Job> sampleJobs() {
    final now = DateTime.now();
    return [
      Job(
        id: 'sample-india-flutter-engineer',
        title: 'Flutter Mobile Engineer',
        company: 'Northstar Labs',
        location: 'Remote - India',
        url: 'https://himalayas.app/jobs',
        description:
            'Build polished mobile workflows, integrate Firebase, and ship Android features for Indian and global customers.',
        category: 'Software Development',
        publishedAt: now.subtract(const Duration(hours: 8)),
        source: 'Sample India',
        salary: 'INR 12L - 24L',
        salaryMin: 1200000,
        salaryMax: 2400000,
      ),
      Job(
        id: 'sample-ai-product-designer',
        title: 'AI Product Designer',
        company: 'BrightPath AI',
        location: 'Remote - APAC',
        url: 'https://jobicy.com',
        description:
            'Design AI-assisted job seeker experiences, run discovery, and translate insights into production-ready product screens.',
        category: 'Product',
        publishedAt: now.subtract(const Duration(days: 1)),
        source: 'Sample Remote',
        salary: '\$95k - \$130k',
        salaryMin: 95000,
        salaryMax: 130000,
      ),
      Job(
        id: 'sample-growth-analyst',
        title: 'Growth Analyst',
        company: 'RemoteScale',
        location: 'Bengaluru / Remote',
        url: 'https://www.themuse.com/search/location/india/',
        description:
            'Analyze funnels, track application outcomes, and build reports that help teams improve candidate conversion.',
        category: 'Marketing',
        publishedAt: now.subtract(const Duration(days: 2)),
        source: 'Sample India',
        salary: 'INR 8L - 16L',
        salaryMin: 800000,
        salaryMax: 1600000,
      ),
    ];
  }
}

class JobsApiException implements Exception {
  const JobsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
