import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/epreuve_duration.dart';
import '../../core/widgets/app_button.dart';

/// Briefing avant le démarrage d'un examen blanc TCF complet (les 4 épreuves).
/// Bottomsheet modal dans la palette stricte bleu / blanc / rouge SejourFR.
///
/// 🛑 **Il n'y a plus d'enveloppe globale de 90 min.** Chaque épreuve porte son
/// propre chrono, rien ne se transfère de l'une à l'autre et l'abandon-reprise
/// entre épreuves est officiellement supporté. Le total annoncé (~95 min) est un
/// **ordre de grandeur**, pas un décompte — et les durées viennent de
/// [kEpreuveDurationSeconds], jamais d'un chiffre écrit dans cet écran (c'est
/// exactement ici que la CE affichait 30 min alors qu'elle en vaut 35).
class TcfFullExamBriefingSheet extends StatelessWidget {
  const TcfFullExamBriefingSheet({
    super.key,
    required this.slot,
    required this.onStart,
    this.isFreeAccount = false,
  });

  /// Numéro 1-20 du slot d'examen choisi — affiché dans le header pour le
  /// repérage. Les questions/sujets restent tirés aléatoirement côté backend.
  final int slot;
  final VoidCallback onStart;

  /// Compte sans abonnement TCF : rappelle que l'EE/EO n'est offerte qu'une fois.
  final bool isFreeAccount;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
                      Text(
                        'EXAMEN BLANC $slot',
                        style: AppFonts.mono(
                          size: 9.5,
                          color: AppColors.muted,
                          letterSpacing: 1.8,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _DurationBadge(
                        label: '≈ '
                            '${epreuveDurationLabel(kExamenCompletSecondes) ?? ''}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _Hero(),
                  const SizedBox(height: 16),
                  _DerouleCard(),
                  const SizedBox(height: 12),
                  const _ASavoirCard(),
                  if (isFreeAccount) ...[
                    const SizedBox(height: 12),
                    const _FreeNoteCard(),
                  ],
                  const SizedBox(height: 22),
                  AppButton(
                    label: 'Lancer l\'examen blanc',
                    icon: LucideIcons.play,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onStart();
                    },
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Annuler',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper : ouvre le briefing en bottomsheet modal.
void showTcfFullExamBriefingSheet(
  BuildContext context, {
  required int slot,
  required VoidCallback onStart,
  bool isFreeAccount = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TcfFullExamBriefingSheet(
      slot: slot,
      onStart: onStart,
      isFreeAccount: isFreeAccount,
    ),
  );
}

/// Encart compte gratuit : l'expression écrite et orale (EE/EO) n'est offerte
/// qu'une fois dans l'examen complet ; ensuite l'examen reste jouable en
/// compréhension (CO+CE) mais EE/EO passent en abonnement.
class _FreeNoteCard extends StatelessWidget {
  const _FreeNoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 18, color: AppColors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppFonts.ui(
                  size: 12.5,
                  color: AppColors.ink2,
                  height: 1.45,
                ),
                children: [
                  const TextSpan(text: 'Compte gratuit : '),
                  TextSpan(
                    text: 'l\'expression écrite et orale, évaluées par l\'IA, '
                        'te sont offertes une seule fois',
                    style: AppFonts.ui(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: AppColors.blue,
                      height: 1.45,
                    ),
                  ),
                  const TextSpan(
                    text: '. Tu pourras ensuite refaire cet examen en '
                        'compréhension (CO + CE) ; l\'EE et l\'EO passeront en '
                        'abonnement Intégral.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        // Hero rouge — convention SejourFR : tous les hero de la partie TCF
        // sont en rouge, distinct du bleu civique.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.red, AppColors.redDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.22),
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
            child: const Icon(
              LucideIcons.crown,
              size: 30,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'TCF IRN en conditions réelles',
            style: AppFonts.ui(
              size: 22,
              weight: FontWeight.w800,
              color: AppColors.white,
              height: 1.15,
            ).copyWith(letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            'Enchaîne les 4 épreuves : compréhension orale, écrite, expression écrite et orale. Tu obtiens un niveau CECRL global à la fin.',
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

class _DerouleCard extends StatelessWidget {
  /// Durées lues dans [kEpreuveDurationSeconds] — la même table que les écrans
  /// d'épreuve isolée, pour qu'un même examen ne s'annonce pas différemment
  /// selon l'endroit d'où on le lance. L'oral n'a pas de durée d'épreuve : on le
  /// dit au lieu d'inventer un chiffre.
  static final _rows = <_DerouleRow>[
    _DerouleRow(
      icon: '🎧',
      label: 'Compréhension orale',
      duration: epreuveDurationLabelFor(EpreuveType.tcfCo),
    ),
    _DerouleRow(
      icon: '📖',
      label: 'Compréhension écrite',
      duration: epreuveDurationLabelFor(EpreuveType.tcfCe),
    ),
    _DerouleRow(
      icon: '✍️',
      label: 'Expression écrite',
      duration: epreuveDurationLabelFor(EpreuveType.tcfEe),
    ),
    _DerouleRow(
      icon: '🎙️',
      label: 'Expression orale',
      duration: kChronoParTacheLabel,
    ),
  ];

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
            'DÉROULÉ DE L\'EXAMEN',
            style: AppFonts.mono(
              size: 9.5,
              color: AppColors.muted,
              letterSpacing: 1.8,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < _rows.length; i++) ...[
            _DerouleRowWidget(row: _rows[i]),
            if (i != _rows.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _DerouleRow {
  const _DerouleRow({
    required this.icon,
    required this.label,
    required this.duration,
  });

  final String icon;
  final String label;
  final String duration;
}

class _DerouleRowWidget extends StatelessWidget {
  const _DerouleRowWidget({required this.row});

  final _DerouleRow row;

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
          Text(row.icon, style: AppFonts.ui(size: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.label,
              style: AppFonts.ui(
                size: 13.5,
                weight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            row.duration,
            style: AppFonts.ui(
              size: 12.5,
              weight: FontWeight.w800,
              color: AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ASavoirCard extends StatelessWidget {
  const _ASavoirCard();

  static const _items = <_ASavoirItem>[
    _ASavoirItem(
        icon: '⏱️', label: 'Chaque épreuve a son propre temps, rien ne se reporte'),
    _ASavoirItem(
        icon: '🚪',
        label: 'Le chrono continue si tu quittes — tu reprends là où tu en étais'),
    _ASavoirItem(icon: '🎧', label: 'Les audios se lancent une fois'),
    _ASavoirItem(icon: '🎙️', label: 'À l\'oral, tu lances chaque tâche quand tu es prêt'),
    _ASavoirItem(icon: '✨', label: 'Correction IA pour écrit et oral'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.lightbulb, size: 14, color: AppColors.red),
              const SizedBox(width: 6),
              Text(
                'À SAVOIR',
                style: AppFonts.mono(
                  size: 9.5,
                  color: AppColors.red,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _items.length; i++) ...[
            Row(
              children: [
                Text(_items[i].icon, style: AppFonts.ui(size: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _items[i].label,
                    style: AppFonts.ui(
                      size: 13,
                      color: AppColors.ink2,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (i != _items.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _ASavoirItem {
  const _ASavoirItem({required this.icon, required this.label});

  final String icon;
  final String label;
}
