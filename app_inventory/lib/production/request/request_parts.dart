import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';

const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// 'Jum, 7 Nov 2026' style date used on the request and receipt.
String longDate(DateTime value) =>
    '${_days[value.weekday - 1]}, ${value.day} ${_months[value.month - 1]} ${value.year}';

/// Content width used by the request form and its success receipt.
const requestMaxWidth = 560.0;

Widget centered(Widget child) => Center(
  heightFactor: 1,
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: requestMaxWidth),
    child: child,
  ),
);

/// White r24 card with a title row, used for each request step.
class RequestCard extends StatelessWidget {
  const RequestCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    super.key,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

/// Navy top area of the request form: back button, title and the item.
class RequestHeader extends StatelessWidget {
  const RequestHeader({required this.item, required this.onBack, super.key});
  final InventoryItem item;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: AppColors.navy,
    padding: EdgeInsets.fromLTRB(
      16,
      MediaQuery.paddingOf(context).top + 12,
      20,
      36,
    ),
    child: centered(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Kembali',
                onPressed: onBack,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ajukan peminjaman',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const IconTile(
                Icons.inventory_2_outlined,
                size: 56,
                background: AppColors.navy2,
                foreground: Colors.white,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navyMuted,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${item.available} unit tersedia',
                          style: const TextStyle(
                            color: AppColors.navyMuted,
                            fontSize: 14,
                          ),
                        ),
                        AssetTag(item.id, dark: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Round minus/plus stepper with the selected quantity in large type.
class QuantityCard extends StatelessWidget {
  const QuantityCard({
    required this.quantity,
    required this.max,
    required this.busy,
    required this.onChanged,
    super.key,
  });
  final int quantity, max;
  final bool busy;
  final ValueChanged<int> onChanged;

  Widget round({
    required IconData icon,
    required String tooltip,
    required bool primary,
    required VoidCallback? onPressed,
  }) => PressSpring(
    enabled: onPressed != null,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size(48, 48),
        shape: const CircleBorder(),
        backgroundColor: primary ? AppColors.navy : AppColors.paper,
        foregroundColor: primary ? Colors.white : AppColors.ink,
        disabledBackgroundColor: AppColors.paper,
        disabledForegroundColor: AppColors.control,
      ),
      icon: Icon(icon),
    ),
  );

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jumlah',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Maksimal $max unit',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
        round(
          icon: Icons.remove_rounded,
          tooltip: 'Kurangi jumlah',
          primary: false,
          onPressed: busy || quantity <= 1
              ? null
              : () => onChanged(quantity - 1),
        ),
        SizedBox(
          width: 56,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
          ),
        ),
        round(
          icon: Icons.add_rounded,
          tooltip: 'Tambah jumlah',
          primary: true,
          onPressed: busy || quantity >= max
              ? null
              : () => onChanged(quantity + 1),
        ),
      ],
    ),
  );
}

/// WhatsApp preparation switch, with notes on contacts and own number.
class NotifyCard extends StatelessWidget {
  const NotifyCard({
    required this.value,
    required this.hasContacts,
    required this.phone,
    required this.busy,
    required this.onChanged,
    super.key,
  });
  final bool value, hasContacts, busy;
  final String phone;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
    child: SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: const Icon(Icons.chat_outlined, color: AppColors.ok),
      title: const Text(
        'Siapkan pesan WhatsApp ke admin',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        [
          hasContacts
              ? 'Pesan disiapkan setelah pengajuan tersimpan.'
              : 'Kontak WhatsApp admin belum diatur. Pengajuan tetap dapat dikirim melalui aplikasi.',
          if (phone.isNotEmpty) 'Nomor WhatsApp akun Anda: $phone',
        ].join('\n'),
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      value: value && hasContacts,
      onChanged: busy || !hasContacts ? null : onChanged,
    ),
  );
}

/// Sticky footer of the form: error, helper note and the submit button.
class RequestSubmitBar extends StatelessWidget {
  const RequestSubmitBar({
    required this.busy,
    required this.error,
    required this.onSubmit,
    super.key,
  });
  final bool busy;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.paper,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: centered(
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.badSoft,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
                child: Text(
                  error!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.bad,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const Text(
              'Pengajuan ditinjau admin. Stok berkurang setelah disetujui.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: busy ? null : onSubmit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.muted,
                      ),
                    )
                  : const Icon(Icons.send_outlined, size: 20),
              label: Text(busy ? 'Mengirim pengajuan...' : 'Ajukan peminjaman'),
            ),
          ],
        ),
      ),
    ),
  );
}
