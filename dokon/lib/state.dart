import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

class CartItem {
  final int id; // product id (yoki bonus uchun manfiy/maxsus)
  final String name;
  final double price;
  int qty;
  final String? icon;
  final String unit;
  final bool isBonus;
  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.qty = 1,
    this.icon,
    this.unit = 'dona',
    this.isBonus = false,
  });
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'price': price, 'qty': qty, 'icon': icon, 'unit': unit, 'isBonus': isBonus};
  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        id: j['id'],
        name: j['name'],
        price: (j['price'] ?? 0).toDouble(),
        qty: j['qty'] ?? 1,
        icon: j['icon'],
        unit: j['unit'] ?? 'dona',
        isBonus: j['isBonus'] ?? false,
      );
}

class AppState extends ChangeNotifier {
  late SharedPreferences _sp;

  ThemeMode themeMode = ThemeMode.light;

  int? userId;
  String? userName;
  String? userPhone;

  int? storeId;
  String? storeName;

  List<CartItem> cart = [];
  double bonusBalance = 0;

  bool get isRegistered => userId != null;
  bool get hasStore => storeId != null;

  Future<void> init() async {
    _sp = await SharedPreferences.getInstance();
    themeMode = (_sp.getString('theme') == 'light') ? ThemeMode.light : ThemeMode.dark;
    userId = _sp.getInt('userId');
    userName = _sp.getString('userName');
    userPhone = _sp.getString('userPhone');
    storeId = _sp.getInt('storeId');
    storeName = _sp.getString('storeName');
    final cj = _sp.getString('cart');
    if (cj != null) {
      cart = (jsonDecode(cj) as List).map((e) => CartItem.fromJson(e)).toList();
    }
    notifyListeners();
  }

  // ---- Theme ----
  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _sp.setString('theme', themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  // ---- User ----
  Future<void> setUser(int id, String name, String phone) async {
    userId = id;
    userName = name;
    userPhone = phone;
    await _sp.setInt('userId', id);
    await _sp.setString('userName', name);
    await _sp.setString('userPhone', phone);
    notifyListeners();
  }

  // ---- Store ----
  Future<void> setStore(int id, String name) async {
    storeId = id;
    storeName = name;
    await _sp.setInt('storeId', id);
    await _sp.setString('storeName', name);
    notifyListeners();
  }

  Future<void> leaveStore() async {
    storeId = null;
    storeName = null;
    await _sp.remove('storeId');
    await _sp.remove('storeName');
    notifyListeners();
  }

  Future<void> logout() async {
    await _sp.clear();
    userId = null;
    userName = null;
    userPhone = null;
    storeId = null;
    storeName = null;
    cart = [];
    notifyListeners();
  }

  // ---- Cart ----
  int get cartCount => cart.fold(0, (s, i) => s + i.qty);
  double get cartTotal => cart.fold(0.0, (s, i) => s + i.price * i.qty);

  void _saveCart() => _sp.setString('cart', jsonEncode(cart.map((e) => e.toJson()).toList()));

  void addToCart(Product p) {
    final ex = cart.where((i) => i.id == p.id && !i.isBonus).toList();
    if (ex.isNotEmpty) {
      if (ex.first.qty >= p.stock) return;
      ex.first.qty++;
    } else {
      cart.add(CartItem(id: p.id, name: p.name, price: p.price, icon: p.icon, unit: p.unit));
    }
    _saveCart();
    notifyListeners();
  }

  void addProductQty(Product p, int qty) {
    if (qty < 1) qty = 1;
    final ex = cart.where((i) => i.id == p.id && !i.isBonus).toList();
    if (ex.isNotEmpty) {
      ex.first.qty += qty;
    } else {
      cart.add(CartItem(id: p.id, name: p.name, price: p.price, qty: qty, icon: p.icon, unit: p.unit));
    }
    _saveCart();
    notifyListeners();
  }

  void addCustom(String name, double price, int qty, {String? icon}) {
    cart.add(CartItem(id: -DateTime.now().millisecondsSinceEpoch, name: name, price: price, qty: qty, icon: icon));
    _saveCart();
    notifyListeners();
  }

  void addBonus(String name, {String? icon}) {
    cart.add(CartItem(id: -DateTime.now().millisecondsSinceEpoch, name: '🎁 $name', price: 0, icon: icon, isBonus: true));
    _saveCart();
    notifyListeners();
  }

  void changeQty(CartItem item, int delta) {
    item.qty += delta;
    if (item.qty < 1) cart.remove(item);
    _saveCart();
    notifyListeners();
  }

  void removeItem(CartItem item) {
    cart.remove(item);
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    cart = [];
    _saveCart();
    notifyListeners();
  }

  void setBonus(double b) {
    bonusBalance = b;
    notifyListeners();
  }
}
