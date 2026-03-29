import 'package:flutter/material.dart';
import '../../../models/resident_model.dart';
import '../../../models/paiement_model.dart';
import '../../../services/resident_service.dart';
import '../../../services/parking_service.dart';
import '../../../services/box_service.dart';
import '../../../services/garage_service.dart';
import '../../../models/parking_model.dart';
import '../../../models/box_model.dart';
import '../../../models/garage_model.dart';
import '../../../utils/temp_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/inter_syndic_header.dart';

// ignore_for_file: avoid_multiple_underscores_for_members

// ── Palette moderne — sans jaune
class _C {
  // Primaires
  static const coral      = Color(0xFFD86233);
  static const coralDark  = Color(0xFFEF7136);
  static const coralLight = Color(0xFFFDF1E6);
  static const coralMid   = Color(0xFFFADCC2);

  // Neutres
  static const bg         = Color(0xFFF5F6F8);
  static const bgCard     = Color(0xFFFFFFFF);
  static const dark       = Color(0xFF111827);
  static const darkMid    = Color(0xFF374151);
  static const textMid    = Color(0xFF6B7280);
  static const textLight  = Color(0xFF9CA3AF);
  static const divider    = Color(0xFFE5E7EB);
  static const surface    = Color(0xFFF9FAFB);

  // Accent bleu (remplace orange/blue confus)
  static const blue       = Color(0xFF3B82F6);
  static const blueLight  = Color(0xFFEFF6FF);
  static const blueMid    = Color(0xFFBFDBFE);

  // Vert succès
  static const green      = Color(0xFF10B981);
  static const greenLight = Color(0xFFECFDF5);
  static const greenMid   = Color(0xFFA7F3D0);

  // Rouge/coral impayé
  static const red        = Color(0xFFEF4444);
  static const redLight   = Color(0xFFFEF2F2);

  // Orange partiel
  static const orange     = Color(0xFFF97316);
  static const orangeLight= Color(0xFFFFF7ED);
}

class ResidentsScreen extends StatefulWidget {
  final int trancheId;
  const ResidentsScreen({super.key, required this.trancheId});

  @override
  State<ResidentsScreen> createState() => _ResidentsScreenState();
}

class _ResidentsScreenState extends State<ResidentsScreen>
    with SingleTickerProviderStateMixin {
  final _service = ResidentService();
  List<ResidentModel> _residents = [];
  List<ResidentModel> _filtered = [];
  bool _loading = true;
  String _filterStatut = 'tous';

  Map<String, dynamic>? _selectedMandat;
  List<Map<String, dynamic>> _mandatsDisponibles = [];
  bool _loadingMandats = true;

  final _searchCtrl = TextEditingController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  double? _prixAnnuel;
  bool _loadingPrix = true;

  int? get _currentMandatId => _selectedMandat?['id'] as int?;

  int get _fallbackAnnee {
    if (_selectedMandat == null || _selectedMandat!['date_debut'] == null) {
      return DateTime.now().year;
    }
    final d = _selectedMandat!['date_debut'].toString();
    if (d.length >= 4) return int.tryParse(d.substring(0, 4)) ?? DateTime.now().year;
    return DateTime.now().year;
  }

  List<Map<String, dynamic>> _appartementsLibres = [];
  List<Map<String, dynamic>> _appartementsLibresPaies = [];
  bool _loadingAppartementsLibres = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadPrixAnnuel();
    _loadMandats();
    _loadAppartementsLibres();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMandats() async {
    try {
      final db = Supabase.instance.client;
      final mandatsRes = await db
          .from('historique_affectations')
          .select('id, date_debut, date_fin')
          .eq('tranche_id', widget.trancheId)
          .eq('inter_syndic_id', TempSession.interSyndicId ?? 0)
          .order('date_debut', ascending: false);
      final List mandatsList = mandatsRes as List? ?? [];
      setState(() {
        _mandatsDisponibles = mandatsList.cast<Map<String, dynamic>>();
        _selectedMandat = _mandatsDisponibles.isNotEmpty ? _mandatsDisponibles.first : null;
        _loadingMandats = false;
      });
    } catch (e) {
      debugPrint('>>> ERREUR _loadMandats: $e');
      setState(() { _mandatsDisponibles = []; _selectedMandat = null; _loadingMandats = false; });
    }
    _load();
  }

  Future<void> _loadPrixAnnuel() async {
    try {
      final db = Supabase.instance.client;
      final res = await db.from('tranches').select('prix_annuel').eq('id', widget.trancheId).maybeSingle();
      if (mounted) {
        setState(() {
          _prixAnnuel = res != null ? double.tryParse((res['prix_annuel'] ?? 0).toString()) ?? 0.0 : 0.0;
          _loadingPrix = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingPrix = false);
    }
  }

  Future<void> _loadAppartementsLibres() async {
    try {
      final db = Supabase.instance.client;
      final immRes = await db.from('immeubles').select('id, nom').eq('tranche_id', widget.trancheId);
      final immIds = (immRes as List).map((i) => i['id']).toList();
      if (immIds.isEmpty) { if (mounted) setState(() => _loadingAppartementsLibres = false); return; }

      final appRes = await db.from('appartements').select('id, numero, immeuble_id, immeubles(nom)').inFilter('immeuble_id', immIds).eq('statut', 'libre');
      final List list = appRes as List? ?? [];
      if (list.isEmpty) {
        if (mounted) setState(() { _appartementsLibres = []; _appartementsLibresPaies = []; _loadingAppartementsLibres = false; });
        return;
      }

      final allIds = list.map((a) => a['id']).toList();
      var paiResQuery = db.from('paiements').select('appartement_id, montant_total, montant_paye, statut, date_paiement').inFilter('appartement_id', allIds).eq('type_paiement', 'charges');
      if (_currentMandatId != null) paiResQuery = paiResQuery.eq('mandat_id', _currentMandatId!);
      final paiRes = await paiResQuery;
      final List paiList = paiRes as List? ?? [];

      final Map<dynamic, Map<String, dynamic>> paiByAppart = {};
      for (final p in paiList) paiByAppart[p['appartement_id']] = Map<String, dynamic>.from(p);

      final List<Map<String, dynamic>> nonPaies = [];
      final List<Map<String, dynamic>> paies = [];

      for (final a in list) {
        final entry = { 'id': a['id'], 'numero': a['numero']?.toString() ?? '', 'immeuble': a['immeubles']?['nom']?.toString() ?? '', 'label': '${a['immeubles']?['nom'] ?? ''} - Appt. ${a['numero']}' };
        final paiement = paiByAppart[a['id']];
        if (paiement != null) {
          final double mt = double.tryParse(paiement['montant_total'].toString()) ?? 0;
          final double mp = double.tryParse(paiement['montant_paye'].toString()) ?? 0;
          paies.add({ ...entry, 'montant_total': mt, 'montant_paye': mp, 'reste': mt - mp, 'statut': paiement['statut']?.toString() ?? 'impaye', 'date_paiement': paiement['date_paiement']?.toString() ?? '' });
        } else { nonPaies.add(entry); }
      }

      if (mounted) setState(() { _appartementsLibres = nonPaies; _appartementsLibresPaies = paies; _loadingAppartementsLibres = false; });
    } catch (e) {
      debugPrint('>>> ERREUR _loadAppartementsLibres: $e');
      if (mounted) setState(() => _loadingAppartementsLibres = false);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getResidentsByTranche(widget.trancheId, mandatId: _currentMandatId).timeout(const Duration(seconds: 15));
      setState(() { _residents = data; _loading = false; });
      _applyFilter();
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      debugPrint('>>> ERREUR _load: $e');
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _residents.where((r) {
        final matchSearch = r.nomComplet.toLowerCase().contains(q) || (r.appartementNumero?.toLowerCase().contains(q) ?? false);
        final matchStatut = _filterStatut == 'tous' || r.statutPaiement == _filterStatut;
        return matchSearch && matchStatut;
      }).toList();
    });
  }

  void _setFilter(String f) { setState(() => _filterStatut = f); _applyFilter(); }

  int get _total => _residents.length;
  int get _complets => _residents.where((r) => r.statutPaiement == 'complet').length;
  int get _impayes => _residents.where((r) => r.statutPaiement == 'impaye').length;
  int get _partiels => _total - _complets - _impayes;

  Color _statutColor(String s) => s == 'complet' ? _C.green : s == 'partiel' ? _C.orange : _C.red;
  Color _statutBg(String s) => s == 'complet' ? _C.greenLight : s == 'partiel' ? _C.orangeLight : _C.redLight;
  String _statutLabel(String s) => s == 'complet' ? 'Complet' : s == 'partiel' ? 'Partiel' : 'Impayé';

  String _typeLabel(String type) { switch (type.toLowerCase()) { case 'garage': return 'Garage'; case 'parking': return 'Parking'; case 'box': return 'Box'; default: return 'Charges'; } }
  Color _typeColor(String type) { switch (type.toLowerCase()) { case 'garage': return _C.blue; case 'parking': return _C.orange; case 'box': return _C.coral; default: return _C.green; } }
  Color _typeBgColor(String type) { switch (type.toLowerCase()) { case 'garage': return _C.blueLight; case 'parking': return _C.orangeLight; case 'box': return _C.coralLight; default: return _C.greenLight; } }
  IconData _typeIcon(String type) { switch (type.toLowerCase()) { case 'garage': return Icons.garage_rounded; case 'parking': return Icons.local_parking_rounded; case 'box': return Icons.inventory_2_rounded; default: return Icons.payments_rounded; } }

  String _getMandatLabel(Map<String, dynamic>? mandat) {
    if (mandat == null) return 'N/A';
    final d = mandat['date_debut']?.toString().split('-').reversed.join('/') ?? '';
    final f = mandat['date_fin']?.toString().split('-').reversed.join('/') ?? '';
    return f.isEmpty ? 'Depuis $d' : '$d → $f';
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD PRINCIPAL
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? _buildLoader()
                  : FadeTransition(
                opacity: _fadeAnim,
                child: RefreshIndicator(
                  color: _C.coral,
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildTopSection()),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        sliver: SliverToBoxAdapter(child: _buildSearchAndFilter()),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: _filtered.isEmpty
                            ? SliverToBoxAdapter(child: _buildEmpty())
                            : SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _buildResidentCard(_filtered[i]),
                            childCount: _filtered.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HEADER — identique à l'original
  // ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return InterSyndicHeader(
      title: 'ResiManager',
      subtitle: 'inter_syndic',
      gridIcon: Icons.grid_view_rounded,
      onBack: () => Navigator.pop(context),
      onAdd: _showAddResidentDialog,
      addLabel: 'Ajouter',
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // SECTION HAUT — hero stats + mandat + prix + appts libres
  // ─────────────────────────────────────────────────────────────────

  Widget _buildTopSection() {
    return Column(
      children: [
        _buildHeroStats(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(children: [
            _buildInfoRow(),
            const SizedBox(height: 10),
            if (!_loadingAppartementsLibres && (_appartementsLibres.length + _appartementsLibresPaies.length) > 0)
              _buildAppartementsLibresBanner(),
            const SizedBox(height: 16),
          ]),
        ),
      ],
    );
  }

  // ── Hero stats compact — grande bande colorée
  Widget _buildHeroStats() {
    final pct = _total == 0 ? 0.0 : _complets / _total;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: _C.coral,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Haut : titre + mandat
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Résidents', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
                      const SizedBox(height: 2),
                      Text('$_total résidents · mandat actif', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                // Sélecteur mandat compact
                _loadingMandats
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : _mandatsDisponibles.isEmpty
                    ? Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: const Text('Aucun mandat', style: TextStyle(color: Colors.white, fontSize: 11)))
                    : GestureDetector(
                  onTap: _showMandatPickerMenu,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(14)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 12),
                      const SizedBox(width: 6),
                      Text(_getMandatLabel(_selectedMandat), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 14),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          // Barre de progression
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${(pct * 100).toInt()}% complets', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('$_complets / $_total', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          // 3 chips
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                _heroChip(Icons.check_circle_rounded, '$_complets', 'Complets', Colors.white),
                _dividerV(),
                _heroChip(Icons.timelapse_rounded, '$_partiels', 'Partiels', Colors.white.withValues(alpha: 0.85)),
                _dividerV(),
                _heroChip(Icons.cancel_rounded, '$_impayes', 'Impayés', Colors.white.withValues(alpha: 0.85)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String val, String label, Color c) {
    return Expanded(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: c, size: 14),
          const SizedBox(width: 5),
          Text(val, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: c.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _dividerV() => Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.25));

  // ── Ligne info : prix annuel
  Widget _buildInfoRow() {
    return Row(
      children: [
        // Prix annuel
        Expanded(
          child: _infoCard(
            icon: Icons.monetization_on_rounded,
            iconColor: _C.coral,
            iconBg: _C.coralLight,
            label: 'Prix annuel',
            value: _loadingPrix ? '...' : '${_prixAnnuel?.toInt() ?? 0} DH',
            onTap: _showEditPrixAnnuelDialog,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit_rounded, size: 11, color: _C.coral),
                SizedBox(width: 3),
                Text('Modifier', style: TextStyle(color: _C.coral, fontSize: 10, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard({required IconData icon, required Color iconColor, required Color iconBg, required String label, required String value, VoidCallback? onTap, Widget? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: _C.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.divider)),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: _C.textLight, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: _C.dark, fontWeight: FontWeight.w800, fontSize: 15)),
          ])),
          if (trailing != null) trailing,
        ]),
      ),
    );
  }

  // ── Banner appartements libres — compact
  Widget _buildAppartementsLibresBanner() {
    final countLibres = _appartementsLibres.length;
    final countPaies = _appartementsLibresPaies.length;
    final total = countLibres + countPaies;

    return GestureDetector(
      onTap: _showAppartementsLibresPaiementDialog,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.green.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.home_work_rounded, color: _C.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Appartements libres', style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 4),
            Row(children: [
              _miniChip('$countPaies payés', _C.green, _C.greenLight),
              const SizedBox(width: 6),
              _miniChip('$countLibres non payés', _C.red, _C.redLight),
            ]),
          ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: countLibres > 0 ? _C.green : _C.surface, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.payments_rounded, size: 13, color: countLibres > 0 ? Colors.white : _C.textLight),
              const SizedBox(width: 5),
              Text('Payer', style: TextStyle(color: countLibres > 0 ? Colors.white : _C.textLight, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _miniChip(String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  // ─────────────────────────────────────────────────────────────────
  // SEARCH + FILTER
  // ─────────────────────────────────────────────────────────────────

  Widget _buildSearchAndFilter() {
    return Column(children: [
      // Search
      Container(
        decoration: BoxDecoration(color: _C.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.divider)),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(fontSize: 14, color: _C.dark),
          decoration: InputDecoration(
            hintText: 'Rechercher un résident...',
            hintStyle: const TextStyle(color: _C.textLight, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: _C.textLight, size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? GestureDetector(onTap: () { _searchCtrl.clear(); _applyFilter(); }, child: const Icon(Icons.close_rounded, color: _C.textLight, size: 18))
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
      const SizedBox(height: 10),
      // Filter tabs
      Row(children: [
        _filterTab('tous', 'Tous', _total),
        const SizedBox(width: 6),
        _filterTab('complet', 'Complets', _complets),
        const SizedBox(width: 6),
        _filterTab('partiel', 'Partiels', _partiels),
        const SizedBox(width: 6),
        _filterTab('impaye', 'Impayés', _impayes),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Text('${_filtered.length} résultats', style: const TextStyle(color: _C.textMid, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 10),
    ]);
  }

  Widget _filterTab(String key, String label, int count) {
    final isSelected = _filterStatut == key;
    Color accent = _C.coral;
    if (key == 'complet') accent = _C.green;
    if (key == 'partiel') accent = _C.orange;
    if (key == 'impaye') accent = _C.red;

    return Expanded(
      child: GestureDetector(
        onTap: () => _setFilter(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? accent : _C.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? accent : _C.divider),
          ),
          child: Column(children: [
            Text('$count', style: TextStyle(color: isSelected ? Colors.white : _C.dark, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 1),
            Text(label, style: TextStyle(color: isSelected ? Colors.white.withValues(alpha: 0.85) : _C.textLight, fontSize: 9, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // CARD RÉSIDENT — compacte et moderne
  // ─────────────────────────────────────────────────────────────────

  Widget _buildResidentCard(ResidentModel r) {
    final pct = r.pourcentagePaiement;
    final statut = r.statutPaiement;
    final Color sColor = _statutColor(statut);
    final Color sBg = _statutBg(statut);
    final bool isProp = r.type == 'proprietaire';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        children: [
          // Ligne principale
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: isProp ? _C.blueLight : _C.coralLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      r.nomComplet.isNotEmpty ? r.nomComplet[0].toUpperCase() : '?',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: isProp ? _C.blue : _C.coral),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                // Nom + adresse
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.nomComplet, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _C.dark, letterSpacing: -0.2), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 10, color: _C.textLight),
                      const SizedBox(width: 2),
                      Expanded(child: Text(r.adresseAppart, style: const TextStyle(color: _C.textLight, fontSize: 11), overflow: TextOverflow.ellipsis)),
                    ]),
                  ]),
                ),
                const SizedBox(width: 8),
                // Badge statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: sBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 5, height: 5, decoration: BoxDecoration(color: sColor, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(_statutLabel(statut), style: TextStyle(color: sColor, fontSize: 10, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ],
            ),
          ),
          // Barre de paiement + montants
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(children: [
              // Progress
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  backgroundColor: _C.divider,
                  valueColor: AlwaysStoppedAnimation(sColor),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                _amountPill('Payé', '${r.montantPaye.toInt()} DH', _C.green, _C.greenLight),
                const SizedBox(width: 6),
                _amountPill('Reste', '${r.resteAPayer.toInt()} DH', _C.red, _C.redLight),
                const SizedBox(width: 6),
                _amountPill('Total', '${r.montantTotal.toInt()} DH', _C.textMid, _C.surface),
                const Spacer(),
                Text('${(pct * 100).toInt()}%', style: TextStyle(color: sColor, fontWeight: FontWeight.w800, fontSize: 13)),
              ]),
            ]),
          ),
          // Actions
          Container(
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              border: Border(top: BorderSide(color: _C.divider)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(children: [
              _actionBtn('Payer', Icons.payments_rounded, _C.coral, onTap: () => _showPaiementDialog(r)),
              const SizedBox(width: 6),
              _iconActionBtn(Icons.history_rounded, _C.blue, _C.blueLight, () => _showHistoriqueDialog(r)),
              const SizedBox(width: 6),
              _iconActionBtn(Icons.edit_rounded, _C.textMid, _C.surface, () => _showEditDialog(r)),
              const SizedBox(width: 6),
              _iconActionBtn(Icons.delete_rounded, _C.red, _C.redLight, () => _showDeleteConfirm(r)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _amountPill(String label, String val, Color c, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: _C.textLight, fontSize: 9, fontWeight: FontWeight.w500)),
        Text(val, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 11)),
      ]),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, {required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _iconActionBtn(IconData icon, Color fg, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.divider)),
        child: Icon(icon, color: fg, size: 16),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // LOADER + EMPTY
  // ─────────────────────────────────────────────────────────────────

  Widget _buildLoader() => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(color: _C.coral, strokeWidth: 2.5),
      SizedBox(height: 14),
      Text('Chargement...', style: TextStyle(color: _C.textLight, fontSize: 13)),
    ]),
  );

  Widget _buildEmpty() => Padding(
    padding: const EdgeInsets.only(top: 50),
    child: Column(children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.people_rounded, color: _C.coral, size: 28),
      ),
      const SizedBox(height: 12),
      const Text('Aucun résident', style: TextStyle(color: _C.dark, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      const Text('Modifiez les filtres ou ajoutez un résident.', style: TextStyle(color: _C.textLight, fontSize: 12)),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────
  // MENU MANDAT
  // ─────────────────────────────────────────────────────────────────

  void _showMandatPickerMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    showMenu<Map<String, dynamic>>(
      context: context,
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 12,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(button.localToGlobal(Offset.zero, ancestor: overlay).dx + button.size.width - 220, button.localToGlobal(Offset.zero, ancestor: overlay).dy + 170, 220, 0),
        Offset.zero & overlay.size,
      ),
      items: _mandatsDisponibles.map((mandat) => PopupMenuItem<Map<String, dynamic>>(
        value: mandat,
        height: 48,
        child: Text(_getMandatLabel(mandat), style: TextStyle(color: mandat['id'] == _selectedMandat?['id'] ? _C.coral : Colors.white, fontWeight: mandat['id'] == _selectedMandat?['id'] ? FontWeight.w800 : FontWeight.w500, fontSize: 13)),
      )).toList(),
    ).then((mandat) {
      if (mandat != null && mandat['id'] != _selectedMandat?['id']) {
        setState(() => _selectedMandat = mandat);
        _load();
        _loadAppartementsLibres();
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOGS — Design unifié moderne
  // ═══════════════════════════════════════════════════════════════

  // ── Helpers dialog
  Widget _dHeader(BuildContext ctx, String title, {IconData? icon, Color? iconColor}) {
    return Row(children: [
      if (icon != null) ...[
        Container(width: 34, height: 34, decoration: BoxDecoration(color: (iconColor ?? _C.coral).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: iconColor ?? _C.coral, size: 17)),
        const SizedBox(width: 10),
      ],
      Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _C.dark))),
      GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Container(width: 28, height: 28, decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _C.divider)), child: const Icon(Icons.close_rounded, size: 14, color: _C.textMid)),
      ),
    ]);
  }

  Widget _dActions({required BuildContext ctx, required bool saving, required String label, required Color color, required VoidCallback onConfirm}) {
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: saving ? null : () => Navigator.pop(ctx),
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)), child: const Text('Annuler', textAlign: TextAlign.center, style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 13))),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: GestureDetector(
          onTap: saving ? null : onConfirm,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: saving ? color.withValues(alpha: 0.5) : color, borderRadius: BorderRadius.circular(12)),
            child: saving
                ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                : Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ),
    ]);
  }

  Widget _dError(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(color: _C.redLight, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [const Icon(Icons.error_outline_rounded, color: _C.red, size: 15), const SizedBox(width: 8), Expanded(child: Text(msg, style: const TextStyle(color: _C.red, fontSize: 12)))]),
  );

  Widget _dLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _C.textMid)));

  Widget _dField(TextEditingController ctrl, String hint, {TextInputType inputType = TextInputType.text}) => TextField(
    controller: ctrl, keyboardType: inputType,
    style: const TextStyle(fontSize: 14, color: _C.dark),
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: _C.textLight, fontSize: 13),
      filled: true, fillColor: _C.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.coral, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );

  Widget _dDropdown({required Widget child}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.divider)),
    child: child,
  );

  Widget _dToggle(String label, bool selected, Color accent) => Container(
    padding: const EdgeInsets.symmetric(vertical: 11),
    decoration: BoxDecoration(color: selected ? accent.withValues(alpha: 0.08) : _C.surface, border: Border.all(color: selected ? accent : _C.divider, width: selected ? 1.5 : 1), borderRadius: BorderRadius.circular(10)),
    child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? accent : _C.textMid, fontWeight: FontWeight.w700, fontSize: 13)),
  );

  Widget _dEmpty(String msg) => Container(padding: const EdgeInsets.all(13), width: double.infinity, decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(10)), child: Text(msg, style: const TextStyle(color: _C.textLight, fontSize: 13)));

  // ── DIALOG MODIFIER PRIX ANNUEL
  void _showEditPrixAnnuelDialog() {
    final prixCtrl = TextEditingController(text: _prixAnnuel != null ? _prixAnnuel!.toInt().toString() : '');
    bool saving = false;
    String? errorMsg;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _dHeader(ctx, 'Prix annuel', icon: Icons.monetization_on_rounded, iconColor: _C.coral),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(10)), child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: _C.coral, size: 15),
            const SizedBox(width: 8),
            Text('Prix actuel : ${_prixAnnuel?.toInt() ?? 0} DH / an', style: const TextStyle(color: _C.coral, fontSize: 12, fontWeight: FontWeight.w600)),
          ])),
          const SizedBox(height: 14),
          if (errorMsg != null) _dError(errorMsg!),
          _dLabel('Nouveau prix (DH) *'),
          _dField(prixCtrl, 'ex: 3000', inputType: TextInputType.number),
          const SizedBox(height: 20),
          _dActions(ctx: ctx, saving: saving, label: 'Enregistrer', color: _C.coral, onConfirm: () async {
            final val = double.tryParse(prixCtrl.text.trim());
            if (val == null || val <= 0) { setDialog(() => errorMsg = 'Entrez un prix valide'); return; }
            setDialog(() { saving = true; errorMsg = null; });
            try {
              await Supabase.instance.client.from('tranches').update({'prix_annuel': val}).eq('id', widget.trancheId);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              setState(() => _prixAnnuel = val);
            } catch (e) { setDialog(() { errorMsg = e.toString(); saving = false; }); }
          }),
        ])),
      )),
    );
  }

  // ── DIALOG AJOUTER RÉSIDENT
  void _showAddResidentDialog() {
    final prenomCtrl = TextEditingController();
    final nomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String type = 'proprietaire';
    String? errorMsg;
    bool saving = false;
    bool obscurePassword = true;
    List<Map<String, dynamic>> appartementsLibres = [];
    int? selectedAppartId;
    int? selectedParkingId;
    int? selectedBoxId;
    int? selectedGarageId;
    bool loadingApparts = true, loadingParkings = true, loadingBoxes = true, loadingGarages = true;
    List<ParkingModel> parkingsLibres = [];
    List<BoxModel> boxesLibres = [];
    List<GarageModel> garagesLibres = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
        if (loadingApparts) { loadingApparts = false; _service.getAppartementsLibres(widget.trancheId).then((list) { if (ctx.mounted) setDialog(() => appartementsLibres = list); }); }
        if (loadingParkings) { loadingParkings = false; ParkingService().getParkingsByTranche(widget.trancheId).then((list) { if (ctx.mounted) setDialog(() => parkingsLibres = list.where((p) => p.statut.name == 'disponible').toList()); }); }
        if (loadingBoxes) { loadingBoxes = false; BoxService().getBoxesByTranche(widget.trancheId).then((list) { if (ctx.mounted) setDialog(() => boxesLibres = list.where((b) => b.statut.name == 'disponible').toList()); }); }
        if (loadingGarages) { loadingGarages = false; GarageService().getGaragesByTranche(widget.trancheId).then((list) { if (ctx.mounted) setDialog(() => garagesLibres = list.where((g) => g.statut == 'disponible').toList()); }); }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(padding: const EdgeInsets.all(22), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _dHeader(ctx, 'Ajouter un résident', icon: Icons.person_add_rounded, iconColor: _C.coral),
            const SizedBox(height: 14),
            // Mandat + prix infos
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)), child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Mandat actif', style: TextStyle(color: _C.textLight, fontSize: 10, fontWeight: FontWeight.w500)),
                Text(_getMandatLabel(_selectedMandat), style: const TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 12)),
              ])),
              Container(width: 1, height: 28, color: _C.divider),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Prix annuel', style: TextStyle(color: _C.textLight, fontSize: 10, fontWeight: FontWeight.w500)),
                Text('${_prixAnnuel?.toInt() ?? 0} DH', style: const TextStyle(color: _C.coral, fontWeight: FontWeight.w700, fontSize: 12)),
              ])),
            ])),
            const SizedBox(height: 14),
            if (errorMsg != null) _dError(errorMsg!),
            _dLabel('Prénom *'), _dField(prenomCtrl, 'ex: Ahmed'), const SizedBox(height: 12),
            _dLabel('Nom *'), _dField(nomCtrl, 'ex: Bennani'), const SizedBox(height: 12),
            _dLabel('Email *'), _dField(emailCtrl, 'ex: ahmed@example.com', inputType: TextInputType.emailAddress), const SizedBox(height: 12),
            _dLabel('Mot de passe *'),
            StatefulBuilder(builder: (_, setLocal) => TextField(
              controller: passwordCtrl, obscureText: obscurePassword,
              style: const TextStyle(fontSize: 14, color: _C.dark),
              decoration: InputDecoration(
                hintText: 'Min. 8 caractères', hintStyle: const TextStyle(color: _C.textLight, fontSize: 13),
                filled: true, fillColor: _C.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.coral, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: GestureDetector(onTap: () => setDialog(() => obscurePassword = !obscurePassword), child: Icon(obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: _C.textLight, size: 18)),
              ),
            )),
            const SizedBox(height: 12),
            _dLabel('Téléphone'), _dField(telCtrl, 'ex: 0612345678', inputType: TextInputType.phone), const SizedBox(height: 12),
            _dLabel('Appartement *'),
            appartementsLibres.isEmpty ? _dEmpty('Aucun appartement libre') : _dDropdown(child: DropdownButtonHideUnderline(child: DropdownButton<int>(isExpanded: true, hint: const Text('Sélectionner', style: TextStyle(color: _C.textLight, fontSize: 13)), value: selectedAppartId, items: appartementsLibres.map((a) => DropdownMenuItem<int>(value: a['id'] as int, child: Text(a['label'].toString()))).toList(), onChanged: (val) => setDialog(() => selectedAppartId = val)))),
            const SizedBox(height: 12),
            _dLabel('Parking (optionnel)'),
            parkingsLibres.isEmpty ? _dEmpty('Aucun parking disponible') : _dDropdown(child: DropdownButtonHideUnderline(child: DropdownButton<int?>(isExpanded: true, hint: const Text('Aucun', style: TextStyle(color: _C.textLight, fontSize: 13)), value: selectedParkingId, items: [const DropdownMenuItem<int?>(value: null, child: Text('Aucun', style: TextStyle(fontStyle: FontStyle.italic, color: _C.textLight))), ...parkingsLibres.map((p) => DropdownMenuItem<int?>(value: p.id, child: Text('Parking ${p.numero}')))], onChanged: (val) => setDialog(() => selectedParkingId = val)))),
            const SizedBox(height: 12),
            _dLabel('Box (optionnel)'),
            boxesLibres.isEmpty ? _dEmpty('Aucun box disponible') : _dDropdown(child: DropdownButtonHideUnderline(child: DropdownButton<int?>(isExpanded: true, hint: const Text('Aucun', style: TextStyle(color: _C.textLight, fontSize: 13)), value: selectedBoxId, items: [const DropdownMenuItem<int?>(value: null, child: Text('Aucun', style: TextStyle(fontStyle: FontStyle.italic, color: _C.textLight))), ...boxesLibres.map((b) => DropdownMenuItem<int?>(value: b.id, child: Text('Box ${b.numero}')))], onChanged: (val) => setDialog(() => selectedBoxId = val)))),
            const SizedBox(height: 12),
            _dLabel('Garage (optionnel)'),
            garagesLibres.isEmpty ? _dEmpty('Aucun garage disponible') : _dDropdown(child: DropdownButtonHideUnderline(child: DropdownButton<int?>(isExpanded: true, hint: const Text('Aucun', style: TextStyle(color: _C.textLight, fontSize: 13)), value: selectedGarageId, items: [const DropdownMenuItem<int?>(value: null, child: Text('Aucun', style: TextStyle(fontStyle: FontStyle.italic, color: _C.textLight))), ...garagesLibres.map((g) => DropdownMenuItem<int?>(value: g.id, child: Text('Garage ${g.numero}')))], onChanged: (val) => setDialog(() => selectedGarageId = val)))),
            const SizedBox(height: 12),
            _dLabel('Type *'),
            Row(children: [
              Expanded(child: GestureDetector(onTap: () => setDialog(() => type = 'proprietaire'), child: _dToggle('Propriétaire', type == 'proprietaire', _C.blue))),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(onTap: () => setDialog(() => type = 'locataire'), child: _dToggle('Locataire', type == 'locataire', _C.coral))),
            ]),
            const SizedBox(height: 20),
            _dActions(ctx: ctx, saving: saving, label: 'Ajouter', color: _C.coral, onConfirm: () async {
              if (prenomCtrl.text.trim().isEmpty || nomCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) { setDialog(() => errorMsg = 'Prénom, Nom et Email obligatoires'); return; }
              if (passwordCtrl.text.trim().length < 8) { setDialog(() => errorMsg = 'Mot de passe : 8 caractères minimum'); return; }
              if (selectedAppartId == null) { setDialog(() => errorMsg = 'Sélectionnez un appartement'); return; }
              if (_currentMandatId == null) { setDialog(() => errorMsg = 'Aucun mandat actif sélectionné'); return; }
              setDialog(() { saving = true; errorMsg = null; });
              final err = await _service.addResident(nom: nomCtrl.text, prenom: prenomCtrl.text, email: emailCtrl.text, telephone: telCtrl.text.isEmpty ? null : telCtrl.text, password: passwordCtrl.text.trim(), type: type, trancheId: widget.trancheId, appartementId: selectedAppartId!, montantTotal: _prixAnnuel ?? 0.0, mandatId: _currentMandatId!, parkingId: selectedParkingId, boxId: selectedBoxId, garageId: selectedGarageId);
              if (!ctx.mounted) return;
              if (err != null) { setDialog(() { errorMsg = err; saving = false; }); } else { Navigator.pop(ctx); _load(); }
            }),
          ]))),
        );
      }),
    );
  }

  // ── DIALOG PAIEMENT
  void _showPaiementDialog(ResidentModel r) {
    final montantCtrl = TextEditingController();
    PaiementModel? selectedPaiement = r.paiements.isNotEmpty ? r.paiements.first : null;
    String? errorMsg;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _dHeader(ctx, 'Enregistrer un paiement', icon: Icons.payments_rounded, iconColor: _C.coral),
          const SizedBox(height: 14),
          // Résident info
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)), child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(r.nomComplet.isNotEmpty ? r.nomComplet[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _C.coral)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.nomComplet, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.dark)),
              Text(r.adresseAppart, style: const TextStyle(color: _C.textLight, fontSize: 11)),
            ])),
          ])),
          const SizedBox(height: 14),
          _dLabel('Ligne de paiement *'),
          _dDropdown(child: DropdownButtonHideUnderline(child: DropdownButton<PaiementModel>(value: selectedPaiement, isExpanded: true, onChanged: (val) => setDialog(() => selectedPaiement = val), items: r.paiements.map((p) => DropdownMenuItem(value: p, child: Text(_paiementLabel(p), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))).toList()))),
          if (selectedPaiement != null) ...[
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _statPill('Total', '${selectedPaiement!.montantTotal.toInt()} DH', _C.textMid, _C.surface),
              _statPill('Payé', '${selectedPaiement!.montantPaye.toInt()} DH', _C.green, _C.greenLight),
              _statPill('Reste', '${selectedPaiement!.resteAPayer.toInt()} DH', _C.red, _C.redLight),
            ])),
          ],
          const SizedBox(height: 12),
          if (errorMsg != null) _dError(errorMsg!),
          _dLabel('Montant à payer (DH) *'),
          _dField(montantCtrl, 'ex: 1500', inputType: TextInputType.number),
          const SizedBox(height: 20),
          _dActions(ctx: ctx, saving: saving, label: 'Enregistrer', color: _C.coral, onConfirm: () async {
            final montant = double.tryParse(montantCtrl.text.trim()) ?? 0;
            if (montant <= 0) { setDialog(() => errorMsg = 'Entrez un montant valide'); return; }
            if (selectedPaiement == null) { setDialog(() => errorMsg = 'Sélectionnez une ligne de paiement'); return; }
            setDialog(() { saving = true; errorMsg = null; });
            final err = await _service.enregistrerPaiement(paiementId: selectedPaiement!.id, residentUserId: r.userId, montantAjoute: montant, montantDejaPane: selectedPaiement!.montantPaye, montantTotal: selectedPaiement!.montantTotal);
            if (!ctx.mounted) return;
            if (err != null) { setDialog(() { errorMsg = err; saving = false; }); } else { Navigator.pop(ctx); _load(); }
          }),
        ])),
      )),
    );
  }

  Widget _statPill(String label, String val, Color c, Color bg) => Column(children: [
    Text(label, style: const TextStyle(color: _C.textLight, fontSize: 10, fontWeight: FontWeight.w500)),
    const SizedBox(height: 2),
    Text(val, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 13)),
  ]);

  // ── DIALOG HISTORIQUE
  void _showHistoriqueDialog(ResidentModel r) {
    List<Map<String, dynamic>> historique = [];
    bool fetchDone = false;
    bool fetchLaunched = false;
    int? selectedAnnee;
    final String mandatLabel = _getMandatLabel(_selectedMandat);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
        if (!fetchLaunched) {
          fetchLaunched = true;
          _service.getHistoriquePaiements(r.userId, mandatId: _currentMandatId).then((data) {
            if (ctx.mounted) {
              setDialog(() {
                historique = data;
                fetchDone = true;
                final anneesDispo = data.map((h) => h['annee_paiement'] as int?).whereType<int>().toSet().toList()..sort((a, b) => b.compareTo(a));
                selectedAnnee = anneesDispo.isNotEmpty ? anneesDispo.first : null;
              });
            }
          });
        }

        final anneesSet = historique.map((h) => h['annee_paiement'] as int?).whereType<int>().toSet().toList()..sort((a, b) => b.compareTo(a));
        final filtered = selectedAnnee == null ? historique : historique.where((h) => h['annee_paiement'] == selectedAnnee).toList();
        final totalAnnee = filtered.fold<double>(0, (sum, h) => sum + (double.tryParse(h['montant'].toString()) ?? 0));
        final pct = r.pourcentagePaiement;
        final sColor = _statutColor(r.statutPaiement);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _dHeader(ctx, 'Historique', icon: Icons.history_rounded, iconColor: _C.blue),
            const SizedBox(height: 12),
            // Mandat badge
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: _C.blueLight, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.calendar_today_rounded, color: _C.blue, size: 12), const SizedBox(width: 6), Text(mandatLabel, style: const TextStyle(color: _C.blue, fontWeight: FontWeight.w700, fontSize: 11))])),
            const SizedBox(height: 12),
            // Récap résident
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12)), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(r.nomComplet, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.dark)),
                Text('${(pct * 100).toInt()}% payé', style: TextStyle(color: sColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct.clamp(0.0, 1.0), backgroundColor: _C.divider, valueColor: AlwaysStoppedAnimation(sColor), minHeight: 5)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Payé : ${r.montantPaye.toInt()} DH', style: const TextStyle(color: _C.green, fontSize: 11, fontWeight: FontWeight.w600)),
                Text('Reste : ${r.resteAPayer.toInt()} DH', style: const TextStyle(color: _C.red, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ])),
            const SizedBox(height: 12),
            // Tabs années
            if (fetchDone && anneesSet.isNotEmpty) ...[
              SizedBox(height: 32, child: ListView(scrollDirection: Axis.horizontal, children: [
                GestureDetector(onTap: () => setDialog(() => selectedAnnee = null), child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: selectedAnnee == null ? _C.blue : _C.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: selectedAnnee == null ? _C.blue : _C.divider)), child: Text('Toutes', style: TextStyle(color: selectedAnnee == null ? Colors.white : _C.textMid, fontWeight: FontWeight.w600, fontSize: 11)))),
                ...anneesSet.map((annee) => GestureDetector(onTap: () => setDialog(() => selectedAnnee = annee), child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: selectedAnnee == annee ? _C.blue : _C.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: selectedAnnee == annee ? _C.blue : _C.divider)), child: Text('$annee', style: TextStyle(color: selectedAnnee == annee ? Colors.white : _C.textMid, fontWeight: FontWeight.w600, fontSize: 11))))),
              ])),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.payments_rounded, size: 13, color: _C.green), const SizedBox(width: 8), Text(selectedAnnee != null ? 'Total $selectedAnnee' : 'Total mandat', style: const TextStyle(color: _C.green, fontSize: 12, fontWeight: FontWeight.w600)), const Spacer(), Text('${totalAnnee.toInt()} DH', style: const TextStyle(color: _C.green, fontSize: 14, fontWeight: FontWeight.w800))])),
              const SizedBox(height: 10),
            ],
            Container(height: 1, color: _C.divider),
            const SizedBox(height: 8),
            !fetchDone
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _C.blue)))
                : filtered.isEmpty
                ? Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Column(children: [Icon(Icons.receipt_long_outlined, color: _C.divider, size: 38), const SizedBox(height: 8), Text(selectedAnnee != null ? 'Aucun paiement en $selectedAnnee' : 'Aucun paiement pour ce mandat', style: const TextStyle(color: _C.textLight, fontSize: 12))])))
                : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Container(height: 1, color: _C.divider),
                itemBuilder: (_, i) {
                  final h = filtered[i];
                  final montant = double.parse(h['montant'].toString()).toInt();
                  final dateStr = h['date']?.toString() ?? '';
                  final typePaiement = h['type_paiement']?.toString() ?? 'charges';
                  final anneeH = h['annee_paiement']?.toString() ?? '';
                  String dateF = dateStr;
                  try { final d = DateTime.parse(dateStr); dateF = '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}'; } catch (_) {}
                  return Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(children: [
                    Container(width: 34, height: 34, decoration: BoxDecoration(color: _typeBgColor(typePaiement), borderRadius: BorderRadius.circular(9)), child: Icon(_typeIcon(typePaiement), color: _typeColor(typePaiement), size: 15)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${_typeLabel(typePaiement)}${anneeH.isNotEmpty ? ' · $anneeH' : ''}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _typeColor(typePaiement))),
                      Text(dateF, style: const TextStyle(color: _C.textLight, fontSize: 10)),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: _typeBgColor(typePaiement), borderRadius: BorderRadius.circular(20)), child: Text('+$montant DH', style: TextStyle(color: _typeColor(typePaiement), fontWeight: FontWeight.w800, fontSize: 12))),
                  ]));
                },
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)), child: const Text('Fermer', textAlign: TextAlign.center, style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 13)))),
          ])),
        );
      }),
    );
  }

  // ── DIALOG MODIFIER RÉSIDENT
  void _showEditDialog(ResidentModel r) {
    final nomCtrl = TextEditingController(text: r.nom);
    final prenomCtrl = TextEditingController(text: r.prenom);
    final telCtrl = TextEditingController(text: r.telephone ?? '');
    final chargesPaiement = r.paiements.firstWhere((p) => p.typePaiement == TypePaiementEnum.charges, orElse: () => r.paiements.isNotEmpty ? r.paiements.first : PaiementModel(id: 0, residentId: 0, appartementId: 0, depenseId: 0, interSyndicId: 0, residenceId: 0, montantTotal: r.montantTotal, montantPaye: 0, typePaiement: TypePaiementEnum.charges, statut: StatutPaiementEnum.impaye, annee: _fallbackAnnee));
    final prixCtrl = TextEditingController(text: chargesPaiement.montantTotal.toInt().toString());
    String type = r.type;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(padding: const EdgeInsets.all(22), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _dHeader(ctx, 'Modifier résident', icon: Icons.edit_rounded, iconColor: _C.blue),
          const SizedBox(height: 16),
          _dLabel('Prénom'), _dField(prenomCtrl, ''), const SizedBox(height: 12),
          _dLabel('Nom'), _dField(nomCtrl, ''), const SizedBox(height: 12),
          _dLabel('Téléphone'), _dField(telCtrl, '', inputType: TextInputType.phone), const SizedBox(height: 12),
          _dLabel('Prix charges annuelles (DH)'), _dField(prixCtrl, 'ex: 3000', inputType: TextInputType.number), const SizedBox(height: 12),
          _dLabel('Type'),
          Row(children: [
            Expanded(child: GestureDetector(onTap: () => setDialog(() => type = 'proprietaire'), child: _dToggle('Propriétaire', type == 'proprietaire', _C.blue))),
            const SizedBox(width: 8),
            Expanded(child: GestureDetector(onTap: () => setDialog(() => type = 'locataire'), child: _dToggle('Locataire', type == 'locataire', _C.coral))),
          ]),
          const SizedBox(height: 20),
          _dActions(ctx: ctx, saving: saving, label: 'Enregistrer', color: _C.blue, onConfirm: () async {
            setDialog(() => saving = true);
            await _service.updateResident(userId: r.userId, nom: nomCtrl.text, prenom: prenomCtrl.text, telephone: telCtrl.text.isEmpty ? null : telCtrl.text, type: type, montantTotal: double.tryParse(prixCtrl.text.trim()), annee: _fallbackAnnee, mandatId: _currentMandatId);
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            _load();
          }),
        ]))),
      )),
    );
  }

  // ── DIALOG SUPPRIMER
  void _showDeleteConfirm(ResidentModel r) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: _C.redLight, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.person_remove_rounded, color: _C.red, size: 24)),
          const SizedBox(height: 14),
          const Text('Confirmer la suppression', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _C.dark)),
          const SizedBox(height: 6),
          Text('Supprimer ${r.nomComplet} ?', textAlign: TextAlign.center, style: const TextStyle(color: _C.textMid, fontSize: 13)),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)), child: const Text('Annuler', textAlign: TextAlign.center, style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 13))))),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(onTap: () async { await _service.deleteResident(r.userId, r.appartementId); if (!ctx.mounted) return; Navigator.pop(ctx); _load(); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: _C.red, borderRadius: BorderRadius.circular(12)), child: const Text('Supprimer', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))))),
          ]),
        ])),
      ),
    );
  }

  // ── DIALOG APPARTEMENTS LIBRES
  void _showAppartementsLibresPaiementDialog() {
    int activeTab = _appartementsLibres.isEmpty ? 1 : 0;
    Map<String, dynamic>? selectedAppart = _appartementsLibres.isNotEmpty ? _appartementsLibres.first : null;
    final montantCtrl = TextEditingController(text: (_prixAnnuel?.toInt() ?? 0).toString());
    String? errorMsg;
    bool saving = false;
    bool paymentDone = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(padding: const EdgeInsets.all(22), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _dHeader(ctx, 'Appartements libres', icon: Icons.home_work_rounded, iconColor: _C.green),
          const SizedBox(height: 14),
          // Tabs
          Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12)), child: Row(children: [
            Expanded(child: GestureDetector(onTap: () => setDialog(() { activeTab = 0; paymentDone = false; }), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 9), decoration: BoxDecoration(color: activeTab == 0 ? _C.bgCard : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: activeTab == 0 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)] : []), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.payments_rounded, size: 12, color: activeTab == 0 ? _C.green : _C.textLight), const SizedBox(width: 5), Text('Payer (${_appartementsLibres.length})', style: TextStyle(color: activeTab == 0 ? _C.green : _C.textLight, fontWeight: FontWeight.w700, fontSize: 12))])))),
            Expanded(child: GestureDetector(onTap: () => setDialog(() => activeTab = 1), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 9), decoration: BoxDecoration(color: activeTab == 1 ? _C.bgCard : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: activeTab == 1 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)] : []), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_rounded, size: 12, color: activeTab == 1 ? _C.blue : _C.textLight), const SizedBox(width: 5), Text('Historique (${_appartementsLibresPaies.length})', style: TextStyle(color: activeTab == 1 ? _C.blue : _C.textLight, fontWeight: FontWeight.w700, fontSize: 12))])))),
          ])),
          const SizedBox(height: 16),
          // TAB 0
          if (activeTab == 0) ...[
            if (_appartementsLibres.isEmpty) ...[
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(12)), child: Column(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.check_rounded, color: Colors.white, size: 22)), const SizedBox(height: 10), const Text('Tous les appartements sont payés !', style: TextStyle(color: _C.green, fontWeight: FontWeight.w700, fontSize: 13), textAlign: TextAlign.center)])),
            ] else if (paymentDone) ...[
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(12)), child: Column(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.check_rounded, color: Colors.white, size: 22)), const SizedBox(height: 10), const Text('Paiement enregistré !', style: TextStyle(color: _C.green, fontWeight: FontWeight.w700, fontSize: 13))])),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: GestureDetector(onTap: () => setDialog(() { paymentDone = false; selectedAppart = _appartementsLibres.isNotEmpty ? _appartementsLibres.first : null; }), child: Container(padding: const EdgeInsets.symmetric(vertical: 11), decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.green.withValues(alpha: 0.3))), child: const Text('Payer un autre', textAlign: TextAlign.center, style: TextStyle(color: _C.green, fontWeight: FontWeight.w700, fontSize: 12))))),
                const SizedBox(width: 8),
                Expanded(child: GestureDetector(onTap: () { Navigator.pop(ctx); _load(); _loadAppartementsLibres(); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 11), decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(10)), child: const Text('Fermer', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))))),
              ]),
            ] else ...[
              _dLabel('Appartement *'),
              _appartementsLibres.length == 1
                  ? Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.divider)), child: Row(children: [const Icon(Icons.home_rounded, color: _C.green, size: 15), const SizedBox(width: 8), Text(_appartementsLibres.first['label'].toString(), style: const TextStyle(color: _C.dark, fontSize: 13, fontWeight: FontWeight.w600))]))
                  : _dDropdown(child: DropdownButtonHideUnderline(child: DropdownButton<Map<String, dynamic>>(isExpanded: true, value: selectedAppart, items: _appartementsLibres.map((a) => DropdownMenuItem(value: a, child: Text(a['label'].toString(), style: const TextStyle(fontSize: 13)))).toList(), onChanged: (val) => setDialog(() => selectedAppart = val)))),
              const SizedBox(height: 12),
              _dLabel('Montant (DH) *'),
              _dField(montantCtrl, '${_prixAnnuel?.toInt() ?? 0}', inputType: TextInputType.number),
              if ((_prixAnnuel ?? 0) > 0) ...[
                const SizedBox(height: 6),
                GestureDetector(onTap: () => setDialog(() => montantCtrl.text = _prixAnnuel!.toInt().toString()), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.bolt_rounded, color: _C.green, size: 12), const SizedBox(width: 5), Text('Prix tranche : ${_prixAnnuel!.toInt()} DH', style: const TextStyle(color: _C.green, fontSize: 11, fontWeight: FontWeight.w600))]))),
              ],
              if (errorMsg != null) ...[const SizedBox(height: 8), _dError(errorMsg!)],
              const SizedBox(height: 16),
              _dActions(ctx: ctx, saving: saving, label: 'Enregistrer le paiement', color: _C.green, onConfirm: () async {
                final montant = double.tryParse(montantCtrl.text.trim()) ?? 0;
                if (montant <= 0) { setDialog(() => errorMsg = 'Entrez un montant valide'); return; }
                if (selectedAppart == null) { setDialog(() => errorMsg = 'Sélectionnez un appartement'); return; }
                if (_currentMandatId == null) { setDialog(() => errorMsg = 'Aucun mandat sélectionné'); return; }
                setDialog(() { saving = true; errorMsg = null; });
                try {
                  final db = Supabase.instance.client;
                  final appartId = selectedAppart!['id'];
                  final trData = await db.from('tranches').select('residence_id, inter_syndic_id').eq('id', widget.trancheId).maybeSingle();
                  final residenceId = trData?['residence_id'] ?? 1;
                  final isId = trData?['inter_syndic_id'] ?? 1;
                  final existing = await db.from('paiements').select('id, montant_paye, montant_total').eq('appartement_id', appartId).eq('type_paiement', 'charges').eq('mandat_id', _currentMandatId!).maybeSingle();
                  if (existing != null) {
                    final double dejaP = double.tryParse(existing['montant_paye'].toString()) ?? 0;
                    final double total = double.tryParse(existing['montant_total'].toString()) ?? montant;
                    final double nouveau = dejaP + montant;
                    final String statut = nouveau >= total ? 'complet' : (nouveau > 0 ? 'partiel' : 'impaye');
                    await db.from('paiements').update({'montant_paye': nouveau, 'statut': statut, 'date_paiement': DateTime.now().toIso8601String().substring(0, 10)}).eq('id', existing['id']);
                  } else {
                    await db.from('paiements').insert({'appartement_id': appartId, 'residence_id': residenceId, 'inter_syndic_id': isId, 'montant_total': montant, 'montant_paye': montant, 'type_paiement': 'charges', 'statut': 'complet', 'annee': _fallbackAnnee, 'mois': DateTime.now().month, 'date_paiement': DateTime.now().toIso8601String().substring(0, 10), 'mandat_id': _currentMandatId!});
                  }
                  await _loadAppartementsLibres();
                  if (ctx.mounted) setDialog(() { saving = false; paymentDone = true; selectedAppart = _appartementsLibres.isNotEmpty ? _appartementsLibres.first : null; });
                } catch (e) { setDialog(() { errorMsg = e.toString(); saving = false; }); }
              }),
            ],
          ],
          // TAB 1
          if (activeTab == 1) ...[
            if (_appartementsLibresPaies.isEmpty) ...[
              Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Column(children: [Icon(Icons.receipt_long_outlined, color: _C.divider, size: 40), const SizedBox(height: 8), const Text('Aucun appartement payé pour ce mandat', style: TextStyle(color: _C.textLight, fontSize: 12))]))),
            ] else ...[
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.check_circle_rounded, color: _C.green, size: 15), const SizedBox(width: 8), Text('${_appartementsLibresPaies.length} appartement(s) payé(s)', style: const TextStyle(color: _C.green, fontWeight: FontWeight.w700, fontSize: 12)), const Spacer(), Text('${_appartementsLibresPaies.fold<double>(0, (s, a) => s + (a['montant_paye'] as double? ?? 0)).toInt()} DH', style: const TextStyle(color: _C.green, fontWeight: FontWeight.w800, fontSize: 13))])),
              const SizedBox(height: 10),
              ConstrainedBox(constraints: const BoxConstraints(maxHeight: 250), child: ListView.separated(shrinkWrap: true, itemCount: _appartementsLibresPaies.length, separatorBuilder: (_, __) => Container(height: 1, color: _C.divider), itemBuilder: (_, i) {
                final a = _appartementsLibresPaies[i];
                final double mp = a['montant_paye'] as double? ?? 0;
                final String statut = a['statut']?.toString() ?? 'impaye';
                final String dateStr = a['date_paiement']?.toString() ?? '';
                String dateF = dateStr;
                try { final d = DateTime.parse(dateStr); dateF = '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}'; } catch (_) {}
                final Color sColor = _statutColor(statut);
                final Color sBg = _statutBg(statut);
                return Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.home_rounded, color: _C.green, size: 17)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a['label']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _C.dark), overflow: TextOverflow.ellipsis), Text(dateF, style: const TextStyle(color: _C.textLight, fontSize: 10))])),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('+${mp.toInt()} DH', style: TextStyle(color: sColor, fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 2), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: sBg, borderRadius: BorderRadius.circular(20)), child: Text(_statutLabel(statut), style: TextStyle(color: sColor, fontSize: 9, fontWeight: FontWeight.w700)))]),
                ]));
              })),
            ],
            const SizedBox(height: 14),
            GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)), child: const Text('Fermer', textAlign: TextAlign.center, style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 13)))),
          ],
        ]))),
      )),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────

  String _paiementLabel(PaiementModel p) {
    final type = p.typePaiement.name.toUpperCase();
    final ref = (p.reference != null && p.reference!.isNotEmpty) ? ' ${p.reference}' : '';
    final annee = p.annee > 0 ? ' · ${p.annee}' : '';
    return '$type$ref$annee';
  }
}