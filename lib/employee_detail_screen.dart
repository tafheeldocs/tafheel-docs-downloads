import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final String companyId;
  final String employeeId;
  final Map<String, dynamic> employeeData;

  const EmployeeDetailScreen({
    super.key,
    required this.companyId,
    required this.employeeId,
    required this.employeeData,
  });

  @override
  State<EmployeeDetailScreen> createState() =>
      _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState
    extends State<EmployeeDetailScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color deepNavy = Color(0xFF0D1B2A);
  static const Color offWhite = Color(0xFFF0EDE8);
  static const Color electricYellowGreen = Color(0xFFC8F500);
  static const Color cardBg = Color(0xFF16222D);
  static const Color dialogBg = Color(0xFF1B2A38);

  // ============================================================
  // EMPLOYEE REFERENCE
  // ============================================================

  DocumentReference<Map<String, dynamic>> get _employeeRef {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('employees')
        .doc(widget.employeeId);
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
        initialDate =
            DateTime.parse(controller.text.trim());
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
  // EDIT EMPLOYEE
  // ============================================================

  void _showEditEmployeeDialog(
      Map<String, dynamic> employeeData,
      ) {
    final employeeNameController =
    TextEditingController(
      text:
      employeeData['employeeName']?.toString() ?? '',
    );

    final visaNumberController =
    TextEditingController(
      text:
      employeeData['visaNumber']?.toString() ?? '',
    );

    final visaExpiryController =
    TextEditingController(
      text:
      employeeData['visaExpiry']?.toString() ?? '',
    );

    final laborCardNumberController =
    TextEditingController(
      text: employeeData['laborCardNumber']
          ?.toString() ??
          '',
    );

    final laborExpiryController =
    TextEditingController(
      text:
      employeeData['laborExpiry']?.toString() ?? '',
    );

    final ohcCardNumberController =
    TextEditingController(
      text:
      employeeData['ohcCardNumber']?.toString() ?? '',
    );

    final ohcExpiryController =
    TextEditingController(
      text:
      employeeData['ohcExpiry']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              title: const Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    color: electricYellowGreen,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Edit Employee',
                    style: TextStyle(
                      color: offWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(
                        controller:
                        employeeNameController,
                        label: 'Employee Name *',
                        icon: Icons.person_outline,
                      ),

                      const SizedBox(height: 18),

                      _sectionTitle(
                        'Visa Information',
                        Icons.badge_outlined,
                        electricYellowGreen,
                      ),

                      const SizedBox(height: 10),

                      _buildTextField(
                        controller:
                        visaNumberController,
                        label: 'Visa Number',
                        icon: Icons.numbers,
                      ),

                      const SizedBox(height: 10),

                      _buildDateField(
                        context: dialogContext,
                        controller:
                        visaExpiryController,
                        label: 'Visa Expiry',
                      ),

                      const SizedBox(height: 20),

                      _sectionTitle(
                        'Labor Card Information',
                        Icons.work_outline,
                        Colors.orangeAccent,
                      ),

                      const SizedBox(height: 10),

                      _buildTextField(
                        controller:
                        laborCardNumberController,
                        label: 'Labor Card Number',
                        icon: Icons.credit_card,
                      ),

                      const SizedBox(height: 10),

                      _buildDateField(
                        context: dialogContext,
                        controller:
                        laborExpiryController,
                        label: 'Labor Card Expiry',
                      ),

                      const SizedBox(height: 20),

                      _sectionTitle(
                        'OHC Card Information',
                        Icons.health_and_safety_outlined,
                        Colors.cyanAccent,
                      ),

                      const SizedBox(height: 10),

                      _buildTextField(
                        controller:
                        ohcCardNumberController,
                        label: 'OHC Card Number',
                        icon: Icons.credit_card,
                      ),

                      const SizedBox(height: 10),

                      _buildDateField(
                        context: dialogContext,
                        controller:
                        ohcExpiryController,
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
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    electricYellowGreen,
                    foregroundColor: deepNavy,
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                    final employeeName =
                    employeeNameController
                        .text
                        .trim();

                    if (employeeName.isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
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
                      await _employeeRef.update({
                        'employeeName':
                        employeeName,

                        'visaNumber':
                        visaNumberController
                            .text
                            .trim(),

                        'visaExpiry':
                        visaExpiryController
                            .text
                            .trim(),

                        'laborCardNumber':
                        laborCardNumberController
                            .text
                            .trim(),

                        'laborExpiry':
                        laborExpiryController
                            .text
                            .trim(),

                        'ohcCardNumber':
                        ohcCardNumberController
                            .text
                            .trim(),

                        'ohcExpiry':
                        ohcExpiryController
                            .text
                            .trim(),

                        'companyId':
                        widget.companyId,

                        'updatedAt':
                        FieldValue
                            .serverTimestamp(),
                      });

                      if (!dialogContext
                          .mounted) {
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                      );

                      if (!mounted) return;

                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(
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

                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Update error: $e',
                          ),
                        ),
                      );
                    }
                  },

                  icon: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: deepNavy,
                    ),
                  )
                      : const Icon(
                    Icons.save_outlined,
                  ),

                  label: Text(
                    saving
                        ? 'Updating...'
                        : 'Update Employee',
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
      String employeeName,
      ) async {
    final bool? confirm =
    await showDialog<bool>(
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
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              icon: const Icon(
                Icons.delete_outline,
              ),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _employeeRef.delete();

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Employee deleted successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Delete error: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // EXPIRY STATUS
  // ============================================================

  Color _expiryColor(String? expiry) {
    if (expiry == null ||
        expiry.trim().isEmpty) {
      return Colors.white54;
    }

    try {
      final expiryDate =
      DateTime.parse(expiry.trim());

      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      final days =
          expiryDate.difference(today).inDays;

      if (days < 0) {
        return Colors.redAccent;
      }

      if (days <= 30) {
        return Colors.orangeAccent;
      }

      return electricYellowGreen;
    } catch (_) {
      return Colors.white54;
    }
  }

  String _expiryStatus(String? expiry) {
    if (expiry == null ||
        expiry.trim().isEmpty) {
      return 'No expiry date';
    }

    try {
      final expiryDate =
      DateTime.parse(expiry.trim());

      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      final days =
          expiryDate.difference(today).inDays;

      if (days < 0) {
        return 'Expired ${days.abs()} days ago';
      }

      if (days == 0) {
        return 'Expires today';
      }

      if (days <= 30) {
        return 'Expires in $days days';
      }

      return '$days days remaining';
    } catch (_) {
      return 'Invalid expiry date';
    }
  }

  // ============================================================
  // DOCUMENT CARD
  // ============================================================

  Widget _buildDocumentCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required String? number,
    required String? expiry,
  }) {
    final safeNumber =
    number == null || number.trim().isEmpty
        ? 'N/A'
        : number.trim();

    final safeExpiry =
    expiry == null || expiry.trim().isEmpty
        ? 'N/A'
        : expiry.trim();

    final statusColor =
    _expiryColor(expiry);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color:
          accentColor.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color:
                  accentColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    9,
                  ),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _detailRow(
            'Number',
            safeNumber,
          ),

          const SizedBox(height: 10),

          _detailRow(
            'Expiry',
            safeExpiry,
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color:
              statusColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(8),
              border: Border.all(
                color:
                statusColor.withValues(
                  alpha: 0.30,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: statusColor,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _expiryStatus(expiry),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
      String label,
      String value,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
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
            value,
            style: const TextStyle(
              color: offWhite,
              fontSize: 14,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),
      ],
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
          borderRadius:
          BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.white
                .withValues(alpha: 0.12),
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(10),
          borderSide:
          const BorderSide(
            color:
            electricYellowGreen,
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
        _pickDate(
          context,
          controller,
        );
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
          onPressed: () {
            controller.clear();
          },
          icon: const Icon(
            Icons.clear,
            color: Colors.white38,
          ),
        ),
        filled: true,
        fillColor: deepNavy,
        enabledBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.white
                .withValues(alpha: 0.12),
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(10),
          borderSide:
          const BorderSide(
            color:
            electricYellowGreen,
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
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: _employeeRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: deepNavy,
            body: Center(
              child:
              CircularProgressIndicator(
                color:
                electricYellowGreen,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: deepNavy,
            appBar: AppBar(
              backgroundColor: deepNavy,
              iconTheme:
              const IconThemeData(
                color: offWhite,
              ),
            ),
            body: Center(
              child: Padding(
                padding:
                const EdgeInsets.all(
                  20,
                ),
                child: Text(
                  'Error loading employee:\n${snapshot.error}',
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    color:
                    Colors.redAccent,
                  ),
                ),
              ),
            ),
          );
        }

        Map<String, dynamic> data;

        if (snapshot.hasData &&
            snapshot.data!.exists &&
            snapshot.data!.data() !=
                null) {
          data =
          snapshot.data!.data()!;
        } else {
          data =
              widget.employeeData;
        }

        final employeeName =
            data['employeeName']
                ?.toString() ??
                'Employee Details';

        final visaNumber =
        data['visaNumber']
            ?.toString();

        final visaExpiry =
        data['visaExpiry']
            ?.toString();

        final laborCardNumber =
        data['laborCardNumber']
            ?.toString();

        final laborExpiry =
        data['laborExpiry']
            ?.toString();

        final ohcCardNumber =
        data['ohcCardNumber']
            ?.toString();

        final ohcExpiry =
        data['ohcExpiry']
            ?.toString();

        return Scaffold(
          backgroundColor: deepNavy,

          appBar: AppBar(
            backgroundColor: deepNavy,
            elevation: 0,
            iconTheme:
            const IconThemeData(
              color: offWhite,
            ),

            title: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  employeeName,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color: offWhite,
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const Text(
                  'Employee Details',
                  style: TextStyle(
                    color:
                    Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),

            actions: [
              IconButton(
                tooltip: 'Edit Employee',
                onPressed: () {
                  _showEditEmployeeDialog(
                    data,
                  );
                },
                icon: const Icon(
                  Icons.edit_outlined,
                  color:
                  electricYellowGreen,
                ),
              ),

              IconButton(
                tooltip:
                'Delete Employee',
                onPressed: () {
                  _deleteEmployee(
                    employeeName,
                  );
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color:
                  Colors.redAccent,
                ),
              ),

              const SizedBox(width: 6),
            ],
          ),

          body:
          SingleChildScrollView(
            padding:
            const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              40,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // ==============================================
                // EMPLOYEE HEADER
                // ==============================================

                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(
                    20,
                  ),
                  decoration:
                  BoxDecoration(
                    color: cardBg,
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                    border:
                    Border.all(
                      color:
                      electricYellowGreen
                          .withValues(
                        alpha: 0.25,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration:
                        BoxDecoration(
                          color:
                          electricYellowGreen
                              .withValues(
                            alpha: 0.12,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            14,
                          ),
                        ),
                        child:
                        const Icon(
                          Icons.person,
                          color:
                          electricYellowGreen,
                          size: 32,
                        ),
                      ),

                      const SizedBox(
                        width: 16,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              employeeName,
                              style:
                              const TextStyle(
                                color:
                                offWhite,
                                fontSize: 20,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            Text(
                              data['companyName']
                                  ?.toString() ??
                                  'Company Employee',
                              style:
                              const TextStyle(
                                color:
                                Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        tooltip:
                        'Edit Employee',
                        onPressed: () {
                          _showEditEmployeeDialog(
                            data,
                          );
                        },
                        icon: const Icon(
                          Icons.edit,
                          color:
                          electricYellowGreen,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                const Text(
                  'Document Information',
                  style: TextStyle(
                    color: offWhite,
                    fontSize: 20,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                // ==============================================
                // VISA
                // ==============================================

                _buildDocumentCard(
                  title:
                  'Visa Information',
                  icon:
                  Icons.badge_outlined,
                  accentColor:
                  electricYellowGreen,
                  number: visaNumber,
                  expiry: visaExpiry,
                ),

                const SizedBox(
                  height: 14,
                ),

                // ==============================================
                // LABOR CARD
                // ==============================================

                _buildDocumentCard(
                  title:
                  'Labor Card Information',
                  icon:
                  Icons.work_outline,
                  accentColor:
                  Colors.orangeAccent,
                  number:
                  laborCardNumber,
                  expiry:
                  laborExpiry,
                ),

                const SizedBox(
                  height: 14,
                ),

                // ==============================================
                // OHC CARD
                // ==============================================

                _buildDocumentCard(
                  title:
                  'OHC Card Information',
                  icon: Icons
                      .health_and_safety_outlined,
                  accentColor:
                  Colors.cyanAccent,
                  number:
                  ohcCardNumber,
                  expiry: ohcExpiry,
                ),

                const SizedBox(
                  height: 25,
                ),

                // ==============================================
                // EDIT BUTTON
                // ==============================================

                SizedBox(
                  width: double.infinity,
                  child:
                  ElevatedButton.icon(
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      electricYellowGreen,
                      foregroundColor:
                      deepNavy,
                      padding:
                      const EdgeInsets
                          .symmetric(
                        vertical: 15,
                      ),
                    ),

                    onPressed: () {
                      _showEditEmployeeDialog(
                        data,
                      );
                    },

                    icon: const Icon(
                      Icons.edit_outlined,
                    ),

                    label: const Text(
                      'EDIT EMPLOYEE',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}