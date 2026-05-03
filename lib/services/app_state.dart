import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/application_record.dart';
import '../models/job.dart';
import '../models/resume_result.dart';
import '../models/user_profile.dart';
import 'ai_resume_service.dart';
import 'firebase_service.dart';
import 'jobs_api_service.dart';
import 'pdf_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.firebaseService,
    required this.preferences,
    AiResumeService? aiResumeService,
    JobsApiService? jobsApiService,
    PdfService? pdfService,
  })  : _aiResumeService = aiResumeService ?? const AiResumeService(),
        _jobsApiService = jobsApiService ?? JobsApiService(),
        _pdfService = pdfService ?? PdfService();

  static const _profileKey = 'profile.v1';
  static const _savedJobsKey = 'savedJobs.v1';
  static const _applicationsKey = 'applications.v1';
  static const _resumeResultKey = 'resumeResult.v1';

  final FirebaseService firebaseService;
  final SharedPreferences preferences;
  final AiResumeService _aiResumeService;
  final JobsApiService _jobsApiService;
  final PdfService _pdfService;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;
  StreamSubscription<List<Job>>? _savedJobsSubscription;
  StreamSubscription<List<ApplicationRecord>>? _applicationsSubscription;
  StreamSubscription<ResumeResult?>? _resumeResultSubscription;

  List<Job> _jobs = [];
  List<Job> _savedJobs = [];
  List<ApplicationRecord> _applications = [];

  UserProfile profile = UserProfile.empty();
  User? user;
  ResumeResult? resumeResult;

  bool isLoadingJobs = false;
  bool isTailoringResume = false;
  String? jobsError;
  String? resumeError;

  String roleFilter = '';
  String locationFilter = '';
  int minimumSalary = 0;
  bool indiaFriendlyOnly = true;
  bool fastHiringOnly = false;

  List<Job> get jobs => List.unmodifiable(_jobs);
  List<Job> get savedJobs => List.unmodifiable(_savedJobs);
  List<ApplicationRecord> get applications => List.unmodifiable(_applications);

  bool get firebaseEnabled => firebaseService.isEnabled;
  bool get aiConfigured => _aiResumeService.isConfigured;
  bool get isAuthenticated => user != null;
  bool get hasResumeResult => resumeResult != null;

  List<Job> get filteredJobs {
    final role = roleFilter.trim().toLowerCase();
    final location = locationFilter.trim().toLowerCase();

    return _jobs.where((job) {
      final roleMatches = role.isEmpty ||
          job.title.toLowerCase().contains(role) ||
          job.company.toLowerCase().contains(role) ||
          job.category.toLowerCase().contains(role);
      final locationMatches =
          location.isEmpty || job.location.toLowerCase().contains(location);
      final salaryMatches = minimumSalary == 0 ||
          (job.salaryMax != null && job.salaryMax! >= minimumSalary) ||
          (job.salaryMin != null && job.salaryMin! >= minimumSalary);
      final indiaMatches = !indiaFriendlyOnly || job.isIndiaFriendly;
      final fastHiringMatches = !fastHiringOnly || job.hasFastHiringSignal;
      return roleMatches &&
          locationMatches &&
          salaryMatches &&
          indiaMatches &&
          fastHiringMatches;
    }).toList();
  }

  Map<ApplicationStatus, int> get statusCounts {
    return {
      for (final status in ApplicationStatus.values)
        status: _applications.where((record) => record.status == status).length,
    };
  }

  double get successRate {
    final decided = _applications
        .where(
          (record) =>
              record.status == ApplicationStatus.offer ||
              record.status == ApplicationStatus.rejected,
        )
        .length;
    if (decided == 0) return 0;
    final offers = _applications
        .where((record) => record.status == ApplicationStatus.offer)
        .length;
    return offers / decided;
  }

  List<ApplicationRecord> get timeline {
    final copy = [..._applications];
    copy.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return copy;
  }

  List<String> searchSuggestionsFor(String query) {
    final normalized = query.trim().toLowerCase();
    final values = <String>{
      'Flutter',
      'Android',
      'Python',
      'Data Analyst',
      'Product Manager',
      'UI UX Designer',
      'Remote India',
      'Fresher',
      'Internship',
      'Contract',
      for (final job in _jobs) job.title,
      for (final job in _jobs) job.company,
      for (final job in _jobs) job.category,
    }.where((value) {
      final item = value.trim();
      if (item.length < 3) return false;
      return normalized.isEmpty || item.toLowerCase().contains(normalized);
    }).toList()
      ..sort((a, b) => a.length.compareTo(b.length));

    return values.take(6).toList();
  }

  Future<void> bootstrap() async {
    _loadLocalState();
    _listenToAuthState();
    await refreshJobs(silent: true);
  }

  Future<void> refreshJobs({bool silent = false}) async {
    if (!silent) {
      isLoadingJobs = true;
      jobsError = null;
      notifyListeners();
    }

    try {
      _jobs = await _jobsApiService.fetchJobs(
        search: roleFilter.trim().isEmpty ? null : roleFilter,
      );
      jobsError = _jobs.isEmpty ? 'No live jobs matched this search.' : null;
    } catch (_) {
      if (_jobs.isEmpty) {
        _jobs = JobsApiService.sampleJobs();
      }
      jobsError =
          'Live portals are not reachable right now. Showing starter roles.';
    } finally {
      isLoadingJobs = false;
      notifyListeners();
    }
  }

  void setRoleFilter(String value) {
    roleFilter = value;
    notifyListeners();
  }

  void setLocationFilter(String value) {
    locationFilter = value;
    notifyListeners();
  }

  void setMinimumSalary(int value) {
    minimumSalary = max(0, value);
    notifyListeners();
  }

  void setIndiaFriendlyOnly(bool value) {
    indiaFriendlyOnly = value;
    notifyListeners();
  }

  void setFastHiringOnly(bool value) {
    fastHiringOnly = value;
    notifyListeners();
  }

  void clearJobFilters() {
    roleFilter = '';
    locationFilter = '';
    minimumSalary = 0;
    indiaFriendlyOnly = true;
    fastHiringOnly = false;
    notifyListeners();
  }

  bool isJobSaved(String jobId) {
    return _savedJobs.any((job) => job.id == jobId);
  }

  bool isTracked(String jobId) {
    return _applications.any((record) => record.jobId == jobId);
  }

  Future<void> toggleSaveJob(Job job) async {
    if (isJobSaved(job.id)) {
      _savedJobs.removeWhere((saved) => saved.id == job.id);
      await firebaseService.removeSavedJob(job.id);
    } else {
      _savedJobs = [job, ..._savedJobs];
      await firebaseService.saveJob(job);
    }
    await _persistSavedJobs();
    notifyListeners();
  }

  Future<void> addToTracker(Job job) async {
    if (isTracked(job.id)) return;
    final record = ApplicationRecord.fromJob(job);
    _applications = [record, ..._applications];
    await firebaseService.upsertApplication(record);
    await _persistApplications();
    notifyListeners();
  }

  Future<void> updateApplicationStatus(
    ApplicationRecord record,
    ApplicationStatus status,
  ) async {
    final updated = record.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    _applications = _applications
        .map((candidate) => candidate.id == record.id ? updated : candidate)
        .toList();
    await firebaseService.upsertApplication(updated);
    await _persistApplications();
    notifyListeners();
  }

  Future<void> updateApplicationNotes(
    ApplicationRecord record,
    String notes,
  ) async {
    final updated = record.copyWith(
      notes: notes,
      updatedAt: DateTime.now(),
    );
    _applications = _applications
        .map((candidate) => candidate.id == record.id ? updated : candidate)
        .toList();
    await firebaseService.upsertApplication(updated);
    await _persistApplications();
    notifyListeners();
  }

  Future<void> removeApplication(ApplicationRecord record) async {
    _applications.removeWhere((candidate) => candidate.id == record.id);
    await firebaseService.deleteApplication(record.id);
    await _persistApplications();
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? resumeText,
    bool? darkMode,
    bool? jobAlerts,
    bool? applicationUpdates,
    String? preferredLocation,
    String? salaryExpectation,
  }) async {
    profile = profile.copyWith(
      name: name,
      email: email,
      resumeText: resumeText,
      darkMode: darkMode,
      jobAlerts: jobAlerts,
      applicationUpdates: applicationUpdates,
      preferredLocation: preferredLocation,
      salaryExpectation: salaryExpectation,
    );
    await _persistProfile();
    await firebaseService.saveProfile(profile);
    notifyListeners();
  }

  Future<void> tailorResume({
    required String resumeText,
    required String targetJobDescription,
    required String templateStyle,
  }) async {
    if (resumeText.trim().isEmpty || targetJobDescription.trim().isEmpty) {
      resumeError = 'Add both resume text and the target job description.';
      notifyListeners();
      return;
    }

    isTailoringResume = true;
    resumeError = null;
    notifyListeners();

    try {
      final result = await _aiResumeService.tailorResume(
        resumeText: resumeText,
        targetJobDescription: targetJobDescription,
        templateStyle: templateStyle,
      );
      resumeResult = result;
      profile = profile.copyWith(resumeText: resumeText);
      await _persistProfile();
      await _persistResumeResult();
      await firebaseService.saveProfile(profile);
      await firebaseService.saveResumeResult(result);
    } catch (error) {
      resumeError = error.toString();
    } finally {
      isTailoringResume = false;
      notifyListeners();
    }
  }

  Future<void> exportTailoredResumePdf() async {
    final result = resumeResult;
    if (result == null) return;
    await _pdfService.exportResume(
      result: result,
      candidateName: profile.name,
    );
  }

  Future<void> logout() async {
    await firebaseService.signOut();
    resumeResult = null;
    await preferences.remove(_resumeResultKey);
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await firebaseService.signInWithEmail(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    final credential = await firebaseService.signInWithGoogle();
    final signedInUser = credential.user;
    if (signedInUser == null) return;
    profile = profile.copyWith(
      name: signedInUser.displayName ?? profile.name,
      email: signedInUser.email ?? profile.email,
    );
    await _persistProfile();
    await firebaseService.saveProfile(profile);
    notifyListeners();
  }

  Future<void> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await firebaseService.createAccountWithEmail(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
    await updateProfile(name: name.trim(), email: email.trim());
  }

  Future<void> sendPasswordReset(String email) {
    return firebaseService.sendPasswordReset(email);
  }

  void _listenToAuthState() {
    _authSubscription?.cancel();
    user = firebaseService.currentUser;

    if (!firebaseService.isEnabled) {
      notifyListeners();
      return;
    }

    _authSubscription = firebaseService.authStateChanges().listen((value) {
      user = value;
      if (value == null) {
        _cancelUserCloudSubscriptions();
        _savedJobs = [];
        _applications = [];
        profile = UserProfile.empty();
      } else {
        profile = profile.copyWith(
          name: value.displayName ?? profile.name,
          email: value.email ?? profile.email,
        );
        _listenToUserCloudState();
      }
      notifyListeners();
    });
  }

  void _listenToUserCloudState() {
    if (!firebaseService.isEnabled) return;

    _cancelUserCloudSubscriptions();

    _profileSubscription = firebaseService.profileStream().listen((value) {
      if (value == null) return;
      profile = value;
      unawaited(_persistProfile());
      notifyListeners();
    });

    _savedJobsSubscription = firebaseService.savedJobsStream().listen((value) {
      _savedJobs = value;
      unawaited(_persistSavedJobs());
      notifyListeners();
    });

    _applicationsSubscription =
        firebaseService.applicationsStream().listen((value) {
      _applications = value;
      unawaited(_persistApplications());
      notifyListeners();
    });

    _resumeResultSubscription =
        firebaseService.latestResumeResultStream().listen((value) {
      if (value == null) return;
      resumeResult = value;
      unawaited(_persistResumeResult());
      notifyListeners();
    });
  }

  void _cancelUserCloudSubscriptions() {
    _profileSubscription?.cancel();
    _savedJobsSubscription?.cancel();
    _applicationsSubscription?.cancel();
    _resumeResultSubscription?.cancel();
    _profileSubscription = null;
    _savedJobsSubscription = null;
    _applicationsSubscription = null;
    _resumeResultSubscription = null;
  }

  void _loadLocalState() {
    final profileJson = preferences.getString(_profileKey);
    if (profileJson != null) {
      profile = UserProfile.fromMap(
        Map<String, dynamic>.from(jsonDecode(profileJson) as Map),
      );
    }

    final savedJobsJson = preferences.getString(_savedJobsKey);
    if (savedJobsJson != null) {
      _savedJobs = (jsonDecode(savedJobsJson) as List)
          .map((item) => Job.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    final applicationsJson = preferences.getString(_applicationsKey);
    if (applicationsJson != null) {
      _applications = (jsonDecode(applicationsJson) as List)
          .map(
            (item) => ApplicationRecord.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    final resumeResultJson = preferences.getString(_resumeResultKey);
    if (resumeResultJson != null) {
      resumeResult = ResumeResult.fromMap(
        Map<String, dynamic>.from(jsonDecode(resumeResultJson) as Map),
      );
    }
  }

  Future<void> _persistProfile() {
    return preferences.setString(_profileKey, jsonEncode(profile.toMap()));
  }

  Future<void> _persistSavedJobs() {
    return preferences.setString(
      _savedJobsKey,
      jsonEncode(_savedJobs.map((job) => job.toMap()).toList()),
    );
  }

  Future<void> _persistApplications() {
    return preferences.setString(
      _applicationsKey,
      jsonEncode(_applications.map((record) => record.toMap()).toList()),
    );
  }

  Future<void> _persistResumeResult() {
    final result = resumeResult;
    if (result == null) {
      return preferences.remove(_resumeResultKey);
    }
    return preferences.setString(_resumeResultKey, jsonEncode(result.toMap()));
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    _savedJobsSubscription?.cancel();
    _applicationsSubscription?.cancel();
    _resumeResultSubscription?.cancel();
    super.dispose();
  }
}
