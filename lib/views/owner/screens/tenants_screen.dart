// lib/screens/tenants_screen.dart
// Enhanced version: adds robust validation, error handling, image‑lifecycle cleanup,
// flexible search (name / phone / house), server‑side pagination & sorting, and
// deletes old photos from Storage when records change or are removed.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({Key? key}) : super(key: key);

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  // ======== STATE ========
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _houseCtrl = TextEditingController();
  final _idTypeCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  final _nokNameCtrl = TextEditingController();
  final _nokPhoneCtrl = TextEditingController();

  File? _imageTmp;
  final _picker = ImagePicker();

  // Search & sort
  final _searchCtrl = TextEditingController();
  String _searchTerm = '';
  String _sortOption = 'nameAsc';

  // Pagination (Firestore server‑side)
  static const int _pageSize = 10;
  DocumentSnapshot? _lastDoc; // cursor
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final List<DocumentSnapshot> _tenantDocs = [];

  String? _ownerId;

  // ======== LIFECYCLE ========
  @override
  void initState() {
    super.initState();
    _ownerId = FirebaseAuth.instance.currentUser?.uid;
    _loadFirstPage();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _houseCtrl.dispose();
    _idTypeCtrl.dispose();
    _idNumberCtrl.dispose();
    _nokNameCtrl.dispose();
    _nokPhoneCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ======== DATA FETCH ========
  Query _baseQuery() {
    Query q = FirebaseFirestore.instance
        .collection('Tenants')
        .where('ownerId', isEqualTo: _ownerId!);
    switch (_sortOption) {
      case 'nameAsc':
        q = q.orderBy('fullName');
        break;
      case 'nameDesc':
        q = q.orderBy('fullName', descending: true);
        break;
      case 'createdDesc':
        q = q.orderBy('createdAt', descending: true);
        break;
      case 'createdAsc':
        q = q.orderBy('createdAt');
        break;
    }
    return q;
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _tenantDocs.clear();
      _lastDoc = null;
      _hasMore = true;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      Query q = _baseQuery().limit(_pageSize);
      if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);
      final snap = await q.get();
      if (snap.docs.length < _pageSize) _hasMore = false;
      if (snap.docs.isNotEmpty) _lastDoc = snap.docs.last;
      setState(() => _tenantDocs.addAll(snap.docs));
    } catch (e) {
      _showSnack('Error loading tenants');
    }
    setState(() => _isLoadingMore = false);
  }

  // Helper to fetch tenants list (used in dropdown / uniqueness checks)
  Future<List<DocumentSnapshot>> _fetchTenants() async {
    final snap =
        await FirebaseFirestore.instance
            .collection('Tenants')
            .where('ownerId', isEqualTo: _ownerId)
            .get();
    return snap.docs;
  }

  // ======== VALIDATION HELPERS ========
  final _phoneExp = RegExp(r'^[0-9+]{7,15}\$');

  String? _validatePhone(String? val) {
    if (val == null || val.isEmpty) return 'Enter phone';
    if (!_phoneExp.hasMatch(val)) return 'Invalid phone';
    return null;
  }

  // ======== UI HELPERS ========
  void _showSnack(String msg) {
    if (!mounted) return; // avoid context issues
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) setState(() => _imageTmp = File(picked.path));
  }

  // ======== CREATE ========
  Future<void> _addTenantDialog() async {
    _clearForm();
    await showDialog(
      context: context,
      builder:
          (ctx) => _TenantFormDialog(
            title: 'Add Tenant',
            formKey: _formKey,
            fullNameCtrl: _fullNameCtrl,
            phoneCtrl: _phoneCtrl,
            houseCtrl: _houseCtrl,
            idTypeCtrl: _idTypeCtrl,
            idNumberCtrl: _idNumberCtrl,
            nokNameCtrl: _nokNameCtrl,
            nokPhoneCtrl: _nokPhoneCtrl,
            imageTmp: _imageTmp,
            onPickImage: _pickImage,
            validatePhone: _validatePhone,
            onSave: () async {
              if (!_formKey.currentState!.validate()) return;
              try {
                // Duplicate phone check (simple)
                final dup =
                    await FirebaseFirestore.instance
                        .collection('Tenants')
                        .where('ownerId', isEqualTo: _ownerId)
                        .where('phoneNumber', isEqualTo: _phoneCtrl.text.trim())
                        .get();
                if (dup.docs.isNotEmpty) {
                  _showSnack('Phone already exists');
                  return;
                }

                String? url;
                if (_imageTmp != null) {
                  final ref = FirebaseStorage.instance.ref(
                    'tenant_photos/${DateTime.now().millisecondsSinceEpoch}.jpg',
                  );
                  await ref.putFile(_imageTmp!);
                  url = await ref.getDownloadURL();
                }
                await FirebaseFirestore.instance.collection('Tenants').add({
                  'ownerId': _ownerId,
                  'fullName': _fullNameCtrl.text.trim(),
                  'phoneNumber': _phoneCtrl.text.trim(),
                  'houseNumber': _houseCtrl.text.trim(),
                  'idType': _idTypeCtrl.text.trim(),
                  'idNumber': _idNumberCtrl.text.trim(),
                  'profilePhotoUrl': url,
                  'nextOfKinName': _nokNameCtrl.text.trim(),
                  'nextOfKinPhoneNumber': _nokPhoneCtrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
                _loadFirstPage();
              } catch (e) {
                _showSnack('Failed to save tenant');
              }
            },
          ),
    );
  }

  // ======== EDIT ========
  Future<void> _editTenantDialog(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    _fullNameCtrl.text = data['fullName'] ?? '';
    _phoneCtrl.text = data['phoneNumber'] ?? '';
    _houseCtrl.text = data['houseNumber'] ?? '';
    _idTypeCtrl.text = data['idType'] ?? '';
    _idNumberCtrl.text = data['idNumber'] ?? '';
    _nokNameCtrl.text = data['nextOfKinName'] ?? '';
    _nokPhoneCtrl.text = data['nextOfKinPhoneNumber'] ?? '';
    _imageTmp = null;
    String? existingUrl = data['profilePhotoUrl'];

    await showDialog(
      context: context,
      builder:
          (ctx) => _TenantFormDialog(
            title: 'Edit Tenant',
            formKey: _formKey,
            fullNameCtrl: _fullNameCtrl,
            phoneCtrl: _phoneCtrl,
            houseCtrl: _houseCtrl,
            idTypeCtrl: _idTypeCtrl,
            idNumberCtrl: _idNumberCtrl,
            nokNameCtrl: _nokNameCtrl,
            nokPhoneCtrl: _nokPhoneCtrl,
            imageTmp: _imageTmp,
            existingPhotoUrl: existingUrl,
            onPickImage: () async {
              await _pickImage();
              (ctx as Element).markNeedsBuild(); // refresh dialog
            },
            validatePhone: _validatePhone,
            onSave: () async {
              if (!_formKey.currentState!.validate()) return;
              try {
                String? url = existingUrl;
                if (_imageTmp != null) {
                  // upload new
                  final ref = FirebaseStorage.instance.ref(
                    'tenant_photos/${doc.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                  );
                  await ref.putFile(_imageTmp!);
                  url = await ref.getDownloadURL();
                  // delete old
                  if (existingUrl != null) {
                    await FirebaseStorage.instance
                        .refFromURL(existingUrl)
                        .delete();
                  }
                }
                await doc.reference.update({
                  'fullName': _fullNameCtrl.text.trim(),
                  'phoneNumber': _phoneCtrl.text.trim(),
                  'houseNumber': _houseCtrl.text.trim(),
                  'idType': _idTypeCtrl.text.trim(),
                  'idNumber': _idNumberCtrl.text.trim(),
                  'profilePhotoUrl': url,
                  'nextOfKinName': _nokNameCtrl.text.trim(),
                  'nextOfKinPhoneNumber': _nokPhoneCtrl.text.trim(),
                });
                Navigator.pop(ctx);
                _loadFirstPage();
              } catch (e) {
                _showSnack('Update failed');
              }
            },
          ),
    );
  }

  // ======== DELETE ========
  Future<void> _deleteTenant(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Delete Tenant'),
            content: Text('Delete ${data['fullName']} permanently?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
    if (ok != true) return;
    try {
      await doc.reference.delete();
      if (data['profilePhotoUrl'] != null) {
        await FirebaseStorage.instance
            .refFromURL(data['profilePhotoUrl'])
            .delete();
      }
      _showSnack('Tenant deleted');
      _loadFirstPage();
    } catch (_) {
      _showSnack('Delete failed');
    }
  }

  // ======== UTIL ========
  void _clearForm() {
    _formKey.currentState?.reset();
    _fullNameCtrl.clear();
    _phoneCtrl.clear();
    _houseCtrl.clear();
    _idTypeCtrl.clear();
    _idNumberCtrl.clear();
    _nokNameCtrl.clear();
    _nokPhoneCtrl.clear();
    _imageTmp = null;
  }

  // ======== BUILD ========
  @override
  Widget build(BuildContext context) {
    final list =
        _tenantDocs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final term = _searchTerm.toLowerCase();
          return (d['fullName'] ?? '').toString().toLowerCase().contains(
                term,
              ) ||
              (d['phoneNumber'] ?? '').toString().toLowerCase().contains(
                term,
              ) ||
              (d['houseNumber'] ?? '').toString().toLowerCase().contains(term);
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Tenants'),
        backgroundColor: Color(0xFF22577A),
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: _addTenantDialog),
          PopupMenuButton<String>(
            onSelected:
                (v) => setState(() {
                  _sortOption = v;
                  _loadFirstPage();
                }),
            itemBuilder:
                (ctx) => [
                  PopupMenuItem(value: 'nameAsc', child: Text('Name ↑')),
                  PopupMenuItem(value: 'nameDesc', child: Text('Name ↓')),
                  PopupMenuItem(value: 'createdDesc', child: Text('Newest')),
                  PopupMenuItem(value: 'createdAsc', child: Text('Oldest')),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search name / phone / house',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (v) => setState(() => _searchTerm = v),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadFirstPage(),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: list.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == list.length) {
                    if (_hasMore) {
                      _loadMore();
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  }
                  final doc = list[i];
                  final d = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading:
                          d['profilePhotoUrl'] != null
                              ? CircleAvatar(
                                backgroundImage: NetworkImage(
                                  d['profilePhotoUrl'],
                                ),
                              )
                              : CircleAvatar(child: Icon(Icons.person)),
                      title: Text(d['fullName'] ?? '-'),
                      subtitle: Text(
                        '${d['phoneNumber'] ?? '-'}  •  House: ${d['houseNumber'] ?? '-'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editTenantDialog(doc),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
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
    );
  }
}

// ----------------------------------------------------------------------------
// Reusable form dialog widget ------------------------------------------------
// ----------------------------------------------------------------------------
class _TenantFormDialog extends StatelessWidget {
  const _TenantFormDialog({
    required this.title,
    required this.formKey,
    required this.fullNameCtrl,
    required this.phoneCtrl,
    required this.houseCtrl,
    required this.idTypeCtrl,
    required this.idNumberCtrl,
    required this.nokNameCtrl,
    required this.nokPhoneCtrl,
    required this.imageTmp,
    required this.onPickImage,
    required this.validatePhone,
    required this.onSave,
    this.existingPhotoUrl,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController houseCtrl;
  final TextEditingController idTypeCtrl;
  final TextEditingController idNumberCtrl;
  final TextEditingController nokNameCtrl;
  final TextEditingController nokPhoneCtrl;
  final File? imageTmp;
  final VoidCallback onPickImage;
  final String? Function(String?) validatePhone;
  final VoidCallback onSave;
  final String? existingPhotoUrl;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: fullNameCtrl,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: phoneCtrl,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: validatePhone,
              ),
              TextFormField(
                controller: houseCtrl,
                decoration: InputDecoration(labelText: 'House/Unit No.'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: idTypeCtrl,
                decoration: InputDecoration(labelText: 'ID Type'),
              ),
              TextFormField(
                controller: idNumberCtrl,
                decoration: InputDecoration(labelText: 'ID Number'),
              ),
              const SizedBox(height: 8),
              if (existingPhotoUrl != null && imageTmp == null)
                Image.network(existingPhotoUrl!, height: 90),
              if (imageTmp != null) Image.file(imageTmp!, height: 90),
              TextButton.icon(
                icon: Icon(Icons.image),
                label: Text('Pick Photo'),
                onPressed: onPickImage,
              ),
              TextFormField(
                controller: nokNameCtrl,
                decoration: InputDecoration(labelText: 'Next of Kin Name'),
              ),
              TextFormField(
                controller: nokPhoneCtrl,
                decoration: InputDecoration(labelText: 'Next of Kin Phone'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onSave,
          child: Text('Save'),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF22577A)),
        ),
      ],
    );
  }
}
