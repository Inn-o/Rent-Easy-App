// lib/screens/maintenance_screen.dart
import 'package:flutter/material.dart';

class MaintenanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F7F2),
      appBar: AppBar(
        title: Text('Maintenance Requests'),
        backgroundColor: Color(0xFF22577A),
      ),
      body: Center(
        child: Text(
          'Maintenance requests will be handled here.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
