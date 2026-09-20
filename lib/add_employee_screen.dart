import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  static const Color deepNavy = Color(0xFF0D1B2A);
  static const Color offWhite = Color(0xFFF0EDE8);
  static const Color electricYellowGreen = Color(0xFFC8F500);
  static const Color cardBg = Color(0xFF16222D);

  final _formKey = GlobalKey<FormState>();

  final employeeNameController = TextEditingController();

  final visaNumberController = TextEditingController();
  final visaExpiryController = TextEditingController();

  final laborCardNumberController = TextEditingController();
  final laborExpiryController = TextEditingController();

  final ohcCardNumberController = TextEditingController();
  final ohcExpiryController = TextEditingController();

  bool isSaving = false;

  @override
  void dispose() {
    employeeNameController.dispose();

    visaNumberController.dispose();
    visaExpiryController.dispose();

    laborCardNumberController.dispose();
    laborExpiryController.dispose();

    ohcCardNumberController.dispose();
    ohcExpiryController.dispose();

    super.dispose();
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate(
      BuildContext context,
      TextEditingController controller,
      ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: electricYellowGreen,
              onPrimary: deepNavy,
              surface: Color(0xFF1B2A38),
              onSurface: offWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final year = pickedDate.year.toString().padLeft(4, '0');
      final month = pickedDate.month.toString().padLeft(2, '0');
      final day = pickedDate.day.toString().padLeft(2, '0');

      controller.text = '$year-$month-$day';
    }
  }

  // ============================================================
  // SAVE EMPLOYEE
  // ============================================================

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // --------------------------------------------------------
      // USER-SPECIFIC EMPLOYEE COLLECTION
      // users/{uid}/employees/{employeeId}
      // --------------------------------------------------------

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('employees')
          .add({
        'employeeName': employeeNameController.text.trim(),

        'visaNumber': visaNumberController.text.trim(),
        'visaExpiry': visaExpiryController.text.trim(),

        'laborCardNumber': laborCardNumberController.text.trim(),
        'laborExpiry': laborExpiryController.text.trim(),

        'ohcCardNumber': ohcCardNumberController.text.trim(),
        'ohcExpiry': ohcExpiryController.text.trim(),

        'userId': user.uid,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Employee added successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save employee: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    bool requiredField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          color: offWhite,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null
              ? null
              : Icon(
            icon,
            color: electricYellowGreen,
          ),
          labelStyle: const TextStyle(
            color: Colors.white70,
          ),
          hintStyle: const TextStyle(
            color: Colors.white38,
          ),
          filled: true,
          fillColor: cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.white12,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: electricYellowGreen,
              width: 2,
            ),
          ),
        ),
        validator: requiredField
            ? (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          return null;
        }
            : null,
      ),
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _dateField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(
          color: offWhite,
        ),
        onTap: () {
          _selectDate(context, controller);
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: 'YYYY-MM-DD',
          prefixIcon: const Icon(
            Icons.calendar_month,
            color: electricYellowGreen,
          ),
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.white70,
          ),
          labelStyle: const TextStyle(
            color: Colors.white70,
          ),
          hintStyle: const TextStyle(
            color: Colors.white38,
          ),
          filled: true,
          fillColor: cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.white12,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: electricYellowGreen,
              width: 2,
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
      String title,
      IconData icon,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 12,
        bottom: 14,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: electricYellowGreen,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: electricYellowGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,

      appBar: AppBar(
        backgroundColor: deepNavy,
        foregroundColor: offWhite,
        title: const Text(
          'Add Employee',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ==================================================
              // EMPLOYEE INFORMATION
              // ==================================================

              _sectionTitle(
                'Employee Information',
                Icons.person,
              ),

              _textField(
                label: 'Employee Name',
                hint: 'Enter employee name',
                controller: employeeNameController,
                icon: Icons.person_outline,
                requiredField: true,
              ),

              // ==================================================
              // VISA
              // ==================================================

              _sectionTitle(
                'Visa Information',
                Icons.badge,
              ),

              _textField(
                label: 'Visa Number',
                hint: 'Enter visa number',
                controller: visaNumberController,
                icon: Icons.confirmation_number_outlined,
                requiredField: true,
              ),

              _dateField(
                label: 'Visa Expiry Date',
                controller: visaExpiryController,
              ),

              // ==================================================
              // LABOUR CARD
              // ==================================================

              _sectionTitle(
                'Labour Card Information',
                Icons.work_outline,
              ),

              _textField(
                label: 'Labour Card Number',
                hint: 'Enter labour card number',
                controller: laborCardNumberController,
                icon: Icons.credit_card,
                requiredField: true,
              ),

              _dateField(
                label: 'Labour Card Expiry Date',
                controller: laborExpiryController,
              ),

              // ==================================================
              // OHC CARD
              // ==================================================

              _sectionTitle(
                'OHC Card Information',
                Icons.medical_information_outlined,
              ),

              _textField(
                label: 'OHC Card Number',
                hint: 'Enter OHC card number',
                controller: ohcCardNumberController,
                icon: Icons.medical_information,
                requiredField: true,
              ),

              _dateField(
                label: 'OHC Card Expiry Date',
                controller: ohcExpiryController,
              ),

              const SizedBox(height: 20),

              // ==================================================
              // SAVE BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : _saveEmployee,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: electricYellowGreen,
                    foregroundColor: deepNavy,
                    disabledBackgroundColor:
                    electricYellowGreen.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: deepNavy,
                    ),
                  )
                      : const Icon(
                    Icons.save,
                  ),
                  label: Text(
                    isSaving ? 'Saving...' : 'Save Employee',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}