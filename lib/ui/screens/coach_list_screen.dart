import 'package:flutter/material.dart';

class CoachListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> coaches = [
    {
      'name': 'محمد رضایی',
      'experience': '۵ سال سابقه',
      'clients': 120,
      'achievements': 10,
      'image': 'https://via.placeholder.com/150',
    },
    {
      'name': 'علی کریمی',
      'experience': '۷ سال سابقه',
      'clients': 200,
      'achievements': 15,
      'image': 'https://via.placeholder.com/150',
    },
    {
      'name': 'زهرا احمدی',
      'experience': '۳ سال سابقه',
      'clients': 90,
      'achievements': 5,
      'image': 'https://via.placeholder.com/150',
    },
  ];

  CoachListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('لیست مربیان'), centerTitle: true),
      body: ListView.builder(
        itemCount: coaches.length,
        itemBuilder: (context, index) {
          final coach = coaches[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(coach['image']),
              ),
              title: Text(
                coach['name'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${coach['experience']} | ${coach['clients']} شاگرد | ${coach['achievements']} مقام',
              ),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CoachDetailScreen(coach: coach),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class CoachDetailScreen extends StatelessWidget {
  final Map<String, dynamic> coach;

  const CoachDetailScreen({super.key, required this.coach});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(coach['name'])),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(coach['image']),
            ),
            SizedBox(height: 16),
            Text(
              coach['name'],
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(coach['experience'], style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text(
              '${coach['clients']} شاگرد | ${coach['achievements']} مقام',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: () {}, child: Text('درخواست مشاوره')),
          ],
        ),
      ),
    );
  }
}
