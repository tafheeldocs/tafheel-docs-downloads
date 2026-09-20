import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'company_detail_screen.dart';
import 'manual_reminder_screen.dart';

class CompanyListScreen extends StatelessWidget {
  const CompanyListScreen({super.key});

  static const Color deepNavy =
  Color(0xFF0D1B2A);

  static const Color offWhite =
  Color(0xFFF0EDE8);

  static const Color electricYellowGreen =
  Color(0xFFC8F500);

  static const Color mutedSlate =
  Color(0xFF3A4A5C);

  static const Color dialogBg =
  Color(0xFF1B2A38);

  Future<Map<String, String>> _createCompanyLogin({
    required String companyName,
    required String loginEmail,
    required String password,
  }) async {
    FirebaseApp? secondaryApp;

    try {
      final appName =
          'companyCreator_${DateTime.now().microsecondsSinceEpoch}';

      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: loginEmail.trim().toLowerCase(),
        password: password,
      );

      final companyUser = credential.user;
      if (companyUser == null) {
        throw Exception('Unable to create company login account.');
      }

      await companyUser.updateDisplayName(companyName);
      final uid = companyUser.uid;
      await secondaryAuth.signOut();

      return {
        'uid': uid,
        'email': loginEmail.trim().toLowerCase(),
      };
    } finally {
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }
    }
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration:
      const InputDecoration().copyWith(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white70,
        ),
        enabledBorder:
        const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white30,
          ),
        ),
        focusedBorder:
        const UnderlineInputBorder(
          borderSide: BorderSide(
            color: electricYellowGreen,
          ),
        ),
      ),
    );
  }

  void _showAddCompanyDialog(
      BuildContext context,
      ) {
    final companyNameController =
    TextEditingController();

    final tradeLicenseController =
    TextEditingController();

    final tradeExpiryController =
    TextEditingController();

    final tenancyController =
    TextEditingController();

    final tenancyExpiryController =
    TextEditingController();

    final establishmentController =
    TextEditingController();

    final establishmentExpiryController =
    TextEditingController();

    final authorizedPersonController =
    TextEditingController();

    final mobileController =
    TextEditingController();

    final emailController =
    TextEditingController();

    final loginEmailController =
    TextEditingController();

    final passwordController =
    TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: const Text(
            'Add New Company',
            style: TextStyle(
              color: offWhite,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  _textField(
                    controller:
                    companyNameController,
                    label: 'Company Name',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    tradeLicenseController,
                    label:
                    'Trade License No',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    tradeExpiryController,
                    label:
                    'Trade License Expiry (YYYY-MM-DD)',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    tenancyController,
                    label:
                    'Tenancy Contract No',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    tenancyExpiryController,
                    label:
                    'Tenancy Expiry (YYYY-MM-DD)',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    establishmentController,
                    label:
                    'Establishment Card No',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    establishmentExpiryController,
                    label:
                    'Establishment Expiry (YYYY-MM-DD)',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    authorizedPersonController,
                    label:
                    'Authorized Person Name',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    mobileController,
                    label:
                    'Mobile Number',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    emailController,
                    label: 'Email ID',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    loginEmailController,
                    label: 'Login Email',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    passwordController,
                    label: 'Temporary Password',
                    obscureText: true,
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
              icon: const Icon(Icons.save),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                electricYellowGreen,
                foregroundColor:
                deepNavy,
              ),
              onPressed: () async {
                final companyName =
                companyNameController.text.trim();
                final loginEmail =
                loginEmailController.text.trim().toLowerCase();
                final password = passwordController.text;

                if (companyName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter Company Name'),
                    ),
                  );
                  return;
                }

                if (loginEmail.isEmpty || !loginEmail.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid Login Email'),
                    ),
                  );
                  return;
                }

                if (password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Temporary Password must be at least 6 characters',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  final loginResult = await _createCompanyLogin(
                    companyName: companyName,
                    loginEmail: loginEmail,
                    password: password,
                  );

                  final authUid = loginResult['uid'];
                  if (authUid == null || authUid.isEmpty) {
                    throw Exception('Company login UID was not created.');
                  }

                  final companyReference = FirebaseFirestore.instance
                      .collection('companies')
                      .doc();
                  final companyId = companyReference.id;

                  await companyReference.set({
                    'companyName': companyName,
                    'tradeLicense': tradeLicenseController.text.trim(),
                    'tradeExpiry': tradeExpiryController.text.trim(),
                    'tenancy': tenancyController.text.trim(),
                    'tenancyExpiry': tenancyExpiryController.text.trim(),
                    'establishmentCard': establishmentController.text.trim(),
                    'establishmentExpiry':
                    establishmentExpiryController.text.trim(),
                    'authorizedPerson':
                    authorizedPersonController.text.trim(),
                    'mobile': mobileController.text.trim(),
                    'email': emailController.text.trim(),
                    'loginEmail': loginEmail,
                    'authUid': authUid,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(authUid)
                      .set({
                    'role': 'company',
                    'companyId': companyId,
                    'companyName': companyName,
                    'email': loginEmail,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Company created successfully! Login: $loginEmail',
                      ),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  String message =
                      e.message ?? 'Unable to create login account.';

                  if (e.code == 'email-already-in-use') {
                    message = 'This Login Email is already registered.';
                  } else if (e.code == 'invalid-email') {
                    message = 'Please enter a valid Login Email.';
                  } else if (e.code == 'weak-password') {
                    message =
                    'Password is too weak. Use at least 6 characters.';
                  }

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Company creation error: $e'),
                    ),
                  );
                }
              },
              label: const Text(
                'Save Company',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditCompanyDialog(
      BuildContext context,
      String companyId,
      Map<String, dynamic> companyData,
      ) {
    final companyNameController =
    TextEditingController(
      text:
      companyData['companyName']
          ?.toString() ??
          '',
    );

    final tradeLicenseController =
    TextEditingController(
      text:
      companyData['tradeLicense']
          ?.toString() ??
          '',
    );

    final tradeExpiryController =
    TextEditingController(
      text:
      companyData['tradeExpiry']
          ?.toString() ??
          '',
    );

    final tenancyController =
    TextEditingController(
      text:
      companyData['tenancy']
          ?.toString() ??
          '',
    );

    final tenancyExpiryController =
    TextEditingController(
      text:
      companyData['tenancyExpiry']
          ?.toString() ??
          '',
    );

    final establishmentController =
    TextEditingController(
      text:
      companyData[
      'establishmentCard']
          ?.toString() ??
          '',
    );

    final establishmentExpiryController =
    TextEditingController(
      text:
      companyData[
      'establishmentExpiry']
          ?.toString() ??
          '',
    );

    final authorizedPersonController =
    TextEditingController(
      text:
      companyData[
      'authorizedPerson']
          ?.toString() ??
          '',
    );

    final mobileController =
    TextEditingController(
      text:
      companyData['mobile']
          ?.toString() ??
          '',
    );

    final emailController =
    TextEditingController(
      text:
      companyData['email']
          ?.toString() ??
          '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: const Text(
            'Modify Company Information',
            style: TextStyle(
              color: offWhite,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  _textField(
                    controller:
                    companyNameController,
                    label:
                    'Company Name',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    tradeLicenseController,
                    label:
                    'Trade License No',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    tradeExpiryController,
                    label:
                    'Trade License Expiry (YYYY-MM-DD)',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    tenancyController,
                    label:
                    'Tenancy Contract No',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    tenancyExpiryController,
                    label:
                    'Tenancy Expiry (YYYY-MM-DD)',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    establishmentController,
                    label:
                    'Establishment Card No',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    establishmentExpiryController,
                    label:
                    'Establishment Expiry (YYYY-MM-DD)',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    authorizedPersonController,
                    label:
                    'Authorized Person Name',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    mobileController,
                    label:
                    'Mobile Number',
                  ),
                  const SizedBox(
                      height: 12),

                  _textField(
                    controller:
                    emailController,
                    label: 'Email ID',
                  ),
                  const SizedBox(
                      height: 12),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Login Email: ${companyData['loginEmail']?.toString() ?? 'Not configured'}',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
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
              icon: const Icon(Icons.save),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                electricYellowGreen,
                foregroundColor:
                deepNavy,
              ),
              onPressed: () async {
                final companyName =
                companyNameController
                    .text
                    .trim();

                if (companyName.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Company Name cannot be empty',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore
                      .instance
                      .collection(
                    'companies',
                  )
                      .doc(companyId)
                      .update({
                    'companyName':
                    companyName,

                    'tradeLicense':
                    tradeLicenseController
                        .text
                        .trim(),

                    'tradeExpiry':
                    tradeExpiryController
                        .text
                        .trim(),

                    'tenancy':
                    tenancyController
                        .text
                        .trim(),

                    'tenancyExpiry':
                    tenancyExpiryController
                        .text
                        .trim(),

                    'establishmentCard':
                    establishmentController
                        .text
                        .trim(),

                    'establishmentExpiry':
                    establishmentExpiryController
                        .text
                        .trim(),

                    'authorizedPerson':
                    authorizedPersonController
                        .text
                        .trim(),

                    'mobile':
                    mobileController
                        .text
                        .trim(),

                    'email':
                    emailController
                        .text
                        .trim(),

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

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Company information updated successfully!',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!dialogContext
                      .mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Update error: $e',
                      ),
                    ),
                  );
                }
              },
              label: const Text(
                'Update Company',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCompany(
      BuildContext context,
      String companyId,
      String companyName,
      ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: const Text(
            'Delete Company?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete '
                '"$companyName"?\n\n'
                'All employees under this company will also be deleted.',
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
                style: TextStyle(
                  color: Colors.white70,
                ),
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
              icon: const Icon(
                Icons.delete_forever,
              ),
              label: const Text(
                'Delete All',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final FirebaseFirestore firestore =
          FirebaseFirestore.instance;

      final DocumentReference<Map<String, dynamic>>
      companyRef = firestore
          .collection('companies')
          .doc(companyId);

      // ==========================================================
      // 1. GET ALL EMPLOYEES OF THIS COMPANY
      // ==========================================================

      final QuerySnapshot<Map<String, dynamic>>
      employeeSnapshot = await companyRef
          .collection('employees')
          .get();

      // ==========================================================
      // 2. DELETE EMPLOYEES IN BATCHES
      // Firestore batch limit is 500 operations.
      // ==========================================================

      const int batchSize = 450;

      for (
      int start = 0;
      start < employeeSnapshot.docs.length;
      start += batchSize
      ) {
        final int end =
        (start + batchSize < employeeSnapshot.docs.length)
            ? start + batchSize
            : employeeSnapshot.docs.length;

        final WriteBatch batch = firestore.batch();

        for (int i = start; i < end; i++) {
          batch.delete(
            employeeSnapshot.docs[i].reference,
          );
        }

        await batch.commit();
      }

      // ==========================================================
      // 3. DELETE COMPANY ROLE DOCUMENT
      // ==========================================================

      final DocumentSnapshot<Map<String, dynamic>>
      companySnapshot = await companyRef.get();

      final Map<String, dynamic>? companyData =
      companySnapshot.data();

      final String authUid =
          companyData?['authUid']
              ?.toString()
              .trim() ??
              '';

      if (authUid.isNotEmpty) {
        await firestore
            .collection('users')
            .doc(authUid)
            .delete();
      }

      // ==========================================================
      // 4. DELETE COMPANY
      // ==========================================================

      await companyRef.delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$companyName and all employees deleted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delete error: $e',
          ),
        ),
      );
    }
  }

  void _openCompanyReminder(
      BuildContext context,
      Map<String, dynamic> data,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: dialogBg,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                const Text(
                  'Select Document',
                  style: TextStyle(
                    color:
                    electricYellowGreen,
                    fontSize: 20,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                    height: 20),

                _companyDocumentButton(
                  context: sheetContext,
                  title:
                  'Trade License',
                  number:
                  data['tradeLicense']
                      ?.toString() ??
                      '',
                  expiry:
                  data['tradeExpiry']
                      ?.toString() ??
                      '',
                  companyName:
                  data['companyName']
                      ?.toString() ??
                      '',
                  mobile:
                  data['mobile']
                      ?.toString() ??
                      '',
                  email:
                  data['email']
                      ?.toString() ??
                      '',
                  icon:
                  Icons.description,
                ),

                _companyDocumentButton(
                  context: sheetContext,
                  title:
                  'Tenancy Contract',
                  number:
                  data['tenancy']
                      ?.toString() ??
                      '',
                  expiry:
                  data['tenancyExpiry']
                      ?.toString() ??
                      '',
                  companyName:
                  data['companyName']
                      ?.toString() ??
                      '',
                  mobile:
                  data['mobile']
                      ?.toString() ??
                      '',
                  email:
                  data['email']
                      ?.toString() ??
                      '',
                  icon:
                  Icons.home_work,
                ),

                _companyDocumentButton(
                  context: sheetContext,
                  title:
                  'Establishment Card',
                  number:
                  data['establishmentCard']
                      ?.toString() ??
                      '',
                  expiry:
                  data['establishmentExpiry']
                      ?.toString() ??
                      '',
                  companyName:
                  data['companyName']
                      ?.toString() ??
                      '',
                  mobile:
                  data['mobile']
                      ?.toString() ??
                      '',
                  email:
                  data['email']
                      ?.toString() ??
                      '',
                  icon:
                  Icons.badge,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _companyDocumentButton({
    required BuildContext context,
    required String title,
    required String number,
    required String expiry,
    required String companyName,
    required String mobile,
    required String email,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      child: ElevatedButton.icon(
        style:
        ElevatedButton.styleFrom(
          backgroundColor: mutedSlate,
          foregroundColor: Colors.white,
          padding:
          const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 15,
          ),
        ),
        onPressed: () {
          Navigator.pop(context);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ManualReminderScreen(
                    type: 'Company',
                    referenceName:
                    companyName,
                    phone: mobile,
                    email: email,
                    documentType: title,
                    documentNumber: number,
                    expiryDate: expiry,
                  ),
            ),
          );
        },
        icon: Icon(
          icon,
          color:
          electricYellowGreen,
        ),
        label: Row(
          children: [
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
              expiry.isEmpty
                  ? 'N/A'
                  : expiry,
              style:
              const TextStyle(
                color:
                Colors.orangeAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor: deepNavy,

      appBar: AppBar(
        backgroundColor: deepNavy,
        elevation: 0,
        iconTheme:
        const IconThemeData(
          color: offWhite,
        ),
        title: const Text(
          'Company Information',
          style: TextStyle(
            color: offWhite,
            fontWeight:
            FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding:
            const EdgeInsets.only(
              right: 16,
            ),
            child:
            ElevatedButton.icon(
              onPressed: () {
                _showAddCompanyDialog(
                  context,
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
                    8,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.add,
                size: 18,
              ),
              label: const Text(
                'Add Company',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding:
        const EdgeInsets.all(24),
        child: StreamBuilder<
            QuerySnapshot>(
          stream:
          FirebaseFirestore.instance
              .collection(
            'companies',
          )
              .orderBy(
            'createdAt',
            descending: true,
          )
              .snapshots(),

          builder: (
              context,
              snapshot,
              ) {
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

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading companies:\n'
                      '${snapshot.error}',
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
                snapshot
                    .data!
                    .docs
                    .isEmpty) {
              return const Center(
                child: Text(
                  'No companies found.\n\n'
                      'Click "Add Company" to add your first company.',
                  textAlign:
                  TextAlign.center,
                  style:
                  TextStyle(
                    color:
                    Colors.white54,
                    fontSize: 14,
                  ),
                ),
              );
            }

            final companies =
                snapshot.data!.docs;

            return ListView.builder(
              itemCount:
              companies.length,
              itemBuilder: (
                  context,
                  index,
                  ) {
                final companyDocument =
                companies[index];

                final companyId =
                    companyDocument.id;

                final companyData =
                companyDocument.data()
                as Map<String, dynamic>;

                final companyName =
                    companyData[
                    'companyName']
                        ?.toString() ??
                        'Unnamed Company';

                final tradeLicense =
                    companyData[
                    'tradeLicense']
                        ?.toString() ??
                        'N/A';

                final authorizedPerson =
                    companyData[
                    'authorizedPerson']
                        ?.toString() ??
                        'N/A';

                final mobile =
                    companyData['mobile']
                        ?.toString() ??
                        'N/A';

                return Container(
                  margin:
                  const EdgeInsets.only(
                    bottom: 12,
                  ),
                  decoration:
                  BoxDecoration(
                    color: mutedSlate
                        .withValues(
                      alpha: 0.3,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                    border:
                    Border.all(
                      color: offWhite
                          .withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                  child: ListTile(
                    contentPadding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),

                    leading:
                    const CircleAvatar(
                      backgroundColor:
                      electricYellowGreen,
                      child: Icon(
                        Icons.business,
                        color: deepNavy,
                      ),
                    ),

                    title: Text(
                      companyName,
                      style:
                      const TextStyle(
                        color: offWhite,
                        fontWeight:
                        FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    subtitle: Padding(
                      padding:
                      const EdgeInsets
                          .only(
                        top: 5,
                      ),
                      child: Text(
                        'Trade License: $tradeLicense\n'
                            'Authorized: $authorizedPerson\n'
                            'Mobile: $mobile',
                        style:
                        TextStyle(
                          color:
                          offWhite
                              .withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),

                    trailing: Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip:
                          'Expiry Reminder',
                          icon:
                          const Icon(
                            Icons
                                .notifications_active,
                            color:
                            Colors.orangeAccent,
                            size: 21,
                          ),
                          onPressed: () {
                            _openCompanyReminder(
                              context,
                              companyData,
                            );
                          },
                        ),

                        IconButton(
                          tooltip:
                          'Modify Company',
                          icon:
                          const Icon(
                            Icons
                                .edit_rounded,
                            color:
                            Colors.amberAccent,
                            size: 21,
                          ),
                          onPressed: () {
                            _showEditCompanyDialog(
                              context,
                              companyId,
                              companyData,
                            );
                          },
                        ),

                        IconButton(
                          tooltip:
                          'Delete Company',
                          icon:
                          const Icon(
                            Icons
                                .delete_outline,
                            color:
                            Colors.redAccent,
                            size: 21,
                          ),
                          onPressed: () {
                            _deleteCompany(
                              context,
                              companyId,
                              companyName,
                            );
                          },
                        ),

                        const SizedBox(
                            width: 4),

                        const Icon(
                          Icons
                              .arrow_forward_ios_rounded,
                          color: offWhite,
                          size: 16,
                        ),
                      ],
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CompanyDetailScreen(
                                companyId:
                                companyId,
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
    );
  }
}
