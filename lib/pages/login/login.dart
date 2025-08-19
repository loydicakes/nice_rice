import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  bool _isLoginMode = true;
  bool _obscure = true;
  bool _loading = false;
  String? _errorText;

  bool get _isFormValid {
    final email = _email.text.trim();
    final pass = _password.text;
    final hasAt = email.contains("@");
    final hasDot = email.contains(".");
    return email.isNotEmpty && hasAt && hasDot && pass.length >= 6;
  }

  @override
  void initState() {
    super.initState();
    // Rebuild whenever user types
    _email.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
        await auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isLoginMode ? 'Signed in!' : 'Account created!')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
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
                autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ show errors as typing
                child: Column(
                  children: [
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        if (!v.contains("@") || !v.contains(".")) return "Enter a valid email";
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    const SizedBox(height: 24),

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
                                    "Continue",
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
