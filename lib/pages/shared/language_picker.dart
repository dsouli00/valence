import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/providers/locale_provider.dart';
import 'package:valence/theme/app_theme.dart';

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

/// Premium clean bottom sheet for choosing the app language. Writes the choice
/// to [LocaleProvider] (which persists it); the whole app re-localizes live.
Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = context.l10n;
    final provider = context.watch<LocaleProvider>();
    final selectedCode = provider.locale?.languageCode;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.p20,
        right: AppSpacing.p20,
        top: AppSpacing.p12,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.p20,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.p16),
            Text(
              l10n.chooseLanguage,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: AppSpacing.p16),
            _LangTile(
              title: l10n.languageSystemDefault,
              subtitle: null,
              selected: selectedCode == null,
              onTap: () {
                context.read<LocaleProvider>().setLocale(null);
                Navigator.of(context).pop();
              },
            ),
            for (final lang in kAppLanguages)
              _LangTile(
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

class _LangTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LangTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.p8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondaryColor.withValues(alpha: 0.12)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.secondaryColor.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              selected ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
              color: selected
                  ? AppColors.secondaryColor
                  : cs.onSurfaceVariant.withValues(alpha: 0.4),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
