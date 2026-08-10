import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/ui/auth_wrapper.dart';
import 'features/dashboard/data/repositories/dashboard_repository.dart';
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'features/dashboard/bloc/dashboard_event.dart';

import 'dart:io';
import 'core/network/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Check backend connectivity
  try {
    final url = ApiClient.baseUrl;
    debugPrint('📡 Checking backend connectivity at: $url');
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 4);
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    debugPrint('✅ Backend connection successful! Status: ${response.statusCode}');
  } catch (e) {
    debugPrint('❌ Backend connection failed: $e');
  }

  // Load saved theme before showing the app
  final themeCubit = ThemeCubit();
  await themeCubit.load();

  runApp(MyApp(themeCubit: themeCubit));
}

class MyApp extends StatelessWidget {
  final ThemeCubit themeCubit;
  const MyApp({super.key, required this.themeCubit});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(),
        ),
        RepositoryProvider<DashboardRepository>(
          create: (context) => DashboardRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>.value(value: themeCubit),
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: RepositoryProvider.of<AuthRepository>(context),
            )..add(const AppStarted()),
          ),
          BlocProvider<DashboardBloc>(
            create: (context) => DashboardBloc(
              dashboardRepository: RepositoryProvider.of<DashboardRepository>(context),
            )..add(const LoadProfileRequested()),
          ),
        ],
        child: BlocBuilder<ThemeCubit, bool>(
          builder: (context, isDark) {
            return MaterialApp(
              title: 'Smart Transit Driver',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: const AuthWrapper(),
            );
          },
        ),
      ),
    );
  }
}
