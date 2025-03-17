class CoachReview {
  final String id;
  final String coachId;
  final String studentId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  CoachReview({
    required this.id,
    required this.coachId,
    required this.studentId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory CoachReview.fromJson(Map<String, dynamic> json) {
    return CoachReview(
      id: json['id'],
      coachId: json['coach_id'],
      studentId: json['student_id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coach_id': coachId,
      'student_id': studentId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
