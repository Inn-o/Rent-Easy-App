import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> markOnboardingComplete(String userId) async {
    await _firestore.collection('Users').doc(userId).update({
      'onboardingComplete': true,
    });
  }
}
