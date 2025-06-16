// lib/screens/maintenance_screen.dart
// Owner Maintenance Screen – now with explicit back button on the AppBar.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late final String _ownerId = FirebaseAuth.instance.currentUser!.uid;
  String _filter = 'All';
  late final AnimationController _fadeAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  @override
  void dispose() {
    _fadeAnim.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _stream() {
    Query q = FirebaseFirestore.instance
        .collection('MaintenanceRequests')
        .where('ownerId', isEqualTo: _ownerId)
        .orderBy('createdAt', descending: true);
    if (_filter != 'All') q = q.where('status', isEqualTo: _filter);
    return q.snapshots();
  }

  Color _statusColor(String s) => switch (s) {
    'Open' => Colors.orange,
    'In-Progress' => Colors.blue,
    'Closed' => Colors.green,
    _ => Colors.grey,
  };

  Future<void> _showDetails(DocumentSnapshot doc) async {
    final d = doc.data() as Map<String, dynamic>;
    String status = d['status'] ?? 'Open';
    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Request details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText('Property ID: ${d['propertyId']}'),
                const SizedBox(height: 6),
                SelectableText('Tenant ID: ${d['tenantId']}'),
                const SizedBox(height: 12),
                Text(
                  d['description'] ?? '-',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Update status'),
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'Open', child: Text('Open')),
                    DropdownMenuItem(
                      value: 'In-Progress',
                      child: Text('In-Progress'),
                    ),
                    DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                  ],
                  onChanged: (v) => status = v ?? status,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22577A),
                ),
                onPressed: () async {
                  await doc.reference.update({'status': status});
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Open', 'In-Progress', 'Closed'];
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22577A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Maintenance Requests'),
      ),
      body: Stack(
        children: [
          const _Bubble(offset: Offset(-80, -90), color: Color(0xFF9ADBCD)),
          const _Bubble(offset: Offset(330, -60), color: Color(0xFFB7B5F5)),
          const _Bubble(offset: Offset(-60, 560), color: Color(0xFFFFD59E)),
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Wrap(
                    spacing: 8,
                    children:
                        filters
                            .map(
                              (f) => ChoiceChip(
                                label: Text(f),
                                selected: _filter == f,
                                onSelected: (_) => setState(() => _filter = f),
                              ),
                            )
                            .toList(),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _stream(),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return const Center(child: Text('No requests'));
                      }
                      return ListView.builder(
                        itemCount: snap.data!.docs.length,
                        itemBuilder: (ctx, i) {
                          final doc = snap.data!.docs[i];
                          final d = doc.data() as Map<String, dynamic>;
                          final status = d['status'] ?? 'Open';
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              onTap: () => _showDetails(doc),
                              leading: CircleAvatar(
                                backgroundColor: _statusColor(status),
                                radius: 6,
                              ),
                              title: Text(
                                d['description'] ?? '-',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Property: ${d['propertyId']} • $status',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
        color: color.withValues(alpha: .35),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 10)],
      ),
    ),
  );
}
