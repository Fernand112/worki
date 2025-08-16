import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String lastName;
  final String email;
  final String? bio;
  final String? profileImageUrl;
  final List<String> skills;
  final DateTime? createdAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.lastName,
    required this.email,
    this.bio,
    this.profileImageUrl,
    this.skills = const [],
    this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
      skills: List<String>.from(data['skills'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lastName': lastName,
      'email': email,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'skills': skills,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  String get fullName => '$name $lastName'.trim();
  String get displayName => fullName.isNotEmpty ? fullName : 'Usuario';
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'application', 'job_update', etc.
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? '',
      data: data['data'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
