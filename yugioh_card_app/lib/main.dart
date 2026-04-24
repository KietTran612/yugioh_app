import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_shell.dart';

void main() {
  FlutterError.onError = (details) {
    debugPrint('Flutter error: ${details.exceptionAsString()}');
    debugPrint(details.stack.toString());
  };
  runApp(const ProviderScope(child: YugiohApp()));
}

class YugiohApp extends StatelessWidget {
  const YugiohApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yu-Gi-Oh! Cards',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A2E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A2E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}
