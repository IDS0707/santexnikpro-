import 'dart:convert';
import 'package:http/http.dart' as http;

const String kApiBase = "http://109.123.253.238:8091";

// ---------------- Modellar ----------------
class Category {
  final int id;
  final String name;
  final String? code;
  final String? icon;
  final int productCount;
  Category({required this.id, required this.name, this.code, this.icon, this.productCount = 0});
  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'],
        name: j['name'] ?? '',
        code: j['code'],
        icon: j['icon'],
        productCount: (j['product_count'] ?? 0) is int
            ? (j['product_count'] ?? 0)
            : int.tryParse('${j['product_count']}') ?? 0,
      );
}

class Product {
  final int id;
  final String name;
  final double price;
  final double? oldPrice;
  final int stock;
  final String unit;
  final String? badge;
  final String? icon;
  final int? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final String? description;
  Product({
    required this.id,
    required this.name,
    required this.price,
    this.oldPrice,
    this.stock = 0,
    this.unit = 'dona',
    this.badge,
    this.icon,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.description,
  });
  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'],
        name: j['name'] ?? '',
        price: (j['price'] ?? 0).toDouble(),
        oldPrice: j['old_price'] == null ? null : (j['old_price']).toDouble(),
        stock: j['stock'] ?? 0,
        unit: j['unit'] ?? 'dona',
        badge: (j['badge'] == null || '${j['badge']}'.isEmpty) ? null : j['badge'],
        icon: j['icon'],
        categoryId: j['category_id'],
        categoryName: j['category_name'],
        imageUrl: (j['image_url'] == null || '${j['image_url']}'.isEmpty) ? null : j['image_url'],
        description: j['description'],
      );
}

class BonusReward {
  final int id;
  final String name;
  final double points;
  final String? icon;
  BonusReward({required this.id, required this.name, required this.points, this.icon});
  factory BonusReward.fromJson(Map<String, dynamic> j) =>
      BonusReward(id: j['id'], name: j['name'] ?? '', points: (j['points_cost'] ?? j['points'] ?? 0).toDouble(), icon: j['icon']);
}

class StoreInfo {
  final int id;
  final String name;
  final String? address;
  StoreInfo({required this.id, required this.name, this.address});
  factory StoreInfo.fromJson(Map<String, dynamic> j) =>
      StoreInfo(id: j['id'], name: j['name'] ?? '', address: j['address']);
}

class OrderInfo {
  final int id;
  final double total;
  final String status;
  final String createdAt;
  OrderInfo({required this.id, required this.total, required this.status, required this.createdAt});
  factory OrderInfo.fromJson(Map<String, dynamic> j) => OrderInfo(
        id: j['id'],
        total: (j['total'] ?? 0).toDouble(),
        status: j['status'] ?? 'new',
        createdAt: j['created_at'] ?? '',
      );
}

class BannerInfo {
  final int id;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final String? linkUrl;
  final String? backgroundColor;
  final bool isActive;
  BannerInfo({
    required this.id,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.linkUrl,
    this.backgroundColor,
    this.isActive = true,
  });
  static String? _nz(dynamic v) => (v == null || '$v'.trim().isEmpty) ? null : '$v';
  factory BannerInfo.fromJson(Map<String, dynamic> j) => BannerInfo(
        id: j['id'] ?? 0,
        title: _nz(j['title']),
        subtitle: _nz(j['subtitle']),
        imageUrl: _nz(j['image_url']),
        linkUrl: _nz(j['link_url']),
        backgroundColor: _nz(j['background_color']),
        isActive: j['is_active'] ?? true,
      );
}

// ---------------- API klient ----------------
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class Api {
  static Future<dynamic> _req(String method, String path,
      {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    final uri = Uri.parse('$kApiBase$path');
    final h = {'Content-Type': 'application/json', ...?headers};
    http.Response r;
    try {
      switch (method) {
        case 'POST':
          r = await http.post(uri, headers: h, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
          break;
        case 'GET':
        default:
          r = await http.get(uri, headers: h).timeout(const Duration(seconds: 20));
      }
    } catch (e) {
      throw ApiException("Serverga ulanib bo'lmadi. Internetni tekshiring.");
    }
    final data = r.body.isEmpty ? null : jsonDecode(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) return data;
    final msg = (data is Map && data['detail'] != null) ? '${data['detail']}' : 'Xatolik (${r.statusCode})';
    throw ApiException(msg);
  }

  static Future<Map<String, dynamic>> register(String name, String phone) async {
    final d = await _req('POST', '/register', body: {'full_name': name, 'phone': phone});
    return Map<String, dynamic>.from(d);
  }

  static Future<List<StoreInfo>> stores() async {
    final d = await _req('GET', '/stores');
    return (d as List).map((e) => StoreInfo.fromJson(e)).toList();
  }

  static Future<StoreInfo> storeLogin(int storeId, String password) async {
    final d = await _req('POST', '/stores/login', body: {'store_id': storeId, 'password': password});
    return StoreInfo.fromJson(d['store']);
  }

  static Future<List<Category>> categories(int storeId) async {
    final d = await _req('GET', '/categories?store_id=$storeId');
    return (d as List).map((e) => Category.fromJson(e)).toList();
  }

  static Future<List<Product>> products(int storeId) async {
    final d = await _req('GET', '/products?store_id=$storeId');
    return (d as List).map((e) => Product.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> createOrder({
    required int storeId,
    required int userId,
    required List<Map<String, dynamic>> items,
    String? customerName,
    String? phone,
    String? note,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final d = await _req('POST', '/orders', body: {
      'store_id': storeId,
      'app_user_id': userId,
      'customer_name': customerName,
      'phone': phone,
      'items': items,
      'note': note,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    });
    return Map<String, dynamic>.from(d);
  }

  static Future<List<OrderInfo>> myOrders(int userId) async {
    final d = await _req('GET', '/orders?app_user_id=$userId');
    return (d as List).map((e) => OrderInfo.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> myBonus(int storeId, int userId) async {
    final d = await _req('GET', '/bonus/me?store_id=$storeId&app_user_id=$userId');
    return Map<String, dynamic>.from(d);
  }

  static Future<List<BonusReward>> bonusRewards(int storeId) async {
    final d = await _req('GET', '/bonus/rewards?store_id=$storeId');
    return (d as List).map((e) => BonusReward.fromJson(e)).toList();
  }

  static Future<void> redeem(int storeId, int userId, int bonusItemId, int pointsCost) async {
    await _req('POST', '/bonus/redeem', body: {
      'store_id': storeId,
      'app_user_id': userId,
      'bonus_item_id': bonusItemId,
      'points_cost': pointsCost,
    });
  }

  static Future<List<BannerInfo>> banners(int storeId) async {
    final d = await _req('GET', '/banners?store_id=$storeId');
    return (d as List).map((e) => BannerInfo.fromJson(e)).toList();
  }
}
