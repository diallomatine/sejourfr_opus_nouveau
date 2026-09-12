import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/router/retour.dart';
import '../../core/api/api_client.dart';
import '../../core/api/civic_diagnostic_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/civic_diagnostic_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'civic_diagnostic_blocks.dart';
import 'civic_diagnostic_guest_store.dart';
import 'civic_diagnostic_labels.dart';

/// Le résultat du diagnostic **civique** (`20_` §4.5, maquette
/// `civique-resultat`).
///
/// Ordre imposé : score → vos thèmes → mises en situation → ce qui coûte le
/// plus de points → rassurance → aperçu du plan.
///
/// 🛑 **Le constat est intégralement gratuit.** Aucun `locked` : le paywall
/// porte sur l'accompagnement, jamais sur ce que le candidat vient de mesurer.
///
/// 🛑 **Un thème NON ÉVALUÉ n'est pas faible.** Il se dit « Non évalué », en
/// neutre, et n'entre dans aucune priorité.
///
/// 🛑 **Un VISITEUR n'obtient aucun résultat ici** (`V053`, arbitrage du
/// propriétaire du 2026-09-10) : il a répondu à ses 40 questions, et c'est
/// précisément le résultat qu'on échange contre le compte. L'écran lui montre
/// ce qu'il a déjà — le nombre de réponses enregistrées — et le renvoie vers
/// l'inscription. Le serveur n'expose d'ailleurs aucune route de résultat
/// publique : cet écran ne pourrait pas mentir même s'il le voulait.
class CivicDiagnosticResultScreen extends ConsumerStatefulWidget {
  const CivicDiagnosticResultScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<CivicDiagnosticResultScreen> createState() =>
      _CivicDiagnosticResultScreenState();
}

class _CivicDiagnosticResultScreenState
    extends ConsumerState<CivicDiagnosticResultScreen> {
  final _store = CivicDiagnosticGuestStore();

  CivicDiagnosticResultDto? _resultat;

  /// L'avancement du visiteur, quand il n'y a pas encore de compte.
  CivicDiagnosticDto? _invite;

  bool _loading = true;
  String? _error;

  bool get _authentifie =>
      ref.read(authControllerProvider) is AuthAuthenticated;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(civicDiagnosticRepositoryProvider);
    try {
      if (!_authentifie) {
        // 🛑 Aucun résultat pour un visiteur : on ne montre que ce qu'il a
        // déjà, le nombre de questions traitées.
        final etat = await repo.guest(widget.sessionId);
        if (!mounted) return;
        setState(() {
          _invite = etat;
          _loading = false;
        });
        return;
      }

      // 🛑 **L'adoption d'abord**, et son échec n'arrête rien : un compte qui
      // avait déjà son diagnostic gratuit se voit refuser l'adoption et doit
      // tout de même voir SON résultat.
      await _adopterSiInvite(repo);

      // 🛑 `result()` (POST) et non `readResult()` : c'est lui qui CLÔTURE la
      // session. Sans cette clôture, le diagnostic reste « en cours » pour
      // toujours et le Plan continue de réclamer un diagnostic que le candidat
      // vient de terminer. L'appel est idempotent : une session déjà close est
      // rendue telle quelle.
      final r = await repo.result(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _resultat = r;
        _invite = null;
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

  Future<void> _adopterSiInvite(CivicDiagnosticGateway repo) async {
    final invite = await _store.read();
    if (invite == null) return;
    try {
      await repo.adopt(invite.sessionId);
    } catch (_) {
      // Refus le plus probable : le quota du compte. Le résultat du compte
      // existe quand même, on le lit juste après.
    }
    await _store.forget();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final invite = _invite;
    if (invite != null) return _gate(invite);

    final r = _resultat;
    if (r == null) {
      return Center(
        child: Padding(
          padding: sfGutter,
          child: Text(
            _error ?? 'Résultat indisponible.',
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 14, color: AppColors.red),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        SfTop(
          onBack: () => retourOuRepli(context, repli: AppRoutes.plan),
          kicker: kCivicResultKicker,
          title: kCivicResultTitle,
          badges: const [kCivicResultBadge],
        ),
        _hero(r),
        _themes(r),
        _situations(r),
        _priorites(r),
        _rassurance(r),
        _plan(r),
      ],
    );
  }

  /// 1 — le score. L'élément dominant de l'écran.
  Widget _hero(CivicDiagnosticResultDto r) {
    final perspective = civicPerspectiveLine(r);
    return Padding(
      padding: sfGutter,
      child: SfCard(
        variant: SfCardVariant.hero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SfLabel(kCivicScoreLabel),
            const SizedBox(height: 6),
            SfScore(score: r.bonnes, total: r.posees),
            // 🛑 Absente si rien n'a été posé : « on n'a rien mesuré » ne se
            // dit pas « vous auriez 0 sur 40 ».
            if (perspective != null) ...[
              const SizedBox(height: 12),
              SfInsight(perspective),
            ],
            const SizedBox(height: 12),
            SfThreshold(civicThresholdLine(r)),
          ],
        ),
      ),
    );
  }

  /// 2 — les 5 thèmes, **tous**, y compris ceux qu'aucune question n'a touchés.
  Widget _themes(CivicDiagnosticResultDto r) {
    return SfSection(
      flush: true,
      title: kCivicThemesTitle,
      child: SfCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < r.themes.length; i++)
              SfThemeLine(
                tone: sfToneOf(r.themes[i].etat),
                name: r.themes[i].label,
                status: r.themes[i].etat.label,
                last: i == r.themes.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  /// 3 — les mises en situation, bloc distinct : c'est une compétence
  /// différente, et c'est souvent ce qui fait la différence.
  ///
  /// 🛑 **Toute la section disparaît** quand aucune n'a été posée (mode
  /// dégradé) : un bloc à zéro se lirait comme un échec.
  Widget _situations(CivicDiagnosticResultDto r) {
    final ligne = situationsLine(r);
    if (ligne == null) return const SizedBox.shrink();
    return SfSection(
      flush: true,
      title: kCivicSituationsTitle,
      child: SfCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SfLabel(kCivicSituationsLabel),
            const SizedBox(height: 6),
            SfHeadline(ligne),
            const SizedBox(height: 8),
            const SfTiny(kCivicSituationsText),
          ],
        ),
      ),
    );
  }

  /// 4 — ce qui coûte le plus de points.
  ///
  /// Le rang, le thème et l'état sont **servis** ; aucune phrase explicative
  /// n'existe côté serveur, on n'en invente pas. 🛑 L'étiquette porte l'état et
  /// le titre le thème : le grain est le THÈME (`20_` §3.4), `label` EST déjà
  /// le thème, et répéter la même chaîne deux fois ne dirait rien.
  Widget _priorites(CivicDiagnosticResultDto r) {
    final visibles = _visibles(r);
    if (visibles.isEmpty) return const SizedBox.shrink();
    return SfSection(
      flush: true,
      title: kCivicPrioritesTitle,
      child: SfStack(
        pad: false,
        children: [
          for (var i = 0; i < visibles.length; i++)
            SfPrio(
              rank: i + 1,
              tag: visibles[i].etat.label,
              title: visibles[i].label,
            ),
        ],
      ),
    );
  }

  /// 🛑 **Plafond d'AFFICHAGE, jamais un budget** : le serveur classe tous les
  /// thèmes sous l'objectif, l'écran en montre trois et compte le reste.
  List<CivicPrioriteTheme> _visibles(CivicDiagnosticResultDto r) =>
      r.priorites.take(kCivicPrioritesVisibles).toList();

  /// 5 — rassurance. 🛑 Absente si aucun thème n'est solide.
  Widget _rassurance(CivicDiagnosticResultDto r) {
    final texte = civicRassuranceText(r);
    if (texte == null) return const SizedBox.shrink();
    return SfSection(
      flush: true,
      child: SfNoteCard(
        icon: LucideIcons.check,
        title: kCivicRassuranceTitle,
        variant: SfCardVariant.ok,
        child: SfTiny(texte, color: AppColors.ink2),
      ),
    );
  }

  /// 6 — l'aperçu du plan et sa porte d'entrée.
  Widget _plan(CivicDiagnosticResultDto r) {
    final visibles = _visibles(r);
    final autres = civicAutresPrioritesLine(r.priorites.length);
    return SfSection(
      flush: true,
      title: kCivicPlanTeaserTitle,
      child: SfStack(
        pad: false,
        children: [
          if (visibles.isNotEmpty)
            SfCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SfMiniPlan(
                    rows: [
                      for (final p in visibles)
                        SfMiniRow(
                          label: p.label,
                          pill: p.etat.label,
                          tone: sfToneOf(p.etat),
                        ),
                    ],
                  ),
                  if (autres != null) ...[
                    const SizedBox(height: 10),
                    SfTiny(autres),
                  ],
                ],
              ),
            ),
          SfButton(
            label: kCivicDiagnosticPlanCta,
            variant: SfButtonVariant.blue,
            onPressed: () => context.go('/plan?module=CIVIQUE'),
          ),
        ],
      ),
    );
  }

  /// L'écran de compte du diagnostic passé en visiteur (`V053`).
  ///
  /// 🛑 **Aucun résultat n'est montré ici.** Ni score, ni thème, ni projection :
  /// c'est exactement ce qu'on échange contre le compte. 🛑 **Les réponses ne
  /// sont pas en jeu** — elles sont déjà corrigées côté serveur, sur une session
  /// que l'inscription se contente d'*adopter*, et l'écran le dit.
  Widget _gate(CivicDiagnosticDto invite) {
    final destination = AppRoutes.civicDiagnosticResultPath(widget.sessionId);
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        SfTop(
          onBack: () => retourOuRepli(context, repli: AppRoutes.plan),
          kicker: kCivicDiagnosticGateEyebrow,
          title: kCivicDiagnosticGateTitle,
          badges: const [kCivicDiagnosticGuestBadge],
        ),
        Padding(
          padding: sfGutter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SfInsight(kCivicDiagnosticGateLead),
              const SizedBox(height: 12),
              SfLabel(civicProgressionLabel(invite.repondues, invite.total)),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: AppFonts.ui(size: 13, color: AppColors.red)),
              ],
            ],
          ),
        ),
        SfSection(
          flush: true,
          child: SfStack(
            pad: false,
            children: [
              SfButton(
                label: 'Créer mon compte gratuit',
                variant: SfButtonVariant.blue,
                onPressed: () => context.push(
                    authFlowLocation(AppRoutes.register, destination)),
              ),
              SfButton(
                label: 'J\'ai déjà un compte',
                variant: SfButtonVariant.line,
                onPressed: () => context.push(loginLocationFor(destination)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: sfGutter,
          child: SfTiny(
            'Gratuit, sans carte bancaire. Vos réponses sont déjà enregistrées : '
            'elles vous suivent.',
          ),
        ),
      ],
    );
  }
}
