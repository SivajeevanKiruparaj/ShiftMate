import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  Future<void> saveWorker({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String joinCode,
  }) async {
    await firestore.collection("users").doc(uid).set({
      "name": name,
      "email": email,
      "phone": phone,
      "joinCode": joinCode,
      "role": "worker",
      "createdAt": Timestamp.now(),
    });
  }
}