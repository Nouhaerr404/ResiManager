// lib/screens/inter_syndic/annonces/annonces_screen.dart

import 'package:flutter/material.dart';
import '../../../services/tranche_service.dart';
import '../../../services/reunion_service.dart';
import '../../../widgets/inter_syndic_header.dart';

// ── Palette (identique aux autres écrans inter-syndic)
class _C {
  static const coral      = Color(0xFFE8603C);
  static const coralLight = Color(0xFFFFF0EB);
  static const bg         = Color(0xFFF2F3F5);
  static const white      = Color(0xFFFFFFFF);
  static const dark       = Color(0xFF1A1A1A);
  static const textMid    = Color(0xFF5A5A6A);
  static const textLight  = Color(0xFF9A9AAF);
  static const divider    = Color(0xFFE8E8F0);
  static const blue       = Color(0xFF4B6BFB);
  static const blueLight  = Color(0xFFEEF1FF);
  static const amber      = Color(0xFFF5A623);
  static const amberLight = Color(0xFFFFF8EC);
  static const green      = Color(0xFF34C98B);
  static const greenLight = Color(0xFFEBFAF4);
}

class AnnoncesScreen extends StatefulWidget {
  final int trancheId;
  const AnnoncesScreen({super.key, required this.trancheId});

  @override
  State<AnnoncesScreen> createState() => _AnnoncesScreenState();
}

class _AnnoncesScreenState extends State<AnnoncesScreen> {
  final _service = TrancheService();
  final _reunionService = ReunionService();

  List<Map<String, dynamic>> _all      = [];
  List<Map<String, dynamic>> _filtered = [];
  bool   _loading      = true;
  String _filterType   = 'tous'; // 'tous' | 'publiee' | 'archivee' | 'urgente'
  final  _searchCtrl   = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getAnnoncesByTranche(widget.trancheId);
    setState(() { _all = data; _loading = false; });
    _applyFilter();
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all.where((a) {
        final matchSearch = (a['titre'] ?? '').toString().toLowerCase().contains(q) ||
            (a['contenu'] ?? '').toString().toLowerCase().contains(q);
        final matchType = _filterType == 'tous'
            ? true
            : _filterType == 'urgente'
                ? a['type'] == 'urgente'
                : a['statut'] == _filterType;
        return matchSearch && matchType;
      }).toList();
    });
  }

  void _setFilter(String f) {
    setState(() => _filterType = f);
    _applyFilter();
  }

  // ── Compteurs ──────────────────────────────────────────────
  int get _nbPubliee   => _all.where((a) => a['statut'] == 'publiee').length;
  int get _nbArchivee  => _all.where((a) => a['statut'] == 'archivee').length;
  int get _nbUrgente   => _all.where((a) => a['type'] == 'urgente').length;

  bool showFilters = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: InterSyndicHeader(
                  title: 'ResiManager',
                  subtitle: 'Gestion Annonces',
                  gridIcon: Icons.campaign_rounded,
                  onBack: () => Navigator.pop(context),
                  onAdd: () => _showFormDialog(null),
                  addLabel: 'Ajouter',
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHeroStatsCard(_all.length, _nbPubliee, _nbArchivee, _nbUrgente),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _C.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: _C.divider),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            // onChanged: (_) => _applyFilter(), listener in initState
                            decoration: const InputDecoration(
                              hintText: 'Rechercher une annonce...',
                              hintStyle: TextStyle(color: _C.textLight),
                              prefixIcon: Icon(Icons.search_rounded, color: _C.textLight),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() => showFilters = !showFilters),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: showFilters ? _C.coral : _C.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (showFilters ? _C.coral : Colors.black).withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: showFilters ? _C.coral : _C.divider),
                          ),
                          child: Icon(
                            showFilters ? Icons.filter_list_off : Icons.filter_list, 
                            color: showFilters ? _C.white : _C.dark,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showFilters)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildFilterTabs(),
                  ),
                ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: _C.coral)),
                )
              else if (_filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmpty(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildCard(_filtered[index]),
                      childCount: _filtered.length,
                    ),
                  ),
                ),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.white.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator(color: _C.coral)),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroStatsCard(int total, int publiee, int archivee, int urgente) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.coral,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _C.coral.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'Annonces',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '$total annonces au total',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.campaign_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    const Text(
                      'Communication',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                '${total > 0 ? ((publiee / total) * 100).toInt() : 0}% publiées',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
               Text(
                '${urgente} Urgente${urgente > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? (publiee / total) : 0,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHeroStatMiniItem(publiee.toString().padLeft(2, '0'), 'Publiées'),
                _buildHeroStatDivider(),
                _buildHeroStatMiniItem(urgente.toString().padLeft(2, '0'), 'Urgentes'),
                _buildHeroStatDivider(),
                _buildHeroStatMiniItem(archivee.toString().padLeft(2, '0'), 'Archivées'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatMiniItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStatDivider() =>
      Container(width: 1, height: 24, color: Colors.white.withOpacity(0.2));

  Widget _buildFilterTabs() {
    final filters = [
      ('tous',      'Tous',        _all.length),
      ('publiee',   'Publiées',    _nbPubliee),
      ('urgente',   'Urgentes',    _nbUrgente),
      ('archivee',  'Archivées',   _nbArchivee),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _filterType == f.$1;
          return GestureDetector(
            onTap: () => _setFilter(f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _C.coral : _C.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: _C.coral.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
                border: Border.all(color: isSelected ? _C.coral : _C.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f.$2,
                    style: TextStyle(
                        color: isSelected ? _C.white : _C.textMid,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? _C.white.withOpacity(0.2) : _C.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${f.$3}',
                      style: TextStyle(
                          color: isSelected ? _C.white : _C.textMid,
                          fontSize: 11,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _C.divider.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.campaign_outlined, size: 80, color: _C.textLight.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune annonce', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _C.dark),
          ),
          const SizedBox(height: 8),
          Text(
            _filterType == 'tous'
                ? 'Essayez d\'ajouter une nouvelle annonce'
                : 'Aucune annonce avec ce filtre', 
            style: const TextStyle(fontSize: 14, color: _C.textLight),
          ),
          const SizedBox(height: 24),
          if (_filterType != 'tous' || _searchCtrl.text.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchCtrl.clear();
                  _filterType = 'tous';
                  _applyFilter();
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réinitialiser tout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _C.coral,
                side: const BorderSide(color: _C.coral),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Carte annonce ──────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> a) {
    final bool isUrgent   = a['type'] == 'urgente';
    final bool isReunion  = a['type'] == 'reunion';
    final bool isPubliee  = a['statut'] == 'publiee';
    final String dateStr  = (a['created_at'] ?? '').toString().split('T')[0];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? _C.coral.withValues(alpha: 0.4) : (isReunion ? _C.blue.withValues(alpha: 0.4) : _C.divider),
          width: (isUrgent || isReunion) ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [

        // Corps
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Titre + badges
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Barre colorée latérale
              Container(
                width: 4, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isUrgent
                        ? [_C.coral, const Color(0xFFFF9A6C)]
                        : isReunion 
                            ? [_C.blue, const Color(0xFF88A0FF)]
                            : [const Color(0xFF2D2D2D), const Color(0xFF6B6B6B)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        a['titre'] ?? '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _C.dark, letterSpacing: -0.2),
                      ),
                      if (isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: _C.coral, borderRadius: BorderRadius.circular(20)),
                          child: const Text('URGENT', style: TextStyle(color: _C.white, fontSize: 8, fontWeight: FontWeight.w800)),
                        ),
                      if (isReunion)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: _C.blue, borderRadius: BorderRadius.circular(20)),
                          child: const Text('RÉUNION', style: TextStyle(color: _C.white, fontSize: 8, fontWeight: FontWeight.w800)),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPubliee ? _C.greenLight : _C.bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isPubliee ? _C.green.withValues(alpha: 0.4) : _C.divider),
                        ),
                        child: Text(
                          isPubliee ? 'Publiée' : 'Archivée',
                          style: TextStyle(color: isPubliee ? _C.green : _C.textLight, fontSize: 8, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a['contenu'] ?? '',
                    style: const TextStyle(color: _C.textMid, fontSize: 13, height: 1.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 11, color: _C.textLight),
                    const SizedBox(width: 4),
                    Text('Publié le $dateStr', style: const TextStyle(color: _C.textLight, fontSize: 11)),
                  ]),
                ]),
              ),
            ]),
          ]),
        ),

        // Footer actions
        Container(
          decoration: BoxDecoration(
            color: _C.bg,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
            border: Border(top: BorderSide(color: _C.divider)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _togglePublish(a),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPubliee ? _C.bg : _C.greenLight,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: isPubliee ? _C.divider : _C.green.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isPubliee ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 12, color: isPubliee ? _C.textMid : _C.green),
                      const SizedBox(width: 4),
                      Text(isPubliee ? 'Dépublier' : 'Publier', style: TextStyle(color: isPubliee ? _C.textMid : _C.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showFormDialog(a),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _C.blueLight, borderRadius: BorderRadius.circular(9)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 12, color: _C.blue),
                      SizedBox(width: 4),
                      Text('Modifier', style: TextStyle(color: _C.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _confirmDelete(a),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(9), border: Border.all(color: _C.divider)),
                  child: const Icon(Icons.delete_outline_rounded, size: 16, color: _C.coral),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Actions ────────────────────────────────────────────────

  Future<void> _togglePublish(Map<String, dynamic> a) async {
    final newStatut = a['statut'] == 'publiee' ? 'archivee' : 'publiee';
    final err = await _service.updateAnnonce(
      id: a['id'],
      titre: a['titre'],
      contenu: a['contenu'],
      type: a['type'],
      statut: newStatut,
    );
    if (!mounted) return;
    if (err != null) {
      _showSnack('Erreur : $err', isError: true);
    } else {
      _showSnack(newStatut == 'publiee' ? 'Annonce publiée ✓' : 'Annonce dépubliée');
      _load();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.delete_forever_rounded, color: _C.coral, size: 26),
            ),
            const SizedBox(height: 16),
            const Text('Supprimer l\'annonce ?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _C.dark)),
            const SizedBox(height: 8),
            Text(
              'Cette action est irréversible.',
              style: const TextStyle(color: _C.textLight, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(color: _C.coral, borderRadius: BorderRadius.circular(12)),
                    child: const Text('Supprimer', textAlign: TextAlign.center,
                        style: TextStyle(color: _C.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.pop(ctx, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)),
                  child: const Text('Annuler', style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (confirm == true) {
      final err = await _service.deleteAnnonce(a['id']);
      if (!mounted) return;
      if (err != null) {
        _showSnack('Erreur : $err', isError: true);
      } else {
        _showSnack('Annonce supprimée');
        _load();
      }
    }
  }

  // ── Dialog création / modification ─────────────────────────
  void _showFormDialog(Map<String, dynamic>? existing) {
    final isEdit = existing != null;
    final titreCtrl   = TextEditingController(text: existing?['titre'] ?? '');
    final contenuCtrl = TextEditingController(text: existing?['contenu'] ?? '');
    
    // Reunion specific fields
    final dateCtrl = TextEditingController();
    final hourCtrl = TextEditingController();
    final lieuCtrl = TextEditingController();
    DateTime? selectedDate;
    
    String selectedType = existing?['type'] ?? 'normale';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          bool isSaving = false;
          String? errorMessage;

          return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Header dialog
                Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.campaign_rounded, color: _C.coral, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isEdit ? 'Modifier l\'annonce' : 'Nouvelle annonce',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _C.dark)),
                    Text(isEdit ? 'Mettre à jour les informations' : 'Remplissez les informations',
                        style: const TextStyle(color: _C.textLight, fontSize: 12)),
                  ])),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close_rounded, color: _C.textLight),
                  ),
                ]),
                const SizedBox(height: 20),
                Container(height: 1, color: _C.divider),
                const SizedBox(height: 20),

                // Titre
                const Text('Titre', style: TextStyle(color: _C.textLight, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    controller: titreCtrl,
                    style: const TextStyle(fontSize: 14, color: _C.dark),
                    decoration: const InputDecoration(
                      hintText: 'Ex: Coupure d\'eau prévue...',
                      hintStyle: TextStyle(color: _C.textLight, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Contenu
                const Text('Contenu', style: TextStyle(color: _C.textLight, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    controller: contenuCtrl,
                    minLines: 3,
                    maxLines: 6,
                    style: const TextStyle(fontSize: 14, color: _C.dark),
                    decoration: const InputDecoration(
                      hintText: 'Décrivez l\'annonce en détail...',
                      hintStyle: TextStyle(color: _C.textLight, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Type
                const Text('Type', style: TextStyle(color: _C.textLight, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _typeOption('normale', 'Normale', Icons.info_outline_rounded, _C.dark, setDialog, selectedType, (v) => selectedType = v),
                    const SizedBox(width: 8),
                    _typeOption('information', 'Info', Icons.lightbulb_outline_rounded, _C.amber, setDialog, selectedType, (v) => selectedType = v),
                    const SizedBox(width: 8),
                    _typeOption('urgente', 'Urgente', Icons.warning_amber_rounded, _C.coral, setDialog, selectedType, (v) => selectedType = v),
                    const SizedBox(width: 8),
                    _typeOption('reunion', 'Réunion', Icons.groups_rounded, _C.blue, setDialog, selectedType, (v) => selectedType = v),
                  ]),
                ),
                
                if (selectedType == 'reunion') ...[
                  const SizedBox(height: 20),
                  const Text('Détails de la réunion', style: TextStyle(color: _C.dark, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Date', style: TextStyle(color: _C.textLight, fontSize: 11)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () async {
                            final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                            if (d != null) { setDialog(() { selectedDate = d; dateCtrl.text = "${d.day}/${d.month}/${d.year}"; }); }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: _C.textLight),
                              const SizedBox(width: 8),
                              Text(dateCtrl.text.isEmpty ? 'Sélectionner' : dateCtrl.text, style: TextStyle(fontSize: 13, color: dateCtrl.text.isEmpty ? _C.textLight : _C.dark)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Heure', style: TextStyle(color: _C.textLight, fontSize: 11)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                            if (t != null) { setDialog(() => hourCtrl.text = "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}"); }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: _C.textLight),
                              const SizedBox(width: 8),
                              Text(hourCtrl.text.isEmpty ? 'Sélectionner' : hourCtrl.text, style: TextStyle(fontSize: 13, color: hourCtrl.text.isEmpty ? _C.textLight : _C.dark)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  const Text('Lieu', style: TextStyle(color: _C.textLight, fontSize: 11)),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10)),
                    child: TextField(
                      controller: lieuCtrl,
                      style: const TextStyle(fontSize: 13, color: _C.dark),
                      decoration: const InputDecoration(
                        hintText: 'Ex: Salle de réunion, Garden...',
                        hintStyle: TextStyle(color: _C.textLight, fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded, color: _C.coral, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(errorMessage!, style: const TextStyle(color: _C.coral, fontSize: 12, fontWeight: FontWeight.w600))),
                      ]),
                    ),
                  ),
                const SizedBox(height: 24),

                // Bouton confirmer
                GestureDetector(
                  onTap: isSaving ? null : () async {
                    final titre   = titreCtrl.text.trim();
                    final contenu = contenuCtrl.text.trim();
                    
                    if (titre.isEmpty || contenu.isEmpty) {
                      setDialog(() => errorMessage = 'Veuillez remplir tous les champs');
                      return;
                    }
                    if (selectedType == 'reunion') {
                      if (selectedDate == null || hourCtrl.text.isEmpty || lieuCtrl.text.trim().isEmpty) {
                        setDialog(() => errorMessage = 'Veuillez remplir les détails de la réunion');
                        return;
                      }
                    }

                    setDialog(() { isSaving = true; errorMessage = null; });
                    
                    String? err;
                    int? createdAnnonceId;

                    try {
                      // 1. Créer l'annonce d'abord
                      if (isEdit) {
                        err = await _service.updateAnnonce(
                          id: existing!['id'],
                          titre: titre,
                          contenu: contenu,
                          type: selectedType,
                          statut: existing['statut'] ?? 'publiee',
                        );
                      } else {
                        // On modifie temporairement l'appel pour gérer le retour d'ID si on le fait
                        // Pour l'instant on garde la compatibilité si addAnnonce n'est pas encore mis à jour
                        final res = await _service.addAnnonce(
                          trancheId: widget.trancheId,
                          titre: titre,
                          contenu: contenu,
                          type: selectedType,
                        );
                        // Si addAnnonce retourne Map<String, dynamic>
                        if (res is Map) {
                          err = res['error'];
                          createdAnnonceId = res['id'];
                        } else {
                          err = res as String?;
                        }
                      }

                      if (err != null) throw Exception(err);

                      // 2. Si c'est une réunion, créer l'entrée réunion liée
                      if (selectedType == 'reunion' && !isEdit) {
                        final rErr = await _reunionService.addReunion(
                          titre: titre,
                          description: contenu,
                          date: selectedDate!,
                          heure: hourCtrl.text,
                          lieu: lieuCtrl.text.trim(),
                          trancheId: widget.trancheId,
                          annonceId: createdAnnonceId,
                        );
                        if (rErr != null) throw Exception('Erreur réunion : $rErr');
                      }

                      if (!mounted) return;
                      Navigator.pop(ctx);
                      _showSnack(isEdit ? 'Annonce modifiée ✓' : 'Annonce créée ✓');
                      _load();

                    } catch (e) {
                      setDialog(() { 
                        isSaving = false; 
                        errorMessage = e.toString().replaceAll('Exception: ', ''); 
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSaving ? _C.textLight : _C.coral, 
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: isSaving 
                      ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                      : Text(
                          isEdit ? 'Enregistrer les modifications' : 'Créer l\'annonce',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _C.white, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                  ),
                ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _typeOption(
    String value,
    String label,
    IconData icon,
    Color color,
    StateSetter setDialog,
    String current,
    void Function(String) onSelect,
  ) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => setDialog(() => onSelect(value)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? (value == 'urgente' ? _C.coralLight : _C.bg) : _C.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : _C.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: isSelected ? color : _C.textLight),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isSelected ? color : _C.textMid, fontWeight: FontWeight.w700, fontSize: 13)),
          if (isSelected) ...[ const SizedBox(width: 4), Icon(Icons.check_circle_rounded, size: 14, color: color)],
        ]),
      ),
    );
  }

  // ── Toast notification ─────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? _C.coral : _C.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}
