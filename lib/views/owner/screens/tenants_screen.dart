// lib/screens/owner/tenants_screen.dart
import 'package:flutter/material.dart';

class TenantsScreen extends StatelessWidget {
  const TenantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F7F2),
      appBar: AppBar(
        title: Text('Tenants'),
        backgroundColor: Color(0xFF22577A),
      ),
      body: Center(
        child: Text(
          'List of Tenants will be shown here.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
