import 'package:flutter/material.dart';
import '../../../models/box_model.dart';
import '../../../models/resident_model.dart';
import '../../../models/immeuble_model.dart';
import '../../../services/box_service.dart';
import '../../../services/resident_service.dart';
import '../../../services/tranche_service.dart';
import '../../../widgets/inter_syndic_header.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/inter_syndic_palette.dart';

class BoxesScreen extends StatefulWidget {
  final int trancheId;
  final int? residenceId;
  final String? trancheName;
  final String? residenceName;

  const BoxesScreen({
    super.key, 
    required this.trancheId,
    this.residenceId,
    this.trancheName,
    this.residenceName,
  });

  @override
  State<BoxesScreen> createState() => _BoxesScreenState();
}

class _BoxesScreenState extends State<BoxesScreen>
    with SingleTickerProviderStateMixin {
  final _service = BoxService();
  List<BoxModel> _boxes = [];
  List<BoxModel> _filtered = [];
  bool _loading = true;
  String _filterStatut = 'tous';
  final _searchCtrl = TextEditingController();

  double _prixAnnuelUnitaire = 800.0;
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
      final data = await _service.getBoxesByTranche(widget.trancheId)
          .timeout(const Duration(seconds: 15));
      setState(() {
        _boxes = data;
        _filtered = data;

        // Calculer le prix unitaire moyen pour l'affichage/défaut
        if (_boxes.isNotEmpty) {
          _prixAnnuelUnitaire = _boxes.first.prixAnnuel;
        }

        _loading = false;
        _loadingPrix = false;
      });
      _applyFilter();
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      debugPrint('>>> ERREUR load boxes: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _boxes.where((p) {
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

  int get _total => _boxes.length;
  int get _disponibles =>
      _boxes.where((p) => p.statut == StatutEspaceEnum.disponible).length;
  int get _occupes => _boxes.where((p) => p.statut == StatutEspaceEnum.occupe).length;
  double get _revenusXan => _boxes
      .where((p) => p.statut == StatutEspaceEnum.occupe)
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
                  subtitle: 'Gestion Boxes',
                  gridIcon: Icons.inventory_2_rounded,
                  onBack: () => Navigator.pop(context),
                  onAdd: _showAddBoxDialog,
                  addLabel: 'Ajouter',
                ),
              ),

              // 2. Carte Héros de Statistiques
              SliverToBoxAdapter(
                child: _buildHeroStatsCard(_total, _occupes, _disponibles, _revenusXan),
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
                              hintText: 'Rechercher un box...',
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
                            color: showFilters ? InterSyndicPalette.coral : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (showFilters ? InterSyndicPalette.coral : Colors.black).withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: showFilters ? InterSyndicPalette.coral : InterSyndicPalette.divider),
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

              // 5. Liste des boxes
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: InterSyndicPalette.coral)),
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
                        child: _buildBoxCard(_filtered[index]),
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
              child: const Center(child: CircularProgressIndicator(color: InterSyndicPalette.coral)),
            ),
        ],
      ),
    );
  }

  Widget _buildLoader() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: InterSyndicPalette.coral, strokeWidth: 2.5),
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
            child: Icon(Icons.inventory_2_rounded, size: 80, color: InterSyndicPalette.textLight.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun box trouvé', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: InterSyndicPalette.darkMid),
          ),
          const SizedBox(height: 8),
          const Text(
            'Essayez de modifier vos filtres ou d\'ajouter un box', 
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
                foregroundColor: InterSyndicPalette.coral,
                side: const BorderSide(color: InterSyndicPalette.coral),
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
        color: InterSyndicPalette.coral,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: InterSyndicPalette.coral.withOpacity(0.25),
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
                    'Boxes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '$total boxes au total',
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
                    const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    const Text(
                      'Gestion Stockage',
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
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
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
      iconColor: InterSyndicPalette.coral,
      iconBg: InterSyndicPalette.coral.withOpacity(0.1),
      label: 'Prix unitaire / an',
      value: _loadingPrix ? '...' : '${_prixAnnuelUnitaire.toInt()} DH',
      onTap: _showEditPrixAnnuelDialog,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: InterSyndicPalette.coral.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.edit_rounded, size: 12, color: InterSyndicPalette.coral),
            SizedBox(width: 4),
            Text('Modifier',
                style: TextStyle(
                    color: InterSyndicPalette.coral,
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
                    icon: Icons.monetization_on_rounded, iconColor: InterSyndicPalette.coral),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),
                
                const Text(
                  'Définissez le prix annuel par défaut pour les boxes de cette tranche.',
                  style: TextStyle(color: InterSyndicPalette.textMid, fontSize: 13),
                ),
                const SizedBox(height: 16),
                
                _label('Nouveau prix annuel (DH) *'),
                _field(prixCtrl, 'ex: 800', inputType: TextInputType.number),
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: updateAll,
                        activeColor: InterSyndicPalette.coral,
                        onChanged: (val) => setDialog(() => updateAll = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Appliquer à tous les boxes existants de cette tranche',
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
                      final err = await _service.updateAllBoxesPrice(widget.trancheId, newPrice);
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
                    if (mounted) _load();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


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
          return GestureDetector(
            onTap: () => _setFilter(f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? InterSyndicPalette.coral : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected ? [
                  BoxShadow(color: InterSyndicPalette.coral.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                ] : [],
                border: Border.all(color: isSelected ? InterSyndicPalette.coral : InterSyndicPalette.divider),
              ),
              child: Row(
                children: [
                  Text(f.$2,
                      style: TextStyle(
                          color: isSelected ? Colors.white : InterSyndicPalette.darkMid,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.2) : InterSyndicPalette.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${f.$3}',
                        style: TextStyle(
                            color: isSelected ? Colors.white : InterSyndicPalette.textMid,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Text(
    text,
    style: const TextStyle(
        color: InterSyndicPalette.dark,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        letterSpacing: -0.3),
  );

  Widget _buildBoxCard(BoxModel p) {
    final isOccupe = p.statut == StatutEspaceEnum.occupe;
    final statusColor = isOccupe ? InterSyndicPalette.coral : InterSyndicPalette.green;
    final statusBg = isOccupe ? InterSyndicPalette.coralLight : InterSyndicPalette.greenLight;
    final statusLabel = isOccupe ? 'Occupé' : 'Disponible';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: InterSyndicPalette.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: isOccupe ? InterSyndicPalette.coralLight : InterSyndicPalette.greenLight,
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.inventory_2_rounded,
                    color: isOccupe ? InterSyndicPalette.coral : InterSyndicPalette.green, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(p.numero,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: InterSyndicPalette.dark,
                                letterSpacing: -0.4)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                          child: Text(statusLabel,
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${p.prixAnnuel.toInt()} DH / an',
                        style: const TextStyle(
                            color: InterSyndicPalette.coral, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          if (isOccupe) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: InterSyndicPalette.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: InterSyndicPalette.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_rounded, size: 16, color: InterSyndicPalette.textMid),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nomCompletBeneficiaire.isNotEmpty ? p.nomCompletBeneficiaire : 'Résident inconnu',
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
          const SizedBox(height: 16),
          Row(
            children: [
              if (isOccupe)
                Expanded(child: _buildIconActionBtn(Icons.phone_rounded, InterSyndicPalette.blue, () => _callResident(p.beneficiaireTelephone))),
              if (isOccupe) const SizedBox(width: 8),
              Expanded(child: _buildIconActionBtn(Icons.edit_rounded, InterSyndicPalette.darkMid, () => _showEditBoxDialog(p))),
              const SizedBox(width: 8),
              Expanded(
                child: _buildIconActionBtn(
                  isOccupe ? Icons.person_remove_rounded : Icons.person_add_rounded,
                  isOccupe ? InterSyndicPalette.coral : InterSyndicPalette.green,
                  isOccupe ? () => _showLiberDialog(p) : () => _showAssignerDialog(p),
                ),
              ),
              const SizedBox(width: 8),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ══════════════════════════════════════
  // DIALOGS
  // ══════════════════════════════════════

  Widget _dialogHeader(BuildContext ctx, String title,
      {IconData? icon, Color? iconColor}) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: (iconColor ?? InterSyndicPalette.coral).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor ?? InterSyndicPalette.coral, size: 20),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: InterSyndicPalette.dark,
                  letterSpacing: -0.4)),
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: InterSyndicPalette.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: InterSyndicPalette.red.withOpacity(0.2))),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, color: InterSyndicPalette.red, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(color: InterSyndicPalette.red, fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: InterSyndicPalette.textMid)),
      );

  Widget _field(TextEditingController ctrl, String hint,
          {String? prefix, bool readOnly = false, TextInputType inputType = TextInputType.text}) =>
      TextField(
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
            border: Border.all(color: active ? color : InterSyndicPalette.divider, width: active ? 1.5 : 1)),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: active ? color : InterSyndicPalette.textMid,
                fontWeight: FontWeight.w800,
                fontSize: 13)),
      );

  Widget _dialogActions(
          {required BuildContext ctx,
          required bool saving,
          required String confirmLabel,
          required Color confirmColor,
          required VoidCallback onConfirm}) =>
      Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  color: InterSyndicPalette.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: InterSyndicPalette.divider)),
              child: const Text('Annuler',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: InterSyndicPalette.darkMid,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
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
                  boxShadow: [
                    BoxShadow(
                        color: confirmColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]),
              child: saving
                  ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                  : Text(confirmLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
            ),
          ),
        ),
      ]);

  void _showAddBoxDialog() async {
    final resIdCtrl = TextEditingController(text: widget.residenceName ?? '');
    final trancheIdCtrl = TextEditingController(text: widget.trancheName ?? '');
    final boxIdCtrl = TextEditingController();
    final prixCtrl = TextEditingController(text: _prixAnnuelUnitaire.toInt().toString());
    final residentSearchCtrl = TextEditingController();
    
    String? errorMsg;
    bool saving = false;
    bool estOccupe = false;
    ResidentModel? selectedResident;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogHeader(ctx, 'Ajouter un Box', icon: Icons.inventory_2_rounded),
                  const SizedBox(height: 20),
                  if (errorMsg != null) _errorBanner(errorMsg!),

                  _label('Codification du box *'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: _field(resIdCtrl, 'Résidence', prefix: 'R')),
                      const SizedBox(width: 8),
                      Expanded(child: _field(trancheIdCtrl, 'Tranche', prefix: '-T')),
                      const SizedBox(width: 8),
                      Expanded(child: _field(boxIdCtrl, 'N°', prefix: '-B')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _label('Prix annuel (DH) *'),
                  _field(prixCtrl, 'ex: 800', inputType: TextInputType.number),
                  const SizedBox(height: 16),

                  _label('Statut initial'),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialog(() => estOccupe = false),
                          child: _typeBtn('Disponible', !estOccupe, InterSyndicPalette.green),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialog(() => estOccupe = true),
                          child: _typeBtn('Occupé', estOccupe, InterSyndicPalette.coral),
                        ),
                      ),
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
                    confirmLabel: 'Confirmer',
                    confirmColor: InterSyndicPalette.coral,
                    onConfirm: () async {
                      if (boxIdCtrl.text.isEmpty || prixCtrl.text.isEmpty) {
                        setDialog(() => errorMsg = 'Veuillez remplir tous les champs');
                        return;
                      }
                      if (estOccupe && selectedResident == null) {
                        setDialog(() => errorMsg = 'Veuillez sélectionner un résident');
                        return;
                      }

                      setDialog(() => saving = true);
                      
                      final numero = 'R${resIdCtrl.text.trim()}-T${trancheIdCtrl.text.trim()}-B${boxIdCtrl.text.trim()}';
                      
                      String? err;
                      if (estOccupe) {
                        err = await _service.addBoxWithAssignment(
                          numero: numero,
                          trancheId: widget.trancheId,
                          residenceId: widget.residenceId ?? 1,
                          prixAnnuel: double.tryParse(prixCtrl.text) ?? 0,
                          nom: selectedResident!.nom,
                          prenom: selectedResident!.prenom,
                          telephone: selectedResident!.telephone,
                          residentId: selectedResident!.userId,
                        );
                      } else {
                        err = await _service.addBox(
                          numero: numero,
                          trancheId: widget.trancheId,
                          residenceId: widget.residenceId ?? 1,
                          prixAnnuel: double.tryParse(prixCtrl.text) ?? 0,
                        );
                      }

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
      ),
    );
  }

  void _showEditBoxDialog(BoxModel p) {
    String res = widget.residenceName ?? '';
    String tra = widget.trancheName ?? '';
    String num = p.numero;

    final match = RegExp(r'^R(.*?)-T(.*?)-B(.*)$').firstMatch(p.numero);
    if (match != null) {
      res = match.group(1) ?? res;
      tra = match.group(2) ?? tra;
      num = match.group(3) ?? num;
    }

    final resIdCtrl = TextEditingController(text: res);
    final trancheIdCtrl = TextEditingController(text: tra);
    final boxIdCtrl = TextEditingController(text: num);
    final prixCtrl = TextEditingController(text: p.prixAnnuel.toInt().toString());
    
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
                _dialogHeader(ctx, 'Modifier Box', icon: Icons.edit_rounded),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),

                _label('Codification du box'),
                Row(
                  children: [
                    Expanded(child: _field(resIdCtrl, 'Résidence', prefix: 'R')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(trancheIdCtrl, 'Tranche', prefix: '-T')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(boxIdCtrl, 'N°', prefix: '-B')),
                  ],
                ),
                const SizedBox(height: 16),

                _label('Prix annuel (DH) *'),
                _field(prixCtrl, 'ex: 800', inputType: TextInputType.number),

                const SizedBox(height: 32),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Enregistrer',
                  confirmColor: InterSyndicPalette.coral,
                  onConfirm: () async {
                    if (boxIdCtrl.text.isEmpty || prixCtrl.text.isEmpty) {
                      setDialog(() => errorMsg = 'Champs obligatoires');
                      return;
                    }

                    setDialog(() => saving = true);
                    
                    final numero = 'R${resIdCtrl.text.trim()}-T${trancheIdCtrl.text.trim()}-B${boxIdCtrl.text.trim()}';
                    
                    final err = await _service.updateBox(
                      boxId: p.id,
                      numero: numero,
                      prixAnnuel: double.tryParse(prixCtrl.text) ?? 0,
                    );

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

  void _showAssignerDialog(BoxModel p) {
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
                _dialogHeader(ctx, 'Assigner Box', icon: Icons.person_add_rounded, iconColor: InterSyndicPalette.green),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),

                _label('Box: ${p.numero}'),
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
                    final err = await _service.assignerBox(
                      boxId: p.id,
                      nom: selectedResident!.nom,
                      prenom: selectedResident!.prenom,
                      telephone: selectedResident!.telephone,
                      trancheId: widget.trancheId,
                      residentId: selectedResident!.userId,
                    );

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

  void _showLiberDialog(BoxModel p) {
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
                _dialogHeader(ctx, 'Libérer Box', icon: Icons.person_remove_rounded),
                const SizedBox(height: 20),
                const Text(
                  'Voulez-vous libérer ce box ?\nLe résident actuel ne sera plus associé à cet emplacement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: InterSyndicPalette.textMid, fontSize: 13),
                ),
                const SizedBox(height: 24),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Oui, Libérer',
                  confirmColor: InterSyndicPalette.coral,
                  onConfirm: () async {
                    setDialog(() => saving = true);
                    await _service.libererBox(p.id);
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

  void _showDeleteDialog(BoxModel p) {
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
                _dialogHeader(ctx, 'Supprimer Box', icon: Icons.delete_outline_rounded, iconColor: InterSyndicPalette.red),
                const SizedBox(height: 20),
                const Text(
                  'Action irréversible.\nVoulez-vous vraiment supprimer définitivement ce box ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: InterSyndicPalette.textMid, fontSize: 13),
                ),
                const SizedBox(height: 24),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Supprimer',
                  confirmColor: InterSyndicPalette.red,
                  onConfirm: () async {
                    setDialog(() => saving = true);
                    final err = await _service.deleteBox(p.id);
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
  Widget _residentAutocomplete(Function(ResidentModel) onSelected) {
    return Container(
      decoration: BoxDecoration(
        color: InterSyndicPalette.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InterSyndicPalette.divider),
      ),
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
