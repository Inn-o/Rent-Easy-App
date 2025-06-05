// lib/screens/owner_dashboard.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rent_easy/views/owner/onboarding/onboarding_screen.dart';
import 'package:rent_easy/views/owner/screens/maintenance_screen.dart';
import 'package:rent_easy/views/owner/screens/properties_screen.dart';
import 'package:rent_easy/views/owner/screens/rent_tracking_screen.dart';
import 'package:rent_easy/views/owner/screens/tenants_screen.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  // Generate random alphanumeric password of 8 characters
  String _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(
      8,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  void _onboardTenant(BuildContext context) async {
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Onboard Tenant"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFB3640),
                ),
                onPressed: () async {
                  final email = emailController.text.trim();
                  final name = nameController.text.trim();
                  final password = _generatePassword();

                  try {
                    final userCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );

                    await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(userCredential.user!.uid)
                        .set({
                          'userId': userCredential.user!.uid,
                          'name': name,
                          'email': email,
                          'role': 'tenant',
                          'password': password,
                        });

                    Navigator.pop(context);

                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text("Tenant Onboarded"),
                            content: Text(
                              "Password for $email is:\n$password\n\nPlease provide this to the tenant.",
                            ),
                            actions: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFB3640),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: Text("OK"),
                              ),
                            ],
                          ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to onboard tenant: $e")),
                    );
                  }
                },
                child: Text("Create Tenant"),
              ),
            ],
          ),
    );
  }

  void _viewTenantPasswords(BuildContext context) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Tenant Passwords"),
            content: Container(
              width: double.maxFinite,
              child: FutureBuilder<QuerySnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('Users')
                        .where('role', isEqualTo: 'tenant')
                        .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text("No tenants found.");
                  }
                  return ListView(
                    shrinkWrap: true,
                    children:
                        snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(data['name'] ?? 'Unnamed'),
                            subtitle: Text(
                              "Email: ${data['email']}\nPassword: ${data['password'] ?? 'N/A'}",
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFB3640),
                              ),
                              child: Text("Reset"),
                              onPressed: () async {
                                final newPassword = _generatePassword();
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('Users')
                                      .doc(data['userId'])
                                      .update({'password': newPassword});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Password reset for ${data['email']}: $newPassword",
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Error resetting password: $e",
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Close"),
              ),
            ],
          ),
    );
  }

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
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFB3640),
              ),
              onPressed: () {
                _onboardTenant(context);
              },
              child: Text('Onboard New Tenant'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFB3640),
              ),
              onPressed: () {
                _viewTenantPasswords(context);
              },
              child: Text('View Tenant Passwords'),
            ),
          ],
        ),
      ),
    );
  }
}
