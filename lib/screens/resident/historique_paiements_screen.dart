import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import 'resident_dashboard_screen.dart';

class HistoriquePaiementsScreen extends StatefulWidget {
  final int userId;
  final Function(int)? onNavigate;
  const HistoriquePaiementsScreen({
    super.key,
    required this.userId,
    this.onNavigate,
  });
  @override
  State<HistoriquePaiementsScreen> createState() =>
      _HistoriquePaiementsScreenState();
}

class _HistoriquePaiementsScreenState extends State<HistoriquePaiementsScreen>
    with SingleTickerProviderStateMixin {

  final ResidentService _service = ResidentService();
  late int userId;

  late TabController _tabController;

  // ── Mandats (même logique que ResidentChargesScreen) ─────────────
  List<Map<String, dynamic>> _mandats = [];
  Map<String, dynamic>?      _mandatSelectionne;
  bool                       _mandatsLoaded = false;

  // ── Filtre historique par année (dans l'onglet 2)
  int? _filterYear;

  // ── Data
  Map<String, dynamic>? _overview;
  bool _loadingOverview = true;

  Map<String, dynamic>? _history;
  bool _loadingHistory = true;

  static const Color _brand = Color(0xFFFF6B4A);
  static const Color _dark  = Color(0xFF1C1C1E);
  static const Color _green = Color(0xFF34C759);
  static const Color _red   = Color(0xFFFF3B30);
  static const Color _bg    = Color(0xFFF5F0EA);

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    _tabController = TabController(length: 2, vsync: this);
    _loadMandats(); // charge les mandats PUIS déclenche les fetches
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── 1. Charger les mandats (identique à ResidentChargesScreen) ───
  Future<void> _loadMandats() async {
    final mandats = await _service.getMandatsVecus(userId);
    setState(() {
      _mandats = mandats;
      _mandatSelectionne = mandats.isNotEmpty
          ? mandats.firstWhere(
              (m) => m['est_en_cours'] == true,
          orElse: () => mandats.first)
          : null;
      _mandatsLoaded = true;
    });
    // Déclencher les deux fetches une fois le mandat connu
    await Future.wait([_fetchOverview(), _fetchHistory()]);
  }

  // ── 2. Overview filtré par mandat ────────────────────────────────
  // getPaiementOverview filtre par année → on lui passe l'année du
  // mandat sélectionné, et on filtre ensuite les lignes par mandat_id.
  // On utilise getHistoriquePaiementsParMandat pour l'onglet overview
  // car il retourne les paiements filtrés par mandat_id directement.
  Future<void> _fetchOverview() async {
    setState(() => _loadingOverview = true);

    final int? mandatId = _mandatSelectionne?['id'] as int?;

    // Récupère les paiements filtrés par mandat
    final histData = await _service.getHistoriquePaiementsParMandat(
      userId,
      mandatId: mandatId,
    );

    final List<Map<String, dynamic>> paiements =
    List<Map<String, dynamic>>.from(histData['historique'] as List? ?? []);

    // Calculer les totaux depuis les paiements du mandat
    double montantTotal = 0;
    double montantPaye  = 0;
    final List<Map<String, dynamic>> lignes = [];

    for (final p in paiements) {
      final double mt = (p['montant_total'] as num?)?.toDouble() ?? 0.0;
      final double mp = (p['montant_paye']  as num?)?.toDouble() ?? 0.0;
      montantTotal += mt;
      montantPaye  += mp;

      lignes.add({
        'type':          p['type_paiement']?.toString() ?? 'charges',
        'montant_total': mt,
        'montant_paye':  mp,
        'reste':         mt - mp,
        'statut':        p['statut']?.toString() ?? 'impaye',
      });
    }

    final double reste = montantTotal - montantPaye;
    final String statut = montantPaye >= montantTotal && montantTotal > 0
        ? 'complet'
        : (montantPaye > 0 ? 'partiel' : 'impaye');

    // Récupérer les infos de l'appartement pour l'affichage
    final overviewData = await _service.getPaiementOverview(
        userId, DateTime.now().year);

    setState(() {
      _overview = {
        'num_appart':   overviewData['num_appart'],
        'immeuble_nom': overviewData['immeuble_nom'],
        'tranche_nom':  overviewData['tranche_nom'],
        'total_annee':  montantTotal,
        'paye_annee':   montantPaye,
        'reste_annee':  reste,
        'statut':       statut,
        'lignes':       lignes,
        // Période du mandat pour l'affichage
        'mandat_label':      _mandatSelectionne?['label'] ?? '',
        'mandat_syndic_nom': _mandatSelectionne?['syndic_nom'] ?? '',
        'mandat_en_cours':   _mandatSelectionne?['est_en_cours'] == true,
      };
      _loadingOverview = false;
    });
  }

  // ── 3. Historique filtré par mandat ──────────────────────────────
  Future<void> _fetchHistory() async {
    setState(() => _loadingHistory = true);

    final int? mandatId = _mandatSelectionne?['id'] as int?;

    // getHistoriquePaiementsParMandat existe déjà dans resident_service.dart
    final data = await _service.getHistoriquePaiementsParMandat(
      userId,
      mandatId: mandatId,
    );

    setState(() {
      _history        = data;
      _loadingHistory = false;
      _filterYear     = null; // reset filtre année à chaque changement mandat
    });
  }

  // ── 4. Rechargement quand on change de mandat ────────────────────
  void _onMandatChanged(Map<String, dynamic> mandat) {
    setState(() => _mandatSelectionne = mandat);
    Future.wait([_fetchOverview(), _fetchHistory()]);
  }

  @override
  Widget build(BuildContext context) {
    final bool inLayout = widget.onNavigate != null;

    if (!_mandatsLoaded) {
      return const Center(child: CircularProgressIndicator(color: _brand));
    }

    final body = Column(children: [
      // ── Info appartement + sélecteur mandat ──────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_overview != null)
                Text(
                  'Appt ${_overview!['num_appart']} · '
                      '${_overview!['immeuble_nom']} · '
                      '${_overview!['tranche_nom']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
            ]),
          ),
          const SizedBox(width: 8),
          if (_mandats.isNotEmpty) _buildMandatSelector(),
        ]),
      ),

      // ── Bannière mandat ──────────────────────────────────────────
      if (_mandatSelectionne != null) _buildMandatBanner(),

      // ── TabBar ───────────────────────────────────────────────────
      Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          indicatorColor: _brand,
          indicatorWeight: 3,
          labelColor: _brand,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: "Vue d'ensemble"),
            Tab(text: 'Historique'),
          ],
        ),
      ),

      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    ]);

    if (inLayout) return body;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Mon Paiement',
            style: TextStyle(color: Color(0xFF1C1C1E),
                fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: _brand),
      ),
      drawer: ResidentMobileDrawer(currentIndex: 2, userId: userId),
      body: body,
    );
  }

  // ── Sélecteur de mandat (copié de ResidentChargesScreen) ─────────
  Widget _buildMandatSelector() {
    final bool enCours = _mandatSelectionne?['est_en_cours'] == true;
    return GestureDetector(
      onTap: _showMandatPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(enCours ? Icons.radio_button_checked : Icons.history_rounded,
              size: 14, color: enCours ? Colors.green : _brand),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _mandatSelectionne?['label'] ?? 'Mandat',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: enCours ? Colors.green : _dark,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16),
        ]),
      ),
    );
  }

  void _showMandatPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Mes mandats',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ..._mandats.map((m) {
            final bool isSel   = _mandatSelectionne?['id'] == m['id'];
            final bool enCours = m['est_en_cours'] == true;
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: enCours
                      ? Colors.green.withOpacity(0.1)
                      : _brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  enCours ? Icons.radio_button_checked : Icons.history_rounded,
                  color: enCours ? Colors.green : _brand, size: 18,
                ),
              ),
              title: Text(m['label'],
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSel ? _brand : _dark)),
              subtitle: Text(
                '${m['syndic_nom']}${enCours ? ' · En cours' : ''}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              trailing: isSel
                  ? const Icon(Icons.check_circle_rounded, color: _brand)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                _onMandatChanged(m);
              },
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Bannière mandat ──────────────────────────────────────────────
  Widget _buildMandatBanner() {
    final bool enCours = _mandatSelectionne?['est_en_cours'] == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: enCours
          ? Colors.green.withOpacity(0.07)
          : const Color(0xFFEEF1FF),
      child: Row(children: [
        Icon(Icons.verified_user_rounded,
            color: enCours ? Colors.green : const Color(0xFF4B6BFB),
            size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Mandat : ${_mandatSelectionne?['label'] ?? ''}'
                '  ·  Syndic : ${_mandatSelectionne?['syndic_nom'] ?? ''}',
            style: TextStyle(
              color: enCours ? Colors.green : const Color(0xFF4B6BFB),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ONGLET 1 — VUE D'ENSEMBLE
  // ════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _loadingOverview
            ? const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: _brand),
            ))
            : _buildDarkCard(),
      ]),
    );
  }

  Widget _buildDarkCard() {
    if (_overview == null) return const SizedBox();

    final double total  = (_overview!['total_annee'] as num?)?.toDouble() ?? 0.0;
    final double paye   = (_overview!['paye_annee']  as num?)?.toDouble() ?? 0.0;
    final double reste  = (_overview!['reste_annee'] as num?)?.toDouble() ?? 0.0;
    final String statut = (_overview!['statut']      as String?) ?? 'impaye';
    final double pct    = total > 0 ? (paye / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.credit_card_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Mandat : ${_mandatSelectionne?['label'] ?? ''}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                'Syndic : ${_mandatSelectionne?['syndic_nom'] ?? ''}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 20),

        _amountRow('Total mandat',  total, Colors.white.withOpacity(0.1), Colors.white),
        const SizedBox(height: 10),
        _amountRow('Déjà payé',     paye,  const Color(0xFF1A4A2E), _green),
        const SizedBox(height: 10),
        _amountRow('Reste à payer', reste, const Color(0xFF4A1A1A), _red),
        const SizedBox(height: 20),

        // Détail par type de paiement
        if ((_overview!['lignes'] as List?)?.isNotEmpty == true) ...[
          const Text('Détail par type',
              style: TextStyle(color: Colors.white70,
                  fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 10),
          ...(_overview!['lignes'] as List).map((l) => _buildLignePaiement(l)),
          const SizedBox(height: 16),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Progression',
                style: TextStyle(color: Colors.white70,
                    fontWeight: FontWeight.w600, fontSize: 13)),
            Text('${(pct * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(_green),
          ),
        ),
        const SizedBox(height: 16),

        _statutBanner(statut, reste),
      ]),
    );
  }

  Widget _buildLignePaiement(Map ligne) {
    final String type  = ligne['type']?.toString() ?? 'charges';
    final double mt    = (ligne['montant_total'] as num?)?.toDouble() ?? 0.0;
    final double mp    = (ligne['montant_paye']  as num?)?.toDouble() ?? 0.0;
    final String stat  = ligne['statut']?.toString() ?? 'impaye';

    final Color statColor = stat == 'complet'
        ? _green
        : stat == 'partiel'
        ? const Color(0xFFFFCC00)
        : _red;

    final Map<String, IconData> typeIcons = {
      'charges': Icons.apartment_rounded,
      'parking': Icons.local_parking_rounded,
      'garage':  Icons.garage_rounded,
      'box':     Icons.inventory_2_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(typeIcons[type] ?? Icons.receipt_rounded,
            color: Colors.white60, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            type[0].toUpperCase() + type.substring(1),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${_format(mp)} / ${_format(mt)} DH',
              style: const TextStyle(color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w600)),
          Text(stat,
              style: TextStyle(color: statColor,
                  fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _amountRow(String label, double amount, Color bg, Color textColor) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
            Text('${_format(amount)} DH',
                style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _statutBanner(String statut, double reste) {
    final Color bg;
    final Color iconColor;
    final IconData icon;
    final String title;
    final String msg;

    switch (statut) {
      case 'complet':
        bg = const Color(0xFF1A4A2E); iconColor = _green;
        icon = Icons.check_circle_rounded;
        title = 'Paiement complet';
        msg   = 'Vous êtes à jour pour ce mandat';
        break;
      case 'partiel':
        bg = const Color(0xFF4A3A00); iconColor = const Color(0xFFFFCC00);
        icon = Icons.info_outline_rounded;
        title = 'Paiement partiel';
        msg   = 'Il reste ${_format(reste)} DH à régler';
        break;
      default:
        bg = const Color(0xFF4A1A1A); iconColor = _red;
        icon = Icons.warning_amber_rounded;
        title = 'Paiement impayé';
        msg   = 'Montant dû : ${_format(reste)} DH';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(msg,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ONGLET 2 — HISTORIQUE
  // ════════════════════════════════════════════════════════════════
  Widget _buildHistoryTab() {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator(color: _brand));
    }
    if (_history == null) return const SizedBox();

    // historique = liste des paiements du mandat (pas des versements)
    final List<Map<String, dynamic>> all =
    List<Map<String, dynamic>>.from(
        _history!['historique'] as List? ?? []);

    // Grouper par année pour les chips de filtre
    final Map<int, List> byYear = {};
    for (final h in all) {
      final int y = (h['annee'] as int?) ?? 0;
      byYear.putIfAbsent(y, () => []).add(h);
    }
    final List<int> years =
    byYear.keys.cast<int>().toList()..sort((a, b) => b.compareTo(a));

    final List<Map<String, dynamic>> filtered = _filterYear == null
        ? all
        : all.where((h) => h['annee'] == _filterYear).toList();

    final double filteredTotal = filtered.fold(
        0.0,
            (double s, h) =>
        s + ((h['montant_paye'] as num?)?.toDouble() ?? 0.0));

    final double totalVerse =
        (_history!['total_verse'] as num?)?.toDouble() ?? 0.0;

    return Column(children: [
      // ── Chips filtres par année ───────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _chip(
              label: 'Toutes (${all.length})',
              selected: _filterYear == null,
              onTap: () => setState(() => _filterYear = null),
            ),
            ...years.map((y) {
              final int cnt = (byYear[y] as List).length;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _chip(
                  label: '$y ($cnt)',
                  selected: _filterYear == y,
                  onTap: () => setState(() => _filterYear = y),
                ),
              );
            }),
          ]),
        ),
      ),

      Expanded(
        child: filtered.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_rounded,
                  size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('Aucun paiement pour ce mandat',
                  style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) => _buildPaymentItem(filtered[i]),
        ),
      ),

      // ── Total versé ───────────────────────────────────────────────
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
            color: _dark, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Text('TOTAL VERSÉ',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1)),
          const Spacer(),
          Text(
            '${_format(_filterYear == null ? totalVerse : filteredTotal)} DH',
            style: const TextStyle(
                color: _green, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildPaymentItem(Map<String, dynamic> item) {
    final String? dateStr = item['date_paiement'] as String?;
    final double  amount  = (item['montant_paye'] as num?)?.toDouble() ?? 0.0;
    final int?    year    = item['annee'] as int?;
    final String  type    = item['type_paiement']?.toString() ?? 'charges';
    final String  statut  = item['statut']?.toString() ?? 'impaye';

    String dateLabel = '—';
    if (dateStr != null) {
      try {
        final dt = DateTime.parse(dateStr);
        const months = [
          '', 'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
          'juil', 'aoû', 'sep', 'oct', 'nov', 'déc',
        ];
        dateLabel = '${dt.day} ${months[dt.month]} ${dt.year}';
      } catch (_) {
        dateLabel = dateStr;
      }
    }

    final Color statColor = statut == 'complet'
        ? _green
        : statut == 'partiel'
        ? const Color(0xFFFFCC00)
        : _red;

    final Map<String, IconData> typeIcons = {
      'charges': Icons.apartment_rounded,
      'parking': Icons.local_parking_rounded,
      'garage':  Icons.garage_rounded,
      'box':     Icons.inventory_2_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8EE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(typeIcons[type] ?? Icons.receipt_rounded,
              color: _green, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              type[0].toUpperCase() + type.substring(1),
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: _dark),
            ),
            Text(
              dateStr != null ? dateLabel : 'Aucun versement',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (year != null)
              Text('Année $year',
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '${_format(amount)} DH',
            style: const TextStyle(
                color: _green, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statut,
              style: TextStyle(
                  color: statColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? _dark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? _dark : Colors.grey.shade300),
          ),
          child: Text(label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              )),
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