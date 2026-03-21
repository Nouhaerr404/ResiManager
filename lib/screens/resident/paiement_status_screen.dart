import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import 'resident_dashboard_screen.dart';

class PaiementStatusScreen extends StatefulWidget {
  final int userId;
  final Function(int)? onNavigate;
  const PaiementStatusScreen({
    super.key,
    this.userId = 0,
    this.onNavigate,
  });

  @override
  State<PaiementStatusScreen> createState() => _PaiementStatusScreenState();
}

class _PaiementStatusScreenState extends State<PaiementStatusScreen>
    with SingleTickerProviderStateMixin {

  final ResidentService _service = ResidentService();
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;
  Map<String, dynamic>? _overview;
  Map<String, dynamic>? _history;
  bool _loadingOverview = true;
  bool _loadingHistory = true;
  int? _filterYear;

  static const Color _orange  = Color(0xFFFF6B4A);
  static const Color _purple  = Color(0xFF6C63FF);
  static const Color _green   = Color(0xFF2ECC71);
  static const Color _yellow  = Color(0xFFFFC107);
  static const Color _dark    = Color(0xFF1E1E2C);
  static const Color _bg      = Color(0xFFF4F6F9);
  static const Color _white   = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOverview();
    _fetchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOverview() async {
    setState(() => _loadingOverview = true);
    final data = await _service.getPaiementOverview(widget.userId, _selectedYear);
    setState(() { _overview = data; _loadingOverview = false; });
  }

  Future<void> _fetchHistory() async {
    setState(() => _loadingHistory = true);
    final data = await _service.getHistoriquePaiementsComplet(widget.userId);
    setState(() { _history = data; _loadingHistory = false; });
  }

  @override
  Widget build(BuildContext context) {
    final bool inLayout = widget.onNavigate != null;

    final body = Column(
      children: [
        // ── HEADER ORANGE ──
        _buildHeader(),

        // ── TABS + CONTENU ──
        Expanded(
          child: Column(children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildOverviewTab(), _buildHistoryTab()],
              ),
            ),
          ]),
        ),
      ],
    );

    if (inLayout) return body;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Mes Paiements',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _orange,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: ResidentMobileDrawer(currentIndex: 2, userId: widget.userId),
      body: body,
    );
  }

  // ── HEADER ──
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_orange, Color(0xFFFF9A6C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Mes Paiements",
                    style: TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.bold)),
                if (_overview != null && _overview!['num_appart'] != null)
                  Text(
                      'App. ${_overview!['num_appart']} • ${_overview!['tranche_nom'] ?? ''}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
              ]),
              _buildYearSelector(),
            ],
          ),
          const SizedBox(height: 20),

          // ── 3 KPIs ──
          if (!_loadingOverview && _overview != null)
            Row(children: [
              _headerKpi("Total",
                  "${_format((_overview!['total_annee'] as num?)?.toDouble() ?? 0)} DH",
                  Icons.account_balance_wallet_outlined),
              const SizedBox(width: 10),
              _headerKpi("Payé",
                  "${_format((_overview!['paye_annee'] as num?)?.toDouble() ?? 0)} DH",
                  Icons.check_circle_outline),
              const SizedBox(width: 10),
              _headerKpi("Reste",
                  "${_format((_overview!['reste_annee'] as num?)?.toDouble() ?? 0)} DH",
                  Icons.timer_outlined),
            ]),
        ],
      ),
    );
  }

  Widget _headerKpi(String label, String value, IconData icon) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(
            color: Colors.white70, fontSize: 10)),
      ]),
    ));
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedYear,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Colors.white, size: 18),
          isDense: true,
          dropdownColor: _orange,
          items: [
            for (int y = DateTime.now().year; y >= DateTime.now().year - 4; y--)
              DropdownMenuItem(value: y,
                  child: Text('$y', style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 13))),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() => _selectedYear = v);
              _fetchOverview();
            }
          },
        ),
      ),
    );
  }

  // ── TAB BAR ──
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
            color: _orange,
            borderRadius: BorderRadius.circular(10)),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.dashboard_outlined, size: 15),
            SizedBox(width: 6), Text("Vue d'ensemble"),
          ])),
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.history_outlined, size: 15),
            SizedBox(width: 6), Text('Historique'),
          ])),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // ONGLET 1 — VUE D'ENSEMBLE
  // ══════════════════════════════════════════════════════
  Widget _buildOverviewTab() {
    if (_loadingOverview) {
      return const Center(
          child: CircularProgressIndicator(color: _orange));
    }
    if (_overview == null) return const SizedBox();

    final double total = (_overview!['total_annee'] as num?)?.toDouble() ?? 0.0;
    final double paye  = (_overview!['paye_annee']  as num?)?.toDouble() ?? 0.0;
    final double reste = (_overview!['reste_annee'] as num?)?.toDouble() ?? 0.0;
    final String statut = (_overview!['statut'] as String?) ?? 'impaye';
    final double pct = total > 0 ? (paye / total).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [

        // ── CARTE PROGRESSION ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Cotisation $_selectedYear',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              _statutChip(statut),
            ]),
            const SizedBox(height: 16),

            // ── BARRE PROGRESSION ──
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Progression', style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 12)),
              Text('${(pct * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: _orange)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: Colors.grey.shade100,
                valueColor: const AlwaysStoppedAnimation<Color>(_orange),
              ),
            ),
            const SizedBox(height: 20),

            // ── 3 MONTANTS ──
            Row(children: [
              _montantCard('Total', total, _purple),
              const SizedBox(width: 10),
              _montantCard('Payé', paye, _green),
              const SizedBox(width: 10),
              _montantCard('Reste', reste, _orange),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // ── BANNER STATUT ──
        _statutBanner(statut, reste),
        const SizedBox(height: 16),

        // ── INFO BOX ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _purple.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _purple.withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, color: _purple, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(
                'Les paiements sont certifiés par l\'Inter-Syndic de votre tranche.',
                style: TextStyle(color: _purple,
                    fontSize: 11, fontWeight: FontWeight.w500))),
          ]),
        ),
      ]),
    );
  }

  Widget _montantCard(String label, double amount, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('${_format(amount)}',
            style: TextStyle(color: color,
                fontSize: 15, fontWeight: FontWeight.bold)),
        Text('DH', style: TextStyle(color: color.withOpacity(0.7),
            fontSize: 10)),
      ]),
    ));
  }

  Widget _statutChip(String statut) {
    Color color; String label; IconData icon;
    switch (statut) {
      case 'complet':
        color = _green; label = 'Complet';
        icon = Icons.check_circle_rounded; break;
      case 'partiel':
        color = _yellow; label = 'Partiel';
        icon = Icons.timelapse_rounded; break;
      default:
        color = _orange; label = 'Impayé';
        icon = Icons.warning_amber_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 11)),
      ]),
    );
  }

  Widget _statutBanner(String statut, double reste) {
    Color color; IconData icon; String title; String msg;
    switch (statut) {
      case 'complet':
        color = _green; icon = Icons.check_circle_rounded;
        title = 'Paiement complet !';
        msg = 'Vous êtes à jour pour cette année 🎉'; break;
      case 'partiel':
        color = _yellow; icon = Icons.info_outline_rounded;
        title = 'Paiement partiel';
        msg = 'Il reste ${_format(reste)} DH à régler'; break;
      default:
        color = _orange; icon = Icons.warning_amber_rounded;
        title = 'Paiement impayé';
        msg = 'Montant dû : ${_format(reste)} DH';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(msg, style: TextStyle(
              color: color.withOpacity(0.8), fontSize: 12)),
        ])),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  // ONGLET 2 — HISTORIQUE
  // ══════════════════════════════════════════════════════
  Widget _buildHistoryTab() {
    if (_loadingHistory) {
      return const Center(
          child: CircularProgressIndicator(color: _orange));
    }
    if (_history == null) return const SizedBox();

    final List<Map<String, dynamic>> all = _history!['historique'] != null
        ? List<Map<String, dynamic>>.from(_history!['historique'] as List)
        : [];

    final Map<int, List> byYear = {};
    for (var h in all) {
      final int y = (h['annee'] as int?) ?? 0;
      byYear.putIfAbsent(y, () => []).add(h);
    }

    final double total =
        (_history!['total_verse'] as num?)?.toDouble() ?? 0.0;
    final List<int> years =
    byYear.keys.toList()..sort((a, b) => b.compareTo(a));
    final List<Map<String, dynamic>> filtered = _filterYear == null
        ? all
        : all.where((h) => h['annee'] == _filterYear).toList();
    final double filteredTotal = filtered.fold(0.0,
            (double s, h) =>
        s + ((h['montant_paye'] as num?)?.toDouble() ?? 0.0));

    return Column(children: [
      // ── FILTRES ──
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _chip(label: 'Tous (${all.length})',
                selected: _filterYear == null,
                onTap: () => setState(() => _filterYear = null)),
            ...years.map((y) {
              final int cnt = (byYear[y] as List).length;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _chip(
                    label: '$y ($cnt)',
                    selected: _filterYear == y,
                    onTap: () => setState(() => _filterYear = y)),
              );
            }),
          ]),
        ),
      ),
      const SizedBox(height: 8),

      // ── LISTE ──
      Expanded(
        child: filtered.isEmpty
            ? Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Aucun paiement trouvé',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 15)),
            const SizedBox(height: 6),
            Text('Sélectionnez une autre année',
                style: TextStyle(
                    color: Colors.grey.shade300, fontSize: 12)),
          ],
        ))
            : ListView.builder(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) =>
              _buildPaymentItem(filtered[i], i),
        ),
      ),

      // ── FOOTER TOTAL ──
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _dark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.white70, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('TOTAL VERSÉ',
              style: TextStyle(color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12, letterSpacing: 0.5)),
          const Spacer(),
          Text(
              '${_format(_filterYear == null ? total : filteredTotal)} DH',
              style: const TextStyle(color: _green,
                  fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ),
    ]);
  }

  Widget _buildPaymentItem(Map<String, dynamic> item, int index) {
    final String? dateStr = item['date_paiement'] as String?;
    final double amount =
        (item['montant_paye'] as num?)?.toDouble() ?? 0.0;
    final int? year = item['annee'] as int?;
    final bool hasDoc = item['facture_path'] != null;
    final String statut = item['statut']?.toString() ?? 'impaye';

    String dateLabel = 'Date inconnue';
    if (dateStr != null) {
      try {
        final dt = DateTime.parse(dateStr);
        const months = ['', 'jan', 'fév', 'mar', 'avr', 'mai',
          'juin', 'juil', 'aoû', 'sep', 'oct', 'nov', 'déc'];
        dateLabel = '${dt.day} ${months[dt.month]} ${dt.year}';
      } catch (_) { dateLabel = dateStr; }
    }

    Color statusColor; String statusLabel; IconData statusIcon;
    switch (statut) {
      case 'complet':
        statusColor = _green; statusLabel = 'Complet';
        statusIcon = Icons.check_circle_rounded; break;
      case 'partiel':
        statusColor = _yellow; statusLabel = 'Partiel';
        statusIcon = Icons.timelapse_rounded; break;
      default:
        statusColor = _orange; statusLabel = 'Impayé';
        statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // ── ICONE ──
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),

          // ── INFOS ──
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dateLabel, style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text('Année ${year ?? "???"}',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 11)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(statusLabel, style: TextStyle(
                  color: statusColor, fontSize: 10,
                  fontWeight: FontWeight.bold)),
            ),
          ])),

          // ── MONTANT + RECU ──
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${_format(amount)} DH',
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 6),
            hasDoc ? _btnRecu() : _btnRecuDisabled(),
          ]),
        ]),
      ),
    );
  }

  Widget _btnRecu() => GestureDetector(
    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement du reçu...'),
            behavior: SnackBarBehavior.floating)),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: _dark,
          borderRadius: BorderRadius.circular(8)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.download_rounded, size: 12, color: Colors.white),
        SizedBox(width: 4),
        Text('Reçu', style: TextStyle(
            color: Colors.white, fontSize: 11,
            fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  Widget _btnRecuDisabled() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.download_rounded, size: 12,
          color: Colors.grey.shade400),
      const SizedBox(width: 4),
      Text('Reçu', style: TextStyle(
          color: Colors.grey.shade400, fontSize: 11)),
    ]),
  );

  Widget _chip({required String label, required bool selected,
    required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
              color: selected ? _orange : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? _orange : Colors.grey.shade200),
              boxShadow: selected
                  ? [BoxShadow(color: _orange.withOpacity(0.3),
                  blurRadius: 6, offset: const Offset(0, 2))]
                  : []),
          child: Text(label, style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade600,
              fontWeight: selected
                  ? FontWeight.bold : FontWeight.normal,
              fontSize: 12)),
        ),
      );

  String _format(double v) {
    final String s = v.toStringAsFixed(0);
    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}