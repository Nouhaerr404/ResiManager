// lib/screens/inter_syndic/reclamations/reclamations_screen.dart
// ignore_for_file: avoid_multiple_underscores_for_members

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/reclamation_service.dart';

class _C {
  static const coral       = Color(0xFFE8603C);
  static const coralLight  = Color(0xFFFFF0EB);
  static const bg          = Color(0xFFF2F3F5);
  static const white       = Color(0xFFFFFFFF);
  static const dark        = Color(0xFF1A1A1A);
  static const textMid     = Color(0xFF5A5A6A);
  static const textLight   = Color(0xFF9A9AAF);
  static const divider     = Color(0xFFE8E8F0);
  static const blue        = Color(0xFF4B6BFB);
  static const blueLight   = Color(0xFFEEF1FF);
  static const amber       = Color(0xFFF5A623);
  static const amberLight  = Color(0xFFFFF8EC);
  static const green       = Color(0xFF34C98B);
  static const greenLight  = Color(0xFFEBFAF4);
  static const red         = Color(0xFFEF4444);
  static const redLight    = Color(0xFFFEF2F2);
}

class ReclamationsScreen extends StatefulWidget {
  final int trancheId;
  const ReclamationsScreen({super.key, required this.trancheId});

  @override
  State<ReclamationsScreen> createState() => _ReclamationsScreenState();
}

class _ReclamationsScreenState extends State<ReclamationsScreen> {
  final _service = ReclamationService();

  List<ReclamationModel> _all      = [];
  List<ReclamationModel> _filtered = [];
  bool   _loading      = true;
  String _filterStatut = 'tous';
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
    final data = await _service.getReclamationsByTranche(widget.trancheId);
    setState(() { _all = data; _loading = false; });
    _applyFilter();
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all.where((r) {
        final matchSearch = r.titre.toLowerCase().contains(q) ||
            r.nomComplet.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q);
        final matchStatut = _filterStatut == 'tous' || r.statut == _filterStatut;
        return matchSearch && matchStatut;
      }).toList();
    });
  }

  void _setFilter(String f) {
    setState(() => _filterStatut = f);
    _applyFilter();
  }

  int get _nbEnCours => _all.where((r) => r.statut == 'en_cours').length;
  int get _nbResolu  => _all.where((r) => r.statut == 'resolue').length;
  int get _nbRejete  => _all.where((r) => r.statut == 'rejetee').length;

  // ─────────────────────────────────────────────────────────
  // Ouvrir / afficher le document joint
  // - Image (jpg/png) → dialog avec Image.network
  // - PDF / autre    → url_launcher pour ouvrir dans le navigateur
  // ─────────────────────────────────────────────────────────
  Future<void> _openDocument(ReclamationModel r) async {
    final url = r.documentUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL du document non disponible'),
          backgroundColor: _C.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (r.isImage) {
      // Afficher l'image dans un dialog
      _showImageDialog(url, r.titre);
    } else {
      // PDF ou autre fichier → ouvrir dans le navigateur
      await _openUrl(url);
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir le document'),
              backgroundColor: _C.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: _C.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Dialog image plein ecran
  void _showImageDialog(String url, String titre) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: _C.dark,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header dialog
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  color: _C.dark,
                  child: Row(children: [
                    const Icon(Icons.image_rounded, color: _C.textLight, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        titre,
                        style: const TextStyle(
                            color: _C.white, fontWeight: FontWeight.w700, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.close_rounded,
                            color: _C.white, size: 16),
                      ),
                    ),
                  ]),
                ),

                // Image
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.65,
                  ),
                  child: InteractiveViewer(
                    panEnabled: true,
                    scaleEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                      : null,
                                  color: _C.coral,
                                ),
                                const SizedBox(height: 12),
                                const Text('Chargement...',
                                    style: TextStyle(
                                        color: _C.textLight, fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const SizedBox(
                        height: 160,
                        child: Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.broken_image_rounded,
                                color: _C.textLight, size: 40),
                            SizedBox(height: 8),
                            Text('Impossible de charger l\'image',
                                style: TextStyle(color: _C.textLight, fontSize: 12)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),

                // Footer — bouton ouvrir dans navigateur
                Container(
                  padding: const EdgeInsets.all(12),
                  color: _C.dark,
                  child: Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _openUrl(url);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                              color: _C.blue,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.open_in_new_rounded,
                                  color: _C.white, size: 15),
                              SizedBox(width: 8),
                              Text('Ouvrir dans le navigateur',
                                  style: TextStyle(
                                      color: _C.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text('Fermer',
                            style: TextStyle(
                                color: _C.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                child: CircularProgressIndicator(
                    color: _C.coral, strokeWidth: 2.5))
                : RefreshIndicator(
              color: _C.coral,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  _buildStats(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildFilterTabs(),
                  const SizedBox(height: 20),
                  Text(
                    '${_filtered.length} reclamation${_filtered.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: _C.dark,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.3),
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

  // ── Header
  Widget _buildHeader() {
    return Container(
      color: _C.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.divider)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 14, color: _C.dark),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: _C.coral, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.report_problem_rounded,
              color: _C.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Reclamations',
                    style: TextStyle(
                        color: _C.dark,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        letterSpacing: -0.3)),
                Text('${_all.length} au total',
                    style: const TextStyle(
                        color: _C.textLight, fontSize: 12)),
              ]),
        ),
        if (_nbEnCours > 0)
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: _C.amberLight,
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.circle, size: 7, color: _C.amber),
              const SizedBox(width: 5),
              Text('$_nbEnCours en cours',
                  style: const TextStyle(
                      color: _C.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
      ]),
    );
  }

  // ── Stats
  Widget _buildStats() {
    return Row(children: [
      _statCard(Icons.hourglass_empty_rounded, '$_nbEnCours', 'En cours',
          _C.amber, _C.amberLight),
      const SizedBox(width: 10),
      _statCard(Icons.check_circle_outline_rounded, '$_nbResolu', 'Resolus',
          _C.green, _C.greenLight),
      const SizedBox(width: 10),
      _statCard(Icons.cancel_outlined, '$_nbRejete', 'Rejetes',
          _C.red, _C.redLight),
    ]);
  }

  Widget _statCard(IconData icon, String value, String label,
      Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.divider)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: _C.dark,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: _C.textLight, fontSize: 10),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  // ── Search bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.divider)),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14, color: _C.dark),
        decoration: const InputDecoration(
          hintText: 'Rechercher par titre, resident...',
          hintStyle: TextStyle(color: _C.textLight, fontSize: 13),
          prefixIcon:
          Icon(Icons.search_rounded, color: _C.textLight, size: 20),
          border: InputBorder.none,
          contentPadding:
          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Filter tabs
  Widget _buildFilterTabs() {
    final filters = [
      ('tous',     'Tous',     _all.length),
      ('en_cours', 'En cours', _nbEnCours),
      ('resolue',  'Resolus',  _nbResolu),
      ('rejetee',  'Rejetes',  _nbRejete),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
          children: filters.map((f) {
            final isSelected = _filterStatut == f.$1;
            return GestureDetector(
              onTap: () => _setFilter(f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _C.coral : _C.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: isSelected ? _C.coral : _C.divider),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(f.$2,
                      style: TextStyle(
                          color: isSelected ? _C.white : _C.textMid,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _C.white.withValues(alpha: 0.25)
                          : _C.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${f.$3}',
                        style: TextStyle(
                            color: isSelected ? _C.white : _C.textLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            );
          }).toList()),
    );
  }

  // ── Empty state
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: _C.coralLight,
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.inbox_rounded,
                color: _C.coral, size: 30)),
        const SizedBox(height: 16),
        const Text('Aucune reclamation',
            style: TextStyle(
                color: _C.dark,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          _filterStatut == 'tous'
              ? 'Aucune reclamation pour cette tranche'
              : 'Aucune reclamation avec ce statut',
          style: const TextStyle(color: _C.textLight, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  // ── Card reclamation
  Widget _buildCard(ReclamationModel r) {
    final statutColor = _statutColor(r.statut);
    final statutBg    = _statutBg(r.statut);
    final statutIcon  = _statutIcon(r.statut);
    final dateStr     = _fmt(r.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: r.statut == 'en_cours'
              ? _C.amber.withValues(alpha: 0.5)
              : _C.divider,
          width: r.statut == 'en_cours' ? 1.5 : 1,
        ),
      ),
      child: Column(children: [

        // Corps
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                      color: _C.coralLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Text(
                      r.nomComplet.isNotEmpty
                          ? r.nomComplet[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: _C.coral,
                          fontWeight: FontWeight.w800,
                          fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: Text(r.titre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: _C.dark,
                                    letterSpacing: -0.2)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                                color: statutBg,
                                borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(statutIcon, size: 10, color: statutColor),
                              const SizedBox(width: 4),
                              Text(r.statutEnum.label,
                                  style: TextStyle(
                                      color: statutColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ]),
                        const SizedBox(height: 5),
                        Row(children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 12, color: _C.textLight),
                          const SizedBox(width: 4),
                          Text(
                            r.nomComplet.isNotEmpty
                                ? r.nomComplet
                                : 'Resident inconnu',
                            style: const TextStyle(
                                color: _C.textMid,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text(r.description,
                            style: const TextStyle(
                                color: _C.textMid, fontSize: 12, height: 1.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 11, color: _C.textLight),
                          const SizedBox(width: 4),
                          Text('Soumis le $dateStr',
                              style: const TextStyle(
                                  color: _C.textLight, fontSize: 11)),
                        ]),
                      ]),
                ),
              ]),
        ),

        // Footer actions
        Container(
          decoration: BoxDecoration(
            color: _C.bg,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            border: Border(top: BorderSide(color: _C.divider)),
          ),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [

            // Voir details
            GestureDetector(
              onTap: () => _showDetails(r),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                    color: _C.blueLight,
                    borderRadius: BorderRadius.circular(9)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.visibility_rounded, size: 13, color: _C.blue),
                  SizedBox(width: 5),
                  Text('Details',
                      style: TextStyle(
                          color: _C.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            const SizedBox(width: 8),

            // Changer statut
            GestureDetector(
              onTap: () => _showStatutDialog(r),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                    color: statutBg,
                    borderRadius: BorderRadius.circular(9)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_rounded, size: 13, color: statutColor),
                  const SizedBox(width: 5),
                  Text('Statut',
                      style: TextStyle(
                          color: statutColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),

            const Spacer(),

            // ── Bouton Document — CLIQUABLE avec ouverture fichier
            if (r.hasDocument)
              GestureDetector(
                onTap: () => _openDocument(r),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                      color: _C.greenLight,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: _C.green.withValues(alpha: 0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      r.isImage
                          ? Icons.image_rounded
                          : Icons.picture_as_pdf_rounded,
                      size: 13,
                      color: _C.green,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      r.isImage ? 'Voir image' : 'Voir PDF',
                      style: const TextStyle(
                          color: _C.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  // ── Dialog details
  void _showDetails(ReclamationModel r) {
    final statutColor = _statutColor(r.statut);
    final statutBg    = _statutBg(r.statut);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(children: [
                  Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                          color: _C.coralLight,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.report_problem_rounded,
                          color: _C.coral, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Detail Reclamation',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: _C.dark)),
                          Text('#${r.id}',
                              style: const TextStyle(
                                  color: _C.textLight, fontSize: 12)),
                        ]),
                  ),
                  GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close_rounded,
                          color: _C.textLight)),
                ]),
                const SizedBox(height: 16),
                Container(height: 1, color: _C.divider),
                const SizedBox(height: 16),

                // Statut badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: statutBg,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    Icon(_statutIcon(r.statut),
                        size: 14, color: statutColor),
                    const SizedBox(width: 8),
                    Text(r.statutEnum.label,
                        style: TextStyle(
                            color: statutColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ]),
                ),
                const SizedBox(height: 14),

                _detailRow('Titre', r.titre),
                const SizedBox(height: 10),
                _detailRow('Resident',
                    r.nomComplet.isNotEmpty ? r.nomComplet : 'Inconnu'),
                const SizedBox(height: 10),
                _detailRow('Date', _fmt(r.createdAt)),
                const SizedBox(height: 14),

                // Description
                const Text('Description',
                    style: TextStyle(
                        color: _C.textLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: _C.bg,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(r.description,
                      style: const TextStyle(
                          color: _C.dark, fontSize: 13, height: 1.6)),
                ),
                const SizedBox(height: 14),

                // Document section dans le detail
                if (r.hasDocument)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _openDocument(r);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: _C.greenLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _C.green.withValues(alpha: 0.3))),
                      child: Row(children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                              color: _C.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(
                            r.isImage
                                ? Icons.image_rounded
                                : Icons.picture_as_pdf_rounded,
                            color: _C.green,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.isImage ? 'Image jointe' : 'Document PDF joint',
                                  style: const TextStyle(
                                      color: _C.green,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                const Text('Appuyer pour ouvrir',
                                    style: TextStyle(
                                        color: _C.green,
                                        fontSize: 11)),
                              ]),
                        ),
                        const Icon(Icons.open_in_new_rounded,
                            color: _C.green, size: 16),
                      ]),
                    ),
                  ),

                const SizedBox(height: 20),

                // Boutons
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _showStatutDialog(r);
                      },
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                            color: _C.coral,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Text('Changer statut',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: _C.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 13),
                      decoration: BoxDecoration(
                          color: _C.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.divider)),
                      child: const Text('Fermer',
                          style: TextStyle(
                              color: _C.dark,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ),
                ]),
              ]),
        ),
      ),
    );
  }

  // ── Dialog changer statut
  void _showStatutDialog(ReclamationModel r) {
    StatutReclamation selected = r.statutEnum;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                            color: _C.coralLight,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.edit_rounded,
                            color: _C.coral, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Changer le statut',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: _C.dark)),
                            Text(r.titre,
                                style: const TextStyle(
                                    color: _C.textLight, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ]),
                    ),
                    GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close_rounded,
                            color: _C.textLight)),
                  ]),
                  const SizedBox(height: 20),

                  ...StatutReclamation.values.map((s) {
                    final isSelected = selected == s;
                    final color = _statutColorFromEnum(s);
                    final bg    = _statutBgFromEnum(s);
                    return GestureDetector(
                      onTap: () => setDialog(() => selected = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? bg : _C.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : _C.divider,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                                color: isSelected ? color : _C.bg,
                                borderRadius: BorderRadius.circular(9)),
                            child: Icon(_statutIcon(s.dbValue),
                                size: 17,
                                color: isSelected
                                    ? _C.white
                                    : _C.textLight),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.label,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isSelected ? color : _C.dark)),
                                  Text(_statutDesc(s),
                                      style: const TextStyle(
                                          color: _C.textLight, fontSize: 11)),
                                ]),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: color, size: 20),
                        ]),
                      ),
                    );
                  }),
                  const SizedBox(height: 6),

                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      final err =
                      await _service.updateStatut(r.id, selected);
                      if (!mounted) return;
                      if (err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Erreur : $err'),
                          backgroundColor: _C.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Statut mis a jour'),
                          backgroundColor: _C.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ));
                        _load();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: _C.coral,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('Confirmer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _C.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  // ── Helpers
  Widget _detailRow(String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(
                  color: _C.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600))),
      const SizedBox(width: 8),
      Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: _C.dark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600))),
    ]);
  }

  Color _statutColor(String s) {
    switch (s) {
      case 'resolue': return _C.green;
      case 'rejetee': return _C.red;
      default:        return _C.amber;
    }
  }

  Color _statutBg(String s) {
    switch (s) {
      case 'resolue': return _C.greenLight;
      case 'rejetee': return _C.redLight;
      default:        return _C.amberLight;
    }
  }

  IconData _statutIcon(String s) {
    switch (s) {
      case 'resolue': return Icons.check_circle_rounded;
      case 'rejetee': return Icons.cancel_rounded;
      default:        return Icons.hourglass_empty_rounded;
    }
  }

  Color _statutColorFromEnum(StatutReclamation s) => _statutColor(s.dbValue);
  Color _statutBgFromEnum(StatutReclamation s)    => _statutBg(s.dbValue);

  String _statutDesc(StatutReclamation s) {
    switch (s) {
      case StatutReclamation.en_cours: return 'Reclamation en attente de traitement';
      case StatutReclamation.resolue:  return 'Reclamation resolue avec succes';
      case StatutReclamation.rejetee:  return 'Reclamation refusee ou non valide';
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}