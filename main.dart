import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_master/firebase_options.dart';
import 'package:todo_master/providers/template_provider.dart';
import 'package:todo_master/providers/theme_provider.dart';
import 'package:todo_master/providers/todo_provider.dart';
import 'package:todo_master/screens/auth_wrapper.dart';
import 'package:todo_master/screens/signup_debug_screen.dart';
import 'package:todo_master/screens/theme_debug_screen.dart';
import 'package:todo_master/services/auth_service.dart';
import 'package:todo_master/services/firestore_service.dart';
import 'package:todo_master/services/notification_service.dart';
import 'package:todo_master/theme/app_theme.dart';
import 'package:flutter/services.dart';

// Set this to choose which screen to display
// Options: 'app', 'login_debug', 'signup_debug'
const String _debugMode = 'app';

// Set to true to enable authentication
const bool useAuthentication = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for faster startup
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase in parallel with other operations
  final firebaseInitFuture = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notification service
  final notificationInitFuture = NotificationService.instance.initialize();

  // Wait for both to complete
  await Future.wait([firebaseInitFuture, notificationInitFuture]);

  // Improve performance by enabling deferred loading
  // This allows the UI to be shown faster while more complex operations
  // can happen after the initial frame is rendered
  runApp(const MyAppLoader());
}

class MyAppLoader extends StatelessWidget {
  const MyAppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    // Choose which app to run based on debug mode
    switch (_debugMode) {
      case 'login_debug':
        return const ThemeDebugScreen();
      case 'signup_debug':
        return const SignupDebugScreen();
      case 'app':
      default:
        return const MyApp();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a singleton instance of FirestoreService to share
    final firestoreService = FirestoreService();

    // Optimize provider initialization to avoid unnecessary rebuilds
    return MultiProvider(
      providers: [
        // Initialize auth service first to be available for other services
        ChangeNotifierProvider(create: (_) => AuthService()),

        // Add FirestoreService as a Provider, not a ChangeNotifier
        Provider.value(value: firestoreService),

        // Move ThemeProvider to lazy initialization
        ChangeNotifierProvider(create: (_) => ThemeProvider(), lazy: true),

        // Initialize TodoProvider only after auth and firestore are ready
        ChangeNotifierProxyProvider<AuthService, TodoProvider>(
          create: (_) => TodoProvider(),
          update: (_, auth, previousTodoProvider) {
            return previousTodoProvider ?? TodoProvider();
          },
        ),

        // Add the template provider
        ChangeNotifierProvider(create: (_) => TemplateProvider(), lazy: true),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Todo Master',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,

            // Optimize the initial route rendering
            home: useAuthentication ? const AuthWrapper() : const AuthWrapper(),
          );
        },
      ),
    );
  }
}
