import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/tcf_diagnostic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/screen_header.dart';
import 'tcf_diagnostic_labels.dart';

/// T06 — l'accueil du diagnostic TCF 4 épreuves (`30_` §5.1).
///
/// Son travail : rendre 75 minutes acceptables en montrant qu'elles se
/// découpent, et ne rien promettre d'autre.
///
/// 🛑 **Aucun résultat partiel n'apparaît ici** (`10_` §4.2) : ni score, ni
/// niveau. Le DTO ne les porte même pas — le résultat est le moment de
/// conversion, le diluer le détruit.
///
/// 🛑 **Aucun écran de passation n'est créé** : les sections QCM ouvrent le
/// runner existant, les productions la session EE/EO existante.
class TcfDiagnosticScreen extends ConsumerStatefulWidget {
  const TcfDiagnosticScreen({super.key});

  @override
  ConsumerState<TcfDiagnosticScreen> createState() => _TcfDiagnosticScreenState();
}

class _TcfDiagnosticScreenState extends ConsumerState<TcfDiagnosticScreen> {
  TcfDiagnosticDto? _diagnostic;
  bool _loading = true;
  bool _busy = false;
  String? _error;

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
    try {
      final courant = await ref.read(tcfDiagnosticRepositoryProvider).current();
      if (!mounted) return;
      setState(() {
        _diagnostic = courant;
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

  /// Ouvrir est idempotent côté serveur : un double appui ne coûte rien.
  Future<void> _ouvrir() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ouvert = await ref.read(tcfDiagnosticRepositoryProvider).open();
      if (!mounted) return;
      setState(() {
        _diagnostic = ouvert;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.toApiException(e).message;
        _busy = false;
      });
    }
  }

  /// Poser l'ancre du chrono **avant** d'ouvrir l'écran de passation : sans cet
  /// appel la section n'a aucune échéance. Idempotent — reprendre ne rend pas
  /// de temps au candidat.
  Future<void> _lancerSection(TcfDiagnosticSectionDto section) async {
    final d = _diagnostic;
    if (_busy || d == null || section.attemptId == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(tcfDiagnosticRepositoryProvider)
          .startSection(d.sessionId, section.epreuve);
      if (!mounted) return;
      setState(() => _busy = false);
      _ouvrirPassation(section);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.toApiException(e).message;
        _busy = false;
      });
    }
  }

  /// 🛑 Aucun écran de passation propre au diagnostic : on rejoint les parcours
  /// existants. Un second runner divergerait du premier.
  void _ouvrirPassation(TcfDiagnosticSectionDto section) {
    final id = section.attemptId!;
    switch (section.epreuve) {
      case EpreuveType.tcfCo:
      case EpreuveType.tcfCe:
        context.push('/runner/$id?from=tcfDiagnostic');
      case EpreuveType.tcfEe:
        context.push('/tcf/expression-ecrite/t/0?tcfDiagnosticAttempt=$id');
      case EpreuveType.tcfEo:
        context.push('/tcf/expression-orale/t/0?tcfDiagnosticAttempt=$id');
      default:
        break;
    }
  }

  Future<void> _voirResultat() async {
    final d = _diagnostic;
    if (_busy || d == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(tcfDiagnosticRepositoryProvider).result(d.sessionId);
      if (!mounted) return;
      setState(() => _busy = false);
      context.push('/diagnostic-tcf/${d.sessionId}/resultat');
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: kTcfDiagnosticTitle,
              sub: kTcfDiagnosticSubtitle,
              onBack: () => context.pop(),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErreurView(message: _error!, onRetry: _load);
    }
    final d = _diagnostic;
    return d == null ? _amorce() : _sections(d);
  }

  /// Aucun diagnostic ouvert : on montre ce qui attend, puis on propose.
  Widget _amorce() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in const [
                EpreuveType.tcfCo,
                EpreuveType.tcfCe,
                EpreuveType.tcfEe,
                EpreuveType.tcfEo,
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text(epreuvePresentation(e).icon,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Text(
                        epreuvePresentation(e).label,
                        style: AppFonts.ui(
                            size: 15, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(kTcfDiagnosticResultNote,
            style: AppFonts.ui(size: 13, color: AppColors.inkSoft)),
        const SizedBox(height: 16),
        AppButton(
          label: kTcfDiagnosticStartCta,
          onPressed: _busy ? null : _ouvrir,
          isLoading: _busy,
        ),
      ],
    );
  }

  Widget _sections(TcfDiagnosticDto d) {
    final jours = joursRestants(d.expiresAt);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(progressionLabel(d),
            style: AppFonts.label(size: 12, color: AppColors.inkFaint)),
        const SizedBox(height: 12),

        // 🛑 Le délai passé n'est PAS une perte : le message le dit.
        if (d.repriseEcoulee) ...[
          AppCard(
            color: AppColors.blueLight,
            child: Text(kTcfDiagnosticRepriseEcoulee,
                style: AppFonts.ui(size: 14, color: AppColors.blueDark)),
          ),
          const SizedBox(height: 12),
        ],

        for (final s in d.sections) ...[
          _SectionCard(
            section: s,
            busy: _busy,
            onStart: () => _lancerSection(s),
          ),
          const SizedBox(height: 10),
        ],

        const SizedBox(height: 4),
        Text(kTcfDiagnosticResultNote,
            style: AppFonts.ui(size: 13, color: AppColors.inkSoft)),
        const SizedBox(height: 16),

        if (resultatDisponible(d) || d.repriseEcoulee)
          AppButton(
            label: kTcfDiagnosticResultCta,
            onPressed: _busy ? null : _voirResultat,
            isLoading: _busy,
          )
        else if (jours > 0)
          Text(
            'Vous avez $jours jour${jours > 1 ? 's' : ''} pour terminer.',
            style: AppFonts.ui(size: 13, color: AppColors.inkSoft),
          ),

        const SizedBox(height: 16),
        Text(kTcfDiagnosticEstimationNote,
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 12, color: AppColors.inkFaint)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.busy,
    required this.onStart,
  });

  final TcfDiagnosticSectionDto section;
  final bool busy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final p = epreuvePresentation(section.epreuve);
    final terminee = section.etat == TcfDiagnosticSectionState.terminee;
    // Section absente du diagnostic : elle se présente « non évaluée », jamais
    // comme un manque de contenu (`00_` §7.4).
    final indisponible = sectionIndisponible(section);

    return AppCard(
      color: terminee
          ? AppColors.green.withValues(alpha: 0.06)
          : AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(p.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.label,
                        style: AppFonts.ui(
                            size: 15,
                            weight: FontWeight.w600,
                            color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(
                      _meta(),
                      style: AppFonts.ui(
                            size: 12, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              AppTag(
                label: sectionEtatLabel(section.etat),
                tone: terminee ? TagTone.success : TagTone.neutral,
                compact: true,
              ),
            ],
          ),
          if (indisponible) ...[
            const SizedBox(height: 8),
            Text(kNiveauNonEvalue,
                style: AppFonts.ui(size: 12, color: AppColors.inkFaint)),
          ] else if (!terminee) ...[
            const SizedBox(height: 10),
            Text(
              section.epreuve == EpreuveType.tcfEo
                  ? '$kTcfDiagnosticSectionWarning $kTcfDiagnosticMicWarning'
                  : kTcfDiagnosticSectionWarning,
              style: AppFonts.ui(size: 12, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: sectionCtaLabel(section.etat),
              onPressed: busy ? null : onStart,
              variant: AppButtonVariant.soft,
              height: 44,
            ),
          ],
        ],
      ),
    );
  }

  String _meta() {
    final volume = section.totalQuestions != null
        ? '${section.totalQuestions} questions'
        : '3 tâches';
    // L'oral ne s'annonce pas en minutes d'épreuve : il se chronomètre par
    // tâche, comme dans l'examen complet.
    final duree = section.epreuve == EpreuveType.tcfEo
        ? 'Chronométré par tâche'
        : section.timeLimitSeconds != null
            ? '${(section.timeLimitSeconds! / 60).round()} min'
            : '—';
    return '$volume · $duree';
  }
}

class _ErreurView extends StatelessWidget {
  const _ErreurView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.circleAlert, color: AppColors.red, size: 32),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 14, color: AppColors.ink)),
          const SizedBox(height: 16),
          AppButton(
            label: 'Réessayer',
            onPressed: onRetry,
            variant: AppButtonVariant.outline,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
