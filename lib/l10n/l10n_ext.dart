import 'package:flutter/widgets.dart';
import 'package:valence/l10n/app_localizations.dart';

/// Terse accessor for translations: `context.l10n.save` instead of
/// `AppLocalizations.of(context).save`.
///
/// To ADD a string: add the key to `lib/l10n/app_en.arb` (the template, with
/// an `@key` description) and to the other 5 ARB files (ar/fr/es/pt/de —
/// `tool/l10n_add.py` does all six at once), then run `flutter gen-l10n`.
/// Never hardcode user-facing text in widgets.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
