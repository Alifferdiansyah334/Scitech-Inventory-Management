import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/motion.dart';
import '../../ui/physics.dart';
import '../../ui/shapes.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import 'request_parts.dart';

/// Saved request in the AgroLens 'Tersimpan · lihat' state of the result
/// screen (confirmation does not imply approval): the check in a large burst
/// shape pops in and throws shapes once, the headline springs up word by
/// word, the request sits in an outlined card radius 28, WhatsApp is one
/// tappable card, and the bar holds the tonal 'saved' call to action.
class RequestSuccessView extends StatefulWidget {
  const RequestSuccessView({
    required this.item,
    required this.quantity,
    required this.presetDays,
    required this.due,
    required this.purpose,
    required this.onWhatsApp,
    required this.onDone,
    super.key,
  });
  final InventoryItem item;
  final int quantity;
  final int? presetDays;
  final DateTime due;
  final String purpose;
  final VoidCallback? onWhatsApp;
  final VoidCallback onDone;

  @override
  State<RequestSuccessView> createState() => _RequestSuccessViewState();
}

class _RequestSuccessViewState extends State<RequestSuccessView> {
  final _badge = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final badge = _badge.currentContext;
      if (!mounted || badge == null) return;
      final scheme = context.colors;
      ShapeBurst.show(
        context,
        origin: ShapeBurst.centerOf(badge),
        count: 22,
        colors: [scheme.primary, scheme.tertiary, scheme.secondary, context.palette.hero],
      );
    });
  }

  /// "Jumlah ........ 2 unit"; the value moves under its label when there
  /// is no room beside it.
  Widget _fact(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: LayoutBuilder(
      builder: (context, box) {
        final title = Text(label, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant));
        final stacked = box.maxWidth < 280 || MediaQuery.textScalerOf(context).scale(14) > 20;
        final content = Text(
          value,
          textAlign: stacked ? TextAlign.start : TextAlign.end,
          style: context.text.titleSmall?.copyWith(fontFeatures: tabular),
        );
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [title, const SizedBox(height: 2), content],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(width: 16),
            Expanded(child: content),
          ],
        );
      },
    ),
  );

  Widget _top() => Column(
    children: [
      ExcludeSemantics(
        child: PopIn(
          child: ShapeIcon(
            key: _badge,
            icon: Icons.check_rounded,
            shape: ExpressiveShape.burst,
            size: 132,
            iconScale: .46,
            fill: context.colors.primary,
            foreground: context.colors.onPrimary,
          ),
        ),
      ),
      const SizedBox(height: 24),
      Semantics(
        liveRegion: true,
        header: true,
        child: Center(
          child: WordReveal('Pengajuan terkirim', style: context.text.headlineMedium?.copyWith(height: 1.12)),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Admin meninjau permintaanmu. Kabar berikutnya muncul di Pinjaman.',
        textAlign: TextAlign.center,
        style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
      ),
    ],
  );

  /// Outlined white card radius 28 (the AgroLens verdict): the status, the
  /// item with its category shape, then the request facts.
  Widget _summary() => Material(
    color: context.colors.surfaceContainerLowest,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
      side: BorderSide(color: context.colors.outlineVariant.withValues(alpha: .6)),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusPill('Menunggu persetujuan admin', tone: Tone.waiting),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.name, style: context.text.headlineSmall?.copyWith(height: 1.15)),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.category,
                      style: context.text.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ExcludeSemantics(child: ShapeIcon.category(widget.item.category, size: 56)),
            ],
          ),
          const SizedBox(height: 12),
          _fact('Jumlah', '${widget.quantity} unit'),
          if (widget.presetDays != null) _fact('Lama pinjam', '${widget.presetDays} hari'),
          _fact('Batas kembali', longDate(widget.due)),
          _fact('Keperluan', widget.purpose),
        ],
      ),
    ),
  );

  /// White row card that opens the WhatsApp draft.
  Widget _whatsApp() => SurfaceCard(
    onTap: widget.onWhatsApp,
    radius: 24,
    padding: const EdgeInsets.all(10),
    child: Row(
      children: [
        ShapeIcon(
          icon: Icons.chat_outlined,
          shape: ExpressiveShape.cookie12,
          size: 52,
          fill: context.colors.secondaryContainer,
          foreground: context.colors.onSecondaryContainer,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hubungi admin via WhatsApp', style: context.text.titleSmall),
              const SizedBox(height: 2),
              Text(
                'Pesan pengajuan disiapkan. Tekan Kirim di WhatsApp untuk mengirimnya.',
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ShapeIcon(
          icon: Icons.arrow_forward_rounded,
          shape: ExpressiveShape.cookie9,
          size: 34,
          fill: context.colors.surfaceContainerHighest,
          foreground: context.colors.primary,
          iconScale: .5,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    child: Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          children: [
            centered(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _top(),
                  const SizedBox(height: 28),
                  Reveal(child: TiltOnTouch(maxAngle: .05, child: _summary())),
                  if (widget.onWhatsApp != null) ...[const SizedBox(height: 12), Reveal(index: 1, child: _whatsApp())],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.outlineVariant.withValues(alpha: .5))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: centered(
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52, minWidth: double.infinity),
                child: FilledButton.tonalIcon(
                  onPressed: widget.onDone,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Lihat status pinjaman', textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
