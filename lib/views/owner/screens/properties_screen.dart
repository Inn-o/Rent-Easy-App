// lib/screens/properties_screen.dart
// Full-featured: image upload, tenant assignment, filters, sorting, pagination
// Colors: #F8F7F2 background, #22577A primary, #FB3640 FAB

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  // ─── Form controllers ────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _roomsCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  // ─── Filters & UI state ──────────────────────────────────────────────────
  String _search = '';
  double? _minRent, _maxRent;
  String _sort = 'none';
  int _page = 0;
  final int _perPage = 6;

  // ─── Image picker ────────────────────────────────────────────────────────
  final _picker = ImagePicker();
  File? _pickedImg;

  String get _ownerId => FirebaseAuth.instance.currentUser!.uid;

  // ─────────────────────────────────────────────────────────────────────────
  // Fetch tenants for dropdown
  Future<List<DocumentSnapshot>> _fetchTenants() async {
    final snap =
        await FirebaseFirestore.instance
            .collection('Users')
            .where('role', isEqualTo: 'tenant')
            //.where('userId', isNotEqualTo: _ownerId)
            .where('ownerId', isEqualTo: _ownerId)
            .where('propertyId', isNull: true)
            .get();
    return snap.docs;
  }

  // ─── Add property flow ───────────────────────────────────────────────────
  Future<void> _addProperty() async {
    if (!_formKey.currentState!.validate()) return;

    String? url;
    if (_pickedImg != null) {
      final ref = FirebaseStorage.instance.ref(
        'property_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(_pickedImg!);
      url = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('Properties').add({
      'ownerId': _ownerId,
      'address': _addressCtrl.text.trim(),
      'rentAmount': double.parse(_rentCtrl.text.trim()),
      'rooms': int.parse(_roomsCtrl.text.trim()),
      'description': _descCtrl.text.trim(),
      'occupancyStatus': 'vacant',
      'tenantId': null,
      'imageUrl': url,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
    _addressCtrl.clear();
    _rentCtrl.clear();
    _roomsCtrl.clear();
    _descCtrl.clear();
    setState(() => _pickedImg = null);
  }

  // ─── Edit property dialog ────────────────────────────────────────────────
  Future<void> _editProperty(String id, Map<String, dynamic> data) async {
    final addr = TextEditingController(text: data['address']);
    final rent = TextEditingController(text: data['rentAmount'].toString());
    final rooms = TextEditingController(text: data['rooms'].toString());
    final desc = TextEditingController(text: data['description'] ?? '');
    String status = data['occupancyStatus'] ?? 'vacant';
    String assignedTenant = data['tenantId'] ?? '';
    String? oldUrl = data['imageUrl'];
    File? newImg;

    final tenants = await _fetchTenants();

    await showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDlg) => AlertDialog(
                  title: const Text('Edit Property'),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: addr,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                          ),
                        ),
                        TextField(
                          controller: rent,
                          decoration: const InputDecoration(labelText: 'Rent'),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: rooms,
                          decoration: const InputDecoration(labelText: 'Rooms'),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: desc,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (oldUrl != null && newImg == null)
                          Image.network(oldUrl, height: 80),
                        if (newImg != null) Image.file(newImg!, height: 80),
                        TextButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text('Change Photo'),
                          onPressed: () async {
                            final p = await _picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 75,
                            );
                            if (p != null) setDlg(() => newImg = File(p.path));
                          },
                        ),
                        DropdownButtonFormField<String>(
                          value: status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items:
                              ['vacant', 'occupied']
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setDlg(() => status = v ?? 'vacant'),
                        ),
                        if (status == 'occupied')
                          DropdownButtonFormField<String>(
                            value:
                                assignedTenant.isNotEmpty
                                    ? assignedTenant
                                    : null,
                            decoration: const InputDecoration(
                              labelText: 'Assign Tenant',
                            ),
                            items:
                                tenants.map((t) {
                                  final d = t.data() as Map<String, dynamic>;
                                  return DropdownMenuItem(
                                    value: t.id,
                                    child: Text(d['fullName'] ?? 'Unnamed'),
                                  );
                                }).toList(),
                            onChanged:
                                (v) => setDlg(() => assignedTenant = v ?? ''),
                          ),
                      ],
                    ),
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
                        String? url = oldUrl;
                        if (newImg != null) {
                          final ref = FirebaseStorage.instance.ref(
                            'property_images/${id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                          );
                          await ref.putFile(newImg!);
                          url = await ref.getDownloadURL();
                          if (oldUrl != null) {
                            await FirebaseStorage.instance
                                .refFromURL(oldUrl)
                                .delete();
                          }
                        }
                        await FirebaseFirestore.instance
                            .collection('Properties')
                            .doc(id)
                            .update({
                              'address': addr.text.trim(),
                              'rentAmount':
                                  double.tryParse(rent.text.trim()) ?? 0,
                              'rooms': int.tryParse(rooms.text.trim()) ?? 0,
                              'description': desc.text.trim(),
                              'occupancyStatus': status,
                              'tenantId':
                                  status == 'occupied' ? assignedTenant : null,
                              'imageUrl': url,
                            });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  // ─── Filtering & sorting helpers ─────────────────────────────────────────
  List<DocumentSnapshot> _applyFilters(List<DocumentSnapshot> docs) {
    var list =
        docs.where((d) {
          final m = d.data() as Map<String, dynamic>;
          final addr = (m['address'] ?? '').toString().toLowerCase();
          final rent = m['rentAmount'] ?? 0.0;
          return addr.contains(_search) &&
              (_minRent == null || rent >= _minRent!) &&
              (_maxRent == null || rent <= _maxRent!);
        }).toList();

    switch (_sort) {
      case 'rentAsc':
        list.sort(
          (a, b) => (a.data() as Map)['rentAmount'].compareTo(
            (b.data() as Map)['rentAmount'],
          ),
        );
        break;
      case 'rentDesc':
        list.sort(
          (a, b) => (b.data() as Map)['rentAmount'].compareTo(
            (a.data() as Map)['rentAmount'],
          ),
        );
        break;
      case 'dateAsc':
        list.sort((a, b) {
          final Timestamp? tA =
              (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final Timestamp? tB =
              (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (tA == null && tB == null) return 0;
          if (tA == null) return -1; // nulls first
          if (tB == null) return 1;
          return tA.compareTo(tB); // ascending
        });
        break;

      case 'dateDesc':
        list.sort((a, b) {
          final Timestamp? tA =
              (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final Timestamp? tB =
              (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (tA == null && tB == null) return 0;
          if (tA == null) return 1; // nulls last
          if (tB == null) return -1;
          return tB.compareTo(tA); // descending
        });
        break;
    }
    return list;
  }

  // ─── Dialogs: add & filters ──────────────────────────────────────────────
  void _showAddDialog() {
    _pickedImg = null;
    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDlg) => AlertDialog(
                  title: const Text('Add Property'),
                  content: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _addressCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: _rentCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Rent Amount',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: _roomsCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Rooms',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: _descCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_pickedImg != null)
                            Image.file(_pickedImg!, height: 80),
                          TextButton.icon(
                            icon: const Icon(Icons.image),
                            label: const Text('Pick Photo'),
                            onPressed: () async {
                              final p = await _picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 75,
                              );
                              if (p != null) {
                                setDlg(() => _pickedImg = File(p.path));
                              }
                            },
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
                        backgroundColor: const Color(0xFF22577A),
                      ),
                      onPressed: _addProperty,
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showFilterDialog() {
    final minCtrl = TextEditingController(text: _minRent?.toString() ?? '');
    final maxCtrl = TextEditingController(text: _maxRent?.toString() ?? '');
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Filters & Sorting'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: minCtrl,
                  decoration: const InputDecoration(labelText: 'Min Rent'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: maxCtrl,
                  decoration: const InputDecoration(labelText: 'Max Rent'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: _sort,
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('None')),
                    DropdownMenuItem(value: 'rentAsc', child: Text('Rent ↑')),
                    DropdownMenuItem(value: 'rentDesc', child: Text('Rent ↓')),
                    DropdownMenuItem(value: 'dateDesc', child: Text('Newest')),
                    DropdownMenuItem(value: 'dateAsc', child: Text('Oldest')),
                  ],
                  onChanged: (v) => setState(() => _sort = v ?? 'none'),
                  decoration: const InputDecoration(labelText: 'Sort By'),
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
                onPressed: () {
                  setState(() {
                    _minRent = double.tryParse(minCtrl.text);
                    _maxRent = double.tryParse(maxCtrl.text);
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
    );
  }

  // ─── Delete confirmation ────────────────────────────────────────────────
  void _confirmDelete(String id, String? imgUrl) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Property'),
            content: const Text('Are you sure?'),
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
                  await FirebaseFirestore.instance
                      .collection('Properties')
                      .doc(id)
                      .delete();
                  if (imgUrl != null) {
                    await FirebaseStorage.instance.refFromURL(imgUrl).delete();
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22577A),
        title: const Text('My Properties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(FontAwesomeIcons.building),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search address...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged:
                  (v) => setState(() {
                    _search = v.toLowerCase();
                    _page = 0; // reset page on new search
                  }),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('Properties')
                      .where('ownerId', isEqualTo: _ownerId)
                      .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No properties'));
                }

                final list = _applyFilters(snap.data!.docs);
                final start = _page * _perPage;
                final end = (start + _perPage).clamp(0, list.length);
                final pageDocs = list.sublist(start, end);

                final grouped = <String, List<DocumentSnapshot>>{
                  'vacant':
                      pageDocs
                          .where(
                            (d) =>
                                (d.data() as Map)['occupancyStatus'] ==
                                'vacant',
                          )
                          .toList(),
                  'occupied':
                      pageDocs
                          .where(
                            (d) =>
                                (d.data() as Map)['occupancyStatus'] ==
                                'occupied',
                          )
                          .toList(),
                };

                final totalRent = list.fold<double>(
                  0,
                  (s, d) => s + ((d.data() as Map)['rentAmount'] ?? 0.0),
                );

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Total: ${list.length} • Rent: TZS ${totalRent.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children:
                            grouped.entries
                                .expand(
                                  (e) => [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Center(
                                        child: Text(
                                          e.key.toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    ...e.value.map((doc) {
                                      final m =
                                          doc.data() as Map<String, dynamic>;
                                      return Card(
                                        color:
                                            e.key == 'vacant'
                                                ? Colors.green[50]
                                                : Colors.red[50],
                                        child: ListTile(
                                          leading:
                                              m['imageUrl'] != null
                                                  ? Image.network(
                                                    m['imageUrl'],
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                  )
                                                  : const Icon(
                                                    Icons.home,
                                                    size: 60,
                                                  ),
                                          title: Text(m['address'] ?? ''),
                                          subtitle: Text(
                                            'TZS ${m['rentAmount']} • ${m['rooms']} rooms\n${m['description'] ?? ''}',
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                ),
                                                onPressed:
                                                    () => _editProperty(
                                                      doc.id,
                                                      m,
                                                    ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onPressed:
                                                    () => _confirmDelete(
                                                      doc.id,
                                                      m['imageUrl'],
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                )
                                .toList(),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed:
                              _page > 0 ? () => setState(() => _page--) : null,
                        ),
                        Text('Page ${_page + 1}'),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed:
                              (_page + 1) * _perPage < list.length
                                  ? () => setState(() => _page++)
                                  : null,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFB3640),
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
