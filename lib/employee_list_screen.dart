import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'employee_detail_screen.dart';
import 'company_detail_screen.dart';
import 'manual_reminder_screen.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  // ============================================================
  // COLORS
  // ============================================================

  static const Color deepNavy = Color(0xFF0D1B2A);
  static const Color offWhite = Color(0xFFF0EDE8);
  static const Color electricYellowGreen = Color(0xFFC8F500);
  static const Color cardBg = Color(0xFF16222D);
  static const Color dialogBg = Color(0xFF1B2A38);

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    try {
      return DateTime.parse(text);
    } catch (_) {
      return null;
    }
  }

  String _dateText(dynamic value) {
    final date = _parseDate(value);

    if (date == null) {
      return 'N/A';
    }

    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Color _expiryColor(dynamic value) {
    final expiry = _parseDate(value);

    if (expiry == null) {
      return Colors.white54;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final expiryOnly = DateTime(
      expiry.year,
      expiry.month,
      expiry.day,
    );

    final days =
        expiryOnly.difference(today).inDays;

    if (days < 0) {
      return Colors.redAccent;
    }

    if (days <= 30) {
      return Colors.orangeAccent;
    }

    return Colors.greenAccent;
  }

  String _expiryLabel(dynamic value) {
    final expiry = _parseDate(value);

    if (expiry == null) {
      return 'N/A';
    }

    final formatted = _dateText(value);

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final expiryOnly = DateTime(
      expiry.year,
      expiry.month,
      expiry.day,
    );

    final days =
        expiryOnly.difference(today).inDays;

    if (days < 0) {
      return '$formatted • EXPIRED';
    }

    if (days == 0) {
      return '$formatted • EXPIRES TODAY';
    }

    if (days == 1) {
      return '$formatted • 1 DAY LEFT';
    }

    if (days <= 30) {
      return '$formatted • $days DAYS LEFT';
    }

    return formatted;
  }

  int _createdAtMilliseconds(
      Map<String, dynamic> data,
      ) {
    final createdAt = data['createdAt'];

    if (createdAt is Timestamp) {
      return createdAt.millisecondsSinceEpoch;
    }

    if (createdAt is DateTime) {
      return createdAt.millisecondsSinceEpoch;
    }

    try {
      return DateTime.parse(
        createdAt.toString(),
      ).millisecondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  }

  String _safeValue(dynamic value) {
    if (value == null) {
      return 'N/A';
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return 'N/A';
    }

    return text;
  }

  // ============================================================
  // COMPANY NAME
  // ============================================================

  Future<String> _getCompanyName(
      String companyId,
      Map<String, dynamic> employeeData,
      ) async {
    final savedCompanyName =
    employeeData['companyName']
        ?.toString()
        .trim();

    if (savedCompanyName != null &&
        savedCompanyName.isNotEmpty) {
      return savedCompanyName;
    }

    if (companyId.isEmpty) {
      return 'Unknown Company';
    }

    try {
      final snapshot =
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .get();

      final data = snapshot.data();

      if (data == null) {
        return 'Unknown Company';
      }

      final companyName =
      data['companyName']
          ?.toString()
          .trim();

      if (companyName == null ||
          companyName.isEmpty) {
        return 'Unknown Company';
      }

      return companyName;
    } catch (_) {
      return 'Unknown Company';
    }
  }

  // ============================================================
  // OPEN EMPLOYEE DETAILS
  // ============================================================

  void _openEmployeeDetails(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>>
      employeeDoc,
      ) {
    final companyReference =
        employeeDoc.reference.parent.parent;

    if (companyReference == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This employee is not linked to a company.',
          ),
        ),
      );

      return;
    }

    final data = employeeDoc.data();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeDetailScreen(
          companyId: companyReference.id,
          employeeId: employeeDoc.id,
          employeeData: data,
        ),
      ),
    );
  }

  // ============================================================
  // DELETE EMPLOYEE
  // ============================================================

  Future<void> _deleteEmployee(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>>
      employeeDoc,
      String employeeName,
      ) async {
    final confirmed =
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
            'Are you sure you want to permanently delete "$employeeName"?',
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
                foregroundColor:
                Colors.white,
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
              label: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await employeeDoc.reference.delete();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '$employeeName deleted successfully',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

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
  // REMINDER
  // ============================================================

  Future<void> _openReminder(
      BuildContext context,
      Map<String, dynamic> employeeData,
      String employeeName,
      String companyId,
      ) async {
    String mobile =
        employeeData['mobile']
            ?.toString()
            .trim() ??
            '';

    String email =
        employeeData['email']
            ?.toString()
            .trim() ??
            '';

    // If employee mobile/email is empty,
    // use company mobile/email.
    if (companyId.isNotEmpty &&
        (mobile.isEmpty || email.isEmpty)) {
      try {
        final companySnapshot =
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .get();

        final companyData =
        companySnapshot.data();

        if (companyData != null) {
          if (mobile.isEmpty) {
            mobile =
                companyData['mobile']
                    ?.toString()
                    .trim() ??
                    '';
          }

          if (email.isEmpty) {
            email =
                companyData['email']
                    ?.toString()
                    .trim() ??
                    '';
          }
        }
      } catch (_) {}
    }

    if (!context.mounted) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: dialogBg,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding:
              const EdgeInsets.all(20),
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color:
                    electricYellowGreen,
                    size: 38,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    employeeName,
                    textAlign:
                    TextAlign.center,
                    style:
                    const TextStyle(
                      color: offWhite,
                      fontSize: 17,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Select Document Reminder',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _documentButton(
                    rootContext: context,
                    sheetContext:
                    sheetContext,
                    icon:
                    Icons.badge_outlined,
                    title: 'Visa',
                    documentNumber:
                    employeeData[
                    'visaNumber']
                        ?.toString() ??
                        '',
                    expiry: employeeData[
                    'visaExpiry']
                        ?.toString() ??
                        '',
                    employeeName:
                    employeeName,
                    mobile: mobile,
                    email: email,
                  ),

                  _documentButton(
                    rootContext: context,
                    sheetContext:
                    sheetContext,
                    icon:
                    Icons.credit_card,
                    title: 'Labor Card',
                    documentNumber:
                    employeeData[
                    'laborCardNumber']
                        ?.toString() ??
                        '',
                    expiry: employeeData[
                    'laborExpiry']
                        ?.toString() ??
                        '',
                    employeeName:
                    employeeName,
                    mobile: mobile,
                    email: email,
                  ),

                  _documentButton(
                    rootContext: context,
                    sheetContext:
                    sheetContext,
                    icon: Icons
                        .health_and_safety_outlined,
                    title: 'OHC Card',
                    documentNumber:
                    employeeData[
                    'ohcCardNumber']
                        ?.toString() ??
                        '',
                    expiry: employeeData[
                    'ohcExpiry']
                        ?.toString() ??
                        '',
                    employeeName:
                    employeeName,
                    mobile: mobile,
                    email: email,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _documentButton({
    required BuildContext rootContext,
    required BuildContext sheetContext,
    required IconData icon,
    required String title,
    required String documentNumber,
    required String expiry,
    required String employeeName,
    required String mobile,
    required String email,
  }) {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: cardBg,
          foregroundColor: Colors.white,
          padding:
          const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 14,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              10,
            ),
          ),
        ),
        onPressed: () {
          Navigator.pop(sheetContext);

          Navigator.push(
            rootContext,
            MaterialPageRoute(
              builder: (_) =>
                  ManualReminderScreen(
                    type: 'Employee',
                    referenceName:
                    employeeName,
                    phone: mobile,
                    email: email,
                    documentType: title,
                    documentNumber:
                    documentNumber,
                    expiryDate: expiry,
                  ),
            ),
          );
        },
        child: Row(
          children: [
            Icon(
              icon,
              color:
              electricYellowGreen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style:
                const TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
            Text(
              expiry.trim().isEmpty
                  ? 'N/A'
                  : expiry,
              style: TextStyle(
                color:
                _expiryColor(expiry),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons
                  .arrow_forward_ios_rounded,
              color: Colors.white38,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SELECT COMPANY FOR ADD EMPLOYEE
  // ============================================================

  void _showCompanySelector(
      BuildContext context,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: dialogBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Select Company',
                          style:
                          TextStyle(
                            color:
                            offWhite,
                            fontSize: 20,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                          );
                        },
                        icon: const Icon(
                          Icons.close,
                          color:
                          Colors.white54,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Select a company to add a new employee.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Expanded(
                    child: StreamBuilder<
                        QuerySnapshot<
                            Map<String,
                                dynamic>>>(
                      stream:
                      FirebaseFirestore
                          .instance
                          .collection(
                          'companies')
                          .snapshots(),
                      builder: (
                          context,
                          snapshot,
                          ) {
                        if (snapshot
                            .connectionState ==
                            ConnectionState
                                .waiting) {
                          return const Center(
                            child:
                            CircularProgressIndicator(
                              color:
                              electricYellowGreen,
                            ),
                          );
                        }

                        if (snapshot
                            .hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style:
                              const TextStyle(
                                color: Colors
                                    .redAccent,
                              ),
                            ),
                          );
                        }

                        final companies =
                        [
                          ...?snapshot
                              .data?.docs,
                        ];

                        companies.sort(
                              (a, b) {
                            final aName =
                                a.data()[
                                'companyName']
                                    ?.toString()
                                    .toLowerCase() ??
                                    '';

                            final bName =
                                b.data()[
                                'companyName']
                                    ?.toString()
                                    .toLowerCase() ??
                                    '';

                            return aName
                                .compareTo(
                              bName,
                            );
                          },
                        );

                        if (companies
                            .isEmpty) {
                          return const Center(
                            child: Text(
                              'No companies found.\nAdd a company first.',
                              textAlign:
                              TextAlign
                                  .center,
                              style:
                              TextStyle(
                                color: Colors
                                    .white54,
                              ),
                            ),
                          );
                        }

                        return ListView
                            .builder(
                          itemCount:
                          companies
                              .length,
                          itemBuilder:
                              (
                              context,
                              index,
                              ) {
                            final company =
                            companies[
                            index];

                            final data =
                            company
                                .data();

                            final companyName =
                                data['companyName']
                                    ?.toString() ??
                                    'Unknown Company';

                            return Container(
                              margin:
                              const EdgeInsets
                                  .only(
                                bottom:
                                10,
                              ),
                              decoration:
                              BoxDecoration(
                                color:
                                cardBg,
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  12,
                                ),
                              ),
                              child:
                              ListTile(
                                leading:
                                const CircleAvatar(
                                  backgroundColor:
                                  electricYellowGreen,
                                  child:
                                  Icon(
                                    Icons
                                        .business,
                                    color:
                                    deepNavy,
                                  ),
                                ),
                                title:
                                Text(
                                  companyName,
                                  style:
                                  const TextStyle(
                                    color:
                                    offWhite,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),
                                subtitle:
                                Text(
                                  'Trade License: ${_safeValue(data['tradeLicense'])}',
                                  style:
                                  const TextStyle(
                                    color: Colors
                                        .white54,
                                    fontSize:
                                    11,
                                  ),
                                ),
                                trailing:
                                const Icon(
                                  Icons
                                      .arrow_forward_ios_rounded,
                                  color: Colors
                                      .white38,
                                  size: 15,
                                ),
                                onTap: () {
                                  Navigator.pop(
                                    sheetContext,
                                  );

                                  Navigator
                                      .push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                          CompanyDetailScreen(
                                            companyId:
                                            company.id,
                                            companyName:
                                            companyName,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // EMPLOYEE CARD
  // ============================================================

  Widget _employeeCard(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>>
      employeeDoc,
      ) {
    final data = employeeDoc.data();

    final employeeName =
    _safeValue(
      data['employeeName'],
    );

    final companyReference =
        employeeDoc.reference.parent.parent;

    final companyId =
        companyReference?.id ?? '';

    final visaNumber =
    _safeValue(
      data['visaNumber'],
    );

    final visaExpiry =
    data['visaExpiry'];

    final laborCardNumber =
    _safeValue(
      data['laborCardNumber'],
    );

    final laborExpiry =
    data['laborExpiry'];

    final ohcCardNumber =
    _safeValue(
      data['ohcCardNumber'],
    );

    final ohcExpiry =
    data['ohcExpiry'];

    return Card(
      color: cardBg,
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.white
              .withValues(alpha: 0.07),
        ),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(14),
        onTap: () {
          _openEmployeeDetails(
            context,
            employeeDoc,
          );
        },
        child: Padding(
          padding:
          const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // =================================================
              // HEADER
              // =================================================

              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration:
                    BoxDecoration(
                      color:
                      electricYellowGreen
                          .withValues(
                        alpha: 0.12,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      color:
                      electricYellowGreen,
                    ),
                  ),

                  const SizedBox(width: 13),

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
                            fontSize:
                            16,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        FutureBuilder<
                            String>(
                          future:
                          _getCompanyName(
                            companyId,
                            data,
                          ),
                          builder:
                              (
                              context,
                              snapshot,
                              ) {
                            return Row(
                              children: [
                                const Icon(
                                  Icons
                                      .business_outlined,
                                  color: Colors
                                      .white38,
                                  size: 14,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  child: Text(
                                    snapshot.data ??
                                        data['companyName']
                                            ?.toString() ??
                                        'Loading company...',
                                    style:
                                    const TextStyle(
                                      color: Colors
                                          .white54,
                                      fontSize:
                                      11,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // REMINDER
                  IconButton(
                    tooltip:
                    'Expiry Reminder',
                    onPressed: () {
                      _openReminder(
                        context,
                        data,
                        employeeName,
                        companyId,
                      );
                    },
                    icon: const Icon(
                      Icons
                          .notifications_active_outlined,
                      color:
                      Colors.orangeAccent,
                      size: 21,
                    ),
                  ),

                  // EDIT / OPEN
                  IconButton(
                    tooltip:
                    'Edit Employee',
                    onPressed: () {
                      _openEmployeeDetails(
                        context,
                        employeeDoc,
                      );
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                      color:
                      electricYellowGreen,
                      size: 21,
                    ),
                  ),

                  // DELETE
                  IconButton(
                    tooltip:
                    'Delete Employee',
                    onPressed: () {
                      _deleteEmployee(
                        context,
                        employeeDoc,
                        employeeName,
                      );
                    },
                    icon: const Icon(
                      Icons
                          .delete_outline,
                      color:
                      Colors.redAccent,
                      size: 21,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Divider(
                height: 1,
                color: Colors.white
                    .withValues(
                  alpha: 0.07,
                ),
              ),

              const SizedBox(height: 13),

              // =================================================
              // VISA
              // =================================================

              _documentRow(
                icon:
                Icons.badge_outlined,
                title: 'Visa',
                number: visaNumber,
                expiry:
                _expiryLabel(
                  visaExpiry,
                ),
                color:
                _expiryColor(
                  visaExpiry,
                ),
              ),

              const SizedBox(height: 10),

              // =================================================
              // LABOR
              // =================================================

              _documentRow(
                icon:
                Icons.work_outline,
                title: 'Labor Card',
                number:
                laborCardNumber,
                expiry:
                _expiryLabel(
                  laborExpiry,
                ),
                color:
                _expiryColor(
                  laborExpiry,
                ),
              ),

              const SizedBox(height: 10),

              // =================================================
              // OHC
              // =================================================

              _documentRow(
                icon: Icons
                    .health_and_safety_outlined,
                title: 'OHC Card',
                number:
                ohcCardNumber,
                expiry:
                _expiryLabel(
                  ohcExpiry,
                ),
                color:
                _expiryColor(
                  ohcExpiry,
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment:
                Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    _openEmployeeDetails(
                      context,
                      employeeDoc,
                    );
                  },
                  icon: const Icon(
                    Icons
                        .arrow_forward_rounded,
                    size: 17,
                  ),
                  label: const Text(
                    'View Details / Edit',
                  ),
                  style:
                  TextButton.styleFrom(
                    foregroundColor:
                    electricYellowGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _documentRow({
    required IconData icon,
    required String title,
    required String number,
    required String expiry,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 18,
        ),

        const SizedBox(width: 9),

        SizedBox(
          width: 82,
          child: Text(
            title,
            style:
            const TextStyle(
              color: Colors.white70,
              fontWeight:
              FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'No: $number',
                style:
                const TextStyle(
                  color: offWhite,
                  fontSize: 12,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                'Expiry: $expiry',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
        elevation: 0,
        title: const Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Employee Information',
              style: TextStyle(
                color: offWhite,
                fontWeight:
                FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'All Company Employees',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add Employee',
            onPressed: () {
              _showCompanySelector(
                context,
              );
            },
            icon: const Icon(
              Icons.person_add_alt_1,
              color:
              electricYellowGreen,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        backgroundColor:
        electricYellowGreen,
        foregroundColor: deepNavy,
        onPressed: () {
          _showCompanySelector(
            context,
          );
        },
        icon: const Icon(
          Icons.person_add_alt_1,
        ),
        label: const Text(
          'Add Employee',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: FirebaseFirestore
            .instance
            .collectionGroup('employees')
            .snapshots(),

        builder: (
            context,
            snapshot,
            ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(
                color:
                electricYellowGreen,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                const EdgeInsets.all(
                  24,
                ),
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color:
                      Colors.redAccent,
                      size: 50,
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    const Text(
                      'Error loading employees',
                      style:
                      TextStyle(
                        color: Colors
                            .redAccent,
                        fontSize: 17,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      '${snapshot.error}',
                      textAlign:
                      TextAlign.center,
                      style:
                      const TextStyle(
                        color: Colors
                            .white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // =====================================================
          // ONLY COMPANY SUBCOLLECTION EMPLOYEES
          // =====================================================

          final employees = [
            ...?snapshot.data?.docs,
          ].where(
                (doc) =>
            doc.reference.parent.parent !=
                null,
          ).toList();

          // Sort latest employees first
          employees.sort(
                (a, b) {
              final aTime =
              _createdAtMilliseconds(
                a.data(),
              );

              final bTime =
              _createdAtMilliseconds(
                b.data(),
              );

              return bTime.compareTo(
                aTime,
              );
            },
          );

          if (employees.isEmpty) {
            return Center(
              child: Padding(
                padding:
                const EdgeInsets.all(
                  24,
                ),
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      color:
                      electricYellowGreen,
                      size: 70,
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    const Text(
                      'No employees found',
                      style:
                      TextStyle(
                        color: offWhite,
                        fontSize: 18,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'Employees added inside companies will appear here.',
                      textAlign:
                      TextAlign.center,
                      style:
                      TextStyle(
                        color: Colors
                            .white54,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    ElevatedButton.icon(
                      style: ElevatedButton
                          .styleFrom(
                        backgroundColor:
                        electricYellowGreen,
                        foregroundColor:
                        deepNavy,
                      ),
                      onPressed: () {
                        _showCompanySelector(
                          context,
                        );
                      },
                      icon: const Icon(
                        Icons.person_add,
                      ),
                      label:
                      const Text(
                        'Add Employee',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding:
            const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              95,
            ),
            itemCount:
            employees.length,
            itemBuilder: (
                context,
                index,
                ) {
              return _employeeCard(
                context,
                employees[index],
              );
            },
          );
        },
      ),
    );
  }
}