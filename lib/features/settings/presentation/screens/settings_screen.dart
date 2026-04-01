import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/localization/app_strings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final s = ref.watch(stringsProvider);
    final currentLang = ref.watch(languageProvider);

    final String langName = switch (currentLang) {
      AppLanguage.ru => 'Русский',
      AppLanguage.en => 'English',
      AppLanguage.ar => 'العربية',
    };

    final user = authState.when(
      data: (user) => user,
      loading: () => null,
      error: (_, __) => null,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          s.navSettings,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter'),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Порог 800 пикселей для переключения в режим Desktop (Mac Mini)
          if (constraints.maxWidth > 800) {
            return _buildDesktopLayout(s, user, langName);
          }
          return _buildMobileLayout(s, user, langName);
        },
      ),
    );
  }

  // --- Верстка для Мобилок ---
  Widget _buildMobileLayout(AppStrings s, dynamic user, String langName) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      children: _buildSettingsItems(s, user, langName),
    );
  }

  // --- Верстка для Desktop (Mac Mini) ---
  Widget _buildDesktopLayout(AppStrings s, dynamic user, String langName) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 4.5,
      padding: const EdgeInsets.all(24),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: _buildSettingsItems(s, user, langName),
    );
  }

  // --- Список элементов настроек ---
  List<Widget> _buildSettingsItems(
      AppStrings s, dynamic user, String langName) {
    return [
      _buildSettingsCard(
        icon: FontAwesomeIcons.user,
        title: s.setAccount,
        subtitle: user?.email ?? s.authLogin,
        badge: user != null ? s.setSubFree : null,
        onTap: () {
          if (user == null) {
            context.push('/auth');
          } else {
            context.push('/profile', extra: user.email);
          }
        },
      ),
      _buildSettingsCard(
        icon: FontAwesomeIcons.globe,
        title: s.setLanguage,
        subtitle: langName,
        onTap: () => context.push('/language'),
      ),
      _buildSettingsCard(
        icon: FontAwesomeIcons.bell,
        title: s.setNotifications,
        subtitle: s.setNotifSettings,
        onTap: () => context.push('/notifications'),
      ),
      _buildSettingsCard(
        icon: FontAwesomeIcons.shieldHalved,
        title: s.setPrivacy,
        subtitle: s.catDetails,
        onTap: () => _openUrl('privacy'),
      ),
      _buildSettingsCard(
        icon: FontAwesomeIcons.fileContract,
        title: s.setTerms,
        subtitle: s.catDetails,
        onTap: () => _openUrl('terms'),
      ),
      _buildSettingsCard(
        icon: FontAwesomeIcons.circleInfo,
        title: s.setAbout,
        subtitle: '${s.setVersion} 1.0.1',
        onTap: () => _showAboutDialog(s),
      ),
    ];
  }

  // --- Основная карточка настройки ---
  Widget _buildSettingsCard({
    required dynamic icon, // dynamic позволяет передавать FaIconData без ошибок
    required String title,
    String? subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  // .withValues(alpha: ...) вместо устаревшего withOpacity
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: FaIcon(
                      icon as FaIconData?, // Явное приведение к типу FaIconData
                      size: 18,
                      color: AppColors.accent),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontFamily: 'Inter',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          _buildBadge(badge),
                        ],
                      ],
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Бейдж (например, FREE план) ---
  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.accent,
        ),
      ),
    );
  }

  void _openUrl(String type) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Open $type')));
  }

  // --- Окно "О приложении" ---
  void _showAboutDialog(AppStrings s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.setAbout,
            style: const TextStyle(
                color: AppColors.textPrimary, fontFamily: 'Inter')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${s.setVersion} 1.0.1',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontFamily: 'Inter')),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _iconBtn(FontAwesomeIcons.telegram, 'Telegram'),
                _iconBtn(FontAwesomeIcons.instagram, 'Instagram'),
                _iconBtn(FontAwesomeIcons.youtube, 'YouTube'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.profCancel,
                  style: const TextStyle(
                      color: AppColors.accent, fontFamily: 'Inter')))
        ],
      ),
    );
  }

  // --- Кнопки соцсетей в диалоге ---
  Widget _iconBtn(dynamic icon, String name) => IconButton(
        icon: FaIcon(icon as FaIconData?, // Фикс типизации для иконок соцсетей
            color: AppColors.accent,
            size: 24),
        onPressed: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Open $name')));
        },
      );
}
