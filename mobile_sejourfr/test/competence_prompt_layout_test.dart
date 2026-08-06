import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sejourfr_mobile/core/api/repositories.dart';
import 'package:sejourfr_mobile/core/api/skill_repository.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';
import 'package:sejourfr_mobile/core/widgets/fixed_action_bar.dart';
import 'package:sejourfr_mobile/screens/tcf_production/competences/competence_prompt_screen.dart';
import 'package:sejourfr_mobile/screens/tcf_production/competences/widgets/skill_answer_card.dart';
import 'package:sejourfr_mobile/screens/tcf_production/tcf_production_module.dart';

/// **Le critère de réussite de cet écran est mesurable** : la zone de
/// production doit être visible sans défiler sur un téléphone standard.
///
/// Ces tests le vérifient sur le vrai écran (pas sur une recomposition de ses
/// blocs), à deux tailles d'écran réelles, à l'écrit **et** à l'oral. Tout
/// ajout au-dessus de la carte « Votre réponse » les fera tomber : c'est le but.
///
/// Ils verrouillent aussi ce qui a **disparu** — l'écran fait produire, il
/// n'explique plus.

/// iPhone 14/15/16 : la taille de référence.
const Size _kStandardPhone = Size(390, 844);

/// Un petit écran encore courant (iPhone 13 mini / SE moderne) : le pire cas
/// qu'on accepte.
const Size _kSmallPhone = Size(375, 812);

Map<String, dynamic> _promptJson(Map<String, dynamic> extra) => {
      'id': 'p1',
      'skillId': 'c1',
      'skillCode': 'EE1-C1',
      'skillTitle': 'Adapter le message au destinataire',
      'skillPromptCount': 5,
      'skillDescription': 'Savoir à qui l\'on écrit change tout le message.',
      'skillGeneralCriterion': 'Le message est adapté à son destinataire.',
      'skillTargetLevel': 'A2',
      'section': 'EE',
      'taskCode': 'EE1',
      'taskTitle': 'Écrire un message court',
      'code': 'EE1-C1-S1',
      'title': 'Un mot pour votre voisine',
      'context': 'Vous partez 3 jours. Vos plantes ont besoin d\'eau. '
          'Vous connaissez peu votre voisine du 2e étage.',
      'instruction': 'Écrivez les deux premières phrases de votre message : '
          'saluez-la et dites qui vous êtes.',
      'uniqueCriterion': 'Employer une salutation et un vouvoiement adaptés '
          'à une voisine que l\'on connaît peu.',
      'difficultyLevel': 'EASY',
      'displayOrder': 1,
      'status': 'TODO',
      'attemptCount': 0,
      'recommendedMinWords': 15,
      'recommendedMaxWords': 35,
      'checklist': [
        'Saluez votre voisine',
        'Dites qui vous êtes',
        'Écrivez 2 phrases',
      ],
      'constraintTags': [
        {'label': 'Vouvoiement', 'icon': 'PERSON'},
        {'label': 'Ton poli', 'icon': 'TONE'},
      ],
      'answerStarter': 'Bonjour Madame, je suis votre voisin du…',
      'tip': 'commencez par bonjour, puis présentez-vous.',
      ...extra,
    };

Map<String, dynamic> _detailJson(SkillPromptDto prompt) => {
      'skill': {
        'id': 'c1',
        'section': prompt.section.wire,
        'taskCode': prompt.taskCode,
        'code': prompt.skillCode,
        'title': prompt.skillTitle,
        'description': prompt.skillDescription,
        'generalCriterion': prompt.skillGeneralCriterion,
        'targetLevel': prompt.skillTargetLevel,
        'displayOrder': 1,
        'promptCount': 5,
        'attemptedCount': 0,
        'validatedCount': 0,
        'toReinforceCount': 0,
      },
      'prompts': [
        for (var i = 0; i < 5; i++)
          {
            'id': 'p${i + 1}',
            'code': 'EE1-C1-S${i + 1}',
            'title': 'Sujet ${i + 1}',
            'uniqueCriterion': prompt.uniqueCriterion,
            'difficultyLevel': 'EASY',
            'displayOrder': i + 1,
            'status': 'TODO',
            'attemptCount': 0,
          },
      ],
    };

/// Repository de test : seules les trois lectures de l'écran sont servies.
class _FakeSkillRepository implements SkillRepository {
  _FakeSkillRepository(this.prompt);

  final SkillPromptDto prompt;

  @override
  Future<SkillPromptDto> getPrompt(String promptId) async => prompt;

  @override
  Future<SkillDetail> getSkillDetail(String skillId) async =>
      SkillDetail.fromJson(_detailJson(prompt));

  @override
  Future<SkillAnalysisQuotaDto> analysisQuota() async =>
      SkillAnalysisQuotaDto.fromJson(const {
        'premium': false,
        'unlimited': false,
        'freeAnalysesTotal': 3,
        'freeAnalysesUsed': 0,
        'remaining': 3,
      });

  @override
  Future<List<SkillDto>> listSkills(String taskCode) async =>
      throw UnimplementedError();

  @override
  Future<List<SkillReferenceDto>> getReferences(String promptId) async =>
      throw UnimplementedError();

  @override
  Future<SkillAttemptDto> getAttempt(String attemptId) async =>
      throw UnimplementedError();

  @override
  Future<SkillAttemptDto> submitText({
    required String skillPromptId,
    required String texte,
    required bool requestAnalysis,
    SkillSelfEvaluation? selfEvaluation,
  }) async =>
      throw UnimplementedError();

  @override
  Future<SkillAttemptDto> submitAudio({
    required String skillPromptId,
    required File audioFile,
    required int durationSec,
    required bool requestAnalysis,
    SkillSelfEvaluation? selfEvaluation,
    String? mimeType,
  }) async =>
      throw UnimplementedError();

  @override
  Future<SkillAttemptDto> requestAnalysis(String attemptId) async =>
      throw UnimplementedError();

  @override
  Future<SkillAttemptDto> retryAnalysis(String attemptId) async =>
      throw UnimplementedError();
}

Future<void> _pumpPrompt(
  WidgetTester tester, {
  required SkillPromptDto prompt,
  Size size = _kStandardPhone,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        skillRepositoryProvider.overrideWithValue(_FakeSkillRepository(prompt)),
      ],
      child: MaterialApp(
        home: CompetencePromptScreen(
          module: prompt.section.isEo
              ? TcfProductionModule.eo
              : TcfProductionModule.ee,
          skillId: 'c1',
          promptId: 'p1',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Le bord haut de la barre d'action fixe : au-delà, plus rien n'est lisible
/// sans défiler.
double _foldOf(WidgetTester tester) =>
    tester.getRect(find.byType(FixedActionBar)).top;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('la zone de production tient au-dessus de la ligne de flottaison', () {
    testWidgets('à l\'écrit, sur un téléphone standard', (tester) async {
      final prompt = SkillPromptDto.fromJson(_promptJson({}));
      await _pumpPrompt(tester, prompt: prompt);

      final field = tester.getRect(find.byType(SkillWritingField));
      final fold = _foldOf(tester);

      expect(field.top, lessThan(fold),
          reason: 'le champ commence sous la barre d\'action');
      // Pas seulement un liseré : une vraie surface de saisie est offerte.
      expect(field.bottom - field.top, greaterThan(80));
      expect(field.bottom, lessThanOrEqualTo(fold),
          reason: 'le champ déborde sous la barre d\'action');
    });

    testWidgets('à l\'écrit, sur un petit téléphone', (tester) async {
      final prompt = SkillPromptDto.fromJson(_promptJson({}));
      await _pumpPrompt(tester, prompt: prompt, size: _kSmallPhone);

      final field = tester.getRect(find.byType(SkillWritingField));
      final visible = _foldOf(tester) - field.top;
      expect(visible, greaterThan(80),
          reason: 'presque rien du champ n\'est visible sans défiler');
    });

    testWidgets('à l\'oral, la carte de réponse est visible elle aussi',
        (tester) async {
      final prompt = SkillPromptDto.fromJson(_promptJson({
        'section': 'EO',
        'recommendedMinWords': null,
        'recommendedMaxWords': null,
        'recommendedDurationSeconds': 45,
      }));
      await _pumpPrompt(tester, prompt: prompt);

      final card = tester.getRect(find.byType(SkillAnswerCard));
      expect(card.top, lessThan(_foldOf(tester)),
          reason: 'l\'oral est resté sur l\'ancienne mise en page');
    });
  });

  group('parité écrit ⇄ oral : même structure, même guidage', () {
    testWidgets('les deux épreuves rendent check-list, situation et étiquettes',
        (tester) async {
      for (final section in ['EE', 'EO']) {
        final prompt = SkillPromptDto.fromJson(_promptJson({
          'section': section,
          if (section == 'EO') 'recommendedDurationSeconds': 45,
        }));
        await _pumpPrompt(tester, prompt: prompt);

        expect(find.text("Ce qu'il faut faire"), findsOneWidget,
            reason: '$section : pas de check-list');
        expect(find.text('Saluez votre voisine'), findsOneWidget);
        expect(find.text('Situation'), findsOneWidget,
            reason: '$section : pas de situation');
        expect(find.text('Votre réponse'), findsOneWidget);
        expect(find.text('Vouvoiement'), findsOneWidget,
            reason: '$section : pas d\'étiquette de contrainte');
        expect(find.text('Ton poli'), findsOneWidget);
      }
    });

    testWidgets('la longueur est une puce, à l\'unité de chaque épreuve',
        (tester) async {
      await _pumpPrompt(
        tester,
        prompt: SkillPromptDto.fromJson(_promptJson({})),
      );
      expect(find.text('≈ 15–35 mots'), findsOneWidget);
      expect(find.text('0 / 35 mots'), findsOneWidget);

      await _pumpPrompt(
        tester,
        prompt: SkillPromptDto.fromJson(_promptJson({
          'section': 'EO',
          'recommendedDurationSeconds': 45,
        })),
      );
      expect(find.text('≈ 45 secondes'), findsOneWidget);
      // À l'oral le compteur de mots devient la durée.
      expect(find.textContaining('mots'), findsNothing);
      expect(find.text('00:00'), findsOneWidget);
    });
  });

  group('ce que l\'écran ne dit plus', () {
    testWidgets('ni fil d\'Ariane, ni badges, ni encarts pédagogiques',
        (tester) async {
      await _pumpPrompt(
        tester,
        prompt: SkillPromptDto.fromJson(_promptJson({})),
      );

      expect(find.text('Une compétence · un critère'), findsNothing);
      expect(find.textContaining('Petit sujet 1/5'), findsNothing);
      expect(find.text('Produis ta propre réponse.'), findsNothing);
      expect(find.textContaining("L'objectif n'est pas d'écrire"), findsNothing);
      expect(find.text('COMPÉTENCE ÉVALUÉE'), findsNothing);
      expect(find.textContaining('Pourquoi cet exercice ?'), findsNothing);
      expect(find.text('Accessible'), findsNothing);
      expect(find.text('Un seul critère'), findsNothing);
      // Le fil d'Ariane laisse place au seul repère utile.
      expect(find.text('Sujet 1/5'), findsOneWidget);
      expect(find.text('Progression'), findsOneWidget);
      expect(find.text('A2'), findsOneWidget);
    });
  });

  group('dégradation — un sujet sans guidage reste utilisable', () {
    testWidgets('aucune carte vide, aucun « null » à l\'écran', (tester) async {
      final prompt = SkillPromptDto.fromJson(_promptJson({
        'checklist': null,
        'constraintTags': null,
        'answerStarter': null,
        'tip': null,
        'recommendedMinWords': null,
        'recommendedMaxWords': null,
      }));
      await _pumpPrompt(tester, prompt: prompt);

      // La carte retombe sur la consigne au lieu de disparaître.
      expect(find.text("Ce qu'il faut faire"), findsOneWidget);
      expect(find.textContaining('saluez-la et dites qui vous êtes'),
          findsOneWidget);
      // Le champ garde un texte grisé neutre, et le pied ne montre que le
      // compteur.
      expect(find.byType(SkillWritingField), findsOneWidget);
      expect(find.textContaining('Astuce'), findsNothing);
      expect(find.text('0 mot'), findsOneWidget);

      expect(find.textContaining('null'), findsNothing);
      expect(tester.takeException(), isNull);

      // Et la zone de production remonte, elle ne descend pas.
      expect(
        tester.getRect(find.byType(SkillWritingField)).top,
        lessThan(_foldOf(tester)),
      );
    });
  });
}
