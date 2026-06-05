import 'package:flutter/material.dart';

import '../../app/state/app_scope.dart';
import '../../app/state/app_store.dart';
import '../../core/responsive.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _storeSlugController = TextEditingController(text: 'santexnika');
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        setState(() {
          _error = null;
          _loginController.clear();
          _passwordController.clear();
        });
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _storeSlugController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final store = AppScope.read(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    final success = _tabController.index == 0
        ? await store.loginAdmin(
            _loginController.text,
            _passwordController.text,
            storeSlug: _storeSlugController.text.trim(),
          )
        : await store.loginDriver(
            _loginController.text,
            _passwordController.text,
          );
    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
      if (!success) {
        _error = _tabController.index == 0
            ? 'Admin login yoki parol noto\'g\'ri'
            : 'Haydovchi login yoki parol noto\'g\'ri';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final horizontalPadding = ResponsiveHelper.getHorizontalPadding(context);
    final verticalPadding = ResponsiveHelper.getVerticalPadding(context);

    final formCard = SurfaceCard(
      padding: EdgeInsets.all(horizontalPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tizimga kirish',
              style: TextStyle(
                fontSize: isMobile ? 22 : 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Admin panel va haydovchi interfeysi bir xil ma\'lumotlar bazasi bilan ishlaydi.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            SizedBox(height: verticalPadding),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                tabs: const [
                  Tab(text: 'Admin'),
                  Tab(text: 'Haydovchi'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_tabController.index == 0) ...[
              TextFormField(
                controller: _storeSlugController,
                decoration: const InputDecoration(
                  labelText: 'Do\'kon kodi (slug)',
                  hintText: 'santexnika',
                  prefixIcon: Icon(Icons.storefront_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Do\'kon kodini kiriting'
                    : null,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _loginController,
              decoration: InputDecoration(
                labelText: 'Login',
                hintText: _tabController.index == 0
                    ? AppStore.adminLogin
                    : 'driver_ali',
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Login kiriting'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Parol',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Parol kiriting'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kirish'),
              ),
            ),
            const SizedBox(height: 22),
            const _DemoCredentials(),
          ],
        ),
      ),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE6FFFA), Color(0xFFF8FAFC), Color(0xFFFFEDD5)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _HeroHeader(),
                        const SizedBox(height: 20),
                        const _HeroChecklist(),
                        const SizedBox(height: 24),
                        formCard,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 20,
                              bottom: 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                _HeroHeader(),
                                SizedBox(height: 18),
                                _HeroChecklist(),
                              ],
                            ),
                          ),
                        ),
                        Expanded(child: formCard),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.water_drop_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Santexnika admin paneli qayta qurildi',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Mahsulot, buyurtma, haydovchi va bonus arizalarini bitta Flutter ilovada boshqarish uchun yangi, toza baza.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _HeroChecklist extends StatelessWidget {
  const _HeroChecklist();

  @override
  Widget build(BuildContext context) {
    const items = [
      'Mahsulot va kategoriyalar CRUD',
      'Buyurtma statuslari va haydovchi taqsimoti',
      'Zaxira boshqaruvi va mijoz statistikasi',
      'Haydovchi uchun alohida ishchi panel',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DemoCredentials extends StatelessWidget {
  const _DemoCredentials();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Demo kirish', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text('Admin: admin@santex.local / Admin123!'),
          SizedBox(height: 4),
          Text('Haydovchi: driver_ali / Driver123!'),
        ],
      ),
    );
  }
}
