import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/route_observer.dart';
import '../../core/theme/app_theme.dart';
import 'production_catalog.dart';
import 'production_subjects_view.dart';
import 'tcf_production_module.dart';
import 'widgets/production_common.dart';
import 'widgets/task_banner.dart';

/// **Niveau 2 du parcours EE/EO** : une tâche, sa consigne, et ses **sujets
/// complets**.
///
/// Il remplace l'écran unique à trois modes : la tâche ne se choisit plus par
/// un sélecteur — on y entre depuis la liste des tâches ([ProductionTasksScreen])
/// ou depuis le Plan — et les examens blancs ne sont plus un troisième onglet,
/// ils ont leur écran ([ProductionExamsScreen]).
///
/// ⚠️ **Plus d'onglet « Compétences » depuis le 2026-09-20** (demande du
/// propriétaire) : les compétences ne se travaillent **que via le Plan**, qui
/// route vers la liste d'une tâche puis vers la fiche d'une compétence. L'écran
/// n'ayant plus qu'un seul contenu, la barre segmentée a disparu avec lui.
class ProductionTaskScreen extends ConsumerStatefulWidget {
  const ProductionTaskScreen({
    super.key,
    required this.module,
    required this.tache,
  });

  final TcfProductionModule module;
  final int tache;

  @override
  ConsumerState<ProductionTaskScreen> createState() =>
      _ProductionTaskScreenState();
}

class _ProductionTaskScreenState extends ConsumerState<ProductionTaskScreen>
    with RouteAware {
  /// Voile d'attente au démarrage d'une session, remonté par la liste des
  /// sujets. Porté ici pour couvrir **aussi** l'en-tête.
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

  /// Retour d'un flux poussé au-dessus de la tâche (production d'un sujet). Le
  /// candidat vient potentiellement de produire : sa progression a changé, et
  /// un cache muet afficherait un « 6/20 sujets traités » périmé.
  @override
  void didPopNext() {
    invalidateProductionCatalog(ref, widget.module.epreuve);
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
            // L'en-tete n'est plus fixe : il vit dans le meme encart que la
            // consigne, en tete de la liste, et defile avec elle (demande du
            // proprietaire, 2026-08-21). Le retour reste atteignable par le
            // geste iOS meme une fois le bandeau remonte.
            ProductionSubjectsView(
              module: widget.module,
              tache: widget.tache,
              onBusy: _setBusy,
              top: taskBannerTop(
                context,
                module: widget.module,
                tache: widget.tache,
              ),
            ),
            if (_busy) const Positioned.fill(child: BusyOverlay()),
          ],
        ),
      ),
    );
  }
}
