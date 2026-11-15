part of 'auth_entry.dart';

extension _AuthFrameBrand on _AuthFrameState {
  Widget _brandBar() {
    final fg = context.colors.primary;
    final top = widget.step.top;
    final onBack = widget.step.onBack;
    return Padding(
      padding: EdgeInsets.fromLTRB(onBack != null ? 8 : 20, 8, 14, 8),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              tooltip: 'Kembali',
              onPressed: onBack,
              style: IconButton.styleFrom(backgroundColor: fg.withValues(alpha: .15), foregroundColor: fg),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 8),
          ],
          AuthLogo(color: fg, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appName,
                  maxLines: 1,
                  style: context.text.titleMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6,
                    height: 1.1,
                  ),
                ),
                Text(
                  appTagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          ?top,
        ],
      ),
    );
  }
}
