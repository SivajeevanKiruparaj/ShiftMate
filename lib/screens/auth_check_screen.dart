import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'welcome_screen.dart';
import 'admin_home_screen.dart';
import 'worker_main_screen.dart';
import 'admin_main_screen.dart';

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  static const primaryBlue = Color(0xFF4DA6FF);

  Future<String?> getUserRole(String uid) async {
    final snapshot =
        await FirebaseDatabase.instance.ref("users/$uid/role").get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const WelcomeScreen();
    }

    return FutureBuilder<String?>(
      future: getUserRole(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7FBFF),
            body: Center(
              child: CircularProgressIndicator(
                color: primaryBlue,
              ),
            ),
          );
        }

        final role = snapshot.data;

        if (role == "admin") {
          return AdminMainScreen();
        }

        if (role == "worker") {
        return AdminMainScreen();
        }

        return const WelcomeScreen();
      },
    );
  }
}