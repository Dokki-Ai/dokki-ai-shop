import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';

// ИМПОРТЫ ЭКРАНОВ
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/catalog/presentation/screens/catalog_screen.dart';
import '../../features/my_bots/presentation/screens/my_bots_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';

// ЛОКАЛИЗАЦИЯ
import '../localization/language_provider.dart';
import '../localization/app_strings.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(), // 0 (только десктоп)
    const CatalogScreen(), // 1
    const MyBotsScreen(), // 2
    const SettingsScreen(), // 3
    const SupportScreen(), // 4
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = ref.watch(stringsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              if (isDesktop) _buildSidebar(s),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
          bottomNavigationBar: isDesktop ? null : _buildBottomNav(s),
        );
      },
    );
  }

  // --- DESKTOP SIDEBAR ---
  Widget _buildSidebar(AppStrings s) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.robot,
                    color: AppColors.accent, size: 28),
                SizedBox(width: 12),
                Text(
                  'DOKKI',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),

          // Передаем иконки: первая стандартная, остальные FontAwesome
          _sidebarItem(Icons.dashboard, 'Dashboard', 0),
          _sidebarItem(FontAwesomeIcons.store, s.navShop, 1),
          _sidebarItem(FontAwesomeIcons.robot, s.navMyBots, 2),
          _sidebarItem(FontAwesomeIcons.gear, s.navSettings, 3),
          _sidebarItem(FontAwesomeIcons.headset, s.navSupport, 4),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'v 1.0.41',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Обновленный метод с безопасной проверкой типа иконки
  Widget _sidebarItem(dynamic icon, String label, int index) {
    final isActive = _currentIndex == index;

    // Проверяем тип иконки и отрисовываем нужный виджет
    Widget iconWidget;
    if (icon is IconData) {
      iconWidget = Icon(icon,
          size: 18,
          color: isActive ? AppColors.accent : AppColors.textSecondary);
    } else {
      iconWidget = FaIcon(icon,
          size: 18,
          color: isActive ? AppColors.accent : AppColors.textSecondary);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _onTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accent.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              iconWidget,
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MOBILE BOTTOM NAV ---
  Widget _buildBottomNav(AppStrings s) {
    return BottomNavigationBar(
      // Если мы на Dashboard (0) и сужаем экран, подсвечиваем Shop (0)
      currentIndex: _currentIndex > 0 ? _currentIndex - 1 : 0,
      // Смещаем индекс на +1, так как Dashboard отсутствует в мобильном меню
      onTap: (index) => _onTap(index + 1),
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontFamily: 'Inter',
      ),
      items: [
        BottomNavigationBarItem(
          icon: const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: FaIcon(FontAwesomeIcons.store, size: 20),
          ),
          label: s.navShop,
        ),
        BottomNavigationBarItem(
          icon: const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: FaIcon(FontAwesomeIcons.robot, size: 20),
          ),
          label: s.navMyBots,
        ),
        BottomNavigationBarItem(
          icon: const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: FaIcon(FontAwesomeIcons.gear, size: 20),
          ),
          label: s.navSettings,
        ),
        BottomNavigationBarItem(
          icon: const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: FaIcon(FontAwesomeIcons.headset, size: 20),
          ),
          label: s.navSupport,
        ),
      ],
    );
  }
}
