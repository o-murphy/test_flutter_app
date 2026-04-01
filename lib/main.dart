import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/shared/helpers/is_desktop.dart';
import 'package:window_manager/window_manager.dart';

import 'core/providers/settings_provider.dart';
import 'router.dart';

// Constants for window sizes
const _windowMinWidth = 320.0;
const _windowMinHeight = 600.0;
const _windowMaxWidth = 1000.0;
const _windowMaxHeight = 1080.0;
const _windowInitialWidth = 375.0;
const _windowInitialHeight = 812.0;

// Constants for content restrictions
const _contentMaxWidth = _windowMaxWidth;
const _contentMaxHeight = _windowMaxHeight;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(_windowInitialWidth, _windowInitialHeight),
      minimumSize: Size(_windowMinWidth, _windowMinHeight),
      maximumSize: Size(_windowMaxWidth, _windowMaxHeight),
      center: true,
      title: 'eBalistyka',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();

      await windowManager.setMinimumSize(
        const Size(_windowMinWidth, _windowMinHeight),
      );
      await windowManager.setMaximumSize(
        const Size(_windowMaxWidth, _windowMaxHeight),
      );
      await windowManager.setMaximizable(false);
    });
  }

  runApp(const ProviderScope(child: MyApp()));
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  static final _lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ),
  );

  static final _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      routerConfig: appRouter,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
      scrollBehavior: _AppScrollBehavior(),
      builder: (context, child) {
        if (isDesktop) {
          return Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: _contentMaxWidth,
                maxHeight: _contentMaxHeight,
              ),
              child: child,
            ),
          );
        }
        return child!;
      },
    );
  }
}
