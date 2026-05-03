import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../models/application_record.dart';
import '../models/job.dart';
import '../models/resume_result.dart';
import '../models/user_profile.dart';

class FirebaseService {
  bool _enabled = false;
  bool _googleInitialized = false;

  static const _googleServerClientId =
      '556007849704-7g9bs2m0akj2ppna445saaql1bjieikk.apps.googleusercontent.com';

  bool get isEnabled => _enabled;
  User? get currentUser => _enabled ? FirebaseAuth.instance.currentUser : null;
  Stream<User?> authStateChanges() {
    if (!_enabled) {
      return Stream.value(null);
    }
    return FirebaseAuth.instance.authStateChanges();
  }

  Future<void> initialize() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      _enabled = false;
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _enabled = true;
      try {
        await _initializeGoogleSignIn();
      } catch (_) {
        _googleInitialized = false;
      }
    } catch (_) {
      _enabled = false;
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    _assertEnabled();
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> createAccountWithEmail({
    required String email,
    required String password,
  }) {
    _assertEnabled();
    return FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    _assertEnabled();
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserCredential> signInWithGoogle() async {
    _assertEnabled();
    await _initializeGoogleSignIn();

    final googleSignIn = GoogleSignIn.instance;
    if (!googleSignIn.supportsAuthenticate()) {
      throw StateError('Google sign-in is not supported on this device.');
    }

    final account = await googleSignIn.authenticate(
      scopeHint: const ['email', 'profile'],
    );
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Stream<UserProfile?> profileStream() {
    if (!_enabled || currentUser == null) {
      return Stream.value(null);
    }
    return _userDoc.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return UserProfile.fromMap(data);
    });
  }

  Stream<List<Job>> savedJobsStream() {
    if (!_enabled || currentUser == null) {
      return Stream.value(const []);
    }
    return _userDoc.collection('savedJobs').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Job.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  Stream<List<ApplicationRecord>> applicationsStream() {
    if (!_enabled || currentUser == null) {
      return Stream.value(const []);
    }
    return _userDoc
        .collection('applications')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ApplicationRecord.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                }),
              )
              .toList(),
        );
  }

  Stream<ResumeResult?> latestResumeResultStream() {
    if (!_enabled || currentUser == null) {
      return Stream.value(null);
    }
    return _userDoc
        .collection('resumeResults')
        .orderBy('generatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ResumeResult.fromMap(snapshot.docs.first.data());
    });
  }

  Future<void> saveProfile(UserProfile profile) async {
    if (!_enabled || currentUser == null) return;
    await _userDoc.set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> saveJob(Job job) async {
    if (!_enabled || currentUser == null) return;
    await _userDoc.collection('savedJobs').doc(job.id).set(job.toMap());
  }

  Future<void> removeSavedJob(String jobId) async {
    if (!_enabled || currentUser == null) return;
    await _userDoc.collection('savedJobs').doc(jobId).delete();
  }

  Future<void> upsertApplication(ApplicationRecord record) async {
    if (!_enabled || currentUser == null) return;
    await _userDoc
        .collection('applications')
        .doc(record.id)
        .set(record.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteApplication(String recordId) async {
    if (!_enabled || currentUser == null) return;
    await _userDoc.collection('applications').doc(recordId).delete();
  }

  Future<void> saveResumeResult(ResumeResult result) async {
    if (!_enabled || currentUser == null) return;
    final id = result.generatedAt.millisecondsSinceEpoch.toString();
    await _userDoc.collection('resumeResults').doc(id).set(result.toMap());
  }

  Future<void> signOut() async {
    if (!_enabled) return;
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
    await FirebaseAuth.instance.signOut();
  }

  DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = currentUser?.uid;
    if (uid == null) {
      throw StateError('Firebase user is not signed in.');
    }
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  Stream<List<Job>> jobsStream() {
    if (!_enabled) {
      return Stream.value(const []);
    }

    return FirebaseFirestore.instance
        .collection('jobs')
        .where('active', isEqualTo: true)
        .orderBy('publishedAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Job.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  void _assertEnabled() {
    if (!_enabled) {
      throw StateError('Firebase is not configured.');
    }
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
    _googleInitialized = true;
  }
}
