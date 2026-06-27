import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/config.dart';
import 'core/di/injection_container.dart' as di;
import 'features/library/presentation/cubit/game_launch/game_launch_cubit.dart';
import 'features/library/presentation/cubit/game_log/game_log_cubit.dart';
import 'features/library/presentation/cubit/library/library_cubit.dart';
import 'features/library/presentation/library_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Config.load();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await di.configureDependencies();
  runApp(const VaporApp());
}

class VaporApp extends StatelessWidget {
  const VaporApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.getIt<LibraryCubit>()..load()),
        BlocProvider.value(value: di.getIt<GameLogCubit>()),
        BlocProvider.value(value: di.getIt<GameLaunchCubit>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Vapor',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const LibraryScreen(),
      ),
    );
  }
}
