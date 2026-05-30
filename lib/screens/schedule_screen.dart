import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  static const primaryBlue = Color(0xFF4DA6FF);
  static const darkBlue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final shiftsRef = FirebaseDatabase.instance.ref("shifts");

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        title: const Text("My Schedule"),
      ),
      body: StreamBuilder(
        stream: shiftsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading shifts"),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text("No shifts found"),
            );
          }

          final data = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          final shifts = data.values
              .map((e) => Map<String, dynamic>.from(e))
              .where((shift) =>
                  shift["workerId"] == currentUser?.uid)
              .toList();

          if (shifts.isEmpty) {
            return const Center(
              child: Text("No shifts assigned yet"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: shifts.length,
            itemBuilder: (context, index) {
              final shift = shifts[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: primaryBlue,
                      child: Icon(
                        Icons.work,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            shift["date"] ?? "",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkBlue,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "${shift["startTime"]} - ${shift["endTime"]}",
                          ),

                          Text(
                            "Rate: £${shift["hourlyRate"]}",
                          ),

                          if (shift["hasBreak"] == true)
                            Text(
                              "Break: ${shift["breakMinutes"]} min",
                            ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        shift["status"] ?? "Upcoming",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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