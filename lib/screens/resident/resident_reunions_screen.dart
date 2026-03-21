import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/resident_service.dart';
import 'resident_dashboard_screen.dart';

class ResidentReunionsScreen extends StatefulWidget {
  final int userId;
  final Function(int)? onNavigate;
  const ResidentReunionsScreen({
    super.key,
    this.userId = 3,
    this.onNavigate,
  });

  @override
  _ResidentReunionsScreenState createState() => _ResidentReunionsScreenState();
}

class _ResidentReunionsScreenState extends State<ResidentReunionsScreen>
    with SingleTickerProviderStateMixin {
  final ResidentService _service = ResidentService();
  final _db = Supabase.instance.client;

  late int userId;
  int? _residentId;

  final Map<int, String> _statusMap = {};
  final Map<int, String?> _pendingMap = {};
  final Map<int, bool> _loadingMap = {};
  Future<List<Map<String, dynamic>>>? _future;

  // ── NOUVEAU : tabs + filtre année ──
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;
  List<int> _availableYears = [];

  static const _orange = Color(0xFFFF6B4A);

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── LOGIQUE ORIGINALE INCHANGÉE ───

  Future<void> _init() async {
    try {
      final resRow = await _db
          .from('residents')
          .select('id')
          .eq('user_id', userId)
          .single();
      _residentId = resRow['id'] as int;
      _loadReunions();
    } catch (e) {
      print("Erreur init résidentId: $e");
      setState(() { _future = Future.value([]); });
    }
  }

  void _loadReunions() {
    if (_residentId == null) return;
    setState(() { _future = _fetchReunionsWithStatus(); });
  }

  Future<List<Map<String, dynamic>>> _fetchReunionsWithStatus() async {
    final resData = await _db
        .from('residents')
        .select('appartement_id')
        .eq('id', _residentId!)
        .single();

    final appartData = await _db
        .from('appartements')
        .select('immeuble_id')
        .eq('id', resData['appartement_id'])
        .single();

    final immData = await _db
        .from('immeubles')
        .select('tranche_id')
        .eq('id', appartData['immeuble_id'])
        .single();

    final int trancheId = immData['tranche_id'] as int;

    final List reunionsRaw = await _db
        .from('reunions')
        .select()
        .eq('tranche_id', trancheId)
        .order('date', ascending: false);

    final List participationRaw = await _db
        .from('reunion_resident')
        .select('reunion_id, confirmation')
        .eq('resident_id', userId); // ← residents.id (correct)

    final Map<int, String> statusByReunion = {
      for (final p in participationRaw)
        (p['reunion_id'] as int): p['confirmation'] as String,
    };

    final result = reunionsRaw.map((r) {
      final Map<String, dynamic> reunion = Map<String, dynamic>.from(r as Map);
      final int id = reunion['id'] as int;
      reunion['mon_statut'] = statusByReunion[id] ?? 'en_attente';
      return reunion;
    }).toList().cast<Map<String, dynamic>>();

    // Extraire années disponibles pour le filtre
    final years = result
        .map((r) => DateTime.tryParse(r['date']?.toString() ?? '')?.year)
        .whereType<int>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (mounted) {
      setState(() {
        _availableYears = years;
        if (years.isNotEmpty && !years.contains(_selectedYear)) {
          _selectedYear = years.first;
        }
      });
    }

    for (final r in result) {
      final id = r['id'] as int;
      if (!_statusMap.containsKey(id)) {
        _statusMap[id]  = r['mon_statut'] as String;
        _pendingMap[id] = null;
      }
    }
    return result;
  }

  void _select(int reunionId, String choice) =>
      setState(() => _pendingMap[reunionId] = choice);

  Future<void> _confirm(int reunionId) async {
    final choice = _pendingMap[reunionId];
    if (choice == null || _residentId == null) return;
    setState(() => _loadingMap[reunionId] = true);
    try {
      await _db.from('reunion_resident').upsert(
        {
          'reunion_id'  : reunionId,
          'resident_id' : userId,  // ← residents.id (correct)
          'confirmation': choice,
        },
        onConflict: 'reunion_id,resident_id',
      );
      setState(() {
        _statusMap[reunionId]  = choice;
        _pendingMap[reunionId] = null;
      });
      _snack(
        choice == 'confirme' ? "✅ Présence confirmée !" : "❌ Absence enregistrée.",
        choice == 'confirme' ? const Color(0xFF059669) : const Color(0xFFEF4444),
      );
    } catch (e) {
      _snack("Erreur : $e", Colors.red);
    } finally {
      setState(() => _loadingMap[reunionId] = false);
    }
  }

  Future<void> _cancel(int reunionId) async {
    if (_residentId == null) return;
    setState(() => _loadingMap[reunionId] = true);
    try {
      await _db.from('reunion_resident').upsert(
        {
          'reunion_id'  : reunionId,
          'resident_id' : userId,  // ← residents.id (correct)
          'confirmation': 'en_attente',
        },
        onConflict: 'reunion_id,resident_id',
      );
      setState(() {
        _statusMap[reunionId]  = 'en_attente';
        _pendingMap[reunionId] = null;
      });
      _snack("↩️ Participation annulée.", const Color(0xFF6B7280));
    } catch (e) {
      _snack("Erreur : $e", Colors.red);
    } finally {
      setState(() => _loadingMap[reunionId] = false);
    }
  }

  void _clearPending(int reunionId) =>
      setState(() => _pendingMap[reunionId] = null);

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(20),
    ));
  }

  // ─── SÉPARATION À VENIR / PASSÉ ───
  bool _isUpcoming(Map<String, dynamic> r) {
    final date = DateTime.tryParse(r['date']?.toString() ?? '');
    if (date == null) return false;
    return !date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool inLayout = widget.onNavigate != null;
    final body = _buildBody();
    if (inLayout) return body;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text("Réunions",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _orange),
      ),
      drawer: ResidentMobileDrawer(currentIndex: 4, userId: userId),
      body: body,
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (_future == null ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _orange));
        }
        if (snapshot.hasError) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text("Erreur : ${snapshot.error}", textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _init, child: const Text("Réessayer")),
            ],
          ));
        }

        final allReunions = snapshot.data ?? [];
        final upcoming = allReunions.where(_isUpcoming).toList();
        final history = allReunions
            .where((r) => !_isUpcoming(r))
            .where((r) {
          final date = DateTime.tryParse(r['date']?.toString() ?? '');
          return date?.year == _selectedYear;
        })
            .toList();

        final confirmed = allReunions
            .where((r) => (_statusMap[r['id']] ?? r['mon_statut']) == 'confirme')
            .length;

        return Column(
          children: [
            // ── Header ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [_orange, Color(0xFFFF9A6C)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.groups_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Réunions",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A))),
                      Text("${allReunions.length} au total",
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 13)),
                    ]),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    _statChip(Icons.event_rounded,
                        "${upcoming.length} à venir", _orange),
                    const SizedBox(width: 10),
                    _statChip(Icons.check_circle_rounded,
                        "$confirmed confirmées", const Color(0xFF059669)),
                  ]),
                ],
              ),
            ),
            // ── Tabs ──
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: _orange,
                indicatorWeight: 3,
                labelColor: _orange,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
                tabs: [
                  Tab(text: "À venir (${upcoming.length})"),
                  Tab(text: "Historique"),
                ],
              ),
            ),
            // ── Contenu tabs ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── ONGLET À VENIR : logique participation complète originale ──
                  upcoming.isEmpty
                      ? _buildEmpty("Aucune réunion à venir")
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    itemCount: upcoming.length,
                    itemBuilder: (_, i) => _buildCard(upcoming[i]),
                  ),
                  // ── ONGLET HISTORIQUE : lecture seule + filtre année ──
                  Column(
                    children: [
                      if (_availableYears.isNotEmpty) _buildYearFilter(),
                      Expanded(
                        child: history.isEmpty
                            ? _buildEmpty(
                            "Aucune réunion passée pour $_selectedYear")
                            : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          itemCount: history.length,
                          itemBuilder: (_, i) =>
                              _buildHistoryCard(history[i]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildYearFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFFAF9F6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableYears.length,
        itemBuilder: (_, i) {
          final year = _availableYears[i];
          final selected = year == _selectedYear;
          return GestureDetector(
            onTap: () => setState(() => _selectedYear = year),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? _orange : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected ? _orange : Colors.grey.shade300),
                boxShadow: selected
                    ? [BoxShadow(
                    color: _orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2))]
                    : [],
              ),
              child: Text(year.toString(),
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.event_busy_rounded, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 14),
        Text(msg, style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
      ],
    ));
  }

  // ── CARTE HISTORIQUE (compacte, lecture seule) ──
  Widget _buildHistoryCard(Map<String, dynamic> r) {
    final int id = r['id'] as int;
    final String confirmed = _statusMap[id] ?? r['mon_statut'] ?? 'en_attente';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 4,
          height: 55,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r['titre']?.toString() ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 5),
            Row(children: [
              Icon(Icons.calendar_today_rounded,
                  size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(r['date']?.toString() ?? '—',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(width: 12),
              Icon(Icons.location_on_rounded,
                  size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Flexible(
                child: Text(r['lieu']?.toString() ?? '—',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ],
        )),
        _participationBadge(confirmed),
      ]),
    );
  }

  Widget _participationBadge(String status) {
    final map = {
      'confirme' : (const Color(0xFF059669), Icons.check_circle_rounded, "Présent"),
      'absent'   : (const Color(0xFFEF4444), Icons.cancel_rounded, "Absent"),
      'en_attente': (const Color(0xFF9CA3AF), Icons.help_outline_rounded, "—"),
    };
    final cfg = map[status] ?? map['en_attente']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cfg.$1.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(cfg.$2, size: 13, color: cfg.$1),
        const SizedBox(width: 4),
        Text(cfg.$3, style: TextStyle(
            color: cfg.$1, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ── CARTE À VENIR : LOGIQUE ORIGINALE COMPLÈTE (copie exacte du fichier 7) ──
  Widget _buildCard(Map<String, dynamic> r) {
    final int id            = r['id'] as int;
    final String confirmed  = _statusMap[id]  ?? 'en_attente';
    final String? pending   = _pendingMap[id];
    final bool isLoading    = _loadingMap[id] ?? false;
    final String display    = pending ?? confirmed;
    final bool hasConfirmed = confirmed != 'en_attente';
    final bool hasPending   = pending != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // ── Header gradient orange ──
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_orange, Color(0xFFFF9A6C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.groups_outlined,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['titre']?.toString() ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  if ((r['description'] ?? '').toString().isNotEmpty)
                    Text(r['description'].toString(),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                ])),
            _statusBadge(r['statut']?.toString() ?? ''),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            Row(children: [
              _infoBox("Date",  r['date']?.toString()  ?? '—',
                  Icons.calendar_today_rounded, _orange),
              const SizedBox(width: 12),
              _infoBox("Heure", r['heure']?.toString() ?? '—',
                  Icons.access_time_rounded, const Color(0xFF2563EB)),
              const SizedBox(width: 12),
              _infoBox("Lieu",  r['lieu']?.toString()  ?? '—',
                  Icons.location_on_rounded, const Color(0xFF059669)),
            ]),
            const SizedBox(height: 24),

            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _bgColor(display),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor(display), width: 1.5),
              ),
              child: isLoading
                  ? const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _orange),
              ))
                  : Column(children: [
                Row(children: [
                  Icon(_icon(display), color: _color(display), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    hasPending
                        ? (pending == 'confirme'
                        ? "Confirmer votre présence ?"
                        : "Confirmer votre absence ?")
                        : "Votre participation",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _color(display)),
                  ),
                ]),
                const SizedBox(height: 16),

                // ── ÉTAT A : en_attente, rien sélectionné ──
                if (!hasConfirmed && !hasPending)
                  Row(children: [
                    Expanded(child: _choiceBtn(
                      label: "Je serai présent",
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF059669),
                      onTap: () => _select(id, 'confirme'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _choiceBtn(
                      label: "Je serai absent",
                      icon: Icons.cancel_outlined,
                      color: const Color(0xFFEF4444),
                      onTap: () => _select(id, 'absent'),
                    )),
                  ]),

                // ── ÉTAT B : choix en attente de confirmation ──
                if (hasPending)
                  Row(children: [
                    OutlinedButton.icon(
                      onPressed: () => _select(id,
                          pending == 'confirme' ? 'absent' : 'confirme'),
                      icon: Icon(
                        pending == 'confirme'
                            ? Icons.cancel_outlined
                            : Icons.check_circle_outline_rounded,
                        size: 16,
                      ),
                      label: Text(
                          pending == 'confirme' ? "Absent" : "Présent"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _clearPending(id),
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: Color(0xFF9CA3AF)),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: ElevatedButton.icon(
                      onPressed: () => _confirm(id),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text("Confirmer",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pending == 'confirme'
                            ? const Color(0xFF059669)
                            : const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    )),
                  ]),

                // ── ÉTAT C : confirmé en DB ──
                if (hasConfirmed && !hasPending) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _color(confirmed).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            confirmed == 'confirme'
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: _color(confirmed),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            confirmed == 'confirme'
                                ? "Présence confirmée"
                                : "Absence enregistrée",
                            style: TextStyle(
                                color: _color(confirmed),
                                fontWeight: FontWeight.w600),
                          ),
                        ]),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancel(id),
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      label: const Text("Annuler ma participation",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  // WIDGETS HELPERS (identiques à l'original)
  // ─────────────────────────────────────────────

  Widget _choiceBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          elevation: 0,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );

  Widget _infoBox(String label, String value, IconData icon, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
        ]),
      ));

  Widget _statusBadge(String statut) {
    final map = {
      'planifiee': (const Color(0xFFF59E0B), "Planifiée"),
      'confirmee': (const Color(0xFF10B981), "Confirmée"),
      'terminee' : (const Color(0xFF6B7280), "Terminée"),
      'annulee'  : (const Color(0xFFEF4444), "Annulée"),
    };
    final cfg = map[statut] ?? (const Color(0xFF6B7280), statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: cfg.$1.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.$1.withOpacity(0.5)),
      ),
      child: Text(cfg.$2, style: TextStyle(
          color: cfg.$1, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Color    _color(String s)       => s == 'confirme' ? const Color(0xFF059669) : s == 'absent' ? const Color(0xFFEF4444) : const Color(0xFF6B7280);
  Color    _bgColor(String s)     => s == 'confirme' ? const Color(0xFFF0FDF4) : s == 'absent' ? const Color(0xFFFFF1F2) : const Color(0xFFF9FAFB);
  Color    _borderColor(String s) => s == 'confirme' ? const Color(0xFFBBF7D0) : s == 'absent' ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB);
  IconData _icon(String s)        => s == 'confirme' ? Icons.check_circle_rounded : s == 'absent' ? Icons.cancel_rounded : Icons.help_outline_rounded;
}