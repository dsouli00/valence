/// A coach-defined custom habit for a specific client. Tracked daily *on top of*
/// the core water / sleep / weight pillars (which are unchanged). [icon] is a
/// key into the home screen's habit-icon map.
class HabitDefinition {
  final String id;
  final String name;
  final String icon;

  const HabitDefinition({
    required this.id,
    required this.name,
    this.icon = 'check',
  });

  factory HabitDefinition.fromJson(Map<String, dynamic> json) {
    return HabitDefinition(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? 'check',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'icon': icon};

  HabitDefinition copyWith({String? name, String? icon}) =>
      HabitDefinition(id: id, name: name ?? this.name, icon: icon ?? this.icon);
}
