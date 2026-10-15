import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import '../core/constants/app_constants.dart';

/// Root application widget.
///
/// Wraps the app in [ProviderScope] (Riverpod) and configures
/// [MaterialApp.router] with the Campus Signal theme and GoRouter.
class FindersKeepersApp extends ConsumerWidget {
  const FindersKeepersApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      routerConfig: appRouter,
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      // Accessibility — ensure text doesn't overflow on large font sizes
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Clamp text scale to prevent layout overflow at extreme sizes
            textScaler: MediaQuery.of(context).textScaler.clamp(
                  minScaleFactor: 0.85,
                  maxScaleFactor: 1.3,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
