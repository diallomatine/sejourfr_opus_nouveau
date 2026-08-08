import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import 'tcf_note_scale.dart';

/// Ligne d'un critere : icone bubble coloree + nom + bande qualitative + barre.
///
/// On affiche la **bande** (« Satisfaisant »), pas la note du critere — l'IA ne
/// distingue pas honnetement un 13 d'un 14. Seule la note globale /20 reste
/// chiffree, ailleurs sur l'ecran. Les evaluations anterieures au contrat v4
/// n'ont pas de `bande` : on la **relit depuis leur note** sur la table
/// officielle du TCF ([TcfNoteScale.bandeFor]), pour qu'elles se rendent
/// exactement comme les recentes. Aucun critere ne s'affiche plus en chiffres.
///
/// Notre grille courante n'a que quatre codes (`communiquer`, `interagir`,
/// `lexique`, `morphosyntaxe`), mais les evaluations deja en base en portent
/// d'autres : les tables ci-dessous les couvrent tous, sans quoi l'historique
/// tomberait sur l'icone et le libelle par defaut.
class CriterionRow extends StatelessWidget {
  const CriterionRow({
    super.key,
    required this.criterion,
    this.showDetail = true,
    this.onToggle,
  });

  final CriterionScore criterion;

  /// Commentaire et preuve. Replies dans la vue « en un coup d'œil » : ce qui
  /// se lit d'un regard, c'est le nom du critere et sa bande — la
  /// justification, on va la chercher.
  final bool showDetail;

  /// Non nul = la ligne est depliable : chevron, zone tactile, et le detail
  /// pilote par [showDetail].
  final VoidCallback? onToggle;

  bool get _hasDetail =>
      criterion.commentaire.isNotEmpty || criterion.preuve != null;

  /// Bande du critere : celle du serveur, ou celle que sa note vaut sur
  /// l'echelle du TCF quand l'evaluation est trop ancienne pour la porter.
  BandeCritere get _bande =>
      criterion.bande ?? TcfNoteScale.bandeFor(criterion.noteSurVingt);

  /// Teinte de la **bande**, jamais d'un seuil sur 20. `fragile` est le seul
  /// rouge admis : c'est un jugement qualitatif du serveur, pas un niveau
  /// CECRL peint en echec.
  Color get _color => switch (_bande) {
        BandeCritere.tresBonneMaitrise => AppColors.green,
        BandeCritere.satisfaisant => AppColors.blue,
        BandeCritere.enCoursAcquisition => AppColors.amber,
        BandeCritere.fragile => AppColors.red,
        BandeCritere.nonEvaluable => AppColors.muted2,
      };

  double get _fillRatio => _bande.fillRatio;

  IconData _iconForCode(String code) {
    switch (code) {
      case 'communiquer':
      case 'realisation_consigne':
      case 'pertinence':
        return LucideIcons.target;
      case 'interagir':
      case 'adequation_destinataire':
        return LucideIcons.userRound;
      case 'chronologie_recit':
        return LucideIcons.clock;
      case 'prise_position':
        return LucideIcons.flag;
      case 'argumentation':
        return LucideIcons.scale;
      case 'conduite_echange':
        return LucideIcons.messagesSquare;
      case 'developpement_reponses':
        return LucideIcons.messageSquareMore;
      case 'organisation':
      case 'coherence':
        return LucideIcons.list;
      case 'lexique':
      case 'vocabulaire':
        return LucideIcons.bookOpen;
      case 'morphosyntaxe':
      case 'grammaire':
        return LucideIcons.spellCheck;
      case 'orthographe':
        return LucideIcons.type;
      case 'prononciation':
        return LucideIcons.audioLines;
      default:
        return LucideIcons.listChecks;
    }
  }

  /// Nom court du critere, pour la vue « en un coup d'œil ».
  ///
  /// Le `label` du serveur est une **definition** (« Communiquer : accomplir la
  /// tache et enchainer les idees »), pas un nom : sur deux lignes, il pousse la
  /// bande hors de vue et rend la liste illisible d'un regard. On garde donc le
  /// nom court dans la ligne, et la definition complete reapparait quand on
  /// deplie — elle n'est jamais perdue.
  String? _shortLabelForCode(String code) => switch (code) {
        'communiquer' => 'Communiquer',
        'interagir' => 'Interagir',
        'lexique' || 'vocabulaire' => 'Vocabulaire',
        'morphosyntaxe' || 'grammaire' => 'Grammaire',
        _ => null,
      };

  /// Le backend joint desormais `label` depuis la grille de la tache. On le
  /// privilegie ; cette table sert de fallback pour les anciennes evaluations.
  String _labelForCode(String code) {
    switch (code) {
      case 'communiquer':
        return 'Capacité à communiquer';
      case 'interagir':
        return 'Capacité à interagir';
      case 'realisation_consigne':
        return 'Réalisation de la consigne';
      case 'adequation_destinataire':
        return 'Adéquation au destinataire';
      case 'chronologie_recit':
        return 'Chronologie et repères temporels';
      case 'prise_position':
        return 'Prise de position';
      case 'argumentation':
        return 'Justification des arguments';
      case 'conduite_echange':
        return "Conduite de l'échange";
      case 'developpement_reponses':
        return 'Développement des réponses';
      case 'pertinence':
        return 'Pertinence du contenu';
      case 'morphosyntaxe':
        return 'Correction morphosyntaxique';
      case 'grammaire':
        return 'Correction grammaticale';
      case 'vocabulaire':
      case 'lexique':
        return 'Richesse lexicale';
      case 'coherence':
      case 'organisation':
        return 'Cohérence du discours';
      case 'orthographe':
        return 'Orthographe et ponctuation';
      case 'prononciation':
        return 'Prononciation';
      case 'clarte_orale':
      case 'fluidite':
        return 'Clarté et fluidité';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expandable = onToggle != null && _hasDetail;
    final color = _color;
    final bande = _bande;
    final fullLabel = criterion.label ?? _labelForCode(criterion.code);
    final shortLabel = _shortLabelForCode(criterion.code) ?? fullLabel;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child:
                    Icon(_iconForCode(criterion.code), size: 19, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.ui(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: LinearProgressIndicator(
                        value: _fillRatio,
                        minHeight: 6,
                        backgroundColor: AppColors.line2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  bande.displayName,
                  textAlign: TextAlign.right,
                  style: AppFonts.ui(
                    size: 12,
                    weight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (expandable) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 2, right: 6),
                  child: Text(
                    showDetail ? 'Masquer le détail' : 'Voir pourquoi',
                    style: AppFonts.ui(
                      size: 13,
                      weight: FontWeight.w800,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (showDetail && _hasDetail) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: AppColors.line),
            const SizedBox(height: 10),
            // La definition complete du critere ne s'affiche qu'ici : elle
            // explique ce qu'on a mesure, elle n'a pas a tenir la ligne.
            if (fullLabel != shortLabel) ...[
              Text(
                fullLabel,
                style: AppFonts.ui(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: AppColors.ink2,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
            ],
            if (criterion.commentaire.isNotEmpty)
              Text(
                criterion.commentaire,
                style: AppFonts.ui(
                  size: 13,
                  color: AppColors.muted,
                  height: 1.55,
                ),
              ),
            if (criterion.preuve != null) ...[
              const SizedBox(height: 8),
              _PreuveQuote(preuve: criterion.preuve!, color: color),
            ],
          ],
        ],
      ),
    );
  }
}

/// Citation litterale de la production, rendue en filet vertical teinte.
class _PreuveQuote extends StatelessWidget {
  const _PreuveQuote({required this.preuve, required this.color});

  final String preuve;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Text(
        '« $preuve »',
        style: AppFonts.ui(
          size: 12.5,
          color: AppColors.ink2,
          height: 1.4,
        ).copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }
}
