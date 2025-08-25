// lib/pages/login/login.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  bool _isLoginMode = true;
  bool _obscure = true;
  bool _loading = false;
  String? _errorText;

  bool get _isFormValid {
    final email = _email.text.trim();
    final pass = _password.text;
    final hasAt = email.contains("@");
    final hasDot = email.contains(".");
    final baseValid = email.isNotEmpty && hasAt && hasDot && pass.length >= 6;

    if (_isLoginMode) return baseValid;
    // In sign-up mode ensure names are present
    return baseValid &&
        _firstName.text.trim().isNotEmpty &&
        _lastName.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    // Rebuild whenever user types
    _email.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
    _firstName.addListener(() => setState(() {}));
    _lastName.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final auth = FirebaseAuth.instance;

      if (_isLoginMode) {
        await auth.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        // CREATE ACCOUNT
        final cred = await auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );

        // Create user profile in Firestore
        await _createUserProfile(cred);

        // (Optional) Send verification:
        // await auth.currentUser?.sendEmailVerification();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isLoginMode ? 'Signed in!' : 'Account created!')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createUserProfile(UserCredential cred) async {
    final user = cred.user;
    if (user == null) return;

    final first = _firstName.text.trim();
    final last = _lastName.text.trim();
    final full = [first, last].where((s) => s.isNotEmpty).join(' ');

    final users = FirebaseFirestore.instance.collection('users');

    await users.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'firstName': first,
      'lastName': last,
      'fullName': full,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _errorText = 'Enter your email to reset your password.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = _friendlyError(e));
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email looks invalid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Auth error: ${e.message ?? e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeGreen = const Color(0xFF2D4F2B);
    final bgGrey = const Color(0xFFF5F5F5);
    final borderGrey = const Color(0xFF7C7C7C);
    final buttonInactive = const Color(0xFFD7D7D7);
    final buttonActive = const Color(0xFFA5AB85);

    return Scaffold(
      backgroundColor: bgGrey,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                height: 150,
                width: 150,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/1.png"),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                _isLoginMode ? "Sign in to your account" : "Create a new account",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: themeGreen,
                ),
              ),
              const SizedBox(height: 24),

              if (_errorText != null) ...[
                Text(
                  _errorText!,
                  style: GoogleFonts.poppins(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],

              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    // First/Last name only in Create Account mode
                    if (!_isLoginMode) ...[
                      TextFormField(
                        controller: _firstName,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                          hintText: "First name",
                          hintStyle: GoogleFonts.poppins(color: borderGrey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: Icon(Icons.person_outline, color: borderGrey),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: borderGrey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: themeGreen, width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          if (_isLoginMode) return null;
                          if (v == null || v.trim().isEmpty) {
                            return 'First name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastName,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                          hintText: "Last name",
                          hintStyle: GoogleFonts.poppins(color: borderGrey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: Icon(Icons.person_outline, color: borderGrey),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: borderGrey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: themeGreen, width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          if (_isLoginMode) return null;
                          if (v == null || v.trim().isEmpty) {
                            return 'Last name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Email
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        hintText: "Email",
                        hintStyle: GoogleFonts.poppins(color: borderGrey),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefixIcon: Icon(Icons.email_outlined, color: borderGrey),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: borderGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: themeGreen, width: 1.5),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Enter your email";
                        if (!v.contains("@") || !v.contains(".")) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        hintText: "Password",
                        hintStyle: GoogleFonts.poppins(color: borderGrey),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefixIcon: Icon(Icons.lock_outline, color: borderGrey),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: borderGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: themeGreen, width: 1.5),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: borderGrey,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Enter your password";
                        if (v.length < 6) return "Password must be at least 6 characters";
                        return null;
                      },
                    ),

                    // Forgot password (only in login mode)
                    if (_isLoginMode)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _resetPassword,
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.poppins(color: themeGreen),
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFormValid ? buttonActive : buttonInactive,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _isFormValid && !_loading ? _submit : null,
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isLoginMode ? "Continue" : "Create account",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, color: Colors.white),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: borderGrey)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text("or", style: GoogleFonts.poppins(color: themeGreen)),
                        ),
                        Expanded(child: Divider(color: borderGrey)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Google button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: implement Google sign-in
                        },
                        icon: Image.asset("assets/images/google.png", height: 20),
                        label: Text(
                          "Sign in with Google",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: themeGreen,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: BorderSide(color: borderGrey),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bottom text
                    RichText(
                      text: TextSpan(
                        text: _isLoginMode
                            ? "Don’t have an account? "
                            : "Already have an account? ",
                        style: GoogleFonts.poppins(color: Colors.black87),
                        children: [
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => setState(() => _isLoginMode = !_isLoginMode),
                              child: Text(
                                _isLoginMode ? "Sign up here" : "Sign in here",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: themeGreen,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
