import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bottom sheet de la refonte 2026 (cf. `MSheet` maquette) : poignée,
/// pastille d'icône optionnelle, titre Bricolage centré, sous-titre, puis
/// les actions empilées avec 10 px d'écart.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  IconData? icon,
  Color iconBg = AppColors.blueLight,
  Color iconColor = AppColors.blueDark,
  String? title,
  String? sub,
  required List<Widget> children,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.white,
    barrierColor: AppColors.scrim,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            if (icon != null)
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(icon, size: 26, color: iconColor),
                ),
              ),
            if (title != null)
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppFonts.display(size: 19),
              ),
            if (sub != null) ...[
              const SizedBox(height: 3),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: AppFonts.ui(size: 13, color: AppColors.inkFaint),
              ),
            ],
            const SizedBox(height: 18),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              children[i],
            ],
          ],
        ),
      ),
    ),
  );
}
