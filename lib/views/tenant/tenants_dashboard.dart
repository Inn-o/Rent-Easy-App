// lib/screens/tenant_dashboard.dart
import 'package:flutter/material.dart';
import 'package:rent_easy/views/tenant/screens/profile_screen.dart';
import 'package:rent_easy/views/tenant/screens/rent_payment_screen.dart';
import 'package:rent_easy/views/tenant/screens/submit_maintenance_request_screen.dart';

class TenantDashboard extends StatelessWidget {
  const TenantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F7F2),
      appBar: AppBar(
        title: Text('Tenant Dashboard'),
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
                  MaterialPageRoute(builder: (context) => RentPaymentScreen()),
                );
              },
              child: Text('Pay Rent'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFB3640),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubmitMaintenanceRequestScreen(),
                  ),
                );
              },
              child: Text('Submit Maintenance Request'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFB3640),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              child: Text('Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
