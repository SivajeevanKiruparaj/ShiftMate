import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PayReportScreen extends StatelessWidget {
  const PayReportScreen({super.key});

  static const primaryBlue = Color(0xFF4DA6FF);
  static const darkBlue = Color(0xFF1565C0);

  DateTime? parseShiftDate(String date) {
    try {
      final parts = date.split("/");
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (e) {
      return null;
    }
  }

  bool isThisWeek(String dateText) {
    final date = parseShiftDate(dateText);
    if (date == null) return false;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final cleanDate = DateTime(date.year, date.month, date.day);
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);

    return cleanDate.isAtSameMomentAs(start) ||
        cleanDate.isAtSameMomentAs(end) ||
        (cleanDate.isAfter(start) && cleanDate.isBefore(end));
  }

  (int, int) parseTime(String time) {
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

  double calculateShiftHours(Map<String, dynamic> shift) {
    try {
      final start = parseTime(shift["startTime"].toString());
      final end = parseTime(shift["endTime"].toString());

      double startHour = start.$1 + (start.$2 / 60);
      double endHour = end.$1 + (end.$2 / 60);

      if (endHour < startHour) {
        endHour += 24;
      }

      final breakMinutes = shift["breakMinutes"] ?? 0;
      final hours = endHour - startHour - (breakMinutes / 60);

      return hours < 0 ? 0 : hours;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final shiftsRef = FirebaseDatabase.instance.ref("shifts");

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        title: const Text("Pay Report"),
      ),
      body: user == null
          ? const Center(child: Text("Please login again"))
          : StreamBuilder(
              stream: shiftsRef.onValue,
              builder: (context, snapshot) {
                double weeklyHours = 0;
                double weeklyPay = 0;
                double totalHours = 0;
                double totalPay = 0;

                List<Map<String, dynamic>> myShifts = [];

                if (snapshot.hasData &&
                    snapshot.data!.snapshot.value != null) {
                  final data = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );

                  myShifts = data.values
                      .map((e) => Map<String, dynamic>.from(e))
                      .where((shift) => shift["workerId"] == user.uid)
                      .toList();

                  for (final shift in myShifts) {
                    final hours = calculateShiftHours(shift);
                    final rate = double.tryParse(
                          shift["hourlyRate"].toString(),
                        ) ??
                        0;

                    totalHours += hours;
                    totalPay += hours * rate;

                    if (isThisWeek(shift["date"].toString())) {
                      weeklyHours += hours;
                      weeklyPay += hours * rate;
                    }
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "This Week",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              "Hours",
                              "${weeklyHours.toStringAsFixed(1)} hrs",
                              Icons.timer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryCard(
                              "Pay",
                              "£${weeklyPay.toStringAsFixed(2)}",
                              Icons.payments,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              "Total Hours",
                              "${totalHours.toStringAsFixed(1)} hrs",
                              Icons.work_history,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryCard(
                              "Total Pay",
                              "£${totalPay.toStringAsFixed(2)}",
                              Icons.account_balance_wallet,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        "Shift Breakdown",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                      const SizedBox(height: 12),

                      myShifts.isEmpty
                          ? const Center(child: Text("No shifts found"))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: myShifts.length,
                              itemBuilder: (context, index) {
                                final shift = myShifts[index];
                                final hours = calculateShiftHours(shift);
                                final rate = double.tryParse(
                                      shift["hourlyRate"].toString(),
                                    ) ??
                                    0;
                                final pay = hours * rate;

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
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: primaryBlue,
                                        child: Icon(
                                          Icons.receipt_long,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
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
                                            Text(
                                              "${shift["startTime"]} - ${shift["endTime"]}",
                                            ),
                                            Text(
                                              "Hours: ${hours.toStringAsFixed(1)}",
                                            ),
                                            Text("Rate: £$rate"),
                                            Text(
                                              "Pay: £${pay.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4DA6FF), Color(0xFF8ED0FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.20),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}