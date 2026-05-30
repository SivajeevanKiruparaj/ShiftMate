import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfPayslipScreen extends StatelessWidget {
  const PdfPayslipScreen({super.key});

  static const primaryBlue = Color(0xFF4DA6FF);
  static const darkBlue = Color(0xFF1565C0);

  (int, int) parseTime(String time) {
    final parts = time.split(" ");
    final hm = parts[0].split(":");

    int hour = int.parse(hm[0]);
    int minute = int.parse(hm[1]);

    if (parts.length > 1) {
      final period = parts[1].toUpperCase();

      if (period == "PM" && hour != 12) hour += 12;
      if (period == "AM" && hour == 12) hour = 0;
    }

    return (hour, minute);
  }

  double calculateHours(Map<String, dynamic> shift) {
    try {
      final start = parseTime(shift["startTime"].toString());
      final end = parseTime(shift["endTime"].toString());

      double startHour = start.$1 + start.$2 / 60;
      double endHour = end.$1 + end.$2 / 60;

      if (endHour < startHour) endHour += 24;

      final breakMinutes = shift["breakMinutes"] ?? 0;

      return endHour - startHour - (breakMinutes / 60);
    } catch (e) {
      return 0;
    }
  }

  Future<void> generatePdf(
    BuildContext context,
    List<Map<String, dynamic>> shifts,
  ) async {
    final pdf = pw.Document();

    double totalHours = 0;
    double totalPay = 0;

    for (final shift in shifts) {
      final hours = calculateHours(shift);
      final rate = double.tryParse(shift["hourlyRate"].toString()) ?? 0;

      totalHours += hours;
      totalPay += hours * rate;
    }

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            "ShiftMate Payslip",
            style: pw.TextStyle(
              fontSize: 26,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text("Generated Date: ${DateTime.now()}"),
          pw.SizedBox(height: 20),

          pw.Text(
            "Summary",
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text("Total Hours: ${totalHours.toStringAsFixed(1)} hrs"),
          pw.Text("Total Pay: £${totalPay.toStringAsFixed(2)}"),

          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: [
              "Date",
              "Start",
              "End",
              "Break",
              "Rate",
              "Hours",
              "Pay",
            ],
            data: shifts.map((shift) {
              final hours = calculateHours(shift);
              final rate =
                  double.tryParse(shift["hourlyRate"].toString()) ?? 0;
              final pay = hours * rate;

              return [
                shift["date"] ?? "",
                shift["startTime"] ?? "",
                shift["endTime"] ?? "",
                "${shift["breakMinutes"] ?? 0} min",
                "£$rate",
                hours.toStringAsFixed(1),
                "£${pay.toStringAsFixed(2)}",
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final shiftsRef = FirebaseDatabase.instance.ref("shifts");

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        title: const Text("PDF Payslip"),
      ),
      body: user == null
          ? const Center(child: Text("Please login again"))
          : StreamBuilder(
              stream: shiftsRef.onValue,
              builder: (context, snapshot) {
                List<Map<String, dynamic>> shifts = [];

                if (snapshot.hasData &&
                    snapshot.data!.snapshot.value != null) {
                  final data = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );

                  shifts = data.values
                      .map((e) => Map<String, dynamic>.from(e))
                      .where((shift) => shift["workerId"] == user.uid)
                      .toList();
                }

                return Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf,
                        size: 90,
                        color: primaryBlue,
                      ),
                      const SizedBox(height: 15),

                      const Text(
                        "Download Payslip",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Create a PDF report from your saved shifts.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 30),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Available Shifts",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              shifts.length.toString(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton.icon(
                          onPressed: shifts.isEmpty
                              ? null
                              : () => generatePdf(context, shifts),
                          icon: const Icon(Icons.download),
                          label: const Text(
                            "Generate PDF Payslip",
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
                );
              },
            ),
    );
  }
}