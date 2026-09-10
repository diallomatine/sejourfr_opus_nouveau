import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/civic_diagnostic_models.dart';
import '../../core/models/tcf_diagnostic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/screen_header.dart';
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
class CivicDiagnosticScreen extends ConsumerStatefulWidget {
  const CivicDiagnosticScreen({super.key});

  @override
  ConsumerState<CivicDiagnosticScreen> createState() =>
      _CivicDiagnosticScreenState();
}

class _CivicDiagnosticScreenState extends ConsumerState<CivicDiagnosticScreen> {
  CivicDiagnosticDto? _diagnostic;
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
      final courant =
          await ref.read(civicDiagnosticRepositoryProvider).current();
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

  /// Ouvrir est idempotent côté serveur : un double appui ne retire pas.
  Future<void> _ouvrir() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ouvert = await ref.read(civicDiagnosticRepositoryProvider).open();
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

  Future<void> _voirResultat(String sessionId) async {
    if (_busy) return;
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
    final termine = d?.status == TcfDiagnosticStatus.completed;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
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
      ],
    );
  }
}
