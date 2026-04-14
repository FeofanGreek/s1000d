import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'styles.dart';
import 'router.dart';
import 'controllers/app_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Gazprom MI Render',
      theme: buildQRHTheme(),
      routerConfig: appRouter,
    );
  }
}
