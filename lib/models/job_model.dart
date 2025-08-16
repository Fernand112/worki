import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String title;
  final String description;
  final double budget;
  final List<String> skills;
  final String authorId;
  final DateTime? createdAt;
  final String? authorName;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.budget,
    required this.skills,
    required this.authorId,
    this.createdAt,
    this.authorName,
  });

  factory Job.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Job(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      budget: (data['budget'] ?? 0.0).toDouble(),
      skills: List<String>.from(data['skills'] ?? []),
      authorId: data['authorId'] ?? '',
      createdAt: (data['timestamp'] as Timestamp?)?.toDate(),
      authorName: data['authorName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'budget': budget,
      'skills': skills,
      'authorId': authorId,
      'timestamp': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'authorName': authorName,
    };
  }
}

class JobApplication {
  final String id;
  final String jobId;
  final String applicantId;
  final String applicantName;
  final double offerAmount;
  final String coverLetter;
  final DateTime? appliedAt;
  final String status; // 'pending', 'accepted', 'rejected'

  JobApplication({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.applicantName,
    required this.offerAmount,
    required this.coverLetter,
    this.appliedAt,
    this.status = 'pending',
  });

  factory JobApplication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobApplication(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      applicantId: data['applicantId'] ?? '',
      applicantName: data['applicantName'] ?? '',
      offerAmount: (data['offerAmount'] ?? 0.0).toDouble(),
      coverLetter: data['coverLetter'] ?? '',
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'offerAmount': offerAmount,
      'coverLetter': coverLetter,
      'appliedAt': appliedAt != null ? Timestamp.fromDate(appliedAt!) : FieldValue.serverTimestamp(),
      'status': status,
    };
  }
}
