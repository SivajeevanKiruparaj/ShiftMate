import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'staff_list_screen.dart';
import 'create_shift_screen.dart';
import 'invite_staff_screen.dart';
import 'shift_list_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';


class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  static const primaryBlue = Color(0xFF4DA6FF);
  static const darkBlue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseDatabase.instance.ref("users");
    final shiftsRef = FirebaseDatabase.instance.ref("shifts");

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: usersRef.onValue,
        builder: (context, userSnapshot) {
          return StreamBuilder(
            stream: shiftsRef.onValue,
            builder: (context, shiftSnapshot) {
              int totalWorkers = 0;
              int totalShifts = 0;
              int upcomingShifts = 0;
              int completedShifts = 0;

              if (userSnapshot.hasData &&
                  userSnapshot.data!.snapshot.value != null) {
                final users = Map<String, dynamic>.from(
                  userSnapshot.data!.snapshot.value as Map,
                );

                totalWorkers = users.values.where((user) {
                  final data = Map<String, dynamic>.from(user);
                  return data["role"] == "worker";
                }).length;
              }

              if (shiftSnapshot.hasData &&
                  shiftSnapshot.data!.snapshot.value != null) {
                final shifts = Map<String, dynamic>.from(
                  shiftSnapshot.data!.snapshot.value as Map,
                );

                totalShifts = shifts.length;

                for (final shift in shifts.values) {
                  final data = Map<String, dynamic>.from(shift);
                  final status = data["status"] ?? "upcoming";

                  if (status == "upcoming") {
                    upcomingShifts++;
                  }

                  if (status == "completed") {
                    completedShifts++;
                  }
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Overview",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Manage staff and shifts easily",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.35,
                      children: [
                        _statCard(
                          "Workers",
                          totalWorkers.toString(),
                          Icons.group,
                        ),
                        _statCard(
                          "Total Shifts",
                          totalShifts.toString(),
                          Icons.calendar_month,
                        ),
                        _statCard(
                          "Upcoming",
                          upcomingShifts.toString(),
                          Icons.schedule,
                        ),
                        _statCard(
                          "Completed",
                          completedShifts.toString(),
                          Icons.check_circle,
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                    const SizedBox(height: 15),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      children: [
                        _adminCard(
                          context,
                          "Staff Details",
                          Icons.group,
                          const StaffListScreen(),
                        ),
                        _adminCard(
                          context,
                          "Create Shift",
                          Icons.add_box,
                          const CreateShiftScreen(),
                        ),
                        _adminCard(
                          context,
                          "Invite Staff",
                          Icons.mail,
                          const InviteStaffScreen(),
                        ),
                        _adminCard(
                          context,
                          "All Shifts",
                          Icons.calendar_month,
                          const ShiftListScreen(),
                        ),
                        _adminCard(
                            context,
                            "Notifications",
                            Icons.notifications,
                            const NotificationScreen(),
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

  Widget _statCard(String title, String value, IconData icon) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: primaryBlue, size: 34),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _adminCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4DA6FF), Color(0xFF8ED0FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.20),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 45),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }
}