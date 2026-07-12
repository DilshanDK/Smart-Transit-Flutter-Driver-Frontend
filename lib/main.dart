import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/ui/auth_wrapper.dart';
import 'features/dashboard/data/repositories/dashboard_repository.dart';
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'features/dashboard/bloc/dashboard_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        child: MaterialApp(
          title: 'Smart Transit Driver',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system, // Auto switches based on system settings
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}

