// lib/screens/rent_tracking_screen.dart
import 'package:flutter/material.dart';

class RentTrackingScreen extends StatelessWidget {
  const RentTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F7F2),
      appBar: AppBar(
        title: Text('Rent Tracking'),
        backgroundColor: Color(0xFF22577A),
      ),
      body: Center(
        child: Text(
          'Rent tracking features will be shown here.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
