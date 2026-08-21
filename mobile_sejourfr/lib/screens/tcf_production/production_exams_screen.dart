import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/route_observer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/screen_header.dart';
import 'production_catalog.dart';
import 'production_exams_tab_view.dart';
import 'tcf_production_module.dart';
import 'widgets/production_common.dart';

/// **Les examens blancs d'une épreuve EE/EO**, sur leur propre écran.
///
/// Ils étaient le 3ᵉ mode de l'écran unique du parcours ; la maquette
/// 2026-08-21 les sort du flux des tâches et les atteint par le bouton de la
/// barre fixe de [ProductionTasksScreen]. **Rien du flux n'a bougé** : la
/// grille des 10 slots, le verrou freemium, la feuille de briefing et le
/// démarrage d'une session sont ceux de [ProductionExamsTabView], réutilisée
/// telle quelle — seul son enrobage change. Le chemin
/// `/tcf/expression-{orale,ecrite}/examens` est **inchangé**, donc les liens
/// profonds existants continuent d'aboutir ici.
class ProductionExamsScreen extends ConsumerStatefulWidget {
  const ProductionExamsScreen({super.key, required this.module});

  final TcfProductionModule module;

  @override
  ConsumerState<ProductionExamsScreen> createState() =>
      _ProductionExamsScreenState();
}

class _ProductionExamsScreenState extends ConsumerState<ProductionExamsScreen>
    with RouteAware {
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Retour d'une session d'examen ou d'un bilan : une évaluation a pu se
  /// terminer entre-temps. Les bilans ne se redemandent pas tout seuls tant
  /// que la liste des sessions est la même.
  @override
  void didPopNext() {
    invalidateProductionCatalog(ref, widget.module.epreuve);
    ref.invalidate(examBilansProvider(widget.module.epreuve));
  }

  void _setBusy(bool value) {
    if (value == _busy) return;
    setState(() => _busy = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                ScreenHeader(
                  title: 'Examens blancs',
                  sub: '${widget.module.title} · 3 tâches enchaînées',
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ProductionExamsTabView(
                    module: widget.module,
                    onBusy: _setBusy,
                    top: const [],
                  ),
                ),
              ],
            ),
            if (_busy) const Positioned.fill(child: BusyOverlay()),
          ],
        ),
      ),
    );
  }
}
