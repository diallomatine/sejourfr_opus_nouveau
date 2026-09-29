import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/router/app_router.dart';
import 'package:sejourfr_mobile/screens/shell/main_shell.dart';

void main() {
  // ⚠️ Ce test gelait « le QUATRIÈME onglet ouvre Plan ». Le rang n'est pas le
  // contrat — le propriétaire a réordonné la barre le 2026-09-12 (Plan en 2ᵉ).
  // Ce qui doit tenir : le Plan a son onglet, il pointe sur le plan serveur, et
  // les écrans de progression n'y sont pas (ils s'ouvrent depuis le Profil et
  // l'Accueil — l'ancien écran Progrès `/progress` est supprimé le 2026-09-24).
  test('le Plan a son onglet et la progression reste secondaire', () {
    expect(mainShellDestinations, hasLength(5));
    final plan = mainShellDestinations
        .singleWhere((destination) => destination.label == 'Plan');
    expect(plan.route, AppRoutes.plan);
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
