import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sejourfr_mobile/screens/exam/exam_report_screen.dart';
import 'package:sejourfr_mobile/screens/exam/exam_result_screen.dart';
import 'package:sejourfr_mobile/screens/history/history_screen.dart';

import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/exam/exam_setup_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/question_runner/runner_screen.dart';
import '../../screens/review/review_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/training/training_setup_screen.dart';
import '../auth/auth_controller.dart';

/// Routes nommées centralisées (utilisées par les écrans).
class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/';
  static const trainingSetup = '/training';
  static const examSetup = '/exam';
  static const runner = '/runner/:attemptId';
  static const review = '/review';
  static const profile = '/profile';
  static const onboarding = '/onboarding';
  static const examResult = '/exam-result/:attemptId';
  static const history = '/history';
  static const examReport = '/exam-report/:attemptId';
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      // Pendant le boot, on reste sur le splash le temps d'avoir un verdict.
      if (auth is AuthLoading) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isAuth = auth is AuthAuthenticated;
      final isOnAuthFlow =
          loc == AppRoutes.login || loc == AppRoutes.register || loc == AppRoutes.forgotPassword;
      final isOnOnboarding = loc == AppRoutes.onboarding;
      final isOnSplash = loc == AppRoutes.splash;

      // Si user connecté : pas d'auth flow, pas d'onboarding, pas de splash.
      if (isAuth) {
        if (isOnAuthFlow || isOnOnboarding || isOnSplash) {
          return AppRoutes.home;
        }
        return null;
      }

      // User non connecté : on regarde si l'onboarding a déjà été vu.
      final onboardingSeen = ref.read(onboardingSeenProvider).valueOrNull ?? false;

      if (!onboardingSeen && !isOnOnboarding) {
        return AppRoutes.onboarding;
      }

      if (onboardingSeen && !isOnAuthFlow && !isOnOnboarding) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.examResult,
        builder: (_, state) {
          final attemptId = state.pathParameters['attemptId']!;
          return ExamResultScreen(attemptId: attemptId);
        },
      ),

      // Historique des examens (accessible depuis le profil)
      GoRoute(
        path: AppRoutes.history,
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.examReport,
        builder: (_, state) {
          final attemptId = state.pathParameters['attemptId']!;
          return ExamReportScreen(attemptId: attemptId);
        },
      ),

      // Shell avec bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.trainingSetup,
            builder: (_, __) => const TrainingSetupScreen(),
          ),
          GoRoute(
            path: AppRoutes.examSetup,
            builder: (_, __) => const ExamSetupScreen(),
          ),
          GoRoute(
            path: AppRoutes.review,
            builder: (_, __) => const ReviewScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // Runner hors shell (plein écran)
      GoRoute(
        path: AppRoutes.runner,
        builder: (_, state) {
          final attemptId = state.pathParameters['attemptId']!;
          return RunnerScreen(attemptId: attemptId);
        },
      ),
    ],
  );
});

/// Pont entre Riverpod et go_router : on rafraîchit le router à chaque
/// changement d'AuthState pour appliquer les redirections.
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _sub = _ref.listen<AuthState>(
      authControllerProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
