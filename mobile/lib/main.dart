import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api.dart';
import 'core/l10n.dart';
import 'core/storage.dart';
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
import 'providers/quick_add_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/set_password_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/home_screen.dart';
import 'screens/transactions/add_transaction_screen.dart';
import 'screens/transactions/quick_add_screen.dart';
import 'screens/transactions/transfer_screen.dart';

/// FCM background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  // Firebase shows the notification automatically
}

/// HomeWidget background callback — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _homeWidgetBackgroundHandler(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (uri == null) return;
  debugPrint('BuxBux Background URI: $uri');
  
  if (uri.scheme == 'buxbux' && uri.host == 'quickadd') {
    final type = uri.queryParameters['type'] ?? 'expense';
    final amountStr = uri.queryParameters['amount'] ?? '0';
    final amount = double.tryParse(amountStr) ?? 0;
    
    final customAccountId = uri.queryParameters['accountId'];
    final customCategoryId = uri.queryParameters['categoryId'];
    final customNote = uri.queryParameters['note'];
    
    try {
      await NotificationService.initialize(fromBackground: true);
      
      final lang = await Storage.getLanguage();
      final l10n = AppL10n.fromLang(lang);
      
      final token = await Storage.getToken();
      if (token == null) {
        debugPrint('Background Log Error: No token found');
        await NotificationService.showImmediate(
          id: 'error_auth',
          title: l10n.authRequired,
          body: l10n.authRequiredMsg,
        );
        return;
      }
      
      final dio = Dio(BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ));
      
      String? accountId = customAccountId;
      String? categoryId = customCategoryId;

      // If custom IDs are missing, fetch defaults
      if ((accountId == null || accountId.isEmpty) || (categoryId == null || categoryId.isEmpty)) {
        debugPrint('Background Log: Fetching accounts/categories for defaults...');
        final responses = await Future.wait([
          dio.get('/accounts'),
          dio.get('/categories'),
        ]);
        
        final accounts = responses[0].data as List;
        final categories = responses[1].data as List;
        
        if (accounts.isNotEmpty && (accountId == null || accountId.isEmpty)) {
          accountId = accounts.first['id'] ?? accounts.first['_id'];
        }
        
        if (categories.isNotEmpty && (categoryId == null || categoryId.isEmpty)) {
          final filteredCats = categories.where((c) => c['type'] == type).toList();
          final targetCat = filteredCats.isNotEmpty ? filteredCats.first : categories.first;
          categoryId = targetCat['id'] ?? targetCat['_id'];
        }
      }
      
      if (accountId == null || categoryId == null) {
        throw Exception('Account or Category not found.');
      }

      // 2. Log the transaction
      debugPrint('Background Log: Posting transaction...');
      await dio.post('/transactions', 
        data: {
          'type': type,
          'amount': amount,
          'accountId': accountId,
          'categoryId': categoryId,
          'date': DateTime.now().toIso8601String(),
          'note': (customNote != null && customNote.isNotEmpty) ? customNote : 'Quick Add from Widget',
        }
      );

      // 3. Show success notification
      debugPrint('Background Log: Success!');
      final typeLabel = type == 'income' ? l10n.income : l10n.expense;
      await NotificationService.showImmediate(
        id: DateTime.now().hashCode.toString(),
        title: l10n.transactionLogged,
        body: l10n.transactionAddedBody(typeLabel, amountStr),
      );

      // 4. Update the widget balance
      final accRes = await dio.get('/accounts');
      final accList = accRes.data as List;
      final firstCurrency = accList.isNotEmpty ? (accList.first['currency'] ?? 'IDR') : 'IDR';
      final totalBal = accList.fold<double>(0, (s, a) => s + ((a['balance'] as num?)?.toDouble() ?? 0));
      await HomeWidget.saveWidgetData('balance', '$firstCurrency ${totalBal.toStringAsFixed(0)}');
      await HomeWidget.updateWidget(name: 'BuxBuxWidgetProvider');
    } catch (e) {
      debugPrint('Background Log Error: $e');
      String msg = e.toString().replaceFirst('Exception: ', '');
      if (e is DioException) {
        msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      }
      
      await NotificationService.showImmediate(
        id: 'error_log',
        title: 'Quick Add Failed',
        body: msg,
      );
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  HomeWidget.registerBackgroundCallback(_homeWidgetBackgroundHandler);

  final auth = AuthProvider();
  final theme = ThemeProvider();
  final reminder = ReminderProvider();
  final quickAdd = QuickAddProvider();
    
  await Future.wait([
    auth.initialize(),
    theme.initialize(),
    quickAdd.initialize(),
  ]);

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: theme),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => RecurringProvider()),
        ChangeNotifierProvider.value(value: reminder),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider.value(value: quickAdd),
      ],
      child: const BuxBuxApp(),
    ),
  );
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
    return const _AppRoot();
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
      locale: _localeFromLang(themeProvider.language),
      supportedLocales: const [Locale('en'), Locale('id'), Locale('zh')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: !auth.initialized
          ? const _SplashScreen()
            : auth.isAuthenticated
                ? (!auth.user!.hasPassword)
                    ? const SetPasswordScreen()
                    : (!auth.user!.emailVerified)
                        ? const VerifyEmailScreen()
                        : const _DeepLinkHandler(child: HomeScreen())
                : const LoginScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':    return slideRoute(const LoginScreen());
          case '/register': return slideRoute(const RegisterScreen());
          case '/forgot_password': return slideRoute(const ForgotPasswordScreen());
          case '/set_password': return fadeRoute(const SetPasswordScreen());
          case '/verify_email': return fadeRoute(const VerifyEmailScreen());
          case '/home':     return fadeRoute(const HomeScreen());
          case '/add_transaction':
            final type = settings.arguments as String?;
            return slideRoute(AddTransactionScreen(initialType: type));
// Updated quick add route handling with additional parameters
          case '/quick_add':
            final qArgs = settings.arguments;
            String qType = 'expense';
            String? qAmount;
            String? qAccountId;
            String? qCategoryId;
            String? qNote;
            if (qArgs is String) {
              qType = qArgs;
            } else if (qArgs is Map) {
              qType = qArgs['type'] as String? ?? 'expense';
              qAmount = qArgs['amount'] as String?;
              qAccountId = qArgs['accountId'] as String?;
              qCategoryId = qArgs['categoryId'] as String?;
              qNote = qArgs['note'] as String?;
            }
            return fadeRoute(QuickAddScreen(
              type: qType,
              prefilledAmount: qAmount,
              accountId: qAccountId,
              categoryId: qCategoryId,
              note: qNote,
            ));
          case '/transfer':
            return slideRoute(const TransferScreen());
          default:          return null;
        }
      },
    );
  }
}

/// A wrapper that listens for deep links/widget clicks and navigates accordingly.
class _DeepLinkHandler extends StatefulWidget {
  final Widget child;
  const _DeepLinkHandler({required this.child});

  @override
  State<_DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<_DeepLinkHandler> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinkHandling();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinkHandling() async {
    // 1. Handle initial launch URI
    final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (initialUri != null) _handleUri(initialUri);

    // 2. Listen for subsequent clicks while app is running
    _sub = HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    debugPrint('BuxBux Foreground URI received: $uri');
    if (uri.scheme == 'buxbux' && (uri.host == 'add' || uri.host == 'quickadd')) {
      final type = uri.queryParameters['type'] ?? 'expense';
      final amount = uri.queryParameters['amount'];
      
      String? accountId = uri.queryParameters['accountId'];
      if (accountId != null && accountId.isEmpty) accountId = null;
      
      String? categoryId = uri.queryParameters['categoryId'];
      if (categoryId != null && categoryId.isEmpty) categoryId = null;
      
      String? note = uri.queryParameters['note'];
      if (note != null && note.isEmpty) note = null;
      
      debugPrint('Routing to /quick_add with type=$type, amount=$amount, account=$accountId');
      Navigator.pushNamed(context, '/quick_add', arguments: {
        'type': type,
        'amount': amount,
        'accountId': accountId,
        'categoryId': categoryId,
        'note': note,
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Locale _localeFromLang(String lang) {
  switch (lang) {
    case 'id': return const Locale('id', 'ID');
    case 'zh': return const Locale('zh', 'CN');
    default:   return const Locale('en', 'US');
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
