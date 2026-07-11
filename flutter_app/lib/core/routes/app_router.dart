import 'package:go_router/go_router.dart';
import 'package:code_card_ai/core/routes/route_names.dart';
import 'package:code_card_ai/features/auth/presentation/pages/login_page.dart';
import 'package:code_card_ai/features/auth/presentation/pages/register_page.dart';
import 'package:code_card_ai/features/home/presentation/pages/home_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.loginPath,
    routes: [
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.loginName,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.registerPath,
        name: RouteNames.registerName,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.homePath,
        name: RouteNames.homeName,
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
