import 'package:flutter/widgets.dart';
import 'package:valence/l10n/app_localizations.dart';

/// Terse accessor for translations: `context.l10n.save` instead of
/// `AppLocalizations.of(context).save`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
