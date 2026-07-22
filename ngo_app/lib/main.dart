import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'services/notification_service.dart';
import 'services/background_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );

  if (!kIsWeb) {
    // Initialize local notifications
    await NotificationService.initialize();

    // Initialize WorkManager for background tasks
    await Workmanager().initialize(
      backgroundTaskDispatcher,
      isInDebugMode: false,
    );

    // Register periodic background task (every 12 hours)
    await Workmanager().registerPeriodicTask(
      BackgroundWorker.taskName,
      BackgroundWorker.taskName,
      frequency: const Duration(hours: 12),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  runApp(
    const ProviderScope(
      child: NgoApp(),
    ),
  );
}

/// Root widget for the NGO Management App.
class NgoApp extends ConsumerStatefulWidget {
  const NgoApp({super.key});

  @override
  ConsumerState<NgoApp> createState() => _NgoAppState();
}

class _NgoAppState extends ConsumerState<NgoApp> {
  @override
  void initState() {
    super.initState();
    // Run an initial notification check when the app starts
    _runInitialNotificationCheck();
  }

  Future<void> _runInitialNotificationCheck() async {
    if (kIsWeb) return;
    // Delay slightly so providers are ready
    await Future.delayed(const Duration(seconds: 3));
    ref.read(notificationCheckProvider);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'श्री श्याम सेवा समिति',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // NOTE: Dark theme is intentionally NOT set because screens currently
      // hardcode Colors.white for card backgrounds, making dark mode look broken.
      // Re-enable once all screens use Theme.of(context) colors instead.
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
