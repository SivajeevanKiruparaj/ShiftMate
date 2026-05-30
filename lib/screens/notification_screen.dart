import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static const primaryBlue = Color(0xFF4DA6FF);
  static const darkBlue = Color(0xFF1565C0);

  Future<void> deleteNotification(String id) async {
    await FirebaseDatabase.instance.ref("notifications/$id").remove();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsRef =
        FirebaseDatabase.instance.ref("notifications");

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: StreamBuilder(
        stream: notificationsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading notifications"));
          }

          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No notifications yet"));
          }

          final data = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          final notifications = data.entries.map((entry) {
            final item = Map<String, dynamic>.from(entry.value);
            item["id"] = entry.key;
            return item;
          }).toList();

          notifications.sort((a, b) {
            return (b["createdAt"] ?? "")
                .toString()
                .compareTo((a["createdAt"] ?? "").toString());
          });

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];

              final id = item["id"];
              final title = item["title"] ?? "Notification";
              final message = item["message"] ?? "";
              final type = item["type"] ?? "info";
              final createdAt = item["createdAt"] ?? "";

              IconData icon = Icons.notifications;
              Color iconColor = primaryBlue;

              if (type == "shift") {
                icon = Icons.work;
                iconColor = Colors.green;
              } else if (type == "cancelled") {
                icon = Icons.cancel;
                iconColor = Colors.red;
              } else if (type == "reminder") {
                icon = Icons.alarm;
                iconColor = Colors.orange;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: iconColor.withOpacity(0.12),
                      child: Icon(icon, color: iconColor),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: darkBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(message),
                          const SizedBox(height: 5),
                          Text(
                            createdAt.toString(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        deleteNotification(id);
                      },
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