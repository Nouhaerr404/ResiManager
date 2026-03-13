import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/resident_service.dart';
import '../../widgets/resident_nav_bar.dart';
import 'resident_dashboard_screen.dart';

class ResidentReunionsScreen extends StatefulWidget {
  @override
  _ResidentReunionsScreenState createState() => _ResidentReunionsScreenState();
}

class _ResidentReunionsScreenState extends State<ResidentReunionsScreen> {
  final ResidentService _service = ResidentService();
  final _db = Supabase.instance.client;

  // userId = id dans la table USERS (clé de session)
  final int userId = 3;

  // residentId = id dans la table RESIDENTS (PK, différent de userId)
  int? _residentId;

  // Statut confirmé en DB par reunion_id
  final Map<int, String> _statusMap = {};
  // Choix sélectionné mais pas encore confirmé
  final Map<int, String?> _pendingMap = {};
  // Loading par reunion_id
  final Map<int, bool> _loadingMap = {};

  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // ─── Résoudre residents.id puis charger les réunions ───
  Future<void> _init() async {
    try {
      // 1. Résoudre le vrai residents.id depuis users.id
      final resRow = await _db
          .from('residents')
          .select('id')
          .eq('user_id', userId)
          .single();
      _residentId = resRow['id'] as int;

      // 2. Charger les réunions maintenant qu'on a residentId
      _loadReunions();
    } catch (e) {
      print("Erreur init résidentId: $e");
      setState(() {
        _future = Future.value([]);
      });
    }
  }

  void _loadReunions() {
    if (_residentId == null) return;

    setState(() {
      _future = _fetchReunionsWithStatus();
    });
  }

  // Fetch réunions + statuts avec le BON resident_id
  Future<List<Map<String, dynamic>>> _fetchReunionsWithStatus() async {
    // 1. Trouver tranche_id du résident
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

    // 2. Réunions de la tranche
    final List reunionsRaw = await _db
        .from('reunions')
        .select()
        .eq('tranche_id', trancheId)
        .order('date', ascending: true);

    // 3. Participations avec le BON residents.id (pas user_id !)
    final List participationRaw = await _db
        .from('reunion_resident')
        .select('reunion_id, confirmation')
        .eq('resident_id', _residentId!);

    // Index reunion_id → confirmation
    final Map<int, String> statusByReunion = {
      for (final p in participationRaw)
        (p['reunion_id'] as int): p['confirmation'] as String,
    };

    // 4. Fusionner + initialiser les maps d'état
    final result = reunionsRaw.map((r) {
      final Map<String, dynamic> reunion = Map<String, dynamic>.from(r as Map);
      final int id = reunion['id'] as int;
      reunion['mon_statut'] = statusByReunion[id] ?? 'en_attente';
      return reunion;
    }).toList().cast<Map<String, dynamic>>();

    // Initialiser les maps d'état UI
    for (final r in result) {
      final id = r['id'] as int;
      if (!_statusMap.containsKey(id)) {
        _statusMap[id]  = r['mon_statut'] as String;
        _pendingMap[id] = null;
      }
    }

    return result;
  }

  // Étape 1 : clic → pending (pas encore en DB)
  void _select(int reunionId, String choice) {
    setState(() => _pendingMap[reunionId] = choice);
  }

  // Étape 2 : confirmer → upsert en DB avec le BON resident_id
  Future<void> _confirm(int reunionId) async {
    final choice = _pendingMap[reunionId];
    if (choice == null || _residentId == null) return;

    setState(() => _loadingMap[reunionId] = true);
    try {
      await _db.from('reunion_resident').upsert(
        {
          'reunion_id'   : reunionId,
          'resident_id'  : _residentId!, // ← BON id (residents.id)
          'confirmation' : choice,
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

  // Étape 3 : annuler → remettre en_attente en DB
  Future<void> _cancel(int reunionId) async {
    if (_residentId == null) return;
    setState(() => _loadingMap[reunionId] = true);
    try {
      await _db.from('reunion_resident').upsert(
        {
          'reunion_id'  : reunionId,
          'resident_id' : _residentId!,
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

  // Annuler la sélection locale sans toucher la DB
  void _clearPending(int reunionId) {
    setState(() => _pendingMap[reunionId] = null);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(20),
    ));
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text("Réunions", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFFFF6B4A)),
      ),
// ✅ CORRIGÉ
      drawer: ResidentMobileDrawer(currentIndex: 3),      body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        // Pas encore initialisé (résolution residentId en cours)
        if (_future == null || snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text("Erreur : ${snapshot.error}", textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _init, child: const Text("Réessayer")),
            ]),
          );
        }

        final reunions = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 18),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Réunions",
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                  Text(
                    "${reunions.length} réunion${reunions.length > 1 ? 's' : ''} programmée${reunions.length > 1 ? 's' : ''}",
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                ]),
              ]),
              const SizedBox(height: 32),

              if (reunions.isEmpty)
                Center(child: Column(children: [
                  const SizedBox(height: 60),
                  Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("Aucune réunion prévue.",
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
                ])),

              ...reunions.map((r) => _buildCard(r)).toList(),
            ],
          ),
        );
      },
    ),
    );
  }

  // ─────────────────────────────────────────────
  // CARD RÉUNION
  // ─────────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> r) {
    final int id           = r['id'] as int;
    final String confirmed = _statusMap[id]  ?? 'en_attente';
    final String? pending  = _pendingMap[id];
    final bool isLoading   = _loadingMap[id] ?? false;
    final String display   = pending ?? confirmed;
    final bool hasConfirmed = confirmed != 'en_attente';
    final bool hasPending   = pending != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [

        // ── Header violet dégradé ──
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4338CA)],
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_outlined, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r['titre']?.toString() ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              if ((r['description'] ?? '').toString().isNotEmpty)
                Text(r['description'].toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ])),
            _statusBadge(r['statut']?.toString() ?? ''),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(children: [

            // ── Infos date / heure / lieu ──
            Row(children: [
              _infoBox("Date",  r['date']?.toString()  ?? '—', Icons.calendar_today_rounded, const Color(0xFF7C3AED)),
              const SizedBox(width: 12),
              _infoBox("Heure", r['heure']?.toString() ?? '—', Icons.access_time_rounded,    const Color(0xFF2563EB)),
              const SizedBox(width: 12),
              _infoBox("Lieu",  r['lieu']?.toString()  ?? '—', Icons.location_on_rounded,    const Color(0xFF059669)),
            ]),
            const SizedBox(height: 24),

            // ── Zone participation (animée) ──
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
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
              ))
                  : Column(children: [

                // Label état courant
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
                      color: _color(display),
                    ),
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
                    // Basculer vers l'autre choix
                    OutlinedButton.icon(
                      onPressed: () => _select(id, pending == 'confirme' ? 'absent' : 'confirme'),
                      icon: Icon(
                        pending == 'confirme' ? Icons.cancel_outlined : Icons.check_circle_outline_rounded,
                        size: 16,
                      ),
                      label: Text(pending == 'confirme' ? "Absent" : "Présent"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ✕ Annuler la sélection locale
                    IconButton(
                      onPressed: () => _clearPending(id),
                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9CA3AF)),
                      tooltip: "Annuler",
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ✅ Confirmer → écriture DB
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    )),
                  ]),

                // ── ÉTAT C : confirmé en DB ──
                if (hasConfirmed && !hasPending) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _color(confirmed).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(
                        confirmed == 'confirme'
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: _color(confirmed), size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        confirmed == 'confirme'
                            ? "Présence confirmée"
                            : "Absence enregistrée",
                        style: TextStyle(
                          color: _color(confirmed),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  // ↩️ Bouton annuler → DB
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
  // WIDGETS HELPERS
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

  Widget _infoBox(String label, String value, IconData icon, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ),
  );

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
      child: Text(cfg.$2,
          style: TextStyle(color: cfg.$1, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  // ── Couleurs selon statut ──
  Color    _color(String s)       => s == 'confirme' ? const Color(0xFF059669) : s == 'absent' ? const Color(0xFFEF4444) : const Color(0xFF6B7280);
  Color    _bgColor(String s)     => s == 'confirme' ? const Color(0xFFF0FDF4) : s == 'absent' ? const Color(0xFFFFF1F2) : const Color(0xFFF9FAFB);
  Color    _borderColor(String s) => s == 'confirme' ? const Color(0xFFBBF7D0) : s == 'absent' ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB);
  IconData _icon(String s)        => s == 'confirme' ? Icons.check_circle_rounded : s == 'absent' ? Icons.cancel_rounded : Icons.help_outline_rounded;
}