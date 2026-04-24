import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/notifications.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/account_provider.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/recurring_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';

/// FCM background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  // Firebase shows the notification automatically for background/terminated state.
  // Nothing extra needed here.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();

  // Handle FCM messages when app is in the foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final n = message.notification;
    if (n != null) {
      NotificationService.showImmediate(
        id: message.messageId ?? message.hashCode.toString(),
        title: n.title ?? '',
        body: n.body,
      );
    }
  });

  // Register the background handler
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

  // Ask Android to exempt this app from battery optimization
  // so FCM messages arrive even when the app is killed.
  _requestBatteryExemption();

  runApp(const BuxBuxApp());
}

Future<void> _requestBatteryExemption() async {
  const ch = MethodChannel('com.fintrack/battery');
  try {
    final exempt = await ch.invokeMethod<bool>('isIgnoringBatteryOptimization') ?? false;
    if (!exempt) await ch.invokeMethod('requestIgnoreBatteryOptimization');
  } catch (_) {}
}

/// Slide-from-right transition used app-wide.
Route<T> slideRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 280),
    );

/// Fade transition for modal-style screens.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 220),
    );

class BuxBuxApp extends StatelessWidget {
  const BuxBuxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => RecurringProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ThemeProvider>().initialize();
      if (mounted) context.read<AuthProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'BuxBux',
      debugShowCheckedModeBanner: false,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: themeProvider.themeMode,
      home: !auth.initialized
          ? const _SplashScreen()
          : auth.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':    return slideRoute(const LoginScreen());
          case '/register': return slideRoute(const RegisterScreen());
          case '/home':     return fadeRoute(const HomeScreen());
          default:          return null;
        }
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset('assets/logo.png', width: 80, height: 80, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            Text(
              'BuxBux',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: kPrimaryColor,
                  ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
