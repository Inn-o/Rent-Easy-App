// lib/screens/owner_dashboard.dart
import 'package:flutter/material.dart';
import 'package:rent_easy/views/owner/screens/maintenance_screen.dart';
import 'package:rent_easy/views/owner/screens/rent_tracking_screen.dart';
import 'screens/properties_screen.dart';
import 'screens/tenants_screen.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F7F2),
      appBar: AppBar(
        title: Text('Owner Dashboard'),
        backgroundColor: Color(0xFF22577A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFB3640),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PropertiesScreen()),
                );
              },
              child: Text('Manage Properties'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFB3640),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TenantsScreen()),
                );
              },
              child: Text('Manage Tenants'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFB3640),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RentTrackingScreen()),
                );
              },
              child: Text('Track Rent'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFB3640),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MaintenanceScreen()),
                );
              },
              child: Text('Maintenance Requests'),
            ),
          ],
        ),
      ),
    );
  }
}
