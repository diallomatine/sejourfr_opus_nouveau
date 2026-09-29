import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import 'account_labels.dart';
import 'account_widgets.dart';

/// « Adresse e-mail » — `POST /api/me/change-email-request`. L'adresse ne
/// change qu'au clic sur le lien reçu : l'écran le dit avant l'envoi, puis le
/// confirme. Miroir de `web_sejoufr/app/_components/compte/EmailForm.tsx`.
class ChangeEmailScreen extends ConsumerStatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  ConsumerState<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends ConsumerState<ChangeEmailScreen> {
  final _newEmail = TextEditingController();
  final _password = TextEditingController();
  EmailErrors _errors = const EmailErrors();
  bool _submitted = false;
  bool _sending = false;
  String? _serverError;
  String? _sentTo;

  @override
  void dispose() {
    _newEmail.dispose();
    _password.dispose();
    super.dispose();
  }

  void _changed(String currentEmail) {
    setState(() {
      _serverError = null;
      if (_submitted) {
        _errors = validateEmailChange(
            _newEmail.text, _password.text, currentEmail);
      }
    });
  }

  Future<void> _submit(String currentEmail) async {
    final errors =
        validateEmailChange(_newEmail.text, _password.text, currentEmail);
    setState(() {
      _submitted = true;
      _errors = errors;
    });
    if (errors.any) return;
    FocusScope.of(context).unfocus();
    final email = _newEmail.text.trim();
    setState(() {
      _sending = true;
      _serverError = null;
    });
    try {
      await ref.read(profileRepositoryProvider).requestEmailChange(
            newEmail: email,
            currentPassword: _password.text,
          );
      if (!mounted) return;
      setState(() => _sentTo = email);
    } catch (e) {
      if (!mounted) return;
      final message = ApiClient.toApiException(e).message;
      setState(
        () => _serverError = message.isNotEmpty ? message : kCompteEmailFailed,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = auth.user;
    final isLocal = compteIsLocal(user.authProvider);

    return AccountScaffold(
      title: kCompteEmailTitle,
      lead: isLocal && _sentTo == null ? kCompteEmailLead : null,
      children: [
        if (!isLocal)
          AccountProviderNote(note: compteEmailProviderNote(user.authProvider))
        else if (_sentTo != null)
          AccountDone(
            title: kCompteEmailSuccessTitle,
            body: compteEmailSuccessBody(_sentTo!, user.email),
          )
        else
          AccountFormCard(
            children: [
              AccountReadonly(label: kCompteEmailCurrentLabel, value: user.email),
              AccountField(
                label: kCompteEmailNewLabel,
                controller: _newEmail,
                onChanged: (_) => _changed(user.email),
                error: _errors.newEmail,
                placeholder: kCompteEmailPlaceholder,
                enabled: !_sending,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              AccountField(
                label: kCompteCurrentPasswordLabel,
                controller: _password,
                onChanged: (_) => _changed(user.email),
                error: _errors.password,
                password: true,
                enabled: !_sending,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(user.email),
              ),
              if (_serverError != null) AccountAlert(message: _serverError!),
              AccountSubmit(
                label: kCompteEmailSubmit,
                loading: _sending,
                onPressed: () => _submit(user.email),
              ),
            ],
          ),
      ],
    );
  }
}
