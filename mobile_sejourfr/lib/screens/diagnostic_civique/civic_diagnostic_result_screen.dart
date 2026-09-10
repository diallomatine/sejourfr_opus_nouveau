import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/civic_diagnostic_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/civic_diagnostic_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/screen_header.dart';
import 'civic_diagnostic_guest_store.dart';
import 'civic_diagnostic_labels.dart';

/// Le résultat du diagnostic **civique** (`20_` §4.5).
///
/// Ordre imposé : résultat → vos thèmes → mises en situation → ce qui coûte le
/// plus de points → rassurance → teaser du plan.
///
/// 🛑 **Le constat est intégralement gratuit.** Aucun `locked` : le paywall
/// porte sur l'accompagnement, jamais sur ce que le candidat vient de mesurer.
///
/// 🛑 **Un thème NON ÉVALUÉ n'est pas faible.** Il se dit « Non évalué », en
/// atténué, et n'entre dans aucune priorité.
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

    final invite = _invite;
    if (invite != null) return _gate(invite);

    final r = _resultat;
    if (r == null) {
      return Center(
        child: Text(_error ?? 'Résultat indisponible.',
            style: AppFonts.ui(size: 14, color: AppColors.red)),
      );
    }

    final projection = projectionLine(r);
    final situations = situationsLine(r);
    final rassurance = civicRassuranceText(r);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(mentionBadge(r.mention.wire),
                style: AppFonts.label(size: 11, color: AppColors.blueDark)),
          ),
        ),
        const SizedBox(height: 14),

        // 1 — le résultat. L'élément dominant.
        AppCard(
          color: AppColors.blueLight,
          child: Column(
            children: [
              Text('VOTRE RÉSULTAT',
                  style: AppFonts.label(size: 11, color: AppColors.blueDark)),
              const SizedBox(height: 6),
              Text('${r.bonnes} / ${r.posees}',
                  style: AppFonts.display(size: 44, color: AppColors.blue)),
              // 🛑 Absent si rien n'a été posé : « on n'a rien mesuré » ne se
              // dit pas « vous auriez 0 sur 40 ».
              if (projection != null) ...[
                const SizedBox(height: 8),
                Text(projection,
                    textAlign: TextAlign.center,
                    style: AppFonts.ui(
                        size: 13.5, color: AppColors.ink, height: 1.5)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2 — les 5 thèmes, TOUS, y compris les non évalués.
        Text('Vos thèmes',
            style: AppFonts.display(size: 18, color: AppColors.ink)),
        const SizedBox(height: 8),
        for (final t in r.themes) ...[
          _ThemeRow(label: t.label, etat: t.etat),
          const SizedBox(height: 8),
        ],

        // 3 — les mises en situation, bloc distinct : c'est une compétence
        // différente, et c'est souvent ce qui fait la différence.
        if (situations != null) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kCivicSituationsTitle,
                    style: AppFonts.display(size: 16, color: AppColors.ink)),
                const SizedBox(height: 6),
                Text(situations,
                    style: AppFonts.display(size: 22, color: AppColors.blue)),
                const SizedBox(height: 6),
                Text(kCivicSituationsText,
                    style: AppFonts.ui(
                        size: 13, color: AppColors.inkSoft, height: 1.5)),
              ],
            ),
          ),
        ],

        // 4 — ce qui coûte le plus de points. Titre volontairement concret.
        if (r.priorites.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(kCivicPrioritesTitle,
              style: AppFonts.display(size: 18, color: AppColors.ink)),
          const SizedBox(height: 8),
          for (final p in r.priorites) ...[
            _ThemeRow(label: p.label, etat: p.etat, rang: p.rang),
            const SizedBox(height: 8),
          ],
        ],

        // 5 — rassurance. 🛑 Absente si aucun thème n'est solide.
        if (rassurance != null) ...[
          const SizedBox(height: 12),
          AppCard(
            color: AppColors.greenLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kCivicRassuranceTitle,
                    style: AppFonts.display(size: 16, color: AppColors.ink)),
                const SizedBox(height: 6),
                Text(rassurance,
                    style: AppFonts.ui(
                        size: 13, color: AppColors.inkSoft, height: 1.5)),
              ],
            ),
          ),
        ],

        // 6 — le teaser du plan.
        const SizedBox(height: 22),
        Text(kCivicPlanTeaserTitle,
            style: AppFonts.display(size: 18, color: AppColors.ink)),
        const SizedBox(height: 10),
        AppButton(
          label: kCivicDiagnosticPlanCta,
          onPressed: () => context.go('/plan?module=CIVIQUE'),
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(kCivicDiagnosticGateEyebrow.toUpperCase(),
            style: AppFonts.label(size: 11, color: AppColors.red)),
        const SizedBox(height: 8),
        Text(kCivicDiagnosticGateTitle, style: AppFonts.display(size: 24)),
        const SizedBox(height: 10),
        Text(kCivicDiagnosticGateLead,
            style: AppFonts.ui(size: 14, color: AppColors.inkSoft, height: 1.55)),
        const SizedBox(height: 12),
        Text(
          civicProgressionLabel(invite.repondues, invite.total),
          style: AppFonts.label(size: 12, color: AppColors.inkFaint),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: AppFonts.ui(size: 13, color: AppColors.red)),
        ],
        const SizedBox(height: 22),
        AppButton(
          label: 'Créer mon compte gratuit',
          onPressed: () => context.push(
              authFlowLocation(AppRoutes.register, destination)),
        ),
        const SizedBox(height: 10),
        AppButton(
          label: 'J\'ai déjà un compte',
          variant: AppButtonVariant.soft,
          onPressed: () => context.push(loginLocationFor(destination)),
        ),
        const SizedBox(height: 14),
        Text(
          'Gratuit, sans carte bancaire. Vos réponses sont déjà enregistrées : '
          'elles vous suivent.',
          textAlign: TextAlign.center,
          style: AppFonts.ui(size: 12.5, color: AppColors.inkFaint, height: 1.5),
        ),
      ],
    );
  }

}

/// Une ligne de thème : la pastille porte l'état, le texte reste noir.
class _ThemeRow extends StatelessWidget {
  const _ThemeRow({required this.label, required this.etat, this.rang});

  final String label;
  final CivicThemeState etat;
  final int? rang;

  @override
  Widget build(BuildContext context) {
    final tone = civicThemeTone(etat);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (rang case final r?) ...[
            Text('$r',
                style: AppFonts.label(size: 12, color: AppColors.inkFaint)),
            const SizedBox(width: 10),
          ],
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _tonColor(tone),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: AppFonts.ui(size: 14, color: AppColors.ink)),
          ),
          Text(
            etat.label,
            style: AppFonts.label(
              size: 11,
              // Non évalué : atténué, jamais alarmant — ce n'est pas un échec.
              color: tone == CivicThemeTone.muted
                  ? AppColors.inkFaint
                  : _tonColor(tone),
            ),
          ),
        ],
      ),
    );
  }

  static Color _tonColor(CivicThemeTone tone) => switch (tone) {
        CivicThemeTone.ok => AppColors.green,
        CivicThemeTone.warn => AppColors.amber,
        CivicThemeTone.hot => AppColors.red,
        CivicThemeTone.muted => AppColors.line,
      };

}
