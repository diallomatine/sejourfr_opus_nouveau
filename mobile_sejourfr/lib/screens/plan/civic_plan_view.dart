import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/repositories.dart';
import '../../core/models/civic_plan_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/start_failure.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/premium_lock.dart';
import 'civic_plan_labels.dart';

/// **Le plan civique** (L10, `20_` §6).
///
/// ⚠️ **Révoque le panneau précédent**, qui recopiait les priorités *figées* du
/// dernier diagnostic. Le plan est maintenant un **moteur** : il relit tout
/// l'historique des réponses à chaque lecture, y compris celles des séries et
/// des examens blancs (`20_` §8.2), et il dit **quand y revenir**.
///
/// 🛑 **Rien n'est dérivé ici.** L'ordre des cibles, leur état de maîtrise, leur
/// échéance et leur verrou arrivent **servis**. Cet écran les met en mots
/// (`civic_plan_labels.dart`) et ouvre ce qui existe déjà.
///
/// 🛑 **Le plan travaille au grain que le tagging permet**, et il le dit
/// (`20_` §3.3) : thème par thème tant que les questions ne sont pas taguées,
/// notion par notion ensuite. Ce n'est pas une panne, c'est la phase 1 de la
/// spec.
///
/// 🛑 **Le constat est intégralement gratuit.** Le `locked` servi porte sur la
/// **série**, jamais sur ce que le candidat a mesuré : un compte gratuit voit
/// ses priorités entières, avec leurs états et leurs compteurs.
class CivicPlanView extends ConsumerStatefulWidget {
  const CivicPlanView({super.key});

  @override
  ConsumerState<CivicPlanView> createState() => _CivicPlanViewState();
}

class _CivicPlanViewState extends ConsumerState<CivicPlanView> {
  CivicPlan? _plan;
  bool _loading = true;
  String? _enCours;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final plan = await ref.read(civicPlanRepositoryProvider).plan();
      if (mounted) {
        setState(() {
          _plan = plan;
          _loading = false;
        });
      }
    } catch (_) {
      // Best-effort : l'onglet reste sobre. Le constat existe déjà côté
      // diagnostic, on ne remplace pas un plan par une erreur.
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Ouvre la série ciblée.
  ///
  /// 🛑 Le **403** est un refus attendu — le verrou du serveur et le `locked`
  /// servi sont la même règle — et il ouvre l'offre, jamais un message d'erreur
  /// technique (`showPaywallOrError`).
  Future<void> _commencer(CivicPlanCible cible) async {
    if (_enCours != null) return;
    if (cible.locked) {
      unawaited(showPaywallSheet(context));
      return;
    }
    setState(() => _enCours = cible.id);
    try {
      final attempt = await ref
          .read(civicPlanRepositoryProvider)
          .serie(cible.id, cible.grain);
      if (!mounted) return;
      setState(() => _enCours = null);
      context.push('/runner/${attempt.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _enCours = null);
      showPaywallOrError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final plan = _plan;
    if (plan == null || !plan.disponible) return const SizedBox.shrink();

    final grainNote = civicPlanGrainNote(plan.grain);
    final autres = civicPlanAutresLabel(plan);
    final maintenant = DateTime.now();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // 1 — l'objectif. 🛑 Le seuil est SERVI : l'écran le dit sans le
          // connaître, et il ne promet jamais la réussite.
          if (plan.resultat != null) ...[
            _Objectif(resultat: plan.resultat!),
            const SizedBox(height: 16),
          ],

          if (plan.prochaine != null) ...[
            _MaintenantCard(
              cible: plan.prochaine!,
              busy: _enCours == plan.prochaine!.id,
              onStart: () => unawaited(_commencer(plan.prochaine!)),
            ),
            const SizedBox(height: 20),
            Text(kCivicPlanPrioritiesTitle,
                style: AppFonts.display(size: 20, color: AppColors.ink)),
            const SizedBox(height: 10),
            for (var i = 0; i < plan.priorites.length; i++) ...[
              _PrioriteRow(
                rang: i + 1,
                cible: plan.priorites[i],
                busy: _enCours == plan.priorites[i].id,
                onStart: () => unawaited(_commencer(plan.priorites[i])),
              ),
              const SizedBox(height: 10),
            ],
            if (autres != null)
              Text(autres,
                  style: AppFonts.ui(
                      size: 12.5, color: AppColors.inkFaint, height: 1.5)),
          ] else
            _RienDePrioritaire(),

          // 5 — révision d'entretien. 🛑 Secondaire, et JAMAIS présentée comme
          // une alerte : ce sont des points acquis qu'on entretient.
          if (plan.aRevoir.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(kCivicPlanReviewTitle,
                style: AppFonts.display(size: 20, color: AppColors.ink)),
            const SizedBox(height: 8),
            for (final cible in plan.aRevoir)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(cible.label,
                          style: AppFonts.ui(size: 14, color: AppColors.ink)),
                    ),
                    Text(civicRevueLabel(cible, maintenant) ?? '',
                        style: AppFonts.ui(
                            size: 12.5, color: AppColors.inkFaint)),
                  ],
                ),
              ),
          ],

          // 6 — ce qui est acquis. Le candidat n'a pas besoin de tout réviser.
          if (plan.solides.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(kCivicPlanSolidTitle,
                style: AppFonts.display(size: 20, color: AppColors.ink)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cible in plan.solides)
                  _SolidePill(label: cible.label, themeId: cible.themeId),
              ],
            ),
          ],

          if (grainNote != null) ...[
            const SizedBox(height: 20),
            Text(grainNote,
                style: AppFonts.ui(
                    size: 12, color: AppColors.inkFaint, height: 1.5)),
          ],
        ],
      ),
    );
  }
}

class _Objectif extends StatelessWidget {
  const _Objectif({required this.resultat});

  final CivicPlanResultat resultat;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kCivicPlanResultTitle.toUpperCase(),
              style: AppFonts.label(size: 11, color: AppColors.inkFaint)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${resultat.bonnes}',
                  style: AppFonts.display(size: 32, color: AppColors.blue)),
              Text(' / ${resultat.posees}',
                  style: AppFonts.display(size: 22, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$kCivicPlanResultSeuil : ${resultat.seuil} / ${resultat.format}',
            style: AppFonts.ui(size: 13, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// Bloc 2 — « À faire maintenant », le bloc dominant de l'écran.
class _MaintenantCard extends StatelessWidget {
  const _MaintenantCard({
    required this.cible,
    required this.busy,
    required this.onStart,
  });

  final CivicPlanCible cible;
  final bool busy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.blueLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kCivicPlanNowTitle.toUpperCase(),
              style: AppFonts.label(size: 11, color: AppColors.blueDark)),
          const SizedBox(height: 8),
          Text(cible.themeLabel,
              style: AppFonts.ui(size: 12.5, color: AppColors.blueDark)),
          const SizedBox(height: 2),
          Text(cible.label, style: AppFonts.display(size: 21)),
          const SizedBox(height: 6),
          Text(civicPlanRaison(cible),
              style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft)),
          const SizedBox(height: 2),
          Text(civicSerieLabel(cible),
              style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft)),
          const SizedBox(height: 14),
          AppButton(
            label: cible.locked ? kCivicPlanLockedCta : kCivicPlanNowCta,
            iconRight: cible.locked ? LucideIcons.lock : LucideIcons.arrowRight,
            isLoading: busy,
            onPressed: busy ? null : onStart,
          ),
          if (cible.locked) ...[
            const SizedBox(height: 10),
            Text(kCivicPlanLockedNote,
                style: AppFonts.ui(
                    size: 12, color: AppColors.inkFaint, height: 1.5)),
          ],
        ],
      ),
    );
  }
}

/// Une ligne de priorité. 🛑 Le constat est **entier** même verrouillé : seul le
/// geste porte le cadenas.
class _PrioriteRow extends StatelessWidget {
  const _PrioriteRow({
    required this.rang,
    required this.cible,
    required this.busy,
    required this.onStart,
  });

  final int rang;
  final CivicPlanCible cible;
  final bool busy;
  final VoidCallback onStart;

  static Color _tone(CivicCibleTone tone) => switch (tone) {
        CivicCibleTone.hot => AppColors.red,
        CivicCibleTone.warn => AppColors.amber,
        CivicCibleTone.ok => AppColors.green,
        CivicCibleTone.muted => AppColors.line,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: busy ? null : onStart,
      border: Border(
        left: BorderSide(color: _tone(civicCibleTone(cible)), width: 4),
        top: const BorderSide(color: AppColors.line),
        right: const BorderSide(color: AppColors.line),
        bottom: const BorderSide(color: AppColors.line),
      ),
      child: Row(
        children: [
          Text('$rang',
              style: AppFonts.label(size: 13, color: AppColors.inkFaint)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cible.label,
                    style: AppFonts.ui(size: 15, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(
                  '${cible.themeLabel} · ${cible.maitrise.label} · '
                  '${civicPlanRaison(cible)}',
                  style: AppFonts.ui(
                      size: 12, color: AppColors.inkFaint, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (cible.locked)
            const PremiumLockPill()
          else
            Text(kCivicPlanWorkCta,
                style: AppFonts.ui(
                    size: 13.5,
                    weight: FontWeight.w600,
                    color: AppColors.blue)),
        ],
      ),
    );
  }
}

class _SolidePill extends StatelessWidget {
  const _SolidePill({required this.label, required this.themeId});

  final String label;
  final String themeId;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/civique/theme/$themeId'),
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text('✅ $label',
            style: AppFonts.ui(size: 13.5, color: AppColors.ink)),
      ),
    );
  }
}

/// 🛑 Aucune priorité est une BONNE nouvelle, pas un écran vide.
class _RienDePrioritaire extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Text(kCivicPlanAllGoodTitle,
            textAlign: TextAlign.center,
            style: AppFonts.display(size: 22, color: AppColors.ink)),
        const SizedBox(height: 10),
        Text(kCivicPlanAllGoodText,
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 14, color: AppColors.inkSoft, height: 1.55)),
        const SizedBox(height: 20),
        AppButton(
          label: 'Faire un examen blanc',
          onPressed: () => context.push(AppRoutes.civiqueExamsBlanc),
        ),
      ],
    );
  }
}
