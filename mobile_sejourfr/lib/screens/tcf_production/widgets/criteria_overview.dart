import 'package:flutter/material.dart';

import '../../../core/models/production_models.dart';
import 'criterion_row.dart';
import 'results_section_head.dart';

/// Le profil du candidat **en un coup d'œil** : les quatre criteres, leur bande
/// et leur barre, sans une ligne de prose.
///
/// Cette liste etait rangee dans « Voir l'analyse complète », donc invisible en
/// pratique — alors que c'est la seule vue d'ensemble du rapport. Elle remonte
/// ici, mais **compacte** : le commentaire et la preuve ne s'affichent que sur
/// demande, ligne par ligne. C'est le compromis entre « tout deplie »
/// (illisible) et « tout replie » (jamais lu).
class CriteriaOverview extends StatefulWidget {
  const CriteriaOverview({super.key, required this.criteres});

  final List<CriterionScore> criteres;

  @override
  State<CriteriaOverview> createState() => _CriteriaOverviewState();
}

class _CriteriaOverviewState extends State<CriteriaOverview> {
  final _open = <int>{};

  @override
  Widget build(BuildContext context) {
    if (widget.criteres.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ResultsSectionHead(
            title: 'Votre profil en un coup d\'œil',
            hint: 'Appuyez pour le détail',
          ),
          const SizedBox(height: 10),
          // Une carte par critere, comme la maquette : quatre lignes serrees
          // dans une seule carte se lisaient comme un tableau, pas comme
          // quatre choses distinctes sur lesquelles on peut appuyer.
          for (final (index, critere) in widget.criteres.indexed)
            CriterionRow(
              criterion: critere,
              showDetail: _open.contains(index),
              onToggle: () => setState(() {
                _open.contains(index)
                    ? _open.remove(index)
                    : _open.add(index);
              }),
            ),
        ],
      ),
    );
  }
}
