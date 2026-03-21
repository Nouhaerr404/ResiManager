import 'package:flutter/material.dart';
import '../../../models/box_model.dart';
import '../../../models/resident_model.dart';
import '../../../models/immeuble_model.dart';
import '../../../services/box_service.dart';
import '../../../services/resident_service.dart';
import '../../../services/tranche_service.dart';

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
          .getBoxesByTranche(widget.trancheId)
          .timeout(const Duration(seconds: 15));
      setState(() {
        _boxes = data;
        _loading = false;
      });
      _applyFilter();
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      debugPrint('>>> ERREUR load boxes: $e');
      setState(() => _loading = false);
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

  int get _total => _boxes.length;
  int get _disponibles =>
      _boxes.where((p) => p.statut == StatutEspaceEnum.disponible).length;
  int get _occupes => _boxes.where((p) => p.statut == StatutEspaceEnum.occupe).length;
  double get _revenusXan => _boxes
      .where((p) => p.statut == StatutEspaceEnum.occupe)
      .fold(0.0, (s, p) => s + p.prixAnnuel);

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
                      _buildSectionLabel(
                          '${_filtered.length} box${_filtered.length > 1 ? 'es' : ''}'),
                      const SizedBox(height: 14),
                      if (_filtered.isEmpty)
                        _buildEmpty()
                      else
                        ..._filtered.map(_buildBoxCard),
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

  Widget _buildLoader() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: _C.coral, strokeWidth: 2.5),
        SizedBox(height: 16),
        Text('Chargement...',
            style: TextStyle(
                color: _C.textLight,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ],
    ),
  );

  Widget _buildEmpty() => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
              color: _C.coralLight,
              borderRadius: BorderRadius.circular(18)),
          child:
          const Icon(Icons.inventory_2_outlined, color: _C.coral, size: 30),
        ),
        const SizedBox(height: 14),
        const Text('Aucun box',
            style: TextStyle(
                color: _C.dark,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Modifiez les filtres ou ajoutez un box.',
            style: TextStyle(color: _C.textLight, fontSize: 12)),
      ],
    ),
  );

  Widget _buildHeader() {
    return Container(
      color: _C.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: _C.coral, borderRadius: BorderRadius.circular(10)),
            child:
            const Icon(Icons.inventory_2_outlined, color: _C.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ResiManager',
                  style: TextStyle(
                      color: _C.dark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: -0.2)),
              Text('inter_syndic',
                  style: TextStyle(
                      color: _C.textLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showAddBoxDialog,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                  color: _C.coral, borderRadius: BorderRadius.circular(22)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_rounded, size: 16, color: _C.white),
                  SizedBox(width: 6),
                  Text('Ajouter',
                      style: TextStyle(
                          color: _C.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Box',
            style: TextStyle(
                color: _C.dark,
                fontWeight: FontWeight.w800,
                fontSize: 26,
                letterSpacing: -0.5)),
        SizedBox(height: 4),
        Text('Gestion des boxes de la tranche',
            style: TextStyle(
                color: _C.textMid,
                fontSize: 13,
                fontWeight: FontWeight.w400)),
      ],
    );
  }

  Widget _buildStatsBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: _C.coralLight,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.inventory_2_outlined,
                    color: _C.coral, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_total boxes',
                        style: const TextStyle(
                            color: _C.dark,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: -0.3)),
                    const Text('dans cette tranche',
                        style:
                        TextStyle(color: _C.textLight, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: _C.divider),
          const SizedBox(height: 16),
          Row(
            children: [
              _bannerStat('$_disponibles', 'Disponibles', _C.green,
                  _C.greenLight),
              const SizedBox(width: 10),
              _bannerStat('$_occupes', 'Occupes', _C.coral, _C.coralLight),
              const SizedBox(width: 10),
              _bannerStat('${_revenusXan.toInt()} DH', 'Revenus/an', _C.amber,
                  _C.amberLight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerStat(
      String val, String label, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(val,
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.divider)),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14, color: _C.dark),
        decoration: InputDecoration(
          hintText: 'Rechercher un box...',
          hintStyle: const TextStyle(color: _C.textLight, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: _C.textLight, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                _applyFilter();
              },
              child: const Icon(Icons.close_rounded,
                  color: _C.textLight, size: 18))
              : null,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      ('tous', 'Tous', _total),
      ('disponible', 'Disponibles', _disponibles),
      ('occupe', 'Occupes', _occupes),
    ];
    return Row(
      children: filters.map((f) {
        final isSelected = _filterStatut == f.$1;
        return GestureDetector(
          onTap: () => _setFilter(f.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _C.coral : _C.white,
              borderRadius: BorderRadius.circular(22),
              border:
              Border.all(color: isSelected ? _C.coral : _C.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        ? Colors.white.withOpacity(0.25)
                        : _C.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${f.$3}',
                      style: TextStyle(
                          color: isSelected ? _C.white : _C.textLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionLabel(String text) => Text(
    text,
    style: const TextStyle(
        color: _C.dark,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        letterSpacing: -0.3),
  );

  Widget _buildBoxCard(BoxModel p) {
    final isOccupe = p.statut == StatutEspaceEnum.occupe;
    final statusColor = isOccupe ? _C.coral : _C.green;
    final statusBg = isOccupe ? _C.coralLight : _C.greenLight;
    final statusLabel = isOccupe ? 'Occupé' : 'Disponible';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: _C.coralLight,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.inventory_2_outlined,
                color: _C.coral, size: 22),
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
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: _C.dark,
                            letterSpacing: -0.2)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        size: 13, color: _C.textLight),
                    const SizedBox(width: 4),
                    Text('${p.prixAnnuel.toInt()} DH/an',
                        style: const TextStyle(
                            color: _C.textMid, fontSize: 12)),
                  ],
                ),
                if (p.immeubleNom != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.business_rounded,
                          size: 13, color: _C.textLight),
                      const SizedBox(width: 4),
                      Text(p.immeubleNom!,
                          style: const TextStyle(
                              color: _C.textMid, fontSize: 12)),
                    ],
                  ),
                ],
                if (isOccupe && p.nomCompletBeneficiaire.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 13, color: _C.textLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(p.nomCompletBeneficiaire,
                            style: const TextStyle(
                                color: _C.dark,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: _C.bg, borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: _C.divider)),
              child: const Icon(Icons.more_horiz_rounded,
                  color: _C.textMid, size: 16),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 8,
            onSelected: (val) {
              if (val == 'modifier') _showEditBoxDialog(p);
              if (val == 'assigner') _showAssignerDialog(p);
              if (val == 'liberer') _showLiberDialog(p);
              if (val == 'supprimer') _showDeleteDialog(p);
            },
            itemBuilder: (_) => [
              _menuItem('modifier', Icons.edit_rounded, 'Modifier', _C.dark),
              if (!isOccupe)
                _menuItem('assigner', Icons.person_add_rounded, 'Assigner',
                    _C.green),
              if (isOccupe)
                _menuItem('liberer', Icons.person_remove_rounded, 'Liberer',
                    _C.coral),
              _menuItem('supprimer', Icons.delete_outline_rounded, 'Supprimer',
                  _C.coral),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String val, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: (iconColor ?? _C.coral).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor ?? _C.coral, size: 18),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: _C.dark)),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.divider)),
            child: const Icon(Icons.close_rounded,
                size: 15, color: _C.textMid),
          ),
        ),
      ],
    );
  }

  void _showAddBoxDialog() async {
    final resIdCtrl = TextEditingController(text: widget.residenceName ?? '');
    final trancheIdCtrl = TextEditingController(text: widget.trancheName ?? '');
    final boxIdCtrl = TextEditingController();
    final prixCtrl = TextEditingController(text: '800');
    
    int? selectedImmeubleId;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogHeader(ctx, 'Ajouter Box', icon: Icons.inventory_2_outlined),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),

                _label('Codification du box *'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _field(resIdCtrl, 'Résidence', prefix: 'R', readOnly: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(trancheIdCtrl, 'Tranche', prefix: '-T', readOnly: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(boxIdCtrl, 'Box (ex: 05)', prefix: '-B')),
                  ],
                ),
                const SizedBox(height: 14),

                _label('Prix annuel (DH) *'),
                _field(prixCtrl, 'ex: 800', inputType: TextInputType.number),
                const SizedBox(height: 14),

                _label('Statut du box'),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialog(() => estOccupe = false),
                      child: _typeBtn(
                          'Disponible', !estOccupe, _C.green),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialog(() => estOccupe = true),
                      child: _typeBtn('Occupé', estOccupe, _C.coral),
                    ),
                  ),
                ]),

                if (estOccupe) ...[
                  const SizedBox(height: 14),
                  _label('Assigner à un résident *'),
                  _residentAutocomplete((r) => setDialog(() => selectedResident = r)),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      if (resIdCtrl.text.isEmpty || trancheIdCtrl.text.isEmpty || boxIdCtrl.text.isEmpty || prixCtrl.text.isEmpty) {
                        setDialog(() => errorMsg = 'Champs obligatoires');
                        return;
                      }
                      if (estOccupe && selectedResident == null) {
                        setDialog(() => errorMsg = 'Sélectionnez un résident');
                        return;
                      }

                      setDialog(() { saving = true; errorMsg = null; });
                      final resPart = widget.residenceId?.toString() ?? resIdCtrl.text.trim();
                      final traPart = widget.trancheId.toString();
                      final numero = 'R$resPart-T$traPart-B${boxIdCtrl.text.trim()}';
                      
                      String? err;
                      if (estOccupe) {
                        err = await _service.addBoxWithAssignment(
                          numero: numero,
                          trancheId: widget.trancheId,
                          residenceId: widget.residenceId ?? 1, // Dynamic residenceId
                          prixAnnuel: double.tryParse(prixCtrl.text) ?? 0,
                          nom: selectedResident!.nom,
                          prenom: selectedResident!.prenom,
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
                        setDialog(() { errorMsg = err; saving = false; });
                      } else {
                        Navigator.pop(ctx);
                        _load();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.coral,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditBoxDialog(BoxModel p) {
    // Try to parse R[res]-T[tra]-B[num]
    String res = '';
    String tra = '';
    String num = p.numero;

    final match = RegExp(r'^R(.*?)-T(.*?)-B(.*)$').firstMatch(p.numero);
    if (match != null) {
      res = match.group(1) ?? '';
      tra = match.group(2) ?? '';
      num = match.group(3) ?? '';
    }

    final resIdCtrl = TextEditingController(text: res.isEmpty ? (widget.residenceName ?? '') : res);
    final trancheIdCtrl = TextEditingController(text: tra.isEmpty ? (widget.trancheName ?? '') : tra);
    final boxIdCtrl = TextEditingController(text: num);
    final prixCtrl = TextEditingController(text: p.prixAnnuel.toInt().toString());

    String? errorMsg;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogHeader(ctx, 'Modifier Box', icon: Icons.edit_rounded),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),
                _label('Codification du box *'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _field(resIdCtrl, 'Résidence', prefix: 'R', readOnly: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(trancheIdCtrl, 'Tranche', prefix: '-T', readOnly: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(boxIdCtrl, 'Box (ex: 05)', prefix: '-B')),
                  ],
                ),
                const SizedBox(height: 14),
                _label('Prix annuel (DH) *'),
                _field(prixCtrl, 'ex: 800', inputType: TextInputType.number),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      setDialog(() { saving = true; errorMsg = null; });
                      final resPart = widget.residenceId?.toString() ?? resIdCtrl.text.trim();
                      final traPart = widget.trancheId.toString();
                      final numero = 'R$resPart-T$traPart-B${boxIdCtrl.text.trim()}';
                      final err = await _service.updateBox(
                        boxId: p.id,
                        numero: numero,
                        prixAnnuel: double.tryParse(prixCtrl.text) ?? 0,
                      );
                      if (err != null) {
                        setDialog(() { errorMsg = err; saving = false; });
                      } else {
                        Navigator.pop(ctx);
                        _load();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.coral,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Modifier', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogHeader(ctx, 'Assigner Box', icon: Icons.person_add_rounded),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),
                _label('Box: ${p.numero}'),
                const SizedBox(height: 14),
                _label('Chercher un résident *'),
                _residentAutocomplete((r) => setDialog(() => selectedResident = r)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      if (selectedResident == null) {
                        setDialog(() => errorMsg = 'Sélectionnez un résident');
                        return;
                      }
                      setDialog(() { saving = true; errorMsg = null; });
                      final err = await _service.assignerBox(
                        boxId: p.id,
                        nom: selectedResident!.nom,
                        prenom: selectedResident!.prenom,
                        trancheId: widget.trancheId,
                        residentId: selectedResident!.userId,
                      );
                      if (err != null) {
                        setDialog(() { errorMsg = err; saving = false; });
                      } else {
                        Navigator.pop(ctx);
                        _load();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.coral,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Assigner', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLiberDialog(BoxModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Libérer Box'),
        content: Text('Voulez-vous libérer le box ${p.numero} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              await _service.libererBox(p.id);
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Libérer', style: TextStyle(color: _C.coral, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BoxModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer Box'),
        content: Text('Voulez-vous supprimer définitivement le box ${p.numero} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              await _service.deleteBox(p.id);
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets
  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.textMid));

  Widget _field(TextEditingController ctrl, String hint, {TextInputType? inputType, String? prefix, bool readOnly = false}) {
    return Container(
      decoration: BoxDecoration(color: readOnly ? Colors.black12 : _C.bg, borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: inputType,
        style: const TextStyle(fontSize: 14, color: _C.dark, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixText: prefix,
          prefixStyle: const TextStyle(color: _C.textMid, fontWeight: FontWeight.bold),
          hintText: hint,
          hintStyle: const TextStyle(color: _C.textLight, fontSize: 13, fontWeight: FontWeight.normal),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _typeBtn(String label, bool active, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? color : _C.divider),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : _C.textMid,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ),
    );
  }

  Widget _residentAutocomplete(Function(ResidentModel) onSelected) {
    return Container(
      decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10)),
      child: Autocomplete<ResidentModel>(
        optionsBuilder: (val) async {
          if (val.text.isEmpty) return const Iterable<ResidentModel>.empty();
          return await ResidentService().searchResidents(val.text);
        },
        displayStringForOption: (o) => '${o.prenom} ${o.nom}',
        onSelected: onSelected,
        fieldViewBuilder: (ctx, ctrl, focus, onSub) => TextField(
          controller: ctrl,
          focusNode: focus,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Chercher...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, size: 18),
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _errorBanner(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: _C.coral, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: _C.coral, fontSize: 12))),
    ]),
  );
}
