import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:family_budget_app/core/theme/app_theme.dart';
import 'package:family_budget_app/core/theme/theme_provider.dart';
import 'package:family_budget_app/presentation/providers/auth_provider.dart';
import 'package:family_budget_app/presentation/providers/language_provider.dart';
import 'package:family_budget_app/presentation/screens/account_profile_screen.dart';
import 'package:family_budget_app/presentation/screens/bank_debts_screen.dart';
import 'package:family_budget_app/presentation/screens/budget_limits_screen.dart';
import 'package:family_budget_app/presentation/screens/dashboard_screen.dart';
import 'package:family_budget_app/presentation/screens/family_management_screen.dart';
import 'package:family_budget_app/presentation/screens/goals_screen.dart';
import 'package:family_budget_app/presentation/screens/market_screen.dart';
import 'package:family_budget_app/presentation/screens/subscriptions_screen.dart';
import 'package:family_budget_app/presentation/screens/transactions_screen.dart';
import 'package:family_budget_app/presentation/widgets/login_wall_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Deep link init error: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri),
      onError: (err) => debugPrint('Deep link error: $err'),
    );
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'familybudget' && uri.host == 'join') {
      final code = uri.queryParameters['code'];
      if (code != null && mounted) {
        _joinFamilyWithCode(code);
      }
    }
  }

  Future<void> _joinFamilyWithCode(String code) async {
    try {
      await ref.read(authProvider.notifier).joinFamily(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aileye başarıyla katıldınız!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  static const List<Widget> _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    GoalsScreen(),
    SubscriptionsScreen(),
  ];

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('theme_selection'.tr(ref)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('night_blue'.tr(ref)),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF1A1A2E),
                  ),
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .changeTheme(AppThemeType.midnightBlue);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('maroon'.tr(ref)),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF6B0F1A),
                  ),
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .changeTheme(AppThemeType.maroon);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('marble_white'.tr(ref)),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF5F5F0),
                  ),
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .changeTheme(AppThemeType.marbleWhite);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('royal_pearl'.tr(ref)),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2C3E6B),
                  ),
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .changeTheme(AppThemeType.royalPearl);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('baroque_moss'.tr(ref)),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2D4A22),
                  ),
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .changeTheme(AppThemeType.baroqueMoss);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('ocean_blue'.tr(ref)),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF006994),
                  ),
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .changeTheme(AppThemeType.oceanBlue);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('emerald_green'.tr(ref)),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF00695C),
                  ),
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .changeTheme(AppThemeType.emeraldGreen);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('language'.tr(ref)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: const Text(
                    'TR',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
                title: const Text('Türkçe', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('tr');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: const Text(
                    'EN',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                title: const Text('English', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('en');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final String appTitle = 'app_title'.tr(ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              if (authState.isGuest) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) => LoginWallBottomSheet(
                    onSuccess: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountProfileScreen(),
                        ),
                      );
                    },
                    initialIsLogin: true,
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountProfileScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          bottom: true,
          top: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                accountName: Text(
                  authState.isGuest
                      ? 'guest_user'.tr(ref)
                      : (authState.userName ?? 'hello'.tr(ref)),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(
                  authState.isGuest ? 'Giriş yaparak tüm cihazlarla senkronize edin' : (authState.userEmail ?? ''),
                  style: TextStyle(
                    fontSize: authState.isGuest ? 12 : 14,
                    color: Colors.white70,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    authState.isGuest ? Icons.person_outline : Icons.person,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
              if (authState.isGuest)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        builder: (context) => LoginWallBottomSheet(
                          onSuccess: () {},
                          initialIsLogin: true,
                        ),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Giriş Yap / Kayıt Ol'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.home),
                title: Text('home'.tr(ref)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance),
                title: Text('bank_debts'.tr(ref)),
                onTap: () {
                  Navigator.pop(context);
                  checkGuestAndProceed(
                    context,
                    ref,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BankDebtsScreen(),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.show_chart),
                title: Text('markets'.tr(ref)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MarketScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: Text('budget_limits'.tr(ref)),
                onTap: () {
                  Navigator.pop(context);
                  checkGuestAndProceed(
                    context,
                    ref,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BudgetLimitsScreen(),
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Text(
                  'family_profile'.tr(ref),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Aileni Yönet'),
                onTap: () {
                  Navigator.pop(context);
                  checkGuestAndProceed(
                    context,
                    ref,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FamilyManagementScreen(),
                      ),
                    ),
                  );
                },
              ),
              if (!authState.isGuest)
                Column(
                  children: [
                    RadioListTile<String>(
                      title: Text('personal_plan'.tr(ref)),
                      value: 'personal',
                      groupValue: authState.activePlan,
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(authProvider.notifier).switchPlan(val);
                        }
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('family_plan'.tr(ref)),
                      value: 'family',
                      groupValue: authState.activePlan,
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(authProvider.notifier).switchPlan(val);
                        }
                      },
                    ),
                  ],
                ),
              const Divider(),
              if (!authState.isGuest)
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    'logout'.tr(ref),
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(authProvider.notifier).logout();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: Text('themes'.tr(ref)),
                onTap: () {
                  Navigator.pop(context);
                  _showThemeSelector();
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text('language'.tr(ref)),
                onTap: () {
                  Navigator.pop(context);
                  _showLanguageSelector();
                },
              ),
            ],
          ),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: 'summary'.tr(ref),
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: 'transactions'.tr(ref),
          ),
          NavigationDestination(
            icon: const Icon(Icons.flag_outlined),
            selectedIcon: const Icon(Icons.flag),
            label: 'goals'.tr(ref),
          ),
          NavigationDestination(
            icon: const Icon(Icons.subscriptions_outlined),
            selectedIcon: const Icon(Icons.subscriptions),
            label: 'subscriptions_title'.tr(ref),
          ),
        ],
      ),
    );
  }
}
