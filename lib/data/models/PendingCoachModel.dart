class PendingCoachModel {
  final String id;
  final String userId;
  final String username;
  final List<String> certifications;
  final List<String> achievements;
  final int experienceYears;
  final String identityDocumentUrl;
  final String certificatesUrl;
  final String status;
  final DateTime createdAt;

  PendingCoachModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.certifications,
    required this.achievements,
    required this.experienceYears,
    required this.identityDocumentUrl,
    required this.certificatesUrl,
    required this.status,
    required this.createdAt,
  });

  factory PendingCoachModel.fromJson(Map<String, dynamic> json) {
    return PendingCoachModel(
      id: json['id'],
      userId: json['user_id'],
      username: json['user_id']['username'] ?? 'نامشخص',
      certifications: List<String>.from(json['certifications'] ?? []),
      achievements: List<String>.from(json['achievements'] ?? []),
      experienceYears: json['experience_years'] ?? 0,
      identityDocumentUrl: json['identity_document_url'] ?? '',
      certificatesUrl: json['certificates_url'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
