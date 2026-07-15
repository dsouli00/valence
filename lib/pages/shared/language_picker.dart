import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/providers/locale_provider.dart';
import 'package:valence/ui/ui.dart';

/// The label to show as the current value on the "Language" settings row:
/// the active language in its own script, or "System default" when unset.
String currentLanguageLabel(BuildContext context) {
  final code = context.watch<LocaleProvider>().locale?.languageCode;
  if (code == null) return context.l10n.languageSystemDefault;
  for (final lang in kAppLanguages) {
    if (lang.code == code) return lang.nativeName;
  }
  return context.l10n.languageSystemDefault;
}

/// Language picker — a VSheet with quiet rows and a gold check on the active
/// language (design.md §5.17). Writes the choice to [LocaleProvider] (which
/// persists it); the whole app re-localizes live.
Future<void> showLanguagePicker(BuildContext context) {
  return showVSheet<void>(
    context: context,
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<LocaleProvider>();
    final selectedCode = provider.locale?.languageCode;

    return VSheet(
      title: l10n.chooseLanguage,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: 4, bottom: 8),
        child: VGroupCard(
          dividerInset: 14,
          children: [
            _LangRow(
              title: l10n.languageSystemDefault,
              subtitle: null,
              selected: selectedCode == null,
              onTap: () {
                context.read<LocaleProvider>().setLocale(null);
                Navigator.of(context).pop();
              },
            ),
            for (final lang in kAppLanguages)
              _LangRow(
                title: lang.nativeName,
                subtitle: lang.englishName,
                selected: selectedCode == lang.code,
                onTap: () {
                  context.read<LocaleProvider>().setLocale(Locale(lang.code));
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// One language row: native name (+ quiet English name) with the gold check
/// as the ONLY selected signal.
class _LangRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LangRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return VPressable(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      overlay: true,
      overlayRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: VType.body.copyWith(
                        color: t.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        style: VType.caption.copyWith(color: t.inkSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Icon(PhosphorIconsBold.check, size: 18, color: t.goldDeep),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
