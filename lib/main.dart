import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_layout.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authProvider = AuthProvider();
  
  // Do not await here, so runApp can render the splash screen immediately.
  authProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: const TradeLinkApp(),
    ),
  );
}

class TradeLinkApp extends StatelessWidget {
  const TradeLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TradeLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: child,
        );
      },
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isBooting) {
            return const SplashScreen();
          }
          return auth.isAuthenticated ? const MainLayout() : const LoginScreen();
        },
      ),
    );
  }
}
