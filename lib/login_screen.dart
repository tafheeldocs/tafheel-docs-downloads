import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
const LoginScreen({super.key});

@override
State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
final TextEditingController _emailController =
TextEditingController();

final TextEditingController _passwordController =
TextEditingController();

bool _isLoading = false;
bool _obscurePassword = true;

// ============================================================
// LOGIN
// ============================================================
Future<void> _handleLogin() async {
if (_isLoading) return;

final email = _emailController.text.trim();
final password = _passwordController.text;

if (email.isEmpty) {
_showMessage('Please enter your email address.');
return;
}

if (password.isEmpty) {
_showMessage('Please enter your password.');
return;
}

setState(() {
_isLoading = true;
});

try {
debugPrint('LOGIN STARTED');
debugPrint('EMAIL: $email');

await FirebaseAuth.instance.signInWithEmailAndPassword(
email: email,
password: password,
);

debugPrint('LOGIN SUCCESS');
debugPrint(
'CURRENT USER: ${FirebaseAuth.instance.currentUser?.email}',
);

// Do NOT navigate manually.
// AuthGate in main.dart will automatically
// show DashboardScreen when authentication succeeds.
} on FirebaseAuthException catch (e) {
debugPrint('FIREBASE LOGIN ERROR: ${e.code}');
debugPrint('MESSAGE: ${e.message}');

String message;

switch (e.code) {
case 'user-not-found':
message = 'No account found with this email.';
break;

case 'wrong-password':
message = 'Incorrect password.';
break;

case 'invalid-credential':
message = 'Incorrect email or password.';
break;

case 'invalid-email':
message = 'Please enter a valid email address.';
break;

case 'user-disabled':
message = 'This account has been disabled.';
break;

case 'too-many-requests':
message =
'Too many login attempts. Please try again later.';
break;

case 'network-request-failed':
message =
'Network error. Please check your internet connection.';
break;

case 'operation-not-allowed':
message =
'Email/Password login is not enabled in Firebase.';
break;

default:
message =
e.message ?? 'Login failed. Please try again.';
}

if (mounted) {
_showMessage(message);
}
} catch (e) {
debugPrint('LOGIN ERROR: $e');

if (mounted) {
_showMessage('Login error. Please try again.');
}
} finally {
if (mounted) {
setState(() {
_isLoading = false;
});
}
}
}

// ============================================================
// FORGOT PASSWORD
// ============================================================
Future<void> _handlePasswordReset() async {
final email = _emailController.text.trim();

if (email.isEmpty) {
_showMessage(
'Please enter your email address first.',
);
return;
}

try {
await FirebaseAuth.instance.sendPasswordResetEmail(
email: email,
);

if (mounted) {
_showMessage(
'Password reset link has been sent to your email.',
);
}
} on FirebaseAuthException catch (e) {
String message;

switch (e.code) {
case 'invalid-email':
message = 'Please enter a valid email address.';
break;

case 'user-not-found':
message = 'No account found with this email.';
break;

default:
message =
e.message ??
'Unable to send password reset email.';
}

if (mounted) {
_showMessage(message);
}
} catch (e) {
if (mounted) {
_showMessage(
'Unable to send password reset email.',
);
}
}
}

// ============================================================
// MESSAGE
// ============================================================
void _showMessage(String message) {
if (!mounted) return;

ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(message),
behavior: SnackBarBehavior.floating,
),
);
}

// ============================================================
// SIGN UP
// ============================================================
void _openSignup() {
if (_isLoading) return;

Navigator.push(
context,
MaterialPageRoute(
builder: (context) => const SignupScreen(),
),
);
}

// ============================================================
// DISPOSE
// ============================================================
@override
void dispose() {
_emailController.dispose();
_passwordController.dispose();
super.dispose();
}

// ============================================================
// BUILD
// ============================================================
@override
Widget build(BuildContext context) {
const Color deepNavy = Color(0xFF0D1B2A);
const Color offWhite = Color(0xFFF0EDE8);
const Color electricYellowGreen = Color(0xFFC8F500);
const Color dialogBg = Color(0xFF1B2A38);

return Scaffold(
backgroundColor: deepNavy,
body: SafeArea(
child: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Container(
constraints: const BoxConstraints(
maxWidth: 420,
),
padding: const EdgeInsets.all(32),
decoration: BoxDecoration(
color: dialogBg,
borderRadius: BorderRadius.circular(24),
border: Border.all(
color: electricYellowGreen.withValues(
alpha: 0.20,
),
),
boxShadow: [
BoxShadow(
color: Colors.black.withValues(
alpha: 0.40,
),
blurRadius: 20,
offset: const Offset(0, 10),
),
],
),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment:
CrossAxisAlignment.stretch,
children: [
// ==================================================
// LOGO
// ==================================================
Center(
child: Image.asset(
'images/logo.png',
height: 70,
width: 70,
fit: BoxFit.contain,
errorBuilder:
(context, error, stackTrace) {
return Container(
height: 70,
width: 70,
decoration: BoxDecoration(
color: electricYellowGreen,
borderRadius:
BorderRadius.circular(14),
),
child: const Icon(
Icons.business_center,
color: deepNavy,
size: 36,
),
);
},
),
),

const SizedBox(height: 18),

// ==================================================
// APP NAME
// ==================================================
const Text(
'TAFHEEL DOCS',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 26,
fontWeight: FontWeight.bold,
letterSpacing: 1.2,
color: offWhite,
),
),

const SizedBox(height: 8),

Text(
'Company & Document Management',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 13,
color: offWhite.withValues(
alpha: 0.60,
),
),
),

const SizedBox(height: 32),

// ==================================================
// EMAIL
// ==================================================
TextField(
controller: _emailController,
keyboardType:
TextInputType.emailAddress,
textInputAction:
TextInputAction.next,
enabled: !_isLoading,
style: const TextStyle(
color: Colors.white,
),
decoration: InputDecoration(
labelText: 'Email Address',
hintText: 'Enter your email',
prefixIcon: const Icon(
Icons.email_outlined,
),
labelStyle: const TextStyle(
color: Colors.white70,
),
hintStyle: const TextStyle(
color: Colors.white38,
),
filled: true,
fillColor:
deepNavy.withValues(
alpha: 0.55,
),
border: OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
borderSide: BorderSide.none,
),
focusedBorder:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
borderSide:
const BorderSide(
color:
electricYellowGreen,
width: 1.5,
),
),
),
),

const SizedBox(height: 16),

// ==================================================
// PASSWORD
// ==================================================
TextField(
controller: _passwordController,
obscureText: _obscurePassword,
textInputAction:
TextInputAction.done,
enabled: !_isLoading,
onSubmitted: (_) {
if (!_isLoading) {
_handleLogin();
}
},
style: const TextStyle(
color: Colors.white,
),
decoration: InputDecoration(
labelText: 'Password',
hintText: 'Enter your password',
prefixIcon: const Icon(
Icons.lock_outline,
),
suffixIcon: IconButton(
onPressed: _isLoading
? null
    : () {
setState(() {
_obscurePassword =
!_obscurePassword;
});
},
icon: Icon(
_obscurePassword
? Icons
    .visibility_outlined
    : Icons
    .visibility_off_outlined,
color: Colors.white60,
),
),
labelStyle: const TextStyle(
color: Colors.white70,
),
hintStyle: const TextStyle(
color: Colors.white38,
),
filled: true,
fillColor:
deepNavy.withValues(
alpha: 0.55,
),
border: OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
borderSide: BorderSide.none,
),
focusedBorder:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
borderSide:
const BorderSide(
color:
electricYellowGreen,
width: 1.5,
),
),
),
),

// ==================================================
// FORGOT PASSWORD
// ==================================================
Align(
alignment:
Alignment.centerRight,
child: TextButton(
onPressed: _isLoading
? null
    : _handlePasswordReset,
child: const Text(
'Forgot Password?',
style: TextStyle(
color:
electricYellowGreen,
fontSize: 13,
fontWeight:
FontWeight.w600,
),
),
),
),

const SizedBox(height: 8),

// ==================================================
// LOGIN BUTTON
// ==================================================
SizedBox(
height: 52,
child: ElevatedButton(
onPressed: _isLoading
? null
    : () async {
debugPrint(
'LOGIN BUTTON PRESSED',
);
await _handleLogin();
},
style:
ElevatedButton.styleFrom(
backgroundColor:
electricYellowGreen,
foregroundColor: deepNavy,
disabledBackgroundColor:
electricYellowGreen
    .withValues(
alpha: 0.45,
),
disabledForegroundColor:
deepNavy.withValues(
alpha: 0.50,
),
elevation: 0,
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
),
),
child: _isLoading
? const SizedBox(
height: 22,
width: 22,
child:
CircularProgressIndicator(
strokeWidth: 2.5,
color: deepNavy,
),
)
    : const Text(
'LOGIN',
style: TextStyle(
fontSize: 16,
fontWeight:
FontWeight.bold,
letterSpacing: 0.5,
),
),
),
),

const SizedBox(height: 24),

// ==================================================
// DIVIDER
// ==================================================
Row(
children: [
Expanded(
child: Divider(
color: Colors.white
    .withValues(
alpha: 0.12,
),
),
),
Padding(
padding:
const EdgeInsets.symmetric(
horizontal: 12,
),
child: Text(
'OR',
style: TextStyle(
color: Colors.white
    .withValues(
alpha: 0.40,
),
fontSize: 11,
),
),
),
Expanded(
child: Divider(
color: Colors.white
    .withValues(
alpha: 0.12,
),
),
),
],
),

const SizedBox(height: 20),

// ==================================================
// SIGN UP
// ==================================================
Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Text(
"Don't have an account? ",
style: TextStyle(
color: offWhite
    .withValues(
alpha: 0.60,
),
fontSize: 13,
),
),
GestureDetector(
onTap: _isLoading
? null
    : _openSignup,
child: const Text(
'Sign Up',
style: TextStyle(
color:
electricYellowGreen,
fontWeight:
FontWeight.bold,
fontSize: 13,
),
),
),
],
),

const SizedBox(height: 20),

// ==================================================
// FOOTER
// ==================================================
Text(
'Secure login powered by Firebase',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.white.withValues(
alpha: 0.30,
),
fontSize: 10,
),
),
],
),
),
),
),
),
);
}
}
