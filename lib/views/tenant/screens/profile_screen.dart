import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F7F2),
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Color(0xFF22577A),
      ),
      body: Center(child: Text('User profile details will go here.')),
    );
  }
}
