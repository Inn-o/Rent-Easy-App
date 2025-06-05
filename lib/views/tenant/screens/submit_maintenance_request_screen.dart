// lib/screens/submit_maintenance_request_screen.dart
import 'package:flutter/material.dart';

class SubmitMaintenanceRequestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F7F2),
      appBar: AppBar(
        title: Text('Submit Maintenance Request'),
        backgroundColor: Color(0xFF22577A),
      ),
      body: Center(child: Text('Maintenance request form will go here.')),
    );
  }
}
