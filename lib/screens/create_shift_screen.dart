import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CreateShiftScreen extends StatefulWidget {
  const CreateShiftScreen({super.key});

  @override
  State<CreateShiftScreen> createState() => _CreateShiftScreenState();
}

class _CreateShiftScreenState extends State<CreateShiftScreen> {
  static const primaryBlue = Color(0xFF4DA6FF);
  static const darkBlue = Color(0xFF1565C0);

  final DatabaseReference usersRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference shiftsRef = FirebaseDatabase.instance.ref("shifts");

  List<Map<String, dynamic>> workers = [];
  Map<String, dynamic>? selectedWorker;

  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 0, minute: 0);

  bool hasBreak = false;
  bool isLoading = true;
  bool isSaving = false;

  final breakController = TextEditingController();
  final rateController = TextEditingController(text: "7.50");

  @override
  void initState() {
    super.initState();
    loadWorkers();
  }

  Future<void> loadWorkers() async {
    final snapshot = await usersRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      workers = data.entries
          .map((entry) {
            final user = Map<String, dynamic>.from(entry.value);
            user["uid"] = entry.key;
            return user;
          })
          .where((user) => user["role"] == "worker")
          .toList();

      if (workers.isNotEmpty) {
        selectedWorker = workers.first;
      }
    }

    setState(() => isLoading = false);
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
    if (selectedWorker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a worker")),
      );
      return;
    }

    setState(() => isSaving = true);

    int breakMinutes = 0;

    if (hasBreak && breakController.text.trim().isNotEmpty) {
      breakMinutes = int.tryParse(breakController.text.trim()) ?? 0;
    }

    final shiftId = shiftsRef.push().key!;

    await shiftsRef.child(shiftId).set({
      "shiftId": shiftId,
      "workerId": selectedWorker!["uid"],
      "workerName": selectedWorker!["name"],
      "workerEmail": selectedWorker!["email"],
      "workerPhone": selectedWorker!["phone"],
      "date": "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
      "startTime": startTime.format(context),
      "endTime": endTime.format(context),
      "hourlyRate": rateController.text.trim(),
      "hasBreak": hasBreak,
      "breakMinutes": breakMinutes,
      "status": "upcoming",
      "createdAt": DateTime.now().toString(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Shift saved to Firebase")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(title: const Text("Create Shift")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : workers.isEmpty
              ? const Center(child: Text("No workers found. Register worker first."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          value: selectedWorker,
                          decoration: const InputDecoration(
                            labelText: "Select Worker",
                            border: InputBorder.none,
                          ),
                          items: workers.map((worker) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: worker,
                              child: Text(worker["name"] ?? "No Name"),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedWorker = value;
                            });
                          },
                        ),
                      ),

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: SwitchListTile(
                          value: hasBreak,
                          activeColor: primaryBlue,
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            "Add Break Time?",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: darkBlue,
                            ),
                          ),
                          subtitle: Text(
                            hasBreak
                                ? "Enter break time below"
                                : "No break will be recorded",
                          ),
                          secondary: const Icon(
                            Icons.free_breakfast,
                            color: primaryBlue,
                          ),
                          onChanged: (value) {
                            setState(() {
                              hasBreak = value;
                              if (!hasBreak) breakController.clear();
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
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Create Shift",
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
      child: ListTile(
        onTap: onTap,
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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