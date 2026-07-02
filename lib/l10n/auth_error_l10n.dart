import 'package:valence/l10n/app_localizations.dart';
import 'package:valence/providers/auth_provider.dart';

/// Maps a failed [AuthResult]'s [AuthErrorCode] to localized, user-facing text.
/// The provider deliberately returns codes (it has no BuildContext); screens
/// call `result.localizedMessage(context.l10n)` when showing an error.
extension AuthResultL10n on AuthResult {
  String localizedMessage(AppLocalizations l10n) {
    switch (code) {
      case AuthErrorCode.inviteRequired:
        return l10n.authErrInviteRequired;
      case AuthErrorCode.inviteInvalid:
        return l10n.authErrInviteInvalid;
      case AuthErrorCode.emailInUse:
        return l10n.authErrEmailInUse;
      case AuthErrorCode.weakPassword:
        return l10n.authErrWeakPassword;
      case AuthErrorCode.invalidEmail:
        return l10n.authErrInvalidEmail;
      case AuthErrorCode.wrongCredentials:
        return l10n.authErrWrongCredentials;
      case AuthErrorCode.tooManyRequests:
        return l10n.authErrTooManyRequests;
      case AuthErrorCode.network:
        return l10n.authErrNetwork;
      case AuthErrorCode.userDataNotFound:
        return l10n.authErrUserDataNotFound;
      case AuthErrorCode.noEmailOnFile:
        return l10n.authErrNoEmailOnFile;
      case AuthErrorCode.notLoggedIn:
        return l10n.authErrNotLoggedIn;
      case AuthErrorCode.clientsOnly:
        return l10n.authErrClientsOnly;
      case AuthErrorCode.linkCoachFailed:
        return l10n.authErrLinkCoachFailed;
      case AuthErrorCode.incorrectPassword:
        return l10n.authErrIncorrectPassword;
      case AuthErrorCode.recentLoginRequired:
        return l10n.authErrRecentLogin;
      case AuthErrorCode.resetFailed:
        return l10n.authErrResetFailed;
      case AuthErrorCode.signupFailed:
        return l10n.authErrSignupFailed;
      case AuthErrorCode.signinFailed:
        return l10n.authErrSigninFailed;
      case AuthErrorCode.deleteFailed:
        return l10n.authErrDeleteFailed;
      case AuthErrorCode.unknown:
      case null:
        return l10n.authErrUnknown;
    }
  }
}
