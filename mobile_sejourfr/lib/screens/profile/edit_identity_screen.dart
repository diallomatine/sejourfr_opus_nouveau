import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import 'account_labels.dart';
import 'account_widgets.dart';

/// « Nom et prénom » — `PATCH /api/me/profile`. Miroir de
/// `web_sejoufr/app/_components/compte/IdentiteForm.tsx`.
class EditIdentityScreen extends ConsumerStatefulWidget {
  const EditIdentityScreen({super.key});

  @override
  ConsumerState<EditIdentityScreen> createState() => _EditIdentityScreenState();
}

class _EditIdentityScreenState extends ConsumerState<EditIdentityScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  IdentityErrors _errors = const IdentityErrors();
  bool _submitted = false;
  bool _saving = false;
  bool _saved = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  /// Une saisie efface les messages ; après un premier envoi, elle revalide.
  void _changed(String _) {
    setState(() {
      _saved = false;
      _serverError = null;
      if (_submitted) _errors = validateIdentity(_firstName.text, _lastName.text);
    });
  }

  Future<void> _submit() async {
    final errors = validateIdentity(_firstName.text, _lastName.text);
    setState(() {
      _submitted = true;
      _errors = errors;
    });
    if (errors.any) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _saved = false;
      _serverError = null;
    });
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
          );
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (!mounted) return;
      setState(() => _saved = true);
    } catch (e) {
      if (!mounted) return;
      final message = ApiClient.toApiException(e).message;
      setState(
        () => _serverError = message.isNotEmpty ? message : kCompteIdentityFailed,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccountScaffold(
      title: kCompteIdentityTitle,
      lead: kCompteIdentityLead,
      children: [
        AccountFormCard(
          children: [
            AccountField(
              label: kCompteFirstNameLabel,
              controller: _firstName,
              onChanged: _changed,
              error: _errors.firstName,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
            ),
            AccountField(
              label: kCompteLastNameLabel,
              controller: _lastName,
              onChanged: _changed,
              error: _errors.lastName,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.familyName],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            if (_serverError != null) AccountAlert(message: _serverError!),
            if (_saved) const AccountAlert(message: kCompteIdentitySuccess, ok: true),
            AccountSubmit(
              label: kCompteIdentitySubmit,
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ],
    );
  }
}
