import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Bandeau gris doux avec icone cadenas + note RGPD/confidentialite.
/// Equivalent de `.confidential-note` du mockup HTML.
class ConfidentialNote extends StatelessWidget {
  const ConfidentialNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1, right: 10),
            child: Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.muted2),
          ),
          Expanded(
            child: Text(
              text,
              style: AppFonts.jakarta(
                size: 12,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
