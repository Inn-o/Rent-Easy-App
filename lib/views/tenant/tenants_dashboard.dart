// lib/screens/tenant_dashboard.dart
// Modern tenant home – matching look-&-feel of owner dashboard.
// Shows: welcome message, current property, next rent due, quick action cards.
// Requires:
//   • `/Users/{uid}` doc contains `propertyId`
//   • `/Properties/{propertyId}` has `address`, `rentAmount`, `ownerId`
//   • `/Payments` docs filterable by tenantId & status
// Replace stub screens with real ones when implemented.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({Key? key}) : super(key: key);

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard>
    with SingleTickerProviderStateMixin {
  late final String _uid = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>? _prop;
  Map<String, dynamic>? _nextPayment;
  bool _loading = true;

  late final AnimationController _fadeAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // fetch tenant profile to get propertyId
      final uSnap =
          await FirebaseFirestore.instance.collection('Users').doc(_uid).get();
      final propId = uSnap.data()?['propertyId'];
      if (propId != null) {
        final pSnap =
            await FirebaseFirestore.instance
                .collection('Properties')
                .doc(propId)
                .get();
        _prop = pSnap.data();
        // fetch next unpaid payment
        final paySnap =
            await FirebaseFirestore.instance
                .collection('Payments')
                .where('tenantId', isEqualTo: _uid)
                .where('status', isEqualTo: 'Pending')
                .orderBy('date')
                .limit(1)
                .get();
        if (paySnap.docs.isNotEmpty) _nextPayment = paySnap.docs.first.data();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _fadeAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22577A),
        title: const Text('Tenant Dashboard'),
      ),
      body: Stack(
        children: [
          const _Bubble(offset: Offset(-80, -90), color: Color(0xFF9ADBCD)),
          const _Bubble(offset: Offset(330, -60), color: Color(0xFFB7B5F5)),
          const _Bubble(offset: Offset(-60, 560), color: Color(0xFFFFD59E)),
          FadeTransition(
            opacity: _fadeAnim,
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: GoogleFonts.poppins(fontSize: 18),
                          ),
                          Text(
                            FirebaseAuth.instance.currentUser!.email ?? '-',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF22577A),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_prop != null) _propertyCard(),
                          const SizedBox(height: 20),
                          _quickLinks(context),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _propertyCard() {
    final addr = _prop!['address'] ?? 'N/A';
    final rent = _prop!['rentAmount']?.toString() ?? '-';
    String nextDue = 'No pending';
    if (_nextPayment != null) {
      final dt = (_nextPayment!['date'] as Timestamp).toDate();
      nextDue = DateFormat.yMMMd().format(dt);
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Property',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(addr),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monthly Rent'),
                    Text(
                      'TZS $rent',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Next Due'),
                    Text(
                      nextDue,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickLinks(BuildContext context) {
    final items = [
      _DashItem('Pay Rent', FontAwesomeIcons.wallet, Colors.orange.shade400),
      _DashItem(
        'Maintenance',
        FontAwesomeIcons.screwdriverWrench,
        Colors.redAccent.shade200,
      ),
      _DashItem('Profile', FontAwesomeIcons.user, Colors.teal.shade400),
    ];
    return GridView.count(
      crossAxisCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: items.map((e) => _QuickCard(item: e)).toList(),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.item});
  final _DashItem item;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        /* TODO: navigate to feature */
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(item.icon, color: item.color, size: 30),
            const SizedBox(height: 8),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashItem {
  _DashItem(this.title, this.icon, this.color);
  final String title;
  final IconData icon;
  final Color color;
}

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
        color: color.withOpacity(.35),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 10)],
      ),
    ),
  );
}
