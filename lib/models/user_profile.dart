class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.resumeText,
    required this.darkMode,
    required this.jobAlerts,
    required this.applicationUpdates,
    required this.preferredLocation,
    required this.salaryExpectation,
  });

  final String name;
  final String email;
  final String resumeText;
  final bool darkMode;
  final bool jobAlerts;
  final bool applicationUpdates;
  final String preferredLocation;
  final String salaryExpectation;

  factory UserProfile.empty() {
    return const UserProfile(
      name: '',
      email: '',
      resumeText: '',
      darkMode: false,
      jobAlerts: true,
      applicationUpdates: true,
      preferredLocation: 'Anywhere',
      salaryExpectation: '\$100K+',
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      resumeText: map['resumeText']?.toString() ?? '',
      darkMode: map['darkMode'] == true,
      jobAlerts: map['jobAlerts'] != false,
      applicationUpdates: map['applicationUpdates'] != false,
      preferredLocation: map['preferredLocation']?.toString() ?? 'Anywhere',
      salaryExpectation: map['salaryExpectation']?.toString() ?? '\$100K+',
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? resumeText,
    bool? darkMode,
    bool? jobAlerts,
    bool? applicationUpdates,
    String? preferredLocation,
    String? salaryExpectation,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      resumeText: resumeText ?? this.resumeText,
      darkMode: darkMode ?? this.darkMode,
      jobAlerts: jobAlerts ?? this.jobAlerts,
      applicationUpdates: applicationUpdates ?? this.applicationUpdates,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      salaryExpectation: salaryExpectation ?? this.salaryExpectation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'resumeText': resumeText,
      'darkMode': darkMode,
      'jobAlerts': jobAlerts,
      'applicationUpdates': applicationUpdates,
      'preferredLocation': preferredLocation,
      'salaryExpectation': salaryExpectation,
    };
  }
}
