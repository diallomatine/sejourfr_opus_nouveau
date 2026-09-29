import '../../core/models/civic_diagnostic_models.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'civic_diagnostic_labels.dart';

/// Le ton de kit d'un état servi.
///
/// 🛑 `NON_EVALUE` rend [SfTone.muted], jamais [SfTone.warn] : le serveur n'a
/// pas mesuré ce thème, il ne dit pas qu'il est fragile. Miroir de `kitTone`
/// dans `web_sejoufr/lib/civic-diagnostic.ts`.
SfTone sfToneOf(CivicThemeState etat) => switch (civicThemeTone(etat)) {
      CivicThemeTone.ok => SfTone.ok,
      CivicThemeTone.warn => SfTone.warn,
      CivicThemeTone.hot => SfTone.hot,
      CivicThemeTone.muted => SfTone.muted,
    };
