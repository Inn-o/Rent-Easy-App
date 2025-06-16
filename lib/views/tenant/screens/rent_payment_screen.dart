// lib/tenant/screens/rent_payment_screen.dart
import 'package:flutter/material.dart';

class RentPaymentScreen extends StatelessWidget {
  const RentPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F7F2),
      appBar: AppBar(
        title: Text('Pay Rent'),
        backgroundColor: Color(0xFF22577A),
      ),
      body: Center(child: Text('Rent payment functionality will go here.')),
    );
  }
}
