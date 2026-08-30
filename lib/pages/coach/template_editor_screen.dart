import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/user_model.dart';
import 'package:valence/models/workout_models.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/ui/ui.dart';
import 'package:valence/utils/units.dart';

/// Result returned by [AssignWorkoutSheet]. [dates] is the full set of days the
/// workout should be assigned on — one day for a single assignment, or several
/// for recurring/weekly programming (already resolved to concrete days).
class AssignResult {
  final String clientId;
  final List<DateTime> dates;
  const AssignResult(this.clientId, this.dates);
}

// ===========================================================================
// Template editor — full-screen create / edit on flat canvas (design.md §5.15)
// ===========================================================================

/// Create/edit a workout template: name + a list of exercise drafts (name,
/// sets/reps steppers, optional target weight). One screen, two modes —
/// [template] == null creates, otherwise edits in place.
///
/// DESIGN: v2.2 — VHeader + VFields, exercise cards as quiet `surface` cards
/// with round steppers, pinned VPillButton.primary save. Gradient CTA, glow
/// and uppercase micro-labels retired.
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

  /// The COACH's display unit ('kg'|'lb'). Weights are edited in this unit and
  /// stored as canonical kg (utils/units.dart), like everywhere else.
  String? _unit;
  String get _unitLabel =>
      isMetricWeight(_unit) ? context.l10n.unitKg : context.l10n.unitLb;

  String _fmtWeight(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  void initState() {
    super.initState();
    _unit = context.read<AuthProvider>().currentUser?.weightUnit;
    final t = widget.template;
    if (t != null) {
      _nameController.text = t.name;
      for (final e in t.exercises) {
        final w = e.targetWeightKgBySet.isNotEmpty ? e.targetWeightKgBySet.first : null;
        _drafts.add(_ExerciseDraft(
          name: TextEditingController(text: e.name),
          sets: e.sets,
          reps: e.reps,
          weight: TextEditingController(
              text: w == null ? '' : _fmtWeight(displayWeight(w, _unit))),
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
      // Entered in the coach's unit; stored as canonical kg.
      final kg = parsed == null ? null : weightToKg(parsed, _unit);
      exercises.add(WorkoutExercise(
        name: exName,
        sets: d.sets,
        reps: d.reps,
        targetWeightKgBySet: List.generate(d.sets, (_) => kg),
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
      // Toast first (it lives on the root overlay, so it survives the pop).
      showVToast(
        context,
        widget.isEditing ? context.l10n.templateUpdated : context.l10n.templateCreated,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(context.l10n.couldNotSaveNow);
    }
  }

  void _toast(String msg) {
    showVToast(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsetsDirectional.fromSTEB(
                  VSpace.screenMargin,
                  8,
                  VSpace.screenMargin,
                  VSpace.scrollBottom,
                ),
                children: [
                  VHeader(
                    title: context.l10n.workoutTemplateTitle,
                    subtitle: widget.isEditing
                        ? context.l10n.edit
                        : context.l10n.newLabel,
                    onBack: () => Navigator.of(context).maybePop(),
                    backSemanticLabel: context.l10n.back,
                  ),
                  const SizedBox(height: 20),
                  VField(
                    controller: _nameController,
                    label: context.l10n.templateNameLabel,
                    hint: context.l10n.templateNameHint,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: VSpace.sectionGap),
                  Row(
                    children: [
                      Text(
                        context.l10n.statExercises,
                        style: VType.title2.copyWith(color: t.ink),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_drafts.length}',
                        style: VType.stat(17).copyWith(color: t.inkSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < _drafts.length; i++) ...[
                    _ExerciseEditor(
                      key: ObjectKey(_drafts[i]),
                      index: i,
                      draft: _drafts[i],
                      unitLabel: _unitLabel,
                      canRemove: _drafts.length > 1,
                      onRemove: () => _removeExercise(i),
                      onSets: (v) => setState(() => _drafts[i].sets = v),
                      onReps: (v) => setState(() => _drafts[i].reps = v),
                    ),
                    const SizedBox(height: VSpace.cardGap),
                  ],
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: VTextAction(
                      icon: PhosphorIconsBold.plus,
                      label: context.l10n.addExercise,
                      onTap: _addExercise,
                    ),
                  ),
                ],
              ),
            ),
            // Pinned save bar — surface + top hairline, ink primary pill.
            Container(
              decoration: BoxDecoration(
                color: t.surface,
                border: Border(top: BorderSide(color: t.hairline)),
              ),
              padding: const EdgeInsetsDirectional.fromSTEB(
                  VSpace.screenMargin, 12, VSpace.screenMargin, 16),
              child: VPillButton.primary(
                label: widget.isEditing
                    ? context.l10n.saveChanges
                    : context.l10n.createTemplate,
                loading: _saving,
                onPressed: _saving
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        _save();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise card — quiet `surface` card: numbered gold circle · name field ·
// round sets/reps steppers · optional weight field.
// ---------------------------------------------------------------------------

class _ExerciseEditor extends StatelessWidget {
  final int index;
  final _ExerciseDraft draft;
  final String unitLabel;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<int> onSets;
  final ValueChanged<int> onReps;

  const _ExerciseEditor({
    super.key,
    required this.index,
    required this.draft,
    required this.unitLabel,
    required this.canRemove,
    required this.onRemove,
    required this.onSets,
    required this.onReps,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: t.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.tintFill(t.gold),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: VType.caption.copyWith(
                    color: t.goldDeep,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VField(
                  controller: draft.name,
                  hint: context.l10n.exerciseNameHint,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              if (canRemove)
                Semantics(
                  label: context.l10n.remove,
                  button: true,
                  child: VPressable(
                    onTap: onRemove,
                    semanticButton: false,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(PhosphorIconsRegular.trash,
                          size: 18, color: t.alert),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _StepperRow(
            icon: PhosphorIconsFill.stackSimple,
            tint: t.steel,
            label: context.l10n.statSets,
            value: draft.sets,
            onChanged: (v) => onSets(v.clamp(1, 50)),
          ),
          const SizedBox(height: 6),
          Divider(height: 1, thickness: 1, color: t.hairline),
          const SizedBox(height: 6),
          _StepperRow(
            icon: PhosphorIconsFill.arrowsClockwise,
            tint: t.sage,
            label: context.l10n.repsLabel,
            value: draft.reps,
            onChanged: (v) => onReps(v.clamp(1, 100)),
          ),
          const SizedBox(height: 6),
          Divider(height: 1, thickness: 1, color: t.hairline),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(PhosphorIconsFill.barbell, size: 16, color: t.legibleTint(t.clay)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.targetWeightOptional,
                  style: VType.body.copyWith(
                    color: t.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                // 100, not 124. The field only ever holds three or four digits
                // and a unit, while at 124 the label beside it ran out of room
                // and wrapped — "Target weight · optional" needs about 190dp
                // and had 180. The 24dp comes out of dead space in the field.
                width: 100,
                child: VField(
                  controller: draft.weight,
                  hint: '—',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  suffix: Text(
                    unitLabel,
                    style: VType.caption
                        .copyWith(color: context.tokens.inkTertiary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-width stepper row (design.md §5.15 "quiet steppers", same geometry as
/// the client-details update sheet): tinted glyph · label · round − / + around
/// a bold tabular value. Color lives only on the small glyph (§1.1 data tints).
class _StepperRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    Widget btn(IconData btnIcon, VoidCallback onTap) => VPressable(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.surfaceSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(btnIcon, size: 16, color: t.ink),
          ),
        );

    return Semantics(
      label: '$label $value',
      child: Row(
        children: [
          Icon(icon, size: 16, color: t.legibleTint(tint)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: VType.body.copyWith(
                color: t.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          btn(PhosphorIconsBold.minus, () => onChanged(value - 1)),
          SizedBox(
            width: 60,
            child: VTextScaleCap(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: VType.stat(17).copyWith(color: t.ink),
              ),
            ),
          ),
          btn(PhosphorIconsBold.plus, () => onChanged(value + 1)),
        ],
      ),
    );
  }
}

// ===========================================================================
// Assign sheet — VSheet: client picks (gold-ring cards) · date chips ·
// VSegmented Once/Weekly · weekday grid · summary · pinned CTA (§5.15).
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

  Widget _sectionLabel(String text) {
    final t = context.tokens;
    return Text(
      text,
      style: VType.subhead.copyWith(
        color: t.inkSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final isCustom = !_isSameDay(_date, today) && !_isSameDay(_date, tomorrow);
    final resolved = _resolveDates();

    return VSheet(
      title: widget.template.name,
      pinnedAction: VPillButton.primary(
        label: resolved.length > 1
            ? context.l10n.assignNWorkouts(resolved.length)
            : context.l10n.assignWorkoutBtn,
        onPressed: resolved.isEmpty
            ? null
            : () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(AssignResult(_clientId, resolved));
              },
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context.l10n.roleClient),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.clients.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final client = widget.clients[index];
                return _ClientPick(
                  name: client.name,
                  selected: client.uid == _clientId,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _clientId = client.uid);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel(context.l10n.whenLabel),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PickChip(
                  label: context.l10n.todayLabel,
                  active: _isSameDay(_date, today),
                  onTap: () => _setDate(today),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PickChip(
                  label: context.l10n.tomorrowLabel,
                  active: _isSameDay(_date, tomorrow),
                  onTap: () => _setDate(tomorrow),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PickChip(
                  label: isCustom
                      ? '${_date.day}/${_date.month}'
                      : context.l10n.pickLabel,
                  active: isCustom,
                  icon: PhosphorIconsRegular.calendarBlank,
                  onTap: _pickDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel(context.l10n.repeatLabel),
          const SizedBox(height: 10),
          VSegmented<bool>(
            selected: _weekly,
            onChanged: (v) => setState(() => _weekly = v),
            segments: [
              VSegment(false, context.l10n.justOnce),
              VSegment(true, context.l10n.weeklyLabel),
            ],
          ),
          AnimatedSize(
            duration: VDuration.standard,
            curve: VMotion.curve,
            alignment: Alignment.topCenter,
            child: _weekly
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _WeekdayPicker(
                        selected: _weekdays,
                        onToggle: _toggleWeekday,
                      ),
                      const SizedBox(height: 16),
                      _WeeksStepper(
                        weeks: _weeks,
                        onChanged: (v) => setState(() => _weeks = v.clamp(1, 12)),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          // Summary — exactly how many days will be scheduled.
          Row(
            children: [
              Icon(
                resolved.isEmpty
                    ? PhosphorIconsRegular.warningCircle
                    : _weekly
                        ? PhosphorIconsRegular.calendarCheck
                        : PhosphorIconsRegular.calendarBlank,
                size: 15,
                color: resolved.isEmpty ? t.watch : t.goldDeep,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resolved.isEmpty
                      ? context.l10n.noDaysInRange
                      : context.l10n.schedulesDays(resolved.length),
                  style: VType.subhead.copyWith(color: t.inkSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Client pick — VOptionCard language with a person avatar: `surface` card,
/// VAvatar + name, selected = gold ring + wash (the ONLY selected signal).
class _ClientPick extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _ClientPick({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return VPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: VDuration.standard,
        curve: VMotion.curve,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(t.selectedWash, t.surface)
              : t.surface,
          borderRadius: BorderRadius.circular(VRadius.cardSmall),
          boxShadow: t.cardShadow,
          border: Border.all(
            color: selected ? t.gold : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            VAvatar(name: name, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VType.headline.copyWith(color: t.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick-pick chip (Today / Tomorrow / custom date): `surfaceSubtle` at rest,
/// gold ring + wash when active.
class _PickChip extends StatelessWidget {
  final String label;
  final bool active;
  final IconData? icon;
  final VoidCallback onTap;

  const _PickChip({
    required this.label,
    required this.active,
    this.icon,
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
      child: AnimatedContainer(
        duration: VDuration.micro,
        curve: VMotion.curve,
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: active
              ? Color.alphaBlend(t.selectedWash, t.surface)
              : t.surfaceSubtle,
          borderRadius: BorderRadius.circular(VRadius.input),
          border: Border.all(
            color: active ? t.gold : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: active ? t.goldDeep : t.inkSecondary),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VType.subhead.copyWith(
                  color: active ? t.goldDeep : t.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Weekday multi-select (Mon-first). Selected days carry the gold ring + wash;
/// tapping the last remaining day is a no-op so a weekly schedule always has
/// ≥1 day.
class _WeekdayPicker extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  const _WeekdayPicker({
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final narrow = MaterialLocalizations.of(context).narrowWeekdays;
    return Row(
      children: [
        for (var wd = 1; wd <= 7; wd++) ...[
          if (wd > 1) const SizedBox(width: 6),
          Expanded(
            child: VPressable(
              onTap: () => onToggle(wd),
              child: AnimatedContainer(
                duration: VDuration.micro,
                curve: VMotion.curve,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected.contains(wd)
                      ? Color.alphaBlend(t.selectedWash, t.surface)
                      : t.surfaceSubtle,
                  borderRadius: BorderRadius.circular(VRadius.input),
                  border: Border.all(
                    color: selected.contains(wd) ? t.gold : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  narrow[wd % 7],
                  style: VType.subhead.copyWith(
                    color: selected.contains(wd) ? t.goldDeep : t.inkSecondary,
                    fontWeight: FontWeight.w700,
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
  final int weeks;
  final ValueChanged<int> onChanged;

  const _WeeksStepper({
    required this.weeks,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    Widget btn(IconData icon, VoidCallback onTap) => VPressable(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.surfaceSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: t.ink),
          ),
        );

    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.durationLabel,
            style: VType.subhead.copyWith(color: t.inkSecondary),
          ),
        ),
        btn(PhosphorIconsBold.minus, () => onChanged(weeks - 1)),
        SizedBox(
          width: 96,
          child: VTextScaleCap(
            child: Text(
              context.l10n.weekDuration(weeks),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: VType.stat(15).copyWith(color: t.ink),
            ),
          ),
        ),
        btn(PhosphorIconsBold.plus, () => onChanged(weeks + 1)),
      ],
    );
  }
}
