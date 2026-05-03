import 'job.dart';

enum ApplicationStatus {
  interested,
  applied,
  interviewing,
  offer,
  rejected,
}

extension ApplicationStatusLabel on ApplicationStatus {
  String get label {
    switch (this) {
      case ApplicationStatus.interested:
        return 'Interested';
      case ApplicationStatus.applied:
        return 'Applied';
      case ApplicationStatus.interviewing:
        return 'Interviewing';
      case ApplicationStatus.offer:
        return 'Offer';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  static ApplicationStatus fromName(String? value) {
    return ApplicationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ApplicationStatus.interested,
    );
  }
}

class ApplicationRecord {
  const ApplicationRecord({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.jobUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
  });

  final String id;
  final String jobId;
  final String jobTitle;
  final String company;
  final String jobUrl;
  final ApplicationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String notes;

  factory ApplicationRecord.fromJob(Job job) {
    final now = DateTime.now();
    return ApplicationRecord(
      id: job.id,
      jobId: job.id,
      jobTitle: job.title,
      company: job.company,
      jobUrl: job.url,
      status: ApplicationStatus.interested,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory ApplicationRecord.fromMap(Map<String, dynamic> map) {
    return ApplicationRecord(
      id: map['id']?.toString() ?? '',
      jobId: map['jobId']?.toString() ?? '',
      jobTitle: map['jobTitle']?.toString() ?? 'Untitled role',
      company: map['company']?.toString() ?? 'Unknown company',
      jobUrl: map['jobUrl']?.toString() ?? '',
      status: ApplicationStatusLabel.fromName(map['status']?.toString()),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      notes: map['notes']?.toString() ?? '',
    );
  }

  ApplicationRecord copyWith({
    ApplicationStatus? status,
    String? notes,
    DateTime? updatedAt,
  }) {
    return ApplicationRecord(
      id: id,
      jobId: jobId,
      jobTitle: jobTitle,
      company: company,
      jobUrl: jobUrl,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'company': company,
      'jobUrl': jobUrl,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notes': notes,
    };
  }
}
