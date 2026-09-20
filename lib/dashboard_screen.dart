import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'company_list_screen.dart';
import 'company_detail_screen.dart';
import 'employee_list_screen.dart';
import 'employee_detail_screen.dart';
import 'work_follow_up_screen.dart';
import 'notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color deepNavy = Color(0xFF0D1B2A);
  static const Color offWhite = Color(0xFFF0EDE8);
  static const Color electricYellowGreen = Color(0xFFC8F500);
  static const Color cardBg = Color(0xFF16222D);
  static const Color dialogBg = Color(0xFF1B2A38);

  // ============================================================
  // GLOBAL SEARCH
  // ============================================================

  final TextEditingController _searchController =
  TextEditingController();

  String _searchText = '';

  // ============================================================
  // STATUS OPTIONS
  // ============================================================

  static const List<String> statusOptions = [
    'Under Process',
    'Approval',
    'Return for Modification',
    'Rejected',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATE CHECK
  // ============================================================

  bool _isExpiredOrWithin30Days(String? dateText) {
    if (dateText == null || dateText.trim().isEmpty) {
      return false;
    }

    try {
      final expiryDate = DateTime.parse(dateText.trim());

      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      final difference = expiryDate.difference(today).inDays;

      return difference <= 30;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // DATE SORT
  // ============================================================

  int _compareExpiryDates(String a, String b) {
    try {
      final dateA = DateTime.parse(a);
      final dateB = DateTime.parse(b);

      return dateA.compareTo(dateB);
    } catch (_) {
      return 0;
    }
  }

  // ============================================================
  // GLOBAL SEARCH MATCH
  // ============================================================

  bool _matchesSearch(String text) {
    if (_searchText.trim().isEmpty) {
      return true;
    }

    return text.toLowerCase().contains(
      _searchText.trim().toLowerCase(),
    );
  }

  // ============================================================
  // ADD APPLICATION
  // ============================================================

  void _showAddApplicationDialog(BuildContext context) {
    final appNumberController = TextEditingController();
    final appTypeController = TextEditingController();
    final clientNameController = TextEditingController();

    String selectedStatus = 'Under Process';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              title: const Text(
                'Add Application Tracker',
                style: TextStyle(
                  color: offWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: appNumberController,
                        label: 'Application Number',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: appTypeController,
                        label: 'Application Type',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: clientNameController,
                        label: 'Company / Client Name',
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Application Status',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...statusOptions.map(
                            (status) {
                          return RadioListTile<String>(
                            value: status,
                            groupValue: selectedStatus,
                            activeColor: electricYellowGreen,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedStatus = value;
                                });
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: electricYellowGreen,
                    foregroundColor: deepNavy,
                  ),
                  onPressed: () async {
                    final appNumber =
                    appNumberController.text.trim();

                    if (appNumber.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                          Text('Please enter Application Number'),
                        ),
                      );
                      return;
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection('applications')
                          .add({
                        'appNumber': appNumber,
                        'appType':
                        appTypeController.text.trim(),
                        'clientName':
                        clientNameController.text.trim(),
                        'status': selectedStatus,
                        'createdAt':
                        FieldValue.serverTimestamp(),
                        'updatedAt':
                        FieldValue.serverTimestamp(),
                      });

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                          Text('Application added successfully!'),
                        ),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                        ),
                      );
                    }
                  },
                  label: const Text(
                    'Save Tracker',
                    style: TextStyle(
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
  // EDIT APPLICATION
  // ============================================================

  void _showEditApplicationDialog(
      BuildContext context,
      String appId,
      Map<String, dynamic> appData,
      ) {
    final appNumberController = TextEditingController(
      text: appData['appNumber']?.toString() ?? '',
    );

    final appTypeController = TextEditingController(
      text: appData['appType']?.toString() ?? '',
    );

    final clientNameController = TextEditingController(
      text: appData['clientName']?.toString() ?? '',
    );

    String selectedStatus =
        appData['status']?.toString() ?? 'Under Process';

    if (!statusOptions.contains(selectedStatus)) {
      selectedStatus = 'Under Process';
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              title: const Text(
                'Modify Application',
                style: TextStyle(
                  color: offWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: appNumberController,
                        label: 'Application Number',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: appTypeController,
                        label: 'Application Type',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: clientNameController,
                        label: 'Company / Client Name',
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Application Status',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...statusOptions.map(
                            (status) {
                          return RadioListTile<String>(
                            value: status,
                            groupValue: selectedStatus,
                            activeColor: electricYellowGreen,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedStatus = value;
                                });
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: electricYellowGreen,
                    foregroundColor: deepNavy,
                  ),
                  onPressed: () async {
                    final appNumber =
                    appNumberController.text.trim();

                    if (appNumber.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Application Number cannot be empty',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      if (selectedStatus == 'Approval' ||
                          selectedStatus == 'Rejected') {
                        await FirebaseFirestore.instance
                            .collection('applications')
                            .doc(appId)
                            .delete();

                        if (!dialogContext.mounted) return;

                        Navigator.pop(dialogContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              selectedStatus == 'Approval'
                                  ? 'Application approved and removed from tracker.'
                                  : 'Application rejected and removed from tracker.',
                            ),
                          ),
                        );

                        return;
                      }

                      await FirebaseFirestore.instance
                          .collection('applications')
                          .doc(appId)
                          .update({
                        'appNumber': appNumber,
                        'appType':
                        appTypeController.text.trim(),
                        'clientName':
                        clientNameController.text.trim(),
                        'status': selectedStatus,
                        'updatedAt':
                        FieldValue.serverTimestamp(),
                      });

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                          Text('Application updated successfully!'),
                        ),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                          Text('Error updating application: $e'),
                        ),
                      );
                    }
                  },
                  label: const Text(
                    'Update',
                    style: TextStyle(
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
  // DELETE APPLICATION
  // ============================================================

  Future<void> _deleteApplication(
      BuildContext context,
      String appId,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: const Text(
            'Delete Application?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to permanently delete this application?',
            style: TextStyle(color: Colors.white70),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(appId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application deleted'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete error: $e'),
          ),
        );
      }
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: const Text(
            'Logout',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: electricYellowGreen,
                foregroundColor: deepNavy,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white70,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white30,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: electricYellowGreen,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Under Process':
        return Colors.amberAccent;

      case 'Approval':
        return Colors.lightGreenAccent;

      case 'Return for Modification':
        return Colors.orangeAccent;

      case 'Rejected':
        return Colors.redAccent;

      default:
        return Colors.white70;
    }
  }

  // ============================================================
  // COMPANY EXPIRY DIALOG
  // ============================================================

  void _showCompanyExpiryDialog(
      BuildContext context,
      List<QueryDocumentSnapshot> companies,
      ) {
    final List<Map<String, String>> expiryList = [];

    for (final document in companies) {
      final data =
      document.data() as Map<String, dynamic>;

      final companyName =
          data['companyName']?.toString() ??
              'Unknown Company';

      final documents = <String, String>{
        'Trade License':
        data['tradeExpiry']?.toString() ?? '',
        'Tenancy Contract':
        data['tenancyExpiry']?.toString() ?? '',
        'Establishment Card':
        data['establishmentExpiry']?.toString() ?? '',
      };

      for (final entry in documents.entries) {
        if (_isExpiredOrWithin30Days(entry.value)) {
          expiryList.add({
            'company': companyName,
            'document': entry.key,
            'expiry': entry.value,
          });
        }
      }
    }

    expiryList.sort(
          (a, b) => _compareExpiryDates(
        a['expiry']!,
        b['expiry']!,
      ),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: const Text(
            'Company Expired / 30-Day Documents',
            style: TextStyle(
              color: offWhite,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 550,
            height: 400,
            child: expiryList.isEmpty
                ? const Center(
              child: Text(
                'No company documents are expired or expiring within 30 days.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
            )
                : ListView.builder(
              itemCount: expiryList.length,
              itemBuilder: (context, index) {
                final item = expiryList[index];

                return Container(
                  margin:
                  const EdgeInsets.only(bottom: 8),
                  padding:
                  const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent
                        .withValues(alpha: 0.10),
                    borderRadius:
                    BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['company']!,
                              style:
                              const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item['document']!,
                              style:
                              const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Expiry: ${item['expiry']!.isEmpty ? "N/A" : item['expiry']!}',
                              style:
                              const TextStyle(
                                color: Colors.redAccent,
                                fontWeight:
                                FontWeight.bold,
                              ),
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  color: electricYellowGreen,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EMPLOYEE EXPIRY DIALOG
  // ============================================================

  void _showEmployeeExpiryDialog(
      BuildContext context,
      List<QueryDocumentSnapshot> employees,
      ) {
    final List<Map<String, String>> expiryList = [];

    for (final document in employees) {
      final data =
      document.data() as Map<String, dynamic>;

      final employeeName =
          data['employeeName']?.toString() ??
              'Unknown Employee';

      final documents = <String, String>{
        'Visa':
        data['visaExpiry']?.toString() ?? '',
        'Labour Card':
        data['laborExpiry']?.toString() ?? '',
        'OHC Card':
        data['ohcExpiry']?.toString() ?? '',
      };

      for (final entry in documents.entries) {
        if (_isExpiredOrWithin30Days(entry.value)) {
          expiryList.add({
            'employee': employeeName,
            'document': entry.key,
            'expiry': entry.value,
          });
        }
      }
    }

    expiryList.sort(
          (a, b) => _compareExpiryDates(
        a['expiry']!,
        b['expiry']!,
      ),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: const Text(
            'Employee Expired / 30-Day Documents',
            style: TextStyle(
              color: offWhite,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 550,
            height: 400,
            child: expiryList.isEmpty
                ? const Center(
              child: Text(
                'No employee documents are expired or expiring within 30 days.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
            )
                : ListView.builder(
              itemCount: expiryList.length,
              itemBuilder: (context, index) {
                final item = expiryList[index];

                return Container(
                  margin:
                  const EdgeInsets.only(bottom: 8),
                  padding:
                  const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent
                        .withValues(alpha: 0.10),
                    borderRadius:
                    BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['employee']!,
                              style:
                              const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item['document']!,
                              style:
                              const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Expiry: ${item['expiry']!.isEmpty ? "N/A" : item['expiry']!}',
                              style:
                              const TextStyle(
                                color: Colors.redAccent,
                                fontWeight:
                                FontWeight.bold,
                              ),
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  color: electricYellowGreen,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DASHBOARD CARD
  // ============================================================

  Widget _dashboardCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
    bool warning = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints:
          const BoxConstraints(minHeight: 145),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: warning
                  ? Colors.redAccent
                  .withValues(alpha: 0.5)
                  : iconColor
                  .withValues(alpha: 0.25),
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
                      color: iconColor.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius:
                      BorderRadius.circular(9),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white38,
                      size: 14,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: offWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  color: warning
                      ? Colors.redAccent
                      : iconColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GLOBAL SEARCH RESULT
  // ============================================================

  Widget _buildGlobalSearchResults() {
    if (_searchText.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Search Results',
          style: TextStyle(
            color: offWhite,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // ========================================================
        // COMPANY SEARCH
        // ========================================================

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('companies')
              .snapshots(),
          builder: (context, snapshot) {
            final companies =
                snapshot.data?.docs ?? [];

            final results = companies.where((doc) {
              final data =
              doc.data() as Map<String, dynamic>;

              final text = [
                data['companyName'],
                data['tradeLicense'],
                data['authorizedPerson'],
                data['mobile'],
                data['email'],
                data['tenancy'],
                data['establishmentCard'],
              ].join(' ');

              return _matchesSearch(text);
            }).toList();

            if (results.isEmpty) {
              return const SizedBox.shrink();
            }

            return _searchSection(
              title: 'Companies',
              icon: Icons.business_rounded,
              color: electricYellowGreen,
              children: results.map((doc) {
                final data =
                doc.data() as Map<String, dynamic>;

                final companyName =
                    data['companyName']?.toString() ??
                        'Unknown Company';

                final tradeLicense =
                    data['tradeLicense']?.toString() ??
                        'N/A';

                return _searchResultTile(
                  icon: Icons.business,
                  color: electricYellowGreen,
                  title: companyName,
                  subtitle: 'Trade License: $tradeLicense',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CompanyDetailScreen(
                          companyId: doc.id,
                          companyName: companyName,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),

        // ========================================================
        // EMPLOYEE SEARCH
        // ========================================================

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup('employees')
              .snapshots(),
          builder: (context, snapshot) {
            final allEmployees =
                snapshot.data?.docs ?? [];

            final employees = allEmployees.where((doc) {
              final companyRef = doc.reference.parent.parent;
              return companyRef != null &&
                  companyRef.parent.id == 'companies';
            }).toList();

            final results = employees.where((doc) {
              final data =
              doc.data() as Map<String, dynamic>;

              final text = [
                data['employeeName'],
                data['visaNumber'],
                data['visaExpiry'],
                data['laborCardNumber'],
                data['laborExpiry'],
                data['ohcCardNumber'],
                data['ohcExpiry'],
                data['companyName'],
                data['mobile'],
                data['email'],
              ].join(' ');

              return _matchesSearch(text);
            }).toList();

            if (results.isEmpty) {
              return const SizedBox.shrink();
            }

            return _searchSection(
              title: 'Employees',
              icon: Icons.people_alt_rounded,
              color: Colors.lightBlueAccent,
              children: results.map((doc) {
                final data =
                doc.data() as Map<String, dynamic>;

                final employeeName =
                    data['employeeName']?.toString() ??
                        'Unknown Employee';

                final companyRef =
                    doc.reference.parent.parent;

                final companyId =
                    companyRef?.id ?? '';

                final visaExpiry =
                    data['visaExpiry']?.toString() ??
                        'N/A';

                final companyName =
                    data['companyName']?.toString() ?? '';

                return _searchResultTile(
                  icon: Icons.person,
                  color: Colors.lightBlueAccent,
                  title: employeeName,
                  subtitle: companyName.isEmpty
                      ? 'Visa Expiry: $visaExpiry'
                      : '$companyName • Visa: $visaExpiry',
                  onTap: () {
                    if (companyId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Employee is not linked to a company.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeeDetailScreen(
                          companyId: companyId,
                          employeeId: doc.id,
                          employeeData: data,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),

        // ========================================================
        // WORK FOLLOW-UP SEARCH
        // ========================================================

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseAuth.instance.currentUser == null
              ? null
              : FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .collection('work_follow_ups')
              .snapshots(),
          builder: (context, snapshot) {
            final works =
                snapshot.data?.docs ?? [];

            final results = works.where((doc) {
              final data =
              doc.data() as Map<String, dynamic>;

              final text = [
                data['companyPersonName'],
                data['workType'],
                data['applicationNumber'],
                data['contactNumber'],
                data['assignedPerson'],
                data['workDescription'],
                data['status'],
                data['priority'],
                data['remarks'],
              ].join(' ');

              return _matchesSearch(text);
            }).toList();

            if (results.isEmpty) {
              return const SizedBox.shrink();
            }

            return _searchSection(
              title: 'Work Follow-Up',
              icon: Icons.work_history_rounded,
              color: electricYellowGreen,
              children: results.map((doc) {
                final data =
                doc.data() as Map<String, dynamic>;

                return _searchResultTile(
                  icon: Icons.work_history_rounded,
                  color: electricYellowGreen,
                  title:
                  data['companyPersonName']?.toString() ??
                      'Unknown',
                  subtitle:
                  '${data['workType']?.toString() ?? 'Work'} • ${data['status']?.toString() ?? 'N/A'}',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const WorkFollowUpScreen(),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),

        // ========================================================
        // APPLICATION SEARCH
        // ========================================================

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('applications')
              .snapshots(),
          builder: (context, snapshot) {
            final applications =
                snapshot.data?.docs ?? [];

            final results = applications.where((doc) {
              final data =
              doc.data() as Map<String, dynamic>;

              final text = [
                data['appNumber'],
                data['appType'],
                data['clientName'],
                data['status'],
              ].join(' ');

              return _matchesSearch(text);
            }).toList();

            if (results.isEmpty) {
              return const SizedBox.shrink();
            }

            return _searchSection(
              title: 'Applications',
              icon: Icons.description_rounded,
              color: Colors.orangeAccent,
              children: results.map((doc) {
                final data =
                doc.data() as Map<String, dynamic>;

                return _searchResultTile(
                  icon: Icons.description_rounded,
                  color: Colors.orangeAccent,
                  title:
                  data['appNumber']?.toString() ??
                      'N/A',
                  subtitle:
                  '${data['appType']?.toString() ?? 'Application'} • ${data['clientName']?.toString() ?? 'N/A'}',
                  onTap: () {},
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH SECTION
  // ============================================================

  Widget _searchSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 21,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH RESULT TILE
  // ============================================================

  Widget _searchResultTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin:
        const EdgeInsets.only(bottom: 6),
        padding:
        const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: deepNavy,
          borderRadius:
          BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 21,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white30,
              size: 13,
            ),
          ],
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

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: deepNavy,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding:
              const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: electricYellowGreen,
                borderRadius:
                BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.business_center,
                color: deepNavy,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'TAFHEEL DOCS',
              style: TextStyle(
                color: offWhite,
                fontWeight:
                FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
            ),
            onPressed: () {
              _logout(context);
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // ==================================================
                // WELCOME
                // ==================================================

                const Text(
                  'Dashboard',
                  style: TextStyle(
                    color: offWhite,
                    fontSize: 25,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Real-time company, employee and document summary',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // TEST NOTIFICATION
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await NotificationService
                          .showTestNotification();

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Test notification sent. Check your notification panel.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_active,
                      color:
                      electricYellowGreen,
                    ),
                    label: const Text(
                      'TEST NOTIFICATION',
                      style: TextStyle(
                        color:
                        electricYellowGreen,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    style:
                    OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color:
                        electricYellowGreen,
                      ),
                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // GLOBAL SEARCH BAR
                // ==================================================

                Container(
                  decoration:
                  BoxDecoration(
                    color: cardBg,
                    borderRadius:
                    BorderRadius.circular(
                        14),
                    border: Border.all(
                      color:
                      electricYellowGreen
                          .withValues(
                        alpha: 0.25,
                      ),
                    ),
                  ),
                  child: TextField(
                    controller:
                    _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                    style:
                    const TextStyle(
                      color: Colors.white,
                    ),
                    decoration:
                    InputDecoration(
                      hintText:
                      'Search company, employee, work or application...',
                      hintStyle:
                      const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                      prefixIcon:
                      const Icon(
                        Icons.search_rounded,
                        color:
                        electricYellowGreen,
                      ),
                      suffixIcon:
                      _searchText.isNotEmpty
                          ? IconButton(
                        icon:
                        const Icon(
                          Icons.clear,
                          color:
                          Colors.white54,
                        ),
                        onPressed: () {
                          _searchController
                              .clear();

                          setState(() {
                            _searchText =
                            '';
                          });
                        },
                      )
                          : null,
                      border:
                      InputBorder.none,
                      contentPadding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // GLOBAL SEARCH RESULTS
                // ==================================================

                _buildGlobalSearchResults(),

                const SizedBox(height: 18),

                // ==================================================
                // COMPANY / EMPLOYEE DATA
                // ==================================================

                StreamBuilder<QuerySnapshot>(
                  stream:
                  FirebaseFirestore.instance
                      .collection(
                      'companies')
                      .snapshots(),
                  builder: (context,
                      companySnapshot) {
                    final companies =
                        companySnapshot
                            .data?.docs ??
                            [];

                    final companyCount =
                        companies.length;

                    int companyExpiryCount =
                    0;

                    for (final company
                    in companies) {
                      final data =
                      company.data()
                      as Map<String,
                          dynamic>;

                      final dates = [
                        data['tradeExpiry']
                            ?.toString(),
                        data['tenancyExpiry']
                            ?.toString(),
                        data['establishmentExpiry']
                            ?.toString(),
                      ];

                      for (final date
                      in dates) {
                        if (_isExpiredOrWithin30Days(
                            date)) {
                          companyExpiryCount++;
                        }
                      }
                    }

                    return Column(
                      children: [
                        // ==================================================
                        // COMPANY ROW
                        // ==================================================

                        Row(
                          children: [
                            _dashboardCard(
                              title:
                              'Company Information',
                              value:
                              '$companyCount',
                              subtitle:
                              'Companies • Tap to open',
                              icon:
                              Icons.business_rounded,
                              iconColor:
                              electricYellowGreen,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                    const CompanyListScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(
                                width: 14),
                            _dashboardCard(
                              title:
                              'Company Expiry',
                              value:
                              '$companyExpiryCount',
                              subtitle:
                              'Expired / within 30 days',
                              icon:
                              Icons.warning_amber_rounded,
                              iconColor:
                              Colors.redAccent,
                              warning:
                              companyExpiryCount >
                                  0,
                              onTap: () {
                                _showCompanyExpiryDialog(
                                  context,
                                  companies,
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(
                            height: 14),

                        // ==================================================
                        // EMPLOYEE
                        // ==================================================

                        StreamBuilder<
                            QuerySnapshot>(
                          stream:
                          FirebaseFirestore
                              .instance
                              .collectionGroup(
                              'employees')
                              .snapshots(),
                          builder: (context,
                              employeeSnapshot) {
                            final allEmployees =
                                employeeSnapshot
                                    .data
                                    ?.docs ??
                                    [];

                            final employees =
                            allEmployees.where((doc) {
                              final companyRef =
                                  doc.reference.parent.parent;

                              return companyRef != null &&
                                  companyRef.parent.id ==
                                      'companies';
                            }).toList();

                            final employeeCount =
                                employees.length;

                            int employeeExpiryCount =
                            0;

                            for (final employee
                            in employees) {
                              final data =
                              employee.data()
                              as Map<String,
                                  dynamic>;

                              final dates = [
                                data['visaExpiry']
                                    ?.toString(),
                                data['laborExpiry']
                                    ?.toString(),
                                data['ohcExpiry']
                                    ?.toString(),
                              ];

                              for (final date
                              in dates) {
                                if (_isExpiredOrWithin30Days(
                                    date)) {
                                  employeeExpiryCount++;
                                }
                              }
                            }

                            return Row(
                              children: [
                                _dashboardCard(
                                  title:
                                  'Employee Information',
                                  value:
                                  '$employeeCount',
                                  subtitle:
                                  'Employees • Company records',
                                  icon:
                                  Icons.people_alt_rounded,
                                  iconColor:
                                  Colors.lightBlueAccent,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                        const EmployeeListScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(
                                    width: 14),
                                _dashboardCard(
                                  title:
                                  'Employee Expiry',
                                  value:
                                  '$employeeExpiryCount',
                                  subtitle:
                                  'Expired / within 30 days',
                                  icon:
                                  Icons.assignment_late_rounded,
                                  iconColor:
                                  Colors.redAccent,
                                  warning:
                                  employeeExpiryCount >
                                      0,
                                  onTap: () {
                                    _showEmployeeExpiryDialog(
                                      context,
                                      employees,
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),

                // ==================================================
                // WORK FOLLOW-UP
                // ==================================================

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    const Text(
                      'Work Follow-Up',
                      style: TextStyle(
                        color: offWhite,
                        fontSize: 19,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const WorkFollowUpScreen(),
                          ),
                        );
                      },
                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        electricYellowGreen,
                        foregroundColor:
                        deepNavy,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                              8),
                        ),
                      ),
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 17,
                      ),
                      label: const Text(
                        'Open',
                        style: TextStyle(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const WorkFollowUpScreen(),
                      ),
                    );
                  },
                  borderRadius:
                  BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.all(20),
                    decoration:
                    BoxDecoration(
                      color: cardBg,
                      borderRadius:
                      BorderRadius.circular(
                          14),
                      border: Border.all(
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
                          padding:
                          const EdgeInsets.all(
                              12),
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
                                12),
                          ),
                          child: const Icon(
                            Icons
                                .work_history_rounded,
                            color:
                            electricYellowGreen,
                            size: 28,
                          ),
                        ),
                        const SizedBox(
                            width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                'Work Follow-Up',
                                style:
                                TextStyle(
                                  color:
                                  offWhite,
                                  fontSize: 17,
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                              SizedBox(
                                  height: 5),
                              Text(
                                'Track applications, assigned work, status and follow-up dates',
                                style:
                                TextStyle(
                                  color:
                                  Colors.white54,
                                  fontSize: 12,
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
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                // ==================================================
                // APPLICATION TRACKER HEADER
                // ==================================================

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    const Text(
                      'Application Status Tracker',
                      style: TextStyle(
                        color: offWhite,
                        fontSize: 19,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showAddApplicationDialog(
                            context);
                      },
                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        electricYellowGreen,
                        foregroundColor:
                        deepNavy,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                              8),
                        ),
                      ),
                      icon: const Icon(
                        Icons.add,
                        size: 17,
                      ),
                      label: const Text(
                        'Add Application',
                        style: TextStyle(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ==================================================
                // APPLICATION TRACKER
                // ==================================================

                Container(
                  width: double.infinity,
                  constraints:
                  const BoxConstraints(
                    minHeight: 250,
                  ),
                  padding:
                  const EdgeInsets.all(16),
                  decoration:
                  BoxDecoration(
                    color: cardBg,
                    borderRadius:
                    BorderRadius.circular(
                        12),
                    border: Border.all(
                      color:
                      offWhite.withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                  child:
                  StreamBuilder<QuerySnapshot>(
                    stream:
                    FirebaseFirestore.instance
                        .collection(
                        'applications')
                        .snapshots(),
                    builder:
                        (context, snapshot) {
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

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading applications:\n${snapshot.error}',
                            textAlign:
                            TextAlign.center,
                            style:
                            const TextStyle(
                              color:
                              Colors.redAccent,
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.docs
                              .isEmpty) {
                        return const Center(
                          child: Padding(
                            padding:
                            EdgeInsets.all(
                                30),
                            child: Text(
                              'No active application trackers found.\n\nClick "Add Application" to create one.',
                              textAlign:
                              TextAlign.center,
                              style:
                              TextStyle(
                                color:
                                Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }

                      final apps =
                          snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        itemCount:
                        apps.length,
                        itemBuilder:
                            (context, index) {
                          final appId =
                              apps[index].id;

                          final appData =
                          apps[index].data()
                          as Map<String,
                              dynamic>;

                          final String appNumber =
                              appData[
                              'appNumber']
                                  ?.toString() ??
                                  'N/A';

                          final String appType =
                              appData['appType']
                                  ?.toString() ??
                                  'N/A';

                          final String clientName =
                              appData[
                              'clientName']
                                  ?.toString() ??
                                  'N/A';

                          final String status =
                              appData['status']
                                  ?.toString() ??
                                  'Under Process';

                          if (status ==
                              'Approval' ||
                              status ==
                                  'Rejected') {
                            WidgetsBinding
                                .instance
                                .addPostFrameCallback(
                                  (_) async {
                                try {
                                  await FirebaseFirestore
                                      .instance
                                      .collection(
                                      'applications')
                                      .doc(appId)
                                      .delete();
                                } catch (_) {}
                              },
                            );

                            return const SizedBox
                                .shrink();
                          }

                          final statusColor =
                          _getStatusColor(
                            status,
                          );

                          return Container(
                            margin:
                            const EdgeInsets
                                .only(
                              bottom: 10,
                            ),
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            decoration:
                            BoxDecoration(
                              color: deepNavy,
                              borderRadius:
                              BorderRadius
                                  .circular(
                                9,
                              ),
                              border:
                              Border.all(
                                color:
                                offWhite
                                    .withValues(
                                  alpha: 0.06,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child:
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(
                                        'App No: $appNumber',
                                        style:
                                        const TextStyle(
                                          color:
                                          offWhite,
                                          fontWeight:
                                          FontWeight
                                              .bold,
                                          fontSize:
                                          15,
                                        ),
                                      ),
                                      const SizedBox(
                                          height:
                                          5),
                                      Text(
                                        'Type: $appType',
                                        style:
                                        TextStyle(
                                          color: offWhite
                                              .withValues(
                                            alpha:
                                            0.65,
                                          ),
                                          fontSize:
                                          12,
                                        ),
                                      ),
                                      const SizedBox(
                                          height:
                                          3),
                                      Text(
                                        'Company: $clientName',
                                        style:
                                        TextStyle(
                                          color: offWhite
                                              .withValues(
                                            alpha:
                                            0.65,
                                          ),
                                          fontSize:
                                          12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding:
                                  const EdgeInsets
                                      .symmetric(
                                    horizontal:
                                    10,
                                    vertical: 6,
                                  ),
                                  decoration:
                                  BoxDecoration(
                                    color:
                                    statusColor
                                        .withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      6,
                                    ),
                                    border:
                                    Border.all(
                                      color:
                                      statusColor
                                          .withValues(
                                        alpha:
                                        0.4,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    status,
                                    style:
                                    TextStyle(
                                      color:
                                      statusColor,
                                      fontSize: 11,
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                    width: 6),
                                IconButton(
                                  tooltip:
                                  'Modify Application',
                                  icon:
                                  const Icon(
                                    Icons.edit,
                                    color:
                                    Colors.amberAccent,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _showEditApplicationDialog(
                                      context,
                                      appId,
                                      appData,
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip:
                                  'Delete Application',
                                  icon:
                                  const Icon(
                                    Icons
                                        .delete_outline,
                                    color:
                                    Colors.redAccent,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _deleteApplication(
                                      context,
                                      appId,
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // FOOTER
                // ==================================================

                Center(
                  child: Text(
                    'TAFHEEL DOCS • Company & Document Management',
                    style: TextStyle(
                      color:
                      Colors.white.withValues(
                        alpha: 0.35,
                      ),
                      fontSize: 11,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
