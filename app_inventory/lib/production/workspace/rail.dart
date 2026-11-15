import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../ui/button_feedback.dart';
import '../../core/appearance.dart';
import '../../core/brand.dart';
import '../../ui/avatars.dart';
import '../../ui/motion.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import 'chrome.dart';
import 'shell.dart';

/// Expanded navigation rail on the container background (wide layouts),
/// built like the AgroLens brand bar and dock: bobbing logo with the name in
/// titleMedium primary, destinations as pills (selected = secondary pill
/// whose badge morphs into the destination's shape on a bouncy spring),
/// the waiting count on the loans destination and the signed-in account
/// with sign-out at the foot.
class RailContent extends StatelessWidget {
  const RailContent({
    required this.destinations,
    required this.selected,
    required this.onSelect,
    required this.isAdmin,
    required this.name,
    required this.email,
    required this.userId,
    required this.pending,
    required this.onSignOut,
    super.key,
  });
  final List<NavDest> destinations;
  final int selected, pending;
  final ValueChanged<int> onSelect;
  final bool isAdmin;
  final String name, email, userId;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
        child: Row(
          children: [
            Bob(distance: 3, child: WhiteLogo(size: 30, color: context.colors.primary)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appName, style: context.text.titleMedium?.copyWith(color: context.colors.primary)),
                  Text(
                    isAdmin ? 'Admin' : 'Peminjam',
                    style: context.text.labelMedium?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (var i = 0; i < destinations.length; i++)
              _RailItem(
                dest: destinations[i],
                selected: selected == i,
                badge: destinations[i].label.startsWith('Pinjaman') ? pending : 0,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
      _AccountRow(
        name: name,
        email: email,
        userId: userId,
        onTap: () => onSelect(destinations.length - 1),
        onSignOut: onSignOut,
      ),
    ],
  );
}

/// One destination: a pill that fills with the secondary container when
/// selected while its round badge morphs into the destination's shape and
/// turns (like the dock). Held, it squashes on the press spring.
class _RailItem extends StatelessWidget {
  const _RailItem({required this.dest, required this.selected, required this.badge, required this.onTap});
  final NavDest dest;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final curve = SpringCurve(AppSprings.bouncy);
    final label = context.text.labelLarge;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: PressSpring(
        scale: .97,
        squash: .05,
        child: Semantics(
          selected: selected,
          button: true,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: selected ? 1 : 0),
            duration: reducedMotion(context) ? Duration.zero : curve.duration,
            curve: curve,
            builder: (context, s, _) {
              final t = s.clamp(0.0, 1.0);
              final radius = BorderRadius.circular(AppRadii.lg + 12 * t);
              return Material(
                color: Color.lerp(Colors.transparent, AppColors.secondary, t),
                shape: RoundedRectangleBorder(borderRadius: radius),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: RoundedRectangleBorder(borderRadius: radius),
                  onTap: tactileTap(onTap),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          SizedBox.square(
                            dimension: 38,
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                color: Color.lerp(Colors.transparent, AppColors.brand, t),
                                shape: ExpressiveShapeBorder(
                                  ExpressiveShape.circle,
                                  morphTo: dest.shape,
                                  morph: s.clamp(0, 1.25),
                                  rotation: s * .65 * math.pi / 3,
                                ),
                              ),
                              child: Icon(
                                selected ? dest.selectedIcon : dest.icon,
                                size: 20,
                                color: Color.lerp(AppColors.muted, AppColors.onBrand, t),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              dest.label,
                              style: label?.copyWith(
                                color: selected ? AppColors.onSecondary : AppColors.muted,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (badge > 0) _CountBadge(badge),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Count of requests waiting on the admin, in the deadline tone.
class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 24, minWidth: 28),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    alignment: Alignment.center,
    decoration: BoxDecoration(color: AppColors.deadlineContainer, borderRadius: BorderRadius.circular(AppRadii.full)),
    child: Text(
      '$count',
      semanticsLabel: '$count menunggu',
      style: context.text.labelMedium?.copyWith(color: AppColors.onDeadlineContainer, fontFeatures: tabular),
    ),
  );
}

/// Signed-in person at the foot of the rail on a white card (radius 24):
/// picture, name and email open the account section; the trailing button
/// signs out.
class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.name,
    required this.email,
    required this.userId,
    required this.onTap,
    required this.onSignOut,
  });
  final String name, email, userId;
  final VoidCallback onTap;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final avatar = AppearanceScope.of(context).avatarFor(userId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: tactileTap(onTap),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ProfileAvatar(preset: avatar.presetSpec, photo: avatar.photo, frame: avatar.frame, size: 44),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: context.text.titleSmall),
                            if (email.isNotEmpty)
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.bodySmall?.copyWith(color: AppColors.muted),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Keluar',
              onPressed: onSignOut,
              style: IconButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: AppColors.error),
              icon: const Icon(Icons.logout_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
