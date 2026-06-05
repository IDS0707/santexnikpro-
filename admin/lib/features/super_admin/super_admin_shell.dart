import 'package:flutter/material.dart';

import '../../app/state/app_scope.dart';
import '../../app/state/app_store.dart';
import '../../ui/theme.dart';
import 'pages/global_dashboard_page.dart';
import 'pages/stores_management_page.dart';
import 'pages/users_management_page.dart';
import 'pages/global_analytics_page.dart';
import 'pages/activity_logs_page.dart';
import 'pages/plans_page.dart';
import 'pages/pending_shops_page.dart';
import 'pages/banners_management_page.dart';
import 'pages/notification_templates_page.dart';

class SuperAdminShell extends StatefulWidget {
  const SuperAdminShell({super.key});

  @override
  State<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends State<SuperAdminShell> {
  int _selected = 0;

  static const List<_NavItem> _items = [
    _NavItem('Bosh sahifa', Icons.dashboard_rounded),
    _NavItem('Kutilayotgan', Icons.pending_actions_rounded),
    _NavItem('Do\'konlar', Icons.storefront_rounded),
    _NavItem('Reklama', Icons.image_rounded),
    _NavItem('Bildirishnomalar', Icons.notifications_active_rounded),
    _NavItem('Tarif rejalari', Icons.workspace_premium_rounded),
    _NavItem('Mijozlar', Icons.people_rounded),
    _NavItem('Analitika', Icons.insights_rounded),
    _NavItem('Faollik tarixi', Icons.history_rounded),
  ];

  Widget _bodyFor(int i, AppStore store) {
    switch (i) {
      case 0: return GlobalDashboardPage(onOpenStore: (id) {
                  setState(() => _selected = 2);
                });
      case 1: return const PendingShopsPage();
      case 2: return const StoresManagementPage();
      case 3: return const BannersManagementPage();
      case 4: return const NotificationTemplatesPage();
      case 5: return const PlansPage();
      case 6: return const UsersManagementPage();
      case 7: return const GlobalAnalyticsPage();
      case 8: return const ActivityLogsPage();
      default: return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.watch(context);
    final superName = store.session.superAdminName ?? 'Super Admin';
    final width = MediaQuery.of(context).size.width;
    final compact = width < 1000;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: [
            if (!compact) _Sidebar(
              selected: _selected,
              items: _items,
              superName: superName,
              onSelect: (i) => setState(() => _selected = i),
              onLogout: () async {
                await store.logout();
              },
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    title: _items[_selected].label,
                    superName: superName,
                    compact: compact,
                    onMenu: compact ? () => _showMobileMenu(context) : null,
                  ),
                  Expanded(child: _bodyFor(_selected, store)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            ..._items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              return ListTile(
                leading: Icon(item.icon, color: _selected == i ? AppColors.primary : AppColors.textMuted),
                title: Text(item.label, style: TextStyle(
                  fontWeight: _selected == i ? FontWeight.w800 : FontWeight.w500,
                  color: _selected == i ? AppColors.primary : null,
                )),
                onTap: () { Navigator.pop(context); setState(() => _selected = i); },
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
              title: const Text('Chiqish', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(context);
                AppScope.read(context).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selected,
    required this.items,
    required this.superName,
    required this.onSelect,
    required this.onLogout,
  });

  final int selected;
  final List<_NavItem> items;
  final String superName;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('SANTEXNIK PRO',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
                            fontSize: 14, letterSpacing: 0.8)),
                      Text('Super Admin paneli',
                        style: TextStyle(color: Colors.white60, fontSize: 10.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final active = i == selected;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Material(
                color: active ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onSelect(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Icon(item.icon, color: active ? Colors.white : Colors.white60, size: 20),
                        const SizedBox(width: 12),
                        Text(item.label, style: TextStyle(
                          color: active ? Colors.white : Colors.white70,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onLogout,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
                      SizedBox(width: 12),
                      Text('Chiqish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.superName,
    required this.compact,
    this.onMenu,
  });

  final String title;
  final String superName;
  final bool compact;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (onMenu != null)
            IconButton(icon: const Icon(Icons.menu_rounded), onPressed: onMenu),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('SUPER ADMIN',
                style: TextStyle(color: Color(0xFF7C3AED), fontSize: 10, fontWeight: FontWeight.w900)),
          ),
          const Spacer(),
          if (!compact) ...[
            // Notification icon
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_rounded, color: AppColors.textMuted),
                  Positioned(
                    right: -2, top: -2,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
            // Help icon
            IconButton(
              icon: const Icon(Icons.help_outline_rounded, color: AppColors.textMuted),
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 28, color: Colors.grey.shade200),
            const SizedBox(width: 12),
          ],
          // Profile chip
          Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Text(superName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
