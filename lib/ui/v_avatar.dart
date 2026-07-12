/// [VAvatar] — people are circles, things (workouts/templates) are squircles
/// r14. Identity data-tint @ 16% fill + tint-colored initials w800. No rings,
/// no status colors on avatars (design.md §2).
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

enum VAvatarShape { circle, squircle }

class VAvatar extends StatelessWidget {
  const VAvatar({
    super.key,
    required this.name,
    this.shape = VAvatarShape.circle,
    this.size = 40,
    this.imageUrl,
  });

  /// Drives both the initials and the (stable) identity tint.
  final String name;
  final VAvatarShape shape;

  /// 40 in rows, 56 for a detail hero.
  final double size;

  /// When present, the photo fills the shape; initials are the fallback.
  final String? imageUrl;

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final w = parts.first;
      return w.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  BorderRadius get _radius => shape == VAvatarShape.circle
      ? BorderRadius.circular(size / 2)
      : BorderRadius.circular(VRadius.squircle);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tint = t.identityTint(name);

    final Widget fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.tintFill(tint),
        borderRadius: _radius,
      ),
      child: Text(
        _initials(name),
        style: VType.stat(size * 0.34).copyWith(color: tint),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: _radius,
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}
