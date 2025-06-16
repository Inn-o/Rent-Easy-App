import 'package:flutter/material.dart';
import 'package:rent_easy/theme.dart';
//import 'package:rent_easy/views/auth/login.dart';
//import 'package:rent_easy/views/owner/onboarding/onboarding_screen.dart';
//import 'package:rent_easy/views/owner/owner_dashboard.dart';
//import 'package:rent_easy/views/owner/screens/maintenance_screen.dart';
//import 'package:rent_east/theme.dart';
import 'package:rent_easy/views/tenant/tenants_dashboard.dart';
//import 'package:rent_easy/views/auth/register.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RentEase',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      //home: const LoginScreen(),
      //home: const OwnerDashboard(),
      //home: const RegisterScreen(),
      //home: const MaintenanceScreen(),
      //home: const Dashboard(),,
      home: const TenantDashboard(),
    );
  }
}
