/// Valence design system — single import for screens.
///
/// `import 'package:valence/ui/ui.dart';` brings in every V-component plus the
/// design tokens (`context.tokens`, [VType], [VRadius], [VSpace], [VDuration],
/// [VMotion]). Screens compose these primitives — they never copy styling
/// (design.md §3).
library;

// Foundations.
export '../theme/tokens.dart';
export '../theme/typography.dart';

// Components (design.md §2).
export 'v_atmosphere.dart';
export 'v_avatar.dart';
export 'v_buttons.dart';
export 'v_callout.dart';
export 'v_code_boxes.dart';
export 'v_empty.dart';
export 'v_field.dart';
export 'v_group_card.dart';
export 'v_header.dart';
export 'v_health_bar.dart';
export 'v_option_card.dart';
export 'v_pressable.dart';
export 'v_progress_segments.dart';
export 'v_row.dart';
export 'v_ruler_dial.dart';
export 'v_search_bar.dart';
export 'v_segmented.dart';
export 'v_sheet.dart';
export 'v_skeleton.dart';
export 'v_stats.dart';
export 'v_status_pill.dart';
export 'v_stepper.dart';
export 'v_toast.dart';
