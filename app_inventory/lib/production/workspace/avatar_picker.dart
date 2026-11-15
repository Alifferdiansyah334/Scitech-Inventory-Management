import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../ui/button_feedback.dart';
import '../../core/appearance.dart';
import '../../ui/avatars.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';

/// Indonesian name of an avatar frame shape.
String frameName(ExpressiveShape frame) => switch (frame) {
  ExpressiveShape.cookie9 => 'Kue',
  ExpressiveShape.clover4 => 'Semanggi',
  ExpressiveShape.sunny8 => 'Matahari',
  ExpressiveShape.gem => 'Permata',
  ExpressiveShape.circle => 'Lingkaran',
  _ => frame.name,
};

/// Illustrated avatars in the current frame shape, four per row; the
/// selected one carries a ring and a check.
class AvatarPresetGrid extends StatelessWidget {
  const AvatarPresetGrid({required this.choice, required this.onChanged, super.key});
  final AvatarChoice choice;
  final ValueChanged<AvatarChoice> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = 8.0;
      final cell = ((box.maxWidth - gap * 3) / 4).floorToDouble().clamp(56.0, 96.0);
      final selectedPreset = choice.photo == null ? choice.preset : null;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var i = 0; i < avatarPresets.length; i++)
            _PresetCell(
              preset: avatarPresets[i],
              frame: choice.frame,
              size: cell,
              selected: i == selectedPreset,
              label: 'Avatar ${i + 1}',
              onTap: () => onChanged(choice.copyWith(preset: i, clearPhoto: true)),
            ),
        ],
      );
    },
  );
}

/// Frame shapes as a connected row; the selected one fills with the brand
/// colour and rounds into a pill.
class FramePicker extends StatelessWidget {
  const FramePicker({required this.choice, required this.onChanged, super.key});
  final AvatarChoice choice;
  final ValueChanged<AvatarChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final duration = reducedMotion(context) ? Duration.zero : fastSpatialCurve.duration;
    return Row(
      children: [
        for (var i = 0; i < avatarFrames.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: true,
              selected: avatarFrames[i] == choice.frame,
              label: 'Bingkai ${frameName(avatarFrames[i])}',
              excludeSemantics: true,
              child: _FrameOption(
                frame: avatarFrames[i],
                selected: avatarFrames[i] == choice.frame,
                duration: duration,
                onTap: () => onChanged(choice.copyWith(frame: avatarFrames[i])),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PresetCell extends StatelessWidget {
  const _PresetCell({
    required this.preset,
    required this.frame,
    required this.size,
    required this.selected,
    required this.label,
    required this.onTap,
  });
  final AvatarPreset preset;
  final ExpressiveShape frame;
  final double size;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: PressSpring(
      scale: .94,
      squash: .1,
      child: SizedBox.square(
        dimension: size,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: ExpressiveShapeBorder(frame),
            onTap: tactileTap(onTap),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ProfileAvatar(preset: preset, frame: frame, size: size - 12, ring: selected ? AppColors.brand : null),
                if (selected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.card, width: 2),
                      ),
                      child: Icon(Icons.check_rounded, size: 16, color: AppColors.onBrand),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _FrameOption extends StatelessWidget {
  const _FrameOption({required this.frame, required this.selected, required this.duration, required this.onTap});
  final ExpressiveShape frame;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(selected ? 28 : AppRadii.md);
    return PressSpring(
      scale: .95,
      squash: .08,
      child: AnimatedContainer(
        duration: duration,
        curve: fastSpatialCurve,
        height: 56,
        decoration: BoxDecoration(color: selected ? AppColors.brand : AppColors.high, borderRadius: radius),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: tactileTap(onTap),
            child: Center(
              child: SizedBox.square(
                dimension: 34,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: selected ? AppColors.onBrand : AppColors.muted,
                    shape: ExpressiveShapeBorder(frame),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Edge of the square profile photo kept on the device.
const _photoSize = 320;

/// Square, upright, small JPEG of [raw]; null when it cannot be decoded.
/// Runs in a background isolate.
Uint8List? squareProfilePhoto(Uint8List raw) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) return null;
  final square = img.copyResizeCropSquare(
    img.bakeOrientation(decoded),
    size: _photoSize,
    interpolation: img.Interpolation.average,
  );
  return Uint8List.fromList(img.encodeJpg(square, quality: 82));
}

/// White editor card (radius 26, pad 16) with a titleMedium heading and an
/// optional value pill, as the AgroLens editor's category card.
class EditorCard extends StatelessWidget {
  const EditorCard({required this.title, required this.child, this.trailing, super.key});
  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(header: true, child: Text(title, style: text.titleMedium)),
                ),
                if (trailing != null)
                  Flexible(
                    child: DecoratedBox(
                      decoration: ShapeDecoration(color: AppColors.secondary, shape: const StadiumBorder()),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                        child: Text(
                          trailing!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelMedium?.copyWith(color: AppColors.onSecondary),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
