import 'package:flutter/material.dart';
import '../../auth/screens/face_test_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FaceTestScreen()),
            );
          },
          child: Text('Test Face Detection'),
        ),
      ),
    );
  }
}