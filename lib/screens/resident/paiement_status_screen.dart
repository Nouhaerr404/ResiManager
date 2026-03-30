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

  // FILTRES AVANCÉS
  int? _filterYear;
  int? _filterMonth;
  String _filterStatus = 'tous';
  String _filterType = 'tous';
  List<Map<String, dynamic>> _mandats = [];
  Map<String, dynamic>? _mandatSelectionne;
  bool _mandatsLoaded = false;

  static const Color _orange  = Color(0xFFFF6B4A);
  static const Color _purple  = Color(0xFF6C63FF);
  static const Color _green   = Color(0xFF2ECC71);
  static const Color _yellow  = Color(0xFFFFC107);
  static const Color _dark    = Color(0xFF1E1E2C);
  static const Color _bg      = Color(0xFFF4F6F9);
  static const Color _white   = Colors.white;

  @override
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMandats();
  }

  Future<void> _loadMandats() async {
    final mandats = await _service.getMandatsVecus(widget.userId);
    setState(() {
      _mandats = mandats;
      _mandatSelectionne = mandats.isNotEmpty
          ? mandats.firstWhere(
              (m) => m['est_en_cours'] == true,
          orElse: () => mandats.first)
          : null;
      _mandatsLoaded = true;
    });
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
    final data = await _service.getHistoriquePaiementsParMandat(
      widget.userId,
      mandatId: _mandatSelectionne?['id'],
    );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResidentDashboardScreen(userId: widget.userId),
            ),
          ),
        ),
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
    if (_mandats.isEmpty) return const SizedBox();
    final bool enCours = _mandatSelectionne?['est_en_cours'] == true;
    return GestureDetector(
      onTap: () => showModalBottomSheet(
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
              final bool isSel = _mandatSelectionne?['id'] == m['id'];
              final bool ec    = m['est_en_cours'] == true;
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ec ? Colors.green.withOpacity(0.1)
                        : _orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    ec ? Icons.radio_button_checked : Icons.history_rounded,
                    color: ec ? Colors.green : _orange, size: 18,
                  ),
                ),
                title: Text(m['label'],
                    style: TextStyle(fontWeight: FontWeight.w600,
                        color: isSel ? _orange : _dark)),
                subtitle: Text(
                  '${m['syndic_nom']}${ec ? ' · En cours' : ''}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                trailing: isSel
                    ? const Icon(Icons.check_circle_rounded, color: _orange)
                    : null,
                onTap: () {
                  setState(() => _mandatSelectionne = m);
                  Navigator.pop(ctx);
                  _fetchHistory();
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            enCours ? Icons.radio_button_checked : Icons.history_rounded,
            color: Colors.white, size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            _mandatSelectionne?['label'] ?? 'Mandat',
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
        ]),
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
        _buildLignesDetail(),

      ]),
    );
  }
  Widget _buildLignesDetail() {
    final List lignes = (_overview!['lignes'] as List?) ?? [];
    if (lignes.isEmpty) return const SizedBox();

    // Icône + couleur selon type
    IconData _typeIcon(String type) {
      switch (type) {
        case 'parking': return Icons.local_parking_rounded;
        case 'garage':  return Icons.garage_rounded;
        case 'box':     return Icons.inventory_2_rounded;
        default:        return Icons.home_work_rounded;
      }
    }

    String _typeLabel(String type, String? ref) {
      switch (type) {
        case 'parking': return 'Parking${ref != null ? ' $ref' : ''}';
        case 'garage':  return 'Garage${ref != null ? ' $ref' : ''}';
        case 'box':     return 'Box${ref != null ? ' $ref' : ''}';
        default:        return 'Charges';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Détail des cotisations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 14),
        ...lignes.map((l) {
          final String type   = l['type']  as String? ?? 'charges';
          final String? ref   = l['reference'] as String?;
          final double  mt    = (l['montant_total'] as num?)?.toDouble() ?? 0;
          final double  mp    = (l['montant_paye']  as num?)?.toDouble() ?? 0;
          final double  reste = (l['reste']         as num?)?.toDouble() ?? 0;
          final String  stat  = l['statut']         as String? ?? 'impaye';
          final double  pct   = mt > 0 ? (mp / mt).clamp(0.0, 1.0) : 0.0;

          Color color;
          switch (stat) {
            case 'complet': color = _green;  break;
            case 'partiel': color = _yellow; break;
            default:        color = _orange;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_typeIcon(type), color: color, size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  _typeLabel(type, ref),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                )),
                _statutChip(stat),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ligneMontant('Payé',  mp,     _green),
                  _ligneMontant('Reste', reste,  _orange),
                  _ligneMontant('Total', mt,     _purple),
                ],
              ),
            ]),
          );
        }).toList(),
      ]),
    );
  }

  Widget _ligneMontant(String label, double amount, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        Text('${_format(amount)} DH',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ]);
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

    // Extraire les années et mois dispos
    final Set<int> availableYears = all.map((h) => (h['annee'] as int?) ?? 0).toSet();
    final List<int> sortedYears = availableYears.toList()..sort((a, b) => b.compareTo(a));

    // Filtrage combiné
    final List<Map<String, dynamic>> filtered = all.where((h) {
      final bool yearMatch   = _filterYear == null   || h['annee'] == _filterYear;
      final bool monthMatch  = _filterMonth == null  || h['mois'] == _filterMonth;
      final bool statusMatch = _filterStatus == 'tous' || h['statut'] == _filterStatus;
      final bool typeMatch   = _filterType == 'tous'   || h['type_paiement'] == _filterType;
      return yearMatch && monthMatch && statusMatch && typeMatch;
    }).toList();

    final double filteredTotal = filtered.fold(0.0,
            (double s, h) => s + ((h['montant_paye'] as num?)?.toDouble() ?? 0.0));

    return Column(children: [
      // ── BARRE DE FILTRES AVANCÉS ──
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            // FILTRE TYPE
            _filterDropdown<String>(
              label: "Type",
              value: _filterType,
              items: {
                'tous': 'Tous types',
                'charges': 'Charges',
                'parking': 'Parking',
                'garage': 'Garage',
                'box': 'Box',
              },
              onChanged: (v) => setState(() => _filterType = v!),
            ),
            const SizedBox(width: 8),
            // FILTRE STATUT
            _filterDropdown<String>(
              label: "Statut",
              value: _filterStatus,
              items: {
                'tous': 'Tous statuts',
                'complet': 'Complet',
                'partiel': 'Partiel',
                'impaye': 'Impayé',
              },
              onChanged: (v) => setState(() => _filterStatus = v!),
            ),
            const SizedBox(width: 8),
            // FILTRE ANNÉE
            _filterDropdown<int?>(
              label: "Année",
              value: _filterYear,
              items: {
                null: 'Toutes',
                for (var y in sortedYears) y: '$y',
              },
              onChanged: (v) => setState(() => _filterYear = v),
            ),
            const SizedBox(width: 8),
            // FILTRE MOIS
            _filterDropdown<int?>(
              label: "Mois",
              value: _filterMonth,
              items: {
                null: 'Tous',
                1: 'Janv', 2: 'Févr', 3: 'Mars', 4: 'Avril',
                5: 'Mai', 6: 'Juin', 7: 'Juil', 8: 'Août',
                9: 'Sept', 10: 'Oct', 11: 'Nov', 12: 'Déc',
              },
              onChanged: (v) => setState(() => _filterMonth = v),
            ),
          ]),
        ),
      ),

      // ── COMPTEUR ──
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          Text('${filtered.length} résultat(s)',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (_filterYear != null || _filterMonth != null || _filterStatus != 'tous' || _filterType != 'tous')
            GestureDetector(
              onTap: () => setState(() {
                _filterYear = null; _filterMonth = null;
                _filterStatus = 'tous'; _filterType = 'tous';
              }),
              child: const Text('Réinitialiser',
                  style: TextStyle(color: _orange, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ]),
      ),

      // ── LISTE ──
      Expanded(
        child: filtered.isEmpty
            ? Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Aucun résultat pour ces filtres',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 15)),
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
          const Text('TOTAL FILTRÉ',
              style: TextStyle(color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12, letterSpacing: 0.5)),
          const Spacer(),
          Text(
              '${_format(filteredTotal)} DH',
              style: const TextStyle(color: _green,
                  fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ),
    ]);
  }

  Widget _filterDropdown<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          hint: Text(label, style: const TextStyle(fontSize: 12)),
          style: const TextStyle(color: _dark, fontSize: 12, fontWeight: FontWeight.w600),
          items: items.entries.map((e) => DropdownMenuItem<T>(
            value: e.key,
            child: Text(e.value),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> item, int index) {
    final String? dateStr  = item['date_paiement'] as String?;
    final double  amount   = (item['montant_paye'] as num?)?.toDouble() ?? 0.0;
    final int?    year     = item['annee'] as int?;
    final int?    month    = item['mois'] as int?;
    final String  type     = item['type_paiement']?.toString() ?? 'charges';
    final String? ref      = item['reference'] as String?;
    final String  statut   = item['statut']?.toString() ?? 'impaye';

    String dateLabel = 'Date inconnue';
    if (dateStr != null) {
      try {
        final dt = DateTime.parse(dateStr);
        const months = ['', 'jan', 'fév', 'mar', 'avr', 'mai',
          'juin', 'juil', 'aoû', 'sep', 'oct', 'nov', 'déc'];
        dateLabel = '${dt.day} ${months[dt.month]} ${dt.year}';
      } catch (_) { dateLabel = dateStr; }
    }

    // Libellé mois/année de la cotisation
    String targetLabel = "";
    if (month != null && year != null) {
       const monthsFull = ['', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
       targetLabel = "Cotisation ${monthsFull[month]} $year";
    }

    // ── Couleur selon STATUT
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

    // ── Icône + couleur selon TYPE
    IconData typeIcon; Color typeColor; String typeLabel;
    switch (type) {
      case 'garage':
        typeIcon = Icons.garage_rounded;
        typeColor = const Color(0xFF0891B2);
        typeLabel = 'Garage${ref != null ? ' $ref' : ''}'; break;
      case 'parking':
        typeIcon = Icons.local_parking_rounded;
        typeColor = _purple;
        typeLabel = 'Parking${ref != null ? ' $ref' : ''}'; break;
      case 'box':
        typeIcon = Icons.inventory_2_rounded;
        typeColor = _yellow;
        typeLabel = 'Box${ref != null ? ' $ref' : ''}'; break;
      default:
        typeIcon = Icons.home_work_rounded;
        typeColor = _orange;
        typeLabel = 'Charges';
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
          // ── ICONE TYPE
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),

          // ── INFOS ──
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(targetLabel.isNotEmpty ? targetLabel : dateLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            if (targetLabel.isNotEmpty)
              Text("Payé le $dateLabel", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            const SizedBox(height: 6),

            Row(children: [
              // BADGE TYPE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(typeIcon, size: 10, color: typeColor),
                  const SizedBox(width: 3),
                  Text(typeLabel, style: TextStyle(
                      color: typeColor, fontSize: 10,
                      fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(width: 6),
              // BADGE STATUT
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon, size: 10, color: statusColor),
                  const SizedBox(width: 3),
                  Text(statusLabel, style: TextStyle(
                      color: statusColor, fontSize: 10,
                      fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
          ])),

          // ── MONTANT ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_format(amount)} DH',
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              _btnRecuMini(),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _btnRecuMini() => GestureDetector(
    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement du reçu...'),
            behavior: SnackBarBehavior.floating)),
    child: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text('Détails >', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
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
