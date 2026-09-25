import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sejourfr_mobile/core/api/profile_repository.dart';
import 'package:sejourfr_mobile/core/api/repositories.dart';
import 'package:sejourfr_mobile/core/models/email_preferences.dart';
import 'package:sejourfr_mobile/screens/profile/account_labels.dart';
import 'package:sejourfr_mobile/screens/profile/notifications_screen.dart';

/// « Notifications par e-mail » : chargement, bascule optimiste, succès, échec
/// et retour arrière. Test ajouté À LA DEMANDE EXPLICITE du propriétaire (revue
/// du chantier e-mails, 2026-09-25) — exception à « aucun nouveau test front »
/// limitée à cet écran. Miroir web : `web_sejoufr/lib/notifications.test.ts`.

const _actif = EmailPreferences(engagementEnabled: true, marketingEnabled: false);

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({this.initial = _actif, this.failUpdate = false});

  final EmailPreferences initial;
  final bool failUpdate;
  final List<bool?> updates = [];

  /// Posé, il retient la réponse du PATCH pour observer l'état optimiste.
  Completer<void>? gate;

  @override
  Future<EmailPreferences> getEmailPreferences() async => initial;

  @override
  Future<EmailPreferences> updateEmailPreferences({
    bool? engagementEnabled,
    bool? marketingEnabled,
  }) async {
    updates.add(engagementEnabled);
    await gate?.future;
    if (failUpdate) throw Exception('500');
    return initial.copyWith(engagementEnabled: engagementEnabled);
  }

  @override
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> requestEmailChange({
    required String newEmail,
    required String currentPassword,
  }) =>
      throw UnimplementedError();
}

ProviderContainer _container(_FakeProfileRepository repo) {
  final container = ProviderContainer(
    overrides: [profileRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  // autoDispose : on garde le provider vivant pendant tout le test.
  container.listen(emailPreferencesProvider, (_, __) {});
  return container;
}

Future<void> _pumpScreen(WidgetTester tester, _FakeProfileRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: NotificationsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

bool _switchValue(WidgetTester tester) =>
    tester.widget<Switch>(find.byType(Switch)).value;

void main() {
  group('EmailPreferencesNotifier', () {
    test('charge les préférences servies', () async {
      final container = _container(_FakeProfileRepository(
        initial: const EmailPreferences(
          engagementEnabled: false,
          marketingEnabled: false,
        ),
      ));

      final prefs = await container.read(emailPreferencesProvider.future);
      expect(prefs.engagementEnabled, isFalse);
    });

    for (final next in [false, true]) {
      test('bascule vers $next de façon optimiste, puis garde le résultat',
          () async {
        final repo = _FakeProfileRepository(
          initial: _actif.copyWith(engagementEnabled: !next),
        )..gate = Completer<void>();
        final container = _container(repo);
        await container.read(emailPreferencesProvider.future);

        final pending = container
            .read(emailPreferencesProvider.notifier)
            .setEngagement(next);
        expect(
          container.read(emailPreferencesProvider).value?.engagementEnabled,
          next,
          reason: 'l\'état bascule avant la réponse du serveur',
        );

        repo.gate!.complete();
        await pending;
        expect(repo.updates, [next]);
        expect(
          container.read(emailPreferencesProvider).value?.engagementEnabled,
          next,
        );
      });

      test('rétablit ${!next} et relance l\'erreur si l\'envoi échoue',
          () async {
        final repo = _FakeProfileRepository(
          initial: _actif.copyWith(engagementEnabled: !next),
          failUpdate: true,
        )..gate = Completer<void>();
        final container = _container(repo);
        await container.read(emailPreferencesProvider.future);

        final pending = container
            .read(emailPreferencesProvider.notifier)
            .setEngagement(next);
        expect(
          container.read(emailPreferencesProvider).value?.engagementEnabled,
          next,
        );

        repo.gate!.complete();
        await expectLater(pending, throwsA(isA<Exception>()));
        expect(
          container.read(emailPreferencesProvider).value?.engagementEnabled,
          !next,
        );
      });
    }
  });

  group('NotificationsScreen', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

    testWidgets('succès : l\'interrupteur bascule et la confirmation s\'affiche',
        (tester) async {
      final repo = _FakeProfileRepository();
      await _pumpScreen(tester, repo);

      expect(find.text(kCompteNotifEngagementLabel), findsOneWidget);
      expect(_switchValue(tester), isTrue);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump();

      expect(repo.updates, [false]);
      expect(_switchValue(tester), isFalse);
      expect(find.text(kCompteNotifSaved), findsOneWidget);
      expect(find.text(kCompteNotifSaveFailed), findsNothing);

      // L'alerte verte est brève : elle disparaît après 3 s.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text(kCompteNotifSaved), findsNothing);
    });

    testWidgets('échec : l\'interrupteur revient et l\'erreur s\'affiche',
        (tester) async {
      final repo = _FakeProfileRepository(failUpdate: true);
      await _pumpScreen(tester, repo);
      expect(_switchValue(tester), isTrue);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump();

      expect(repo.updates, [false]);
      expect(_switchValue(tester), isTrue);
      expect(find.text(kCompteNotifSaveFailed), findsOneWidget);
      expect(find.text(kCompteNotifSaved), findsNothing);
    });
  });
}
