import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _service = SupabaseService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isLogin) {
        await _service.signIn(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
      } else {
        await _service.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: _nameCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sandLight,
      appBar: AppBar(title: Text(_isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!_isLogin) ...[
            const Text('الاسم', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'اسمك الكامل'),
            ),
            const SizedBox(height: 16),
          ],
          const Text('البريد الإلكتروني', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
          const SizedBox(height: 6),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'example@email.com'),
          ),
          const SizedBox(height: 16),
          const Text('كلمة السر', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '6 أحرف على الأقل'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: AppColors.clay), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.oliveDeep,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isLogin ? 'دخول' : 'إنشاء الحساب'),
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => setState(() {
              _isLogin = !_isLogin;
              _error = null;
            }),
            child: Text(_isLogin ? 'ما عندك حساب؟ أنشئ واحد' : 'عندك حساب؟ سجّل دخولك'),
          ),
        ],
      ),
    );
  }
}
