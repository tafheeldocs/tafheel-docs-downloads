import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'employee_detail_screen.dart';

class CompanyPortalScreen extends StatelessWidget {
  final String companyId;

  const CompanyPortalScreen({
    super.key,
    required this.companyId,
  });

  static const Color deepNavy = Color(0xFF0D1B2A);
  static const Color offWhite = Color(0xFFF0EDE8);
  static const Color electricYellowGreen = Color(0xFFC8F500);
  static const Color cardBg = Color(0xFF16222D);

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    try {
      return DateTime.parse(
        value.toString().trim(),
      );
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

  String _expiryStatus(dynamic value) {
    final expiry = _parseDate(value);

    if (expiry == null) {
      return 'No expiry date';
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
      return 'EXPIRED';
    }

    if (days == 0) {
      return 'EXPIRES TODAY';
    }

    if (days == 1) {
      return '1 DAY LEFT';
    }

    if (days <= 30) {
      return '$days DAYS LEFT';
    }

    return 'VALID';
  }

  String _safe(dynamic value) {
    if (value == null) {
      return 'N/A';
    }

    final text = value.toString().trim();

    return text.isEmpty ? 'N/A' : text;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(
      BuildContext context,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardBg,
          title: const Text(
            'Logout?',
            style: TextStyle(
              color: offWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
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
                electricYellowGreen,
                foregroundColor:
                deepNavy,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              icon: const Icon(
                Icons.logout,
              ),
              label: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await FirebaseAuth.instance.signOut();
  }

  // ============================================================
  // DOCUMENT CARD
  // ============================================================

  Widget _documentCard({
    required IconData icon,
    required String title,
    required String number,
    required dynamic expiry,
  }) {
    final color =
    _expiryColor(expiry);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.12,
              ),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: offWhite,
                    fontSize: 15,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'No: ${_safe(number)}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Expiry: ${_dateText(expiry)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.12,
              ),
              borderRadius:
              BorderRadius.circular(20),
            ),
            child: Text(
              _expiryStatus(expiry),
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _informationRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
            electricYellowGreen,
            size: 18,
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),

          Expanded(
            child: Text(
              _safe(value),
              style: const TextStyle(
                color: offWhite,
                fontSize: 12,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPLOYEE CARD
  // ============================================================

  Widget _employeeCard(
      BuildContext context,
      QueryDocumentSnapshot<
          Map<String, dynamic>>
      employeeDoc,
      String companyName,
      ) {
    final data =
    employeeDoc.data();

    final employeeName =
    _safe(data['employeeName']);

    final visaExpiry =
    data['visaExpiry'];

    final laborExpiry =
    data['laborExpiry'];

    final ohcExpiry =
    data['ohcExpiry'];

    return Card(
      color: cardBg,
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(14),
        onTap: () {
          final detailData =
          Map<String, dynamic>.from(
            data,
          );

          detailData['companyName'] =
              companyName;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EmployeeDetailScreen(
                    companyId: companyId,
                    employeeId:
                    employeeDoc.id,
                    employeeData:
                    detailData,
                  ),
            ),
          );
        },
        child: Padding(
          padding:
          const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor:
                    electricYellowGreen,
                    child: Icon(
                      Icons.person,
                      color: deepNavy,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
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
                            fontSize:
                            15,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          'Visa No: ${_safe(data['visaNumber'])}',
                          style:
                          const TextStyle(
                            color: Colors
                                .white54,
                            fontSize:
                            11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    color:
                    Colors.white38,
                    size: 15,
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              Divider(
                color: Colors.white
                    .withValues(
                  alpha: 0.08,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              _employeeExpiryRow(
                'Visa',
                visaExpiry,
              ),

              _employeeExpiryRow(
                'Labor Card',
                laborExpiry,
              ),

              _employeeExpiryRow(
                'OHC Card',
                ohcExpiry,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _employeeExpiryRow(
      String title,
      dynamic expiry,
      ) {
    final color =
    _expiryColor(expiry);

    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ),

          Expanded(
            child: Text(
              _dateText(expiry),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),

          Text(
            _expiryStatus(expiry),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight:
              FontWeight.bold,
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
    return StreamBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
      stream: FirebaseFirestore
          .instance
          .collection('companies')
          .doc(companyId)
          .snapshots(),

      builder: (
          context,
          companySnapshot,
          ) {
        if (companySnapshot
            .connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor:
            deepNavy,
            body: Center(
              child:
              CircularProgressIndicator(
                color:
                electricYellowGreen,
              ),
            ),
          );
        }

        if (companySnapshot.hasError) {
          return Scaffold(
            backgroundColor:
            deepNavy,
            body: Center(
              child: Text(
                'Company loading error:\n${companySnapshot.error}',
                textAlign:
                TextAlign.center,
                style: const TextStyle(
                  color:
                  Colors.redAccent,
                ),
              ),
            ),
          );
        }

        if (!companySnapshot
            .hasData ||
            !companySnapshot
                .data!.exists) {
          return Scaffold(
            backgroundColor:
            deepNavy,
            appBar: AppBar(
              backgroundColor:
              deepNavy,
              foregroundColor:
              offWhite,
              actions: [
                IconButton(
                  onPressed: () {
                    _logout(context);
                  },
                  icon: const Icon(
                    Icons.logout,
                  ),
                ),
              ],
            ),
            body: const Center(
              child: Text(
                'Company account not found.',
                style: TextStyle(
                  color: offWhite,
                ),
              ),
            ),
          );
        }

        final companyData =
            companySnapshot.data!
                .data() ??
                {};

        final companyName =
        _safe(
          companyData['companyName'],
        );

        return Scaffold(
          backgroundColor: deepNavy,

          appBar: AppBar(
            backgroundColor: deepNavy,
            foregroundColor: offWhite,
            elevation: 0,
            title: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                const Text(
                  'TAFHEEL DOCS',
                  style: TextStyle(
                    color:
                    electricYellowGreen,
                    fontSize: 11,
                    fontWeight:
                    FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  companyName,
                  style:
                  const TextStyle(
                    color: offWhite,
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Logout',
                onPressed: () {
                  _logout(context);
                },
                icon: const Icon(
                  Icons.logout,
                  color:
                  Colors.redAccent,
                ),
              ),
              const SizedBox(
                width: 5,
              ),
            ],
          ),

          body:
          SingleChildScrollView(
            padding:
            const EdgeInsets.fromLTRB(
              16,
              10,
              16,
              30,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // ================================================
                // WELCOME
                // ================================================

                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(
                    20,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    electricYellowGreen,
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      const Text(
                        'COMPANY PORTAL',
                        style:
                        TextStyle(
                          color:
                          deepNavy,
                          fontSize:
                          11,
                          fontWeight:
                          FontWeight
                              .bold,
                          letterSpacing:
                          1.2,
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      Text(
                        companyName,
                        style:
                        const TextStyle(
                          color:
                          deepNavy,
                          fontSize:
                          22,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      const Text(
                        'Company documents & employee expiry information',
                        style:
                        TextStyle(
                          color:
                          deepNavy,
                          fontSize:
                          12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                const Text(
                  'Company Information',
                  style: TextStyle(
                    color: offWhite,
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(
                    16,
                  ),
                  decoration:
                  BoxDecoration(
                    color: cardBg,
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Column(
                    children: [
                      _informationRow(
                        Icons
                            .person_outline,
                        'Authorized',
                        _safe(
                          companyData[
                          'authorizedPerson'],
                        ),
                      ),

                      _informationRow(
                        Icons.phone_outlined,
                        'Mobile',
                        _safe(
                          companyData[
                          'mobile'],
                        ),
                      ),

                      _informationRow(
                        Icons.email_outlined,
                        'Email',
                        _safe(
                          companyData[
                          'email'],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                const Text(
                  'Company Documents',
                  style: TextStyle(
                    color: offWhite,
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                _documentCard(
                  icon:
                  Icons.business_center,
                  title:
                  'Trade License',
                  number: _safe(
                    companyData[
                    'tradeLicense'],
                  ),
                  expiry:
                  companyData[
                  'tradeExpiry'],
                ),

                _documentCard(
                  icon:
                  Icons.home_work_outlined,
                  title:
                  'Tenancy Contract',
                  number: _safe(
                    companyData[
                    'tenancy'],
                  ),
                  expiry:
                  companyData[
                  'tenancyExpiry'],
                ),

                _documentCard(
                  icon: Icons
                      .account_balance_wallet_outlined,
                  title:
                  'Establishment Card',
                  number: _safe(
                    companyData[
                    'establishmentCard'],
                  ),
                  expiry:
                  companyData[
                  'establishmentExpiry'],
                ),

                const SizedBox(
                  height: 15,
                ),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Employees',
                        style:
                        TextStyle(
                          color:
                          offWhite,
                          fontSize:
                          18,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                    ),

                    StreamBuilder<
                        QuerySnapshot<
                            Map<String,
                                dynamic>>>(
                      stream:
                      FirebaseFirestore
                          .instance
                          .collection(
                          'companies')
                          .doc(
                          companyId)
                          .collection(
                          'employees')
                          .snapshots(),
                      builder:
                          (
                          context,
                          snapshot,
                          ) {
                        final count =
                            snapshot
                                .data
                                ?.docs
                                .length ??
                                0;

                        return Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal:
                            10,
                            vertical: 5,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            electricYellowGreen
                                .withValues(
                              alpha:
                              0.12,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              20,
                            ),
                          ),
                          child: Text(
                            '$count Employees',
                            style:
                            const TextStyle(
                              color:
                              electricYellowGreen,
                              fontSize:
                              10,
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(
                  height: 10,
                ),

                // ================================================
                // ONLY THIS COMPANY'S EMPLOYEES
                // ================================================

                StreamBuilder<
                    QuerySnapshot<
                        Map<String,
                            dynamic>>>(
                  stream:
                  FirebaseFirestore
                      .instance
                      .collection(
                      'companies')
                      .doc(companyId)
                      .collection(
                      'employees')
                      .snapshots(),

                  builder:
                      (
                      context,
                      snapshot,
                      ) {
                    if (snapshot
                        .connectionState ==
                        ConnectionState
                            .waiting) {
                      return const Padding(
                        padding:
                        EdgeInsets.all(
                          30,
                        ),
                        child: Center(
                          child:
                          CircularProgressIndicator(
                            color:
                            electricYellowGreen,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding:
                        const EdgeInsets
                            .all(
                          20,
                        ),
                        child: Text(
                          'Employee loading error: ${snapshot.error}',
                          style:
                          const TextStyle(
                            color: Colors
                                .redAccent,
                          ),
                        ),
                      );
                    }

                    final employees =
                    [
                      ...?snapshot
                          .data?.docs,
                    ];

                    employees.sort(
                          (a, b) {
                        final aValue =
                        a.data()[
                        'createdAt'];

                        final bValue =
                        b.data()[
                        'createdAt'];

                        final aTime =
                        aValue
                        is Timestamp
                            ? aValue
                            .millisecondsSinceEpoch
                            : 0;

                        final bTime =
                        bValue
                        is Timestamp
                            ? bValue
                            .millisecondsSinceEpoch
                            : 0;

                        return bTime
                            .compareTo(
                          aTime,
                        );
                      },
                    );

                    if (employees
                        .isEmpty) {
                      return Container(
                        width:
                        double.infinity,
                        padding:
                        const EdgeInsets
                            .all(
                          30,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          cardBg,
                          borderRadius:
                          BorderRadius
                              .circular(
                            14,
                          ),
                        ),
                        child:
                        const Column(
                          children: [
                            Icon(
                              Icons
                                  .people_outline,
                              color:
                              electricYellowGreen,
                              size:
                              45,
                            ),
                            SizedBox(
                              height:
                              10,
                            ),
                            Text(
                              'No employees found',
                              style:
                              TextStyle(
                                color:
                                offWhite,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children:
                      employees.map(
                            (employeeDoc) {
                          return _employeeCard(
                            context,
                            employeeDoc,
                            companyName,
                          );
                        },
                      ).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}