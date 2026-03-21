import 'package:flutter/material.dart';
import '../../../models/resident_model.dart';
import '../../../models/paiement_model.dart';
import '../../../services/resident_service.dart';

class _C {
  static const coral       = Color(0xFFE8603C);
  static const coralLight  = Color(0xFFFFF0EB);
  static const bg          = Color(0xFFF2F3F5);
  static const white       = Color(0xFFFFFFFF);
  static const dark        = Color(0xFF1A1A1A);
  static const textMid     = Color(0xFF5A5A6A);
  static const textLight   = Color(0xFF9A9AAF);
  static const divider     = Color(0xFFE8E8F0);
  static const iconBg      = Color(0xFFEDEDED);
  static const blue        = Color(0xFF4B6BFB);
  static const blueLight   = Color(0xFFEEF1FF);
  static const amber       = Color(0xFFF5A623);
  static const amberLight  = Color(0xFFFFF8EC);
  static const green       = Color(0xFF34C98B);
  static const greenLight  = Color(0xFFEBFAF4);
  static const orange      = Color(0xFFF97316);
  static const orangeLight = Color(0xFFFFF7ED);
}

// ── Icône et couleur par type de paiement
IconData _typeIcon(TypePaiementEnum t) {
  switch (t) {
    case TypePaiementEnum.charges: return Icons.apartment_rounded;
    case TypePaiementEnum.parking: return Icons.local_parking_rounded;
    case TypePaiementEnum.garage:  return Icons.garage_rounded;
    case TypePaiementEnum.box:     return Icons.inventory_2_rounded;
    default:                       return Icons.payments_rounded;
  }
}

Color _typeColor(TypePaiementEnum t) {
  switch (t) {
    case TypePaiementEnum.charges: return _C.coral;
    case TypePaiementEnum.parking: return _C.blue;
    case TypePaiementEnum.garage:  return _C.amber;
    case TypePaiementEnum.box:     return _C.green;
    default:                       return _C.textMid;
  }
}

String _typeLabel(TypePaiementEnum t) {
  switch (t) {
    case TypePaiementEnum.charges: return 'Charges';
    case TypePaiementEnum.parking: return 'Parking';
    case TypePaiementEnum.garage:  return 'Garage';
    case TypePaiementEnum.box:     return 'Box';
    default:                       return t.name.toUpperCase();
  }
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
  final _searchCtrl = TextEditingController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getResidentsByTranche(widget.trancheId).timeout(const Duration(seconds: 15));
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

  int get _total    => _residents.length;
  int get _complets => _residents.where((r) => r.statutPaiement == 'complet').length;
  int get _impayes  => _residents.where((r) => r.statutPaiement == 'impaye').length;

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
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    children: [
                      _buildPageTitle(),
                      const SizedBox(height: 20),
                      _buildStatsBanner(),
                      const SizedBox(height: 20),
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildFilterTabs(),
                      const SizedBox(height: 24),
                      _buildSectionLabel('${_filtered.length} resident${_filtered.length > 1 ? 's' : ''}'),
                      const SizedBox(height: 14),
                      if (_filtered.isEmpty) _buildEmpty() else ..._filtered.map(_buildResidentCard),
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

  // ═══════════════════════════════════════
  // WIDGETS DE BASE
  // ═══════════════════════════════════════

  Widget _buildLoader() => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(color: _C.coral, strokeWidth: 2.5),
      SizedBox(height: 16),
      Text('Chargement...', style: TextStyle(color: _C.textLight, fontSize: 13, fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _buildEmpty() => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.people_rounded, color: _C.coral, size: 30)),
      const SizedBox(height: 14),
      const Text('Aucun resident', style: TextStyle(color: _C.dark, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      const Text('Modifiez les filtres ou ajoutez un resident.', style: TextStyle(color: _C.textLight, fontSize: 12)),
    ]),
  );

  Widget _buildHeader() => Container(
    color: _C.white,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(width: 38, height: 38, decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.divider)), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: _C.dark)),
      ),
      const SizedBox(width: 12),
      Container(width: 38, height: 38, decoration: BoxDecoration(color: _C.coral, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.grid_view_rounded, color: _C.white, size: 20)),
      const SizedBox(width: 10),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('ResiManager', style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2)),
        Text('inter_syndic', style: TextStyle(color: _C.textLight, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
      const Spacer(),
      GestureDetector(
        onTap: _showAddResidentDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(color: _C.coral, borderRadius: BorderRadius.circular(22)),
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.add_rounded, size: 16, color: _C.white),
            SizedBox(width: 6),
            Text('Ajouter', style: TextStyle(color: _C.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    ]),
  );

  Widget _buildPageTitle() => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Residents', style: TextStyle(color: _C.dark, fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.5)),
    SizedBox(height: 4),
    Text('Gestion des residents de la tranche', style: TextStyle(color: _C.textMid, fontSize: 13, fontWeight: FontWeight.w400)),
  ]);

  Widget _buildStatsBanner() {
    final pctVal = _total == 0 ? 0 : (_complets * 100 ~/ _total);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.divider)),
      child: Column(children: [
        Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.people_rounded, color: _C.coral, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$_total residents', style: const TextStyle(color: _C.dark, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3)),
            const Text('dans cette tranche', style: TextStyle(color: _C.textLight, fontSize: 11)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(20)),
              child: Text('$pctVal% complets', style: const TextStyle(color: _C.coral, fontWeight: FontWeight.w700, fontSize: 12))),
        ]),
        const SizedBox(height: 16),
        ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: (_total == 0 ? 0.0 : _complets / _total).clamp(0.0, 1.0), backgroundColor: _C.divider, valueColor: const AlwaysStoppedAnimation(_C.coral), minHeight: 7)),
        const SizedBox(height: 16),
        Row(children: [
          _bannerChip('$_complets', 'Complets', _C.green, _C.greenLight, Icons.check_circle_rounded),
          const SizedBox(width: 10),
          _bannerChip('$_impayes', 'Impayes', _C.coral, _C.coralLight, Icons.cancel_rounded),
          const SizedBox(width: 10),
          _bannerChip('${_total - _complets - _impayes}', 'Partiels', _C.amber, _C.amberLight, Icons.timelapse_rounded),
        ]),
      ]),
    );
  }

  Widget _bannerChip(String value, String label, Color color, Color bg, IconData icon) => Expanded(
    child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: color, size: 18), const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ]),
    ),
  );

  Widget _buildSearchBar() => Container(
    decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)),
    child: TextField(
      controller: _searchCtrl,
      style: const TextStyle(fontSize: 14, color: _C.dark),
      decoration: InputDecoration(
        hintText: 'Rechercher un resident...',
        hintStyle: const TextStyle(color: _C.textLight, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: _C.textLight, size: 20),
        suffixIcon: _searchCtrl.text.isNotEmpty ? GestureDetector(onTap: () { _searchCtrl.clear(); _applyFilter(); }, child: const Icon(Icons.close_rounded, color: _C.textLight, size: 18)) : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );

  Widget _buildFilterTabs() {
    final filters = [('tous', 'Tous', _total), ('complet', 'Complets', _complets), ('partiel', 'Partiels', _total - _complets - _impayes), ('impaye', 'Impayes', _impayes)];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: filters.map((f) {
        final isSelected = _filterStatut == f.$1;
        return GestureDetector(
          onTap: () => _setFilter(f.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: isSelected ? _C.coral : _C.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: isSelected ? _C.coral : _C.divider)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(f.$2, style: TextStyle(color: isSelected ? _C.white : _C.textMid, fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: isSelected ? Colors.white.withValues(alpha: 0.25) : _C.bg, borderRadius: BorderRadius.circular(10)),
                  child: Text('${f.$3}', style: TextStyle(color: isSelected ? _C.white : _C.textLight, fontSize: 11, fontWeight: FontWeight.w700))),
            ]),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildSectionLabel(String text) => Text(text, style: const TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.3));

  Widget _buildResidentCard(ResidentModel r) {
    final pct = r.pourcentagePaiement;
    final Color barColor = pct >= 1.0 ? _C.green : pct > 0 ? _C.orange : _C.coral;
    final Color barBg    = pct >= 1.0 ? _C.greenLight : pct > 0 ? _C.orangeLight : _C.coralLight;
    final bool isProp    = r.type == 'proprietaire';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: isProp ? _C.blueLight : _C.amberLight, borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(r.nomComplet.isNotEmpty ? r.nomComplet[0].toUpperCase() : '?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isProp ? _C.blue : _C.amber)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.nomComplet, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _C.dark, letterSpacing: -0.2)),
            const SizedBox(height: 3),
            Row(children: [const Icon(Icons.location_on_rounded, size: 11, color: _C.textLight), const SizedBox(width: 3), Expanded(child: Text(r.adresseAppart, style: const TextStyle(color: _C.textLight, fontSize: 11), overflow: TextOverflow.ellipsis))]),
          ])),
          const SizedBox(width: 8),
          _typeBadge(r.type),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Paiement ${r.anneePaiement}', style: const TextStyle(color: _C.textMid, fontSize: 12, fontWeight: FontWeight.w500)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: barBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(pct >= 1.0 ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: barColor, size: 11),
                    const SizedBox(width: 4),
                    Text('${(pct * 100).toInt()}%', style: TextStyle(color: barColor, fontWeight: FontWeight.w700, fontSize: 11)),
                  ])),
            ]),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: pct.clamp(0.0, 1.0), backgroundColor: _C.divider, valueColor: AlwaysStoppedAnimation(barColor), minHeight: 6)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _amountChip('Paye', '${r.montantPaye.toInt()} DH', _C.greenLight, _C.green),
              _amountChip('Reste', '${r.resteAPayer.toInt()} DH', _C.coralLight, _C.coral),
              _amountChip('Total', '${r.montantTotal.toInt()} DH', _C.iconBg, _C.textMid),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => _showPaiementDialog(r), child: Container(padding: const EdgeInsets.symmetric(vertical: 11), decoration: BoxDecoration(color: _C.coral, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.payments_rounded, size: 15, color: _C.white), SizedBox(width: 6), Text('Payer', style: TextStyle(color: _C.white, fontWeight: FontWeight.w700, fontSize: 13))])))),
          const SizedBox(width: 8),
          _iconBtn(Icons.history_rounded, _C.blueLight, _C.blue, () => _showHistoriqueDialog(r)),
          const SizedBox(width: 8),
          _iconBtn(Icons.edit_rounded, _C.iconBg, _C.textMid, () => _showEditDialog(r)),
          const SizedBox(width: 8),
          _iconBtn(Icons.delete_rounded, _C.coralLight, _C.coral, () => _showDeleteConfirm(r)),
        ]),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, Color bg, Color fg, VoidCallback onTap) => GestureDetector(onTap: onTap,
      child: Container(width: 40, height: 40, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: fg, size: 17)));

  Widget _amountChip(String label, String value, Color bg, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: _C.textLight, fontSize: 10, fontWeight: FontWeight.w500)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    ]),
  );

  Widget _typeBadge(String type) {
    final isProp = type == 'proprietaire';
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: isProp ? _C.blueLight : _C.amberLight, borderRadius: BorderRadius.circular(20)),
        child: Text(isProp ? 'Proprietaire' : 'Locataire', style: TextStyle(color: isProp ? _C.blue : _C.amber, fontSize: 10, fontWeight: FontWeight.w700)));
  }

  // ═══════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════

  Widget _dialogHeader(BuildContext ctx, String title, {IconData? icon, Color? iconColor}) => Row(children: [
    if (icon != null) ...[Container(width: 36, height: 36, decoration: BoxDecoration(color: (iconColor ?? _C.coral).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor ?? _C.coral, size: 18)), const SizedBox(width: 12)],
    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _C.dark))),
    GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(width: 30, height: 30, decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _C.divider)), child: const Icon(Icons.close_rounded, size: 15, color: _C.textMid))),
  ]);

  Widget _errorBanner(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [const Icon(Icons.error_outline_rounded, color: _C.coral, size: 16), const SizedBox(width: 8), Expanded(child: Text(msg, style: const TextStyle(color: _C.coral, fontSize: 12)))]),
  );

  Widget _infoBanner(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [const Icon(Icons.info_outline_rounded, color: _C.green, size: 16), const SizedBox(width: 8), Expanded(child: Text(msg, style: const TextStyle(color: _C.green, fontSize: 12, fontWeight: FontWeight.w500)))]),
  );

  Widget _dialogActions({required BuildContext ctx, required bool saving, required String confirmLabel, required Color confirmColor, required VoidCallback onConfirm}) => Row(children: [
    Expanded(child: GestureDetector(onTap: saving ? null : () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)), child: const Text('Annuler', textAlign: TextAlign.center, style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 14))))),
    const SizedBox(width: 12),
    Expanded(child: GestureDetector(onTap: saving ? null : onConfirm, child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: saving ? confirmColor.withValues(alpha: 0.5) : confirmColor, borderRadius: BorderRadius.circular(12)),
        child: saving ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _C.white, strokeWidth: 2))) : Text(confirmLabel, textAlign: TextAlign.center, style: const TextStyle(color: _C.white, fontWeight: FontWeight.w700, fontSize: 14))))),
  ]);

  Widget _infoRow(String label, String value, Color color, {bool bold = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Text(label, style: const TextStyle(color: _C.textMid, fontSize: 13)), Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: 14))],
  );

  // ────────────────────────────────────────────────────────────────
  // DIALOG : Enregistrer un paiement
  // Charge dynamiquement charges + parking/box/garage si bénéficiaire
  // ────────────────────────────────────────────────────────────────
  void _showPaiementDialog(ResidentModel r) {
    if (r.appartementId == null) return;

    List<PaiementModel> lignes = [];
    PaiementModel? selectedPaiement;
    bool loadingLignes = true;
    String? errorMsg;
    bool saving = false;
    final montantCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          // Chargement unique des lignes de paiement + ressources
          if (loadingLignes) {
            loadingLignes = false;
            _service.getPaiementsAvecRessources(
              residentUserId: r.userId,
              appartementId: r.appartementId!,
            ).then((data) {
              if (ctx.mounted) {
                setDialog(() {
                  lignes = data;
                  // Pré-sélectionner "charges" par défaut
                  selectedPaiement = lignes.firstWhere(
                        (p) => p.typePaiement == TypePaiementEnum.charges,
                    orElse: () => lignes.isNotEmpty ? lignes.first : selectedPaiement!,
                  );
                });
              }
            });
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                _dialogHeader(ctx, 'Enregistrer Paiement', icon: Icons.payments_rounded, iconColor: _C.coral),
                const SizedBox(height: 18),

                // ── Carte résident
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)),
                  child: Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text(r.nomComplet.isNotEmpty ? r.nomComplet[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _C.coral)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.nomComplet, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _C.dark)),
                      Text(r.adresseAppart, style: const TextStyle(color: _C.textLight, fontSize: 11)),
                    ])),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Sélection de la ligne de paiement
                _label('Ligne de paiement *'),
                const SizedBox(height: 6),
                lignes.isEmpty
                    ? Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: const [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: _C.coral, strokeWidth: 2)), SizedBox(width: 12), Text('Chargement des lignes...', style: TextStyle(color: _C.textLight, fontSize: 13))]))
                    : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.divider)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PaiementModel>(
                      value: selectedPaiement,
                      isExpanded: true,
                      onChanged: (val) => setDialog(() { selectedPaiement = val; montantCtrl.clear(); errorMsg = null; }),
                      items: lignes.map((p) {
                        final color = _typeColor(p.typePaiement);
                        return DropdownMenuItem<PaiementModel>(
                          value: p,
                          child: Row(children: [
                            Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(_typeIcon(p.typePaiement), color: color, size: 15)),
                            const SizedBox(width: 10),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                              Text('${_typeLabel(p.typePaiement)} — ${p.annee}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              Text('Reste : ${p.resteAPayer.toInt()} DH', style: TextStyle(fontSize: 11, color: p.resteAPayer > 0 ? _C.coral : _C.green, fontWeight: FontWeight.w600)),
                            ]),
                          ]),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Récapitulatif de la ligne sélectionnée
                if (selectedPaiement != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _typeColor(selectedPaiement!.typePaiement).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _typeColor(selectedPaiement!.typePaiement).withValues(alpha: 0.2)),
                    ),
                    child: Column(children: [
                      Row(children: [
                        Icon(_typeIcon(selectedPaiement!.typePaiement), color: _typeColor(selectedPaiement!.typePaiement), size: 16),
                        const SizedBox(width: 8),
                        Text(_typeLabel(selectedPaiement!.typePaiement), style: TextStyle(color: _typeColor(selectedPaiement!.typePaiement), fontWeight: FontWeight.w700, fontSize: 13)),
                      ]),
                      const SizedBox(height: 10),
                      _infoRow('Total', '${selectedPaiement!.montantTotal.toInt()} DH', _C.dark),
                      const SizedBox(height: 6),
                      _infoRow('Payé', '${selectedPaiement!.montantPaye.toInt()} DH', _C.green),
                      const SizedBox(height: 6),
                      _infoRow('Reste à payer', '${selectedPaiement!.resteAPayer.toInt()} DH', _C.coral, bold: true),
                    ]),
                  ),
                  const SizedBox(height: 14),
                ],

                if (errorMsg != null) _errorBanner(errorMsg!),
                _label('Montant à enregistrer (DH)'),
                _field(montantCtrl, 'ex: 1500', inputType: TextInputType.number),
                const SizedBox(height: 22),

                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Enregistrer',
                  confirmColor: _C.coral,
                  onConfirm: () async {
                    final montant = double.tryParse(montantCtrl.text.trim()) ?? 0;
                    if (montant <= 0) { setDialog(() => errorMsg = 'Entrez un montant valide'); return; }
                    if (selectedPaiement == null) { setDialog(() => errorMsg = 'Sélectionnez une ligne de paiement'); return; }
                    if (montant > selectedPaiement!.resteAPayer) {
                      setDialog(() => errorMsg = 'Montant supérieur au reste dû (${selectedPaiement!.resteAPayer.toInt()} DH)');
                      return;
                    }
                    setDialog(() { saving = true; errorMsg = null; });
                    final err = await _service.enregistrerPaiement(
                      paiementId: selectedPaiement!.id,
                      residentUserId: r.userId,
                      montantAjoute: montant,
                      montantDejaPane: selectedPaiement!.montantPaye,
                      montantTotal: selectedPaiement!.montantTotal,
                      typePaiement: selectedPaiement!.typePaiement.name,
                    );
                    if (!ctx.mounted) return;
                    if (err != null) { setDialog(() { errorMsg = err; saving = false; }); }
                    else { Navigator.pop(ctx); _load(); }
                  },
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // DIALOG : Ajouter un résident
  // ────────────────────────────────────────────────────────────────
  void _showAddResidentDialog() {
    final prenomCtrl   = TextEditingController();
    final nomCtrl      = TextEditingController();
    final emailCtrl    = TextEditingController();
    final telCtrl      = TextEditingController();
    final passwordCtrl = TextEditingController();
    String type = 'proprietaire';
    String? errorMsg;
    bool saving = false;
    List<Map<String, dynamic>> appartementsLibres = [];
    int? selectedAppartId;
    bool loadingApparts = true;
    double? montantCalcule;
    bool loadingMontant = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
        if (loadingApparts) {
          loadingApparts = false;
          _service.getAppartementsLibres(widget.trancheId).then((list) { if (ctx.mounted) setDialog(() => appartementsLibres = list); });
          _service.calculerMontantAnnuelTranche(widget.trancheId).then((m) { if (ctx.mounted) setDialog(() { montantCalcule = m; loadingMontant = false; }); });
        }
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _dialogHeader(ctx, 'Ajouter Resident', icon: Icons.person_add_rounded, iconColor: _C.coral),
            const SizedBox(height: 20),
            if (errorMsg != null) _errorBanner(errorMsg!),
            _label('Prenom *'), _field(prenomCtrl, 'ex: Ahmed'), const SizedBox(height: 14),
            _label('Nom *'), _field(nomCtrl, 'ex: Bennani'), const SizedBox(height: 14),
            _label('Email *'), _field(emailCtrl, 'ex: ahmed@example.com', inputType: TextInputType.emailAddress), const SizedBox(height: 14),
            _label('Telephone'), _field(telCtrl, 'ex: 0612345678', inputType: TextInputType.phone), const SizedBox(height: 14),
            _label('Mot de passe *'), _passwordField(passwordCtrl),
            const SizedBox(height: 4),
            const Text('Le résident utilisera ce mot de passe pour se connecter à son espace.', style: TextStyle(color: _C.textLight, fontSize: 11)),
            const SizedBox(height: 14),
            _label('Appartement *'),
            appartementsLibres.isEmpty
                ? Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10)), child: const Text('Aucun appartement libre', style: TextStyle(color: _C.textLight)))
                : Container(padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.divider)),
                child: DropdownButtonHideUnderline(child: DropdownButton<int>(isExpanded: true, hint: const Text('Selectionner un appartement', style: TextStyle(color: _C.textLight, fontSize: 13)), value: selectedAppartId,
                    items: appartementsLibres.map((a) => DropdownMenuItem<int>(value: a['id'] as int, child: Text(a['label'].toString()))).toList(),
                    onChanged: (val) => setDialog(() => selectedAppartId = val)))),
            const SizedBox(height: 14),
            _label('Montant annuel (DH)'),
            loadingMontant
                ? Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10)),
                child: Row(children: const [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: _C.coral, strokeWidth: 2)), SizedBox(width: 12), Text('Calcul en cours...', style: TextStyle(color: _C.textLight, fontSize: 13))]))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.green.withValues(alpha: 0.3))),
                child: Row(children: [
                  const Icon(Icons.calculate_rounded, color: _C.green, size: 18), const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${(montantCalcule ?? 0).toStringAsFixed(2)} DH', style: const TextStyle(color: _C.green, fontWeight: FontWeight.w800, fontSize: 16)),
                    const Text('Total dépenses tranche ÷ nb appartements', style: TextStyle(color: _C.green, fontSize: 10, fontWeight: FontWeight.w500)),
                  ]),
                ]),
              ),
              if ((montantCalcule ?? 0) == 0) ...[const SizedBox(height: 6), _infoBanner('Aucune dépense enregistrée pour cette tranche cette année. Le montant sera 0 DH.')],
            ]),
            const SizedBox(height: 14),
            _label('Type *'),
            Row(children: [
              Expanded(child: GestureDetector(onTap: () => setDialog(() => type = 'proprietaire'), child: _typeToggle('Proprietaire', type == 'proprietaire', _C.blue))),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(onTap: () => setDialog(() => type = 'locataire'), child: _typeToggle('Locataire', type == 'locataire', _C.amber))),
            ]),
            const SizedBox(height: 24),
            _dialogActions(
              ctx: ctx, saving: saving, confirmLabel: 'Ajouter', confirmColor: _C.coral,
              onConfirm: () async {
                if (prenomCtrl.text.trim().isEmpty || nomCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) { setDialog(() => errorMsg = 'Prenom, Nom et Email obligatoires'); return; }
                if (passwordCtrl.text.length < 6) { setDialog(() => errorMsg = 'Le mot de passe doit avoir au moins 6 caractères'); return; }
                if (selectedAppartId == null) { setDialog(() => errorMsg = 'Selectionnez un appartement'); return; }
                if (loadingMontant) { setDialog(() => errorMsg = 'Calcul du montant en cours...'); return; }
                setDialog(() { saving = true; errorMsg = null; });
                final err = await _service.addResident(
                  nom: nomCtrl.text, prenom: prenomCtrl.text, email: emailCtrl.text,
                  telephone: telCtrl.text.isEmpty ? null : telCtrl.text,
                  password: passwordCtrl.text, type: type,
                  trancheId: widget.trancheId, appartementId: selectedAppartId!, montantTotal: montantCalcule ?? 0.0,
                );
                if (!ctx.mounted) return;
                if (err != null) { setDialog(() { errorMsg = err; saving = false; }); }
                else { Navigator.pop(ctx); _load(); }
              },
            ),
          ]))),
        );
      }),
    );
  }

  // ── History Dialog
  void _showHistoriqueDialog(ResidentModel r) {
    List<Map<String, dynamic>> historique = [];
    bool loadingHist = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
        if (loadingHist) { loadingHist = false; _service.getHistoriquePaiements(r.userId).then((data) { if (ctx.mounted) setDialog(() => historique = data); }); }
        final pct = r.pourcentagePaiement;
        final Color barColor = pct >= 1.0 ? _C.green : pct > 0 ? _C.orange : _C.coral;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _dialogHeader(ctx, 'Historique', icon: Icons.history_rounded, iconColor: _C.blue),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(r.nomComplet, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _C.dark)),
                Text('${(pct * 100).toInt()}% payé', style: TextStyle(color: barColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: pct.clamp(0.0, 1.0), backgroundColor: _C.divider, valueColor: AlwaysStoppedAnimation(barColor), minHeight: 6)),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_infoRow('Paye', '${r.montantPaye.toInt()} DH', _C.green), _infoRow('Reste', '${r.resteAPayer.toInt()} DH', _C.coral)]),
            ])),
            const SizedBox(height: 16),
            Container(height: 1, color: _C.divider),
            const SizedBox(height: 12),
            historique.isEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [Icon(Icons.history_rounded, color: _C.divider, size: 40), const SizedBox(height: 8), const Text('Aucun historique', style: TextStyle(color: _C.textLight))])))
                : ConstrainedBox(constraints: const BoxConstraints(maxHeight: 220), child: ListView.separated(
              shrinkWrap: true,
              itemCount: historique.length,
              separatorBuilder: (_, __) => Container(height: 1, color: _C.divider),
              itemBuilder: (_, i) {
                final h = historique[i];
                final montant = double.parse(h['montant'].toString()).toInt();
                final type = h['type']?.toString() ?? 'charges';
                final tEnum = TypePaiementEnum.values.firstWhere((e) => e.name == type, orElse: () => TypePaiementEnum.charges);
                return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: _typeColor(tEnum).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(_typeIcon(tEnum), color: _typeColor(tEnum), size: 16)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(h['description'] ?? 'Paiement', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _C.dark)),
                    Text(h['date']?.toString() ?? '', style: const TextStyle(color: _C.textLight, fontSize: 11)),
                  ])),
                  Text('+$montant DH', style: const TextStyle(color: _C.green, fontWeight: FontWeight.w800, fontSize: 14)),
                ]));
              },
            )),
            const SizedBox(height: 16),
            GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)), child: const Text('Fermer', textAlign: TextAlign.center, style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 14)))),
          ])),
        );
      }),
    );
  }

  // ── Edit Dialog
  void _showEditDialog(ResidentModel r) {
    final nomCtrl = TextEditingController(text: r.nom);
    final prenomCtrl = TextEditingController(text: r.prenom);
    final telCtrl = TextEditingController(text: r.telephone ?? '');
    String type = r.type;
    bool saving = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _dialogHeader(ctx, 'Modifier Resident', icon: Icons.edit_rounded, iconColor: _C.blue),
          const SizedBox(height: 20),
          _label('Prenom'), _field(prenomCtrl, ''), const SizedBox(height: 14),
          _label('Nom'), _field(nomCtrl, ''), const SizedBox(height: 14),
          _label('Telephone'), _field(telCtrl, '', inputType: TextInputType.phone), const SizedBox(height: 14),
          _label('Type'),
          Row(children: [
            Expanded(child: GestureDetector(onTap: () => setDialog(() => type = 'proprietaire'), child: _typeToggle('Proprietaire', type == 'proprietaire', _C.blue))),
            const SizedBox(width: 8),
            Expanded(child: GestureDetector(onTap: () => setDialog(() => type = 'locataire'), child: _typeToggle('Locataire', type == 'locataire', _C.amber))),
          ]),
          const SizedBox(height: 24),
          _dialogActions(ctx: ctx, saving: saving, confirmLabel: 'Enregistrer', confirmColor: _C.blue, onConfirm: () async {
            setDialog(() => saving = true);
            await _service.updateResident(userId: r.userId, nom: nomCtrl.text, prenom: prenomCtrl.text, telephone: telCtrl.text.isEmpty ? null : telCtrl.text, type: type);
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            _load();
          }),
        ])),
      )),
    );
  }

  // ── Delete Dialog
  void _showDeleteConfirm(ResidentModel r) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.person_remove_rounded, color: _C.coral, size: 26)),
          const SizedBox(height: 16),
          const Text('Confirmer la suppression', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _C.dark)),
          const SizedBox(height: 8),
          Text('Supprimer ${r.nomComplet} de la liste ?', textAlign: TextAlign.center, style: const TextStyle(color: _C.textMid, fontSize: 13)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)), child: const Text('Annuler', textAlign: TextAlign.center, style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 14))))),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(onTap: () async { await _service.deleteResident(r.userId, r.appartementId); if (!ctx.mounted) return; Navigator.pop(ctx); _load(); },
                child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _C.coral, borderRadius: BorderRadius.circular(12)), child: const Text('Supprimer', textAlign: TextAlign.center, style: TextStyle(color: _C.white, fontWeight: FontWeight.w700, fontSize: 14))))),
          ]),
        ])),
      ),
    );
  }

  // ── Helpers
  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _C.textMid)));

  Widget _field(TextEditingController ctrl, String hint, {TextInputType inputType = TextInputType.text}) => TextField(
    controller: ctrl, keyboardType: inputType,
    style: const TextStyle(fontSize: 14, color: _C.dark),
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: _C.textLight, fontSize: 13),
      filled: true, fillColor: _C.bg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.coral, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
  );

  Widget _passwordField(TextEditingController ctrl) => StatefulBuilder(
    builder: (ctx, setLocal) {
      bool obscure = true;
      return StatefulBuilder(builder: (ctx2, setLocal2) => TextField(
        controller: ctrl, obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: _C.dark),
        decoration: InputDecoration(
          hintText: 'Min. 6 caractères', hintStyle: const TextStyle(color: _C.textLight, fontSize: 13),
          filled: true, fillColor: _C.bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.coral, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          suffixIcon: GestureDetector(onTap: () => setLocal2(() => obscure = !obscure), child: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: _C.textLight, size: 18)),
        ),
      ));
    },
  );

  Widget _typeToggle(String label, bool selected, Color accent) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: selected ? accent.withValues(alpha: 0.1) : _C.bg, border: Border.all(color: selected ? accent : _C.divider, width: selected ? 1.5 : 1), borderRadius: BorderRadius.circular(10)),
    child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? accent : _C.textMid, fontWeight: FontWeight.w700, fontSize: 13)),
  );
}