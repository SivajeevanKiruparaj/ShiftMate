import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    String uid = userCredential.user!.uid;

    await _db.child("users").child(uid).set({
      "uid": uid,
      "name": name,
      "email": email,
      "phone": phone,
      "role": role,
      "status": "active",
      "createdAt": DateTime.now().toString(),
    });
  }

  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    UserCredential userCredential =
        await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    String uid = userCredential.user!.uid;

    final snapshot = await _db.child("users").child(uid).get();

    if (!snapshot.exists) {
      throw "User profile not found";
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    return data["role"];
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}