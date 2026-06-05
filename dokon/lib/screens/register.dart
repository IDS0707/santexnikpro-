import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController(text: '+998 ');
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await Api.register(_name.text.trim(), _phone.text.trim());
      final u = res['user'];
      if (!mounted) return;
      await context.read<AppState>().setUser(u['id'], u['full_name'], u['phone']);
    } catch (e) {
      if (mounted) notify(context, '$e', type: 'error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset('assets/logo.png', width: 84, height: 84, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 18),
                const Center(
                  child: Text('SANTEXNIK PRO',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 4),
                Center(child: Text("Ro'yxatdan o'tish", style: TextStyle(color: AppColors.grayLight, fontSize: 14))),
                const SizedBox(height: 36),
                const Text('Ismingiz', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: "To'liq ismingiz", prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Ismni kiriting' : null,
                ),
                const SizedBox(height: 18),
                const Text('Telefon raqami', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: '+998 90 000-00-00', prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (v) => (v == null || v.replaceAll(RegExp(r'\D'), '').length < 9) ? "To'g'ri raqam kiriting" : null,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Davom etish'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text('Davom etib, do\'kon tanlaysiz',
                      style: TextStyle(color: AppColors.grayLight, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
