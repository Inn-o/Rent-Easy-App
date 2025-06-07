// lib/screens/owner_dashboard.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rent_easy/views/owner/screens/maintenance_screen.dart';
import 'package:rent_easy/views/owner/screens/properties_screen.dart';
import 'package:rent_easy/views/owner/screens/rent_tracking_screen.dart';
import 'package:rent_easy/views/owner/screens/tenants_screen.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<_DashItem> items = [
      _DashItem(
        title: 'My Properties',
        icon: FontAwesomeIcons.building,
        color: Colors.teal[300]!,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PropertiesScreen()),
            ),
      ),
      _DashItem(
        title: 'Tenants',
        icon: FontAwesomeIcons.users,
        color: Colors.indigo[400]!,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TenantsScreen()),
            ),
      ),
      _DashItem(
        title: 'Rent Tracking',
        icon: FontAwesomeIcons.coins,
        color: Colors.orange[400]!,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RentTrackingScreen()),
            ),
      ),
      _DashItem(
        title: 'Maintenance',
        icon: FontAwesomeIcons.toolbox,
        color: Colors.red[300]!,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MaintenanceScreen()),
            ),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F2),
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        backgroundColor: const Color(0xFF22577A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _DashboardCard(item: item);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFB3640),
        child: const Icon(Icons.logout),
        onPressed: () {
          // TODO: implement sign-out (FirebaseAuth.instance.signOut(), etc.)
        },
      ),
    );
  }
}

/// --- Helper classes / widgets ------------------------------------------------

class _DashItem {
  _DashItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.item});

  final _DashItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(item.icon, size: 40, color: item.color),
            const SizedBox(height: 12),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: item.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
