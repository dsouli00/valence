import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/user_model.dart';
import 'package:valence/models/workout_models.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/theme/app_theme.dart';

/// Result returned by [AssignWorkoutSheet]. [dates] is the full set of days the
/// workout should be assigned on — one day for a single assignment, or several
/// for recurring/weekly programming (already resolved to concrete days).
class AssignResult {
  final String clientId;
  final List<DateTime> dates;
  const AssignResult(this.clientId, this.dates);
}

// ===========================================================================
// Template editor — premium full-screen create / edit.
// ===========================================================================

/// Create/edit a workout template: name + a list of exercise drafts (name,
/// sets/reps steppers, optional target weight). One screen, two modes —
/// [template] == null creates, otherwise edits in place.
class TemplateEditorScreen extends StatefulWidget {
  final String coachId;
  final WorkoutTemplate? template;

  const TemplateEditorScreen({super.key, required this.coachId, this.template});

  bool get isEditing => template != null;

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

/// Mutable editing buffer for one exercise row. Kept separate from the
/// immutable WorkoutExercise model; converted on save. Owns two controllers,
/// so every removal path must call [dispose].
class _ExerciseDraft {
  final TextEditingController name;
  int sets;
  int reps;
  final TextEditingController weight;

  _ExerciseDraft({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  void dispose() {
    name.dispose();
    weight.dispose();
  }
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  final _firestoreService = FirestoreService();
  final _nameController = TextEditingController();
  final List<_ExerciseDraft> _drafts = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    if (t != null) {
      _nameController.text = t.name;
      for (final e in t.exercises) {
        final w = e.targetWeightKgBySet.isNotEmpty ? e.targetWeightKgBySet.first : null;
        _drafts.add(_ExerciseDraft(
          name: TextEditingController(text: e.name),
          sets: e.sets,
          reps: e.reps,
          weight: TextEditingController(text: w == null ? '' : w.toStringAsFixed(1)),
        ));
      }
    }
    if (_drafts.isEmpty) _drafts.add(_blankDraft());
  }

  _ExerciseDraft _blankDraft() => _ExerciseDraft(
        name: TextEditingController(),
        sets: 3,
        reps: 10,
        weight: TextEditingController(),
      );

  @override
  void dispose() {
    _nameController.dispose();
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _addExercise() {
    HapticFeedback.selectionClick();
    setState(() => _drafts.add(_blankDraft()));
  }

  void _removeExercise(int index) {
    if (_drafts.length <= 1) return;
    HapticFeedback.selectionClick();
    setState(() => _drafts.removeAt(index).dispose());
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final exercises = <WorkoutExercise>[];
    for (final d in _drafts) {
      final exName = d.name.text.trim();
      if (exName.isEmpty) continue;
      final raw = d.weight.text.trim();
      final parsed = raw.isEmpty ? null : double.tryParse(raw);
      if (raw.isNotEmpty && parsed == null) {
        _toast(context.l10n.enterValidWeightBlank);
        return;
      }
      exercises.add(WorkoutExercise(
        name: exName,
        sets: d.sets,
        reps: d.reps,
        targetWeightKgBySet: List.generate(d.sets, (_) => parsed),
      ));
    }

    if (name.isEmpty) {
      _toast(context.l10n.giveTemplateName);
      return;
    }
    if (exercises.isEmpty) {
      _toast(context.l10n.addAtLeastOneExercise);
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        await _firestoreService.updateWorkoutTemplate(
          templateId: widget.template!.id,
          name: name,
          exercises: exercises,
        );
      } else {
        await _firestoreService.createWorkoutTemplate(
          coachId: widget.coachId,
          name: name,
          exercises: exercises,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? context.l10n.templateUpdated : context.l10n.templateCreated)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(context.l10n.couldNotSaveNow);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: _Glow(
        child: SafeArea(
          child: Column(
            children: [
              _EditorHeader(theme: theme, isEditing: widget.isEditing),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.p16,
                    AppSpacing.p8,
                    AppSpacing.p16,
                    AppSpacing.p24,
                  ),
                  children: [
                    _FieldLabel(theme: theme, label: context.l10n.templateNameLabel.toUpperCase()),
                    SizedBox(height: AppSpacing.p8),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: context.l10n.templateNameHint,
                      ),
                    ),
                    SizedBox(height: AppSpacing.p24),
                    Row(
                      children: [
                        _FieldLabel(theme: theme, label: context.l10n.statExercises.toUpperCase()),
                        SizedBox(width: AppSpacing.p8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_drafts.length}',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.secondaryColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.p12),
                    for (var i = 0; i < _drafts.length; i++) ...[
                      _ExerciseEditor(
                        key: ObjectKey(_drafts[i]),
                        theme: theme,
                        index: i,
                        draft: _drafts[i],
                        canRemove: _drafts.length > 1,
                        onRemove: () => _removeExercise(i),
                        onSets: (v) => setState(() => _drafts[i].sets = v),
                        onReps: (v) => setState(() => _drafts[i].reps = v),
                      ),
                      SizedBox(height: AppSpacing.p12),
                    ],
                    _AddExerciseButton(theme: theme, onTap: _addExercise),
                  ],
                ),
              ),
              _SaveBar(
                theme: theme,
                label: widget.isEditing ? context.l10n.saveChanges : context.l10n.createTemplate,
                saving: _saving,
                onTap: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorHeader extends StatelessWidget {
  final ThemeData theme;
  final bool isEditing;

  const _EditorHeader({required this.theme, required this.isEditing});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.p8, AppSpacing.p8, AppSpacing.p16, AppSpacing.p8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(PhosphorIconsBold.arrowLeft, color: cs.onSurface, size: 20),
          ),
          SizedBox(width: AppSpacing.p4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? context.l10n.edit.toUpperCase() : context.l10n.newLabel.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontSize: 10,
                ),
              ),
              Text(
                context.l10n.workoutTemplateTitle,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseEditor extends StatelessWidget {
  final ThemeData theme;
  final int index;
  final _ExerciseDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<int> onSets;
  final ValueChanged<int> onReps;

  const _ExerciseEditor({
    super.key,
    required this.theme,
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
    required this.onSets,
    required this.onReps,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.p12),
              Expanded(
                child: TextField(
                  controller: draft.name,
                  textCapitalization: TextCapitalization.words,
                  style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: context.l10n.exerciseNameHint,
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: context.l10n.remove,
                  onPressed: onRemove,
                  icon: Icon(PhosphorIconsRegular.trash, size: 18, color: cs.error),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          Row(
            children: [
              Expanded(
                child: _Stepper(
                  theme: theme,
                  label: context.l10n.statSets.toUpperCase(),
                  value: draft.sets,
                  onChanged: (v) => onSets(v.clamp(1, 50)),
                ),
              ),
              SizedBox(width: AppSpacing.p12),
              Expanded(
                child: _Stepper(
                  theme: theme,
                  label: context.l10n.repsLabel.toUpperCase(),
                  value: draft.reps,
                  onChanged: (v) => onReps(v.clamp(1, 100)),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          TextField(
            controller: draft.weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true,
              labelText: context.l10n.targetWeightOptional,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.theme,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            fontSize: 9.5,
          ),
        ),
        SizedBox(height: AppSpacing.p4 + 2),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              _StepBtn(
                icon: PhosphorIconsBold.minus,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(value - 1);
                },
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              _StepBtn(
                icon: PhosphorIconsBold.plus,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(value + 1);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Icon(icon, size: 15, color: AppColors.secondaryColor),
      ),
    );
  }
}

class _AddExerciseButton extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onTap;

  const _AddExerciseButton({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.secondaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.secondaryColor.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIconsBold.plus, size: 15, color: AppColors.secondaryColor),
            SizedBox(width: AppSpacing.p8),
            Text(
              context.l10n.addExercise,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final bool saving;
  final VoidCallback? onTap;

  const _SaveBar({
    required this.theme,
    required this.label,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.p16,
        AppSpacing.p12,
        AppSpacing.p16,
        AppSpacing.p12,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondaryColor,
                AppColors.secondaryColor.withValues(alpha: 0.82),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: saving
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primaryColor),
                )
              : Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Assign sheet — premium client + date picker.
// ===========================================================================

class AssignWorkoutSheet extends StatefulWidget {
  final WorkoutTemplate template;
  final List<AppUser> clients;

  const AssignWorkoutSheet({
    super.key,
    required this.template,
    required this.clients,
  });

  @override
  State<AssignWorkoutSheet> createState() => _AssignWorkoutSheetState();
}

class _AssignWorkoutSheetState extends State<AssignWorkoutSheet> {
  late String _clientId = widget.clients.first.uid;
  DateTime _date = DateTime.now();

  // Recurrence. When [_weekly] is on, the workout repeats on the chosen
  // [_weekdays] (1 = Mon … 7 = Sun) for [_weeks] weeks, anchored to [_date].
  bool _weekly = false;
  late final Set<int> _weekdays = {_date.weekday};
  // Until the coach edits the weekday picker, the selected weekday tracks the
  // start date so "Weekly" defaults to repeating on the start day's weekday.
  bool _weekdaysTouched = false;
  int _weeks = 4;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _setDate(DateTime d) {
    setState(() {
      _date = DateTime(d.year, d.month, d.day);
      if (!_weekdaysTouched) {
        _weekdays
          ..clear()
          ..add(_date.weekday);
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _date,
    );
    if (picked == null) return;
    _setDate(picked);
  }

  /// Resolves the recurrence into concrete days. Single day when not weekly;
  /// otherwise every selected weekday across [_weeks] weeks from the anchor
  /// week, skipping any day that falls before the start date.
  List<DateTime> _resolveDates() {
    final anchor = DateTime(_date.year, _date.month, _date.day);
    if (!_weekly || _weekdays.isEmpty) return [anchor];

    // Monday of the anchor's week, so week offsets line up to calendar weeks.
    final anchorMonday = anchor.subtract(Duration(days: anchor.weekday - 1));
    final out = <DateTime>[];
    for (var w = 0; w < _weeks; w++) {
      for (final wd in _weekdays) {
        final day = anchorMonday.add(Duration(days: w * 7 + (wd - 1)));
        if (!day.isBefore(anchor)) out.add(day);
      }
    }
    out.sort();
    return out;
  }

  void _toggleWeekday(int wd) {
    HapticFeedback.selectionClick();
    setState(() {
      _weekdaysTouched = true;
      if (_weekdays.contains(wd)) {
        if (_weekdays.length > 1) _weekdays.remove(wd); // keep at least one
      } else {
        _weekdays.add(wd);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final isCustom = !_isSameDay(_date, today) && !_isSameDay(_date, tomorrow);
    final resolved = _resolveDates();

    return Container(
      // Never taller than the screen — the content scrolls instead of
      // overflowing when the Weekly options + weekday picker expand.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
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
        child: SingleChildScrollView(
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
              context.l10n.assignWorkout.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                fontSize: 10,
              ),
            ),
            SizedBox(height: 2),
            Text(
              widget.template.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: AppSpacing.p20),
            _FieldLabel(theme: theme, label: context.l10n.roleClient.toUpperCase()),
            SizedBox(height: AppSpacing.p8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.clients.length,
                separatorBuilder: (_, _) => SizedBox(height: AppSpacing.p8),
                itemBuilder: (context, index) {
                  final client = widget.clients[index];
                  final selected = client.uid == _clientId;
                  return _ClientPick(
                    theme: theme,
                    name: client.name,
                    selected: selected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _clientId = client.uid);
                    },
                  );
                },
              ),
            ),
            SizedBox(height: AppSpacing.p20),
            _FieldLabel(theme: theme, label: context.l10n.whenLabel.toUpperCase()),
            SizedBox(height: AppSpacing.p8),
            Row(
              children: [
                _DateChip(
                  theme: theme,
                  label: context.l10n.todayLabel,
                  active: _isSameDay(_date, today),
                  onTap: () => _setDate(today),
                ),
                SizedBox(width: AppSpacing.p8),
                _DateChip(
                  theme: theme,
                  label: context.l10n.tomorrowLabel,
                  active: _isSameDay(_date, tomorrow),
                  onTap: () => _setDate(tomorrow),
                ),
                SizedBox(width: AppSpacing.p8),
                _DateChip(
                  theme: theme,
                  label: isCustom ? '${_date.day}/${_date.month}' : context.l10n.pickLabel,
                  active: isCustom,
                  icon: PhosphorIconsRegular.calendarBlank,
                  onTap: _pickDate,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.p20),
            _FieldLabel(theme: theme, label: context.l10n.repeatLabel.toUpperCase()),
            SizedBox(height: AppSpacing.p8),
            Row(
              children: [
                _DateChip(
                  theme: theme,
                  label: context.l10n.justOnce,
                  active: !_weekly,
                  onTap: () => setState(() => _weekly = false),
                ),
                SizedBox(width: AppSpacing.p8),
                _DateChip(
                  theme: theme,
                  label: context.l10n.weeklyLabel,
                  active: _weekly,
                  icon: PhosphorIconsRegular.repeat,
                  onTap: () => setState(() => _weekly = true),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _weekly
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: AppSpacing.p16),
                        _WeekdayPicker(
                          theme: theme,
                          selected: _weekdays,
                          onToggle: _toggleWeekday,
                        ),
                        SizedBox(height: AppSpacing.p16),
                        _WeeksStepper(
                          theme: theme,
                          weeks: _weeks,
                          onChanged: (v) => setState(() => _weeks = v.clamp(1, 12)),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(height: AppSpacing.p16),
            _AssignSummary(theme: theme, count: resolved.length, weekly: _weekly),
            SizedBox(height: AppSpacing.p16),
            GestureDetector(
              onTap: resolved.isEmpty
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop(AssignResult(_clientId, resolved));
                    },
              child: Opacity(
                opacity: resolved.isEmpty ? 0.5 : 1,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondaryColor,
                        AppColors.secondaryColor.withValues(alpha: 0.82),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIconsFill.paperPlaneTilt, size: 16, color: AppColors.primaryColor),
                      SizedBox(width: AppSpacing.p8),
                      Text(
                        resolved.length > 1 ? context.l10n.assignNWorkouts(resolved.length) : context.l10n.assignWorkoutBtn,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Weekday multi-select (Mon-first). Selected days are gold-filled; tapping the
/// last remaining day is a no-op so a weekly schedule always has ≥1 day.
class _WeekdayPicker extends StatelessWidget {
  final ThemeData theme;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  const _WeekdayPicker({
    required this.theme,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Row(
      children: [
        for (var wd = 1; wd <= 7; wd++) ...[
          if (wd > 1) SizedBox(width: AppSpacing.p8),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(wd),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected.contains(wd)
                      ? AppColors.secondaryColor.withValues(alpha: 0.16)
                      : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected.contains(wd)
                        ? AppColors.secondaryColor.withValues(alpha: 0.5)
                        : cs.outlineVariant.withValues(alpha: 0.3),
                    width: selected.contains(wd) ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  MaterialLocalizations.of(context).narrowWeekdays[wd % 7],
                  style: textTheme.labelLarge?.copyWith(
                    color: selected.contains(wd)
                        ? AppColors.secondaryColor
                        : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact "− N weeks +" duration control for a weekly schedule.
class _WeeksStepper extends StatelessWidget {
  final ThemeData theme;
  final int weeks;
  final ValueChanged<int> onChanged;

  const _WeeksStepper({
    required this.theme,
    required this.weeks,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            context.l10n.durationLabel,
            style: textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _StepBtn(
            icon: PhosphorIconsBold.minus,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(weeks - 1);
            },
          ),
          SizedBox(
            width: 78,
            child: Text(
              context.l10n.weekDuration(weeks),
              textAlign: TextAlign.center,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ),
          _StepBtn(
            icon: PhosphorIconsBold.plus,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(weeks + 1);
            },
          ),
        ],
      ),
    );
  }
}

/// A one-line confirmation of exactly how many days will be scheduled.
class _AssignSummary extends StatelessWidget {
  final ThemeData theme;
  final int count;
  final bool weekly;

  const _AssignSummary({required this.theme, required this.count, required this.weekly});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final empty = count == 0;
    final text = empty
        ? context.l10n.noDaysInRange
        : context.l10n.schedulesDays(count);
    return Row(
      children: [
        Icon(
          empty
              ? PhosphorIconsRegular.warningCircle
              : weekly
                  ? PhosphorIconsRegular.calendarCheck
                  : PhosphorIconsRegular.calendarBlank,
          size: 15,
          color: empty ? AppColors.statusYellow : AppColors.secondaryColor,
        ),
        SizedBox(width: AppSpacing.p8),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClientPick extends StatelessWidget {
  final ThemeData theme;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _ClientPick({
    required this.theme,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? 'U'
        : parts.length == 1
            ? parts.first[0].toUpperCase()
            : '${parts.first[0]}${parts.last[0]}'.toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondaryColor,
                    AppColors.secondaryColor.withValues(alpha: 0.25),
                  ],
                ),
              ),
              child: CircleAvatar(
                backgroundColor: cs.surface,
                child: Text(
                  initials,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.p12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Icon(
              selected ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
              color: selected ? AppColors.secondaryColor : cs.onSurfaceVariant.withValues(alpha: 0.4),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final bool active;
  final IconData? icon;
  final VoidCallback onTap;

  const _DateChip({
    required this.theme,
    required this.label,
    required this.active,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? AppColors.secondaryColor.withValues(alpha: 0.14)
                : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? AppColors.secondaryColor.withValues(alpha: 0.5)
                  : cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 13,
                    color: active ? AppColors.secondaryColor : cs.onSurfaceVariant),
                SizedBox(width: AppSpacing.p4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: active ? AppColors.secondaryColor : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Shared.
// ===========================================================================

class _FieldLabel extends StatelessWidget {
  final ThemeData theme;
  final String label;

  const _FieldLabel({required this.theme, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        fontSize: 10,
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Widget child;
  const _Glow({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.7, -1.0),
          radius: 1.1,
          colors: [
            AppColors.secondaryColor.withValues(alpha: 0.10),
            AppColors.secondaryColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.7],
        ),
      ),
      child: child,
    );
  }
}
