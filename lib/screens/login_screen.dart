import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../data/favorites_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool returnToPrevious;
  const LoginScreen({super.key, this.returnToPrevious = false});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
      if (res['token'] != null) {
        await ApiService.saveToken(res['token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(res['user']));
        // Save user ID and load their favorites
        final userId = res['user']['id'] ?? res['user']['_id'];
        if (userId != null) {
          await prefs.setString('current_user_id', userId.toString());
          await FavoritesStore.instance.loadForUser(userId.toString());
          // No need to syncToBackend() here - loadForUser() already handles merging
          // and syncing local favorites to backend
        } else {
          print('Warning: userId is null in login response');
          await FavoritesStore.instance.loadForUser(null);
        }
        if (mounted) {
          if (widget.returnToPrevious) {
            // Go back to where the user came from (movie detail)
            Navigator.pop(context);
          } else {
            Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
          }
        }
      } else {
        setState(() => _error = res['message'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _error = 'Cannot reach server. Make sure backend is running and you are on the same WiFi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back/Close button to go to main app without login
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // Go to main app without logging in (continue as guest)
                        Navigator.pushAndRemoveUntil(context,
                          MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
                      },
                      icon: const Icon(Icons.close, color: Colors.white70, size: 24),
                      tooltip: 'Continue as guest',
                    ),
                    const Spacer(),
                    if (widget.returnToPrevious)
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 24),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // Logo
                Center(
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A1A2E),
                      border: Border.all(color: const Color(0xFFE5383B), width: 2),
                    ),
                    child: const Icon(Icons.movie_filter_rounded, color: Color(0xFFE5383B), size: 40),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text('AddisCinema', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                const SizedBox(height: 6),
                Center(child: Text('Sign in to your account', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14))),
                const SizedBox(height: 40),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildField('Email', _emailCtrl, Icons.email_outlined, keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Enter email' : null),
                const SizedBox(height: 16),
                _buildField('Password', _passCtrl, Icons.lock_outline, obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => v!.length < 6 ? 'Min 6 characters' : null),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5383B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("Don't have an account? ", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Sign Up', style: TextStyle(color: Color(0xFFE5383B), fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 24),
                // Continue as guest button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Go to main app without logging in (continue as guest)
                      Navigator.pushAndRemoveUntil(context,
                        MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      'Continue as Guest',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
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

  Widget _buildField(String label, TextEditingController ctrl, IconData icon,
      {bool obscure = false, Widget? suffix, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white38, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5383B))),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red)),
          ),
        ),
      ],
    );
  }
}
