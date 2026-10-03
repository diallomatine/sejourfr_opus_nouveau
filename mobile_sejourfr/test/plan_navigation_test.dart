import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/router/app_router.dart';
import 'package:sejourfr_mobile/core/router/shell_navigation.dart';
import 'package:sejourfr_mobile/screens/shell/main_shell.dart';

void main() {
  // ⚠️ Navigation v2 (2026-10-03) : la barre passe à 4 onglets — Accueil ·
  // TCF · Civique · Profil. Le Plan n'a plus d'onglet à lui : c'est le
  // segment par défaut de chaque onglet de module. Ce qui doit tenir : les
  // onglets de module ouvrent leur segment Plan, et les écrans de progression
  // ne sont pas des onglets (on les ouvre depuis la carte « Ma progression »).
  test('les onglets de module ouvrent leur Plan, la progression reste secondaire',
      () {
    expect(mainShellDestinations, hasLength(4));
    final tcf = mainShellDestinations
        .singleWhere((destination) => destination.branche == ShellBranch.tcf);
    expect(tcf.route, AppRoutes.tcfPlan);
    final civique = mainShellDestinations
        .singleWhere((destination) => destination.branche == ShellBranch.civique);
    expect(civique.route, AppRoutes.civiquePlan);
    expect(
      mainShellDestinations.map((destination) => destination.route),
      isNot(contains(AppRoutes.progressionTcf)),
    );
    expect(AppRoutes.progressionTcf, '/progression/tcf');
  });

  group('destination après connexion', () {
    test('conserve un lien profond interne vers diagnostic ou plan', () {
      expect(
        safePostLoginDestination('/diagnostic?source=direct'),
        '/diagnostic?source=direct',
      );
      expect(safePostLoginDestination('/plan'), AppRoutes.plan);
      expect(
        loginLocationFor('/diagnostic'),
        '/login?redirect=%2Fdiagnostic',
      );
      expect(
        authFlowLocation(AppRoutes.register, '/diagnostic'),
        '/register?redirect=%2Fdiagnostic',
      );
      expect(
        authFlowLocation(AppRoutes.login, '/plan'),
        '/login?redirect=%2Fplan',
      );
    });

    test('AuthLoading → Authenticated restitue le lien froid une seule fois',
        () {
      final pending = PendingAuthDestination();

      pending.remember('/diagnostic');
      expect(pending.value, AppRoutes.diagnostic);
      expect(pending.take(), AppRoutes.diagnostic);
      expect(pending.take(), isNull);
    });

    test('AuthLoading → Unauthenticated transmet le lien froid au login', () {
      final pending = PendingAuthDestination();

      pending.remember('/plan');
      expect(
        loginLocationFor(pending.take()!),
        '/login?redirect=%2Fplan',
      );
    });

    test('onboarding de parcours authentifié conserve aussi le lien froid', () {
      final pending = PendingAuthDestination();

      pending.remember('/plan');
      expect(targetPathLocation(pending.take()), '/target-path?from=%2Fplan');
    });

    test('refuse les redirections externes et les boucles d’authentification',
        () {
      expect(safePostLoginDestination('https://evil.example/plan'), isNull);
      expect(safePostLoginDestination('//evil.example/plan'), isNull);
      expect(safePostLoginDestination('/login'), isNull);
      expect(safePostLoginDestination('/target-path?from=%2Fplan'), isNull);
      expect(safePostLoginDestination('plan'), isNull);
      expect(
        authFlowLocation(AppRoutes.register, 'https://evil.example/plan'),
        AppRoutes.register,
      );
    });
  });
}
