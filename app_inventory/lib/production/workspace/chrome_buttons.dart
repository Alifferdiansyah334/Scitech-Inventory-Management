part of 'chrome.dart';

/// Tonal action button (secondary container); [danger] uses the error tone.
Widget tonalAction(String label, IconData icon, VoidCallback? onPressed, {bool danger = false}) => FilledButton.icon(
  style: FilledButton.styleFrom(
    backgroundColor: danger ? AppColors.errorContainer : AppColors.secondary,
    foregroundColor: danger ? AppColors.onErrorContainer : AppColors.onSecondary,
    minimumSize: const Size(48, 56),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  ),
  onPressed: onPressed,
  icon: Icon(icon, size: 18),
  label: Text(label),
);

/// Shape of one button in a connected group: outer corners fully round,
/// inner corners small. [pill] keeps every corner round (the primary or
/// selected segment).
OutlinedBorder connectedShape(double height, {required bool first, required bool last, bool pill = false}) {
  final full = Radius.circular(height / 2);
  const inner = Radius.circular(AppRadii.sm);
  if (pill) return const StadiumBorder();
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.horizontal(left: first ? full : inner, right: last ? full : inner),
  );
}

/// Buttons joined by a 2 px gap with proportional widths ([flex]). Stacks
/// vertically when enlarged text or a narrow box leaves no room.
class ConnectedButtons extends StatelessWidget {
  const ConnectedButtons({required this.children, this.flex, super.key});
  final List<Widget> children;
  final List<int>? flex;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      if (box.maxWidth / children.length < 120 * scale) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: AppSpace.sm), children[i]],
          ],
        );
      }
      return Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(flex: flex?[i] ?? 1, child: children[i]),
          ],
        ],
      );
    },
  );
}
