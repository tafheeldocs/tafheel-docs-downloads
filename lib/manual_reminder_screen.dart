import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'notification_service.dart';

class ManualReminderScreen extends StatefulWidget {
  final String? type;
  final String? referenceName;
  final String? phone;
  final String? email;

  final String? documentType;
  final String? documentNumber;
  final String? expiryDate;

  const ManualReminderScreen({
    super.key,
    this.type,
    this.referenceName,
    this.phone,
    this.email,
    this.documentType,
    this.documentNumber,
    this.expiryDate,
  });

  @override
  State<ManualReminderScreen> createState() =>
      _ManualReminderScreenState();
}

class _ManualReminderScreenState
    extends State<ManualReminderScreen> {
  static const Color deepNavy = Color(0xFF0D1B2A);
  static const Color cardBg = Color(0xFF16222D);
  static const Color dialogBg = Color(0xFF1B2A38);
  static const Color electricYellowGreen =
  Color(0xFFC8F500);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
  get _remindersCollection {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return _firestore
          .collection('users')
          .doc('unknown')
          .collection('manual_reminders');
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('manual_reminders');
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == 'N/A') {
      return null;
    }

    try {
      return DateTime.parse(text);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';

    return DateFormat('dd MMM yyyy').format(date);
  }

  Future<void> _showReminderDialog({
    DocumentSnapshot<Map<String, dynamic>>? existing,
  }) async {
    final data = existing?.data();

    String reminderType =
        data?['type']?.toString() ??
            widget.type ??
            'Company';

    String selectedDocument =
        data?['documentType']?.toString() ??
            widget.documentType ??
            'Document';

    final nameController = TextEditingController(
      text: data?['referenceName']?.toString() ??
          widget.referenceName ??
          '',
    );

    final phoneController = TextEditingController(
      text: data?['phone']?.toString() ??
          widget.phone ??
          '',
    );

    final emailController = TextEditingController(
      text: data?['email']?.toString() ??
          widget.email ??
          '',
    );

    final documentNumberController =
    TextEditingController(
      text: data?['documentNumber']?.toString() ??
          widget.documentNumber ??
          '',
    );

    final expiryDateController =
    TextEditingController(
      text: data?['expiryDate']?.toString() ??
          widget.expiryDate ??
          '',
    );

    final titleController = TextEditingController(
      text: data?['title']?.toString() ??
          '${widget.documentType ?? 'Document'} Expiry Reminder',
    );

    final messageController = TextEditingController(
      text: data?['message']?.toString() ??
          'Please check the $selectedDocument expiry for ${widget.referenceName ?? 'this record'}.',
    );

    DateTime reminderDate =
    data?['reminderAt'] is Timestamp
        ? (data!['reminderAt'] as Timestamp).toDate()
        : DateTime.now().add(
      const Duration(hours: 1),
    );

    TimeOfDay reminderTime =
    TimeOfDay.fromDateTime(reminderDate);

    final companyDocuments = [
      'Trade License',
      'Tenancy Contract',
      'Establishment Card',
    ];

    final employeeDocuments = [
      'Visa',
      'Labour Card',
      'OHC Card',
    ];

    final availableDocuments =
    reminderType == 'Employee'
        ? employeeDocuments
        : companyDocuments;

    if (!availableDocuments.contains(selectedDocument)) {
      selectedDocument = availableDocuments.first;
    }

    void updateDocumentDefaults(
        String document,
        void Function(void Function()) setDialogState,
        ) {
      setDialogState(() {
        selectedDocument = document;

        if (existing == null) {
          titleController.text =
          '$document Expiry Reminder';

          messageController.text =
          'Please check the $document expiry for '
              '${nameController.text.trim().isEmpty ? 'this record' : nameController.text.trim()}.';
        }
      });
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            final currentDocuments =
            reminderType == 'Employee'
                ? employeeDocuments
                : companyDocuments;

            if (!currentDocuments.contains(
              selectedDocument,
            )) {
              selectedDocument =
                  currentDocuments.first;
            }

            return AlertDialog(
              backgroundColor: dialogBg,
              title: Text(
                existing == null
                    ? 'Add Expiry Reminder'
                    : 'Edit Expiry Reminder',
                style: const TextStyle(
                  color: electricYellowGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: reminderType,
                        dropdownColor: dialogBg,
                        decoration:
                        const InputDecoration(
                          labelText: 'Reminder For',
                          labelStyle: TextStyle(
                            color: Colors.white70,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Company',
                            child: Text(
                              'Company',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Employee',
                            child: Text(
                              'Employee',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setDialogState(() {
                            reminderType = value;

                            if (value == 'Employee') {
                              selectedDocument =
                                  employeeDocuments
                                      .first;

                              if (existing == null) {
                                titleController.text =
                                'Visa Expiry Reminder';
                                messageController.text =
                                'Please check the Visa expiry.';
                              }
                            } else {
                              selectedDocument =
                                  companyDocuments
                                      .first;

                              if (existing == null) {
                                titleController.text =
                                'Trade License Expiry Reminder';
                                messageController.text =
                                'Please check the Trade License expiry.';
                              }
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        value: selectedDocument,
                        dropdownColor: dialogBg,
                        decoration:
                        const InputDecoration(
                          labelText: 'Document',
                          labelStyle: TextStyle(
                            color: Colors.white70,
                          ),
                          prefixIcon: Icon(
                            Icons.description,
                            color:
                            electricYellowGreen,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                        items: currentDocuments
                            .map(
                              (document) =>
                              DropdownMenuItem(
                                value: document,
                                child: Text(
                                  document,
                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.white,
                                  ),
                                ),
                              ),
                        )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          updateDocumentDefaults(
                            value,
                            setDialogState,
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: nameController,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Company / Employee Name',
                          labelStyle: TextStyle(
                            color: Colors.white70,
                          ),
                          prefixIcon: Icon(
                            Icons.person,
                            color:
                            electricYellowGreen,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller:
                        documentNumberController,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Document Number',
                          labelStyle: TextStyle(
                            color: Colors.white70,
                          ),
                          prefixIcon: Icon(
                            Icons.numbers,
                            color:
                            electricYellowGreen,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller:
                        expiryDateController,
                        readOnly: true,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration:
                        const InputDecoration(
                          labelText: 'Expiry Date',
                          labelStyle: TextStyle(
                            color: Colors.white70,
                          ),
                          prefixIcon: Icon(
                            Icons.event,
                            color: Colors.orange,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: phoneController,
                        keyboardType:
                        TextInputType.phone,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration:
                        const InputDecoration(
                          labelText:
                          'WhatsApp Number',
                          hintText:
                          '+971xxxxxxxxx',
                          hintStyle: TextStyle(
                            color: Colors.white38,
                          ),
                          labelStyle: TextStyle(
                            color: Colors.white70,
                          ),
                          prefixIcon: Icon(
                            Icons.phone,
                            color: Colors.green,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: emailController,
                        keyboardType:
                        TextInputType.emailAddress,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration:
                        const InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            color: Colors.white70,
                          ),
                          prefixIcon: Icon(
                            Icons.email,
                            color: Colors.orange,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: titleController,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Reminder Title',
                          labelStyle: TextStyle(
                            color: Colors.white70,
                          ),
                          prefixIcon: Icon(
                            Icons.title,
                            color:
                            electricYellowGreen,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: messageController,
                        maxLines: 4,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Reminder Message',
                          labelStyle: TextStyle(
                            color: Colors.white70,
                          ),
                          alignLabelWithHint: true,
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      ListTile(
                        contentPadding:
                        EdgeInsets.zero,
                        leading: const Icon(
                          Icons.calendar_month,
                          color:
                          electricYellowGreen,
                        ),
                        title: const Text(
                          'Reminder Date',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat(
                            'dd MMM yyyy',
                          ).format(reminderDate),
                          style:
                          const TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        onTap: () async {
                          final selected =
                          await showDatePicker(
                            context: context,
                            initialDate:
                            reminderDate.isBefore(
                              DateTime.now(),
                            )
                                ? DateTime.now()
                                : reminderDate,
                            firstDate:
                            DateTime.now(),
                            lastDate:
                            DateTime(2100),
                          );

                          if (selected != null) {
                            setDialogState(() {
                              reminderDate =
                                  DateTime(
                                    selected.year,
                                    selected.month,
                                    selected.day,
                                    reminderTime.hour,
                                    reminderTime.minute,
                                  );
                            });
                          }
                        },
                      ),

                      ListTile(
                        contentPadding:
                        EdgeInsets.zero,
                        leading: const Icon(
                          Icons.access_time,
                          color:
                          electricYellowGreen,
                        ),
                        title: const Text(
                          'Reminder Time',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        subtitle: Text(
                          reminderTime.format(
                            context,
                          ),
                          style:
                          const TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        onTap: () async {
                          final selected =
                          await showTimePicker(
                            context: context,
                            initialTime:
                            reminderTime,
                          );

                          if (selected != null) {
                            setDialogState(() {
                              reminderTime =
                                  selected;

                              reminderDate =
                                  DateTime(
                                    reminderDate.year,
                                    reminderDate.month,
                                    reminderDate.day,
                                    selected.hour,
                                    selected.minute,
                                  );
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
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
                  onPressed: () async {
                    final name =
                    nameController.text.trim();

                    final title =
                    titleController.text.trim();

                    final message =
                    messageController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter name.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (title.isEmpty ||
                        message.isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter title and message.',
                          ),
                        ),
                      );
                      return;
                    }

                    final finalReminderDate =
                    DateTime(
                      reminderDate.year,
                      reminderDate.month,
                      reminderDate.day,
                      reminderTime.hour,
                      reminderTime.minute,
                    );

                    if (finalReminderDate
                        .isBefore(DateTime.now())) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select a future reminder date and time.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      final reminderId =
                          existing?.id ??
                              DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString();

                      final notificationId =
                      reminderId.hashCode.abs();

                      final reminderData =
                      <String, dynamic>{
                        'type': reminderType,
                        'referenceName': name,
                        'documentType':
                        selectedDocument,
                        'documentNumber':
                        documentNumberController
                            .text
                            .trim(),
                        'expiryDate':
                        expiryDateController
                            .text
                            .trim(),
                        'phone':
                        phoneController.text
                            .trim(),
                        'email':
                        emailController.text
                            .trim(),
                        'title': title,
                        'message': message,
                        'reminderAt':
                        Timestamp.fromDate(
                          finalReminderDate,
                        ),
                        'notificationId':
                        notificationId,
                        'updatedAt':
                        FieldValue
                            .serverTimestamp(),
                      };

                      if (existing == null) {
                        reminderData['createdAt'] =
                            FieldValue
                                .serverTimestamp();

                        await _remindersCollection
                            .doc(reminderId)
                            .set(
                          reminderData,
                        );
                      } else {
                        final oldNotificationId =
                        data?[
                        'notificationId'];

                        if (oldNotificationId
                        is int) {
                          await NotificationService
                              .cancelReminder(
                            oldNotificationId,
                          );
                        }

                        await _remindersCollection
                            .doc(existing.id)
                            .update(
                          reminderData,
                        );
                      }

                      await NotificationService
                          .scheduleManualReminder(
                        id: notificationId,
                        title: title,
                        body:
                        '$name - $selectedDocument - $message',
                        reminderDateTime:
                        finalReminderDate,
                      );

                      if (!mounted) return;

                      Navigator.pop(
                        dialogContext,
                      );

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            existing == null
                                ? 'Expiry reminder saved successfully.'
                                : 'Expiry reminder updated successfully.',
                          ),
                          backgroundColor:
                          Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error saving reminder: $e',
                          ),
                          backgroundColor:
                          Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Reminder'),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    electricYellowGreen,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    documentNumberController.dispose();
    expiryDateController.dispose();
    titleController.dispose();
    messageController.dispose();
  }

  Future<void> _deleteReminder(
      DocumentSnapshot<Map<String, dynamic>>
      reminder,
      ) async {
    final data = reminder.data();

    final notificationId =
    data?['notificationId'];

    final shouldDelete =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: const Text(
            'Delete Reminder?',
            style: TextStyle(
              color: electricYellowGreen,
            ),
          ),
          content: Text(
            data?['title']?.toString() ??
                'This reminder',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    false,
                  ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    true,
                  ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.red,
                foregroundColor:
                Colors.white,
              ),
              child:
              const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      if (notificationId is int) {
        await NotificationService
            .cancelReminder(
          notificationId,
        );
      }

      await _remindersCollection
          .doc(reminder.id)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text('Reminder deleted.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text('Error deleting reminder: $e'),
        ),
      );
    }
  }

  Future<void> _openWhatsApp(
      Map<String, dynamic> data,
      ) async {
    final phone =
        data['phone']?.toString().trim() ??
            '';

    if (phone.isEmpty) {
      _showMessage(
        'WhatsApp number is not available.',
      );
      return;
    }

    String cleanPhone =
    phone.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (cleanPhone.startsWith('00')) {
      cleanPhone =
          cleanPhone.substring(2);
    }

    final name =
        data['referenceName']
            ?.toString() ??
            '';

    final document =
        data['documentType']
            ?.toString() ??
            'Document';

    final expiry =
        data['expiryDate']
            ?.toString() ??
            '';

    final message =
        data['message']?.toString() ??
            '';

    final text =
        'Hello $name,\n\n'
        '$document expiry: $expiry\n\n'
        '$message\n\n'
        'Regards,\nTAFHEEL DOCS';

    final uri = Uri.parse(
      'https://wa.me/$cleanPhone?text='
          '${Uri.encodeComponent(text)}',
    );

    try {
      final launched =
      await launchUrl(
        uri,
        mode:
        LaunchMode.externalApplication,
      );

      if (!launched) {
        _showMessage(
          'Could not open WhatsApp.',
        );
      }
    } catch (_) {
      _showMessage(
        'Could not open WhatsApp.',
      );
    }
  }

  Future<void> _openEmail(
      Map<String, dynamic> data,
      ) async {
    final email =
        data['email']?.toString().trim() ??
            '';

    if (email.isEmpty) {
      _showMessage(
        'Email address is not available.',
      );
      return;
    }

    final subject =
        data['title']?.toString() ??
            'TAFHEEL DOCS Reminder';

    final name =
        data['referenceName']
            ?.toString() ??
            '';

    final document =
        data['documentType']
            ?.toString() ??
            'Document';

    final expiry =
        data['expiryDate']
            ?.toString() ??
            '';

    final message =
        data['message']?.toString() ??
            '';

    final body =
        'Hello $name,\n\n'
        '$document expiry: $expiry\n\n'
        '$message\n\n'
        'Regards,\nTAFHEEL DOCS';

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query:
      'subject=${Uri.encodeComponent(subject)}'
          '&body=${Uri.encodeComponent(body)}',
    );

    try {
      final launched =
      await launchUrl(
        uri,
        mode:
        LaunchMode.externalApplication,
      );

      if (!launched) {
        _showMessage(
          'Could not open email app.',
        );
      }
    } catch (_) {
      _showMessage(
        'Could not open email app.',
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        backgroundColor: deepNavy,
        foregroundColor: Colors.white,
        title: const Text(
          'Manual Expiry Reminders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showReminderDialog();
            },
            icon: const Icon(
              Icons.add_alert,
              color:
              electricYellowGreen,
            ),
          ),
        ],
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _remindersCollection
            .orderBy(
          'reminderAt',
          descending: false,
        )
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
                const EdgeInsets.all(20),
                child: Text(
                  'Error loading reminders:\n'
                      '${snapshot.error}',
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    color:
                    Colors.white70,
                  ),
                ),
              ),
            );
          }

          final reminders =
              snapshot.data?.docs ?? [];

          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 70,
                    color:
                    electricYellowGreen,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'No expiry reminders',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a reminder for a company or employee document.',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      color:
                      Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showReminderDialog();
                    },
                    icon: const Icon(
                      Icons.add_alert,
                    ),
                    label: const Text(
                      'ADD REMINDER',
                    ),
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      electricYellowGreen,
                      foregroundColor:
                      Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding:
            const EdgeInsets.all(12),
            itemCount:
            reminders.length,
            itemBuilder: (
                context,
                index,
                ) {
              final reminder =
              reminders[index];

              final data =
              reminder.data();

              final reminderAt =
              data['reminderAt']
              is Timestamp
                  ? (data['reminderAt']
              as Timestamp)
                  .toDate()
                  : null;

              final type =
                  data['type']
                      ?.toString() ??
                      'Company';

              final name =
                  data['referenceName']
                      ?.toString() ??
                      '';

              final document =
                  data['documentType']
                      ?.toString() ??
                      'Document';

              final expiry =
                  data['expiryDate']
                      ?.toString() ??
                      'N/A';

              final title =
                  data['title']
                      ?.toString() ??
                      '';

              final message =
                  data['message']
                      ?.toString() ??
                      '';

              return Card(
                color: cardBg,
                margin:
                const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.all(
                    14,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                            electricYellowGreen,
                            child: Icon(
                              type ==
                                  'Employee'
                                  ? Icons.person
                                  : Icons.business,
                              color:
                              Colors.black,
                            ),
                          ),
                          const SizedBox(
                              width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  title,
                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.white,
                                    fontSize:
                                    17,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),
                                const SizedBox(
                                    height: 4),
                                Text(
                                  '$type • $name',
                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<
                              String>(
                            icon:
                            const Icon(
                              Icons.more_vert,
                              color:
                              Colors.white70,
                            ),
                            color:
                            dialogBg,
                            onSelected:
                                (value) {
                              if (value ==
                                  'edit') {
                                _showReminderDialog(
                                  existing:
                                  reminder,
                                );
                              } else if (value ==
                                  'delete') {
                                _deleteReminder(
                                  reminder,
                                );
                              }
                            },
                            itemBuilder:
                                (context) {
                              return const [
                                PopupMenuItem(
                                  value:
                                  'edit',
                                  child:
                                  Text(
                                    'Edit',
                                    style:
                                    TextStyle(
                                      color:
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value:
                                  'delete',
                                  child:
                                  Text(
                                    'Delete',
                                    style:
                                    TextStyle(
                                      color:
                                      Colors.red,
                                    ),
                                  ),
                                ),
                              ];
                            },
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 12),

                      Container(
                        width:
                        double.infinity,
                        padding:
                        const EdgeInsets
                            .all(10),
                        decoration:
                        BoxDecoration(
                          borderRadius:
                          BorderRadius
                              .circular(
                            10,
                          ),
                          border:
                          Border.all(
                            color:
                            electricYellowGreen,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              'Document: $document',
                              style:
                              const TextStyle(
                                color:
                                Colors.white,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                            const SizedBox(
                                height: 5),
                            Text(
                              'Expiry: $expiry',
                              style:
                              const TextStyle(
                                color:
                                Colors.orangeAccent,
                              ),
                            ),
                            if (reminderAt !=
                                null) ...[
                              const SizedBox(
                                  height: 5),
                              Text(
                                'Reminder: ${DateFormat('dd MMM yyyy • hh:mm a').format(reminderAt)}',
                                style:
                                const TextStyle(
                                  color:
                                  electricYellowGreen,
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(
                          height: 12),

                      Text(
                        message,
                        style:
                        const TextStyle(
                          color:
                          Colors.white70,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(
                          height: 14),

                      Row(
                        children: [
                          Expanded(
                            child:
                            OutlinedButton.icon(
                              onPressed: () {
                                _openWhatsApp(
                                  data,
                                );
                              },
                              icon:
                              const Icon(
                                Icons.chat,
                                color:
                                Colors.green,
                              ),
                              label:
                              const Text(
                                'WhatsApp',
                                style:
                                TextStyle(
                                  color:
                                  Colors.green,
                                ),
                              ),
                              style:
                              OutlinedButton
                                  .styleFrom(
                                side:
                                const BorderSide(
                                  color:
                                  Colors.green,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                              width: 10),
                          Expanded(
                            child:
                            OutlinedButton.icon(
                              onPressed: () {
                                _openEmail(
                                  data,
                                );
                              },
                              icon:
                              const Icon(
                                Icons.email,
                                color:
                                Colors.orange,
                              ),
                              label:
                              const Text(
                                'Email',
                                style:
                                TextStyle(
                                  color:
                                  Colors.orange,
                                ),
                              ),
                              style:
                              OutlinedButton
                                  .styleFrom(
                                side:
                                const BorderSide(
                                  color:
                                  Colors.orange,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: () {
          _showReminderDialog();
        },
        backgroundColor:
        electricYellowGreen,
        foregroundColor: Colors.black,
        icon: const Icon(
          Icons.add_alert,
        ),
        label: const Text(
          'Add Reminder',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),
    );
  }
}