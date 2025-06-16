// lib/screens/tenants_screen.dart
// Modern UI revamp: blurred bubbles background, Poppins font, soft‑shadow cards,
// server‑side pagination, search & sort.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen>
    with SingleTickerProviderStateMixin {
  // ─── state
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nidaCtrl = TextEditingController();
  final _nokNameCtrl = TextEditingController();
  final _nokPhoneCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  // property dropdown
  List<DocumentSnapshot> _propertyDocs = [];
  String? _selectedPropertyId;

  // list / pagination helpers
  String _search = '';
  String _sort = 'nameAsc';
  final int _pageSize = 10;
  bool _hasMore = true, _loadingMore = false;
  DocumentSnapshot? _cursor;
  final List<DocumentSnapshot> _docs = [];

  late final String _ownerId = FirebaseAuth.instance.currentUser!.uid;
  late final AnimationController _fadeAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  @override
  void dispose() {
    _fadeAnim.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _nidaCtrl.dispose();
    _nokNameCtrl.dispose();
    _nokPhoneCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Firestore query
  Query _base() {
    Query q = FirebaseFirestore.instance
        .collection('Tenants')
        .where('ownerId', isEqualTo: _ownerId);
    switch (_sort) {
      case 'nameDesc':
        q = q.orderBy('fullName', descending: true);
        break;
      case 'createdDesc':
        q = q.orderBy('createdAt', descending: true);
        break;
      case 'createdAsc':
        q = q.orderBy('createdAt');
        break;
      default:
        q = q.orderBy('fullName');
    }
    return q;
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _docs.clear();
      _cursor = null;
      _hasMore = true;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    Query q = _base().limit(_pageSize);
    if (_cursor != null) q = q.startAfterDocument(_cursor!);
    final snap = await q.get();
    if (snap.docs.length < _pageSize) _hasMore = false;
    if (snap.docs.isNotEmpty) _cursor = snap.docs.last;
    setState(() {
      _docs.addAll(snap.docs);
      _loadingMore = false;
    });
  }

  // ─── utilities
  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _fetchOwnerProperties() async {
    final snap =
        await FirebaseFirestore.instance
            .collection('Properties')
            .where('ownerId', isEqualTo: _ownerId)
            .get();
    _propertyDocs = snap.docs;
  }

  // ─── create / edit dialogs (reuse)
  Future<void> _tenantDialog({DocumentSnapshot? doc}) async {
    final isEdit = doc != null;
    if (isEdit) {
      final d = doc.data() as Map<String, dynamic>;
      _nameCtrl.text = d['fullName'] ?? '';
      _phoneCtrl.text = d['phoneNumber'] ?? '';
      _nidaCtrl.text = d['nidanumber'] ?? '';
      _nokNameCtrl.text = d['nextOfKinName'] ?? '';
      _nokPhoneCtrl.text = d['nextOfKinPhoneNumber'] ?? '';
    } else {
      _formKey.currentState?.reset();
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _nidaCtrl.clear();
      _nokNameCtrl.clear();
      _nokPhoneCtrl.clear();
      _selectedPropertyId = null;
    }

    await _fetchOwnerProperties();
    if (_propertyDocs.isNotEmpty && _selectedPropertyId == null) {
      _selectedPropertyId = _propertyDocs.first.id;
    }

    await showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, dlgSet) => AlertDialog(
                  title: Text(isEdit ? 'Edit Tenant' : 'Add Tenant'),
                  content: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: _phoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          DropdownButtonFormField<String>(
                            value: _selectedPropertyId,
                            decoration: const InputDecoration(
                              labelText: 'Select Property',
                            ),
                            items:
                                _propertyDocs.map((p) {
                                  final d = p.data() as Map<String, dynamic>;
                                  return DropdownMenuItem(
                                    value: p.id,
                                    child: Text(d['address'] ?? 'Unnamed'),
                                  );
                                }).toList(),
                            onChanged:
                                (v) => dlgSet(() => _selectedPropertyId = v),
                            validator:
                                (v) => v == null ? 'Choose property' : null,
                          ),
                          TextFormField(
                            controller: _nidaCtrl,
                            decoration: const InputDecoration(
                              labelText: 'NIDA Number',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _nokNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Next‑of‑kin Name',
                            ),
                          ),
                          TextFormField(
                            controller: _nokPhoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Next‑of‑kin Phone',
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFB3640),
                      ),
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        try {
                          if (isEdit) {
                            await doc.reference.update({
                              'fullName': _nameCtrl.text.trim(),
                              'phoneNumber': _phoneCtrl.text.trim(),
                              'nidanumber': _nidaCtrl.text.trim(),
                              'propertyId': _selectedPropertyId,
                              'nextOfKinName': _nokNameCtrl.text.trim(),
                              'nextOfKinPhoneNumber': _nokPhoneCtrl.text.trim(),
                            });
                          } else {
                            await FirebaseFirestore.instance
                                .collection('Tenants')
                                .add({
                                  'ownerId': _ownerId,
                                  'fullName': _nameCtrl.text.trim(),
                                  'phoneNumber': _phoneCtrl.text.trim(),
                                  'nidanumber': _nidaCtrl.text.trim(),
                                  'propertyId': _selectedPropertyId,
                                  'nextOfKinName': _nokNameCtrl.text.trim(),
                                  'nextOfKinPhoneNumber':
                                      _nokPhoneCtrl.text.trim(),
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                          }
                          Navigator.pop(ctx);
                          _loadFirstPage();
                        } catch (_) {
                          _snack('Save failed');
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  // ─── delete
  Future<void> _deleteTenant(DocumentSnapshot doc) async {
    final d = doc.data() as Map;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Delete ${d['fullName']}?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (ok != true) return;
    try {
      await doc.reference.delete();
      if (d['profilePhotoUrl'] != null) {
        await FirebaseStorage.instance
            .refFromURL(d['profilePhotoUrl'])
            .delete();
      }
      _snack('Deleted');
      _loadFirstPage();
    } catch (_) {
      _snack('Delete failed');
    }
  }

  // ─── build bubbles + list
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22577A),
        title: const Text('Tenants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _tenantDialog(),
          ),
          PopupMenuButton<String>(
            onSelected:
                (v) => setState(() {
                  _sort = v;
                  _loadFirstPage();
                }),
            itemBuilder:
                (ctx) => const [
                  PopupMenuItem(value: 'nameAsc', child: Text('Name ↑')),
                  PopupMenuItem(value: 'nameDesc', child: Text('Name ↓')),
                  PopupMenuItem(value: 'createdDesc', child: Text('Newest')),
                  PopupMenuItem(value: 'createdAsc', child: Text('Oldest')),
                ],
          ),
        ],
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
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by name / phone / house',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => _loadFirstPage(),
                    child: ListView.builder(
                      itemCount:
                          _docs.where((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return d['fullName']
                                    .toString()
                                    .toLowerCase()
                                    .contains(_search) ||
                                d['phoneNumber']
                                    .toString()
                                    .toLowerCase()
                                    .contains(_search) ||
                                d['houseNumber']
                                    .toString()
                                    .toLowerCase()
                                    .contains(_search);
                          }).length +
                          1,
                      itemBuilder: (ctx, i) {
                        if (i == _docs.length) {
                          if (_hasMore) {
                            _loadMore();
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        }
                        final doc = _docs[i];
                        final d = doc.data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading:
                                d['profilePhotoUrl'] != null
                                    ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        d['profilePhotoUrl'],
                                      ),
                                    )
                                    : const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                            title: Text(
                              d['fullName'] ?? '-',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${d['phoneNumber']} • House: ${d['houseNumber']}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _tenantDialog(doc: doc),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteTenant(doc),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
