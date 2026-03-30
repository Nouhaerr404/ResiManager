import 'package:flutter/material.dart';
import '../../../models/parking_model.dart';
import '../../../models/resident_model.dart';
import '../../../services/parking_service.dart';
import '../../../services/resident_service.dart';
import '../../../services/tranche_service.dart';
import '../../../widgets/inter_syndic_header.dart';
import '../../../theme/inter_syndic_palette.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Brand palette — aligned with ResiManager desktop app
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
}

class ParkingsScreen extends StatefulWidget {
  final int trancheId;
  final int? residenceId;
  final String? trancheName;
  final String? residenceName;

  const ParkingsScreen({
    super.key, 
    required this.trancheId,
    this.residenceId,
    this.trancheName,
    this.residenceName,
  });

  @override
  State<ParkingsScreen> createState() => _ParkingsScreenState();
}

class _ParkingsScreenState extends State<ParkingsScreen>
    with SingleTickerProviderStateMixin {
  final _service = ParkingService();
  List<ParkingModel> _parkings = [];
  List<ParkingModel> _filtered = [];
  bool _loading = true;
  String _filterStatut = 'tous';
  final _searchCtrl = TextEditingController();

  double _prixAnnuelUnitaire = 600.0;
  bool _loadingPrix = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
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
      final data = await _service
          .getParkingsByTranche(widget.trancheId)
          .timeout(const Duration(seconds: 15));
      setState(() {
        _parkings = data;
        _filtered = data;
        
        // Calculer le prix unitaire moyen pour l'affichage/défaut
        if (_parkings.isNotEmpty) {
          _prixAnnuelUnitaire = _parkings.first.prixAnnuel;
        }
        
        _loading = false;
        _loadingPrix = false;
      });
      _applyFilter();
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      debugPrint('>>> ERREUR load parkings: $e');
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _parkings.where((p) {
        final matchSearch = p.numero.toLowerCase().contains(q) ||
            (p.nomCompletBeneficiaire.toLowerCase().contains(q));
        final matchStatut =
            _filterStatut == 'tous' || p.statut.name == _filterStatut;
        return matchSearch && matchStatut;
      }).toList();
    });
  }

  void _setFilter(String f) {
    setState(() => _filterStatut = f);
    _applyFilter();
  }

  Future<void> _callResident(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Numéro de téléphone non disponible')),
        );
      }
      return;
    }
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de lancer l\'appel')),
        );
      }
    }
  }

  int get _total => _parkings.length;
  int get _disponibles =>
      _parkings.where((p) => p.statut.name == 'disponible').length;
  int get _occupes => _parkings.where((p) => p.statut.name == 'occupe').length;
  double get _revenus => _parkings
      .where((p) => p.statut.name == 'occupe')
      .fold(0.0, (s, p) => s + p.prixAnnuel);

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
              // 1. Header Premium
              SliverToBoxAdapter(
                child: InterSyndicHeader(
                  title: 'ResiManager',
                  subtitle: 'Gestion Parkings',
                  gridIcon: Icons.local_parking_rounded,
                  onBack: () => Navigator.pop(context),
                  onAdd: _showAddParkingDialog,
                  addLabel: 'Ajouter',
                ),
              ),

              // 2. Carte Héros de Statistiques
              SliverToBoxAdapter(
                child: _buildHeroStatsCard(_total, _occupes, _disponibles, _revenus),
              ),

              // 2b. Prix unitaire (Style Resident)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _buildInfoRow(),
                ),
              ),

              // 3. Barre de Recherche et Bouton Filtres
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
                            onChanged: (_) => _applyFilter(),
                            decoration: InputDecoration(
                              hintText: 'Rechercher un parking...',
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

              // 4. Filtres (Optionnel)
              if (showFilters)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildFilterTabs(),
                  ),
                ),

              // 5. Liste des parkings
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
                        child: _buildParkingCard(_filtered[index]),
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

  Widget _buildLoader() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: InterSyndicPalette.orange, strokeWidth: 2.5),
        SizedBox(height: 16),
        Text('Chargement...',
            style: TextStyle(
                color: InterSyndicPalette.textLight,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ],
    ),
  );

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
            child: Icon(Icons.local_parking_rounded, size: 80, color: InterSyndicPalette.textLight.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun parking trouvé', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: InterSyndicPalette.darkMid),
          ),
          const SizedBox(height: 8),
          const Text(
            'Essayez de modifier vos filtres ou d\'ajouter un parking', 
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

  // ── Header
  Widget _buildHeader() {
    return InterSyndicHeader(
      title: 'ResiManager',
      subtitle: 'inter_syndic',
      gridIcon: Icons.business_rounded,
      onBack: () => Navigator.pop(context),
      onAdd: _showAddParkingDialog,
      addLabel: 'Ajouter',
    );
  }

  // ── Page title
  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Parkings',
            style: TextStyle(
                color: InterSyndicPalette.dark,
                fontWeight: FontWeight.w800,
                fontSize: 26,
                letterSpacing: -0.5)),
        SizedBox(height: 4),
        Text('Gestion des parkings de la tranche',
            style: TextStyle(
                color: InterSyndicPalette.textMid,
                fontSize: 13,
                fontWeight: FontWeight.w400)),
      ],
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
                    'Parkings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '$total parkings au total',
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
                    const Icon(Icons.local_parking_rounded, color: Colors.white, size: 12),
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
      value: _loadingPrix ? '...' : '${_prixAnnuelUnitaire.toInt()} DH',
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

  void _showEditPrixAnnuelDialog() {
    final prixCtrl = TextEditingController(text: _prixAnnuelUnitaire.toInt().toString());
    bool updateAll = false;
    bool saving = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogHeader(ctx, 'Ajuster le prix',
                    icon: Icons.monetization_on_rounded, iconColor: InterSyndicPalette.orange),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),
                
                const Text(
                  'Définissez le prix annuel par défaut pour les parkings de cette tranche.',
                  style: TextStyle(color: InterSyndicPalette.textMid, fontSize: 13),
                ),
                const SizedBox(height: 16),
                
                _label('Nouveau prix annuel (DH) *'),
                _field(prixCtrl, 'ex: 700', inputType: TextInputType.number),
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: updateAll,
                        activeColor: InterSyndicPalette.orange,
                        onChanged: (val) => setDialog(() => updateAll = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Appliquer à tous les parkings existants de cette tranche',
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
                  confirmColor: InterSyndicPalette.orange,
                  onConfirm: () async {
                    final newPrice = double.tryParse(prixCtrl.text.trim());
                    if (newPrice == null || newPrice <= 0) {
                      setDialog(() => errorMsg = 'Veuillez entrer un prix valide');
                      return;
                    }

                    setDialog(() => saving = true);

                    if (updateAll) {
                      // Bulk update
                      final err = await _service.updateAllParkingsPrice(widget.trancheId, newPrice);
                      if (err != null) {
                        setDialog(() {
                          errorMsg = err;
                          saving = false;
                        });
                        return;
                      }
                    }

                    setState(() {
                      _prixAnnuelUnitaire = newPrice;
                    });
                    
                    Navigator.pop(ctx);
                    if (mounted) _load(); // Recharger pour voir les changements
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Search bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: InterSyndicPalette.divider)),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14, color: InterSyndicPalette.dark),
        decoration: InputDecoration(
          hintText: 'Rechercher un parking...',
          hintStyle: const TextStyle(color: InterSyndicPalette.textLight, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: InterSyndicPalette.textLight, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                _applyFilter();
              },
              child: const Icon(Icons.close_rounded,
                  color: InterSyndicPalette.textLight, size: 18))
              : null,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Filter tabs
  Widget _buildFilterTabs() {
    final filters = [
      ('tous', 'Tous', _total),
      ('disponible', 'Disponibles', _disponibles),
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
                          color: isSelected ? Colors.white : InterSyndicPalette.textLight,
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

  // ── Section label
  Widget _buildSectionLabel(String text) => Text(
    text,
    style: const TextStyle(
        color: InterSyndicPalette.dark,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        letterSpacing: -0.3),
  );

  // ── Parking Card Modernized
  Widget _buildParkingCard(ParkingModel p) {
    final isOccupe = p.statut.name == 'occupe';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: InterSyndicPalette.divider.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: InterSyndicPalette.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_parking_rounded, color: InterSyndicPalette.orange, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.numero, 
                      style: const TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.w800, 
                        color: InterSyndicPalette.dark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.payments_rounded, size: 10, color: InterSyndicPalette.textLight),
                        const SizedBox(width: 4),
                        Text(
                          '${p.prixAnnuel.toInt()} DH / an',
                          style: const TextStyle(fontSize: 11, color: InterSyndicPalette.textLight, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(isOccupe),
              const SizedBox(width: 10),
              // ACTIONS ROW (Matching Apartment UI)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOccupe && p.beneficiaireTelephone != null && p.beneficiaireTelephone!.isNotEmpty) ...[
                    _buildIconActionBtn(
                      icon: Icons.phone_in_talk_rounded,
                      color: InterSyndicPalette.green,
                      bgColor: InterSyndicPalette.green.withOpacity(0.1),
                      onTap: () => _callResident(p.beneficiaireTelephone),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (isOccupe) ...[
                     _buildIconActionBtn(
                      icon: Icons.person_remove_rounded,
                      color: InterSyndicPalette.orange,
                      bgColor: InterSyndicPalette.orange.withOpacity(0.1),
                      onTap: () => _showLiberDialog(p),
                    ),
                    const SizedBox(width: 6),
                  ] else ...[
                    _buildIconActionBtn(
                      icon: Icons.person_add_rounded,
                      color: InterSyndicPalette.green,
                      bgColor: InterSyndicPalette.green.withOpacity(0.1),
                      onTap: () => _showAssignerDialog(p),
                    ),
                    const SizedBox(width: 6),
                  ],
                  _buildIconActionBtn(
                    icon: Icons.edit_rounded,
                    color: InterSyndicPalette.blue,
                    bgColor: InterSyndicPalette.bg,
                    onTap: () => _showEditParkingDialog(p),
                  ),
                  if (!isOccupe) ...[
                    const SizedBox(width: 6),
                    _buildIconActionBtn(
                      icon: Icons.delete_outline_rounded,
                      color: InterSyndicPalette.red,
                      bgColor: InterSyndicPalette.red.withOpacity(0.1),
                      onTap: () => _showDeleteDialog(p),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (isOccupe && p.nomCompletBeneficiaire.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: InterSyndicPalette.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.person_rounded, size: 14, color: InterSyndicPalette.orange),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.nomCompletBeneficiaire,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: InterSyndicPalette.darkMid),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (p.beneficiaireTelephone != null && p.beneficiaireTelephone!.isNotEmpty)
                    GestureDetector(
                      onTap: () => _callResident(p.beneficiaireTelephone),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: InterSyndicPalette.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.phone_in_talk_rounded, size: 14, color: InterSyndicPalette.green),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: InterSyndicPalette.divider),
                    ),
                    child: Text(
                      p.typeBeneficiaire,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: InterSyndicPalette.textMid),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isOccupied) {
    final color = isOccupied ? InterSyndicPalette.orange : InterSyndicPalette.green;
    final bgColor = isOccupied ? InterSyndicPalette.orange.withOpacity(0.1) : InterSyndicPalette.green.withOpacity(0.1);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(
            isOccupied ? 'Occupé' : 'Libre',
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String val, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // DIALOGS
  // ══════════════════════════════════════

  Widget _dialogHeader(BuildContext ctx, String title,
      {IconData? icon, Color? iconColor}) {
    final effectiveIconColor = iconColor ?? InterSyndicPalette.orange;
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: effectiveIconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: effectiveIconColor, size: 20),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: InterSyndicPalette.dark)),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: InterSyndicPalette.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: InterSyndicPalette.divider)),
            child: const Icon(Icons.close_rounded,
                size: 16, color: InterSyndicPalette.textMid),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: InterSyndicPalette.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded,
          color: InterSyndicPalette.red, size: 18),
      const SizedBox(width: 8),
      Expanded(
          child: Text(msg,
              style:
              const TextStyle(color: InterSyndicPalette.red, fontSize: 13, fontWeight: FontWeight.w600))),
    ]),
  );

  void _showAddParkingDialog() async {
    final resIdCtrl = TextEditingController(text: widget.residenceName ?? '');
    final trancheIdCtrl = TextEditingController(text: widget.trancheName ?? '');
    final parkingIdCtrl = TextEditingController();
    final prixCtrl = TextEditingController(text: _prixAnnuelUnitaire.toInt().toString());
    final residentSearchCtrl = TextEditingController();
    
    String? errorMsg;
    bool saving = false;
    bool estOccupe = false;
    ResidentModel? selectedResident;



    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogHeader(ctx, 'Ajouter Parking',
                    icon: Icons.local_parking_rounded, iconColor: InterSyndicPalette.orange),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),
                
                _label('Codification du parking *'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _field(resIdCtrl, 'Résidence', prefix: 'R')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(trancheIdCtrl, 'Tranche', prefix: '-T')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(parkingIdCtrl, 'Num (ex: 01)', prefix: '-P')),
                  ],
                ),
                const SizedBox(height: 14),
                _label('Prix annuel (DH) *'),
                _field(prixCtrl, 'ex: 600',
                    inputType: TextInputType.number),
                const SizedBox(height: 14),
                
                // Toggle Occupé / Disponible
                _label('Statut du parking'),
                const SizedBox(height: 6),
                Row(children: [
                   Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setDialog(() => estOccupe = false),
                      child: _typeBtn(
                          'Disponible', !estOccupe, InterSyndicPalette.green),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setDialog(() => estOccupe = true),
                      child: _typeBtn(
                          'Occupé', estOccupe, InterSyndicPalette.orange),
                    ),
                  ),
                ]),

                if (estOccupe) ...[
                  const SizedBox(height: 14),
                  _label('Assigner à un résident *'),
                  Container(
                    decoration: BoxDecoration(
                        color: InterSyndicPalette.bg,
                        borderRadius: BorderRadius.circular(10)),
                    child: Autocomplete<ResidentModel>(
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<ResidentModel>.empty();
                        }
                        return await ResidentService().searchResidents(textEditingValue.text, trancheId: widget.trancheId);
                      },
                      displayStringForOption: (ResidentModel option) =>
                          '${option.prenom} ${option.nom}',
                      onSelected: (ResidentModel selection) {
                        setDialog(() => selectedResident = selection);
                      },
                      fieldViewBuilder: (BuildContext context,
                          TextEditingController fieldTextEditingController,
                          FocusNode fieldFocusNode,
                          VoidCallback onFieldSubmitted) {
                        return TextField(
                          controller: fieldTextEditingController,
                          focusNode: fieldFocusNode,
                          style: const TextStyle(fontSize: 14, color: InterSyndicPalette.dark, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Rechercher par nom ou prénom...',
                            hintStyle: const TextStyle(color: InterSyndicPalette.textLight, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                            suffixIcon: selectedResident != null 
                              ? const Icon(Icons.check_circle_rounded, color: InterSyndicPalette.green, size: 20)
                              : const Icon(Icons.search_rounded, color: InterSyndicPalette.textLight, size: 20),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 200.0,
                              width: 300.0, // Match field width roughly
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final ResidentModel option = options.elementAt(index);
                                  return ListTile(
                                    title: Text('${option.prenom} ${option.nom}', style: const TextStyle(fontSize: 13)),
                                    subtitle: Text(option.email ?? '', style: const TextStyle(fontSize: 11)),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Ajouter',
                  confirmColor: InterSyndicPalette.orange,
                  onConfirm: () async {
                    if (resIdCtrl.text.trim().isEmpty || trancheIdCtrl.text.trim().isEmpty || parkingIdCtrl.text.trim().isEmpty) {
                      setDialog(
                              () => errorMsg = 'La codification doit être complète (ex: RA-T2-P12).');
                      return;
                    }
                    if (estOccupe && selectedResident == null) {
                      setDialog(
                              () => errorMsg = 'Veuillez sélectionner un résident pour assigner le parking');
                      return;
                    }

                    setDialog(() {
                      saving = true;
                      errorMsg = null;
                    });
                    
                    final String theGeneratedNumber = 'R${resIdCtrl.text.trim()}-T${trancheIdCtrl.text.trim()}-P${parkingIdCtrl.text.trim()}';

                    String? err;
                    if (estOccupe && selectedResident != null) {
                       err = await _service.addParkingWithAssignment(
                        numero: theGeneratedNumber,
                        trancheId: widget.trancheId,
                        residenceId: widget.residenceId ?? 1, // Use dynamic residenceId
                        prixAnnuel: double.tryParse(prixCtrl.text) ?? 600,
                        nom: selectedResident!.nom,
                        prenom: selectedResident!.prenom,
                        telephone: selectedResident!.telephone,
                        residentId: selectedResident!.userId,
                      );
                    } else {
                        err = await _service.addParking(
                        numero: theGeneratedNumber,
                        trancheId: widget.trancheId,
                        residenceId: widget.residenceId ?? 1,
                        prixAnnuel: double.tryParse(prixCtrl.text) ?? 600,
                      );
                    }
                    
                    if (!ctx.mounted) return;
                    if (err != null) {
                      setDialog(() {
                        errorMsg = err;
                        saving = false;
                      });
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

  void _showEditParkingDialog(ParkingModel p) {
    String res = widget.residenceName ?? '';
    String tra = widget.trancheName ?? '';
    String num = p.numero;

    final match = RegExp(r'^R(.*?)-T(.*?)-P(.*)$').firstMatch(p.numero);
    if (match != null) {
      res = match.group(1) ?? res;
      tra = match.group(2) ?? tra;
      num = match.group(3) ?? num;
    }

    final resIdCtrl = TextEditingController(text: res);
    final trancheIdCtrl = TextEditingController(text: tra);
    final parkingIdCtrl = TextEditingController(text: num);
    final prixCtrl = TextEditingController(text: p.prixAnnuel.toInt().toString());
    
    String? errorMsg;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogHeader(ctx, 'Modifier Parking',
                    icon: Icons.edit_rounded, iconColor: InterSyndicPalette.blue),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),
                
                _label('Codification du parking *'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _field(resIdCtrl, 'Résidence', prefix: 'R')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(trancheIdCtrl, 'Tranche', prefix: '-T')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(parkingIdCtrl, 'Num (ex: 01)', prefix: '-P')),
                  ],
                ),
                const SizedBox(height: 14),
                _label('Prix annuel (DH) *'),
                _field(prixCtrl, 'ex: 600',
                    inputType: TextInputType.number),
                const SizedBox(height: 24),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Enregistrer',
                  confirmColor: InterSyndicPalette.blue,
                  onConfirm: () async {
                    if (parkingIdCtrl.text.trim().isEmpty) {
                      setDialog(() => errorMsg = 'Le numéro de parking est obligatoire.');
                      return;
                    }

                    setDialog(() {
                      saving = true;
                      errorMsg = null;
                    });
                    
                    final String theGeneratedNumber = 'R${resIdCtrl.text.trim()}-T${trancheIdCtrl.text.trim()}-P${parkingIdCtrl.text.trim()}';

                    final err = await _service.updateParking(
                      parkingId: p.id,
                      numero: theGeneratedNumber,
                      prixAnnuel: double.tryParse(prixCtrl.text) ?? p.prixAnnuel,
                    );
                    
                    if (!ctx.mounted) return;
                    if (err != null) {
                      setDialog(() {
                        errorMsg = err;
                        saving = false;
                      });
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

  void _showAssignerDialog(ParkingModel p) {
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    ResidentModel? selectedResident;
    String typebenef = 'resident';
    bool saving = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogHeader(ctx, 'Assigner ${p.numero}',
                    icon: Icons.person_add_rounded,
                    iconColor: InterSyndicPalette.orange),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),
                const SizedBox(height: 14),
                _label('Chercher un résident *'),
                Container(
                  decoration: BoxDecoration(
                      color: InterSyndicPalette.bg,
                      borderRadius: BorderRadius.circular(14)),
                  child: Autocomplete<ResidentModel>(
                    optionsBuilder: (val) async {
                      if (val.text.isEmpty) return const Iterable<ResidentModel>.empty();
                      return await ResidentService().searchResidents(val.text, trancheId: widget.trancheId);
                    },
                    displayStringForOption: (o) => '${o.prenom} ${o.nom}',
                    onSelected: (selection) => setDialog(() => selectedResident = selection),
                    fieldViewBuilder: (ctx, ctrl, focus, onSub) => TextField(
                      controller: ctrl,
                      focusNode: focus,
                      style: const TextStyle(fontSize: 14, color: InterSyndicPalette.dark, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Nom ou prénom...',
                        hintStyle: const TextStyle(color: InterSyndicPalette.textLight, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        suffixIcon: selectedResident != null 
                            ? const Icon(Icons.check_circle_rounded, color: InterSyndicPalette.green, size: 20)
                            : const Icon(Icons.search_rounded, color: InterSyndicPalette.textLight, size: 20),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Assigner',
                  confirmColor: InterSyndicPalette.orange,
                  onConfirm: () async {
                    if (selectedResident == null) {
                      setDialog(() => errorMsg = 'Veuillez sélectionner un résident');
                      return;
                    }
                    
                    nomCtrl.text = selectedResident!.nom;
                    prenomCtrl.text = selectedResident!.prenom;
                    telCtrl.text = selectedResident!.telephone ?? '';

                    setDialog(() {
                      saving = true;
                      errorMsg = null;
                    });
                    
                    final err = await _service.assignerParking(
                      parkingId: p.id,
                      nom: selectedResident!.nom,
                      prenom: selectedResident!.prenom,
                      telephone: selectedResident!.telephone,
                      type: 'resident',
                      trancheId: widget.trancheId,
                      residentId: selectedResident?.userId,
                    );

                    if (!ctx.mounted) return;
                    if (err != null) {
                      setDialog(() {
                        errorMsg = err;
                        saving = false;
                      });
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

  void _showLiberDialog(ParkingModel p) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: InterSyndicPalette.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_remove_rounded, color: InterSyndicPalette.orange, size: 30),
              ),
              const SizedBox(height: 20),
              const Text(
                'Libérer le parking',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: InterSyndicPalette.dark),
              ),
              const SizedBox(height: 8),
              Text(
                'Confirmez-vous la libération de ${p.numero} ?',
                textAlign: TextAlign.center,
                style: const TextStyle(color: InterSyndicPalette.textMid, fontSize: 13, height: 1.5),
              ),
              if (p.nomCompletBeneficiaire.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Actuellement assigné à ${p.nomCompletBeneficiaire}',
                    style: const TextStyle(color: InterSyndicPalette.orange, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: InterSyndicPalette.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Annuler', style: TextStyle(color: InterSyndicPalette.dark, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _service.libererParking(p.id);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _load();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: InterSyndicPalette.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Libérer', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(ParkingModel p) {
    bool saving = false;
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
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: InterSyndicPalette.orangeLight,
                      borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: InterSyndicPalette.orange, size: 26),
                ),
                const SizedBox(height: 16),
                const Text('Supprimer le parking',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: InterSyndicPalette.dark)),
                const SizedBox(height: 8),
                Text(
                  'Voulez-vous vraiment supprimer le parking ${p.numero} ? Cette action est irréversible.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: InterSyndicPalette.textMid, fontSize: 13),
                ),
                const SizedBox(height: 24),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Supprimer',
                  confirmColor: InterSyndicPalette.orange,
                  onConfirm: () async {
                    setDialog(() => saving = true);
                    await _service.deleteParking(p.id);
                    if (!ctx.mounted) return;
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

  Widget _dialogActions({
    required BuildContext ctx,
    required bool saving,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: saving ? null : () => Navigator.pop(ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: InterSyndicPalette.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: InterSyndicPalette.divider),
              ),
              child: const Text(
                'Annuler',
                textAlign: TextAlign.center,
                style: TextStyle(color: InterSyndicPalette.dark, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: saving ? null : onConfirm,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: saving ? confirmColor.withOpacity(0.5) : confirmColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (!saving)
                    BoxShadow(
                      color: confirmColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: saving
                  ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                  : Text(
                      confirmLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: InterSyndicPalette.textMid)),
      );

  Widget _buildIconActionBtn({required IconData icon, required Color color, required Color bgColor, required VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 18),
        ),
      );

  Widget _field(TextEditingController ctrl, String hint, {TextInputType inputType = TextInputType.text, String? prefix, bool readOnly = false}) => TextField(
        controller: ctrl,
        keyboardType: inputType,
        readOnly: readOnly,
        style: const TextStyle(fontSize: 14, color: InterSyndicPalette.dark, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          prefixStyle: const TextStyle(fontSize: 14, color: InterSyndicPalette.dark, fontWeight: FontWeight.w900),
          hintStyle: const TextStyle(color: InterSyndicPalette.textLight, fontSize: 13),
          filled: true,
          fillColor: readOnly ? InterSyndicPalette.divider.withOpacity(0.3) : InterSyndicPalette.bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: InterSyndicPalette.orange, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      );

  Widget _typeBtn(String label, bool selected, Color accent) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.1) : InterSyndicPalette.bg,
          border: Border.all(color: selected ? accent : InterSyndicPalette.divider, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: selected ? accent : InterSyndicPalette.textMid, fontWeight: FontWeight.w800, fontSize: 13),
        ),
      );
}
