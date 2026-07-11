import 'package:go_router/go_router.dart';
import 'package:code_card_ai/core/routes/route_names.dart';
import 'package:code_card_ai/features/home/presentation/pages/home_page.dart';
import 'package:code_card_ai/features/splash/presentation/pages/splash_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splashPath,
    routes: [
      GoRoute(
        path: RouteNames.splashPath,
        name: RouteNames.splashName,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.homePath,
        name: RouteNames.homeName,
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
