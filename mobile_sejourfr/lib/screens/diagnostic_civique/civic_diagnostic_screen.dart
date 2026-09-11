import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/api/civic_diagnostic_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/civic_diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/tcf_diagnostic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'civic_diagnostic_guest_store.dart';
import 'civic_diagnostic_labels.dart';

/// L'accueil du diagnostic **civique** (`20_` §4, maquette `civique-intro`).
///
/// 🛑 **Ce n'est PAS un examen blanc**, et l'écran le dit avant de commencer :
/// couverture équilibrée sur les 5 thèmes, il sert à repérer quoi travailler,
/// pas à vérifier si on est prêt. Sans cette phrase, le candidat lit son
/// résultat comme un pronostic de réussite.
///
/// 🛑 **Aucun écran de passation n'est créé** : le diagnostic ouvre le runner
/// existant. Un second runner divergerait du premier.
///
/// 🛑 **Un seul diagnostic civique**, pas de rapide + complet : le civique est
/// du QCM déterministe et rapide, un pré-diagnostic n'apporterait rien et
/// dupliquerait le tunnel du TCF (arbitrage du 2026-09-10).
///
/// 🛑 **On peut le passer AVANT de créer son compte** (`V053`, arbitrage du
/// propriétaire du 2026-09-10). Le visiteur déclare sa démarche — c'est elle
/// qui choisit les questions —, répond à ses 40 questions, et le compte n'est
/// demandé qu'au résultat. Dès qu'il s'authentifie, la session invitée est
/// **adoptée** : mêmes questions, mêmes réponses, rien n'est rejoué.
///
/// Miroir de `web_sejoufr/app/_components/diagnostic-civique/CivicDiagnosticHub.tsx`.
class CivicDiagnosticScreen extends ConsumerStatefulWidget {
  const CivicDiagnosticScreen({super.key});

  @override
  ConsumerState<CivicDiagnosticScreen> createState() =>
      _CivicDiagnosticScreenState();
}

class _CivicDiagnosticScreenState extends ConsumerState<CivicDiagnosticScreen> {
  final _store = CivicDiagnosticGuestStore();

  CivicDiagnosticDto? _diagnostic;

  /// La session affichée est celle d'un visiteur : le résultat lui est refusé
  /// ici, il passe par l'écran de compte.
  bool _invite = false;

  /// La démarche déclarée avant le tirage.
  ///
  /// 🛑 `null` tant que rien n'est coché, et le bouton reste **inerte** : la
  /// démarche choisit les questions, la préremplir à CSP mesurerait un candidat
  /// naturalisation sur le programme le plus étroit sans qu'il l'ait demandé.
  TargetProcedure? _procedure;

  /// Les 5 thèmes du livret : **libellés éditoriaux servis**, jamais recopiés.
  List<String> _themes = const [];

  bool _loading = true;
  bool _busy = false;
  String? _error;

  bool get _authentifie =>
      ref.read(authControllerProvider) is AuthAuthenticated;

  @override
  void initState() {
    super.initState();
    _load();
    _chargerThemes();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(civicDiagnosticRepositoryProvider);
    try {
      if (_authentifie) {
        // 🛑 **L'adoption d'abord.** Le visiteur qui vient de créer son compte
        // doit retrouver SON diagnostic, pas s'en voir proposer un neuf.
        final adopte = await _adopterSiInvite(repo);
        final courant = adopte ?? await repo.current();
        if (!mounted) return;
        setState(() {
          _diagnostic = courant;
          _invite = false;
          _procedure = _procedureDuCompte();
          _loading = false;
        });
        return;
      }
      final invite = await _store.read();
      CivicDiagnosticDto? etat;
      if (invite != null) {
        try {
          etat = await repo.guest(invite.sessionId);
        } catch (_) {
          // Session adoptée ailleurs, expirée, ou ouverte depuis une autre IP :
          // garder l'adresse ferait rejouer l'échec à chaque visite.
          await _store.forget();
        }
      }
      if (!mounted) return;
      setState(() {
        _diagnostic = etat;
        _invite = etat != null;
        _procedure = invite?.procedure;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.toApiException(e).message;
        _loading = false;
      });
    }
  }

  /// Le livret vient du serveur : recopier ses cinq libellés dans le front en
  /// ferait une sixième copie qui dériverait au premier ajustement éditorial.
  ///
  /// 🛑 Lecture **publique** : l'écran s'ouvre sans compte, et un échec laisse
  /// simplement la carte de côté — on ne déclare pas le livret vide sur une
  /// panne réseau.
  Future<void> _chargerThemes() async {
    try {
      final themes = await ref
          .read(themesRepositoryProvider)
          .listPublic(module: AppModule.civique);
      if (!mounted) return;
      setState(() => _themes = themes.map((t) => t.name).toList());
    } catch (_) {
      // Silencieux : la carte du livret est informative, pas bloquante.
    }
  }

  TargetProcedure? _procedureDuCompte() {
    final etat = ref.read(authControllerProvider);
    return etat is AuthAuthenticated ? etat.user.targetProcedure : null;
  }

  /// **L'adoption**, best-effort : son échec le plus probable est le quota (un
  /// compte qui a déjà son diagnostic gratuit), et l'écran retombe alors sur le
  /// diagnostic du compte, qui existe.
  Future<CivicDiagnosticDto?> _adopterSiInvite(
    CivicDiagnosticGateway repo,
  ) async {
    final invite = await _store.read();
    if (invite == null) return null;
    try {
      final adopte = await repo.adopt(invite.sessionId);
      await _store.forget();
      return adopte;
    } catch (_) {
      await _store.forget();
      return null;
    }
  }

  /// Ouvrir est idempotent côté compte : un double appui ne retire pas.
  Future<void> _ouvrir() async {
    final procedure = _procedure;
    if (_busy || procedure == null) return;
    setState(() => _busy = true);
    final repo = ref.read(civicDiagnosticRepositoryProvider);
    try {
      final CivicDiagnosticDto ouvert;
      if (_authentifie) {
        // 🛑 Côté compte, le serveur tire sur `users.target_procedure` :
        // changer de démarche ici doit donc la **déclarer** avant le tirage,
        // sinon l'écran promet un programme et le serveur en sert un autre.
        if (procedure != _procedureDuCompte()) {
          await ref
              .read(userContentRepositoryProvider)
              .updateTargetPath(procedure);
          await ref.read(authControllerProvider.notifier).refreshUser();
        }
        ouvert = await repo.open();
      } else {
        ouvert = await repo.openGuest(procedure);
        // L'adresse de la session, pour la reprise et pour l'adoption au
        // moment du compte.
        await _store.write(ouvert, procedure);
      }
      if (!mounted) return;
      setState(() => _busy = false);
      // 🛑 Le marqueur voyage avec l'attempt : c'est LUI qui ramène au
      // diagnostic à la fin. Sans lui, le candidat termine ses questions et
      // atterrit sur le bilan de série générique.
      context.push(civicRunnerPath(ouvert.attemptId, ouvert.sessionId));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.toApiException(e).message;
        _busy = false;
      });
    }
  }

  /// 🛑 **Un visiteur n'obtient aucun résultat ici** : il est envoyé sur
  /// l'écran de résultat, qui lui demande son compte. Le résultat est
  /// exactement ce qu'on échange contre l'inscription.
  Future<void> _voirResultat(String sessionId) async {
    if (_busy) return;
    if (_invite) {
      context.push('/diagnostic-civique/$sessionId/resultat');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(civicDiagnosticRepositoryProvider).result(sessionId);
      if (!mounted) return;
      setState(() => _busy = false);
      context.push('/diagnostic-civique/$sessionId/resultat');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.toApiException(e).message;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // L'authentification peut basculer pendant que l'écran est monté (retour
    // d'inscription) : on relit alors l'état, ce qui déclenche l'adoption.
    ref.listen(authControllerProvider, (avant, apres) {
      if (avant is! AuthAuthenticated && apres is AuthAuthenticated) {
        _load();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final d = _diagnostic;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        SfTop(
          onBack: () => context.pop(),
          kicker: kCivicIntroKicker,
          title: kCivicIntroTitle,
          badges: _invite ? const [kCivicDiagnosticGuestBadge] : const [],
        ),
        if (_error != null)
          SfSection(
            flush: true,
            child: SfStack(
              pad: false,
              children: [
                SfNoteCard(
                  icon: LucideIcons.circleAlert,
                  title: _error!,
                  variant: SfCardVariant.warn,
                ),
                SfButton(
                  label: 'Réessayer',
                  variant: SfButtonVariant.line,
                  onPressed: _busy ? null : _load,
                ),
              ],
            ),
          ),
        if (d != null) ..._reprise(d) else ..._intro(),
      ],
    );
  }

  /// Un diagnostic déjà ouvert : on ne redécrit pas le format, on dit où il en
  /// est et on le rouvre.
  List<Widget> _reprise(CivicDiagnosticDto d) {
    final termine = d.status == TcfDiagnosticStatus.completed;
    return [
      SfSection(
        flush: true,
        child: SfStack(
          pad: false,
          children: [
            SfCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SfLabel(kCivicDiagnosticEnCoursLabel),
                  const SizedBox(height: 6),
                  SfHeadline(civicProgressionLabel(d.repondues, d.total)),
                  if (!termine) ...[
                    const SizedBox(height: 8),
                    const SfTiny(kCivicDiagnosticNotExam),
                  ],
                ],
              ),
            ),
            if (termine)
              SfButton(
                label: kCivicDiagnosticResultCta,
                variant: SfButtonVariant.blue,
                onPressed: _busy ? null : () => _voirResultat(d.sessionId),
              )
            else ...[
              SfButton(
                label: d.repondues > 0
                    ? kCivicDiagnosticResumeCta
                    : kCivicDiagnosticStartCta,
                variant: SfButtonVariant.blue,
                onPressed: _busy
                    ? null
                    : () =>
                        context.push(civicRunnerPath(d.attemptId, d.sessionId)),
              ),
              // Le résultat reste demandable même sans avoir tout répondu : une
              // question sautée sort du dénominateur, elle ne devient jamais
              // une mauvaise réponse.
              if (d.repondues > 0)
                SfButton(
                  label: kCivicDiagnosticResultCta,
                  variant: SfButtonVariant.line,
                  onPressed: _busy ? null : () => _voirResultat(d.sessionId),
                ),
            ],
          ],
        ),
      ),
      if (_invite) ...[
        const SizedBox(height: 14),
        const Padding(
          padding: sfGutter,
          child: SfTiny(kCivicDiagnosticGuestNote),
        ),
      ],
    ];
  }

  /// L'intro : le format de l'épreuve, le livret, la démarche, le départ.
  List<Widget> _intro() {
    /// 🛑 **Une question déjà posée ne se repose pas.** La démarche est
    /// collectée à l'inscription / à l'onboarding (`TargetPathScreen`) : la
    /// redemander sur l'écran de lancement laissait croire qu'elle n'avait pas
    /// été enregistrée. `null` (invité, ou compte sans démarche) ⇒ le sélecteur
    /// reste, c'est le seul moment où l'information manque vraiment.
    final demarcheDuCompte = _procedureDuCompte();
    return [
      const Padding(padding: sfGutter, child: SfInsight(kCivicIntroLead)),

      // 🛑 Le format de l'épreuve, pas celui de la maquette : 40 questions et
      // un seuil de 32, miroir de `CivicExamFormat`. Aucune durée n'est
      // annoncée — le diagnostic n'a pas de chrono et le serveur n'en sert
      // aucune : l'inventer serait promettre un temps qui n'existe pas.
      const SfSection(
        flush: true,
        child: SfCard(
          child: SfStatGrid(
            stats: [
              (value: '$kCivicExamQuestions', label: kCivicIntroStatQuestions),
              (value: '$kCivicThemesCount', label: kCivicIntroStatThemes),
              (
                value: '$kCivicExamSeuilReussite / $kCivicExamQuestions',
                label: kCivicIntroStatSeuil,
              ),
            ],
          ),
        ),
      ),

      if (_themes.isNotEmpty)
        SfSection(
          flush: true,
          child: SfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SfLabel(kCivicIntroThemesTitle),
                const SizedBox(height: 6),
                SfBulletList(items: _themes),
                const SizedBox(height: 12),
                const SfTiny(kCivicIntroSituationsNote),
              ],
            ),
          ),
        ),

      // 🛑 La démarche n'est pas un confort : elle choisit les questions. Un
      // candidat naturalisation mesuré sur le programme d'une carte de séjour
      // repart avec un diagnostic flatteur et un plan incomplet.
      //
      // 🛑 Mais on ne la REDEMANDE pas à qui l'a déjà donnée : un compte qui la
      // porte la voit rappelée, pas remise en question.
      if (demarcheDuCompte == null)
        SfSection(
          flush: true,
          title: kCivicDiagnosticGuestTitle,
          child: SfStack(
            pad: false,
            children: [
              for (final p in TargetProcedure.values)
                SfChoiceCard(
                  label: kMentionLabel[p.wire] ?? p.wire,
                  selected: p == _procedure,
                  onTap: () => setState(() => _procedure = p),
                ),
            ],
          ),
        ),

      SfSection(
        flush: true,
        child: SfStack(
          pad: false,
          children: [
            // La démarche reste LISIBLE : c'est elle qui choisit les questions,
            // le candidat doit pouvoir vérifier sur quel programme il va être
            // mesuré.
            if (demarcheDuCompte != null)
              SfTiny(civicProcedureLine(demarcheDuCompte.wire)),
            SfButton(
              label: kCivicDiagnosticStartCta,
              variant: SfButtonVariant.blue,
              caption: kCivicIntroFreeCaption,
              // 🛑 Inerte tant qu'aucune démarche n'est cochée.
              onPressed: _busy || _procedure == null ? null : _ouvrir,
            ),
            // Aucun écran neuf : `TargetPathScreen` est déjà l'autorité de la
            // démarche, et il revient ici après enregistrement.
            if (demarcheDuCompte != null)
              SfButton(
                label: kCivicDiagnosticProcedureChangeCta,
                variant: SfButtonVariant.line,
                onPressed: _busy
                    ? null
                    : () => context.push(kCivicProcedureChangePath),
              ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const Padding(
        padding: sfGutter,
        child: SfTiny(kCivicDiagnosticNotExam),
      ),
      if (!_authentifie) ...[
        const SizedBox(height: 8),
        const Padding(
          padding: sfGutter,
          child: SfTiny(kCivicDiagnosticGuestNote),
        ),
      ],
    ];
  }
}
