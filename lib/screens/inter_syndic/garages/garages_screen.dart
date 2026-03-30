import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/garage_model.dart';
import '../../../models/resident_model.dart';
import '../../../services/garage_service.dart';
import '../../../services/resident_service.dart';
import '../../../theme/inter_syndic_palette.dart';
import '../../../widgets/inter_syndic_header.dart';

class GaragesScreen extends StatefulWidget {
  final int trancheId;
  final int? residenceId;
  final String? trancheName;
  final String? residenceName;

  const GaragesScreen({
    super.key,
    required this.trancheId,
    this.residenceId,
    this.trancheName,
    this.residenceName,
  });

  @override
  State<GaragesScreen> createState() => _GaragesScreenState();
}

class _GaragesScreenState extends State<GaragesScreen> {
  final _service = GarageService();
  final _searchCtrl = TextEditingController();

  List<GarageModel> _garages = [];
  List<GarageModel> _filtered = [];
  bool _loading = true;
  String _filterStatut = 'tous';
  double _prixAnnuelUnitaire = 600;

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
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final list = await _service.getGaragesByTranche(widget.trancheId);
      if (!mounted) return;
      setState(() {
        _garages = list;
        if (list.isNotEmpty) {
          _prixAnnuelUnitaire = list.first.prixAnnuel;
        }
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = _garages.where((p) {
        final matchSearch = p.numero.toLowerCase().contains(q) ||
            (p.beneficiaireNom?.toLowerCase().contains(q) ?? false);
        final matchStatut = _filterStatut == 'tous' || p.statut == _filterStatut;
        return matchSearch && matchStatut;
      }).toList();
    });
  }

  void _setFilter(String f) {
    setState(() => _filterStatut = f);
    _applyFilter();
  }

  int get _total => _garages.length;
  int get _disponibles => _garages.where((p) => p.statut == 'disponible').length;
  int get _occupes => _garages.where((p) => p.statut == 'occupe').length;
  double get _revenusAn => _garages.fold(0, (sum, p) => sum + p.prixAnnuel);

  void _callResident(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  bool showFilters = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InterSyndicPalette.bg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: InterSyndicHeader(
                  title: 'ResiManager',
                  subtitle: 'Gestion Garages',
                  gridIcon: Icons.garage_rounded,
                  onBack: () => Navigator.pop(context),
                  onAdd: _showAddGarageDialog,
                  addLabel: 'Ajouter',
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHeroStatsCard(_total, _occupes, _disponibles, _revenusAn),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _buildInfoRow(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: InterSyndicPalette.divider),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            // onChanged: (_) => _applyFilter(), already has a listener in initState so no need
                            decoration: InputDecoration(
                              hintText: 'Rechercher un garage...',
                              hintStyle: const TextStyle(color: InterSyndicPalette.textLight),
                              prefixIcon: const Icon(Icons.search_rounded, color: InterSyndicPalette.textLight),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            color: showFilters ? InterSyndicPalette.orange : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (showFilters ? InterSyndicPalette.orange : Colors.black).withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: showFilters ? InterSyndicPalette.orange : InterSyndicPalette.divider),
                          ),
                          child: Icon(
                            showFilters ? Icons.filter_list_off : Icons.filter_list, 
                            color: showFilters ? Colors.white : InterSyndicPalette.darkMid,
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildFilterTabs(),
                  ),
                ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: InterSyndicPalette.orange)),
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
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildGarageCard(_filtered[index]),
                      ),
                      childCount: _filtered.length,
                    ),
                  ),
                ),
            ],
          ),
          
          if (_loading)
            Container(
              color: Colors.white.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator(color: InterSyndicPalette.orange)),
            ),
        ],
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
              color: InterSyndicPalette.divider.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.garage_rounded, size: 80, color: InterSyndicPalette.textLight.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun garage trouvé', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: InterSyndicPalette.darkMid),
          ),
          const SizedBox(height: 8),
          const Text(
            'Essayez de modifier vos filtres ou d\'ajouter un garage', 
            style: TextStyle(fontSize: 14, color: InterSyndicPalette.textLight),
          ),
          const SizedBox(height: 24),
          if (_searchCtrl.text.isNotEmpty || _filterStatut != 'tous')
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchCtrl.clear();
                  _filterStatut = 'tous';
                  _applyFilter();
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réinitialiser tout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: InterSyndicPalette.orange,
                side: const BorderSide(color: InterSyndicPalette.orange),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroStatsCard(int total, int occupied, int vacant, double revenus) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: InterSyndicPalette.orange,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: InterSyndicPalette.orange.withOpacity(0.25),
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
                    'Garages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '$total garages au total',
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
                    const Icon(Icons.garage_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    const Text(
                      'Gestion locale',
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
                '${total > 0 ? ((occupied / total) * 100).toInt() : 0}% occupés',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
               Text(
                '${revenus.toInt()} DH / an',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? (occupied / total) : 0,
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
                _buildHeroStatMiniItem(occupied.toString().padLeft(2, '0'), 'Occupés'),
                _buildHeroStatDivider(),
                _buildHeroStatMiniItem(vacant.toString().padLeft(2, '0'), 'Vacants'),
                _buildHeroStatDivider(),
                _buildHeroStatMiniItem('${revenus.toInt()}', 'DH/an'),
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

  // ── Info Card (Resident Style)
  Widget _buildInfoRow() {
    return _infoCard(
      icon: Icons.monetization_on_rounded,
      iconColor: InterSyndicPalette.orange,
      iconBg: InterSyndicPalette.orange.withOpacity(0.1),
      label: 'Prix unitaire / an',
      value: '${_prixAnnuelUnitaire.toInt()} DH',
      onTap: _showEditPrixAnnuelDialog,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: InterSyndicPalette.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.edit_rounded, size: 12, color: InterSyndicPalette.orange),
            SizedBox(width: 4),
            Text('Modifier',
                style: TextStyle(
                    color: InterSyndicPalette.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
      {required IconData icon,
      required Color iconColor,
      required Color iconBg,
      required String label,
      required String value,
      VoidCallback? onTap,
      Widget? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: InterSyndicPalette.divider),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Row(children: [
          Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        color: InterSyndicPalette.textLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: InterSyndicPalette.dark,
                        fontWeight: FontWeight.w900,
                        fontSize: 17)),
              ])),
          if (trailing != null) trailing,
        ]),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      ('tous', 'Tous', _total),
      ('disponible', 'Dispos', _disponibles),
      ('occupe', 'Occupés', _occupes),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _filterStatut == f.$1;
          const selectedColor = InterSyndicPalette.orange;
          
          return GestureDetector(
            onTap: () => _setFilter(f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: selectedColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
                border: Border.all(color: isSelected ? selectedColor : InterSyndicPalette.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f.$2,
                    style: TextStyle(
                        color: isSelected ? Colors.white : InterSyndicPalette.textMid,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.2) : InterSyndicPalette.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${f.$3}',
                      style: TextStyle(
                          color: isSelected ? Colors.white : InterSyndicPalette.textMid,
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

  Widget _buildGarageCard(GarageModel p) {
    final isOccupe = p.statut == 'occupe';
    final statusColor = isOccupe ? InterSyndicPalette.coral : InterSyndicPalette.green;
    final statusBg = isOccupe ? InterSyndicPalette.coralLight : InterSyndicPalette.greenLight;
    final statusLabel = isOccupe ? 'Occupé' : 'Disponible';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: InterSyndicPalette.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: InterSyndicPalette.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.garage_rounded, color: InterSyndicPalette.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(p.numero,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: InterSyndicPalette.dark, letterSpacing: -0.4)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                          child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${p.prixAnnuel.toInt()} DH / an',
                        style: const TextStyle(color: InterSyndicPalette.coral, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          if (isOccupe) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: InterSyndicPalette.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: InterSyndicPalette.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.person_rounded, size: 14, color: InterSyndicPalette.textMid),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p.beneficiairePrenom ?? ''} ${p.beneficiaireNom ?? 'Inconnu'}'.trim(),
                          style: const TextStyle(color: InterSyndicPalette.dark, fontSize: 13, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text('Résident assigné', style: TextStyle(color: InterSyndicPalette.textLight, fontSize: 10, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (isOccupe)
                Expanded(child: _buildIconActionBtn(Icons.phone_rounded, InterSyndicPalette.blue, () => _callResident(p.beneficiaireTelephone))),
              if (isOccupe) const SizedBox(width: 6),
              Expanded(child: _buildIconActionBtn(Icons.edit_rounded, InterSyndicPalette.darkMid, () => _showEditGarageDialog(p))),
              const SizedBox(width: 6),
              Expanded(
                child: _buildIconActionBtn(
                  isOccupe ? Icons.person_remove_rounded : Icons.person_add_rounded,
                  isOccupe ? InterSyndicPalette.coral : InterSyndicPalette.green,
                  isOccupe ? () => _showLiberDialog(p) : () => _showAssignerDialog(p),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: _buildIconActionBtn(Icons.delete_outline_rounded, InterSyndicPalette.red, () => _showDeleteDialog(p))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconActionBtn(IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // ══════════════════════════════════════
  // DIALOGS
  // ══════════════════════════════════════

  void _showEditPrixAnnuelDialog() {
    final prixCtrl = TextEditingController(text: _prixAnnuelUnitaire.toInt().toString());
    bool updateAll = false;
    bool saving = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogHeader(ctx, 'Prix Unitaire', icon: Icons.payments_rounded),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),
                _label('Nouveau prix annuel (DH)'),
                _field(prixCtrl, 'ex: 600', inputType: TextInputType.number),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Switch.adaptive(
                      value: updateAll,
                      onChanged: (v) => setDialog(() => updateAll = v),
                      activeColor: InterSyndicPalette.coral,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Appliquer à tous les garages de cette tranche',
                        style: TextStyle(fontSize: 13, color: InterSyndicPalette.darkMid, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Enregistrer',
                  confirmColor: InterSyndicPalette.coral,
                  onConfirm: () async {
                    final newPrice = double.tryParse(prixCtrl.text.trim());
                    if (newPrice == null || newPrice <= 0) {
                      setDialog(() => errorMsg = 'Veuillez entrer un prix valide');
                      return;
                    }
                    setDialog(() => saving = true);
                    if (updateAll) {
                      final err = await _service.updateAllGaragesPrice(widget.trancheId, newPrice);
                      if (err != null) {
                        setDialog(() { errorMsg = err; saving = false; });
                        return;
                      }
                    }
                    setState(() => _prixAnnuelUnitaire = newPrice);
                    Navigator.pop(ctx);
                    _load();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddGarageDialog() {
    final resIdCtrl = TextEditingController(text: widget.residenceName ?? '');
    final trancheIdCtrl = TextEditingController(text: widget.trancheName ?? '');
    final numeroCtrl = TextEditingController();
    final prixCtrl = TextEditingController(text: _prixAnnuelUnitaire.toInt().toString());
    bool estOccupe = false;
    ResidentModel? selectedResident;
    String? errorMsg;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogHeader(ctx, 'Ajouter Garage', icon: Icons.garage_rounded, iconColor: InterSyndicPalette.orange),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),
                
                _label('Codification du garage *'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _field(resIdCtrl, 'Résidence', prefix: 'R')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(trancheIdCtrl, 'Tranche', prefix: '-T')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(numeroCtrl, 'Num', prefix: '-G')),
                  ],
                ),
                const SizedBox(height: 16),
                
                _label('Prix annuel (DH) *'),
                _field(prixCtrl, 'ex: 600', inputType: TextInputType.number),
                const SizedBox(height: 16),
                
                _label('Statut initial'),
                Row(
                  children: [
                    Expanded(child: GestureDetector(onTap: () => setDialog(() => estOccupe = false), child: _typeBtn('Disponible', !estOccupe, InterSyndicPalette.green))),
                    const SizedBox(width: 12),
                    Expanded(child: GestureDetector(onTap: () => setDialog(() => estOccupe = true), child: _typeBtn('Occupé', estOccupe, InterSyndicPalette.coral))),
                  ],
                ),
                if (estOccupe) ...[
                  const SizedBox(height: 16),
                  _label('Assigner à un résident *'),
                  _residentAutocomplete((r) => setDialog(() => selectedResident = r)),
                ],
                const SizedBox(height: 32),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Ajouter',
                  confirmColor: InterSyndicPalette.coral,
                  onConfirm: () async {
                    if (resIdCtrl.text.isEmpty || trancheIdCtrl.text.isEmpty || numeroCtrl.text.isEmpty || prixCtrl.text.isEmpty) {
                      setDialog(() => errorMsg = 'La codification doit être complète.');
                      return;
                    }
                    if (estOccupe && selectedResident == null) {
                      setDialog(() => errorMsg = 'Veuillez sélectionner un résident');
                      return;
                    }
                    setDialog(() => saving = true);
                    
                    final String theGeneratedNumber = 'R${resIdCtrl.text.trim()}-T${trancheIdCtrl.text.trim()}-G${numeroCtrl.text.trim()}';
                    
                    String? err;
                    if (estOccupe) {
                      err = await _service.addGarageWithAssignment(
                        numero: theGeneratedNumber,
                        trancheId: widget.trancheId,
                        residenceId: widget.residenceId ?? 1,
                        prixAnnuel: double.tryParse(prixCtrl.text) ?? 0,
                        nom: selectedResident!.nom,
                        prenom: selectedResident!.prenom,
                        telephone: selectedResident!.telephone,
                        residentId: selectedResident!.userId,
                      );
                    } else {
                      err = await _service.addGarage(
                        numero: theGeneratedNumber,
                        trancheId: widget.trancheId,
                        residenceId: widget.residenceId ?? 1,
                        prixAnnuel: double.tryParse(prixCtrl.text) ?? 0,
                      );
                    }
                    if (err != null) {
                      setDialog(() { errorMsg = err; saving = false; });
                    } else {
                      Navigator.pop(ctx);
                      _load();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditGarageDialog(GarageModel g) {
    String res = widget.residenceName ?? '';
    String tra = widget.trancheName ?? '';
    String num = g.numero;

    final match = RegExp(r'^R(.*?)-T(.*?)-G(.*)$').firstMatch(g.numero);
    if (match != null) {
      res = match.group(1) ?? res;
      tra = match.group(2) ?? tra;
      num = match.group(3) ?? num;
    }

    final resIdCtrl = TextEditingController(text: res);
    final trancheIdCtrl = TextEditingController(text: tra);
    final numeroCtrl = TextEditingController(text: num);
    final prixCtrl = TextEditingController(text: g.prixAnnuel.toInt().toString());
    
    String? errorMsg;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogHeader(ctx, 'Modifier Garage', icon: Icons.edit_rounded),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),
                
                _label('Codification du garage *'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _field(resIdCtrl, 'Résidence', prefix: 'R')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(trancheIdCtrl, 'Tranche', prefix: '-T')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(numeroCtrl, 'Num', prefix: '-G')),
                  ],
                ),
                
                const SizedBox(height: 16),
                _label('Prix annuel (DH) *'),
                _field(prixCtrl, 'ex: 600', inputType: TextInputType.number),
                const SizedBox(height: 32),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Enregistrer',
                  confirmColor: InterSyndicPalette.blue,
                  onConfirm: () async {
                    if (numeroCtrl.text.isEmpty) {
                      setDialog(() => errorMsg = 'Le numéro est obligatoire');
                      return;
                    }
                    setDialog(() => saving = true);
                    
                    final String theGeneratedNumber = 'R${resIdCtrl.text.trim()}-T${trancheIdCtrl.text.trim()}-G${numeroCtrl.text.trim()}';
                    
                    final err = await _service.updateGarage(
                      garageId: g.id,
                      numero: theGeneratedNumber,
                      prixAnnuel: double.tryParse(prixCtrl.text) ?? g.prixAnnuel,
                    );
                    if (err != null) {
                      setDialog(() { errorMsg = err; saving = false; });
                    } else {
                      Navigator.pop(ctx);
                      _load();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAssignerDialog(GarageModel g) {
    ResidentModel? selectedResident;
    String? errorMsg;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogHeader(ctx, 'Assigner Garage', icon: Icons.person_add_rounded, iconColor: InterSyndicPalette.green),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),
                _label('Garage: ${g.numero}'),
                const SizedBox(height: 16),
                _label('Choisir un résident *'),
                _residentAutocomplete((r) => setDialog(() => selectedResident = r)),
                const SizedBox(height: 32),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Confirmer',
                  confirmColor: InterSyndicPalette.green,
                  onConfirm: () async {
                    if (selectedResident == null) {
                      setDialog(() => errorMsg = 'Veuillez sélectionner un résident');
                      return;
                    }
                    setDialog(() => saving = true);
                    final err = await _service.assignerGarage(
                      garageId: g.id,
                      nom: selectedResident!.nom,
                      prenom: selectedResident!.prenom,
                      telephone: selectedResident!.telephone,
                      trancheId: widget.trancheId,
                      residentId: selectedResident!.userId,
                      type: 'garage'
                    );
                    if (err != null) {
                      setDialog(() { errorMsg = err; saving = false; });
                    } else {
                      Navigator.pop(ctx);
                      _load();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLiberDialog(GarageModel g) {
    bool saving = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogHeader(ctx, 'Libérer Garage', icon: Icons.person_remove_rounded),
                const SizedBox(height: 20),
                const Text('Voulez-vous libérer ce garage ?\nLe résident actuel ne sera plus associé.', textAlign: TextAlign.center, style: TextStyle(color: InterSyndicPalette.textMid, fontSize: 13)),
                const SizedBox(height: 24),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Libérer',
                  confirmColor: InterSyndicPalette.coral,
                  onConfirm: () async {
                    setDialog(() => saving = true);
                    await _service.libererGarage(g.id);
                    Navigator.pop(ctx);
                    _load();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(GarageModel g) {
    bool saving = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogHeader(ctx, 'Supprimer Garage', icon: Icons.delete_outline_rounded, iconColor: InterSyndicPalette.red),
                const SizedBox(height: 20),
                const Text('Action irréversible.\nVoulez-vous supprimer ce garage ?', textAlign: TextAlign.center, style: TextStyle(color: InterSyndicPalette.textMid, fontSize: 13)),
                const SizedBox(height: 24),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Supprimer',
                  confirmColor: InterSyndicPalette.red,
                  onConfirm: () async {
                    setDialog(() => saving = true);
                    final err = await _service.deleteGarage(g.id);
                    if (err != null) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                      setDialog(() => saving = false);
                    } else {
                      Navigator.pop(ctx);
                      _load();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── HELPERS
  Widget _dialogHeader(BuildContext ctx, String title, {IconData? icon, Color? iconColor}) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: (iconColor ?? InterSyndicPalette.coral).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor ?? InterSyndicPalette.coral, size: 20),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: InterSyndicPalette.dark, letterSpacing: -0.4))),
        GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: InterSyndicPalette.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: InterSyndicPalette.divider)),
            child: const Icon(Icons.close_rounded, size: 16, color: InterSyndicPalette.textMid),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: InterSyndicPalette.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: InterSyndicPalette.red.withOpacity(0.2))),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: InterSyndicPalette.red, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: InterSyndicPalette.red, fontSize: 12, fontWeight: FontWeight.w600))),
    ]),
  );

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: InterSyndicPalette.textMid)));

  Widget _field(TextEditingController ctrl, String hint, {String? prefix, bool readOnly = false, TextInputType inputType = TextInputType.text}) => TextField(
    controller: ctrl,
    readOnly: readOnly,
    keyboardType: inputType,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: InterSyndicPalette.dark),
    decoration: InputDecoration(
      prefixText: prefix,
      hintText: hint,
      hintStyle: const TextStyle(color: InterSyndicPalette.textLight, fontSize: 13),
      filled: true,
      fillColor: readOnly ? InterSyndicPalette.bg : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: InterSyndicPalette.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: InterSyndicPalette.coral, width: 1.5)),
      contentPadding: const EdgeInsets.all(14),
    ),
  );

  Widget _typeBtn(String label, bool active, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      color: active ? color.withOpacity(0.1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: active ? color : InterSyndicPalette.divider, width: active ? 1.5 : 1)
    ),
    child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? color : InterSyndicPalette.textMid, fontWeight: FontWeight.w800, fontSize: 13)),
  );

  Widget _dialogActions({required BuildContext ctx, required bool saving, required String confirmLabel, required Color confirmColor, required VoidCallback onConfirm}) => Row(children: [
    Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: InterSyndicPalette.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: InterSyndicPalette.divider)),
          child: const Text('Annuler', textAlign: TextAlign.center, style: TextStyle(color: InterSyndicPalette.darkMid, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: GestureDetector(
        onTap: saving ? null : onConfirm,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: confirmColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: confirmColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: saving
            ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
            : Text(confirmLabel, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        ),
      ),
    ),
  ]);

  Widget _residentAutocomplete(Function(ResidentModel) onSelected) {
    return Container(
      decoration: BoxDecoration(color: InterSyndicPalette.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: InterSyndicPalette.divider)),
      child: Autocomplete<ResidentModel>(
        optionsBuilder: (val) async {
          if (val.text.isEmpty) return const Iterable<ResidentModel>.empty();
          return await ResidentService().searchResidents(val.text, trancheId: widget.trancheId);
        },
        displayStringForOption: (o) => '${o.prenom} ${o.nom}',
        onSelected: onSelected,
        fieldViewBuilder: (ctx, ctrl, focus, onSub) => TextField(
          controller: ctrl,
          focusNode: focus,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: InterSyndicPalette.dark),
          decoration: const InputDecoration(
            hintText: 'Rechercher un résident...',
            hintStyle: TextStyle(color: InterSyndicPalette.textLight, fontSize: 13),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search_rounded, size: 18, color: InterSyndicPalette.textMid),
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}