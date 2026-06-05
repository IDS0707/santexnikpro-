import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import 'glass.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _phone;
  final _address = TextEditingController();
  final _note = TextEditingController();
  bool _loading = false;
  bool _gps = false;
  double? _lat, _lng;

  @override
  void initState() {
    super.initState();
    final st = context.read<AppState>();
    _name = TextEditingController(text: st.userName ?? '');
    _phone = TextEditingController(text: st.userPhone ?? '');
  }

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _address.dispose(); _note.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _gps = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) notify(context, 'GPS o\'chiq — yoqing', type: 'error');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) notify(context, 'Joylashuvga ruxsat berilmadi', type: 'error');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _lat = pos.latitude; _lng = pos.longitude;
      String addr = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      try {
        final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          final pm = marks.first;
          final parts = [pm.locality, pm.subLocality, pm.thoroughfare, pm.street]
              .where((e) => e != null && e.trim().isNotEmpty).toSet().toList();
          if (parts.isNotEmpty) addr = parts.join(', ');
        }
      } catch (_) {}
      _address.text = addr;
      if (mounted) notify(context, 'Joylashuv aniqlandi ✓');
    } catch (e) {
      if (mounted) notify(context, 'Joylashuvni aniqlab bo\'lmadi', type: 'error');
    } finally {
      if (mounted) setState(() => _gps = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final st = context.read<AppState>();
    setState(() => _loading = true);
    try {
      final items = st.cart.map((i) => {'product_id': i.id > 0 ? i.id : null, 'name': i.name, 'price': i.price, 'quantity': i.qty}).toList();
      String address = _address.text.trim();
      if (_lat != null && _lng != null) {
        address = '$address (https://maps.google.com/?q=$_lat,$_lng)';
      }
      final res = await Api.createOrder(
        storeId: st.storeId!, userId: st.userId!, items: items,
        customerName: _name.text.trim(), phone: _phone.text.trim(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(), address: address,
        latitude: _lat, longitude: _lng);
      final earned = (res['earned_points'] ?? 0);
      st.clearCart();
      if (!mounted) return;
      Navigator.pop(context);
      notify(context, earned > 0 ? 'Buyurtma qabul qilindi! +${earned is int ? earned : earned.toInt()} ball 🎉' : 'Buyurtma qabul qilindi! 🎉');
    } catch (e) {
      if (mounted) notify(context, '$e', type: 'error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBg(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
                const Text('Buyurtmani rasmiylashtirish', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  GlassCard(child: Column(children: [
                    ...st.cart.map((i) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                      Expanded(child: Text('${i.name} ×${i.qty}', style: const TextStyle(fontSize: 13))),
                      Text(i.isBonus ? '0 so\'m' : money(i.price * i.qty), style: const TextStyle(fontSize: 13)),
                    ]))),
                    Divider(color: AppColors.glassBorder),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Jami:', style: TextStyle(fontWeight: FontWeight.w800)),
                      Text(money(st.cartTotal), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryGlow)),
                    ]),
                  ])),
                  const SizedBox(height: 16),
                  _label('Ismingiz'),
                  TextFormField(controller: _name, decoration: glassInput(context, prefix: const Icon(Icons.person_outline, color: AppColors.textDim)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ismni kiriting' : null),
                  const SizedBox(height: 12),
                  _label('Telefon'),
                  TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: glassInput(context, prefix: const Icon(Icons.phone_outlined, color: AppColors.textDim)),
                      validator: (v) => (v == null || v.trim().length < 7) ? 'Telefonni kiriting' : null),
                  const SizedBox(height: 12),
                  Row(children: [
                    _label('Manzil'),
                    const Spacer(),
                    GestureDetector(
                      onTap: _gps ? null : _detectLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: -3)]),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          _gps
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Icon(Icons.my_location_rounded, color: Colors.black, size: 15),
                          const SizedBox(width: 6),
                          const Text('Joylashuvni yuborish', style: TextStyle(color: Colors.black, fontSize: 11.5, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  TextFormField(controller: _address, maxLines: 2, decoration: glassInput(context, hint: 'Yetkazib berish manzili yoki GPS'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Manzilni kiriting (yoki GPS)' : null),
                  const SizedBox(height: 12),
                  _label('Izoh (ixtiyoriy)'),
                  TextFormField(controller: _note, maxLines: 2, decoration: glassInput(context, hint: 'Qo\'shimcha ma\'lumot')),
                  const SizedBox(height: 22),
                  GlowButton(label: _loading ? 'Yuborilmoqda...' : 'Tasdiqlash', icon: Icons.check_circle_outline,
                      loading: _loading, color: AppColors.secondary, onTap: _submit),
                ])),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)));
}
