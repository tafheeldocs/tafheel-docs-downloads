import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'employee_detail_screen.dart';

class CompanyDetailScreen extends StatefulWidget {
  final String companyId;
  final String companyName;

  const CompanyDetailScreen({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color deepNavy = Color(0xFF0D1B2A);
  static const Color offWhite = Color(0xFFF0EDE8);
  static const Color electricYellowGreen = Color(0xFFC8F500);
  static const Color cardBg = Color(0xFF16222D);
  static const Color dialogBg = Color(0xFF1B2A38);

  // ============================================================
  // EMPLOYEE COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _employeesRef {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('employees');
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickDate(
      BuildContext context,
      TextEditingController controller,
      ) async {
    DateTime initialDate = DateTime.now();

    if (controller.text.trim().isNotEmpty) {
      try {
        initialDate = DateTime.parse(controller.text.trim());
      } catch (_) {}
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    controller.text =
    '${pickedDate.year.toString().padLeft(4, '0')}-'
        '${pickedDate.month.toString().padLeft(2, '0')}-'
        '${pickedDate.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // ADD EMPLOYEE
  // ============================================================

  void _showAddEmployeeDialog() {
    final employeeNameController = TextEditingController();

    final visaNumberController = TextEditingController();
    final visaExpiryController = TextEditingController();

    final laborCardNumberController = TextEditingController();
    final laborExpiryController = TextEditingController();

    final ohcCardNumberController = TextEditingController();
    final ohcExpiryController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              title: const Text(
                'Add Employee',
                style: TextStyle(
                  color: offWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(
                        controller: employeeNameController,
                        label: 'Employee Name *',
                        icon: Icons.person,
                      ),

                      const SizedBox(height: 14),

                      _sectionTitle(
                        'Visa Information',
                        Icons.badge_outlined,
                        electricYellowGreen,
                      ),

                      const SizedBox(height: 10),

                      _buildTextField(
                        controller: visaNumberController,
                        label: 'Visa Number',
                        icon: Icons.numbers,
                      ),

                      const SizedBox(height: 10),

                      _buildDateField(
                        context: dialogContext,
                        controller: visaExpiryController,
                        label: 'Visa Expiry',
                      ),

                      const SizedBox(height: 18),

                      _sectionTitle(
                        'Labor Card Information',
                        Icons.work_outline,
                        Colors.orangeAccent,
                      ),

                      const SizedBox(height: 10),

                      _buildTextField(
                        controller: laborCardNumberController,
                        label: 'Labor Card Number',
                        icon: Icons.credit_card,
                      ),

                      const SizedBox(height: 10),

                      _buildDateField(
                        context: dialogContext,
                        controller: laborExpiryController,
                        label: 'Labor Card Expiry',
                      ),

                      const SizedBox(height: 18),

                      _sectionTitle(
                        'OHC Card Information',
                        Icons.health_and_safety_outlined,
                        Colors.cyanAccent,
                      ),

                      const SizedBox(height: 10),

                      _buildTextField(
                        controller: ohcCardNumberController,
                        label: 'OHC Card Number',
                        icon: Icons.credit_card,
                      ),

                      const SizedBox(height: 10),

                      _buildDateField(
                        context: dialogContext,
                        controller: ohcExpiryController,
                        label: 'OHC Card Expiry',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: electricYellowGreen,
                    foregroundColor: deepNavy,
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                    final employeeName =
                    employeeNameController.text.trim();

                    if (employeeName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter employee name',
                          ),
                        ),
                      );
                      return;
                    }

                    setDialogState(() {
                      saving = true;
                    });

                    try {
                      await _employeesRef.add({
                        'employeeName': employeeName,

                        'visaNumber':
                        visaNumberController.text.trim(),
                        'visaExpiry':
                        visaExpiryController.text.trim(),

                        'laborCardNumber':
                        laborCardNumberController.text.trim(),
                        'laborExpiry':
                        laborExpiryController.text.trim(),

                        'ohcCardNumber':
                        ohcCardNumberController.text.trim(),
                        'ohcExpiry':
                        ohcExpiryController.text.trim(),

                        // Useful later for company portal
                        'companyId': widget.companyId,
                        'companyName': widget.companyName,

                        'createdAt':
                        FieldValue.serverTimestamp(),
                        'updatedAt':
                        FieldValue.serverTimestamp(),
                      });

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      if (!mounted) return;

                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Employee added successfully',
                          ),
                        ),
                      );
                    } catch (e) {
                      setDialogState(() {
                        saving = false;
                      });

                      if (!mounted) return;

                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error adding employee: $e',
                          ),
                        ),
                      );
                    }
                  },
                  icon: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: deepNavy,
                    ),
                  )
                      : const Icon(Icons.save),
                  label: Text(
                    saving ? 'Saving...' : 'Save Employee',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // EDIT EMPLOYEE
  // ============================================================

  void _showEditEmployeeDialog(
      String employeeId,
      Map<String, dynamic> employeeData,
      ) {
    final employeeNameController = TextEditingController(
      text: employeeData['employeeName']?.toString() ?? '',
    );

    final visaNumberController = TextEditingController(
      text: employeeData['visaNumber']?.toString() ?? '',
    );

    final visaExpiryController = TextEditingController(
      text: employeeData['visaExpiry']?.toString() ?? '',
    );

    final laborCardNumberController = TextEditingController(
      text: employeeData['laborCardNumber']?.toString() ?? '',
    );

    final laborExpiryController = TextEditingController(
      text: employeeData['laborExpiry']?.toString() ?? '',
    );

    final ohcCardNumberController = TextEditingController(
      text: employeeData['ohcCardNumber']?.toString() ?? '',
    );

    final ohcExpiryController = TextEditingController(
      text: employeeData['ohcExpiry']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              title: const Text(
                'Edit Employee',
                style: TextStyle(
                  color: offWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(
                        controller: employeeNameController,
                        label: 'Employee Name *',
                        icon: Icons.person,
                      ),

                      const SizedBox(height: 14),

                      _sectionTitle(
                        'Visa Information',
                        Icons.badge_outlined,
                        electricYellowGreen,
                      ),

                      const SizedBox(height: 10),

                      _buildTextField(
                        controller: visaNumberController,
                        label: 'Visa Number',
                        icon: Icons.numbers,
                      ),

                      const SizedBox(height: 10),

                      _buildDateField(
                        context: dialogContext,
                        controller: visaExpiryController,
                        label: 'Visa Expiry',
                      ),

                      const SizedBox(height: 18),

                      _sectionTitle(
                        'Labor Card Information',
                        Icons.work_outline,
                        Colors.orangeAccent,
                      ),

                      const SizedBox(height: 10),

                      _buildTextField(
                        controller: laborCardNumberController,
                        label: 'Labor Card Number',
                        icon: Icons.credit_card,
                      ),

                      const SizedBox(height: 10),

                      _buildDateField(
                        context: dialogContext,
                        controller: laborExpiryController,
                        label: 'Labor Card Expiry',
                      ),

                      const SizedBox(height: 18),

                      _sectionTitle(
                        'OHC Card Information',
                        Icons.health_and_safety_outlined,
                        Colors.cyanAccent,
                      ),

                      const SizedBox(height: 10),

                      _buildTextField(
                        controller: ohcCardNumberController,
                        label: 'OHC Card Number',
                        icon: Icons.credit_card,
                      ),

                      const SizedBox(height: 10),

                      _buildDateField(
                        context: dialogContext,
                        controller: ohcExpiryController,
                        label: 'OHC Card Expiry',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: electricYellowGreen,
                    foregroundColor: deepNavy,
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                    final employeeName =
                    employeeNameController.text.trim();

                    if (employeeName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Employee name cannot be empty',
                          ),
                        ),
                      );
                      return;
                    }

                    setDialogState(() {
                      saving = true;
                    });

                    try {
                      await _employeesRef.doc(employeeId).update({
                        'employeeName': employeeName,

                        'visaNumber':
                        visaNumberController.text.trim(),
                        'visaExpiry':
                        visaExpiryController.text.trim(),

                        'laborCardNumber':
                        laborCardNumberController.text.trim(),
                        'laborExpiry':
                        laborExpiryController.text.trim(),

                        'ohcCardNumber':
                        ohcCardNumberController.text.trim(),
                        'ohcExpiry':
                        ohcExpiryController.text.trim(),

                        'companyId': widget.companyId,
                        'companyName': widget.companyName,

                        'updatedAt':
                        FieldValue.serverTimestamp(),
                      });

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      if (!mounted) return;

                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Employee updated successfully',
                          ),
                        ),
                      );
                    } catch (e) {
                      setDialogState(() {
                        saving = false;
                      });

                      if (!mounted) return;

                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error updating employee: $e',
                          ),
                        ),
                      );
                    }
                  },
                  icon: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: deepNavy,
                    ),
                  )
                      : const Icon(Icons.save),
                  label: Text(
                    saving ? 'Updating...' : 'Update Employee',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DELETE EMPLOYEE
  // ============================================================

  Future<void> _deleteEmployee(
      String employeeId,
      String employeeName,
      ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: const Text(
            'Delete Employee?',
            style: TextStyle(
              color: offWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete $employeeName?',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _employeesRef.doc(employeeId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee deleted successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting employee: $e'),
        ),
      );
    }
  }

  // ============================================================
  // COMPANY INFORMATION CARD
  // ============================================================

  Widget _buildCompanyInformation() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(
            color: electricYellowGreen,
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Unable to load company details: ${snapshot.error}',
            style: const TextStyle(color: Colors.redAccent),
          );
        }

        final data = snapshot.data?.data();

        if (data == null) {
          return const Text(
            'Company information not found.',
            style: TextStyle(color: Colors.white54),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: electricYellowGreen.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _companyInfoRow(
                Icons.badge_outlined,
                'Trade License',
                data['tradeLicense']?.toString() ?? 'N/A',
              ),
              _companyInfoRow(
                Icons.event,
                'Trade License Expiry',
                data['tradeExpiry']?.toString() ?? 'N/A',
              ),
              _companyInfoRow(
                Icons.home_work_outlined,
                'Tenancy',
                data['tenancy']?.toString() ?? 'N/A',
              ),
              _companyInfoRow(
                Icons.event,
                'Tenancy Expiry',
                data['tenancyExpiry']?.toString() ?? 'N/A',
              ),
              _companyInfoRow(
                Icons.business_center_outlined,
                'Establishment Card',
                data['establishmentCard']?.toString() ?? 'N/A',
              ),
              _companyInfoRow(
                Icons.event,
                'Establishment Expiry',
                data['establishmentExpiry']?.toString() ?? 'N/A',
              ),
              _companyInfoRow(
                Icons.person_outline,
                'Authorized Person',
                data['authorizedPerson']?.toString() ?? 'N/A',
              ),
              _companyInfoRow(
                Icons.phone_outlined,
                'Mobile',
                data['mobile']?.toString() ?? 'N/A',
              ),
              _companyInfoRow(
                Icons.email_outlined,
                'Email',
                data['email']?.toString() ?? 'N/A',
                showDivider: false,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _companyInfoRow(
      IconData icon,
      String label,
      String value, {
        bool showDivider = true,
      }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: electricYellowGreen,
                size: 20,
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value.trim().isEmpty ? 'N/A' : value,
                  style: const TextStyle(
                    color: offWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
      ],
    );
  }

  // ============================================================
  // EMPLOYEE CARD
  // ============================================================

  Widget _buildEmployeeCard(
      QueryDocumentSnapshot<Map<String, dynamic>> employeeDoc,
      ) {
    final data = employeeDoc.data();

    final employeeName =
        data['employeeName']?.toString() ?? 'Unknown Employee';

    final visaNumber =
        data['visaNumber']?.toString() ?? '';

    final visaExpiry =
        data['visaExpiry']?.toString() ?? '';

    final laborCardNumber =
        data['laborCardNumber']?.toString() ?? '';

    final laborExpiry =
        data['laborExpiry']?.toString() ?? '';

    final ohcCardNumber =
        data['ohcCardNumber']?.toString() ?? '';

    final ohcExpiry =
        data['ohcExpiry']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeDetailScreen(
                companyId: widget.companyId,
                employeeId: employeeDoc.id,
                employeeData: data,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                  electricYellowGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: electricYellowGreen,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName,
                      style: const TextStyle(
                        color: offWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    _employeeSmallDetail(
                      'Visa',
                      visaNumber,
                      visaExpiry,
                    ),

                    const SizedBox(height: 5),

                    _employeeSmallDetail(
                      'Labor',
                      laborCardNumber,
                      laborExpiry,
                    ),

                    const SizedBox(height: 5),

                    _employeeSmallDetail(
                      'OHC',
                      ohcCardNumber,
                      ohcExpiry,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                children: [
                  IconButton(
                    tooltip: 'Edit Employee',
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: electricYellowGreen,
                    ),
                    onPressed: () {
                      _showEditEmployeeDialog(
                        employeeDoc.id,
                        data,
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Delete Employee',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () {
                      _deleteEmployee(
                        employeeDoc.id,
                        employeeName,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _employeeSmallDetail(
      String label,
      String number,
      String expiry,
      ) {
    final safeNumber =
    number.trim().isEmpty ? 'N/A' : number.trim();

    final safeExpiry =
    expiry.trim().isEmpty ? 'N/A' : expiry.trim();

    return Text(
      '$label: $safeNumber   •   Expiry: $safeExpiry',
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 12,
      ),
    );
  }

  // ============================================================
  // FORM HELPERS
  // ============================================================

  Widget _sectionTitle(
      String title,
      IconData icon,
      Color color,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white60,
        ),
        prefixIcon: Icon(
          icon,
          color: electricYellowGreen,
          size: 20,
        ),
        filled: true,
        fillColor: deepNavy,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: electricYellowGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(
        color: Colors.white,
      ),
      onTap: () {
        _pickDate(context, controller);
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: 'YYYY-MM-DD',
        hintStyle: const TextStyle(
          color: Colors.white30,
        ),
        labelStyle: const TextStyle(
          color: Colors.white60,
        ),
        prefixIcon: const Icon(
          Icons.calendar_month,
          color: electricYellowGreen,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: const Icon(
            Icons.clear,
            color: Colors.white38,
          ),
          onPressed: () {
            controller.clear();
          },
        ),
        filled: true,
        fillColor: deepNavy,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: electricYellowGreen,
          ),
        ),
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
        elevation: 0,
        iconTheme: const IconThemeData(
          color: offWhite,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.companyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: offWhite,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const Text(
              'Company Details',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: electricYellowGreen,
        foregroundColor: deepNavy,
        onPressed: _showAddEmployeeDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(
          'Add Employee',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Company Information',
                style: TextStyle(
                  color: offWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              _buildCompanyInformation(),

              const SizedBox(height: 30),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Employee Information',
                      style: TextStyle(
                        color: offWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: electricYellowGreen,
                      foregroundColor: deepNavy,
                    ),
                    onPressed: _showAddEmployeeDialog,
                    icon: const Icon(
                      Icons.add,
                      size: 18,
                    ),
                    label: const Text(
                      'Add',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: _employeesRef
                    .orderBy(
                  'createdAt',
                  descending: true,
                )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(
                          color: electricYellowGreen,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent
                            .withValues(alpha: 0.08),
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Error loading employees:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                        ),
                      ),
                    );
                  }

                  final employees =
                      snapshot.data?.docs ?? [];

                  if (employees.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white
                              .withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            color: Colors.white30,
                            size: 45,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No employees added yet',
                            style: TextStyle(
                              color: offWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add employees for this company using the button below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style:
                            ElevatedButton.styleFrom(
                              backgroundColor:
                              electricYellowGreen,
                              foregroundColor: deepNavy,
                            ),
                            onPressed:
                            _showAddEmployeeDialog,
                            icon: const Icon(
                              Icons.person_add,
                            ),
                            label: const Text(
                              'Add Employee',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: employees.map((employeeDoc) {
                      return _buildEmployeeCard(
                        employeeDoc,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}