import 'package:flutter/material.dart';
import '../../auth/screens/face_registration_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FaceRegistrationScreen()),
                );
              },
              child: Text('Register Face for Payments'),
            ),
          ],
        ),
      ),
    );
  }
}