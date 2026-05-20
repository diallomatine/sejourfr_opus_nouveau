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
import '../../screens/profile/mes_historiques_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/question_runner/runner_screen.dart';
import '../../screens/review/review_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/stats/stats_screen.dart';
import '../../screens/target_path/target_path_screen.dart';
import '../../screens/tcf_production/ee_briefing_writing_screen.dart';
import '../../screens/tcf_production/ee_results_screen.dart';
import '../../screens/tcf_production/eo_briefing_screen.dart';
import '../../screens/tcf_production/eo_finished_screen.dart';
import '../../screens/tcf_production/eo_recording_screen.dart';
import '../../screens/tcf_production/eo_results_screen.dart';
import '../../screens/tcf_production/history_session_screen.dart';
import '../../screens/tcf_production/production_history_screen.dart';
import '../../screens/tcf_production/session_bilan_screen.dart';
import '../../screens/tcf_production/session_progress_screen.dart';
import '../../screens/training/training_setup_screen.dart';
import '../auth/auth_controller.dart';
import '../models/enums.dart';

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
  static const progress = '/progress';
  static const review = '/review';
  static const profile = '/profile';
  static const onboarding = '/onboarding';
  static const targetPath = '/target-path';
  static const examResult = '/exam-result/:attemptId';
  static const history = '/history';
  static const examReport = '/exam-report/:attemptId';

  // Hub "Mes historiques" depuis le profil : regroupe QCM + EE + EO.
  static const historiques = '/historiques';

  // TCF Expression orale / ecrite (Lot A : briefing seul, soumission a venir).
  static const tcfExpressionOrale = '/tcf/expression-orale';
  static const tcfExpressionEcrite = '/tcf/expression-ecrite';
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);
  late final GoRouter router;

  // Force la navigation vers /login dès qu'un 401 fait passer l'auth en
  // Unauthenticated (forceLogout) ou qu'un logout explicite est déclenché.
  // Le redirect du router gérerait déjà le cas pour la route active, mais
  // appeler `go` explicitement garantit qu'on vide la back-stack des
  // routes pushées (runner, target-path, etc.).
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    if (previous is AuthAuthenticated && next is AuthUnauthenticated) {
      router.go(AppRoutes.login);
    }
  });

  router = GoRouter(
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
      final isOnTargetPath = loc == AppRoutes.targetPath;
      final isOnSplash = loc == AppRoutes.splash;

      // Si user connecté : pas d'auth flow, pas d'onboarding, pas de splash.
      if (isAuth) {
        final user = auth.user;

        // Onboarding parcours obligatoire (sauf pour les comptes ADMIN).
        if (!user.hasCompletedOnboarding && !isOnTargetPath) {
          return AppRoutes.targetPath;
        }

        if (isOnAuthFlow || isOnOnboarding || isOnSplash) {
          return AppRoutes.home;
        }
        return null;
      }

      // User non connecté : on regarde si l'onboarding a déjà été vu.
      // Lecture synchrone : la valeur est préchargée depuis les prefs au boot
      // (main.dart) donc disponible dès le premier frame.
      final onboardingSeen = ref.read(onboardingSeenProvider);

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
        path: AppRoutes.targetPath,
        builder: (_, __) => const TargetPathScreen(),
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
        path: AppRoutes.historiques,
        builder: (_, __) => const MesHistoriquesScreen(),
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
            path: AppRoutes.progress,
            builder: (_, __) => const StatsScreen(),
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

      // TCF Expression orale (Lot E : entry = historique des sessions passees)
      //   /tcf/expression-orale                          -> historique
      //   /tcf/expression-orale/sessions/:attemptId      -> bilan d'une session passee (lecture seule)
      //   /tcf/expression-orale/nouvelle                 -> briefing T1 (nouvelle session)
      //   /tcf/expression-orale/t/:idx                   -> briefing T(idx+1)
      //   /tcf/expression-orale/t/:idx/enregistrement    -> capture audio
      //   /tcf/expression-orale/t/:idx/termine           -> ecoute + soumission
      //   /tcf/expression-orale/resultats/:id?taskIndex=N&history=1  -> resultats (live ou history)
      //   /tcf/expression-orale/progression              -> entre les taches (live)
      //   /tcf/expression-orale/bilan                    -> bilan session live
      GoRoute(
        path: AppRoutes.tcfExpressionOrale,
        builder: (_, __) =>
            const ProductionHistoryScreen(epreuve: EpreuveType.tcfEo),
        routes: [
          GoRoute(
            path: 'nouvelle',
            builder: (_, __) => const EoBriefingScreen(taskIndex: 0),
          ),
          GoRoute(
            path: 'sessions/:attemptId',
            builder: (_, state) => HistorySessionScreen(
              epreuve: EpreuveType.tcfEo,
              attemptId: state.pathParameters['attemptId']!,
            ),
          ),
          GoRoute(
            path: 't/:taskIndex',
            builder: (_, state) {
              final idx = int.tryParse(state.pathParameters['taskIndex'] ?? '0') ?? 0;
              return EoBriefingScreen(taskIndex: idx);
            },
            routes: [
              GoRoute(
                path: 'enregistrement',
                builder: (_, state) {
                  final idx = int.tryParse(state.pathParameters['taskIndex'] ?? '0') ?? 0;
                  return EoRecordingScreen(taskIndex: idx);
                },
              ),
              GoRoute(
                path: 'termine',
                builder: (_, state) {
                  final idx = int.tryParse(state.pathParameters['taskIndex'] ?? '0') ?? 0;
                  return EoFinishedScreen(taskIndex: idx);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'resultats/:submissionId',
            builder: (_, state) {
              final id = state.pathParameters['submissionId']!;
              final idx = int.tryParse(state.uri.queryParameters['taskIndex'] ?? '0') ?? 0;
              final history = state.uri.queryParameters['history'] == '1';
              return EoResultsScreen(
                submissionId: id,
                taskIndex: idx,
                isHistory: history,
              );
            },
          ),
          GoRoute(
            path: 'progression',
            builder: (_, __) =>
                const SessionProgressScreen(epreuve: EpreuveType.tcfEo),
          ),
          GoRoute(
            path: 'bilan',
            builder: (_, __) =>
                const SessionBilanScreen(epreuve: EpreuveType.tcfEo),
          ),
        ],
      ),

      // TCF Expression ecrite (Lot E : entry = historique des sessions passees)
      //   /tcf/expression-ecrite                          -> historique
      //   /tcf/expression-ecrite/sessions/:attemptId      -> bilan d'une session passee (lecture seule)
      //   /tcf/expression-ecrite/nouvelle                 -> briefing+writing T1 (nouvelle session)
      //   /tcf/expression-ecrite/t/:idx                   -> briefing+writing pour cette tache
      //   /tcf/expression-ecrite/resultats/:id?taskIndex=N&history=1 -> resultats (live ou history)
      //   /tcf/expression-ecrite/progression              -> entre taches (live)
      //   /tcf/expression-ecrite/bilan                    -> bilan session live
      GoRoute(
        path: AppRoutes.tcfExpressionEcrite,
        builder: (_, __) =>
            const ProductionHistoryScreen(epreuve: EpreuveType.tcfEe),
        routes: [
          GoRoute(
            path: 'nouvelle',
            builder: (_, __) => const EeBriefingWritingScreen(taskIndex: 0),
          ),
          GoRoute(
            path: 'sessions/:attemptId',
            builder: (_, state) => HistorySessionScreen(
              epreuve: EpreuveType.tcfEe,
              attemptId: state.pathParameters['attemptId']!,
            ),
          ),
          GoRoute(
            path: 't/:taskIndex',
            builder: (_, state) {
              final idx = int.tryParse(state.pathParameters['taskIndex'] ?? '0') ?? 0;
              return EeBriefingWritingScreen(taskIndex: idx);
            },
          ),
          GoRoute(
            path: 'resultats/:submissionId',
            builder: (_, state) {
              final id = state.pathParameters['submissionId']!;
              final idx = int.tryParse(state.uri.queryParameters['taskIndex'] ?? '0') ?? 0;
              final history = state.uri.queryParameters['history'] == '1';
              return EeResultsScreen(
                submissionId: id,
                taskIndex: idx,
                isHistory: history,
              );
            },
          ),
          GoRoute(
            path: 'progression',
            builder: (_, __) =>
                const SessionProgressScreen(epreuve: EpreuveType.tcfEe),
          ),
          GoRoute(
            path: 'bilan',
            builder: (_, __) =>
                const SessionBilanScreen(epreuve: EpreuveType.tcfEe),
          ),
        ],
      ),
    ],
  );
  return router;
});

/// Pont entre Riverpod et go_router : on rafraîchit le router à chaque
/// changement d'AuthState pour appliquer les redirections.
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _authSub = _ref.listen<AuthState>(
      authControllerProvider,
      (_, __) => notifyListeners(),
    );
    _onboardingSub = _ref.listen<bool>(
      onboardingSeenProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _authSub;
  late final ProviderSubscription<bool> _onboardingSub;

  @override
  void dispose() {
    _authSub.close();
    _onboardingSub.close();
    super.dispose();
  }
}
