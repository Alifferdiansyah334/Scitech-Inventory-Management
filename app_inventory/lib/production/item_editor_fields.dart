part of 'item_editor.dart';

/// 16:9 cover (radius 28): the picked photo, else the item's photo, else a
/// shaped add badge with the invitation. A photo gets a 'Ganti' pill.
class _CoverPicker extends StatelessWidget {
  const _CoverPicker({required this.photo, required this.current, required this.state, required this.onTap});
  final Future<Uint8List>? photo;
  final String current;
  final AppState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(28));
    final Widget? image = photo != null
        ? FutureBuilder<Uint8List>(
            future: photo,
            builder: (context, snap) => snap.hasData
                ? Image.memory(snap.data!, fit: BoxFit.cover)
                : ColoredBox(color: scheme.surfaceContainerHighest),
          )
        : current.isNotEmpty
        ? Image.network(
            state.api.imageUrl(current),
            headers: state.api.authHeaders,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(color: scheme.surfaceContainerHighest),
          )
        : null;
    final body = image == null
        ? Padding(
            padding: const EdgeInsets.all(12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShapeIcon(
                    icon: Icons.add_photo_alternate_outlined,
                    shape: ExpressiveShape.cookie12,
                    size: 60,
                    fill: scheme.secondaryContainer,
                    foreground: scheme.onSecondaryContainer,
                  ),
                  const SizedBox(height: 10),
                  Text('Tambahkan foto barang', style: context.text.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    'Opsional · maks. 2 MB',
                    style: context.text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          )
        : Stack(
            fit: StackFit.expand,
            children: [
              image,
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: scheme.surfaceContainerLowest.withValues(alpha: .92),
                      shape: const StadiumBorder(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShapeIcon(
                            icon: Icons.swap_horiz_rounded,
                            shape: ExpressiveShape.cookie9,
                            size: 24,
                            fill: scheme.primary,
                            foreground: scheme.onPrimary,
                            iconScale: .58,
                          ),
                          const SizedBox(width: 6),
                          Text('Ganti', style: context.text.labelLarge),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
    return Semantics(
      button: true,
      label: image == null ? 'Pilih foto barang' : 'Ganti foto barang',
      child: PressSpring(
        enabled: onTap != null,
        scale: .98,
        squash: .05,
        child: Material(
          color: scheme.surfaceContainerHigh,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: shape,
            onTap: tactileTap(onTap),
            enableFeedback: false,
            child: AspectRatio(aspectRatio: 16 / 9, child: body),
          ),
        ),
      ),
    );
  }
}

/// Category card (radius 26, padding 12): a 38 badge in the category's
/// shape, the current choice as a pill, the existing categories as chips
/// and a well for typing a new one.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.controller,
    required this.options,
    required this.enabled,
    required this.validator,
  });
  final TextEditingController controller;
  final List<String> options;
  final bool enabled;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final current = controller.text.trim();
        final style = categoryStyle(current);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: .32)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ShapeIcon(
                      icon: style.icon,
                      shape: style.shape,
                      size: 38,
                      fill: context.palette.hero,
                      foreground: context.palette.onHero,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Kategori', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    if (current.isNotEmpty)
                      Flexible(
                        child: DecoratedBox(
                          decoration: ShapeDecoration(color: scheme.secondaryContainer, shape: const StadiumBorder()),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Text(
                              current,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelSmall?.copyWith(
                                color: scheme.onSecondaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (options.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in options)
                        ExpressiveFilterChip(
                          label: option,
                          shape: categoryStyle(option).shape,
                          icon: categoryStyle(option).icon,
                          selected: current == option,
                          onSelected: () {
                            if (!enabled) return;
                            controller.text = option;
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TextFormField(
                    controller: controller,
                    enabled: enabled,
                    maxLength: 160,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: validator,
                    style: context.text.bodyLarge?.copyWith(height: 1.55),
                    decoration: _wellDecoration(
                      context,
                      options.isEmpty ? 'Ketik kategori, mis. Kamera' : 'Atau ketik kategori baru',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
