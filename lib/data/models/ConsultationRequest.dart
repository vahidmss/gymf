class ConsultationRequest {
  final String id;
  final String coachId;
  final String studentId;
  final String type;
  final String status;
  final DateTime createdAt;
  final String? message;

  ConsultationRequest({
    required this.id,
    required this.coachId,
    required this.studentId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.message,
  });

  factory ConsultationRequest.fromJson(Map<String, dynamic> json) {
    return ConsultationRequest(
      id: json['id'],
      coachId: json['coach_id'],
      studentId: json['student_id'],
      type: json['type'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coach_id': coachId,
      'student_id': studentId,
      'type': type,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'message': message,
    };
  }
}
