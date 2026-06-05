import 'models.dart';

class SeedBundle {
	const SeedBundle({
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

SeedBundle buildSeedData() {
	final now = DateTime.now();

	final categories = <Category>[
		Category(id: 'cat-kran', name: 'Kranlar', code: 'kran', description: 'Oshxona va hammom kranlari', icon: 'water_drop', createdAt: now.subtract(const Duration(days: 90))),
		Category(id: 'cat-dush', name: 'Dush', code: 'dush', description: 'Dush kabina va tizimlari', icon: 'shower', createdAt: now.subtract(const Duration(days: 90))),
		Category(id: 'cat-unitaz', name: 'Unitaz', code: 'unitaz', description: 'Sanuzel jihozlari', icon: 'wc', createdAt: now.subtract(const Duration(days: 90))),
		Category(id: 'cat-truba', name: 'Trubalar', code: 'truba', description: 'PP-R va metal plastik', icon: 'plumbing', createdAt: now.subtract(const Duration(days: 90))),
		Category(id: 'cat-nasos', name: 'Nasoslar', code: 'nasos', description: 'Bosim va suv nasoslari', icon: 'settings_input_component', createdAt: now.subtract(const Duration(days: 90))),
	];

	final products = <Product>[
		Product(id: 'prd-001', name: 'Grohe Essence Kran', categoryId: 'cat-kran', price: 450000, oldPrice: 520000, stock: 25, sku: 'KR-001', description: 'Premium oshxona krani', badge: ProductBadge.chegirma, createdAt: now.subtract(const Duration(days: 40)), soldCount: 42),
		Product(id: 'prd-002', name: 'Hansgrohe Focus Kran', categoryId: 'cat-kran', price: 680000, stock: 15, sku: 'KR-002', description: 'Zamonaviy hammom krani', badge: ProductBadge.ommabop, createdAt: now.subtract(const Duration(days: 25)), soldCount: 35),
		Product(id: 'prd-003', name: 'Iddis Premio Kran', categoryId: 'cat-kran', price: 280000, stock: 40, sku: 'KR-003', description: 'Kundalik foydalanish uchun', badge: ProductBadge.none, createdAt: now.subtract(const Duration(days: 18)), soldCount: 28),
		Product(id: 'prd-004', name: 'Roca Esla Kran', categoryId: 'cat-kran', price: 320000, stock: 8, sku: 'KR-004', description: 'Yangi model', badge: ProductBadge.yangi, createdAt: now.subtract(const Duration(days: 7)), soldCount: 12),
		Product(id: 'prd-005', name: 'Aquaform 90x90 Dush Kabina', categoryId: 'cat-dush', price: 1850000, oldPrice: 2100000, stock: 6, sku: 'DK-001', description: 'Kvadrat shisha kabina', badge: ProductBadge.chegirma, createdAt: now.subtract(const Duration(days: 35)), soldCount: 15),
		Product(id: 'prd-006', name: 'Ravak Chrome Dush Kabina', categoryId: 'cat-dush', price: 2400000, stock: 4, sku: 'DK-002', description: 'Tavsiya etiladigan model', badge: ProductBadge.tavsiya, createdAt: now.subtract(const Duration(days: 32)), soldCount: 10),
		Product(id: 'prd-007', name: 'Dush To\'plami Rain', categoryId: 'cat-dush', price: 560000, stock: 20, sku: 'DK-003', description: 'To\'liq dush to\'plami', badge: ProductBadge.none, createdAt: now.subtract(const Duration(days: 20)), soldCount: 30),
		Product(id: 'prd-008', name: 'Cersanit Mito Unitaz', categoryId: 'cat-unitaz', price: 780000, stock: 18, sku: 'UN-001', description: 'Ommabop unitaz', badge: ProductBadge.ommabop, createdAt: now.subtract(const Duration(days: 50)), soldCount: 55),
		Product(id: 'prd-009', name: 'Roca Meridian Unitaz', categoryId: 'cat-unitaz', price: 1200000, oldPrice: 1400000, stock: 9, sku: 'UN-002', description: 'Chegirmadagi model', badge: ProductBadge.chegirma, createdAt: now.subtract(const Duration(days: 45)), soldCount: 22),
		Product(id: 'prd-010', name: 'Laufen Pro Unitaz', categoryId: 'cat-unitaz', price: 1650000, stock: 5, sku: 'UN-003', description: 'Premium variant', badge: ProductBadge.tavsiya, createdAt: now.subtract(const Duration(days: 42)), soldCount: 18),
		Product(id: 'prd-011', name: 'Gigant Sifon', categoryId: 'cat-unitaz', price: 85000, stock: 60, sku: 'UN-004', description: 'Sifon komplekti', badge: ProductBadge.none, createdAt: now.subtract(const Duration(days: 60)), soldCount: 95),
		Product(id: 'prd-012', name: 'PP-R Truba 20mm', categoryId: 'cat-truba', price: 12000, stock: 500, sku: 'TR-001', description: '1 metr bo\'lak', badge: ProductBadge.none, createdAt: now.subtract(const Duration(days: 120)), soldCount: 320),
		Product(id: 'prd-013', name: 'PP-R Truba 32mm', categoryId: 'cat-truba', price: 18000, stock: 350, sku: 'TR-002', description: 'Bosimga chidamli', badge: ProductBadge.none, createdAt: now.subtract(const Duration(days: 110)), soldCount: 210),
		Product(id: 'prd-014', name: 'Metal Plastik Truba 16mm', categoryId: 'cat-truba', price: 22000, stock: 200, sku: 'TR-003', description: 'Ko\'p qatlamli', badge: ProductBadge.none, createdAt: now.subtract(const Duration(days: 100)), soldCount: 180),
		Product(id: 'prd-015', name: 'Grundfos CM3 Nasos', categoryId: 'cat-nasos', price: 2800000, stock: 7, sku: 'NS-001', description: 'Uy uchun nasos', badge: ProductBadge.tavsiya, createdAt: now.subtract(const Duration(days: 70)), soldCount: 12),
		Product(id: 'prd-016', name: 'Wilo Sub TWI 4 Nasos', categoryId: 'cat-nasos', price: 3600000, stock: 3, sku: 'NS-002', description: 'Chuqur quduq uchun', badge: ProductBadge.none, createdAt: now.subtract(const Duration(days: 65)), soldCount: 8),
		Product(id: 'prd-017', name: 'DAB Aquajet 132M', categoryId: 'cat-nasos', price: 1900000, oldPrice: 2200000, stock: 2, sku: 'NS-003', description: 'Chegirmadagi nasos', badge: ProductBadge.chegirma, createdAt: now.subtract(const Duration(days: 55)), soldCount: 14),
	];

	final drivers = <DriverProfile>[
		const DriverProfile(id: 'drv-ali', name: 'Ali Karimov', phone: '+998901234567', login: 'driver_ali', password: 'Driver123!', vehicleNumber: '01 A 123 BB', status: DriverStatus.free, completedOrders: 47, rating: 4.8),
		const DriverProfile(id: 'drv-bobur', name: 'Bobur Toshmatov', phone: '+998901234568', login: 'driver_bobur', password: 'Driver123!', vehicleNumber: '10 B 456 CC', status: DriverStatus.busy, completedOrders: 35, rating: 4.6, currentOrderId: 'ORD-1002'),
		const DriverProfile(id: 'drv-jasur', name: 'Jasur Nazarov', phone: '+998901234569', login: 'driver_jasur', password: 'Driver123!', vehicleNumber: '30 C 789 DD', status: DriverStatus.offline, completedOrders: 28, rating: 4.9),
	];

	final orders = <OrderRecord>[
		OrderRecord(id: 'ORD-1001', customerName: 'Sardor Yusupov', phone: '+998901111111', email: 'sardor@mail.com', address: 'Toshkent, Yunusobod 3-kvartal, 15-uy', items: const [OrderItem(productId: 'prd-001', name: 'Grohe Essence Kran', quantity: 2, price: 450000)], total: 900000, status: OrderStatus.completed, createdAt: now.subtract(const Duration(days: 5)), driverId: 'drv-ali', latitude: 41.3389, longitude: 69.3456),
		OrderRecord(id: 'ORD-1002', customerName: 'Malika Rahimova', phone: '+998902222222', email: 'malika@mail.com', address: 'Toshkent, Chilonzor 9-kvartal, 22-uy', items: const [OrderItem(productId: 'prd-005', name: 'Aquaform 90x90 Dush Kabina', quantity: 1, price: 1850000)], total: 1850000, status: OrderStatus.processing, createdAt: now.subtract(const Duration(hours: 3)), driverId: 'drv-bobur', latitude: 41.2922, longitude: 69.2000),
		OrderRecord(id: 'ORD-1003', customerName: 'Dilshod Mirzayev', phone: '+998903333333', address: 'Toshkent, Mirzo Ulugbek, Qorasaroy 5-uy', items: const [OrderItem(productId: 'prd-008', name: 'Cersanit Mito Unitaz', quantity: 1, price: 780000), OrderItem(productId: 'prd-011', name: 'Gigant Sifon', quantity: 2, price: 85000)], total: 950000, status: OrderStatus.pending, createdAt: now.subtract(const Duration(hours: 1)), latitude: 41.35, longitude: 69.38),
		OrderRecord(id: 'ORD-1004', customerName: 'Gulnora Ergasheva', phone: '+998904444444', address: 'Samarqand, Registon ko\'chasi, 8-uy', items: const [OrderItem(productId: 'prd-012', name: 'PP-R Truba 20mm', quantity: 10, price: 12000)], total: 120000, status: OrderStatus.pending, createdAt: now.subtract(const Duration(minutes: 30)), latitude: 39.6547, longitude: 66.9758),
		OrderRecord(id: 'ORD-1005', customerName: 'Sherzod Qodirov', phone: '+998905555555', address: 'Toshkent, Shayxontohur, Navro\'z 3-uy', items: const [OrderItem(productId: 'prd-015', name: 'Grundfos CM3 Nasos', quantity: 1, price: 2800000)], total: 2800000, status: OrderStatus.cancelled, createdAt: now.subtract(const Duration(days: 2)), latitude: 41.31, longitude: 69.28),
	];

	final applications = <ApplicationRecord>[
		ApplicationRecord(id: 'APP-001', customerName: 'Sardor Yusupov', phone: '+998901111111', email: 'sardor@mail.com', bonusType: '5% chegirma', points: 50, currentBalance: 65, status: ApplicationStatus.newRequest, createdAt: now.subtract(const Duration(days: 1))),
		ApplicationRecord(id: 'APP-002', customerName: 'Malika Rahimova', phone: '+998902222222', bonusType: 'Bepul yetkazib berish', points: 30, currentBalance: 42, status: ApplicationStatus.reviewing, createdAt: now.subtract(const Duration(hours: 5))),
	];

	return SeedBundle(
		categories: categories,
		products: products,
		orders: orders,
		drivers: drivers,
		applications: applications,
	);
}