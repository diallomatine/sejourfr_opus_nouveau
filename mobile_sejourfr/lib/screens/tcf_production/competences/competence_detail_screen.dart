import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/skill_models.dart';
import '../../../core/router/route_observer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/fixed_action_bar.dart';
import '../../../core/widgets/progress_track.dart';
import '../../../core/widgets/screen_header.dart';
import '../widgets/exam_filter_chips.dart';
import '../tcf_production_module.dart';
import 'competences_nav.dart';
import 'competences_providers.dart';
import '../widgets/production_blocks.dart';
import '../widgets/production_state_views.dart';
import 'widgets/skill_prompt_card.dart';

/// Détail d'une compétence : carte de résumé, progression en sujets traités,
/// filtres, puis la liste des petits sujets avec leur statut.
class CompetenceDetailScreen extends ConsumerStatefulWidget {
  const CompetenceDetailScreen({
    super.key,
    required this.module,
    required this.skillId,
  });

  final TcfProductionModule module;
  final String skillId;

  @override
  ConsumerState<CompetenceDetailScreen> createState() =>
      _CompetenceDetailScreenState();
}

class _CompetenceDetailScreenState
    extends ConsumerState<CompetenceDetailScreen> with RouteAware {
  /// 0 = Tous · 1 = À faire · 2 = Traités
  int _filter = 0;

  Color get _accent => widget.module.accent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Retour depuis un petit sujet : son statut vient de changer (§13.3 — le
  /// sujet doit passer « traité » immédiatement).
  @override
  void didPopNext() {
    ref.invalidate(skillDetailProvider(widget.skillId));
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/tcf/${widget.module.routeKey}');
  }

  void _openPrompt(SkillPromptSummary prompt) {
    context.push(
      competencePromptPath(widget.module, widget.skillId, prompt.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(skillDetailProvider(widget.skillId));
    final detail = async.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: detail?.skill.title ?? 'Compétence',
              sub: detail == null
                  ? widget.module.title
                  : '${detail.skill.code} · ${widget.module.title}',
              onBack: _back,
            ), /// Diallo
            Expanded(
              child: async.when(
                skipLoadingOnReload: true,
                loading: () =>
                    Center(child: CircularProgressIndicator(color: _accent)),
                error: (e, _) => ProductionErrorView(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () =>
                      ref.invalidate(skillDetailProvider(widget.skillId)),
                ),
                data: _list,
              ),
            ),
            if (detail != null && detail.prompts.isNotEmpty)
              FixedActionBar(child: _primaryAction(detail)),
          ],
        ),
      ),
    );
  }

  Widget _primaryAction(SkillDetail detail) {
    final todo = detail.firstTodo;
    final target = todo ?? detail.prompts.first;
    return AppButton(
      label: todo != null ? 'Commencer le premier sujet' : 'Refaire un sujet',
      icon: todo != null ? LucideIcons.play : LucideIcons.refreshCw,
      variant: widget.module.isEo
          ? AppButtonVariant.accent
          : AppButtonVariant.primary,
      onPressed: () => _openPrompt(target),
    );
  }

  Widget _list(SkillDetail detail) {
    final prompts = detail.prompts;
    if (prompts.isEmpty) {
      return const ProductionEmptyView(
        description: 'Les sujets de cette compétence ne sont pas encore prêts.',
      );
    }

    final treated = prompts.where((p) => p.status.isTreated).length;
    final todo = prompts.length - treated;
    final visible = prompts.where((p) {
      if (_filter == 1) return !p.status.isTreated;
      if (_filter == 2) return p.status.isTreated;
      return true;
    }).toList();

    return RefreshIndicator(
      color: _accent,
      onRefresh: () async {
        ref.invalidate(skillDetailProvider(widget.skillId));
        await ref.read(skillDetailProvider(widget.skillId).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SummaryCard(
            skill: detail.skill,
            accent: _accent,
            treated: treated,
            icon: widget.module.icon,
          ),
          const SizedBox(height: 21),
          const ProductionSectionHead(
            title: 'Petits sujets',
            description: 'Les sujets déjà réalisés restent clairement '
                'identifiables.',
          ),
          const SizedBox(height: 11),
          ExamFilterChips(
            active: _filter,
            accent: _accent,
            labels: [
              'Tous · ${prompts.length}',
              'À faire · $todo',
              'Traités · $treated',
            ],
            onChanged: (i) => setState(() => _filter = i),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                _filter == 1
                    ? 'Tous les sujets de cette compétence ont été traités.'
                    : 'Aucun sujet traité pour le moment.',
                textAlign: TextAlign.center,
                style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft),
              ),
            )
          else
            for (final prompt in visible) ...[
              SkillPromptCard(
                prompt: prompt,
                accent: _accent,
                onTap: () => _openPrompt(prompt),
              ),
              const SizedBox(height: 11),
            ],
        ],
      ),
    );
  }
}

/// Carte de résumé de la compétence (`.skill-summary` du prototype) : icône
/// 48×48 en tête, pilule de palier, titre, puis l'encart « Critère travaillé »
/// et la progression en sujets traités.
///
/// L'explication de la compétence (`skill.description`) ne vit **pas** dans le
/// corps de la carte : six lignes de texte y repoussaient le critère et la
/// liste des sujets. Elle est derrière la pastille d'information en haut à
/// droite, qui disparaît quand il n'y a rien à expliquer.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.skill,
    required this.accent,
    required this.treated,
    required this.icon,
  });

  final SkillDto skill;
  final Color accent;
  final int treated;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 23, color: accent),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.title,
                      style: AppFonts.display(size: 19, height: 1.2),
                    ),
                  ],
                ),
              ),
              // Deux textes, deux endroits : l'explication dit à quoi la
              // compétence sert au TCF (ici, à la demande), le critère général
              // dit ce qui est travaillé (dans la carte, toujours visible).
              if (skill.description.trim().isNotEmpty)
                _SkillInfoButton(
                  title: skill.title,
                  description: skill.description,
                  accent: accent,
                ),
            ],
          ),
          if (skill.generalCriterion.trim().isNotEmpty) ...[
            const SizedBox(height: 13),
            _CriterionBox(criterion: skill.generalCriterion),
          ],
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: ProgressTrack(
                  value: skill.promptCount == 0
                      ? 0
                      : treated / skill.promptCount * 100,
                  color: accent,
                  height: 5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$treated/${skill.promptCount} traités',
                style: AppFonts.ui(
                  size: 11,
                  weight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
              ),
              if (skill.validatedCount > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '${skill.validatedCount} ✓',
                  style: AppFonts.ui(
                    size: 11,
                    weight: FontWeight.w800,
                    color: AppColors.green,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Pastille d'information de la carte de résumé : ouvre l'explication de la
/// compétence dans une feuille. Visuel discret (30×30) mais zone tactile de
/// 44×44 — la cible minimale, pas la taille du dessin.
class _SkillInfoButton extends StatelessWidget {
  const _SkillInfoButton({
    required this.title,
    required this.description,
    required this.accent,
  });

  static const String _label = 'À quoi sert cette compétence ?';

  final String title;
  final String description;
  final Color accent;

  void _open(BuildContext context) {
    showAppSheet<void>(
      context,
      icon: LucideIcons.info,
      iconBg: accent.withValues(alpha: 0.10),
      iconColor: accent,
      title: title,
      children: [
        Text(
          description,
          style: AppFonts.ui(
            size: 13.5,
            color: AppColors.inkSoft,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _label,
      child: Tooltip(
        message: _label,
        child: InkWell(
          onTap: () => _open(context),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line),
                ),
                child: Icon(
                  LucideIcons.info,
                  size: 15,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.criterion-box` du prototype : encadré gris neutre, label en petites
/// capitales, critère en 13.
class _CriterionBox extends StatelessWidget {
  const _CriterionBox({required this.criterion});

  final String criterion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CRITÈRE TRAVAILLÉ',
            style: AppFonts.label(size: 10, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 5),
          Text(criterion, style: AppFonts.ui(size: 13, height: 1.4)),
        ],
      ),
    );
  }
}
