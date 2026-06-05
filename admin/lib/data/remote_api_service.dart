import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Backend manzili (VPS FastAPI). --dart-define API_BASE bilan o'zgartirsa bo'ladi.
const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://109.123.253.238:8091',
);

/// Realtime o'rniga polling — yangi buyurtmani kuzatadi.
class OrderWatch {
  OrderWatch(this._timer);
  Timer? _timer;
  void unsubscribe() {
    _timer?.cancel();
    _timer = null;
  }
}

class RemoteSnapshot {
  const RemoteSnapshot({
    required this.categories,
    required this.products,
    required this.orders,
    required this.drivers,
    required this.applications,
  });
  final List<Category> categories;
  final List<Product> products;
  final List<OrderRecord> orders;
  final List<DriverProfile> drivers;
  final List<ApplicationRecord> applications;
}

class RemoteApiService {
  RemoteApiService();

  // main.dart bilan moslik uchun (eski nomlar)
  static const String supabaseUrl = kApiBase;
  static const String supabaseAnonKey = '';
  String get baseUrl => kApiBase;

  // ─── HTTP yordamchilar ───
  Future<dynamic> _get(String path) async {
    final r = await http.get(Uri.parse('$kApiBase$path')).timeout(const Duration(seconds: 20));
    return _decode(r);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final r = await http
        .post(Uri.parse('$kApiBase$path'),
            headers: const {'Content-Type': 'application/json'}, body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    return _decode(r);
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    final r = await http
        .patch(Uri.parse('$kApiBase$path'),
            headers: const {'Content-Type': 'application/json'}, body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    return _decode(r);
  }

  Future<dynamic> _delete(String path) async {
    final r = await http.delete(Uri.parse('$kApiBase$path')).timeout(const Duration(seconds: 20));
    return _decode(r);
  }

  dynamic _decode(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return r.body.isEmpty ? null : jsonDecode(r.body);
    }
    throw Exception('HTTP ${r.statusCode}: ${r.body}');
  }

  String _s(dynamic v) => v == null ? '' : v.toString();
  int? _intOrNull(String? v) => (v == null) ? null : int.tryParse(v);
  String _enumName(Object value) => value.toString().split('.').last;

  Future<bool> ping() async {
    try {
      await _get('/health');
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Login ───
  Future<Map<String, String>?> loginAdmin(String login, String password,
      {String storeSlug = 'santexnika'}) async {
    try {
      final d = await _post('/admin/login', {
        'store_slug': storeSlug,
        'login': login,
        'password': password,
      });
      return {
        'admin_id': _s(d['admin_id']),
        'store_id': _s(d['store_id']),
        'store_name': _s(d['store_name']),
        'store_slug': _s(d['store_slug']),
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>?> loginSuperAdmin(String login, String password) async {
    try {
      final d = await _post('/sa/login', {'login': login, 'password': password});
      return {'user_id': _s(d['user_id']), 'name': _s(d['name'])};
    } catch (_) {
      return null;
    }
  }

  Future<String?> loginDriver(String login, String password) async {
    try {
      final d = await _post('/driver/login', {'login': login, 'password': password});
      return _s(d['driver_id']);
    } catch (_) {
      return null;
    }
  }

  // ─── Super admin: statistika ───
  Future<GlobalStats> fetchGlobalStats() async {
    final d = await _get('/sa/stats');
    return GlobalStats.fromMap(Map<String, dynamic>.from(d as Map));
  }

  Future<List<TopStore>> fetchTopStores({int limit = 5}) async {
    final d = await _get('/sa/top-stores?limit=$limit');
    return (d as List).map((m) => TopStore.fromMap(Map<String, dynamic>.from(m as Map))).toList();
  }

  Future<List<StoreSummary>> fetchStoresSummary() async {
    final d = await _get('/sa/stores');
    return (d as List).map((m) => StoreSummary.fromMap(Map<String, dynamic>.from(m as Map))).toList();
  }

  Future<List<_OrderLite>> _allOrders({String? storeId}) async {
    final d = await _get('/sa/orders${storeId != null ? '?store_id=$storeId' : ''}');
    return (d as List).map((m) {
      final mm = Map<String, dynamic>.from(m as Map);
      return _OrderLite(
        total: ((mm['total'] ?? 0) as num).toDouble(),
        createdAt: DateTime.tryParse(_s(mm['created_at'])) ?? DateTime.now(),
        items: mm['items'] is List ? List.from(mm['items']) : const [],
        storeId: _s(mm['store_id']),
        status: _s(mm['status']),
      );
    }).toList();
  }

  Future<PeriodStats> fetchPeriodStats(
      {required DateTime from, required DateTime to, String? storeId}) async {
    final orders = await _allOrders(storeId: storeId);
    double rev = 0;
    int cnt = 0;
    for (final o in orders) {
      if (o.createdAt.isAfter(from) && o.createdAt.isBefore(to) && o.status != 'cancelled') {
        rev += o.total;
        cnt++;
      }
    }
    return PeriodStats.fromMap({'revenue': rev, 'orders': cnt, 'avg': cnt == 0 ? 0 : rev / cnt});
  }

  Future<List<DailyPoint>> fetchDailyRevenue(
      {required DateTime from, required DateTime to, String? storeId}) async {
    final orders = await _allOrders(storeId: storeId);
    final buckets = <String, ({double revenue, int orders})>{};
    for (final o in orders) {
      if (o.createdAt.isBefore(from) || o.createdAt.isAfter(to)) continue;
      final key = DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day)
          .toIso8601String()
          .substring(0, 10);
      final prev = buckets[key] ?? (revenue: 0.0, orders: 0);
      buckets[key] = (revenue: prev.revenue + o.total, orders: prev.orders + 1);
    }
    final keys = buckets.keys.toList()..sort();
    return keys
        .map((k) => DailyPoint(day: DateTime.parse(k), revenue: buckets[k]!.revenue, orders: buckets[k]!.orders))
        .toList();
  }

  Future<List<TopProduct>> fetchTopProductsByQuantity(
      {required DateTime from, required DateTime to, String? storeId, int limit = 10}) =>
      _topProducts(from: from, to: to, storeId: storeId, limit: limit, byQty: true);

  Future<List<TopProduct>> fetchTopProductsByRevenue(
      {required DateTime from, required DateTime to, String? storeId, int limit = 10}) =>
      _topProducts(from: from, to: to, storeId: storeId, limit: limit, byQty: false);

  Future<List<TopProduct>> _topProducts(
      {required DateTime from,
      required DateTime to,
      String? storeId,
      required int limit,
      required bool byQty}) async {
    final orders = await _allOrders(storeId: storeId);
    final stores = await fetchStoresSummary();
    final storeNames = {for (final s in stores) s.id: s.name};
    final agg = <String, ({int qty, double rev, String storeName})>{};
    for (final o in orders) {
      if (o.createdAt.isBefore(from) || o.createdAt.isAfter(to)) continue;
      for (final it in o.items) {
        final im = Map<String, dynamic>.from(it as Map);
        final name = (im['name'] as String?) ?? '?';
        final qty = ((im['quantity'] ?? im['qty'] ?? 1) as num).toInt();
        final price = ((im['price'] ?? 0) as num).toDouble();
        final sn = storeNames[o.storeId] ?? '';
        final prev = agg[name] ?? (qty: 0, rev: 0.0, storeName: sn);
        agg[name] = (qty: prev.qty + qty, rev: prev.rev + qty * price, storeName: prev.storeName.isEmpty ? sn : prev.storeName);
      }
    }
    final list = agg.entries
        .map((e) => TopProduct(name: e.key, totalQuantity: e.value.qty, totalRevenue: e.value.rev, storeName: e.value.storeName))
        .toList();
    list.sort((a, b) => byQty ? b.totalQuantity.compareTo(a.totalQuantity) : b.totalRevenue.compareTo(a.totalRevenue));
    return list.take(limit).toList();
  }

  // ─── Super admin: do'konlar ───
  Future<void> setStoreStatus(String storeId, String status) =>
      _patch('/sa/stores/$storeId', {'status': status});

  Future<List<Map<String, dynamic>>> fetchPendingShops() async {
    final d = await _get('/sa/stores');
    return (d as List)
        .map((m) => Map<String, dynamic>.from(m as Map))
        .where((m) => m['status'] == 'pending')
        .toList();
  }

  Future<void> approveShop(String storeId, {double commission = 5.0}) =>
      _patch('/sa/stores/$storeId', {'status': 'active', 'commission_rate': commission});

  Future<void> rejectShop(String storeId, String reason) =>
      _patch('/sa/stores/$storeId', {'status': 'blocked'});

  Future<void> updateStoreDetails(String storeId,
      {String? name, String? description, String? category, String? inviteCode}) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (description != null) payload['description'] = description;
    if (payload.isEmpty) return;
    await _patch('/sa/stores/$storeId', payload);
  }

  Future<void> updateStoreCommission(String storeId, double commissionRate) =>
      _patch('/sa/stores/$storeId', {'commission_rate': commissionRate});

  Future<void> deleteStore(String storeId) => _delete('/sa/stores/$storeId');

  Future<String> createStoreWithAdmin({
    required String slug,
    required String name,
    required String description,
    required String inviteCode,
    required String adminLogin,
    required String adminPassword,
    String? adminName,
    String? category,
    double commissionRate = 5.0,
    String? accessPassword,
  }) async {
    final d = await _post('/sa/stores', {
      'slug': slug,
      'name': name,
      'description': description,
      'invite_code': inviteCode,
      'admin_login': adminLogin,
      'admin_password': adminPassword,
      'admin_name': adminName ?? name,
      'category': category,
      'commission_rate': commissionRate,
      'access_password': accessPassword,
    });
    return _s(d['store_id']);
  }

  Future<void> createStore({
    required String slug,
    required String name,
    required String description,
    required String inviteCode,
    String? category,
    double commissionRate = 5.0,
  }) async {
    await _post('/sa/stores', {
      'slug': slug,
      'name': name,
      'description': description,
      'invite_code': inviteCode,
      'admin_login': 'admin',
      'admin_password': '1234',
      'category': category,
      'commission_rate': commissionRate,
    });
  }

  // ─── Super admin: foydalanuvchilar ───
  Future<List<AppUserRecord>> fetchAllUsers() async {
    final d = await _get('/sa/users');
    return (d as List).map((m) => AppUserRecord.fromMap(Map<String, dynamic>.from(m as Map))).toList();
  }

  Future<void> transferUser(String userId, String storeId) =>
      _post('/sa/users/$userId/transfer', {'store_id': _intOrNull(storeId) ?? 0});

  Future<void> setUserStatus(String userId, String status) =>
      _patch('/sa/users/$userId', {'status': status});

  Future<List<Map<String, dynamic>>> fetchActivityLogs({int limit = 50}) async {
    final d = await _get('/sa/activity-logs?limit=$limit');
    return (d as List).map((m) => Map<String, dynamic>.from(m as Map)).toList();
  }

  Future<void> logActivity({
    required String actorRole,
    String? actorId,
    String? storeId,
    required String action,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? metadata,
  }) async {
    // hozircha jurnalni o'tkazib yuboramiz (ixtiyoriy)
  }

  // ─── Banners ───
  Future<List<Map<String, dynamic>>> fetchBanners({String? storeId}) async {
    final d = await _get('/banners${storeId != null ? '?store_id=$storeId' : ''}');
    return (d as List).map((m) => Map<String, dynamic>.from(m as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchAllBanners() => fetchBanners();

  Future<void> upsertBanner(Map<String, dynamic> banner) async {
    final b = Map<String, dynamic>.from(banner);
    b['id'] = _intOrNull(_s(b['id']));
    b['store_id'] = _intOrNull(_s(b['store_id']));
    await _post('/banners', b);
  }

  Future<void> deleteBanner(String id) => _delete('/banners/$id');

  // ─── Notification templates ───
  Future<List<Map<String, dynamic>>> fetchNotificationTemplates({String? storeId}) async {
    final d = await _get('/notification-templates${storeId != null ? '?store_id=$storeId' : ''}');
    return (d as List).map((m) => Map<String, dynamic>.from(m as Map)).toList();
  }

  Future<void> upsertNotificationTemplate(Map<String, dynamic> tpl) async {
    final t = Map<String, dynamic>.from(tpl);
    t['id'] = _intOrNull(_s(t['id']));
    t['store_id'] = _intOrNull(_s(t['store_id']));
    await _post('/notification-templates', t);
  }

  Future<void> deleteNotificationTemplate(String id) async {}

  // ─── Do'kon bonus sozlamalari ───
  Future<Map<String, dynamic>?> getStoreBonus(String storeId) async {
    if (storeId.isEmpty) return null;
    final d = await _get('/admin/bonus/settings?store_id=$storeId');
    return d == null ? null : Map<String, dynamic>.from(d as Map);
  }

  Future<void> updateStoreBonus(String storeId,
      {required bool enabled, required num amount, required int points}) async {
    final r = await http.put(Uri.parse('$kApiBase/admin/bonus/settings'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'store_id': _intOrNull(storeId) ?? 0, 'bonus_enabled': enabled, 'bonus_amount': amount, 'bonus_points': points}));
    _decode(r);
  }

  Future<void> updateStoreAccessPassword(String storeId, String? password) async {
    final r = await http.put(Uri.parse('$kApiBase/admin/access-password'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'store_id': _intOrNull(storeId) ?? 0, 'password': password}));
    _decode(r);
  }

  // ─── Buyurtma bildirishnomalari ───
  Future<List<Map<String, dynamic>>> fetchOrderNotifs(String storeId) async {
    if (storeId.isEmpty) return [];
    final d = await _get('/admin/notifications?store_id=$storeId');
    return (d as List).map((m) => Map<String, dynamic>.from(m as Map)).toList();
  }

  Future<int> unreadOrderNotifCount(String storeId) async {
    if (storeId.isEmpty) return 0;
    final list = await fetchOrderNotifs(storeId);
    return list.where((m) => m['is_read'] == false).length;
  }

  Future<void> markOrderNotifsRead(String storeId) async {
    if (storeId.isEmpty) return;
    await _post('/admin/notifications/read', {'store_id': _intOrNull(storeId) ?? 0});
  }

  OrderWatch watchNewOrders(String storeId, void Function() onNew) {
    int lastCount = -1;
    final timer = Timer.periodic(const Duration(seconds: 12), (_) async {
      try {
        final d = await _get('/admin/snapshot?store_id=$storeId');
        final orders = (d['orders'] as List?) ?? const [];
        if (lastCount >= 0 && orders.length > lastCount) onNew();
        lastCount = orders.length;
      } catch (_) {}
    });
    return OrderWatch(timer);
  }

  // ─── Snapshot (do'kon admin ma'lumotlari) ───
  Future<RemoteSnapshot> fetchAll({String? storeId}) async {
    if (storeId == null || storeId.isEmpty) {
      return const RemoteSnapshot(categories: [], products: [], orders: [], drivers: [], applications: []);
    }
    final d = await _get('/admin/snapshot?store_id=$storeId');
    final m = Map<String, dynamic>.from(d as Map);
    return RemoteSnapshot(
      categories: (m['categories'] as List).map((e) => _categoryFromApi(Map<String, dynamic>.from(e as Map))).toList(),
      products: (m['products'] as List).map((e) => _productFromApi(Map<String, dynamic>.from(e as Map))).toList(),
      orders: (m['orders'] as List).map((e) => _orderFromApi(Map<String, dynamic>.from(e as Map))).toList(),
      drivers: (m['drivers'] as List).map((e) => _driverFromApi(Map<String, dynamic>.from(e as Map))).toList(),
      applications: const [],
    );
  }

  Future<void> upsertCategory(Category c, {required String storeId}) async {
    await _post('/admin/categories', {
      if (int.tryParse(c.id) != null) 'id': int.parse(c.id),
      'store_id': _intOrNull(storeId) ?? 0,
      'name': c.name,
      'code': c.code,
      'description': c.description,
      'icon': c.icon,
    });
  }

  Future<void> deleteCategory(String id) => _delete('/admin/categories/$id');

  Future<void> upsertProduct(Product p, {required String storeId}) async {
    await _post('/admin/products', {
      if (int.tryParse(p.id) != null) 'id': int.parse(p.id),
      'store_id': _intOrNull(storeId) ?? 0,
      'name': p.name,
      'price': p.price,
      'category_id': _intOrNull(p.categoryId),
      'old_price': p.oldPrice,
      'stock': p.stock,
      'sku': p.sku,
      'description': p.description,
      'badge': _enumName(p.badge),
      'image_url': p.imageUrl,
    });
  }

  Future<void> deleteProduct(String id) => _delete('/admin/products/$id');

  Future<void> upsertDriver(DriverProfile d, {required String storeId}) async {
    await _post('/admin/drivers', {
      if (int.tryParse(d.id) != null) 'id': int.parse(d.id),
      'store_id': _intOrNull(storeId) ?? 0,
      'name': d.name,
      'phone': d.phone,
      'login': d.login,
      'password': d.password,
      'vehicle_number': d.vehicleNumber,
      'status': _enumName(d.status),
    });
  }

  Future<void> deleteDriver(String id) => _delete('/admin/drivers/$id');

  Future<void> upsertOrder(OrderRecord o, {required String storeId}) async {
    // Admin faqat status/driver o'zgartiradi
    if (int.tryParse(o.id) != null) {
      await _patch('/admin/orders/${o.id}', {
        'status': _enumName(o.status),
        'driver_id': _intOrNull(o.driverId),
      });
    }
  }

  Future<void> deleteOrder(String id) => _delete('/admin/orders/$id');

  Future<void> patchApplication(String id, Map<String, dynamic> patch) async {}

  // ─── Bonus do'koni ───
  Future<List<Map<String, dynamic>>> getBonusItems(String storeId) async {
    if (storeId.isEmpty) return [];
    final d = await _get('/admin/bonus/items?store_id=$storeId');
    return (d as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> upsertBonusItem(Map<String, dynamic> data) async {
    final b = Map<String, dynamic>.from(data);
    b['id'] = _intOrNull(_s(b['id']));
    b['store_id'] = _intOrNull(_s(b['store_id']));
    await _post('/admin/bonus/items', b);
  }

  Future<void> deleteBonusItem(String id) => _delete('/admin/bonus/items/$id');

  Future<List<Map<String, dynamic>>> getBonusRequests(String storeId) async {
    if (storeId.isEmpty) return [];
    final d = await _get('/admin/bonus/requests?store_id=$storeId');
    return (d as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> updateBonusRequestStatus(String id, String status) =>
      _patch('/admin/bonus/requests/$id', {'status': status});

  Future<void> adjustUserPoints({required String storeId, required String userId, required int delta}) =>
      _post('/admin/bonus/adjust-points', {
        'store_id': _intOrNull(storeId) ?? 0,
        'user_id': _intOrNull(userId) ?? 0,
        'delta': delta,
      });

  // ─── Rasm yuklash ───
  static const String imageBucket = 'product-images';

  Future<String> uploadProductImage(Uint8List bytes, String filename, {required String storeId}) async {
    final req = http.MultipartRequest('POST', Uri.parse('$kApiBase/upload?store_id=$storeId'));
    final lower = filename.toLowerCase();
    final ext = lower.contains('.') ? lower.split('.').last : 'jpg';
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'img.$ext'));
    final resp = await req.send().timeout(const Duration(seconds: 30));
    final body = await resp.stream.bytesToString();
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return (jsonDecode(body) as Map)['url'] as String;
    }
    throw Exception('Rasm yuklanmadi: ${resp.statusCode}');
  }

  // ─── Streams (polling) ───
  Stream<List<OrderRecord>> ordersStream() async* {
    // Bu admin_shell'da to'g'ridan-to'g'ri ishlatilmaydi (snapshot orqali).
    yield <OrderRecord>[];
  }

  Stream<List<Product>> productsStream() async* {
    yield <Product>[];
  }

  // ─── Parserlar (server JSON -> model) ───
  Category _categoryFromApi(Map<String, dynamic> map) => Category(
        id: _s(map['id']),
        name: _s(map['name']),
        code: _s(map['code']),
        description: (map['description'] as String?) ?? '',
        icon: (map['icon'] as String?) ?? 'category',
        createdAt: DateTime.tryParse(_s(map['created_at'])) ?? DateTime.now(),
      );

  Product _productFromApi(Map<String, dynamic> map) => Product(
        id: _s(map['id']),
        name: _s(map['name']),
        categoryId: _s(map['category_id']),
        price: ((map['price'] ?? 0) as num).toDouble(),
        oldPrice: (map['old_price'] as num?)?.toDouble(),
        stock: ((map['stock'] ?? 0) as num).toInt(),
        sku: (map['sku'] as String?) ?? '',
        description: (map['description'] as String?) ?? '',
        badge: _parseProductBadge((map['badge'] as String?) ?? 'none'),
        createdAt: DateTime.tryParse(_s(map['created_at'])) ?? DateTime.now(),
        soldCount: (map['sold_count'] as num?)?.toInt() ?? 0,
        imageUrl: map['image_url'] as String?,
      );

  OrderRecord _orderFromApi(Map<String, dynamic> map) {
    final itemsRaw = map['items'];
    List itemsList;
    if (itemsRaw is List) {
      itemsList = itemsRaw;
    } else if (itemsRaw is String && itemsRaw.isNotEmpty) {
      try {
        itemsList = jsonDecode(itemsRaw) as List;
      } catch (_) {
        itemsList = const [];
      }
    } else {
      itemsList = const [];
    }
    return OrderRecord(
      id: _s(map['id']),
      customerName: (map['customer_name'] as String?) ?? 'Mijoz',
      phone: (map['phone'] as String?) ?? '',
      email: map['email'] as String?,
      address: (map['address'] as String?) ?? '',
      items: itemsList.map((it) => _orderItemFromApi(Map<String, dynamic>.from(it as Map))).toList(),
      total: ((map['total'] ?? 0) as num).toDouble(),
      status: _parseOrderStatus((map['status'] as String?) ?? 'pending'),
      createdAt: DateTime.tryParse(_s(map['created_at'])) ?? DateTime.now(),
      driverId: map['driver_id'] == null ? null : _s(map['driver_id']),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  OrderItem _orderItemFromApi(Map<String, dynamic> map) => OrderItem(
        productId: _s(map['product_id'] ?? map['productId']),
        name: (map['name'] as String?) ?? '',
        quantity: ((map['quantity'] ?? map['qty'] ?? 1) as num).toInt(),
        price: ((map['price'] ?? 0) as num).toDouble(),
      );

  DriverProfile _driverFromApi(Map<String, dynamic> map) => DriverProfile(
        id: _s(map['id']),
        name: _s(map['name']),
        phone: (map['phone'] as String?) ?? '',
        login: (map['login'] as String?) ?? '',
        password: (map['password'] as String?) ?? '',
        vehicleNumber: (map['vehicle_number'] as String?) ?? '',
        status: _parseDriverStatus((map['status'] as String?) ?? 'free'),
        completedOrders: (map['completed_orders'] as num?)?.toInt() ?? 0,
        rating: (map['rating'] as num?)?.toDouble() ?? 5,
        currentOrderId: map['current_order_id'] == null ? null : _s(map['current_order_id']),
      );

  ProductBadge _parseProductBadge(String value) {
    switch (value) {
      case 'yangi':
        return ProductBadge.yangi;
      case 'chegirma':
        return ProductBadge.chegirma;
      case 'tavsiya':
        return ProductBadge.tavsiya;
      case 'ommabop':
        return ProductBadge.ommabop;
      default:
        return ProductBadge.none;
    }
  }

  OrderStatus _parseOrderStatus(String value) {
    switch (value) {
      case 'processing':
        return OrderStatus.processing;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  DriverStatus _parseDriverStatus(String value) {
    switch (value) {
      case 'busy':
        return DriverStatus.busy;
      case 'offline':
        return DriverStatus.offline;
      default:
        return DriverStatus.free;
    }
  }
}

class _OrderLite {
  _OrderLite({required this.total, required this.createdAt, required this.items, required this.storeId, required this.status});
  final double total;
  final DateTime createdAt;
  final List items;
  final String storeId;
  final String status;
}
