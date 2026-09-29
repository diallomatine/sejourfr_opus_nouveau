import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';

/// Module actuellement actif (CIVIQUE par défaut).
/// On le persiste pas en stockage pour rester simple — il survit le temps de la session.
final selectedModuleProvider = StateProvider<AppModule>(
  (ref) => AppModule.civique,
);
