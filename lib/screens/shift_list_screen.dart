import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ShiftListScreen extends StatelessWidget {
  const ShiftListScreen({super.key});

  static const primaryBlue = Color(0xFF4DA6FF);
  static const darkBlue = Color(0xFF1565C0);

  Future<void> deleteShift(
    BuildContext context,
    String shiftId,
    String workerName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Shift"),
          content: Text("Delete this shift for $workerName?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await FirebaseDatabase.instance.ref("shifts/$shiftId").remove();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Shift deleted successfully")),
        );
      }
    }
  }

  Future<void> editShift(
    BuildContext context,
    Map<String, dynamic> shift,
  ) async {
    final rateController = TextEditingController(
      text: shift["hourlyRate"]?.toString() ?? "",
    );

    final breakController = TextEditingController(
      text: shift["breakMinutes"]?.toString() ?? "0",
    );

    final startController = TextEditingController(
      text: shift["startTime"]?.toString() ?? "",
    );

    final endController = TextEditingController(
      text: shift["endTime"]?.toString() ?? "",
    );

    final dateController = TextEditingController(
      text: shift["date"]?.toString() ?? "",
    );

    String status = shift["status"]?.toString() ?? "upcoming";

    final shiftId = shift["shiftId"];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Shift"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _dialogInput(dateController, "Date"),
                    _dialogInput(startController, "Start Time"),
                    _dialogInput(endController, "End Time"),
                    _dialogInput(rateController, "Hourly Rate"),
                    _dialogInput(breakController, "Break Minutes"),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(
                        labelText: "Status",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "upcoming",
                          child: Text("Upcoming"),
                        ),
                        DropdownMenuItem(
                          value: "completed",
                          child: Text("Completed"),
                        ),
                        DropdownMenuItem(
                          value: "cancelled",
                          child: Text("Cancelled"),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          status = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await FirebaseDatabase.instance
                        .ref("shifts/$shiftId")
                        .update({
                      "date": dateController.text.trim(),
                      "startTime": startController.text.trim(),
                      "endTime": endController.text.trim(),
                      "hourlyRate": rateController.text.trim(),
                      "breakMinutes":
                          int.tryParse(breakController.text.trim()) ?? 0,
                      "status": status,
                      "updatedAt": DateTime.now().toString(),
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Shift updated successfully"),
                        ),
                      );
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _dialogInput(
    TextEditingController controller,
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shiftsRef = FirebaseDatabase.instance.ref("shifts");

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        title: const Text("All Shifts"),
      ),
      body: StreamBuilder(
        stream: shiftsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading shifts"));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No shifts found"));
          }

          final data = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          final shifts = data.entries.map((entry) {
            final shift = Map<String, dynamic>.from(entry.value);
            shift["shiftId"] = entry.key;
            return shift;
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: shifts.length,
            itemBuilder: (context, index) {
              final shift = shifts[index];

              final shiftId = shift["shiftId"] ?? "";
              final workerName = shift["workerName"] ?? "No Name";
              final workerEmail = shift["workerEmail"] ?? "";
              final date = shift["date"] ?? "";
              final startTime = shift["startTime"] ?? "";
              final endTime = shift["endTime"] ?? "";
              final hourlyRate = shift["hourlyRate"] ?? "";
              final breakMinutes = shift["breakMinutes"] ?? 0;
              final status = shift["status"] ?? "upcoming";

              Color statusColor = Colors.green;
              if (status == "cancelled") statusColor = Colors.red;
              if (status == "completed") statusColor = Colors.blue;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: primaryBlue,
                          child: Icon(Icons.work, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workerName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: darkBlue,
                                ),
                              ),
                              Text(workerEmail),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Text("Date: $date"),
                    Text("Time: $startTime - $endTime"),
                    Text("Hourly Rate: £$hourlyRate"),
                    Text("Break: $breakMinutes minutes"),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text("Edit"),
                            onPressed: () {
                              editShift(context, shift);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text("Delete"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              deleteShift(context, shiftId, workerName);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}