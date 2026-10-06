import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bugo_service.dart';
import 'bugo_ui.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => BugoService())],
      child: const BugoApp(),
    ),
  );
}

class BugoApp extends StatelessWidget {
  const BugoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bugo Command Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.greenAccent,
      ),
      home: BugoDashboard(),
    );
  }
}
