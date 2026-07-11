import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:code_card_ai/core/di/injection_container.dart';
import 'package:code_card_ai/core/routes/app_router.dart';
import 'package:code_card_ai/core/theme/app_theme.dart';
import 'package:code_card_ai/features/auth/presentation/bloc/auth_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<AuthBloc>(create: (context) => sl<AuthBloc>())],
      child: MaterialApp.router(
        title: 'CodeCard AI',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
