import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/chains_provider.dart';
import 'screens/home_screen.dart';
import 'services/chain_storage.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChainTimerApp());
}

class ChainTimerApp extends StatelessWidget {
  const ChainTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChainsProvider(ChainStorage())..load(),
      child: MaterialApp(
        title: 'ChainTimer',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
