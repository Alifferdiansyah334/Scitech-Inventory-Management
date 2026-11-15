import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/brand.dart';
import '../models.dart';
import '../ui/components.dart';
import '../ui/shapes.dart';
import 'borrow_request.dart';
import 'borrower_catalog.dart';
import 'catalog/dates.dart';
import 'forms.dart';
import 'home/borrower_home.dart';
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

class _ConnectedWorkspaceState extends State<ConnectedWorkspace> with WidgetsBindingObserver, WorkspaceActions {
  int index = 0;
  String loanView = 'Pinjaman saya', loanFilter = 'Semua';

  /// Category the borrower picked on Beranda; Katalog opens filtered to it.
  String? catalogCategory;
  bool visible = true;
  Timer? timer;

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

  /// Every destination keeps one shape in the dock, rail and "Lainnya".
  List<NavDest> get destinations => app.isAdmin
      ? const [
          NavDest('Ringkasan', Icons.home_outlined, Icons.home_rounded, ExpressiveShape.cookie9),
          NavDest('Statistik', Icons.insights_outlined, Icons.insights_rounded, ExpressiveShape.gem),
          NavDest('Barang', Icons.inventory_2_outlined, Icons.inventory_2_rounded, ExpressiveShape.clover4),
          NavDest('Pinjaman', Icons.assignment_outlined, Icons.assignment_rounded, ExpressiveShape.flower8),
          NavDest('Pengadaan', Icons.local_shipping_outlined, Icons.local_shipping_rounded, ExpressiveShape.pentagon),
          NavDest('Pengguna', Icons.group_outlined, Icons.group_rounded, ExpressiveShape.cookie12),
          NavDest('Riwayat', Icons.history_rounded, Icons.manage_history_rounded, ExpressiveShape.burst),
          NavDest('Akun', Icons.settings_outlined, Icons.settings_rounded, ExpressiveShape.sunny8),
        ]
      : const [
          NavDest('Beranda', Icons.home_outlined, Icons.home_rounded, ExpressiveShape.cookie9),
          NavDest('Katalog', Icons.inventory_2_outlined, Icons.inventory_2_rounded, ExpressiveShape.clover4),
          NavDest('Pinjaman', Icons.history_rounded, Icons.manage_history_rounded, ExpressiveShape.flower8),
          NavDest('Akun', Icons.settings_outlined, Icons.settings_rounded, ExpressiveShape.sunny8),
        ];

  int _indexOf(String label) => destinations.indexWhere((d) => d.label == label);

  void go(int value) => setState(() {
    index = value;
    loanFilter = 'Semua';
    catalogCategory = null;
  });

  /// Borrower 'Katalog', optionally filtered to one [category].
  void openCatalog([String? category]) => setState(() {
    index = _indexOf('Katalog');
    catalogCategory = category;
  });

  void openOwnLoans() => setState(() {
    index = _indexOf('Pinjaman');
    loanView = 'Pinjaman saya';
    loanFilter = 'Semua';
  });

  /// Admin 'Pinjaman' with the status filter [filter] (a loans filter key).
  void openAdminLoans(String filter) {
    final target = _indexOf('Pinjaman');
    if (target < 0) return;
    setState(() {
      index = target;
      loanFilter = filter;
    });
  }

  Future<void> borrow(InventoryItem item) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BorrowRequestPage(app: app, item: item, picture: picture),
      ),
    );
    if (submitted == true && mounted) openOwnLoans();
  }

  Future<void> signOut() async {
    if (await confirmAction(
      context,
      'Keluar dari akun?',
      'Sesi pada perangkat ini akan diakhiri.',
      icon: Icons.logout_rounded,
    )) {
      await perform(() => app.signOut(), success: 'Anda sudah keluar.');
    }
  }

  /// Header actions (tonal discs). Signing out lives in Akun, the rail
  /// footer and the admin's "Lainnya" sheet.
  List<Widget> get headerActions => [
    if (!app.isAdmin)
      HeaderIconButton(
        icon: Icons.notifications_none_rounded,
        tooltip: 'Notifikasi pinjaman',
        badge: app.loans.any((l) => const ['approved', 'needs_review', 'returning'].contains(l.status)),
        onPressed: openOwnLoans,
      ),
    HeaderIconButton(
      icon: Icons.refresh_rounded,
      tooltip: 'Perbarui data',
      onPressed: app.loading || locked ? null : app.refresh,
    ),
  ];

  Widget section(String name) => switch (name) {
    'Ringkasan' => AdminDashboard(actions: this, onOpenLoans: openAdminLoans),
    'Statistik' => StatsSection(actions: this),
    'Barang' => AdminInventory(actions: this),
    'Beranda' => BorrowerHome(actions: this, onBorrow: borrow, onCatalog: openCatalog, onLoans: openOwnLoans),
    'Katalog' => BorrowerCatalog(
      key: ValueKey('catalog-$catalogCategory'),
      app: app,
      picture: picture,
      onBorrow: borrow,
      onLoans: openOwnLoans,
      initialCategory: catalogCategory,
    ),
    'Pinjaman' || 'Riwayat' when app.isAdmin => AdminLoans(
      actions: this,
      history: name == 'Riwayat',
      filter: loanFilter,
      onFilter: (value) => setState(() => loanFilter = value),
    ),
    'Pinjaman' => BorrowerLoans(
      actions: this,
      view: loanView,
      filter: loanFilter,
      onView: (value) => setState(() {
        loanView = value;
        loanFilter = 'Semua';
      }),
      onFilter: (value) => setState(() => loanFilter = value),
      onCatalog: openCatalog,
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
    final profile = app.profile!;
    return WorkspaceShell(
      wide: wide,
      destinations: entries,
      selected: selected,
      onSelect: go,
      isAdmin: app.isAdmin,
      name: profile.name,
      email: profile.email,
      userId: profile.id,
      pending: app.loans.where((l) => l.status == 'pending').length,
      progress: app.loading || working,
      onRefresh: app.refresh,
      onSignOut: locked ? null : signOut,
      footnote: updated == null ? null : 'Terakhir diperbarui ${stamp(updated)} · pembaruan otomatis setiap 30 detik',
      child: WorkspaceChrome(
        wide: wide,
        actions: headerActions,
        label: app.isAdmin ? 'Admin · $appName' : null,
        notice: app.error == null
            ? null
            : RefreshErrorCard(
                message: app.error!,
                updatedAt: updated == null ? null : clockTime(updated),
                onRetry: app.loading ? null : app.refresh,
              ),
        child: KeyedSubtree(key: ValueKey('${app.isAdmin}-$selected'), child: section(entries[selected].label)),
      ),
    );
  }
}
