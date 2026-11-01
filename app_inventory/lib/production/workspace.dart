import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_state.dart';
import '../models.dart';
import 'app.dart';
import 'forms.dart';
import 'item_editor.dart';
import 'borrower_catalog.dart';
import 'borrow_request.dart';
import '../services/whatsapp_service.dart';
import 'admin_contact_picker.dart';
import 'app_update_page.dart';

class ConnectedWorkspace extends StatefulWidget {
  const ConnectedWorkspace({required this.state, super.key});
  final AppState state;
  @override
  State<ConnectedWorkspace> createState() => _ConnectedWorkspaceState();
}

class _ConnectedWorkspaceState extends State<ConnectedWorkspace>
    with WidgetsBindingObserver {
  int index = 0;
  String search = '';
  String loanView = 'Pinjaman saya', loanFilter = 'Semua';
  bool working = false, visible = true;
  Timer? timer;
  AppState get app => widget.state;
  bool get locked => working || app.busy;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (visible && !locked) app.refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    visible = state == AppLifecycleState.resumed;
    if (visible) app.refresh();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> perform(
    Future<void> Function() action, {
    String success = 'Perubahan tersimpan.',
  }) async {
    if (locked) return;
    setState(() => working = true);
    try {
      await action();
      if (mounted) message(success);
    } catch (e) {
      message(e.toString());
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> loanAction(
    Loan loan,
    String action, {
    Json data = const {},
  }) async {
    await app.mutate(
      'api/loans/${loan.id}',
      method: 'PATCH',
      data: {...data, 'action': action},
    );
  }

  Future<void> photoAction(Loan loan, bool returning) async {
    if (locked) return;
    var note = '';
    if (returning) {
      final form = await promptForm(context, 'Pengembalian ${loan.name}', [
        const InputSpec(
          'note',
          'Catatan kondisi barang',
          optional: true,
          max: 1000,
        ),
      ], submit: 'Lanjut pilih foto');
      if (form == null || !mounted) return;
      note = form['note'] ?? '';
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 75,
    );
    if (picked == null || !mounted) return;
    var persisted = false;
    await perform(
      () async {
        final id = await app.api.upload(picked, bucket: 'return-images');
        await loanAction(
          loan,
          returning ? 'requestReturn' : 'handover',
          data: {
            returning ? 'return_image_id' : 'admin_image_id': id,
            if (returning) 'user_note': note,
          },
        );
        persisted = true;
      },
      success: returning
          ? 'Pengembalian diajukan untuk diperiksa.'
          : 'Serah terima berhasil dicatat.',
    );
    if (returning && persisted && mounted && app.adminContacts.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Pengembalian diajukan'),
          content: const Text(
            'Foto dan catatan kondisi sudah tersimpan. Admin akan memeriksa pengembalian. Anda juga dapat mengirim konfirmasi melalui WhatsApp.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Selesai'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final contact = await chooseAdminContact(
                  dialogContext,
                  app.adminContacts,
                );
                if (contact == null || !mounted) return;
                try {
                  final launched = await WhatsAppService.sendReturnProofMessage(
                    phoneNumber: contact.phone,
                    borrowerName: app.profile!.name,
                    itemName: loan.name,
                    borrowDate: loan.borrowDate,
                    dueDate: DateTime.now(),
                    note: note.isEmpty
                        ? 'Bukti foto sudah diunggah pada aplikasi.'
                        : note,
                  );
                  if (!launched) {
                    message(
                      'WhatsApp belum dapat dibuka. Pengembalian tetap tercatat.',
                    );
                  }
                } catch (_) {
                  message(
                    'WhatsApp belum dapat dibuka. Pengembalian tetap tercatat.',
                  );
                }
              },
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Konfirmasi WhatsApp'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> noteAction(
    Loan loan,
    String action,
    String title, {
    bool requiredNote = true,
  }) async {
    final values = await promptForm(context, title, [
      InputSpec(
        'note',
        'Catatan',
        optional: !requiredNote,
        min: requiredNote ? 5 : 1,
        max: 1000,
      ),
    ]);
    if (values == null || !mounted) return;
    await perform(
      () => loanAction(
        loan,
        action,
        data: {
          action == 'flagIssue' ? 'issue_note' : 'admin_note': values['note'],
        },
      ),
    );
  }

  List<(String, IconData)> get destinations => app.isAdmin
      ? [
          ('Ringkasan', Icons.dashboard_outlined),
          ('Barang', Icons.inventory_2_outlined),
          ('Pinjaman', Icons.assignment_outlined),
          ('Pengadaan', Icons.local_shipping_outlined),
          ('Pengguna', Icons.group_outlined),
          ('Riwayat', Icons.history),
          ('Akun', Icons.person_outline),
        ]
      : [
          ('Katalog', Icons.inventory_2_outlined),
          ('Pinjaman saya', Icons.assignment_outlined),
          ('Akun', Icons.person_outline),
        ];
  @override
  Widget build(BuildContext context) {
    final entries = destinations;
    final selected = index < entries.length ? index : 0;
    final section = entries[selected].$1;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/Logo.png', width: 30, height: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'SIMS · $section',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!app.isAdmin)
            IconButton(
              tooltip: 'Notifikasi pinjaman',
              onPressed: () => setState(() {
                index = 1;
                loanView = 'Pinjaman saya';
              }),
              icon: Badge(
                isLabelVisible: app.loans.any(
                  (l) => [
                    'approved',
                    'needs_review',
                    'returning',
                  ].contains(l.status),
                ),
                child: const Icon(Icons.notifications_none_rounded),
              ),
            ),
          IconButton(
            tooltip: 'Perbarui data',
            onPressed: app.loading || locked ? null : app.refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: locked
                ? null
                : () async {
                    if (await confirmAction(
                      context,
                      'Keluar dari akun?',
                      'Sesi pada perangkat ini akan diakhiri.',
                    )) {
                      await perform(
                        () => app.signOut(),
                        success: 'Anda sudah keluar.',
                      );
                    }
                  },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: !wide && app.isAdmin
          ? Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    ListTile(
                      title: Text(
                        app.profile!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Administrator Scitech'),
                    ),
                    for (var i = 0; i < entries.length; i++)
                      ListTile(
                        selected: selected == i,
                        leading: Icon(entries[i].$2),
                        title: Text(entries[i].$1),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            index = i;
                            search = '';
                          });
                        },
                      ),
                  ],
                ),
              ),
            )
          : null,
      bottomNavigationBar: !wide && !app.isAdmin
          ? NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (value) => setState(() {
                index = value;
                search = '';
              }),
              destinations: [
                for (final item in entries)
                  NavigationDestination(icon: Icon(item.$2), label: item.$1),
              ],
            )
          : null,
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              extended: true,
              selectedIndex: selected,
              onDestinationSelected: (value) => setState(() {
                index = value;
                search = '';
              }),
              destinations: [
                for (final item in entries)
                  NavigationRailDestination(
                    icon: Icon(item.$2),
                    label: Text(item.$1),
                  ),
              ],
            ),
          Expanded(
            child: Column(
              children: [
                if (app.loading || working)
                  const LinearProgressIndicator(minHeight: 2),
                if (app.error != null)
                  MaterialBanner(
                    content: Text(app.error!),
                    actions: [
                      TextButton(
                        onPressed: app.loading ? null : app.refresh,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: app.refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(wide ? 32 : 18),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  !app.isAdmin && selected == 0
                                      ? 'Katalog Inventaris'
                                      : section,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: navy,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  app.isAdmin
                                      ? 'Kelola inventaris dan permintaan tim.'
                                      : 'Halo, ${app.profile!.name}. ${selected == 0 ? 'Pilih barang dan ajukan peminjaman di sini.' : 'Pantau peminjaman dan aktivitas tim.'}',
                                  style: const TextStyle(
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (section == 'Ringkasan') ...dashboard(),
                                if (section == 'Barang' || section == 'Katalog')
                                  ...inventory(),
                                if (section == 'Pinjaman' ||
                                    section == 'Pinjaman saya')
                                  ...loanList(false),
                                if (section == 'Riwayat') ...loanList(true),
                                if (section == 'Pengadaan')
                                  ...procurementList(),
                                if (section == 'Pengguna') ...userList(),
                                if (section == 'Akun') ...account(),
                                const SizedBox(height: 24),
                                if (app.updatedAt != null)
                                  Text(
                                    'Terakhir diperbarui ${stamp(app.updatedAt!)} · pembaruan otomatis setiap 30 detik',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget empty(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Column(
      children: [
        const Icon(Icons.inbox_outlined, size: 48, color: Colors.blueGrey),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
  Widget action(
    String label,
    VoidCallback? callback, {
    IconData icon = Icons.arrow_forward,
  }) => Padding(
    padding: const EdgeInsets.only(right: 8, bottom: 8),
    child: OutlinedButton.icon(
      onPressed: locked ? null : callback,
      icon: Icon(icon, size: 18),
      label: Text(label),
    ),
  );
  List<Widget> dashboard() => [
    Card(
      color: navy,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventaris Scitech',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 30,
              runSpacing: 18,
              children: [
                for (final stat in [
                  ('${app.items.length}', 'Jenis barang'),
                  (
                    '${app.items.fold<int>(0, (sum, item) => sum + item.available)}',
                    'Unit tersedia',
                  ),
                  (
                    '${app.loans.where((l) => l.status == 'pending').length}',
                    'Menunggu persetujuan',
                  ),
                  (
                    '${app.loans.where((l) => !l.closed && l.status != 'pending').length}',
                    'Pinjaman aktif',
                  ),
                ])
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        stat.$2,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 24),
    const Text(
      'Permintaan terbaru',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
    ),
    const SizedBox(height: 12),
    if (app.loans.isEmpty)
      empty('Belum ada permintaan peminjaman.')
    else
      for (final loan in app.loans.take(5)) loanCard(loan),
  ];
  List<Widget> inventory() {
    if (!app.isAdmin) {
      return [
        BorrowerCatalog(
          app: app,
          picture: picture,
          onBorrow: borrow,
          onLoans: () => setState(() => index = 1),
        ),
      ];
    }
    final rows = app.items
        .where(
          (item) => '${item.name} ${item.category}'.toLowerCase().contains(
            search.toLowerCase(),
          ),
        )
        .toList();
    return [
      Row(
        children: [
          Expanded(
            child: TextField(
              key: ValueKey(index),
              decoration: const InputDecoration(
                labelText: 'Cari nama atau kategori',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => search = value),
            ),
          ),
          if (app.isAdmin) ...[
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: locked
                  ? null
                  : () => showDialog<bool>(
                      context: context,
                      builder: (_) => ItemEditor(state: app),
                    ),
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            ),
          ],
        ],
      ),
      const SizedBox(height: 18),
      if (rows.isEmpty)
        empty(
          search.isEmpty
              ? 'Belum ada barang dalam inventaris.'
              : 'Tidak ada barang yang cocok.',
        ),
      for (final item in rows)
        Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: picture(item.imageUrl),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            item.category,
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.available} dari ${item.total} unit tersedia',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (!item.enabled)
                            const Text(
                              'Peminjaman dinonaktifkan',
                              style: TextStyle(color: Colors.deepOrange),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (item.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(item.description),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  children: app.isAdmin
                      ? [
                          action(
                            'Ubah',
                            () => showDialog<bool>(
                              context: context,
                              builder: (_) =>
                                  ItemEditor(state: app, item: item),
                            ),
                            icon: Icons.edit_outlined,
                          ),
                          action(
                            'Hapus',
                            item.reserved > 0
                                ? null
                                : () async {
                                    if (await confirmAction(
                                      context,
                                      'Hapus barang?',
                                      '${item.name} akan dihapus. Barang yang mempunyai riwayat peminjaman mungkin tidak dapat dihapus.',
                                    )) {
                                      await perform(
                                        () => app
                                            .mutate(
                                              'api/items/${item.id}',
                                              method: 'DELETE',
                                            )
                                            .then((_) {}),
                                      );
                                    }
                                  },
                            icon: Icons.delete_outline,
                          ),
                        ]
                      : [
                          action(
                            item.canBorrow
                                ? 'Ajukan peminjaman'
                                : 'Tidak tersedia',
                            item.canBorrow ? () => borrow(item) : null,
                            icon: Icons.add_shopping_cart,
                          ),
                        ],
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget picture(String value) {
    final url = value.isEmpty ? '' : app.api.imageUrl(value);
    if (url.isEmpty) {
      return const ColoredBox(
        color: Color(0xFFEEF0FF),
        child: Icon(Icons.inventory_2_outlined, color: indigo, size: 32),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        headers: app.api.authHeaders,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.image_not_supported_outlined),
      ),
    );
  }

  Future<void> borrow(InventoryItem item) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BorrowRequestPage(app: app, item: item),
      ),
    );
    if (submitted == true && mounted) {
      setState(() {
        index = 1;
        loanView = 'Pinjaman saya';
      });
    }
  }

  List<Widget> loanList(bool history) {
    if (!app.isAdmin) return borrowerLoans();
    final rows = app.loans
        .where((loan) => history ? loan.closed : true)
        .toList();
    return [
      if (rows.isEmpty)
        empty('Belum ada pinjaman pada daftar ini.')
      else
        for (final loan in rows) loanCard(loan),
    ];
  }

  List<Widget> borrowerLoans() {
    final history = loanView == 'Riwayat', team = loanView == 'Pinjaman rekan';
    final rows = app.loans
        .where(
          (l) =>
              l.closed == history &&
              (loanFilter == 'Semua' || l.status == loanFilter),
        )
        .toList();
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tab in ['Pinjaman saya', 'Pinjaman rekan', 'Riwayat'])
            ChoiceChip(
              label: Text(tab),
              selected: loanView == tab,
              onSelected: (_) => setState(() {
                loanView = tab;
                loanFilter = 'Semua';
              }),
            ),
        ],
      ),
      const SizedBox(height: 18),
      if (team) ...[
        const Text(
          'Barang yang sedang dipinjam rekan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: navy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Cek pemakai dan perkiraan kembali sebelum merencanakan peminjaman.',
          style: TextStyle(color: Colors.blueGrey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (app.activity.where((l) => !l.isMine).isEmpty)
          empty('Belum ada barang yang sedang dipinjam rekan.'),
        for (final loan in app.activity.where((l) => !l.isMine))
          TeamLoanTile(loan: loan),
      ] else ...[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final status in [
                'Semua',
                ...history
                    ? ['returned', 'rejected', 'cancelled']
                    : [
                        'pending',
                        'approved',
                        'borrowed',
                        'returning',
                        'needs_review',
                        'overdue',
                      ],
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(statusLabels[status] ?? status),
                    selected: loanFilter == status,
                    onSelected: (_) => setState(() => loanFilter = status),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          empty(
            history
                ? 'Belum ada riwayat pada status ini.'
                : 'Belum ada pinjaman pada status ini.',
          ),
        if (rows.isEmpty && !history)
          Align(
            alignment: Alignment.center,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => index = 0),
              icon: const Icon(Icons.grid_view),
              label: const Text('Jelajahi katalog'),
            ),
          ),
        for (final loan in rows) ...[
          loanCard(loan),
          if (!loan.closed)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value:
                        const {
                          'pending': .15,
                          'approved': .35,
                          'borrowed': .6,
                          'overdue': .6,
                          'returning': .85,
                          'needs_review': .85,
                        }[loan.status] ??
                        0,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _loanHint(loan),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: app.adminContacts.isEmpty
                          ? null
                          : () => contactAdmin(loan),
                      icon: const Icon(Icons.chat_outlined, size: 17),
                      label: const Text('Hubungi admin via WhatsApp'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    ];
  }

  String _loanHint(Loan loan) => switch (loan.status) {
    'pending' => 'Pengajuan terkirim. Menunggu admin meninjau permintaan Anda.',
    'approved' =>
      'Pengajuan disetujui. Hubungi admin untuk pengambilan barang.',
    'borrowed' || 'overdue' =>
      'Barang sedang digunakan. Unggah foto kondisi ketika mengajukan pengembalian.',
    'returning' =>
      'Bukti pengembalian sudah terkirim. Menunggu pemeriksaan admin.',
    'needs_review' =>
      'Ada catatan pemeriksaan. Periksa catatan admin dan kirim ulang bukti.',
    _ => '',
  };

  Future<void> contactAdmin(Loan loan) async {
    final contact = await chooseAdminContact(context, app.adminContacts);
    if (contact == null || !mounted) return;
    try {
      final sent = await WhatsAppService.contact(
        contact.phone,
        'Halo Admin, saya ${app.profile!.name} ingin menanyakan peminjaman ${loan.name} (${loan.quantity} unit).\nNomor pengajuan: ${loan.id}\nStatus: ${loan.label}\nBatas kembali: ${shortDate(loan.dueDate)}',
      );
      if (!sent) message('WhatsApp belum dapat dibuka. Coba kembali.');
    } catch (_) {
      message('WhatsApp belum dapat dibuka. Coba kembali.');
    }
  }

  Widget loanCard(Loan loan) => Card(
    elevation: 0,
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loan.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Chip(label: Text(loan.label)),
            ],
          ),
          if (app.isAdmin) Text('Peminjam: ${loan.borrower}'),
          Text('${loan.quantity} unit · batas kembali ${stamp(loan.dueDate)}'),
          const SizedBox(height: 8),
          Text(loan.purpose),
          for (final note in [loan.adminNote, loan.userNote, loan.issueNote])
            if (note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(note),
              ),
          if (loan.beforeId != null || loan.afterId != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Wrap(
                spacing: 12,
                children: [
                  if (loan.beforeId != null)
                    SizedBox(
                      width: 130,
                      height: 100,
                      child: picture('/api/images/${loan.beforeId}/'),
                    ),
                  if (loan.afterId != null)
                    SizedBox(
                      width: 130,
                      height: 100,
                      child: picture('/api/images/${loan.afterId}/'),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            children: [
              if (app.isAdmin && loan.status == 'pending') ...[
                action(
                  'Setujui',
                  () => perform(() => loanAction(loan, 'approve')),
                  icon: Icons.check,
                ),
                action(
                  'Tolak',
                  () => noteAction(
                    loan,
                    'reject',
                    'Alasan penolakan',
                    requiredNote: false,
                  ),
                  icon: Icons.close,
                ),
              ],
              if (app.isAdmin && loan.status == 'approved')
                action(
                  'Serah terima + foto',
                  () => photoAction(loan, false),
                  icon: Icons.add_a_photo_outlined,
                ),
              if (!app.isAdmin && loan.canReturn)
                action(
                  'Ajukan pengembalian + foto',
                  () => photoAction(loan, true),
                  icon: Icons.assignment_return_outlined,
                ),
              if (app.isAdmin &&
                  const [
                    'returning',
                    'needs_review',
                  ].contains(loan.status)) ...[
                action('Konfirmasi diterima', () async {
                  if (await confirmAction(
                    context,
                    'Barang sudah diperiksa?',
                    'Konfirmasi akan mengembalikan ${loan.quantity} unit ke stok tersedia.',
                  )) {
                    await perform(
                      () => loanAction(
                        loan,
                        'confirmReturn',
                        data: {
                          'actual_return_date': DateTime.now()
                              .toUtc()
                              .toIso8601String(),
                        },
                      ),
                    );
                  }
                }, icon: Icons.task_alt),
                if (loan.status == 'returning')
                  action(
                    'Perlu tindak lanjut',
                    () => noteAction(loan, 'flagIssue', 'Catatan pemeriksaan'),
                    icon: Icons.report_outlined,
                  ),
              ],
              if (loan.status == 'pending' ||
                  app.isAdmin && loan.status == 'approved')
                action(
                  'Batalkan',
                  () => noteAction(loan, 'cancel', 'Alasan pembatalan'),
                  icon: Icons.cancel_outlined,
                ),
            ],
          ),
        ],
      ),
    ),
  );
  List<Widget> procurementList() => [
    Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: locked || app.items.isEmpty ? null : addProcurement,
        icon: const Icon(Icons.add),
        label: const Text('Tambah pengadaan'),
      ),
    ),
    const SizedBox(height: 18),
    if (app.procurements.isEmpty) empty('Belum ada pengadaan barang.'),
    for (final record in app.procurements)
      Card(
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text('${record.quantity} unit · ${record.supplier}'),
              Text('Biaya per unit: Rp${record.cost.toStringAsFixed(0)}'),
              Text(
                {
                      'ordered': 'Menunggu diterima',
                      'received': 'Sudah diterima',
                      'cancelled': 'Dibatalkan',
                    }[record.status] ??
                    record.status,
              ),
              const SizedBox(height: 12),
              if (record.status == 'ordered')
                Wrap(
                  children: [
                    for (final status in ['received', 'cancelled'])
                      action(
                        status == 'received'
                            ? 'Konfirmasi diterima'
                            : 'Batalkan',
                        () async {
                          if (await confirmAction(
                            context,
                            'Konfirmasi pengadaan?',
                            status == 'received'
                                ? 'Stok barang akan bertambah ${record.quantity} unit.'
                                : 'Pesanan ini akan dibatalkan.',
                          )) {
                            await perform(
                              () => app
                                  .mutate(
                                    'api/admin/procurements',
                                    method: 'PATCH',
                                    data: {'id': record.id, 'status': status},
                                  )
                                  .then((_) {}),
                            );
                          }
                        },
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
  ];
  Future<void> addProcurement() async {
    final selected = await showDialog<InventoryItem>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pilih barang'),
        children: [
          for (final item in app.items)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item),
              child: Text(item.name),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final values = await promptForm(context, 'Pengadaan ${selected.name}', [
      const InputSpec(
        'quantity',
        'Jumlah unit',
        initial: '1',
        numeric: true,
        max: 6,
      ),
      const InputSpec('supplier', 'Pemasok', min: 2, max: 160),
      const InputSpec(
        'cost',
        'Biaya per unit (Rp)',
        initial: '0',
        decimal: true,
        max: 16,
      ),
    ]);
    if (values == null || !mounted) return;
    await perform(
      () => app
          .mutate(
            'api/admin/procurements',
            data: {
              'item_id': selected.id,
              'quantity': int.parse(values['quantity']!),
              'supplier': values['supplier'],
              'unit_cost': double.parse(values['cost']!),
            },
          )
          .then((_) {}),
    );
  }

  List<Widget> userList() => [
    if (app.users.isEmpty) empty('Belum ada pengguna.'),
    for (final user in app.users)
      Card(
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(user.email),
              Text(
                '${user.isAdmin ? 'Admin' : 'Peminjam'} · ${user.active ? 'Aktif' : 'Nonaktif'}',
              ),
              if (user.id != app.profile!.id)
                Wrap(
                  children: [
                    action(user.active ? 'Nonaktifkan' : 'Aktifkan', () async {
                      if (await confirmAction(
                        context,
                        'Ubah status akun?',
                        user.active
                            ? 'Pengguna ini tidak akan dapat mengakses layanan.'
                            : 'Pengguna ini akan dapat mengakses layanan kembali.',
                      )) {
                        await perform(
                          () => app
                              .mutate(
                                'api/admin/users/${user.id}',
                                method: 'PATCH',
                                data: {'is_active': !user.active},
                              )
                              .then((_) {}),
                        );
                      }
                    }),
                    action(
                      user.isAdmin ? 'Jadikan peminjam' : 'Jadikan admin',
                      () async {
                        if (await confirmAction(
                          context,
                          'Ubah hak akses?',
                          user.isAdmin
                              ? 'Hak administrasi akun ini akan dicabut.'
                              : 'Akun ini akan dapat mengelola inventaris dan pengguna.',
                        )) {
                          await perform(
                            () => app
                                .mutate(
                                  'api/admin/users/${user.id}',
                                  method: 'PATCH',
                                  data: {
                                    'role': user.isAdmin ? 'client' : 'admin',
                                  },
                                )
                                .then((_) {}),
                          );
                        }
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
  ];
  List<Widget> account() => [
    Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 28, child: Text(app.profile!.initials)),
            const SizedBox(height: 16),
            Text(
              app.profile!.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(app.profile!.email),
            Text(app.isAdmin ? 'Administrator' : 'Peminjam'),
            if (app.profile!.department.isNotEmpty)
              Text(app.profile!.department),
            if (app.profile!.phone.isNotEmpty) Text(app.profile!.phone),
            const SizedBox(height: 20),
            Wrap(
              children: [
                action('Ubah profil', editProfile, icon: Icons.edit_outlined),
                action(
                  'Ubah kata sandi',
                  changePassword,
                  icon: Icons.lock_outline,
                ),
                action(
                  'Pembaruan aplikasi',
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AppUpdatePage(api: app.api),
                    ),
                  ),
                  icon: Icons.system_update_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ];
  Future<void> editProfile() async {
    final user = app.profile!;
    final values = await promptForm(context, 'Ubah profil', [
      InputSpec(
        'full_name',
        'Nama lengkap',
        initial: user.name,
        min: 2,
        max: 120,
      ),
      InputSpec(
        'department',
        'Tim / divisi',
        initial: user.department,
        optional: true,
        max: 120,
      ),
      InputSpec(
        'phone',
        'Nomor telepon',
        initial: user.phone,
        optional: true,
        max: 30,
      ),
    ]);
    if (values != null && mounted) {
      await perform(() => app.updateProfile(values));
    }
  }

  Future<void> changePassword() async {
    final values = await promptForm(context, 'Ubah kata sandi', [
      const InputSpec('currentPassword', 'Kata sandi saat ini', secret: true),
      const InputSpec(
        'newPassword',
        'Kata sandi baru',
        secret: true,
        min: 8,
        max: 128,
        validatePassword: true,
      ),
      const InputSpec(
        'confirm',
        'Konfirmasi kata sandi baru',
        secret: true,
        min: 8,
      ),
    ]);
    if (values == null || !mounted) return;
    if (values['newPassword'] != values['confirm']) {
      message('Konfirmasi kata sandi tidak sama.');
      return;
    }
    await perform(() async {
      await app.api.request(
        'api/mobile/auth/password',
        method: 'POST',
        data: {
          'currentPassword': values['currentPassword'],
          'newPassword': values['newPassword'],
        },
      );
      await app.signOut(remote: false);
    }, success: 'Kata sandi diubah. Silakan masuk kembali.');
  }
}

String stamp(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
