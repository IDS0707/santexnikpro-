import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../data/local_repository.dart';
import '../../data/models.dart';
import '../../data/remote_api_service.dart';

class AppStore extends ChangeNotifier {
  AppStore({required LocalRepository repository}) : _repository = repository;

  final LocalRepository _repository;
  final RemoteApiService _remoteApi = RemoteApiService();

  static const adminLogin = 'admin@santex.local';
  static const adminPassword = 'Admin123!';
  static const superAdminLogin = 'superadmin';
  static const superAdminPassword = 'Super123!';

  AppSession _session = AppSession.empty;
  List<Category> _categories = <Category>[];
  List<Product> _products = <Product>[];
  List<OrderRecord> _orders = <OrderRecord>[];
  List<DriverProfile> _drivers = <DriverProfile>[];
  List<ApplicationRecord> _applications = <ApplicationRecord>[];
  bool _backendConnected = false;

  AppSession get session => _session;
  List<Category> get categories => List.unmodifiable(_categories);
  List<Product> get products => List.unmodifiable(_products);
  List<OrderRecord> get orders => List.unmodifiable(_orders);
  List<DriverProfile> get drivers => List.unmodifiable(_drivers);
  List<ApplicationRecord> get applications => List.unmodifiable(_applications);
  bool get backendConnected => _backendConnected;

  Future<void> initialize() async {
    await _loadFromLocal();
    try {
      final isAlive = await _remoteApi.ping();
      if (isAlive && _session.storeId != null) {
        final snapshot = await _remoteApi.fetchAll(storeId: _session.storeId);
        _categories = snapshot.categories;
        _products = snapshot.products;
        _orders = snapshot.orders;
        _drivers = snapshot.drivers;
        _applications = snapshot.applications;
        _backendConnected = true;
        await _saveAllToLocal();
      } else {
        _backendConnected = isAlive;
      }
    } catch (_) {
      _backendConnected = false;
    }
    notifyListeners();
  }

  Future<void> _loadFromLocal() async {
    _categories = _repository.loadCategories();
    _products = _repository.loadProducts();
    _orders = _repository.loadOrders();
    _drivers = _repository.loadDrivers();
    _applications = _repository.loadApplications();
    _session = _repository.loadSession();
  }

  Future<void> _saveAllToLocal() async {
    await _repository.saveCategories(_categories);
    await _repository.saveProducts(_products);
    await _repository.saveOrders(_orders);
    await _repository.saveDrivers(_drivers);
    await _repository.saveApplications(_applications);
  }

  DriverProfile? get currentDriver {
    if (_session.role != UserRole.driver || _session.driverId == null) {
      return null;
    }
    return driverById(_session.driverId!);
  }

  Category? categoryById(String id) {
    for (final category in _categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  DriverProfile? driverById(String id) {
    for (final driver in _drivers) {
      if (driver.id == id) {
        return driver;
      }
    }
    return null;
  }

  OrderRecord? orderById(String id) {
    for (final order in _orders) {
      if (order.id == id) {
        return order;
      }
    }
    return null;
  }

  Product? productById(String id) {
    for (final product in _products) {
      if (product.id == id) {
        return product;
      }
    }
    return null;
  }

  List<OrderRecord> get recentOrders {
    final copy = [..._orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy.take(5).toList();
  }

  List<Product> get lowStockProducts {
    final copy = _products.where((product) => product.stock < 10).toList();
    copy.sort((a, b) => a.stock.compareTo(b.stock));
    return copy;
  }

  List<Product> get popularProducts {
    final copy = [..._products]..sort((a, b) => b.soldCount.compareTo(a.soldCount));
    return copy.take(5).toList();
  }

  List<OrderRecord> get activeDeliveries {
    return _orders.where((order) => order.status == OrderStatus.processing).toList();
  }

  List<DriverProfile> get freeDriversSorted {
    final copy = _drivers.where((driver) => driver.status == DriverStatus.free).toList();
    copy.sort((a, b) {
      final completedCompare = b.completedOrders.compareTo(a.completedOrders);
      if (completedCompare != 0) {
        return completedCompare;
      }
      return b.rating.compareTo(a.rating);
    });
    return copy;
  }

  List<CustomerSummary> get customers {
    final byPhone = <String, CustomerSummary>{};
    for (final order in _orders) {
      final existing = byPhone[order.phone];
      final earnedPoints = (order.total / 10000).floor();
      if (existing == null) {
        byPhone[order.phone] = CustomerSummary(
          name: order.customerName,
          phone: order.phone,
          email: order.email ?? '-',
          orderCount: 1,
          totalSpent: order.total,
          lastOrder: order.createdAt,
          points: earnedPoints,
        );
      } else {
        byPhone[order.phone] = CustomerSummary(
          name: existing.name,
          phone: existing.phone,
          email: existing.email == '-' ? (order.email ?? '-') : existing.email,
          orderCount: existing.orderCount + 1,
          totalSpent: existing.totalSpent + order.total,
          lastOrder: order.createdAt.isAfter(existing.lastOrder)
              ? order.createdAt
              : existing.lastOrder,
          points: existing.points + earnedPoints,
        );
      }
    }
    final result = byPhone.values.toList();
    result.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return result;
  }

  // Hardcoded super admin credentials (backend o'chsa ham ishlasin)
  // Format: { login: { password, userId, name } }
  static final Map<String, Map<String, String>> _builtInSuperAdmins = {
    'superadmin': {
      'password': 'Super123!',
      'userId': '99999999-9999-9999-9999-999999999999',
      'name': 'Super Admin',
    },
    'isroiljon': {
      'password': '507712053',
      'userId': '88888888-8888-8888-8888-888888888888',
      'name': 'Isroiljon',
    },
  };

  Future<bool> loginAdmin(
    String login,
    String password, {
    String storeSlug = 'santexnika',
  }) async {
    final trimmedLogin = login.trim();
    final trimmedPass = password.trim();

    // 0) Hardcoded super admin fallback (server kerak emas — har doim ishlaydi)
    final builtIn = _builtInSuperAdmins[trimmedLogin.toLowerCase()];
    if (builtIn != null && builtIn['password'] == trimmedPass) {
      _session = AppSession(
        role: UserRole.superAdmin,
        superAdminId: builtIn['userId'],
        superAdminName: builtIn['name'],
      );
      await _repository.saveSession(_session);
      // Background — server bilan sinxron qilinmoqda, lekin login muvaffaqiyatli
      _remoteApi.logActivity(
        actorRole: 'super_admin',
        actorId: builtIn['userId'],
        action: 'login',
      );
      notifyListeners();
      return true;
    }

    // 1) Try super admin via Supabase RPC
    try {
      final superResult = await _remoteApi.loginSuperAdmin(
        trimmedLogin,
        trimmedPass,
      );
      if (superResult != null) {
        _backendConnected = true;
        _session = AppSession(
          role: UserRole.superAdmin,
          superAdminId: superResult['user_id'],
          superAdminName: superResult['name'],
        );
        await _repository.saveSession(_session);
        await _remoteApi.logActivity(
          actorRole: 'super_admin',
          actorId: superResult['user_id'],
          action: 'login',
        );
        notifyListeners();
        return true;
      }
    } catch (_) {}

    // 2) Try store admin
    try {
      final result = await _remoteApi.loginAdmin(
        login.trim(),
        password.trim(),
        storeSlug: storeSlug,
      );
      if (result != null) {
        _backendConnected = true;
        _session = AppSession(
          role: UserRole.admin,
          storeId: result['store_id'],
          storeName: result['store_name'],
          storeSlug: result['store_slug'],
        );
        await _repository.saveSession(_session);
        await refreshFromServer();
        await _remoteApi.logActivity(
          actorRole: 'admin',
          storeId: result['store_id'],
          action: 'login',
        );
        notifyListeners();
        return true;
      }
    } catch (_) {
      _backendConnected = false;
    }

    // Offline fallback (Santexnika only, legacy)
    if (login.trim() == adminLogin && password.trim() == adminPassword) {
      _session = const AppSession(
        role: UserRole.admin,
        storeId: '11111111-1111-1111-1111-111111111111',
        storeName: 'Santexnika do\'koni',
        storeSlug: 'santexnika',
      );
      await _repository.saveSession(_session);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Super Admin tomonidan store ichiga "kirish" (impersonation).
  /// Vaqtinchalik holatda admin sifatida ishlaydi, lekin super admin ma'lumoti
  /// session ichida saqlanadi — keyin chiqib super admin paneliga qaytishi mumkin.
  Future<bool> enterStoreAsSuperAdmin(String storeId, String storeName, String storeSlug) async {
    if (_session.role != UserRole.superAdmin) return false;
    final savedSuperId = _session.superAdminId;
    final savedSuperName = _session.superAdminName;

    _session = AppSession(
      role: UserRole.admin,
      storeId: storeId,
      storeName: storeName,
      storeSlug: storeSlug,
      superAdminId: savedSuperId,
      superAdminName: savedSuperName,
      impersonating: true,
    );
    await _repository.saveSession(_session);
    await refreshFromServer();
    await _remoteApi.logActivity(
      actorRole: 'super_admin',
      actorId: savedSuperId,
      storeId: storeId,
      action: 'impersonate_store',
    );
    notifyListeners();
    return true;
  }

  /// Impersonation paytidan super admin paneliga qaytish.
  Future<void> exitImpersonation() async {
    if (!_session.impersonating || _session.superAdminId == null) return;
    _session = AppSession(
      role: UserRole.superAdmin,
      superAdminId: _session.superAdminId,
      superAdminName: _session.superAdminName,
    );
    await _repository.saveSession(_session);
    notifyListeners();
  }

  Future<bool> loginDriver(String login, String password) async {
    try {
      final driverId = await _remoteApi.loginDriver(login.trim(), password.trim());
      if (driverId != null && driverId.isNotEmpty) {
        _backendConnected = true;
        _session = AppSession(role: UserRole.driver, driverId: driverId);
        await _repository.saveSession(_session);
        notifyListeners();
        return true;
      }
    } catch (_) {
      _backendConnected = false;
    }

    for (final driver in _drivers) {
      if (driver.login == login.trim() && driver.password == password.trim()) {
        _session = AppSession(role: UserRole.driver, driverId: driver.id);
        await _repository.saveSession(_session);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  Future<void> logout() async {
    _session = AppSession.empty;
    await _repository.clearSession();
    notifyListeners();
  }

  Future<void> resetDemoData() async {
    await _repository.resetToSeed();
    await initialize();
  }

  Future<void> _push(Future<void> Function() action) async {
    if (!_backendConnected) return;
    try {
      await action();
    } catch (_) {
      _backendConnected = false;
    }
  }

  Future<void> saveCategory(Category category) async {
    final index = _categories.indexWhere((item) => item.id == category.id);
    if (index == -1) {
      _categories = [..._categories, category];
    } else {
      final copy = [..._categories];
      copy[index] = category;
      _categories = copy;
    }
    await _repository.saveCategories(_categories);
    await _push(() => _remoteApi.upsertCategory(category, storeId: _session.storeId!));
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    _categories = _categories.where((item) => item.id != id).toList();
    _products = _products.where((item) => item.categoryId != id).toList();
    await _repository.saveCategories(_categories);
    await _repository.saveProducts(_products);
    await _push(() => _remoteApi.deleteCategory(id));
    notifyListeners();
  }

  /// Rasmni Storage'ga yuklab, ommaviy URL qaytaradi (mahsulot/banner uchun).
  Future<String> uploadProductImage(Uint8List bytes, String filename) async {
    final storeId = _session.storeId;
    if (storeId == null) {
      throw StateError('Do\'kon tanlanmagan');
    }
    return _remoteApi.uploadProductImage(bytes, filename, storeId: storeId);
  }

  Future<void> saveProduct(Product product) async {
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index == -1) {
      _products = [..._products, product];
    } else {
      final copy = [..._products];
      copy[index] = product;
      _products = copy;
    }
    await _repository.saveProducts(_products);
    await _push(() => _remoteApi.upsertProduct(product, storeId: _session.storeId!));
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    _products = _products.where((item) => item.id != id).toList();
    await _repository.saveProducts(_products);
    await _push(() => _remoteApi.deleteProduct(id));
    notifyListeners();
  }

  // ====== BONUS DO'KONI (bonus_items / bonus_requests / user_points) ======

  String? get currentStoreId => _session.storeId;

  Future<List<Map<String, dynamic>>> bonusItems() =>
      _remoteApi.getBonusItems(_session.storeId ?? '');

  Future<void> saveBonusItem(Map<String, dynamic> data) =>
      _remoteApi.upsertBonusItem(data);

  Future<void> removeBonusItem(String id) => _remoteApi.deleteBonusItem(id);

  Future<List<Map<String, dynamic>>> bonusRequests() =>
      _remoteApi.getBonusRequests(_session.storeId ?? '');

  Future<void> updateBonusRequest(String id, String status) =>
      _remoteApi.updateBonusRequestStatus(id, status);

  Future<void> adjustPoints(String userId, int delta) => _remoteApi.adjustUserPoints(
        storeId: _session.storeId ?? '',
        userId: userId,
        delta: delta,
      );

  // ── Bonus sozlamalari (faollashtirish + ball qoidasi) ──
  Future<Map<String, dynamic>?> storeBonusSettings() =>
      _remoteApi.getStoreBonus(_session.storeId ?? '');

  Future<void> saveStoreBonus({
    required bool enabled,
    required num amount,
    required int points,
  }) =>
      _remoteApi.updateStoreBonus(_session.storeId ?? '',
          enabled: enabled, amount: amount, points: points);

  // ── Buyurtma bildirishnomalari ──
  Future<int> unreadOrderNotifs() =>
      _remoteApi.unreadOrderNotifCount(_session.storeId ?? '');

  Future<void> markOrderNotifsRead() =>
      _remoteApi.markOrderNotifsRead(_session.storeId ?? '');

  OrderWatch watchNewOrders(void Function() onNew) =>
      _remoteApi.watchNewOrders(_session.storeId ?? '', onNew);

  Future<void> adjustInventory({
    required String productId,
    required InventoryAction action,
    required int amount,
  }) async {
    final index = _products.indexWhere((item) => item.id == productId);
    if (index == -1) {
      return;
    }
    final current = _products[index];
    var newStock = current.stock;
    switch (action) {
      case InventoryAction.add:
        newStock = current.stock + amount;
        break;
      case InventoryAction.subtract:
        newStock = current.stock - amount;
        break;
      case InventoryAction.set:
        newStock = amount;
        break;
    }
    if (newStock < 0) {
      newStock = 0;
    }
    final copy = [..._products];
    final updated = current.copyWith(stock: newStock);
    copy[index] = updated;
    _products = copy;
    await _repository.saveProducts(_products);
    await _push(() => _remoteApi.upsertProduct(updated, storeId: _session.storeId!));
    notifyListeners();
  }

  Future<void> saveDriver(DriverProfile driver) async {
    final index = _drivers.indexWhere((item) => item.id == driver.id);
    if (index == -1) {
      _drivers = [..._drivers, driver];
    } else {
      final copy = [..._drivers];
      copy[index] = driver;
      _drivers = copy;
    }
    await _repository.saveDrivers(_drivers);
    await _push(() => _remoteApi.upsertDriver(driver, storeId: _session.storeId!));
    notifyListeners();
  }

  Future<void> deleteDriver(String id) async {
    _drivers = _drivers.where((item) => item.id != id).toList();
    _orders = _orders
        .map(
          (order) => order.driverId == id
              ? order.copyWith(status: OrderStatus.pending, clearDriverId: true)
              : order,
        )
        .toList();
    await _repository.saveDrivers(_drivers);
    await _repository.saveOrders(_orders);
    await _push(() => _remoteApi.deleteDriver(id));
    notifyListeners();
  }

  Future<void> updateDriverStatus(String id, DriverStatus status) async {
    final index = _drivers.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    final current = _drivers[index];
    final updated = status == DriverStatus.free
        ? current.copyWith(status: status, clearCurrentOrderId: true)
        : current.copyWith(status: status);
    final copy = [..._drivers];
    copy[index] = updated;
    _drivers = copy;
    await _repository.saveDrivers(_drivers);
    await _push(() => _remoteApi.upsertDriver(updated, storeId: _session.storeId!));
    notifyListeners();
  }

  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    final index = _orders.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    final current = _orders[index];
    final updated = current.copyWith(
      status: status,
      clearDriverId: status == OrderStatus.pending || status == OrderStatus.cancelled,
    );
    final copy = [..._orders];
    copy[index] = updated;
    _orders = copy;
    if (status == OrderStatus.pending || status == OrderStatus.cancelled) {
      _drivers = _drivers
          .map(
            (driver) => driver.currentOrderId == id
                ? driver.copyWith(status: DriverStatus.free, clearCurrentOrderId: true)
                : driver,
          )
          .toList();
      await _repository.saveDrivers(_drivers);
    }
    await _repository.saveOrders(_orders);
    await _push(() => _remoteApi.upsertOrder(updated, storeId: _session.storeId!));
    notifyListeners();
  }

  Future<void> assignDriver({required String orderId, required String driverId}) async {
    final orderIndex = _orders.indexWhere((item) => item.id == orderId);
    final driverIndex = _drivers.indexWhere((item) => item.id == driverId);
    if (orderIndex == -1 || driverIndex == -1) {
      return;
    }
    final orderCopy = [..._orders];
    final currentOrder = orderCopy[orderIndex];
    final newStatus = currentOrder.status == OrderStatus.completed ||
            currentOrder.status == OrderStatus.processing
        ? currentOrder.status
        : OrderStatus.pending;
    orderCopy[orderIndex] = currentOrder.copyWith(
      status: newStatus,
      driverId: driverId,
    );
    _orders = orderCopy;

    _drivers = _drivers
        .map(
          (driver) => driver.currentOrderId == orderId && driver.id != driverId
              ? driver.copyWith(status: DriverStatus.free, clearCurrentOrderId: true)
              : driver,
        )
        .toList();
    final driverCopy = [..._drivers];
    final updatedDriver = driverCopy[driverIndex].copyWith(
      status: DriverStatus.busy,
      currentOrderId: orderId,
    );
    driverCopy[driverIndex] = updatedDriver;
    _drivers = driverCopy;

    await _repository.saveOrders(_orders);
    await _repository.saveDrivers(_drivers);
    await _push(() => _remoteApi.upsertOrder(_orders[orderIndex], storeId: _session.storeId!));
    await _push(() => _remoteApi.upsertDriver(updatedDriver, storeId: _session.storeId!));
    notifyListeners();
  }

  Future<void> driverAcceptOrder({required String orderId, required String driverId}) async {
    final orderIndex = _orders.indexWhere((item) => item.id == orderId);
    if (orderIndex == -1) {
      return;
    }
    final order = _orders[orderIndex];
    if (order.driverId != driverId) {
      return;
    }
    final orderCopy = [..._orders];
    final updated = order.copyWith(status: OrderStatus.processing);
    orderCopy[orderIndex] = updated;
    _orders = orderCopy;
    await _repository.saveOrders(_orders);
    await _push(() => _remoteApi.upsertOrder(updated, storeId: _session.storeId!));
    notifyListeners();
  }

  Future<void> driverRejectOrder({required String orderId, required String driverId}) async {
    final orderIndex = _orders.indexWhere((item) => item.id == orderId);
    if (orderIndex == -1) {
      return;
    }
    final order = _orders[orderIndex];
    if (order.driverId != driverId) {
      return;
    }
    final orderCopy = [..._orders];
    final updatedOrder = order.copyWith(
      status: OrderStatus.pending,
      clearDriverId: true,
    );
    orderCopy[orderIndex] = updatedOrder;
    _orders = orderCopy;

    DriverProfile? updatedDriver;
    final driverIndex = _drivers.indexWhere((item) => item.id == driverId);
    if (driverIndex != -1) {
      final driverCopy = [..._drivers];
      updatedDriver = driverCopy[driverIndex].copyWith(
        status: DriverStatus.free,
        clearCurrentOrderId: true,
      );
      driverCopy[driverIndex] = updatedDriver;
      _drivers = driverCopy;
      await _repository.saveDrivers(_drivers);
    }

    await _repository.saveOrders(_orders);
    await _push(() => _remoteApi.upsertOrder(updatedOrder, storeId: _session.storeId!));
    final d = updatedDriver;
    if (d != null) {
      await _push(() => _remoteApi.upsertDriver(d, storeId: _session.storeId!));
    }
    notifyListeners();
  }

  Future<void> completeDelivery(String orderId, String driverId) async {
    final orderIndex = _orders.indexWhere((item) => item.id == orderId);
    final driverIndex = _drivers.indexWhere((item) => item.id == driverId);
    if (orderIndex == -1 || driverIndex == -1) {
      return;
    }
    final orderCopy = [..._orders];
    final updatedOrder = orderCopy[orderIndex].copyWith(status: OrderStatus.completed);
    orderCopy[orderIndex] = updatedOrder;
    _orders = orderCopy;

    final driver = _drivers[driverIndex];
    final driverCopy = [..._drivers];
    final updatedDriver = driver.copyWith(
      status: DriverStatus.free,
      completedOrders: driver.completedOrders + 1,
      clearCurrentOrderId: true,
    );
    driverCopy[driverIndex] = updatedDriver;
    _drivers = driverCopy;

    await _repository.saveOrders(_orders);
    await _repository.saveDrivers(_drivers);
    await _push(() => _remoteApi.upsertOrder(updatedOrder, storeId: _session.storeId!));
    await _push(() => _remoteApi.upsertDriver(updatedDriver, storeId: _session.storeId!));
    notifyListeners();
  }

  Future<void> updateApplication(
    String id,
    ApplicationStatus status, {
    String? note,
  }) async {
    final index = _applications.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    final copy = [..._applications];
    copy[index] = copy[index].copyWith(
      status: status,
      adminNote: note ?? copy[index].adminNote,
    );
    _applications = copy;
    await _repository.saveApplications(_applications);
    final patch = <String, dynamic>{
      'status': status.toString().split('.').last,
    };
    if (note != null) patch['admin_note'] = note;
    await _push(() => _remoteApi.patchApplication(id, patch));
    notifyListeners();
  }

  Future<void> refreshFromServer() async {
    if (_session.storeId == null) return;
    try {
      final snapshot = await _remoteApi.fetchAll(storeId: _session.storeId);
      _categories = snapshot.categories;
      _products = snapshot.products;
      _orders = snapshot.orders;
      _drivers = snapshot.drivers;
      _applications = snapshot.applications;
      _backendConnected = true;
      await _saveAllToLocal();
      notifyListeners();
    } catch (_) {
      _backendConnected = false;
      notifyListeners();
    }
  }
}
