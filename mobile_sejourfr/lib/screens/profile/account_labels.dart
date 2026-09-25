import '../../core/models/enums.dart';

/// Les écrans du compte : « Mes informations » et ses trois écrans d'édition
/// (nom et prénom, adresse e-mail, mot de passe), et « Notifications par
/// e-mail ».
///
/// 🛑 **Miroir mot pour mot** de `web_sejoufr/lib/compte.ts` : libellés,
/// messages de validation et règles de saisie. Un texte qui bouge ici bouge
/// là-bas dans la même passe.
///
/// Les bornes recopient les contraintes du backend (`UpdateProfileRequest`,
/// `ChangePasswordRequest`) : un refus serveur ne doit jamais être la première
/// nouvelle d'une saisie invalide.

// ── Bornes (miroirs du backend) ─────────────────────────────────────────
const int kCompteNameMax = 120;
const int kComptePasswordMin = 8;
const int kComptePasswordMax = 128;

// ── « Mes informations » ────────────────────────────────────────────────
const String kCompteInfoTitle = 'Mes informations';
const String kCompteInfoLead =
    'Votre identité, votre adresse e-mail et votre mot de passe.';
const String kCompteRowIdentity = 'Nom et prénom';
const String kCompteRowEmail = 'Adresse e-mail';
const String kCompteRowPassword = 'Mot de passe';
const String kComptePasswordMask = '••••••••••';
const String kCompteIdentityEmpty = 'Non renseigné';

String compteProviderName(AuthProvider provider) => switch (provider) {
      AuthProvider.google => 'Google',
      AuthProvider.apple => 'Apple',
      AuthProvider.local => 'e-mail',
    };

bool compteIsLocal(AuthProvider provider) => provider == AuthProvider.local;

/// Sous-titre d'une donnée tenue par le fournisseur (Google / Apple).
String compteProviderManaged(AuthProvider provider) =>
    'Géré par votre compte ${compteProviderName(provider)}';

/// Compte Google / Apple : l'adresse e-mail est celle du fournisseur.
String compteEmailProviderNote(AuthProvider provider) {
  final name = compteProviderName(provider);
  return "Connexion via $name — l'adresse e-mail se gère depuis votre compte $name.";
}

/// Compte Google / Apple : aucun mot de passe SejourFR n'existe.
String comptePasswordProviderNote(AuthProvider provider) =>
    "Connexion via ${compteProviderName(provider)} — votre compte n'a pas de mot de passe SejourFR.";

// ── Nom et prénom ───────────────────────────────────────────────────────
const String kCompteIdentityTitle = 'Nom et prénom';
const String kCompteIdentityLead = "Ce nom s'affiche sur votre profil.";
const String kCompteFirstNameLabel = 'Prénom';
const String kCompteLastNameLabel = 'Nom';
const String kCompteFirstNameRequired = 'Indiquez votre prénom.';
const String kCompteLastNameRequired = 'Indiquez votre nom.';
const String kCompteNameTooLong = '$kCompteNameMax caractères maximum.';
const String kCompteIdentitySubmit = 'Enregistrer';
const String kCompteIdentitySuccess = 'Vos informations sont à jour.';
const String kCompteIdentityFailed = 'La mise à jour a échoué. Réessayez.';

// ── Adresse e-mail ──────────────────────────────────────────────────────
const String kCompteEmailTitle = 'Adresse e-mail';
const String kCompteEmailLead =
    "Nous envoyons un lien de vérification à la nouvelle adresse. Votre adresse actuelle reste active tant que vous n'avez pas cliqué dessus.";
const String kCompteEmailCurrentLabel = 'Adresse actuelle';
const String kCompteEmailNewLabel = 'Nouvelle adresse e-mail';
const String kCompteEmailPlaceholder = 'nouvelle@adresse.fr';
const String kCompteCurrentPasswordLabel = 'Mot de passe actuel';
const String kCompteEmailRequired = 'Indiquez votre nouvelle adresse e-mail.';
const String kCompteEmailInvalid = "Cette adresse e-mail n'est pas valide.";
const String kCompteEmailSame = "C'est déjà votre adresse actuelle.";
const String kCompteCurrentPasswordRequired =
    'Indiquez votre mot de passe actuel.';
const String kCompteEmailSubmit = 'Envoyer le lien de vérification';
const String kCompteEmailSuccessTitle = 'Vérifiez votre boîte de réception';
const String kCompteEmailFailed = 'La demande a échoué. Réessayez.';

String compteEmailSuccessBody(String newEmail, String currentEmail) =>
    "Un lien de vérification a été envoyé à $newEmail. Cliquez dessus pour confirmer le changement. D'ici là, vous vous connectez toujours avec $currentEmail.";

// ── Mot de passe ────────────────────────────────────────────────────────
const String kComptePasswordTitle = 'Mot de passe';
const String kComptePasswordLead =
    'Saisissez votre mot de passe actuel, puis choisissez-en un nouveau.';
const String kCompteNewPasswordLabel = 'Nouveau mot de passe';
const String kCompteConfirmPasswordLabel = 'Confirmer le nouveau mot de passe';
const String kCompteNewPasswordHint = '$kComptePasswordMin caractères minimum.';
const String kCompteNewPasswordTooShort =
    'Le nouveau mot de passe doit contenir au moins $kComptePasswordMin caractères.';
const String kCompteNewPasswordTooLong = '$kComptePasswordMax caractères maximum.';
const String kCompteNewPasswordSame =
    "Le nouveau mot de passe doit être différent de l'actuel.";
const String kCompteConfirmMismatch =
    'Les deux mots de passe ne correspondent pas.';
const String kComptePasswordSubmit = 'Mettre à jour le mot de passe';
const String kComptePasswordSuccessTitle = 'Mot de passe modifié';
const String kComptePasswordSuccessBody =
    'Utilisez-le dès votre prochaine connexion.';
const String kComptePasswordFailed = 'La modification a échoué. Réessayez.';
const String kComptePasswordShow = 'Afficher le mot de passe';
const String kComptePasswordHide = 'Masquer le mot de passe';

// ── Notifications par e-mail ────────────────────────────────────────────
const String kCompteNotifRowTitle = 'Notifications par e-mail';
const String kCompteNotifRowSub = "Conseils et rappels d'entraînement";
const String kCompteNotifTitle = 'Notifications par e-mail';
const String kCompteNotifLead =
    'Choisissez les e-mails que SejourFR peut vous envoyer pour vous accompagner.';
const String kCompteNotifEngagementLabel =
    "Recevoir les conseils et rappels d'entraînement";
const String kCompteNotifEngagementSub =
    "Votre plan prêt après un diagnostic, un rappel quand vous n'avez pas pratiqué depuis quelques jours, la fin prochaine de votre accès.";
const String kCompteNotifFootnote =
    'Les emails indispensables liés à votre compte, votre sécurité ou vos paiements continueront à être envoyés.';
const String kCompteNotifLoadFailed =
    'Impossible de charger vos préférences. Réessayez.';
const String kCompteNotifSaveFailed =
    "Votre choix n'a pas pu être enregistré. Réessayez.";
const String kCompteNotifSaved = 'Préférence enregistrée.';

// ── Commun ──────────────────────────────────────────────────────────────
const String kCompteBackToInfo = 'Retour à mes informations';

// ── Validation (pure) ───────────────────────────────────────────────────
class IdentityErrors {
  const IdentityErrors({this.firstName, this.lastName});
  final String? firstName;
  final String? lastName;
  bool get any => firstName != null || lastName != null;
}

class EmailErrors {
  const EmailErrors({this.newEmail, this.password});
  final String? newEmail;
  final String? password;
  bool get any => newEmail != null || password != null;
}

class PasswordErrors {
  const PasswordErrors({this.current, this.next, this.confirm});
  final String? current;
  final String? next;
  final String? confirm;
  bool get any => current != null || next != null || confirm != null;
}

String? _nameError(String value, String required) {
  final v = value.trim();
  if (v.isEmpty) return required;
  if (v.length > kCompteNameMax) return kCompteNameTooLong;
  return null;
}

IdentityErrors validateIdentity(String firstName, String lastName) =>
    IdentityErrors(
      firstName: _nameError(firstName, kCompteFirstNameRequired),
      lastName: _nameError(lastName, kCompteLastNameRequired),
    );

final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

EmailErrors validateEmailChange(
  String newEmail,
  String password,
  String currentEmail,
) {
  final email = newEmail.trim();
  String? emailError;
  if (email.isEmpty) {
    emailError = kCompteEmailRequired;
  } else if (!_emailPattern.hasMatch(email)) {
    emailError = kCompteEmailInvalid;
  } else if (email.toLowerCase() == currentEmail.trim().toLowerCase()) {
    emailError = kCompteEmailSame;
  }
  return EmailErrors(
    newEmail: emailError,
    password: password.isEmpty ? kCompteCurrentPasswordRequired : null,
  );
}

PasswordErrors validatePasswordChange(
  String current,
  String next,
  String confirm,
) {
  String? nextError;
  if (next.length < kComptePasswordMin) {
    nextError = kCompteNewPasswordTooShort;
  } else if (next.length > kComptePasswordMax) {
    nextError = kCompteNewPasswordTooLong;
  } else if (current.isNotEmpty && next == current) {
    nextError = kCompteNewPasswordSame;
  }
  return PasswordErrors(
    current: current.isEmpty ? kCompteCurrentPasswordRequired : null,
    next: nextError,
    confirm: nextError == null && next != confirm ? kCompteConfirmMismatch : null,
  );
}
