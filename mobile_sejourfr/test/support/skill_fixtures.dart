import 'dart:io';

import 'package:sejourfr_mobile/core/api/skill_repository.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';

/// Fixtures partagées du module « Compétences TCF ».
///
/// Trois écrans se testent sur les mêmes objets (un sujet, sa compétence, une
/// tentative, un quota) : les recopier dans chaque fichier de test finissait
/// par les faire diverger — un sujet « sans guidage » ici, « avec » là-bas,
/// pour la même intention.

Map<String, dynamic> promptJson([Map<String, dynamic> extra = const {}]) => {
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

Map<String, dynamic> detailJson(SkillPromptDto prompt) => {
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

/// Un quota d'analyses IA. Par défaut : compte gratuit, 3 analyses offertes,
/// aucune consommée.
Map<String, dynamic> quotaJson({
  bool premium = false,
  bool unlimited = false,
  int freeAnalysesTotal = 3,
  int freeAnalysesUsed = 0,
  int remaining = 3,
}) =>
    {
      'premium': premium,
      'unlimited': unlimited,
      'freeAnalysesTotal': freeAnalysesTotal,
      'freeAnalysesUsed': freeAnalysesUsed,
      'remaining': remaining,
    };

/// Une tentative écrite. `analysis: null` = production enregistrée **sans**
/// analyse (statut `RECORDED`, état final) — pas une attente.
Map<String, dynamic> attemptJson({
  String statut = 'EVALUATED',
  bool analysisRequested = true,
  Map<String, dynamic>? analysis = const {
    'status': 'PARTIAL',
    'verdict': 'La salutation est là, le vouvoiement n\'est pas tenu.',
    'successPoint': 'Tu ouvres par une salutation adaptée à une voisine.',
    'improvementPriority': 'Garde le vouvoiement sur toute la phrase.',
    'improvedVersion': 'Bonjour Madame, je suis votre voisin du 3e étage.',
  },
  String? errorMessage,
}) =>
    {
      'id': 'a1',
      'skillPromptId': 'p1',
      'skillPromptCode': 'EE1-C1-S1',
      'statut': statut,
      'analysisRequested': analysisRequested,
      'createdAt': '2026-08-06T10:00:00Z',
      'writtenProduction': 'Bonjour Madame, je suis ton voisin du 3e étage.',
      'wordsCount': 10,
      if (analysis != null) 'criterionStatus': analysis['status'],
      'analysis': analysis,
      'errorMessage': errorMessage,
    };

List<Map<String, dynamic>> referencesJson() => [
      {
        'level': 'INSUFFICIENT',
        'text': 'Salut, j\'ai des plantes.',
        'pedagogicalNote': 'Ni salutation adaptée ni présentation.',
      },
      {
        'level': 'EXPECTED',
        'text': 'Bonjour Madame, je suis votre voisin du 3e étage.',
        'pedagogicalNote': 'Salutation et présentation, au vouvoiement.',
      },
      {
        'level': 'EXCELLENT',
        'text': 'Bonjour Madame, je me permets de vous écrire : je suis '
            'votre voisin du 3e étage.',
        'pedagogicalNote': 'Le ton reste poli sans devenir guindé.',
      },
    ];

/// Repository de test : sert les lectures des écrans du module et **retient**
/// ce qui a été soumis (c'est ce que verrouillent les tests d'analyse).
class FakeSkillRepository implements SkillRepository {
  FakeSkillRepository({
    required this.prompt,
    Map<String, dynamic>? quota,
    Map<String, dynamic>? attempt,
    List<Map<String, dynamic>>? references,
  })  : quota = quota ?? quotaJson(),
        attempt = attempt ?? attemptJson(),
        references = references ?? referencesJson();

  final SkillPromptDto prompt;
  final Map<String, dynamic> quota;
  final Map<String, dynamic> attempt;
  final List<Map<String, dynamic>> references;

  /// `requestAnalysis` de la dernière soumission — `null` tant que rien n'a
  /// été soumis.
  bool? lastRequestAnalysis;

  @override
  Future<SkillPromptDto> getPrompt(String promptId) async => prompt;

  @override
  Future<SkillDetail> getSkillDetail(String skillId) async =>
      SkillDetail.fromJson(detailJson(prompt));

  @override
  Future<SkillAnalysisQuotaDto> analysisQuota() async =>
      SkillAnalysisQuotaDto.fromJson(quota);

  @override
  Future<List<SkillReferenceDto>> getReferences(String promptId) async =>
      references.map(SkillReferenceDto.fromJson).toList();

  @override
  Future<SkillAttemptDto> getAttempt(String attemptId) async =>
      SkillAttemptDto.fromJson(attempt);

  @override
  Future<List<SkillDto>> listSkillsBySection(String section) async =>
      throw UnimplementedError();

  @override
  Future<List<SkillDto>> listSkills(String taskCode) async =>
      throw UnimplementedError();

  @override
  Future<SkillAttemptDto> submitText({
    required String skillPromptId,
    required String texte,
    required bool requestAnalysis,
    SkillSelfEvaluation? selfEvaluation,
    String? clientSubmissionId,
  }) async {
    lastRequestAnalysis = requestAnalysis;
    return SkillAttemptDto.fromJson(attempt);
  }

  @override
  Future<SkillAttemptDto> submitAudio({
    required String skillPromptId,
    required File audioFile,
    required int durationSec,
    required bool requestAnalysis,
    SkillSelfEvaluation? selfEvaluation,
    String? mimeType,
    String? clientSubmissionId,
  }) async {
    lastRequestAnalysis = requestAnalysis;
    return SkillAttemptDto.fromJson(attempt);
  }

  @override
  Future<SkillAttemptDto> requestAnalysis(String attemptId) async =>
      throw UnimplementedError();

  @override
  Future<SkillAttemptDto> retryAnalysis(String attemptId) async =>
      SkillAttemptDto.fromJson(attempt);
}
