import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: RaspLabApp()));
}

class RaspLabApp extends StatelessWidget {
  const RaspLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RaspLab',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

