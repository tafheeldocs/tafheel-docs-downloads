import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'download_page.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'company_portal_screen.dart';
import 'notification_service.dart';

// ============================================================
// MAIN
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.initialize();

  runApp(const TafheelDocsApp());
}

// ============================================================
// APP
// ============================================================

class TafheelDocsApp extends StatelessWidget {
  const TafheelDocsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TAFHEEL DOCS',

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFC8F500),
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
      ),

      home: const StartPage(),
    );
  }
}

// ============================================================
// START PAGE
// ============================================================

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String path = Uri.base.path.toLowerCase();

    // ----------------------------------------------------------
    // WEB DOWNLOAD PAGE
    // ----------------------------------------------------------

    if (path == '/download' || path == '/download/') {
      return const DownloadPage();
    }

    // ----------------------------------------------------------
    // NORMAL APP
    // ----------------------------------------------------------

    return const AuthGate();
  }
}

// ============================================================
// AUTH GATE
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, authSnapshot) {
        // ------------------------------------------------------
        // AUTH LOADING
        // ------------------------------------------------------

        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // ------------------------------------------------------
        // NOT LOGGED IN
        // ------------------------------------------------------

        final User? user = authSnapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        // ------------------------------------------------------
        // LOGGED IN
        // ------------------------------------------------------

        return UserRoleGate(
          user: user,
        );
      },
    );
  }
}

// ============================================================
// USER ROLE GATE
// ============================================================

class UserRoleGate extends StatelessWidget {
  final User user;

  const UserRoleGate({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // EXISTING ADMIN ACCOUNT
    // ==========================================================
    //
    // This keeps your current admin login working even if
    // users/{uid} does not yet contain role = admin.
    //
    // Later we can remove this hard-coded email after creating
    // the proper admin role document in Firestore.
    // ==========================================================

    final String currentEmail =
        user.email?.trim().toLowerCase() ?? '';

    if (currentEmail == 'tafheel@gmail.com') {
      return const DashboardScreen();
    }

    // ==========================================================
    // CHECK USER ROLE FROM FIRESTORE
    // ==========================================================

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),

      builder: (context, userSnapshot) {
        // ------------------------------------------------------
        // ROLE LOADING
        // ------------------------------------------------------

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // ------------------------------------------------------
        // FIRESTORE ERROR
        // ------------------------------------------------------

        if (userSnapshot.hasError) {
          return _RoleErrorScreen(
            message:
            'Unable to load account information.\n\n'
                '${userSnapshot.error}',
          );
        }

        // ------------------------------------------------------
        // USER DOCUMENT
        // ------------------------------------------------------

        final Map<String, dynamic>? userData =
        userSnapshot.data?.data();

        // ------------------------------------------------------
        // NO USER ROLE DOCUMENT
        // ------------------------------------------------------

        if (userData == null) {
          return _RoleErrorScreen(
            message:
            'This account is not configured yet.\n\n'
                'User: ${user.email ?? user.uid}',
          );
        }

        // ------------------------------------------------------
        // READ ROLE
        // ------------------------------------------------------

        final String role =
            userData['role']?.toString().trim().toLowerCase() ?? '';

        // ======================================================
        // ADMIN
        // ======================================================

        if (role == 'admin') {
          return const DashboardScreen();
        }

        // ======================================================
        // COMPANY USER
        // ======================================================

        if (role == 'company') {
          final String companyId =
              userData['companyId']?.toString().trim() ?? '';

          if (companyId.isEmpty) {
            return const _RoleErrorScreen(
              message:
              'This company account is not linked to a company.\n\n'
                  'Please contact the administrator.',
            );
          }

          return CompanyPortalScreen(
            companyId: companyId,
          );
        }

        // ======================================================
        // UNKNOWN ROLE
        // ======================================================

        return _RoleErrorScreen(
          message:
          'Account role is not configured correctly.\n\n'
              'User: ${user.email ?? user.uid}',
        );
      },
    );
  }
}

// ============================================================
// LOADING SCREEN
// ============================================================

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1B2A),

      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC8F500),
        ),
      ),
    );
  }
}

// ============================================================
// ROLE ERROR SCREEN
// ============================================================

class _RoleErrorScreen extends StatelessWidget {
  final String message;

  const _RoleErrorScreen({
    required this.message,
  });

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    const Color deepNavy = Color(0xFF0D1B2A);
    const Color offWhite = Color(0xFFF0EDE8);
    const Color electricYellowGreen = Color(0xFFC8F500);
    const Color cardBg = Color(0xFF16222D);

    return Scaffold(
      backgroundColor: deepNavy,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: deepNavy,
        foregroundColor: offWhite,
        elevation: 0,

        title: const Text(
          'TAFHEEL DOCS',
          style: TextStyle(
            color: offWhite,
            fontWeight: FontWeight.w600,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(
              Icons.logout,
              color: Colors.redAccent,
            ),
          ),

          const SizedBox(width: 6),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Container(
            width: double.infinity,

            constraints: const BoxConstraints(
              maxWidth: 540,
            ),

            padding: const EdgeInsets.all(30),

            decoration: BoxDecoration(
              color: cardBg,

              borderRadius: BorderRadius.circular(22),

              border: Border.all(
                color: electricYellowGreen.withValues(
                  alpha: 0.10,
                ),
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.25,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                // ------------------------------------------------
                // ICON
                // ------------------------------------------------

                Container(
                  width: 72,
                  height: 72,

                  decoration: BoxDecoration(
                    color: electricYellowGreen.withValues(
                      alpha: 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.manage_accounts_outlined,
                    color: electricYellowGreen,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 22),

                // ------------------------------------------------
                // TITLE
                // ------------------------------------------------

                const Text(
                  'Account Setup Required',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: offWhite,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // MESSAGE
                // ------------------------------------------------

                Text(
                  message,
                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 26),

                // ------------------------------------------------
                // LOGOUT BUTTON
                // ------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 48,

                  child: ElevatedButton.icon(
                    onPressed: _logout,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: electricYellowGreen,
                      foregroundColor: deepNavy,
                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    icon: const Icon(
                      Icons.logout,
                    ),

                    label: const Text(
                      'BACK TO LOGIN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}