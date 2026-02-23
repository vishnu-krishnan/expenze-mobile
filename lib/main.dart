import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/expense_provider.dart';
import 'presentation/providers/category_provider.dart';
import 'presentation/providers/regular_payment_provider.dart';
import 'presentation/screens/auth/app_lock_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/onboarding/landing_page.dart';
import 'presentation/screens/month/month_plan_screen.dart';
import 'presentation/screens/categories/categories_screen.dart';
import 'presentation/screens/regular/regular_payments_screen.dart';
import 'presentation/screens/sms/sms_import_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/navigation/main_navigation_wrapper.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/note_provider.dart';
import 'presentation/screens/notes/notes_screen.dart';
import 'data/services/notification_service.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/settings/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {
      // If .env is missing or not bundled, continue without crashing.
    }

    await NotificationService().init();
    runApp(const MyApp());
  } catch (e, stack) {
    debugPrint("FATAL ERROR DURING APP STARTUP: $e");
    debugPrint(stack.toString());

    // Fallback UI to prevent black screen
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF020617), // Dark slate
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Failed to start Expenze',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme Provider
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(),
        ),
        // Auth Provider
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider()..initialize(),
        ),
        // Expense Provider
        ChangeNotifierProvider<ExpenseProvider>(
          create: (context) => ExpenseProvider()
            ..loadMonthData(DateTime.now().toIso8601String().substring(0, 7)),
        ),
        // Category Provider
        ChangeNotifierProvider<CategoryProvider>(
          create: (context) => CategoryProvider()..loadCategories(),
        ),
        // Note Provider
        ChangeNotifierProvider<NoteProvider>(
          create: (context) => NoteProvider(),
        ),
        // Regular Payment Provider
        ChangeNotifierProvider<RegularPaymentProvider>(
          create: (context) => RegularPaymentProvider()..loadPayments(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Expenze',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const AuthWrapper(),
            routes: {
              '/landing': (context) => const LandingPage(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/lock': (context) => const AppLockScreen(),
              '/main': (context) => const MainNavigationWrapper(),
              '/month': (context) => const MonthPlanScreen(),
              '/categories': (context) => const CategoriesScreen(),
              '/regular': (context) => const RegularPaymentsScreen(),
              '/import': (context) => const SmsImportScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/notes': (context) => const NotesScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/notifications': (context) => const NotificationSettingsScreen(),
              '/analytics': (context) =>
                  const MainNavigationWrapper(initialIndex: 1),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!auth.isOnboarded) {
          return const LandingPage();
        }

        if (auth.isLockEnabled && !auth.isAuthenticated) {
          return const AppLockScreen();
        }

        return const MainNavigationWrapper();
      },
    );
  }
}
