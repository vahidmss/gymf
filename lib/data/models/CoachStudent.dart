class CoachStudent {
  final String id;
  final String coachId;
  final String studentId;
  final String status;
  final DateTime createdAt;

  CoachStudent({
    required this.id,
    required this.coachId,
    required this.studentId,
    required this.status,
    required this.createdAt,
  });

  factory CoachStudent.fromJson(Map<String, dynamic> json) {
    return CoachStudent(
      id: json['id'],
      coachId: json['coach_id'],
      studentId: json['student_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coach_id': coachId,
      'student_id': studentId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
