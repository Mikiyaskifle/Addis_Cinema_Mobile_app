import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../data/favorites_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (res['token'] != null) {
        await ApiService.saveToken(res['token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(res['user']));
        final userId = res['user']['id'] ?? res['user']['_id'];
        await prefs.setString('current_user_id', userId.toString());
        await FavoritesStore.instance.loadForUser(userId.toString());
        if (mounted) Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
      } else {
        setState(() => _error = res['message'] ?? 'Registration failed');
      }
    } catch (e) {
      setState(() => _error = 'Cannot connect to server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFF1A1A2E), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Join AddisCinema today', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.3))),
                    child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildField('Full Name', _nameCtrl, Icons.person_outline, validator: (v) => v!.isEmpty ? 'Enter name' : null),
                const SizedBox(height: 16),
                _buildField('Email', _emailCtrl, Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Enter email' : null),
                const SizedBox(height: 16),
                _buildField('Phone Number', _phoneCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Enter phone' : null),
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
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5383B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
          controller: ctrl, obscureText: obscure, keyboardType: keyboardType, validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white38, size: 20),
            suffixIcon: suffix,
            filled: true, fillColor: const Color(0xFF1A1A2E),
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
