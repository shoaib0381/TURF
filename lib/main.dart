import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/core/theme/app_theme.dart';
import 'package:turf/core/router/app_router.dart';
import 'package:turf/core/services/background_tracking_service.dart' as turf_bg;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://lcrfzwxkrkiuvfhkgfju.supabase.co',
    anonKey: 'sb_publishable_hLE459WDGvetlxZvwMhyGQ_OkwjBtGm',
  );

  await turf_bg.BackgroundTrackingService.initialize();
  
  runApp(
    const ProviderScope(
      child: TurfApp(),
    ),
  );
}

class TurfApp extends StatelessWidget {
  const TurfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TURF',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}