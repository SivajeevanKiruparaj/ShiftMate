import 'package:firebase_database/firebase_database.dart';

class TestFirebase {
  static Future<void> test() async {
    await FirebaseDatabase.instance.ref("test").set({
      "message": "ShiftMate Connected Successfully"
    });
  }
}