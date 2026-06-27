import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/config.dart';
import 'features/library/presentation/library_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Config.load();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(const VaporApp());
}

class VaporApp extends StatelessWidget {
  const VaporApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vapor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LibraryScreen(),
    );
  }
}
