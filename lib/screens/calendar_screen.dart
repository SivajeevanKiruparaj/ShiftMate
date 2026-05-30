import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const primaryBlue = Color(0xFF4DA6FF);
  static const darkBlue = Color(0xFF1565C0);

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  List<Map<String, dynamic>> allShifts = [];

  String dateKey(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  List<Map<String, dynamic>> getShiftsForDay(DateTime day) {
    return allShifts.where((shift) {
      return shift["date"] == dateKey(day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final shiftsRef = FirebaseDatabase.instance.ref("shifts");

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(title: const Text("Calendar")),
      body: user == null
          ? const Center(child: Text("Please login again"))
          : StreamBuilder(
              stream: shiftsRef.onValue,
              builder: (context, snapshot) {
                allShifts = [];

                if (snapshot.hasData &&
                    snapshot.data!.snapshot.value != null) {
                  final data = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );

                  allShifts = data.values
                      .map((e) => Map<String, dynamic>.from(e))
                      .where((shift) => shift["workerId"] == user.uid)
                      .toList();
                }

                final selectedShifts = getShiftsForDay(selectedDay);

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(10),
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
                      child: TableCalendar(
                        firstDay: DateTime(2024),
                        lastDay: DateTime(2030),
                        focusedDay: focusedDay,
                        selectedDayPredicate: (day) {
                          return isSameDay(selectedDay, day);
                        },
                        eventLoader: getShiftsForDay,
                        calendarStyle: const CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Color(0xFF8ED0FF),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        onDaySelected: (selected, focused) {
                          setState(() {
                            selectedDay = selected;
                            focusedDay = focused;
                          });
                        },
                      ),
                    ),

                    Expanded(
                      child: selectedShifts.isEmpty
                          ? const Center(
                              child: Text("No shifts on this date"),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: selectedShifts.length,
                              itemBuilder: (context, index) {
                                final shift = selectedShifts[index];

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
                                          Icons.work,
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
                                              "${shift["startTime"]} - ${shift["endTime"]}",
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: darkBlue,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Rate: £${shift["hourlyRate"]}",
                                            ),
                                            if (shift["hasBreak"] == true)
                                              Text(
                                                "Break: ${shift["breakMinutes"]} min",
                                              ),
                                            Text(
                                              "Status: ${shift["status"] ?? "upcoming"}",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}