import 'package:flutter/material.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import '../catalog/team_loan_tile.dart';
import 'chrome.dart';

/// Navy navigation panel: brand, destinations (active = white pill), pending
/// badge on the loans destination, account chip. Used as the wide rail and
/// inside the phone drawer.
class RailContent extends StatelessWidget {
  const RailContent({
    required this.destinations,
    required this.selected,
    required this.onSelect,
    required this.isAdmin,
    required this.name,
    required this.pending,
    super.key,
  });
  final List<(String, IconData)> destinations;
  final int selected, pending;
  final ValueChanged<int> onSelect;
  final bool isAdmin;
  final String name;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          child: Row(
            children: [
              const WhiteLogo(size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventaris Scitech',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      isAdmin ? 'Admin' : 'Peminjam',
                      style: const TextStyle(
                        color: AppColors.navyMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (var i = 0; i < destinations.length; i++)
                _RailItem(
                  icon: destinations[i].$2,
                  label: destinations[i].$1,
                  selected: selected == i,
                  badge: destinations[i].$1.startsWith('Pinjaman')
                      ? pending
                      : 0,
                  onTap: () => onSelect(i),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _AccountChip(
          name: name,
          role: isAdmin ? 'Administrator' : 'Peminjam',
          onTap: () => onSelect(destinations.length - 1),
        ),
      ],
    ),
  );
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = reducedMotion(context)
        ? Duration.zero
        : snappyCurve.duration;
    final fg = selected ? AppColors.navy : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: PressSpring(
        child: Semantics(
          selected: selected,
          button: true,
          child: AnimatedContainer(
            duration: duration,
            curve: snappyCurve,
            decoration: BoxDecoration(
              color: selected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.control),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.control),
                onTap: onTap,
                child: SizedBox(
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 22,
                          color: selected
                              ? AppColors.navy
                              : AppColors.navyMuted,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: fg,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (badge > 0)
                          Container(
                            constraints: const BoxConstraints(minWidth: 24),
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$badge',
                              semanticsLabel: '$badge menunggu',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
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

class _AccountChip extends StatelessWidget {
  const _AccountChip({
    required this.name,
    required this.role,
    required this.onTap,
  });
  final String name, role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PressSpring(
    child: Material(
      color: AppColors.navy2,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.control),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
                padding: const EdgeInsets.all(2),
                child: PersonAvatar(name, size: 36),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      role,
                      style: const TextStyle(
                        color: AppColors.navyMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
