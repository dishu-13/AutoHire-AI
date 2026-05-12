import 'package:flutter_test/flutter_test.dart';
import 'package:smart_job_assistant/models/application_record.dart';
import 'package:smart_job_assistant/models/job.dart';
import 'package:smart_job_assistant/models/resume_document.dart';
import 'package:smart_job_assistant/services/ai_resume_service.dart';

void main() {
  test('job map round trip preserves primary fields', () {
    final job = Job(
      id: '1',
      title: 'Flutter Engineer',
      company: 'Acme',
      location: 'Remote',
      url: 'https://example.com',
      description: 'Build apps',
      category: 'Software',
      publishedAt: DateTime.utc(2026),
      salary: '\$100k - \$120k',
      salaryMin: 100000,
      salaryMax: 120000,
    );

    final copy = Job.fromMap(job.toMap());

    expect(copy.id, job.id);
    expect(copy.title, job.title);
    expect(copy.salaryLabel, '\$100k - \$120k');
    expect(copy.source, 'Live portal');
    expect(copy.postedLabel, isNotEmpty);
  });

  test('job flags India-friendly and fast-hiring listings', () {
    final job = Job(
      id: 'india-fast',
      title: 'Urgent Flutter Developer',
      company: 'Client Team',
      location: 'Remote - India',
      url: 'https://example.com',
      description: 'Immediate contract hiring with quick screening call.',
      category: 'Software',
      publishedAt: DateTime.now(),
      salary: 'INR 12L - 18L',
    );

    expect(job.isIndiaFriendly, isTrue);
    expect(job.hasFastHiringSignal, isTrue);
  });

  test('application status label maps from stored enum name', () {
    final status = ApplicationStatusLabel.fromName('interviewing');

    expect(status, ApplicationStatus.interviewing);
    expect(status.label, 'Interviewing');
  });

  test('local resume tailoring returns ATS result', () async {
    const service = AiResumeService();

    final result = await service.tailorResume(
      resumeText:
          'Summary\nFlutter developer with Firebase skills and mobile app experience. Improved load time by 25%.',
      targetJobDescription:
          'We need a Flutter engineer with Firebase, REST API, analytics, and Android experience.',
      templateStyle: 'Modern ATS',
    );

    expect(result.atsScore, inInclusiveRange(35, 96));
    expect(result.keywords, isNotEmpty);
    expect(result.optimizedResume, contains('TARGET ROLE ALIGNMENT'));
    expect(result.coverLetter, contains('Dear Hiring Team'));
  });

  test('resume document builds structured plain text', () {
    const document = ResumeDocument(
      name: 'Dishu',
      headline: 'Flutter Developer',
      email: 'dishu@example.com',
      phone: '+91 99999 99999',
      location: 'India',
      links: ['github.com/dishu'],
      summary: 'Flutter developer building Firebase-backed Android apps.',
      skills: ['Flutter', 'Firebase', 'Dart'],
      experiences: [
        ResumeExperience(
          role: 'Developer',
          company: 'AutoHire AI',
          period: '2026',
          location: 'Remote',
          bullets: ['Built resume PDF export with templates.'],
        ),
      ],
      projects: [],
      education: [],
      certifications: ['Flutter development'],
    );

    final text = document.toPlainText();

    expect(document.hasContent, isTrue);
    expect(document.wordCount, greaterThan(10));
    expect(text, contains('SUMMARY'));
    expect(text, contains('EXPERIENCE'));
    expect(text, contains('Built resume PDF export'));
  });
}
