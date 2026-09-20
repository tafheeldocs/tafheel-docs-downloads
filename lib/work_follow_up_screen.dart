import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorkFollowUpScreen extends StatefulWidget {
  const WorkFollowUpScreen({super.key});

  @override
  State<WorkFollowUpScreen> createState() => _WorkFollowUpScreenState();
}

class _WorkFollowUpScreenState extends State<WorkFollowUpScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color deepNavy = Color(0xFF0D1B2A);
  static const Color cardBg = Color(0xFF16222D);
  static const Color dialogBg = Color(0xFF1B2A38);
  static const Color electricYellowGreen = Color(0xFFC8F500);
  static const Color offWhite = Color(0xFFF0EDE8);

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController _searchController =
  TextEditingController();

  String _searchText = '';

  // ============================================================
  // STATUS
  // ============================================================

  final List<String> _statusOptions = const <String>[
    'Fund Not Credited Customer Side/ work not done',
    'Payment Received Form Customer W not done',
    'Under Process',
    'Approved',
    'Rejected',
    'Return for Modification',
  ];

  // ============================================================
  // PRIORITY
  // ============================================================

  final List<String> _priorityOptions = const [
    'Low',
    'Medium',
    'High',
    'Urgent',
  ];

  // ============================================================
  // FIRESTORE COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>> _workCollection() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('work_follow_ups');
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _cleanupOldCompletedWorks();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // COMPLETED STATUS
  // ============================================================

  bool _isCompletedStatus(String status) {
    return status == 'Approved' || status == 'Rejected';
  }

  // ============================================================
  // CLEANUP AFTER 7 DAYS
  // ============================================================

  Future<void> _cleanupOldCompletedWorks() async {
    try {
      final snapshot = await _workCollection().get();

      final now = DateTime.now();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final status = data['status'] as String? ?? '';
        final completedAt = data['completedAt'];

        if (!_isCompletedStatus(status)) {
          continue;
        }

        if (completedAt == null) {
          continue;
        }

        DateTime? completedDate;

        if (completedAt is Timestamp) {
          completedDate = completedAt.toDate();
        }

        if (completedDate == null) {
          continue;
        }

        final difference = now.difference(completedDate);

        if (difference.inDays >= 7) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      debugPrint('Cleanup error: $e');
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<DateTime?> _selectDate(
      BuildContext context,
      DateTime? initialDate,
      ) async {
    final now = DateTime.now();

    return showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: electricYellowGreen,
              onPrimary: Colors.black,
              surface: dialogBg,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  // ============================================================
  // ADD / EDIT WORK
  // ============================================================

  Future<void> _showWorkDialog({
    DocumentSnapshot<Map<String, dynamic>>? document,
  }) async {
    final bool isEditing = document != null;

    final data = document?.data();

    // ------------------------------------------------------------
    // CONTROLLERS
    // ------------------------------------------------------------

    final nameController = TextEditingController(
      text: data?['companyPersonName'] ?? '',
    );

    final workTypeController = TextEditingController(
      text: data?['workType'] ?? '',
    );

    final applicationController = TextEditingController(
      text: data?['applicationNumber'] ?? '',
    );

    final contactController = TextEditingController(
      text: data?['contactNumber'] ?? '',
    );

    final assignedController = TextEditingController(
      text: data?['assignedPerson'] ?? '',
    );

    final descriptionController = TextEditingController(
      text: data?['workDescription'] ?? '',
    );

    final remarksController = TextEditingController(
      text: data?['remarks'] ?? '',
    );

    // ------------------------------------------------------------
    // STATUS
    // ------------------------------------------------------------

    String selectedStatus =
        data?['status'] ?? 'Under Process';

    final oldStatus = data?['status'] as String?;

    // ------------------------------------------------------------
    // PRIORITY
    // ------------------------------------------------------------

    String selectedPriority =
        data?['priority'] ?? 'Medium';

    // ------------------------------------------------------------
    // NEXT FOLLOW-UP DATE
    // ------------------------------------------------------------

    DateTime? selectedFollowUpDate;

    final savedFollowUpDate =
    data?['nextFollowUpDate'];

    if (savedFollowUpDate is Timestamp) {
      selectedFollowUpDate =
          savedFollowUpDate.toDate();
    }

    // ============================================================
    // DIALOG
    // ============================================================

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBg,

              title: Text(
                isEditing
                    ? 'Edit Work Follow-Up'
                    : 'Add Work Follow-Up',
                style: const TextStyle(
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

                      // ==================================================
                      // COMPANY / PERSON NAME
                      // ==================================================

                      TextField(
                        controller: nameController,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: _inputDecoration(
                          'Company / Person Name',
                          Icons.person,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // WORK TYPE
                      // ==================================================

                      TextField(
                        controller: workTypeController,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: _inputDecoration(
                          'Work Type',
                          Icons.work_outline,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // APPLICATION NUMBER
                      // ==================================================

                      TextField(
                        controller: applicationController,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: _inputDecoration(
                          'Application / Reference No.',
                          Icons.confirmation_number_outlined,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // CONTACT NUMBER
                      // ==================================================

                      TextField(
                        controller: contactController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: _inputDecoration(
                          'Contact Number',
                          Icons.phone_outlined,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // ASSIGNED PERSON
                      // ==================================================

                      TextField(
                        controller: assignedController,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: _inputDecoration(
                          'Assigned Person',
                          Icons.badge_outlined,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // DESCRIPTION
                      // ==================================================

                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: _inputDecoration(
                          'Work Description / Notes',
                          Icons.description_outlined,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // STATUS TITLE
                      // ==================================================

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Work Status',
                          style: TextStyle(
                            color: offWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ==================================================
                      // STATUS OPTIONS
                      // ==================================================

                      ..._statusOptions.map(
                            (status) {
                          return CheckboxListTile(
                            value:
                            selectedStatus == status,

                            onChanged: (value) {
                              if (value == true) {
                                setDialogState(() {
                                  selectedStatus =
                                      status;
                                });
                              }
                            },

                            activeColor:
                            electricYellowGreen,

                            checkColor: Colors.black,

                            controlAffinity:
                            ListTileControlAffinity.leading,

                            contentPadding:
                            EdgeInsets.zero,

                            title: Text(
                              status,
                              style: TextStyle(
                                color:
                                _statusColor(status),
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // PRIORITY
                      // ==================================================

                      DropdownButtonFormField<String>(
                        value: selectedPriority,

                        dropdownColor: dialogBg,

                        style: const TextStyle(
                          color: Colors.white,
                        ),

                        decoration: _inputDecoration(
                          'Priority',
                          Icons.priority_high,
                        ),

                        items: _priorityOptions.map(
                              (priority) {
                            return DropdownMenuItem<String>(
                              value: priority,
                              child: Text(
                                priority,
                                style: TextStyle(
                                  color:
                                  _priorityColor(
                                    priority,
                                  ),
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ).toList(),

                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedPriority =
                                  value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // NEXT FOLLOW-UP DATE
                      // ==================================================

                      InkWell(
                        onTap: () async {
                          final date =
                          await _selectDate(
                            context,
                            selectedFollowUpDate,
                          );

                          if (date != null) {
                            setDialogState(() {
                              selectedFollowUpDate =
                                  date;
                            });
                          }
                        },

                        child: InputDecorator(
                          decoration: _inputDecoration(
                            'Next Follow-Up Date',
                            Icons.calendar_month,
                          ),

                          child: Row(
                            children: [

                              Expanded(
                                child: Text(
                                  selectedFollowUpDate ==
                                      null
                                      ? 'Select Date'
                                      : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(
                                    selectedFollowUpDate!,
                                  ),
                                  style:
                                  TextStyle(
                                    color:
                                    selectedFollowUpDate ==
                                        null
                                        ? Colors.white54
                                        : Colors.white,
                                  ),
                                ),
                              ),

                              if (selectedFollowUpDate !=
                                  null)
                                IconButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedFollowUpDate =
                                      null;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.clear,
                                    color:
                                    Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // REMARKS
                      // ==================================================

                      TextField(
                        controller: remarksController,
                        maxLines: 3,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: _inputDecoration(
                          'Remarks',
                          Icons.notes_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==========================================================
              // ACTIONS
              // ==========================================================

              actions: [

                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    electricYellowGreen,
                    foregroundColor: Colors.black,
                  ),

                  onPressed: () async {
                    final name =
                    nameController.text.trim();

                    final workType =
                    workTypeController.text.trim();

                    final applicationNumber =
                    applicationController.text.trim();

                    final contactNumber =
                    contactController.text.trim();

                    final assignedPerson =
                    assignedController.text.trim();

                    final workDescription =
                    descriptionController.text.trim();

                    final remarks =
                    remarksController.text.trim();

                    // ----------------------------------------------------
                    // VALIDATION
                    // ----------------------------------------------------

                    if (name.isEmpty ||
                        workType.isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter Company / Person Name and Work Type',
                          ),
                        ),
                      );

                      return;
                    }

                    Navigator.pop(dialogContext);

                    // ----------------------------------------------------
                    // SAVE
                    // ----------------------------------------------------

                    try {
                      if (isEditing) {

                        final Map<String, dynamic>
                        updateData = {

                          'companyPersonName':
                          name,

                          'workType':
                          workType,

                          'applicationNumber':
                          applicationNumber,

                          'contactNumber':
                          contactNumber,

                          'assignedPerson':
                          assignedPerson,

                          'workDescription':
                          workDescription,

                          'status':
                          selectedStatus,

                          'priority':
                          selectedPriority,

                          'remarks':
                          remarks,

                          'updatedAt':
                          FieldValue
                              .serverTimestamp(),
                        };

                        // ------------------------------------------------
                        // FOLLOW-UP DATE
                        // ------------------------------------------------

                        if (selectedFollowUpDate !=
                            null) {
                          updateData[
                          'nextFollowUpDate'] =
                              Timestamp.fromDate(
                                selectedFollowUpDate!,
                              );
                        } else {
                          updateData[
                          'nextFollowUpDate'] =
                              FieldValue.delete();
                        }

                        // ------------------------------------------------
                        // STATUS -> APPROVED / REJECTED
                        // ------------------------------------------------

                        if (_isCompletedStatus(
                          selectedStatus,
                        ) &&
                            !_isCompletedStatus(
                              oldStatus ?? '',
                            )) {
                          updateData[
                          'completedAt'] =
                              FieldValue
                                  .serverTimestamp();
                        }

                        // ------------------------------------------------
                        // APPROVED / REJECTED -> OTHER STATUS
                        // ------------------------------------------------

                        if (!_isCompletedStatus(
                          selectedStatus,
                        ) &&
                            _isCompletedStatus(
                              oldStatus ?? '',
                            )) {
                          updateData[
                          'completedAt'] =
                              FieldValue.delete();
                        }

                        await document!.reference
                            .update(updateData);
                      } else {

                        // ==================================================
                        // NEW WORK
                        // ==================================================

                        final Map<String, dynamic>
                        newData = {

                          'companyPersonName':
                          name,

                          'workType':
                          workType,

                          'applicationNumber':
                          applicationNumber,

                          'contactNumber':
                          contactNumber,

                          'assignedPerson':
                          assignedPerson,

                          'workDescription':
                          workDescription,

                          'status':
                          selectedStatus,

                          'priority':
                          selectedPriority,

                          'remarks':
                          remarks,

                          'createdAt':
                          FieldValue
                              .serverTimestamp(),

                          'updatedAt':
                          FieldValue
                              .serverTimestamp(),
                        };

                        // ------------------------------------------------
                        // FOLLOW-UP DATE
                        // ------------------------------------------------

                        if (selectedFollowUpDate !=
                            null) {
                          newData[
                          'nextFollowUpDate'] =
                              Timestamp.fromDate(
                                selectedFollowUpDate!,
                              );
                        }

                        // ------------------------------------------------
                        // COMPLETED DATE
                        // ------------------------------------------------

                        if (_isCompletedStatus(
                          selectedStatus,
                        )) {
                          newData[
                          'completedAt'] =
                              FieldValue
                                  .serverTimestamp();
                        }

                        await _workCollection()
                            .add(newData);
                      }

                      if (!mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Work Follow-Up updated successfully'
                                : 'Work Follow-Up added successfully',
                          ),
                        ),
                      );

                      await _cleanupOldCompletedWorks();
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: $e',
                          ),
                        ),
                      );
                    }
                  },

                  child: Text(
                    isEditing
                        ? 'Update'
                        : 'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // ================================================================
    // DISPOSE DIALOG CONTROLLERS
    // ================================================================

    nameController.dispose();
    workTypeController.dispose();
    applicationController.dispose();
    contactController.dispose();
    assignedController.dispose();
    descriptionController.dispose();
    remarksController.dispose();
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration(
      String label,
      IconData icon,
      ) {
    return InputDecoration(
      labelText: label,

      labelStyle: const TextStyle(
        color: Colors.white70,
      ),

      prefixIcon: Icon(
        icon,
        color: electricYellowGreen,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.white24,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: electricYellowGreen,
        ),
      ),

      filled: true,

      fillColor: Colors.black12,
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteWork(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) async {
    final data = document.data();

    final name =
        data?['companyPersonName'] ?? 'this work';

    final confirm =
    await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBg,

          title: const Text(
            'Delete Work?',
            style: TextStyle(
              color: Colors.white,
            ),
          ),

          content: Text(
            'Are you sure you want to delete "$name"?',
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

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await document.reference.delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Work Follow-Up deleted',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delete error: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.greenAccent;

      case 'Rejected':
        return Colors.redAccent;

      case 'Return for Modification':
        return Colors.orangeAccent;

      case 'Under Process':
      default:
        return Colors.amberAccent;
    }
  }

  // ============================================================
  // PRIORITY COLOR
  // ============================================================

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.redAccent;

      case 'High':
        return Colors.orangeAccent;

      case 'Medium':
        return Colors.amberAccent;

      case 'Low':
      default:
        return Colors.greenAccent;
    }
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Waiting...';
    }

    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    }

    if (date == null) {
      return 'Waiting...';
    }

    return DateFormat(
      'dd/MM/yyyy hh:mm a',
    ).format(date);
  }

  // ============================================================
  // REMAINING DAYS
  // ============================================================

  String _remainingDays(dynamic completedAt) {
    if (completedAt == null) {
      return '';
    }

    if (completedAt is! Timestamp) {
      return '';
    }

    final completedDate =
    completedAt.toDate();

    final deleteDate =
    completedDate.add(
      const Duration(days: 7),
    );

    final remaining =
    deleteDate.difference(
      DateTime.now(),
    );

    if (remaining.isNegative) {
      return 'Deleting...';
    }

    final days =
        remaining.inDays;

    final hours =
        remaining.inHours % 24;

    return 'Auto delete in $days day(s) $hours hour(s)';
  }

  // ============================================================
  // SEARCH
  // ============================================================

  bool _matchesSearch(
      Map<String, dynamic> data,
      ) {
    if (_searchText.trim().isEmpty) {
      return true;
    }

    final search =
    _searchText.toLowerCase();

    final name =
    (data['companyPersonName'] ?? '')
        .toString()
        .toLowerCase();

    final workType =
    (data['workType'] ?? '')
        .toString()
        .toLowerCase();

    final application =
    (data['applicationNumber'] ?? '')
        .toString()
        .toLowerCase();

    final contact =
    (data['contactNumber'] ?? '')
        .toString()
        .toLowerCase();

    final assigned =
    (data['assignedPerson'] ?? '')
        .toString()
        .toLowerCase();

    final description =
    (data['workDescription'] ?? '')
        .toString()
        .toLowerCase();

    final status =
    (data['status'] ?? '')
        .toString()
        .toLowerCase();

    final priority =
    (data['priority'] ?? '')
        .toString()
        .toLowerCase();

    final remarks =
    (data['remarks'] ?? '')
        .toString()
        .toLowerCase();

    return name.contains(search) ||
        workType.contains(search) ||
        application.contains(search) ||
        contact.contains(search) ||
        assigned.contains(search) ||
        description.contains(search) ||
        status.contains(search) ||
        priority.contains(search) ||
        remarks.contains(search);
  }

  // ============================================================
  // WORK CARD
  // ============================================================

  Widget _workCard(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data =
        document.data() ?? {};

    final name =
        data['companyPersonName'] ?? '';

    final workType =
        data['workType'] ?? '';

    final applicationNumber =
        data['applicationNumber'] ?? '';

    final contactNumber =
        data['contactNumber'] ?? '';

    final assignedPerson =
        data['assignedPerson'] ?? '';

    final description =
        data['workDescription'] ?? '';

    final status =
        data['status'] ?? 'Under Process';

    final priority =
        data['priority'] ?? 'Medium';

    final remarks =
        data['remarks'] ?? '';

    final createdAt =
    data['createdAt'];

    final updatedAt =
    data['updatedAt'];

    final completedAt =
    data['completedAt'];

    final nextFollowUpDate =
    data['nextFollowUpDate'];

    final isCompleted =
    _isCompletedStatus(status);

    return Card(
      color: cardBg,

      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(16),

        side: BorderSide(
          color: _statusColor(status)
              .withOpacity(0.45),
        ),
      ),

      child: Padding(
        padding:
        const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // ========================================================
            // TOP
            // ========================================================

            Row(
              children: [

                CircleAvatar(
                  backgroundColor:
                  _statusColor(status)
                      .withOpacity(0.15),

                  child: Icon(
                    Icons.work_outline,
                    color:
                    _statusColor(status),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    name.toString(),

                    style:
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                PopupMenuButton<String>(
                  icon:
                  const Icon(
                    Icons.more_vert,
                    color:
                    Colors.white70,
                  ),

                  color: dialogBg,

                  onSelected: (value) {

                    if (value == 'edit') {
                      _showWorkDialog(
                        document:
                        document,
                      );
                    }

                    if (value == 'delete') {
                      _deleteWork(
                        document,
                      );
                    }
                  },

                  itemBuilder:
                      (context) => [

                    const PopupMenuItem(
                      value: 'edit',

                      child: Row(
                        children: [

                          Icon(
                            Icons.edit,
                            color:
                            Colors.white,
                          ),

                          SizedBox(width: 10),

                          Text(
                            'Edit',
                            style:
                            TextStyle(
                              color:
                              Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const PopupMenuItem(
                      value: 'delete',

                      child: Row(
                        children: [

                          Icon(
                            Icons.delete,
                            color:
                            Colors.redAccent,
                          ),

                          SizedBox(width: 10),

                          Text(
                            'Delete',
                            style:
                            TextStyle(
                              color:
                              Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ========================================================
            // WORK TYPE
            // ========================================================

            if (workType
                .toString()
                .isNotEmpty)
              _infoRow(
                Icons.assignment_outlined,
                workType.toString(),
              ),

            // ========================================================
            // APPLICATION NUMBER
            // ========================================================

            if (applicationNumber
                .toString()
                .isNotEmpty)
              _infoRow(
                Icons.confirmation_number_outlined,
                'Ref: ${applicationNumber.toString()}',
              ),

            // ========================================================
            // CONTACT
            // ========================================================

            if (contactNumber
                .toString()
                .isNotEmpty)
              _infoRow(
                Icons.phone_outlined,
                contactNumber.toString(),
              ),

            // ========================================================
            // ASSIGNED
            // ========================================================

            if (assignedPerson
                .toString()
                .isNotEmpty)
              _infoRow(
                Icons.badge_outlined,
                'Assigned: ${assignedPerson.toString()}',
              ),

            const SizedBox(height: 8),

            // ========================================================
            // STATUS
            // ========================================================

            Row(
              children: [

                const Icon(
                  Icons.flag_outlined,
                  size: 18,
                  color: Colors.white54,
                ),

                const SizedBox(width: 8),

                Text(
                  status.toString(),

                  style: TextStyle(
                    color:
                    _statusColor(status),
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ========================================================
            // PRIORITY
            // ========================================================

            Row(
              children: [

                const Icon(
                  Icons.priority_high,
                  size: 18,
                  color: Colors.white54,
                ),

                const SizedBox(width: 8),

                Text(
                  'Priority: ',

                  style:
                  const TextStyle(
                    color:
                    Colors.white54,
                  ),
                ),

                Text(
                  priority.toString(),

                  style: TextStyle(
                    color:
                    _priorityColor(
                      priority.toString(),
                    ),
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),

            // ========================================================
            // DESCRIPTION
            // ========================================================

            if (description
                .toString()
                .isNotEmpty) ...[
              const SizedBox(height: 10),

              Container(
                width:
                double.infinity,

                padding:
                const EdgeInsets.all(10),

                decoration:
                BoxDecoration(
                  color:
                  Colors.black12,

                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),

                child: Text(
                  description.toString(),

                  style:
                  const TextStyle(
                    color:
                    Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            // ========================================================
            // FOLLOW-UP DATE
            // ========================================================

            if (nextFollowUpDate != null) ...[
              const SizedBox(height: 10),

              _infoRow(
                Icons.calendar_month,
                'Next Follow-Up: ${_formatDate(nextFollowUpDate)}',
              ),
            ],

            // ========================================================
            // REMARKS
            // ========================================================

            if (remarks
                .toString()
                .isNotEmpty) ...[
              const SizedBox(height: 8),

              _infoRow(
                Icons.notes_outlined,
                'Remarks: ${remarks.toString()}',
              ),
            ],

            const SizedBox(height: 10),

            // ========================================================
            // CREATED
            // ========================================================

            _infoRow(
              Icons.access_time,
              'Created: ${_formatDate(createdAt)}',
            ),

            // ========================================================
            // UPDATED
            // ========================================================

            if (updatedAt != null)
              _infoRow(
                Icons.update,
                'Updated: ${_formatDate(updatedAt)}',
              ),

            // ========================================================
            // AUTO DELETE
            // ========================================================

            if (isCompleted &&
                completedAt != null) ...[
              const SizedBox(height: 10),

              Container(
                width:
                double.infinity,

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),

                decoration:
                BoxDecoration(
                  color:
                  _statusColor(status)
                      .withOpacity(0.10),

                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),

                child: Text(
                  _remainingDays(
                    completedAt,
                  ),

                  style: TextStyle(
                    color:
                    _statusColor(status),
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(
      IconData icon,
      String text,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 7,
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            size: 18,
            color: Colors.white54,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              text,

              style:
              const TextStyle(
                color:
                Colors.white70,
                fontSize: 14,
              ),
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
        foregroundColor: Colors.white,

        title: const Text(
          'Work Follow-Up',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: Column(
        children: [

          // ==========================================================
          // ADD WORK BUTTON
          // ==========================================================

          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),

            child: SizedBox(
              width:
              double.infinity,

              height: 52,

              child:
              ElevatedButton.icon(
                onPressed: () {
                  _showWorkDialog();
                },

                icon: const Icon(
                  Icons.add,
                  size: 24,
                ),

                label: const Text(
                  'ADD WORK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  electricYellowGreen,

                  foregroundColor:
                  Colors.black,

                  elevation: 3,

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ==========================================================
          // SEARCH BAR
          // ==========================================================

          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              10,
            ),

            child: TextField(
              controller:
              _searchController,

              onChanged: (value) {
                setState(() {
                  _searchText =
                      value;
                });
              },

              style:
              const TextStyle(
                color: Colors.white,
              ),

              decoration:
              InputDecoration(
                hintText:
                'Search company, person, work, status...',

                hintStyle:
                const TextStyle(
                  color:
                  Colors.white54,
                ),

                prefixIcon:
                const Icon(
                  Icons.search,
                  color:
                  electricYellowGreen,
                ),

                suffixIcon:
                _searchText.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController
                        .clear();

                    setState(() {
                      _searchText =
                      '';
                    });
                  },

                  icon:
                  const Icon(
                    Icons.clear,
                    color:
                    Colors.white70,
                  ),
                )
                    : null,

                filled: true,

                fillColor: cardBg,

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                  borderSide:
                  BorderSide.none,
                ),
              ),
            ),
          ),

          // ==========================================================
          // WORK LIST
          // ==========================================================

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: _workCollection()
                  .orderBy(
                'createdAt',
                descending: true,
              )
                  .snapshots(),

              builder:
                  (context, snapshot) {

                // ----------------------------------------------------
                // LOADING
                // ----------------------------------------------------

                if (snapshot
                    .connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                    CircularProgressIndicator(
                      color:
                      electricYellowGreen,
                    ),
                  );
                }

                // ----------------------------------------------------
                // ERROR
                // ----------------------------------------------------

                if (snapshot.hasError) {
                  return Center(
                    child:
                    Padding(
                      padding:
                      const EdgeInsets.all(
                        20,
                      ),

                      child: Text(
                        'Error loading Work Follow-Up:\n${snapshot.error}',

                        textAlign:
                        TextAlign.center,

                        style:
                        const TextStyle(
                          color:
                          Colors.redAccent,
                        ),
                      ),
                    ),
                  );
                }

                // ----------------------------------------------------
                // DOCUMENTS
                // ----------------------------------------------------

                final documents =
                    snapshot.data?.docs ??
                        [];

                // ----------------------------------------------------
                // FILTER
                // ----------------------------------------------------

                final filteredDocuments =
                documents
                    .where(
                      (doc) =>
                      _matchesSearch(
                        doc.data(),
                      ),
                )
                    .toList();

                // ----------------------------------------------------
                // EMPTY
                // ----------------------------------------------------

                if (filteredDocuments
                    .isEmpty) {
                  return Center(
                    child:
                    Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,

                      children: [

                        Icon(
                          Icons
                              .work_off_outlined,
                          size: 70,
                          color: Colors
                              .white
                              .withOpacity(
                            0.25,
                          ),
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        Text(
                          _searchText
                              .isEmpty
                              ? 'No Work Follow-Up found'
                              : 'No matching work found',

                          style:
                          const TextStyle(
                            color:
                            Colors.white60,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // ----------------------------------------------------
                // LIST
                // ----------------------------------------------------

                return RefreshIndicator(
                  color:
                  electricYellowGreen,

                  onRefresh:
                  _cleanupOldCompletedWorks,

                  child:
                  ListView.builder(
                    padding:
                    const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      30,
                    ),

                    itemCount:
                    filteredDocuments
                        .length,

                    itemBuilder:
                        (context, index) {
                      return _workCard(
                        filteredDocuments[
                        index],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}