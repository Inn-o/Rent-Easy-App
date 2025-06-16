// lib/screens/owner_dashboard.dart
// Modern UI: blurred gradient bubbles, cards with soft shadows, and quick links.
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_easy/views/owner/screens/maintenance_screen.dart';
import 'package:rent_easy/views/owner/screens/properties_screen.dart';
import 'package:rent_easy/views/owner/screens/rent_tracking_screen.dart';
import 'package:rent_easy/views/owner/screens/tenants_screen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  @override
  void dispose() {
    _fadeAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = <_DashItem>[
      _DashItem(
        title: 'Properties',
        icon: FontAwesomeIcons.building,
        color: Colors.indigo[400]!,
        next: const PropertiesScreen(),
      ),
      _DashItem(
        title: 'Tenants',
        icon: FontAwesomeIcons.users,
        color: Colors.teal[400]!,
        next: const TenantsScreen(),
      ),
      _DashItem(
        title: 'Rent Tracking',
        icon: FontAwesomeIcons.coins,
        color: Colors.orange[400]!,
        next: const RentTrackingScreen(),
      ),
      _DashItem(
        title: 'Maintenance',
        icon: FontAwesomeIcons.screwdriverWrench,
        color: Colors.redAccent[200]!,
        next: const MaintenanceScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22577A),
        title: const Text('Owner Dashboard'),
      ),
      body: Stack(
        children: [
          const _Bubble(offset: Offset(-80, -100), color: Color(0xFF9ADBCD)),
          const _Bubble(offset: Offset(320, -60), color: Color(0xFFB7B5F5)),
          const _Bubble(offset: Offset(-60, 540), color: Color(0xFFFFD59E)),
          FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children:
                    items
                        .map(
                          (e) => _DashboardCard(
                            item: e,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => e.next,
                                    fullscreenDialog: false,
                                  ),
                                ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFB3640),
        child: const Icon(Icons.logout),
        onPressed: () {
          // TODO: implement logout via FirebaseAuth.instance.signOut()
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.item, required this.onTap});

  final _DashItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: item.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashItem {
  _DashItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.next,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget next;
}

/// Decorative blurred circle (same style as login/register)
class _Bubble extends StatelessWidget {
  const _Bubble({required this.offset, required this.color});
  final Offset offset;
  final Color color;

  @override
  Widget build(BuildContext context) => Positioned(
    left: offset.dx,
    top: offset.dy,
    child: Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .35),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 10)],
      ),
    ),
  );
}
