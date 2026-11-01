import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../models.dart';
import '../ui/components.dart';
import 'borrow_request.dart';
import 'borrower_catalog.dart';
import 'catalog/dates.dart';
import 'forms.dart';
import 'stats/stats_section.dart';
import 'workspace/account.dart';
import 'workspace/actions.dart';
import 'workspace/chrome.dart';
import 'workspace/dashboard.dart';
import 'workspace/inventory_admin.dart';
import 'workspace/loans_admin.dart';
import 'workspace/loans_borrower.dart';
import 'workspace/procurement.dart';
import 'workspace/shell.dart';
import 'workspace/users.dart';

export 'catalog/dates.dart' show stamp;

class ConnectedWorkspace extends StatefulWidget {
  const ConnectedWorkspace({required this.state, super.key});
  final AppState state;
  @override
  State<ConnectedWorkspace> createState() => _ConnectedWorkspaceState();
}

class _ConnectedWorkspaceState extends State<ConnectedWorkspace>
    with WidgetsBindingObserver, WorkspaceActions {
  int index = 0;
  String loanView = 'Pinjaman saya', loanFilter = 'Semua';
  bool visible = true;
  Timer? timer;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  AppState get app => widget.state;

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

  List<(String, IconData)> get destinations => app.isAdmin
      ? [
          ('Ringkasan', Icons.dashboard_outlined),
          ('Statistik', Icons.insights_outlined),
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

  void go(int value) => setState(() {
    index = value;
    loanFilter = 'Semua';
  });

  void openOwnLoans() => setState(() {
    index = 1;
    loanView = 'Pinjaman saya';
    loanFilter = 'Semua';
  });

  Future<void> borrow(InventoryItem item) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BorrowRequestPage(app: app, item: item),
      ),
    );
    if (submitted == true && mounted) openOwnLoans();
  }

  Future<void> signOut() async {
    if (await confirmAction(
      context,
      'Keluar dari akun?',
      'Sesi pada perangkat ini akan diakhiri.',
    )) {
      await perform(() => app.signOut(), success: 'Anda sudah keluar.');
    }
  }

  List<Widget> get headerActions => [
    if (!app.isAdmin)
      HeaderIconButton(
        icon: Icons.notifications_none_rounded,
        tooltip: 'Notifikasi pinjaman',
        badge: app.loans.any(
          (l) => const [
            'approved',
            'needs_review',
            'returning',
          ].contains(l.status),
        ),
        onPressed: openOwnLoans,
      ),
    HeaderIconButton(
      icon: Icons.refresh_rounded,
      tooltip: 'Perbarui data',
      onPressed: app.loading || locked ? null : app.refresh,
    ),
    HeaderIconButton(
      icon: Icons.logout_rounded,
      tooltip: 'Keluar',
      onPressed: locked ? null : signOut,
    ),
  ];

  Widget section(String name) => switch (name) {
    'Ringkasan' => AdminDashboard(actions: this),
    'Statistik' => StatsSection(actions: this),
    'Barang' => AdminInventory(actions: this),
    'Katalog' => BorrowerCatalog(
      app: app,
      picture: picture,
      onBorrow: borrow,
      onLoans: () => go(1),
    ),
    'Pinjaman' || 'Riwayat' => AdminLoans(
      actions: this,
      history: name == 'Riwayat',
      filter: loanFilter,
      onFilter: (value) => setState(() => loanFilter = value),
    ),
    'Pinjaman saya' => BorrowerLoans(
      actions: this,
      view: loanView,
      filter: loanFilter,
      onView: (value) => setState(() {
        loanView = value;
        loanFilter = 'Semua';
      }),
      onFilter: (value) => setState(() => loanFilter = value),
      onCatalog: () => go(0),
    ),
    'Pengadaan' => ProcurementSection(actions: this),
    'Pengguna' => UsersSection(actions: this),
    _ => AccountSection(actions: this),
  };

  @override
  Widget build(BuildContext context) {
    final entries = destinations;
    final selected = index < entries.length ? index : 0;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final updated = app.updatedAt;
    return WorkspaceShell(
      scaffoldKey: scaffoldKey,
      wide: wide,
      destinations: entries,
      selected: selected,
      onSelect: go,
      isAdmin: app.isAdmin,
      name: app.profile!.name,
      pending: app.loans.where((l) => l.status == 'pending').length,
      progress: app.loading || working,
      onRefresh: app.refresh,
      footnote: updated == null
          ? null
          : 'Terakhir diperbarui ${stamp(updated)} · pembaruan otomatis setiap 30 detik',
      child: WorkspaceChrome(
        wide: wide,
        actions: headerActions,
        leading: !wide && app.isAdmin
            ? MenuPill(onPressed: () => scaffoldKey.currentState?.openDrawer())
            : null,
        notice: app.error == null
            ? null
            : RefreshErrorCard(
                message: app.error!,
                updatedAt: updated == null ? null : clockTime(updated),
                onRetry: app.loading ? null : app.refresh,
              ),
        child: KeyedSubtree(
          key: ValueKey('${app.isAdmin}-$selected'),
          child: section(entries[selected].$1),
        ),
      ),
    );
  }
}
