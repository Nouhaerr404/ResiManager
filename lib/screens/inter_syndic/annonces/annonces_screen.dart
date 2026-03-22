// lib/screens/inter_syndic/annonces/annonces_screen.dart

import 'package:flutter/material.dart';
import '../../../services/tranche_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(null),
        backgroundColor: _C.coral,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: _C.white, size: 26),
      ),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _C.coral, strokeWidth: 2.5))
                : RefreshIndicator(
              color: _C.coral,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                children: [
                  _buildStats(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildFilterTabs(),
                  const SizedBox(height: 20),
                  Text(
                    '${_filtered.length} annonce${_filtered.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 14),
                  if (_filtered.isEmpty)
                    _buildEmpty()
                  else
                    ..._filtered.map(_buildCard),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _C.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.divider)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: _C.dark),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: _C.coral, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.campaign_rounded, color: _C.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('Annonces', style: TextStyle(color: _C.dark, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
            Text('${_all.length} au total', style: const TextStyle(color: _C.textLight, fontSize: 12)),
          ]),
        ),
        if (_nbUrgente > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.warning_amber_rounded, size: 12, color: _C.coral),
              const SizedBox(width: 5),
              Text('$_nbUrgente urgente${_nbUrgente > 1 ? 's' : ''}',
                  style: const TextStyle(color: _C.coral, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
      ]),
    );
  }

  // ── Stats ──────────────────────────────────────────────────
  Widget _buildStats() {
    return Row(children: [
      _statCard(Icons.check_circle_outline_rounded, '$_nbPubliee', 'Publiées', _C.green, _C.greenLight),
      const SizedBox(width: 10),
      _statCard(Icons.edit_note_rounded, '$_nbArchivee', 'Archivées', _C.blue, _C.blueLight),
      const SizedBox(width: 10),
      _statCard(Icons.warning_amber_rounded, '$_nbUrgente', 'Urgentes', _C.coral, _C.coralLight),
    ]);
  }

  Widget _statCard(IconData icon, String value, String label, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.divider)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: _C.dark, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _C.textLight, fontSize: 10), overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  // ── Barre de recherche ─────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14, color: _C.dark),
        decoration: InputDecoration(
          hintText: 'Rechercher une annonce...',
          hintStyle: const TextStyle(color: _C.textLight, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: _C.textLight, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: _C.textLight, size: 18),
                  onPressed: () { _searchCtrl.clear(); _applyFilter(); },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Filtres ────────────────────────────────────────────────
  Widget _buildFilterTabs() {
    final filters = [
      ('tous',      'Tous',        _all.length),
      ('publiee',   'Publiées',    _nbPubliee),
      ('archivee',  'Archivées',   _nbArchivee),
      ('urgente',   'Urgentes',    _nbUrgente),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: filters.map((f) {
        final isSelected = _filterType == f.$1;
        return GestureDetector(
          onTap: () => _setFilter(f.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _C.coral : _C.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: isSelected ? _C.coral : _C.divider),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(f.$2, style: TextStyle(color: isSelected ? _C.white : _C.textMid, fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? _C.white.withValues(alpha: 0.25) : _C.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${f.$3}', style: TextStyle(color: isSelected ? _C.white : _C.textLight, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        );
      }).toList()),
    );
  }

  // ── Empty state ────────────────────────────────────────────
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.campaign_outlined, color: _C.coral, size: 30),
        ),
        const SizedBox(height: 16),
        const Text('Aucune annonce', style: TextStyle(color: _C.dark, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          _filterType == 'tous'
              ? 'Appuyez sur + pour créer une nouvelle annonce'
              : 'Aucune annonce avec ce filtre',
          style: const TextStyle(color: _C.textLight, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  // ── Carte annonce ──────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> a) {
    final bool isUrgent   = a['type'] == 'urgente';
    final bool isPubliee  = a['statut'] == 'publiee';
    final String dateStr  = (a['created_at'] ?? '').toString().split('T')[0];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? _C.coral.withValues(alpha: 0.4) : _C.divider,
          width: isUrgent ? 1.5 : 1,
        ),
      ),
      child: Column(children: [

        // Corps
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Titre + badges
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Barre colorée latérale (simulée avec un Container)
              Container(
                width: 4, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isUrgent
                        ? [_C.coral, const Color(0xFFFF9A6C)]
                        : [const Color(0xFF2D2D2D), const Color(0xFF6B6B6B)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        a['titre'] ?? '',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.dark, letterSpacing: -0.2, height: 1.3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _C.coral, borderRadius: BorderRadius.circular(20)),
                        child: const Text('URGENT', style: TextStyle(color: _C.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                      ),
                    const SizedBox(width: 6),
                    // Badge statut
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPubliee ? _C.greenLight : _C.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isPubliee ? _C.green.withValues(alpha: 0.4) : _C.divider),
                      ),
                      child: Text(
                        isPubliee ? 'Publiée' : 'Archivée',
                        style: TextStyle(color: isPubliee ? _C.green : _C.textLight, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ]),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [

            // Publier / Dépublier
            GestureDetector(
              onTap: () => _togglePublish(a),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isPubliee ? _C.bg : _C.greenLight,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: isPubliee ? _C.divider : _C.green.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    isPubliee ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 13,
                    color: isPubliee ? _C.textMid : _C.green,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isPubliee ? 'Dépublier' : 'Publier',
                    style: TextStyle(color: isPubliee ? _C.textMid : _C.green, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),

            // Modifier
            GestureDetector(
              onTap: () => _showFormDialog(a),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: _C.blueLight, borderRadius: BorderRadius.circular(9)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_rounded, size: 13, color: _C.blue),
                  SizedBox(width: 5),
                  Text('Modifier', style: TextStyle(color: _C.blue, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),

            const Spacer(),

            // Supprimer
            GestureDetector(
              onTap: () => _confirmDelete(a),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(9), border: Border.all(color: _C.divider)),
                child: const Icon(Icons.delete_outline_rounded, size: 16, color: _C.coral),
              ),
            ),
          ]),
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
    String selectedType = existing?['type'] ?? 'normale';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
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
                Row(children: [
                  _typeOption('normale', 'Normale', Icons.info_outline_rounded, _C.dark, setDialog, selectedType, (v) => selectedType = v),
                  const SizedBox(width: 10),
                  _typeOption('urgente', 'Urgente', Icons.warning_amber_rounded, _C.coral, setDialog, selectedType, (v) => selectedType = v),
                ]),
                const SizedBox(height: 24),

                // Bouton confirmer
                GestureDetector(
                  onTap: () async {
                    final titre   = titreCtrl.text.trim();
                    final contenu = contenuCtrl.text.trim();
                    if (titre.isEmpty || contenu.isEmpty) {
                      _showSnack('Veuillez remplir tous les champs', isError: true);
                      return;
                    }
                    Navigator.pop(ctx);
                    String? err;
                    if (isEdit) {
                      err = await _service.updateAnnonce(
                        id: existing!['id'],
                        titre: titre,
                        contenu: contenu,
                        type: selectedType,
                        statut: existing['statut'] ?? 'archivee',
                      );
                    } else {
                      err = await _service.addAnnonce(
                        trancheId: widget.trancheId,
                        titre: titre,
                        contenu: contenu,
                        type: selectedType,
                      );
                    }
                    if (!mounted) return;
                    if (err != null) {
                      _showSnack('Erreur : $err', isError: true);
                    } else {
                      _showSnack(isEdit ? 'Annonce modifiée ✓' : 'Annonce créée ✓');
                      _load();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: _C.coral, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      isEdit ? 'Enregistrer les modifications' : 'Créer l\'annonce',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _C.white, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
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
    return Expanded(
      child: GestureDetector(
        onTap: () => setDialog(() => onSelect(value)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? (value == 'urgente' ? _C.coralLight : _C.bg) : _C.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : _C.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: isSelected ? color : _C.textLight),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? color : _C.textMid, fontWeight: FontWeight.w700, fontSize: 13)),
            if (isSelected) ...[ const SizedBox(width: 4), Icon(Icons.check_circle_rounded, size: 14, color: color)],
          ]),
        ),
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
