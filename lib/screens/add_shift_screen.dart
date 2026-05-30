import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AddShiftScreen extends StatefulWidget {
  const AddShiftScreen({super.key});

  @override
  State<AddShiftScreen> createState() => _AddShiftScreenState();
}

class _AddShiftScreenState extends State<AddShiftScreen> {
  static const primaryBlue = Color(0xFF4DA6FF);
  static const darkBlue = Color(0xFF1565C0);

  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 0, minute: 0);

  bool hasBreak = false;
  bool isSaving = false;

  final breakController = TextEditingController();
  final rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDefaultRate();
  }

  Future<void> loadDefaultRate() async {
    final snapshot = await FirebaseDatabase.instance
        .ref("companySettings/defaultHourlyRate")
        .get();

    if (snapshot.exists) {
      rateController.text = snapshot.value.toString();
    } else {
      rateController.text = "12.21";
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDate: selectedDate,
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: startTime,
    );

    if (time != null) {
      setState(() => startTime = time);
    }
  }

  Future<void> pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: endTime,
    );

    if (time != null) {
      setState(() => endTime = time);
    }
  }

  Future<void> saveShift() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login again")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final userSnapshot =
          await FirebaseDatabase.instance.ref("users/${user.uid}").get();

      String workerName = "Worker";
      String workerEmail = user.email ?? "";
      String workerPhone = "";

      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        workerName = userData["name"] ?? "Worker";
        workerEmail = userData["email"] ?? user.email ?? "";
        workerPhone = userData["phone"] ?? "";
      }

      int breakMinutes = 0;

      if (hasBreak && breakController.text.trim().isNotEmpty) {
        breakMinutes = int.tryParse(breakController.text.trim()) ?? 0;
      }

      final shiftsRef = FirebaseDatabase.instance.ref("shifts");
      final shiftId = shiftsRef.push().key!;

      await shiftsRef.child(shiftId).set({
        "shiftId": shiftId,
        "workerId": user.uid,
        "workerName": workerName,
        "workerEmail": workerEmail,
        "workerPhone": workerPhone,
        "date": "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
        "startTime": startTime.format(context),
        "endTime": endTime.format(context),
        "hourlyRate": rateController.text.trim(),
        "hasBreak": hasBreak,
        "breakMinutes": breakMinutes,
        "status": "upcoming",
        "createdBy": "worker",
        "createdAt": DateTime.now().toString(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shift saved successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save shift: $e")),
      );
    }

    if (mounted) {
      setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    breakController.dispose();
    rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        title: const Text("Add Shift"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _selectTile(
              title: "Shift Date",
              value: dateText,
              icon: Icons.calendar_month,
              onTap: pickDate,
            ),
            _selectTile(
              title: "Start Time",
              value: startTime.format(context),
              icon: Icons.access_time,
              onTap: pickStartTime,
            ),
            _selectTile(
              title: "End Time",
              value: endTime.format(context),
              icon: Icons.timer_off,
              onTap: pickEndTime,
            ),
            _inputBox(
              controller: rateController,
              title: "Hourly Rate",
              suffix: "£",
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SwitchListTile(
                value: hasBreak,
                activeColor: primaryBlue,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "Did you take a break?",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
                subtitle: Text(
                  hasBreak
                      ? "Enter your break time below"
                      : "No break will be recorded",
                ),
                secondary: const Icon(
                  Icons.free_breakfast,
                  color: primaryBlue,
                ),
                onChanged: (value) {
                  setState(() {
                    hasBreak = value;
                    if (!hasBreak) {
                      breakController.clear();
                    }
                  });
                },
              ),
            ),
            if (hasBreak)
              _inputBox(
                controller: breakController,
                title: "Break Time",
                suffix: "minutes",
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : saveShift,
                icon: const Icon(Icons.save),
                label: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Shift",
                        style: TextStyle(fontSize: 18),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        leading: Icon(icon, color: primaryBlue),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: darkBlue,
          ),
        ),
      ),
    );
  }

  Widget _inputBox({
    required TextEditingController controller,
    required String title,
    required String suffix,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: title,
          suffixText: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}