import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../production_exam_copy.dart';

/// La feuille « ⓘ » des écrans de production EE/EO : les critères de notre
/// grille et la confidentialité de la production. Miroir de
/// `ProductionInfoSheet` côté web — mêmes phrases, lues dans
/// `production_exam_copy.dart`.
Future<void> showProductionInfoSheet(
  BuildContext context,
  EpreuveType epreuve,
) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ProductionInfoSheet(epreuve: epreuve),
  );
}

class _ProductionInfoSheet extends StatelessWidget {
  const _ProductionInfoSheet({required this.epreuve});

  final EpreuveType epreuve;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.blueLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.info,
                      size: 18,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      kProductionInfoTitle,
                      style: AppFonts.display(
                        size: 18,
                        weight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Label(text: kProductionInfoCriteriaLabel),
              const SizedBox(height: 10),
              for (final c in kProductionCriteria)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 7, right: 10),
                        decoration: const BoxDecoration(
                          color: AppColors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: c.label,
                                style: AppFonts.ui(
                                  size: 13.5,
                                  weight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              TextSpan(text: ' — ${c.hint}'),
                            ],
                          ),
                          style: AppFonts.ui(
                            size: 13.5,
                            color: AppColors.ink2,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                kProductionCriteriaFoot,
                style: AppFonts.ui(
                  size: 12.5,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.line2),
              const SizedBox(height: 16),
              _Label(text: kProductionInfoPrivacyLabel),
              const SizedBox(height: 8),
              Text(
                productionPrivacyText(epreuve),
                style: AppFonts.ui(
                  size: 13.5,
                  color: AppColors.muted,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: kProductionInfoClose,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppFonts.label(size: 10, color: AppColors.muted)
          .copyWith(letterSpacing: 1.6),
    );
  }
}
