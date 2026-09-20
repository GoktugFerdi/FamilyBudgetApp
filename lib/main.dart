import 'package:family_budget_app/core/theme/app_theme.dart';
import 'package:family_budget_app/core/theme/theme_provider.dart';
import 'package:family_budget_app/presentation/screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialize error: $e");
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: FamilyBudgetApp()));
}

class FamilyBudgetApp extends ConsumerWidget {
  final Widget home;

  const FamilyBudgetApp({super.key, this.home = const HomeScreen()});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Aile Bütçesi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(themeType),
      home: home,
    );
  }
}
