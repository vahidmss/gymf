class Comment {
  final String userName;
  final String text;
  final int rating; // امتیاز از 1 تا 5
  final DateTime timestamp;
  int likes; // تعداد لایک‌ها

  Comment({
    required this.userName,
    required this.text,
    required this.rating,
    required this.timestamp,
    this.likes = 0,
  });
}
