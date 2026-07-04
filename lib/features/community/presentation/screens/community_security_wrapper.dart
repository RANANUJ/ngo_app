import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'username_setup_screen.dart';

class CommunitySecurityWrapper extends StatelessWidget {
  final Widget child;
  final String? userId;
  final String userType; // 'ngo' or 'volunteer'

  const CommunitySecurityWrapper({
    Key? key,
    required this.child,
    this.userId,
    required this.userType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Authentication required to access community.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(userType == 'ngo' ? 'ngo_registrations' : 'volunteers')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF0099B8)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error checking profile access: ${snapshot.error}'),
            ),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        
        // If profile document doesn't exist, show username setup with empty registry
        final String username = data != null ? (data['username'] as String? ?? '') : '';

        if (username.isEmpty) {
          return UsernameSetupScreen(
            userId: uid,
            userType: userType,
            existingData: data ?? {},
          );
        }

        return child;
      },
    );
  }
}
