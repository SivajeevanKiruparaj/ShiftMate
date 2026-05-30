import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'add_shift_screen.dart';
import 'schedule_screen.dart';
import 'profile_screen.dart';
import 'worker_main_screen.dart';

class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});

  static const primaryBlue = Color(0xFF4DA6FF);
  static const darkBlue = Color(0xFF1565C0);
  static const bgColor = Color(0xFFF7FBFF);

  double calculateShiftHours(Map<String, dynamic> shift) {
    try {
      final start = shift["startTime"].toString();
      final end = shift["endTime"].toString();

      final startTime = _parseTime(start);
      final endTime = _parseTime(end);

      double startHour = startTime.$1 + (startTime.$2 / 60);
      double endHour = endTime.$1 + (endTime.$2 / 60);

      if (endHour < startHour) {
        endHour += 24;
      }

      final breakMinutes = shift["breakMinutes"] ?? 0;

      double hours = endHour - startHour - (breakMinutes / 60);

      return hours < 0 ? 0 : hours;
    } catch (e) {
      return 0;
    }
  }

  (int, int) _parseTime(String time) {
    final parts = time.split(" ");
    final hm = parts[0].split(":");

    int hour = int.parse(hm[0]);
    int minute = int.parse(hm[1]);

    if (parts.length > 1) {
      final period = parts[1].toUpperCase();

      if (period == "PM" && hour != 12) {
        hour += 12;
      }

      if (period == "AM" && hour == 12) {
        hour = 0;
      }
    }

    return (hour, minute);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final shiftsRef = FirebaseDatabase.instance.ref("shifts");

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("ShiftMate"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text("Please login again"))
          : StreamBuilder(
              stream: shiftsRef.onValue,
              builder: (context, snapshot) {
                double weeklyHours = 0;
                double weeklyPay = 0;

                String todayShift = "No shift today";

                if (snapshot.hasData &&
                    snapshot.data!.snapshot.value != null) {
                  final data = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );

                  final userShifts = data.values
                      .map((e) => Map<String, dynamic>.from(e))
                      .where((shift) =>
                          shift["workerId"] == currentUser.uid)
                      .toList();

                  final now = DateTime.now();

                  for (final shift in userShifts) {
                    final hours = calculateShiftHours(shift);
                    final rate = double.tryParse(
                          shift["hourlyRate"].toString(),
                        ) ??
                        0;

                    weeklyHours += hours;
                    weeklyPay += hours * rate;

                    final date = shift["date"]?.toString() ?? "";
                    final todayDate = "${now.day}/${now.month}/${now.year}";

                    if (date == todayDate) {
                      todayShift =
                          "${shift["startTime"]} - ${shift["endTime"]}";
                    }
                  }
                }

                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Good morning 👋",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkBlue,
                          ),
                        ),
                        const Text(
                          "Manage your shifts easily",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),

                        _bigCard(todayShift),

                        Row(
                          children: [
                            Expanded(
                              child: _smallCard(
                                "This Week",
                                "${weeklyHours.toStringAsFixed(1)} hrs",
                                Icons.timer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _smallCard(
                                "Pay",
                                "£${weeklyPay.toStringAsFixed(2)}",
                                Icons.payments,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        _menuButton(
                          context,
                          "Add Shift",
                          Icons.add_circle,
                          const AddShiftScreen(),
                        ),

                        _menuButton(
                          context,
                          "My Schedule",
                          Icons.calendar_today,
                          const ScheduleScreen(),
                        ),

                        const Spacer(),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF6FF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.notifications_active,
                                color: primaryBlue,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Reminder: check your next shift regularly.",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: darkBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _bigCard(String todayShift) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4DA6FF), Color(0xFF8ED0FF)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.work_history, color: Colors.white, size: 42),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today’s Shift",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  todayShift,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _smallCard(String title, String value, IconData icon) {
    return Container(
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
        children: [
          Icon(icon, color: primaryBlue, size: 32),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton(
    BuildContext context,
    String text,
    IconData icon,
    Widget screen,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
        icon: Icon(icon),
        label: Text(text, style: const TextStyle(fontSize: 17)),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}