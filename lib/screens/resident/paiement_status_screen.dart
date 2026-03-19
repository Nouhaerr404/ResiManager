import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import 'resident_dashboard_screen.dart';

class HistoriquePaiementsScreen extends StatefulWidget {
  final int userId;
  final Function(int)? onNavigate; // ← AJOUT
  const HistoriquePaiementsScreen({
    super.key,
    this.userId = 3,
    this.onNavigate,
  });

  @override
  State<HistoriquePaiementsScreen> createState() =>
      _HistoriquePaiementsScreenState();
}

class _HistoriquePaiementsScreenState
    extends State<HistoriquePaiementsScreen>
    with SingleTickerProviderStateMixin {

  final ResidentService _service = ResidentService();
  late int userId;
  late TabController _tabController;
  int  _selectedYear = DateTime.now().year;
  int? _filterYear;
  Map<String, dynamic>? _overview;
  bool _loadingOverview = true;
  Map<String, dynamic>? _history;
  bool _loadingHistory = true;

  static const Color _dark  = Color(0xFF1C1C1E);
  static const Color _green = Color(0xFF34C759);
  static const Color _red   = Color(0xFFFF3B30);
  static const Color _bg    = Color(0xFFF5F0EA);

  @override
  void initState() {
    super.initState();
    userId = widget.userId; // ← dynamique
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
    final data = await _service.getPaiementOverview(userId, _selectedYear);
    setState(() { _overview = data; _loadingOverview = false; });
  }

  Future<void> _fetchHistory() async {
    setState(() => _loadingHistory = true);
    final data = await _service.getHistoriquePaiementsComplet(userId);
    setState(() { _history = data; _loadingHistory = false; });
  }

  @override
  Widget build(BuildContext context) {
    final bool inLayout = widget.onNavigate != null; // ← AJOUT

    final body = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mon Paiement Annuel',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E))),
          const SizedBox(height: 4),
          if (_overview != null) ...[
            Text('Appartement ${_overview!['num_appart']} - ${_overview!['immeuble_nom']}',
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            Text('${_overview!['tranche_nom']}',
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                      color: _dark, borderRadius: BorderRadius.circular(10)),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                  tabs: const [
                    Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.grid_view_rounded, size: 18),
                      SizedBox(width: 8), Text("Vue d'ensemble"),
                    ])),
                    Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.history_rounded, size: 18),
                      SizedBox(width: 8), Text('Historique'),
                    ])),
                  ],
                ),
              ),
              SizedBox(
                height: 620,
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildOverviewTab(), _buildHistoryTab()],
                ),
              ),
            ]),
          ),
        ],
      ),
    );

    // ← Si dans layout : juste le body
    if (inLayout) return body;

    // ← Si standalone : Scaffold complet
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Mon Paiement',
            style: TextStyle(color: Color(0xFF1C1C1E),
                fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFFFF6B4A)),
      ),
      drawer: ResidentMobileDrawer(currentIndex: 2, userId: userId),
      body: body,
    );
  }

  // ══════════════════════════════════════════════════════
  // ONGLET 1 — VUE D'ENSEMBLE
  // ══════════════════════════════════════════════════════
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _bg, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.calendar_month_rounded,
                color: Color(0xFF1C1C1E), size: 20),
          ),
          const SizedBox(width: 14),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Annee fiscale',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            Text('Selectionnez une annee',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                isDense: true,
                items: [
                  for (int y = DateTime.now().year;
                  y >= DateTime.now().year - 4; y--)
                    DropdownMenuItem(value: y,
                        child: Text('$y', style: const TextStyle(
                            fontWeight: FontWeight.bold))),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedYear = v);
                    _fetchOverview();
                  }
                },
              ),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        _loadingOverview
            ? const Center(child: Padding(padding: EdgeInsets.all(60),
            child: CircularProgressIndicator(color: Color(0xFFFF6B4A))))
            : _buildDarkCard(),
      ]),
    );
  }

  Widget _buildDarkCard() {
    if (_overview == null) return const SizedBox();
    final double total = (_overview!['total_annee'] as double?) ?? 0.0;
    final double paye  = (_overview!['paye_annee']  as double?) ?? 0.0;
    final double reste = (_overview!['reste_annee'] as double?) ?? 0.0;
    final String statut = (_overview!['statut'] as String?) ?? 'impaye';
    final double pct = total > 0 ? (paye / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
          color: _dark, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.credit_card_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cotisation $_selectedYear',
                style: const TextStyle(color: Colors.white,
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('Etat de vos paiements',
                style: TextStyle(color: Colors.white60, fontSize: 13)),
          ]),
        ]),
        const SizedBox(height: 24),
        Row(children: [
          _amountCard('Total annuel', total,
              Colors.white.withValues(alpha: 0.12), Colors.white),
          const SizedBox(width: 12),
          _amountCard('Deja paye', paye,
              const Color(0xFF1A4A2E), _green),
          const SizedBox(width: 12),
          _amountCard('Reste a payer', reste,
              const Color(0xFF4A1A1A), _red),
        ]),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Progression annuelle',
              style: TextStyle(color: Colors.white70,
                  fontWeight: FontWeight.w600)),
          Text('${(pct * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: pct, minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(_green)),
        ),
        const SizedBox(height: 20),
        _statutBanner(statut, reste),
      ]),
    );
  }

  Widget _amountCard(String label, double amount, Color bg, Color textColor) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
              color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 8),
          Text('${_format(amount)} DH',
              style: TextStyle(color: textColor,
                  fontSize: 22, fontWeight: FontWeight.bold)),
        ]),
      ));

  Widget _statutBanner(String statut, double reste) {
    Color bg; Color iconColor; IconData icon; String title; String msg;
    switch (statut) {
      case 'complet':
        bg = const Color(0xFF1A4A2E); iconColor = _green;
        icon = Icons.check_circle_rounded;
        title = 'Paiement complet';
        msg = 'Vous etes a jour pour cette annee'; break;
      case 'partiel':
        bg = const Color(0xFF4A3A00); iconColor = const Color(0xFFFFCC00);
        icon = Icons.info_outline_rounded;
        title = 'Paiement partiel';
        msg = 'Il reste ${_format(reste)} DH a regler'; break;
      default:
        bg = const Color(0xFF4A1A1A); iconColor = _red;
        icon = Icons.warning_amber_rounded;
        title = 'Paiement impaye';
        msg = 'Montant du : ${_format(reste)} DH';
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: iconColor,
              fontWeight: FontWeight.bold, fontSize: 14)),
          Text(msg, style: const TextStyle(
              color: Colors.white60, fontSize: 12)),
        ]),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  // ONGLET 2 — HISTORIQUE
  // ══════════════════════════════════════════════════════
  Widget _buildHistoryTab() {
    if (_loadingHistory)
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B4A)));
    if (_history == null) return const SizedBox();

    final List<Map<String, dynamic>> all =
    List<Map<String, dynamic>>.from(_history!['historique'] as List);
    final Map byYear = _history!['par_annee'] as Map;
    final double total = _history!['total_verse'] as double;
    final List<int> years =
    byYear.keys.cast<int>().toList()..sort((a, b) => b.compareTo(a));
    final List<Map<String, dynamic>> filtered = _filterYear == null
        ? all : all.where((h) => h['annee'] == _filterYear).toList();
    final double filteredTotal = filtered.fold(0.0,
            (double s, h) => s + (h['montant_paye'] as double));

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            const Icon(Icons.filter_list_rounded,
                color: Colors.grey, size: 18),
            const SizedBox(width: 12),
            _chip(label: 'Toutes (${all.length})',
                selected: _filterYear == null,
                onTap: () => setState(() => _filterYear = null)),
            ...years.map((y) {
              final int cnt = (byYear[y] as List).length;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _chip(label: '$y ($cnt)',
                    selected: _filterYear == y,
                    onTap: () => setState(() => _filterYear = y)),
              );
            }),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: filtered.isEmpty
            ? const Center(child: Text('Aucun paiement.',
            style: TextStyle(color: Colors.grey)))
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) => _buildPaymentItem(filtered[i]),
        ),
      ),
      Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        decoration: BoxDecoration(
            color: _dark, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Text('TOTAL VERSE', style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
          const Spacer(),
          Text('${_format(_filterYear == null ? total : filteredTotal)} DH',
              style: const TextStyle(color: _green,
                  fontWeight: FontWeight.bold, fontSize: 22)),
        ]),
      ),
    ]);
  }

  Widget _buildPaymentItem(Map<String, dynamic> item) {
    final String? dateStr = item['date_paiement'] as String?;
    final double amount = (item['montant_paye'] as num?)?.toDouble() ?? 0.0;
    final int? year = item['annee'] as int?;
    final bool hasDoc = item['facture_path'] != null;
    String dateLabel = '???';
    if (dateStr != null) {
      try {
        final dt = DateTime.parse(dateStr);
        const months = ['', 'janvier', 'fevrier', 'mars', 'avril', 'mai',
          'juin', 'juillet', 'aout', 'septembre', 'octobre', 'novembre', 'decembre'];
        dateLabel = '${dt.day} ${months[dt.month]} ${dt.year}';
      } catch (_) { dateLabel = dateStr; }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFE8F8EE),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.check_circle_rounded,
              color: Color(0xFF34C759), size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.w600,
              fontSize: 15, color: Color(0xFF1C1C1E))),
          Text('Annee fiscale ${year ?? "???"}',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${_format(amount)} DH',
              style: const TextStyle(color: Color(0xFF34C759),
                  fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 6),
          hasDoc ? _btnRecu(item['facture_path'] as String)
              : _btnRecuDisabled(),
        ]),
      ]),
    );
  }

  Widget _btnRecu(String path) => ElevatedButton.icon(
    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telechargement du recu...'),
            behavior: SnackBarBehavior.floating)),
    icon: const Icon(Icons.download_rounded, size: 14),
    label: const Text('Recu',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    style: ElevatedButton.styleFrom(backgroundColor: _dark,
        foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
  );

  Widget _btnRecuDisabled() => OutlinedButton.icon(
    onPressed: null,
    icon: const Icon(Icons.download_rounded, size: 14),
    label: const Text('Recu', style: TextStyle(fontSize: 13)),
    style: OutlinedButton.styleFrom(foregroundColor: Colors.grey,
        side: const BorderSide(color: Colors.grey),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
  );

  Widget _chip({required String label, required bool selected,
    required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: selected ? _dark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? _dark : Colors.grey.shade300)),
          child: Text(label, style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade700,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13)),
        ),
      );

  String _format(double v) {
    final String s = v.truncate().toString();
    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}