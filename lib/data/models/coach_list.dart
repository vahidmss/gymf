class Coach {
  final String id;
  final String name;
  final String imageUrl;
  final int experienceYears;
  final int trainees;
  final int achievements;

  Coach({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.experienceYears,
    required this.trainees,
    required this.achievements,
  });

  factory Coach.fromMap(Map<String, dynamic> data) {
    return Coach(
      id: data['id'] ?? '',
      name: data['name'] ?? 'بدون نام',
      imageUrl: data['imageUrl'] ?? '',
      experienceYears: data['experienceYears'] ?? 0,
      trainees: data['trainees'] ?? 0,
      achievements: data['achievements'] ?? 0,
    );
  }
}
