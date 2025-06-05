import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rent_easy/views/owner/owner_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  Future<void> registerOwner() async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'userId': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'owner', // Force role to be owner
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OwnerDashboard()),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F7F2),
      appBar: AppBar(
        title: Text('Register as Owner'),
        backgroundColor: Color(0xFF22577A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: registerOwner,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFB3640),
              ),
              child: Text('Register as Owner'),
            ),
            SizedBox(height: 20),
            Text(
              'Note: Tenants will be added by the Owner using the onboarding screen.',
              style: TextStyle(color: Color(0xFF22577A)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
