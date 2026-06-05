import 'dart:convert';

enum UserRole { none, admin, driver, superAdmin }

enum ProductBadge { none, yangi, chegirma, tavsiya, ommabop }

enum OrderStatus { pending, processing, completed, cancelled }

enum DriverStatus { free, busy, offline }

enum ApplicationStatus { newRequest, reviewing, approved, rejected }

enum InventoryAction { add, subtract, set }

String _enumName(Object value) => value.toString().split('.').last;

T _readEnum<T>(List<T> values, String raw, T fallback) {
  return values.firstWhere(
    (value) => _enumName(value as Object) == raw,
    orElse: () => fallback,
  );
}

class AppSession {
  const AppSession({
    required this.role,
    this.driverId,
    this.storeId,
    this.storeName,
    this.storeSlug,
    this.superAdminId,
    this.superAdminName,
    this.impersonating = false,
  });

  final UserRole role;
  final String? driverId;
  final String? storeId;
  final String? storeName;
  final String? storeSlug;
  final String? superAdminId;
  final String? superAdminName;
  final bool impersonating;

  bool get isSuperAdmin => role == UserRole.superAdmin;

  Map<String, dynamic> toMap() => {
    'role': _enumName(role),
    'driverId': driverId,
    'storeId': storeId,
    'storeName': storeName,
    'storeSlug': storeSlug,
    'superAdminId': superAdminId,
    'superAdminName': superAdminName,
    'impersonating': impersonating,
  };

  factory AppSession.fromMap(Map<String, dynamic> map) => AppSession(
    role: _readEnum(
      UserRole.values,
      map['role'] as String? ?? 'none',
      UserRole.none,
    ),
    driverId: map['driverId'] as String?,
    storeId: map['storeId'] as String?,
    storeName: map['storeName'] as String?,
    storeSlug: map['storeSlug'] as String?,
    superAdminId: map['superAdminId'] as String?,
    superAdminName: map['superAdminName'] as String?,
    impersonating: (map['impersonating'] as bool?) ?? false,
  );

  String encode() => jsonEncode(toMap());

  factory AppSession.decode(String raw) =>
      AppSession.fromMap(jsonDecode(raw) as Map<String, dynamic>);

  static const empty = AppSession(role: UserRole.none);
}

class StoreSummary {
  const StoreSummary({
    required this.id,
    required this.slug,
    required this.name,
    required this.status,
    required this.commissionRate,
    required this.createdAt,
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalProducts,
    required this.totalCustomers,
  });

  final String id;
  final String slug;
  final String name;
  final String status;
  final double commissionRate;
  final DateTime createdAt;
  final int totalOrders;
  final double totalRevenue;
  final int totalProducts;
  final int totalCustomers;

  bool get isActive => status == 'active';
  bool get isBlocked => status == 'blocked';

  factory StoreSummary.fromMap(Map<String, dynamic> m) => StoreSummary(
        id: m['id'] as String,
        slug: m['slug'] as String,
        name: m['name'] as String,
        status: (m['status'] as String?) ?? 'active',
        commissionRate: ((m['commission_rate'] as num?) ?? 0).toDouble(),
        createdAt: DateTime.parse(m['created_at'] as String),
        totalOrders: ((m['total_orders'] as num?) ?? 0).toInt(),
        totalRevenue: ((m['total_revenue'] as num?) ?? 0).toDouble(),
        totalProducts: ((m['total_products'] as num?) ?? 0).toInt(),
        totalCustomers: ((m['total_customers'] as num?) ?? 0).toInt(),
      );
}

class GlobalStats {
  const GlobalStats({
    required this.totalStores,
    required this.activeStores,
    required this.blockedStores,
    required this.totalUsers,
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalCommission,
    required this.completedOrders,
    required this.pendingOrders,
  });

  final int totalStores;
  final int activeStores;
  final int blockedStores;
  final int totalUsers;
  final int totalOrders;
  final double totalRevenue;
  final double totalCommission;
  final int completedOrders;
  final int pendingOrders;

  factory GlobalStats.fromMap(Map<String, dynamic> m) => GlobalStats(
        totalStores: ((m['total_stores'] as num?) ?? 0).toInt(),
        activeStores: ((m['active_stores'] as num?) ?? 0).toInt(),
        blockedStores: ((m['blocked_stores'] as num?) ?? 0).toInt(),
        totalUsers: ((m['total_users'] as num?) ?? 0).toInt(),
        totalOrders: ((m['total_orders'] as num?) ?? 0).toInt(),
        totalRevenue: ((m['total_revenue'] as num?) ?? 0).toDouble(),
        totalCommission: ((m['total_commission'] as num?) ?? 0).toDouble(),
        completedOrders: ((m['completed_orders'] as num?) ?? 0).toInt(),
        pendingOrders: ((m['pending_orders'] as num?) ?? 0).toInt(),
      );
}

class TopStore {
  const TopStore({
    required this.storeId,
    required this.storeName,
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalCommission,
  });

  final String storeId;
  final String storeName;
  final int totalOrders;
  final double totalRevenue;
  final double totalCommission;

  factory TopStore.fromMap(Map<String, dynamic> m) => TopStore(
        storeId: m['store_id'] as String,
        storeName: m['store_name'] as String,
        totalOrders: ((m['total_orders'] as num?) ?? 0).toInt(),
        totalRevenue: ((m['total_revenue'] as num?) ?? 0).toDouble(),
        totalCommission: ((m['total_commission'] as num?) ?? 0).toDouble(),
      );
}

class PeriodStats {
  const PeriodStats({
    required this.totalRevenue,
    required this.totalOrders,
    required this.avgOrder,
    required this.totalCommission,
    required this.completedOrders,
    required this.pendingOrders,
  });

  final double totalRevenue;
  final int totalOrders;
  final double avgOrder;
  final double totalCommission;
  final int completedOrders;
  final int pendingOrders;

  factory PeriodStats.fromMap(Map<String, dynamic> m) => PeriodStats(
        totalRevenue: ((m['total_revenue'] as num?) ?? 0).toDouble(),
        totalOrders: ((m['total_orders'] as num?) ?? 0).toInt(),
        avgOrder: ((m['avg_order'] as num?) ?? 0).toDouble(),
        totalCommission: ((m['total_commission'] as num?) ?? 0).toDouble(),
        completedOrders: ((m['completed_orders'] as num?) ?? 0).toInt(),
        pendingOrders: ((m['pending_orders'] as num?) ?? 0).toInt(),
      );

  static const empty = PeriodStats(
    totalRevenue: 0,
    totalOrders: 0,
    avgOrder: 0,
    totalCommission: 0,
    completedOrders: 0,
    pendingOrders: 0,
  );
}

class DailyPoint {
  const DailyPoint({required this.day, required this.revenue, required this.orders});
  final DateTime day;
  final double revenue;
  final int orders;

  factory DailyPoint.fromMap(Map<String, dynamic> m) => DailyPoint(
        day: DateTime.parse(m['day_bucket'] as String),
        revenue: ((m['total_revenue'] as num?) ?? 0).toDouble(),
        orders: ((m['total_orders'] as num?) ?? 0).toInt(),
      );
}

class TopProduct {
  const TopProduct({
    required this.name,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.storeName,
  });

  final String name;
  final int totalQuantity;
  final double totalRevenue;
  final String storeName;

  factory TopProduct.fromMap(Map<String, dynamic> m) => TopProduct(
        name: (m['product_name'] as String?) ?? '?',
        totalQuantity: ((m['total_quantity'] as num?) ?? 0).toInt(),
        totalRevenue: ((m['total_revenue'] as num?) ?? 0).toDouble(),
        storeName: (m['store_name'] as String?) ?? '',
      );
}

class AppUserRecord {
  const AppUserRecord({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
    required this.status,
    required this.createdAt,
    this.email,
    this.currentStoreId,
  });

  final String id;
  final String phone;
  final String name;
  final String? email;
  final String role;
  final String status;
  final String? currentStoreId;
  final DateTime createdAt;

  factory AppUserRecord.fromMap(Map<String, dynamic> m) => AppUserRecord(
        id: m['id'] as String,
        phone: m['phone'] as String,
        name: m['name'] as String,
        email: m['email'] as String?,
        role: (m['role'] as String?) ?? 'customer',
        status: (m['status'] as String?) ?? 'active',
        currentStoreId: m['current_store_id'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.icon,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String code;
  final String description;
  final String icon;
  final DateTime createdAt;

  Category copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    String? icon,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'code': code,
    'description': description,
    'icon': icon,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as String,
    name: map['name'] as String,
    code: map['code'] as String,
    description: map['description'] as String? ?? '',
    icon: map['icon'] as String? ?? 'category',
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.stock,
    required this.sku,
    required this.description,
    required this.badge,
    required this.createdAt,
    required this.soldCount,
    this.oldPrice,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String categoryId;
  final double price;
  final double? oldPrice;
  final int stock;
  final String sku;
  final String description;
  final ProductBadge badge;
  final DateTime createdAt;
  final int soldCount;
  final String? imageUrl;

  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? price,
    double? oldPrice,
    bool clearOldPrice = false,
    int? stock,
    String? sku,
    String? description,
    ProductBadge? badge,
    DateTime? createdAt,
    int? soldCount,
    String? imageUrl,
    bool clearImageUrl = false,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      oldPrice: clearOldPrice ? null : oldPrice ?? this.oldPrice,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      badge: badge ?? this.badge,
      createdAt: createdAt ?? this.createdAt,
      soldCount: soldCount ?? this.soldCount,
      imageUrl: clearImageUrl ? null : imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'price': price,
    'oldPrice': oldPrice,
    'stock': stock,
    'sku': sku,
    'description': description,
    'badge': _enumName(badge),
    'createdAt': createdAt.toIso8601String(),
    'soldCount': soldCount,
    'imageUrl': imageUrl,
  };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: map['id'] as String,
    name: map['name'] as String,
    categoryId: map['categoryId'] as String,
    price: (map['price'] as num).toDouble(),
    oldPrice: (map['oldPrice'] as num?)?.toDouble(),
    stock: (map['stock'] as num).toInt(),
    sku: map['sku'] as String? ?? '',
    description: map['description'] as String? ?? '',
    badge: _readEnum(
      ProductBadge.values,
      map['badge'] as String? ?? 'none',
      ProductBadge.none,
    ),
    createdAt: DateTime.parse(map['createdAt'] as String),
    soldCount: (map['soldCount'] as num?)?.toInt() ?? 0,
    imageUrl: map['imageUrl'] as String?,
  );
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String productId;
  final String name;
  final int quantity;
  final double price;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'quantity': quantity,
    'price': price,
  };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    productId: map['productId'] as String,
    name: map['name'] as String,
    quantity: (map['quantity'] as num).toInt(),
    price: (map['price'] as num).toDouble(),
  );
}

class OrderRecord {
  const OrderRecord({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.email,
    this.driverId,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String customerName;
  final String phone;
  final String? email;
  final String address;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final String? driverId;
  final double? latitude;
  final double? longitude;

  OrderRecord copyWith({
    String? id,
    String? customerName,
    String? phone,
    String? email,
    bool clearEmail = false,
    String? address,
    List<OrderItem>? items,
    double? total,
    OrderStatus? status,
    DateTime? createdAt,
    String? driverId,
    bool clearDriverId = false,
    double? latitude,
    bool clearLatitude = false,
    double? longitude,
    bool clearLongitude = false,
  }) {
    return OrderRecord(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      email: clearEmail ? null : email ?? this.email,
      address: address ?? this.address,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      driverId: clearDriverId ? null : driverId ?? this.driverId,
      latitude: clearLatitude ? null : latitude ?? this.latitude,
      longitude: clearLongitude ? null : longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'customerName': customerName,
    'phone': phone,
    'email': email,
    'address': address,
    'items': items.map((item) => item.toMap()).toList(),
    'total': total,
    'status': _enumName(status),
    'createdAt': createdAt.toIso8601String(),
    'driverId': driverId,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory OrderRecord.fromMap(Map<String, dynamic> map) => OrderRecord(
    id: map['id'] as String,
    customerName: map['customerName'] as String,
    phone: map['phone'] as String,
    email: map['email'] as String?,
    address: map['address'] as String,
    items: (map['items'] as List<dynamic>)
        .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
        .toList(),
    total: (map['total'] as num).toDouble(),
    status: _readEnum(
      OrderStatus.values,
      map['status'] as String? ?? 'pending',
      OrderStatus.pending,
    ),
    createdAt: DateTime.parse(map['createdAt'] as String),
    driverId: map['driverId'] as String?,
    latitude: (map['latitude'] as num?)?.toDouble(),
    longitude: (map['longitude'] as num?)?.toDouble(),
  );
}

class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.login,
    required this.password,
    required this.vehicleNumber,
    required this.status,
    required this.completedOrders,
    required this.rating,
    this.currentOrderId,
  });

  final String id;
  final String name;
  final String phone;
  final String login;
  final String password;
  final String vehicleNumber;
  final DriverStatus status;
  final int completedOrders;
  final double rating;
  final String? currentOrderId;

  DriverProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? login,
    String? password,
    String? vehicleNumber,
    DriverStatus? status,
    int? completedOrders,
    double? rating,
    String? currentOrderId,
    bool clearCurrentOrderId = false,
  }) {
    return DriverProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      login: login ?? this.login,
      password: password ?? this.password,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      status: status ?? this.status,
      completedOrders: completedOrders ?? this.completedOrders,
      rating: rating ?? this.rating,
      currentOrderId: clearCurrentOrderId
          ? null
          : currentOrderId ?? this.currentOrderId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'login': login,
    'password': password,
    'vehicleNumber': vehicleNumber,
    'status': _enumName(status),
    'completedOrders': completedOrders,
    'rating': rating,
    'currentOrderId': currentOrderId,
  };

  factory DriverProfile.fromMap(Map<String, dynamic> map) => DriverProfile(
    id: map['id'] as String,
    name: map['name'] as String,
    phone: map['phone'] as String,
    login: map['login'] as String,
    password: map['password'] as String,
    vehicleNumber: map['vehicleNumber'] as String,
    status: _readEnum(
      DriverStatus.values,
      map['status'] as String? ?? 'free',
      DriverStatus.free,
    ),
    completedOrders: (map['completedOrders'] as num?)?.toInt() ?? 0,
    rating: (map['rating'] as num?)?.toDouble() ?? 5,
    currentOrderId: map['currentOrderId'] as String?,
  );
}

class ApplicationRecord {
  const ApplicationRecord({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.bonusType,
    required this.points,
    required this.currentBalance,
    required this.status,
    required this.createdAt,
    this.email,
    this.adminNote,
  });

  final String id;
  final String customerName;
  final String phone;
  final String? email;
  final String bonusType;
  final int points;
  final int currentBalance;
  final ApplicationStatus status;
  final DateTime createdAt;
  final String? adminNote;

  ApplicationRecord copyWith({
    String? id,
    String? customerName,
    String? phone,
    String? email,
    bool clearEmail = false,
    String? bonusType,
    int? points,
    int? currentBalance,
    ApplicationStatus? status,
    DateTime? createdAt,
    String? adminNote,
    bool clearAdminNote = false,
  }) {
    return ApplicationRecord(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      email: clearEmail ? null : email ?? this.email,
      bonusType: bonusType ?? this.bonusType,
      points: points ?? this.points,
      currentBalance: currentBalance ?? this.currentBalance,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      adminNote: clearAdminNote ? null : adminNote ?? this.adminNote,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'customerName': customerName,
    'phone': phone,
    'email': email,
    'bonusType': bonusType,
    'points': points,
    'currentBalance': currentBalance,
    'status': _enumName(status),
    'createdAt': createdAt.toIso8601String(),
    'adminNote': adminNote,
  };

  factory ApplicationRecord.fromMap(Map<String, dynamic> map) =>
      ApplicationRecord(
        id: map['id'] as String,
        customerName: map['customerName'] as String,
        phone: map['phone'] as String,
        email: map['email'] as String?,
        bonusType: map['bonusType'] as String,
        points: (map['points'] as num).toInt(),
        currentBalance: (map['currentBalance'] as num).toInt(),
        status: _readEnum(
          ApplicationStatus.values,
          map['status'] as String? ?? 'newRequest',
          ApplicationStatus.newRequest,
        ),
        createdAt: DateTime.parse(map['createdAt'] as String),
        adminNote: map['adminNote'] as String?,
      );
}

class CustomerSummary {
  const CustomerSummary({
    required this.name,
    required this.phone,
    required this.email,
    required this.orderCount,
    required this.totalSpent,
    required this.lastOrder,
    required this.points,
  });

  final String name;
  final String phone;
  final String email;
  final int orderCount;
  final double totalSpent;
  final DateTime lastOrder;
  final int points;
}

extension ProductBadgeX on ProductBadge {
  String get label {
    switch (this) {
      case ProductBadge.none:
        return 'Oddiy';
      case ProductBadge.yangi:
        return 'Yangi';
      case ProductBadge.chegirma:
        return 'Chegirma';
      case ProductBadge.tavsiya:
        return 'Tavsiya';
      case ProductBadge.ommabop:
        return 'Ommabop';
    }
  }
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Yangi';
      case OrderStatus.processing:
        return 'Jarayonda';
      case OrderStatus.completed:
        return 'Bajarildi';
      case OrderStatus.cancelled:
        return 'Bekor';
    }
  }
}

extension DriverStatusX on DriverStatus {
  String get label {
    switch (this) {
      case DriverStatus.free:
        return 'Bo\'sh';
      case DriverStatus.busy:
        return 'Band';
      case DriverStatus.offline:
        return 'Offline';
    }
  }
}

extension ApplicationStatusX on ApplicationStatus {
  String get label {
    switch (this) {
      case ApplicationStatus.newRequest:
        return 'Yangi';
      case ApplicationStatus.reviewing:
        return 'Ko\'rib chiqilmoqda';
      case ApplicationStatus.approved:
        return 'Tasdiqlangan';
      case ApplicationStatus.rejected:
        return 'Rad etilgan';
    }
  }
}
