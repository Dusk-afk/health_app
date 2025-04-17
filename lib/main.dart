import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'services/api/auth_service.dart';
import 'services/api/health_service.dart';
import 'services/providers/vitals_provider.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize health service and start periodic data fetching
  await _initializeHealthService();

  runApp(const WellNestApp());
}

/// Initialize the health service and start periodic data fetching
Future<void> _initializeHealthService() async {
  try {
    // Initialize the health service
    final isInitialized = await HealthService.instance.initialize();

    if (isInitialized) {
      // Start fetching health data every 15 minutes
      HealthService.instance.startPeriodicFetch(interval: const Duration(minutes: 15));
      debugPrint('Health service initialized and periodic fetching started');

      // Initialize vitals provider
      // This will connect to the health service and start tracking vitals
      await VitalsProvider.instance.refreshHealthData();
      debugPrint('Vitals provider initialized and connected to health service');
    } else {
      debugPrint('Failed to initialize health service');
    }
  } catch (e) {
    debugPrint('Error setting up health service: $e');
  }
}

class WellNestApp extends StatefulWidget {
  const WellNestApp({super.key});

  @override
  State<WellNestApp> createState() => _WellNestAppState();
}

class _WellNestAppState extends State<WellNestApp> {
  final Future<bool> _isAuthenticated = AuthService.instance.isAuthenticated();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: VitalsProvider.instance),
      ],
      child: MaterialApp(
        title: 'WellNest',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            primary: Colors.teal,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.teal, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              textStyle: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/main': (context) => const MainScreen(),
        },
        initialRoute: '/',
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    await Future.delayed(const Duration(milliseconds: 1500));

    // Check if user is already logged in
    final bool isAuthenticated = await AuthService.instance.isAuthenticated();

    if (!mounted) return;

    // Navigate to appropriate screen
    Navigator.pushReplacementNamed(
      context,
      isAuthenticated ? '/main' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_rounded,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'WellNest',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
