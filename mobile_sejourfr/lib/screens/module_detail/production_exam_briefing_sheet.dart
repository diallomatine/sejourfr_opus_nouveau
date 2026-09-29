import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../tcf_production/production_catalog.dart';
import '../tcf_production/production_exam_copy.dart';
import '../tcf_production/tcf_production_module.dart' show TcfProductionModule;

/// La **feuille d'information d'un examen blanc EE/EO** (3 tâches
/// enchaînées), avant tout démarrage. Miroir brique pour brique de
/// `ProductionExamBriefingSheet` côté web.
///
/// 🛑 **Rien n'est démarré tant qu'elle est ouverte** : la session — donc
/// `startedAt`, l'ancre du chrono servi — ne naît qu'au tap « Commencer
/// maintenant ». Elle ne s'ouvre que par `launchProductionExam`, le lanceur
/// unique des examens blancs EE/EO.
///
/// Les phrases vivent dans `production_exam_copy.dart` (miroir mot pour mot
/// du web). La contrainte de chaque tâche (« 30-60 mots », « 3 min ») est lue
/// sur les sujets **servis** du catalogue de l'épreuve ; tant qu'ils ne sont
/// pas là, la ligne s'affiche sans elle — jamais un chiffre de repli.
class ProductionExamBriefingSheet extends ConsumerStatefulWidget {
  const ProductionExamBriefingSheet({
    super.key,
    required this.module,
    required this.onStart,
  });

  final TcfProductionModule module;

  /// Démarre la session. La feuille reste ouverte, bouton en attente, tant
  /// que le démarrage n'a pas rendu la main : c'est au lanceur de la fermer.
  final Future<void> Function() onStart;

  @override
  ConsumerState<ProductionExamBriefingSheet> createState() =>
      _ProductionExamBriefingSheetState();
}

class _ProductionExamBriefingSheetState
    extends ConsumerState<ProductionExamBriefingSheet> {
  bool _starting = false;

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    await widget.onStart();
    if (mounted) setState(() => _starting = false);
  }

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final epreuve = module.epreuve;
    final durationLabel = module.durationLabel;
    final tasks =
        ref.watch(productionCatalogProvider(epreuve)).valueOrNull?.tasks;

    return PopScope(
      canPop: !_starting,
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            productionExamBriefingEyebrow(module.title)
                                .toUpperCase(),
                            style: AppFonts.label(
                              size: 9.5,
                              color: AppColors.muted,
                            ).copyWith(letterSpacing: 1.8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _DurationBadge(label: durationLabel),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Hero(
                      icon: module.icon,
                      title: productionExamBriefingTitle(epreuve),
                      description:
                          productionExamBriefingIntro(epreuve, durationLabel),
                    ),
                    const SizedBox(height: 16),
                    _TasksCard(
                      rows: [
                        for (final n in const [1, 2, 3])
                          (
                            index: n,
                            title: 'Tâche $n · ${productionTaskTitle(epreuve, n)}',
                            detail: productionExamTaskDetail(
                              epreuve,
                              n,
                              productionExamTaskConstraint(tasks, epreuve, n),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ConseilCard(text: productionExamBriefingConseil(epreuve)),
                    const SizedBox(height: 22),
                    AppButton(
                      label: kProductionExamBriefingStart,
                      icon: LucideIcons.play,
                      variant: AppButtonVariant.danger,
                      isLoading: _starting,
                      onPressed: _starting ? null : _start,
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: kProductionExamBriefingCancel,
                      variant: AppButtonVariant.ghost,
                      onPressed:
                          _starting ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _TaskRowData = ({int index, String title, String detail});

class _Hero extends StatelessWidget {
  const _Hero({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue, AppColors.blueDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 30, color: AppColors.white),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppFonts.ui(
              size: 22,
              weight: FontWeight.w800,
              color: AppColors.white,
              height: 1.15,
            ).copyWith(letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppFonts.ui(
              size: 13.5,
              color: AppColors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  const _DurationBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.timer, size: 13, color: AppColors.blue),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppFonts.ui(
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksCard extends StatelessWidget {
  const _TasksCard({required this.rows});

  final List<_TaskRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kProductionExamBriefingDeroule.toUpperCase(),
            style: AppFonts.label(size: 9.5, color: AppColors.muted)
                .copyWith(letterSpacing: 1.8),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < rows.length; i++) ...[
            _TaskRow(row: rows[i]),
            if (i != rows.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.row});

  final _TaskRowData row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '${row.index}',
              style: AppFonts.ui(
                size: 12,
                weight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: AppFonts.ui(
                    size: 13.5,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                if (row.detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    row.detail,
                    style: AppFonts.ui(size: 12, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConseilCard extends StatelessWidget {
  const _ConseilCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.lightbulb,
                size: 14,
                color: AppColors.amberDark,
              ),
              const SizedBox(width: 6),
              Text(
                kProductionExamBriefingConseil.toUpperCase(),
                style: AppFonts.label(size: 9.5, color: AppColors.amberDark)
                    .copyWith(letterSpacing: 1.8),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppFonts.ui(
              size: 13,
              color: AppColors.ink2,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
