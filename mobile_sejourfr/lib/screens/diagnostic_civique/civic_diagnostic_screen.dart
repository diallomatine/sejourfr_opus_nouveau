import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/civic_diagnostic_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/civic_diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/tcf_diagnostic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/screen_header.dart';
import 'civic_diagnostic_guest_store.dart';
import 'civic_diagnostic_labels.dart';

/// L'accueil du diagnostic **civique** (`20_` §4).
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

  /// La démarche choisie avant le tirage. Elle ne sert qu'au visiteur.
  TargetProcedure _procedure = TargetProcedure.csp;

  bool _loading = true;
  bool _busy = false;
  String? _error;

  bool get _authentifie =>
      ref.read(authControllerProvider) is AuthAuthenticated;

  @override
  void initState() {
    super.initState();
    _load();
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
        _procedure = invite?.procedure ?? TargetProcedure.csp;
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
    if (_busy) return;
    setState(() => _busy = true);
    final repo = ref.read(civicDiagnosticRepositoryProvider);
    try {
      final invite = !_authentifie;
      final ouvert =
          invite ? await repo.openGuest(_procedure) : await repo.open();
      if (invite) {
        // L'adresse de la session, pour la reprise et pour l'adoption au
        // moment du compte.
        await _store.write(ouvert, _procedure);
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
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: kCivicDiagnosticTitle,
              onBack: () => context.pop(),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final d = _diagnostic;
    if (d == null && !_authentifie) return _choixDemarche();

    final termine = d?.status == TcfDiagnosticStatus.completed;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (_invite) ...[
          const AppTag(
            label: kCivicDiagnosticGuestBadge,
            tone: TagTone.blue,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          d == null
              // 🛑 Tant que le serveur n'a rien servi, on décrit le parcours
              // sans le chiffrer plutôt que d'annoncer un compte qui pourrait
              // changer.
              ? 'Le format de l\'examen, réparti sur les 5 thèmes.'
              : civicDiagnosticSubtitle(d.total),
          style: AppFonts.ui(size: 14, color: AppColors.inkSoft, height: 1.5),
        ),
        if (d != null) ...[
          const SizedBox(height: 10),
          Text(civicProgressionLabel(d.repondues, d.total),
              style: AppFonts.label(size: 12, color: AppColors.inkFaint)),
        ],
        if (!termine) ...[
          const SizedBox(height: 12),
          Text(kCivicDiagnosticNotExam,
              style: AppFonts.ui(size: 13, color: AppColors.inkSoft)),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: AppFonts.ui(size: 13, color: AppColors.red)),
        ],
        const SizedBox(height: 20),
        if (d == null)
          AppButton(
            label: kCivicDiagnosticStartCta,
            onPressed: _busy ? null : _ouvrir,
            isLoading: _busy,
          )
        else if (termine)
          AppButton(
            label: kCivicDiagnosticResultCta,
            onPressed: _busy ? null : () => _voirResultat(d.sessionId),
            isLoading: _busy,
          )
        else ...[
          AppButton(
            label: d.repondues > 0
                ? kCivicDiagnosticResumeCta
                : kCivicDiagnosticStartCta,
            onPressed:
                _busy
                    ? null
                    : () => context.push(
                        civicRunnerPath(d.attemptId, d.sessionId)),
          ),
          // Le résultat reste demandable même sans avoir tout répondu : une
          // question sautée sort du dénominateur, elle ne devient jamais une
          // mauvaise réponse.
          if (d.repondues > 0) ...[
            const SizedBox(height: 10),
            AppButton(
              label: kCivicDiagnosticResultCta,
              variant: AppButtonVariant.outline,
              onPressed: _busy ? null : () => _voirResultat(d.sessionId),
            ),
          ],
        ],
        if (_invite) ...[
          const SizedBox(height: 14),
          Text(kCivicDiagnosticGuestNote,
              style: AppFonts.ui(size: 12.5, color: AppColors.inkFaint,
                  height: 1.5)),
        ],
      ],
    );
  }

  /// L'entrée du visiteur : sa démarche, puis le tirage.
  ///
  /// 🛑 La démarche n'est pas un confort : elle choisit les questions. Un
  /// candidat naturalisation mesuré sur le programme d'une carte de séjour
  /// repart avec un diagnostic flatteur et un plan incomplet.
  Widget _choixDemarche() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const AppTag(label: kCivicDiagnosticGuestBadge, tone: TagTone.blue),
        const SizedBox(height: 12),
        Text(kCivicDiagnosticGuestTitle, style: AppFonts.display(size: 22)),
        const SizedBox(height: 8),
        Text(kCivicDiagnosticGuestLead,
            style: AppFonts.ui(size: 14, color: AppColors.inkSoft, height: 1.5)),
        const SizedBox(height: 16),
        for (final p in TargetProcedure.values) ...[
          _DemarcheTile(
            procedure: p,
            selected: p == _procedure,
            onTap: () => setState(() => _procedure = p),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 6),
        Text(kCivicDiagnosticNotExam,
            style: AppFonts.ui(size: 13, color: AppColors.inkSoft)),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: AppFonts.ui(size: 13, color: AppColors.red)),
        ],
        const SizedBox(height: 18),
        AppButton(
          label: kCivicDiagnosticStartCta,
          onPressed: _busy ? null : _ouvrir,
          isLoading: _busy,
        ),
        const SizedBox(height: 14),
        Text(kCivicDiagnosticGuestNote,
            style: AppFonts.ui(
                size: 12.5, color: AppColors.inkFaint, height: 1.5)),
      ],
    );
  }
}

class _DemarcheTile extends StatelessWidget {
  const _DemarcheTile({
    required this.procedure,
    required this.selected,
    required this.onTap,
  });

  final TargetProcedure procedure;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? AppColors.blueSoft : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(procedure.wire,
                  style: AppFonts.label(size: 12, color: AppColors.blue)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  kMentionLabel[procedure.wire] ?? procedure.wire,
                  style: AppFonts.ui(size: 14, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
