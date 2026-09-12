import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/paywall_context.dart';

/// Onboarding (ou édition depuis le profil) du parcours administratif.
///
/// ## Deux questions, deux écrans (2026-09-12)
///
/// ⚠️ Les deux vivaient sur **une seule page** : la démarche, puis un encart
/// rouge, puis la date. Le candidat arrivait sur un formulaire à faire défiler
/// au moment précis où on lui demande de se décider. Demande du propriétaire :
/// **une question par écran** — la démarche, puis la date d'examen.
///
/// 🛑 **Rien n'est enregistré avant la fin.** Les deux réponses partent
/// ensemble à l'étape 2 : un candidat qui abandonne en route ne laisse pas une
/// démarche à demi déclarée.
///
/// 🛑 **Route serveur SÉPARÉE pour la date** : loger la date dans la mise à
/// jour de la procédure l'effacerait à chaque changement de celle-ci. Et son
/// échec est **best-effort** — il ne fait pas échouer le choix de démarche, qui
/// est le vrai objet de cet écran.
class TargetPathScreen extends ConsumerStatefulWidget {
  const TargetPathScreen({super.key});

  @override
  ConsumerState<TargetPathScreen> createState() => _TargetPathScreenState();
}

class _TargetPathScreenState extends ConsumerState<TargetPathScreen> {
  TargetProcedure? _selected;

  /// La date d'examen (`10_` §3.2, question 3) — **facultative**, et c'est le
  /// point : « Pas encore » est une réponse, pas un formulaire incomplet.
  ///
  /// Sans elle, le compte à rebours et le pass recommandé du paywall (L5) ne
  /// s'affichent jamais.
  DateTime? _examDate;

  /// L'étape affichée : 0 la démarche, 1 la date.
  int _etape = 0;

  bool _saving = false;
  String? _error;

  /// Route d'origine, lue dans le query param `?from=...`. Vide si l'écran
  /// est ouvert en mode onboarding (juste après création de compte).
  String? _fromRoute;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    if (auth is AuthAuthenticated) {
      _selected = auth.user.targetProcedure;
      _examDate = auth.user.examDate;
    }
  }

  Future<void> _submit() async {
    final choice = _selected;
    if (choice == null) return;
    final from = _fromRoute;
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final repository = ref.read(userContentRepositoryProvider);
      await repository.updateTargetPath(choice);
      // Best-effort et à part : un échec sur la date ne doit pas faire échouer
      // le choix de démarche, qui est le vrai objet de cet écran.
      await repository.updateExamDate(_examDate).catchError((_) {});
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (!mounted) return;
      // Navigation explicite via `go` : plus fiable que `pop` après un
      // refresh du state d'auth (qui peut perturber la back stack).
      context.go(from ?? AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiClient.toApiException(e).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Le retour : à l'étape 2 il ramène à la question précédente, jamais hors de
  /// l'écran — sinon le candidat perdrait le choix qu'il vient de faire.
  void _retour() {
    if (_etape > 0) {
      setState(() => _etape = 0);
      return;
    }
    final from = _fromRoute;
    if (from != null) context.go(from);
  }

  @override
  Widget build(BuildContext context) {
    // Capture une seule fois la route d'origine passée par le call-site.
    _fromRoute ??= safePostLoginDestination(
      GoRouterState.of(context).uri.queryParameters['from'],
    );
    final peutRevenir = _fromRoute != null || _etape > 0;

    return PopScope(
      // Le geste de retour système suit la flèche : il recule d'une étape.
      canPop: _etape == 0 && _fromRoute == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _etape > 0) setState(() => _etape = 0);
      },
      child: Scaffold(
        appBar: peutRevenir
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, size: 18),
                  onPressed: _retour,
                ),
              )
            : null,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: _etape == 0 ? _etapeDemarche() : _etapeDate(),
          ),
        ),
      ),
    );
  }

  /* ------------------------------------------------------ 1. la démarche --- */

  List<Widget> _etapeDemarche() => [
        const Eyebrow('Étape 1 sur 2'),
        const SizedBox(height: 8),
        Text(
          'Quelle démarche préparez-vous ?',
          style: AppFonts.display(size: 28, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Nous adapterons votre entraînement en fonction de votre objectif. '
          'Vous pourrez toujours modifier ce choix depuis votre profil.',
          style: AppFonts.ui(size: 13.5, color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 24),
        for (final p in TargetProcedure.values) ...[
          _PathCard(
            procedure: p,
            selected: _selected == p,
            onTap: () => setState(() => _selected = p),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        AppButton(
          label: 'Continuer',
          onPressed:
              _selected == null ? null : () => setState(() => _etape = 1),
        ),
      ];

  /* ---------------------------------------------------------- 2. la date --- */

  List<Widget> _etapeDate() => [
        const Eyebrow('Étape 2 sur 2'),
        const SizedBox(height: 8),
        Text(
          'Quand passez-vous votre examen ?',
          style: AppFonts.display(size: 28, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Si vous connaissez déjà la date, votre plan s\'organise autour '
          'd\'elle. Sinon, passez cette étape — vous pourrez la renseigner plus '
          'tard depuis votre profil.',
          style: AppFonts.ui(size: 13.5, color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 24),
        _ExamDateCard(
          value: _examDate,
          onPick: (picked) => setState(() => _examDate = picked),
          onClear: () => setState(() => _examDate = null),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.redLight,
              border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              _error!,
              style: AppFonts.ui(color: AppColors.red, size: 13),
            ),
          ),
        ],
        const SizedBox(height: 20),
        AppButton(
          // 🛑 La date est **facultative** : le bouton reste actif sans elle.
          // Ce qu'il dit change, pas ce qu'il permet.
          label: _examDate == null ? 'Je n\'ai pas encore de date' : 'Terminer',
          onPressed: _saving ? null : _submit,
          isLoading: _saving,
        ),
      ];
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.procedure,
    required this.selected,
    required this.onTap,
  });

  final TargetProcedure procedure;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      border: Border.all(
        color: selected ? AppColors.blue : AppColors.line,
        width: selected ? 1.5 : 1,
      ),
      color: selected ? AppColors.blueSoft : AppColors.white,
      child: Row(
        children: [
          AppTag(label: procedure.wire, tone: TagTone.blue),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  procedure.fullLabel,
                  style: AppFonts.ui(size: 15, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Niveau TCF requis : ${procedure.tcfLevel}',
                  style: AppFonts.ui(size: 12.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (selected)
            const Icon(LucideIcons.circleCheck, color: AppColors.blue, size: 24)
          else
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line2, width: 2),
              ),
            ),
        ],
      ),
    );
  }
}

/// La date d'examen — **la carte de l'étape 2**, pas un champ de formulaire.
///
/// 🛑 **Un jour, jamais un instant.** Une convocation porte une date ; la
/// stocker avec une heure la ferait basculer d'un fuseau à l'autre.
///
/// 🛑 **Aucun raccourci du type « dans 2 mois ».** Ce serait plus rapide, mais
/// on enregistrerait une date **inventée** — et elle ressortirait telle quelle
/// en « Objectif B2 avant le 12 novembre » sur le paywall. Le sélecteur est le
/// seul chemin, et « pas encore de date » est une vraie réponse.
///
/// Le décompte, lui, est **dérivé** de la date réelle par [joursAvantExamen],
/// l'autorité déjà employée par le paywall : deux calculs auraient fini par
/// annoncer deux nombres de jours.
class _ExamDateCard extends StatelessWidget {
  const _ExamDateCard({
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  Future<void> _choisir(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now.add(const Duration(days: 60)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
      helpText: 'Date de votre examen',
      confirmText: 'Valider',
      cancelText: 'Annuler',
    );
    if (picked != null) onPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    final d = value;
    final jours = joursAvantExamen(d);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          color: d == null ? AppColors.white : AppColors.blueSoft,
          border: Border.all(
            color: d == null ? AppColors.line : AppColors.blueLight,
            width: d == null ? 1 : 1.5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: d == null ? AppColors.surface2 : AppColors.blue,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(
                      LucideIcons.calendarDays,
                      size: 24,
                      color: d == null ? AppColors.muted : AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d == null ? 'Pas encore de date' : formatJour(d),
                          style: AppFonts.display(
                            size: d == null ? 18 : 22,
                            weight: FontWeight.w700,
                            color: d == null ? AppColors.muted : AppColors.ink,
                          ),
                        ),
                        if (d != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${d.year}',
                            style: AppFonts.ui(
                                size: 13, color: AppColors.inkSoft),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Le décompte : un fait, pas une pression. Il n'apparaît que
              // quand une date réelle est posée.
              if (jours != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.hourglass,
                          size: 15, color: AppColors.blue),
                      const SizedBox(width: 8),
                      Text(
                        jours == 0
                            ? 'C\'est aujourd\'hui'
                            : 'Dans $jours jour${jours > 1 ? 's' : ''}',
                        style: AppFonts.ui(
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppColors.blueDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: d == null ? 'Choisir la date' : 'Modifier la date',
          variant: AppButtonVariant.outline,
          iconRight: LucideIcons.calendarDays,
          onPressed: () => _choisir(context),
        ),
        if (d != null)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: onClear,
              child: Text(
                'Je ne connais pas encore ma date',
                style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
