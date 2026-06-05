import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'seed_data.dart';

class LocalRepository {
	static const _categoriesKey = 'santexnika_categories';
	static const _productsKey = 'santexnika_products';
	static const _ordersKey = 'santexnika_orders';
	static const _driversKey = 'santexnika_drivers';
	static const _applicationsKey = 'santexnika_applications';
	static const _sessionKey = 'santexnika_session';
	static const _seedVersionKey = 'santexnika_seed_version';
	static const _seedVersion = 2;

	late SharedPreferences _prefs;

	Future<void> initialize() async {
		_prefs = await SharedPreferences.getInstance();
		await _ensureSeeded();
	}

	Future<void> _ensureSeeded() async {
		final seededVersion = _prefs.getInt(_seedVersionKey) ?? 0;
		if (seededVersion >= _seedVersion && _prefs.containsKey(_categoriesKey)) {
			return;
		}
		await resetToSeed();
	}

	Future<void> resetToSeed() async {
		final seed = buildSeedData();
		await saveCategories(seed.categories);
		await saveProducts(seed.products);
		await saveOrders(seed.orders);
		await saveDrivers(seed.drivers);
		await saveApplications(seed.applications);
		await _prefs.setInt(_seedVersionKey, _seedVersion);
		await clearSession();
	}

	List<Category> loadCategories() => _readList(_categoriesKey, Category.fromMap);

	List<Product> loadProducts() => _readList(_productsKey, Product.fromMap);

	List<OrderRecord> loadOrders() => _readList(_ordersKey, OrderRecord.fromMap);

	List<DriverProfile> loadDrivers() => _readList(_driversKey, DriverProfile.fromMap);

	List<ApplicationRecord> loadApplications() => _readList(_applicationsKey, ApplicationRecord.fromMap);

	AppSession loadSession() {
		final raw = _prefs.getString(_sessionKey);
		if (raw == null || raw.isEmpty) {
			return AppSession.empty;
		}
		return AppSession.decode(raw);
	}

	Future<void> saveCategories(List<Category> items) => _writeList(_categoriesKey, items.map((item) => item.toMap()).toList());

	Future<void> saveProducts(List<Product> items) => _writeList(_productsKey, items.map((item) => item.toMap()).toList());

	Future<void> saveOrders(List<OrderRecord> items) => _writeList(_ordersKey, items.map((item) => item.toMap()).toList());

	Future<void> saveDrivers(List<DriverProfile> items) => _writeList(_driversKey, items.map((item) => item.toMap()).toList());

	Future<void> saveApplications(List<ApplicationRecord> items) => _writeList(_applicationsKey, items.map((item) => item.toMap()).toList());

	Future<void> saveSession(AppSession session) async {
		await _prefs.setString(_sessionKey, session.encode());
	}

	Future<void> clearSession() async {
		await _prefs.remove(_sessionKey);
	}

	List<T> _readList<T>(String key, T Function(Map<String, dynamic>) mapper) {
		final raw = _prefs.getString(key);
		if (raw == null || raw.isEmpty) {
			return <T>[];
		}
		final decoded = jsonDecode(raw) as List<dynamic>;
		return decoded.map((entry) => mapper(entry as Map<String, dynamic>)).toList();
	}

	Future<void> _writeList(String key, List<Map<String, dynamic>> items) async {
		await _prefs.setString(key, jsonEncode(items));
	}
}