part of 'admin_rows.dart';

const _avatarShapes = [
  ExpressiveShape.cookie9,
  ExpressiveShape.clover4,
  ExpressiveShape.pentagon,
  ExpressiveShape.gem,
  ExpressiveShape.cookie12,
  ExpressiveShape.softBurst,
  ExpressiveShape.flower8,
];

int _stableHash(String text) => text.codeUnits.fold(7, (hash, unit) => (hash * 31 + unit) & 0x7fffffff);

/// A person's initials in an expressive shape. Shape and tint are stable per
/// name; inside a [PressSpring] the outline rounds and turns while held.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {this.size = 40, super.key});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hash = _stableHash(name.trim().toLowerCase());
    final shape = _avatarShapes[hash % _avatarShapes.length];
    final (fill, ink) = AppColors.category(CategoryTone.values[(hash ~/ 7) % CategoryTone.values.length]);
    final press = PressSpring.progressOf(context);
    Widget body(double p) => DecoratedBox(
      decoration: ShapeDecoration(
        color: fill,
        shape: ExpressiveShapeBorder(shape, morph: p * .85, rotation: p * math.pi / 6),
      ),
      child: Center(
        child: Text(
          _initials(name),
          maxLines: 1,
          textScaler: TextScaler.noScaling,
          style: TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: size * 0.34, height: 1),
        ),
      ),
    );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: press == null ? body(0) : AnimatedBuilder(animation: press, builder: (context, _) => body(press.value)),
      ),
    );
  }
}
