import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  static const primaryBlue = Color(0xFF4DA6FF);
  static const darkBlue = Color(0xFF1565C0);

  final companyNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final rateController = TextEditingController();

  bool loading = true;
  bool saving = false;

  final settingsRef = FirebaseDatabase.instance.ref("companySettings");

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final snapshot = await settingsRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      companyNameController.text = data["companyName"] ?? "";
      phoneController.text = data["companyPhone"] ?? "";
      addressController.text = data["companyAddress"] ?? "";
      rateController.text = data["defaultHourlyRate"] ?? "";
    }

    setState(() => loading = false);
  }

  Future<void> saveSettings() async {
    setState(() => saving = true);

    await settingsRef.set({
      "companyName": companyNameController.text.trim(),
      "companyPhone": phoneController.text.trim(),
      "companyAddress": addressController.text.trim(),
      "defaultHourlyRate": rateController.text.trim(),
      "updatedAt": DateTime.now().toString(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Company settings saved")),
    );

    setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(title: const Text("Company Settings")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(
                    Icons.business,
                    size: 80,
                    color: primaryBlue,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Workplace Details",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                  const SizedBox(height: 25),

                  _input(
                    controller: companyNameController,
                    label: "Company Name",
                    icon: Icons.store,
                  ),

                  _input(
                    controller: phoneController,
                    label: "Company Phone",
                    icon: Icons.phone,
                  ),

                  _input(
                    controller: addressController,
                    label: "Company Address",
                    icon: Icons.location_on,
                  ),

                  _input(
                    controller: rateController,
                    label: "Default Hourly Rate",
                    icon: Icons.payments,
                    suffix: "£",
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      onPressed: saving ? null : saveSettings,
                      icon: const Icon(Icons.save),
                      label: saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Save Settings",
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

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          prefixIcon: Icon(icon, color: primaryBlue),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}