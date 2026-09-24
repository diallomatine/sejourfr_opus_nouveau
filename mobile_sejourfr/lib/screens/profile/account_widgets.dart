import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/screen_header.dart';
import 'account_labels.dart';

/// Les briques des écrans du compte (« Mes informations » et ses trois écrans
/// d'édition). Miroir de `web_sejoufr/app/_components/compte/CompteParts.tsx` :
/// en-tête + phrase de cadrage, carte de formulaire, champ libellé avec son
/// message d'erreur SOUS le champ, alerte, état final.

/// L'écran : en-tête fixe avec retour, puis un contenu défilant.
class AccountScaffold extends StatelessWidget {
  const AccountScaffold({
    super.key,
    required this.title,
    this.lead,
    required this.children,
  });

  final String title;
  final String? lead;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(title: title, onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  if (lead != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        lead!,
                        style: AppFonts.ui(
                          size: 14,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La carte blanche qui porte les champs d'un formulaire.
class AccountFormCard extends StatelessWidget {
  const AccountFormCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Un champ libellé. L'erreur s'écrit sous le champ, à la place de l'aide.
class AccountField extends StatefulWidget {
  const AccountField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.error,
    this.hint,
    this.placeholder,
    this.password = false,
    this.keyboardType,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? error;
  final String? hint;
  final String? placeholder;
  final bool password;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AccountField> createState() => _AccountFieldState();
}

class _AccountFieldState extends State<AccountField> {
  bool _revealed = false;

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    final below = widget.error ?? widget.hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label.toUpperCase(), style: AppFonts.label(size: 11)),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          obscureText: widget.password && !_revealed,
          autocorrect: false,
          enableSuggestions: !widget.password,
          keyboardType: widget.keyboardType,
          autofillHints: widget.autofillHints,
          textCapitalization: widget.textCapitalization,
          textInputAction: widget.textInputAction,
          onSubmitted: widget.onSubmitted,
          style: AppFonts.ui(size: 16, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: AppFonts.ui(size: 15, color: AppColors.muted2),
            filled: true,
            fillColor: hasError ? AppColors.white : AppColors.surface2,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: _border(AppColors.line),
            enabledBorder: _border(hasError ? AppColors.red : AppColors.line),
            disabledBorder: _border(AppColors.line),
            focusedBorder:
                _border(hasError ? AppColors.red : AppColors.blue, 1.5),
            suffixIcon: widget.password
                ? IconButton(
                    tooltip:
                        _revealed ? kComptePasswordHide : kComptePasswordShow,
                    icon: Icon(
                      _revealed ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 19,
                      color: AppColors.muted,
                    ),
                    onPressed: () => setState(() => _revealed = !_revealed),
                  )
                : null,
          ),
        ),
        if (below != null) ...[
          const SizedBox(height: 7),
          Text(
            below,
            style: AppFonts.ui(
              size: 13,
              height: 1.4,
              color: hasError ? AppColors.red : AppColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Une valeur en lecture seule, présentée comme un champ.
class AccountReadonly extends StatelessWidget {
  const AccountReadonly({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppFonts.label(size: 11)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.ui(size: 16, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

/// Une erreur serveur, ou la confirmation d'un enregistrement.
class AccountAlert extends StatelessWidget {
  const AccountAlert({super.key, required this.message, this.ok = false});

  final String message;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final fg = ok ? AppColors.greenDark : AppColors.redDark;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ok ? AppColors.greenLight : AppColors.redLight,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              ok ? LucideIcons.circleCheck : LucideIcons.circleAlert,
              size: 18,
              color: fg,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppFonts.ui(size: 14, color: fg, height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le bouton d'envoi d'un formulaire du compte.
class AccountSubmit extends StatelessWidget {
  const AccountSubmit({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      isLoading: loading,
      onPressed: loading ? null : onPressed,
    );
  }
}

/// L'état final d'un flux : ce qui s'est passé, et le chemin du retour.
class AccountDone extends StatelessWidget {
  const AccountDone({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: const Icon(
              LucideIcons.circleCheck,
              size: 26,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppFonts.display(size: 21, weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 14.5, color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: kCompteBackToInfo,
            variant: AppButtonVariant.outline,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

/// Un compte Google / Apple sur un écran qu'il ne peut pas utiliser.
class AccountProviderNote extends StatelessWidget {
  const AccountProviderNote({super.key, required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            note,
            style: AppFonts.ui(size: 14.5, color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: kCompteBackToInfo,
            variant: AppButtonVariant.outline,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
