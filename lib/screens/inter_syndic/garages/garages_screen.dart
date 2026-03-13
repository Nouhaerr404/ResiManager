import 'package:flutter/material.dart';
import '../../../models/garage_model.dart';
import '../../../services/garage_service.dart';

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

class GaragesScreen extends StatefulWidget {
  final int trancheId;
  const GaragesScreen({super.key, required this.trancheId});

  @override
  State<GaragesScreen> createState() => _GaragesScreenState();
}

class _GaragesScreenState extends State<GaragesScreen>
    with SingleTickerProviderStateMixin {
  final _service = GarageService();
  List<GarageModel> _garages = [];
  List<GarageModel> _filtered = [];
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
          .getGaragesByTranche(widget.trancheId)
          .timeout(const Duration(seconds: 15));
      setState(() {
        _garages = data;
        _loading = false;
      });
      _applyFilter();
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      debugPrint('>>> ERREUR load garages: $e');
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _garages.where((g) {
        final matchSearch = g.numero.toLowerCase().contains(q) ||
            (g.beneficiaireNom?.toLowerCase().contains(q) ?? false);
        final matchStatut =
            _filterStatut == 'tous' || g.statut == _filterStatut;
        return matchSearch && matchStatut;
      }).toList();
    });
  }

  void _setFilter(String f) {
    setState(() => _filterStatut = f);
    _applyFilter();
  }

  int get _total => _garages.length;
  int get _disponibles =>
      _garages.where((g) => g.statut == 'disponible').length;
  int get _occupes => _garages.where((g) => g.statut == 'occupe').length;
  double get _revenus => _garages
      .where((g) => g.statut == 'occupe')
      .fold(0.0, (s, g) => s + g.prixAnnuel);

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
                          '${_filtered.length} garage${_filtered.length > 1 ? 's' : ''}'),
                      const SizedBox(height: 14),
                      if (_filtered.isEmpty)
                        _buildEmpty()
                      else
                        ..._filtered.map(_buildGarageCard),
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
              color: _C.amberLight,
              borderRadius: BorderRadius.circular(18)),
          child:
          const Icon(Icons.garage_outlined, color: _C.amber, size: 30),
        ),
        const SizedBox(height: 14),
        const Text('Aucun garage',
            style: TextStyle(
                color: _C.dark,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Modifiez les filtres ou ajoutez un garage.',
            style: TextStyle(color: _C.textLight, fontSize: 12)),
      ],
    ),
  );

  // ── Header
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
            const Icon(Icons.grid_view_rounded, color: _C.white, size: 20),
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
            onTap: _showAddGarageDialog,
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

  // ── Page title
  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Garages',
            style: TextStyle(
                color: _C.dark,
                fontWeight: FontWeight.w800,
                fontSize: 26,
                letterSpacing: -0.5)),
        SizedBox(height: 4),
        Text('Gestion des garages de la tranche',
            style: TextStyle(
                color: _C.textMid,
                fontSize: 13,
                fontWeight: FontWeight.w400)),
      ],
    );
  }

  // ── Stats Banner — white cards like app
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
                    color: _C.amberLight,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.garage_outlined,
                    color: _C.amber, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_total garages',
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
              _bannerStat('${_revenus.toInt()} DH', 'Revenus/an', _C.amber,
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
                    color: color.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
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
          border: Border.all(color: _C.divider)),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14, color: _C.dark),
        decoration: InputDecoration(
          hintText: 'Rechercher un garage...',
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

  // ── Filter tabs
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
                        ? Colors.white.withValues(alpha: 0.25)
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

  // ── Section label
  Widget _buildSectionLabel(String text) => Text(
    text,
    style: const TextStyle(
        color: _C.dark,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        letterSpacing: -0.3),
  );

  // ── Garage Card
  Widget _buildGarageCard(GarageModel g) {
    final isOccupe = g.statut == 'occupe';
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
                color: _C.amberLight,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.garage_outlined,
                color: _C.amber, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(g.numero,
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
                    Text('${g.prixAnnuel.toInt()} DH/an',
                        style: const TextStyle(
                            color: _C.textMid, fontSize: 12)),
                  ],
                ),
                if (g.beneficiaireNom != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 13, color: _C.textLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(g.beneficiaireNom!,
                            style: const TextStyle(
                                color: _C.dark,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: g.beneficiaireType == 'resident'
                              ? _C.coralLight
                              : _C.blueLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          g.beneficiaireType == 'resident'
                              ? 'Resident'
                              : 'Externe',
                          style: TextStyle(
                              color: g.beneficiaireType == 'resident'
                                  ? _C.coral
                                  : _C.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
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
              if (val == 'modifier') _showEditGarageDialog(g);
              if (val == 'assigner') _showAssignerDialog(g);
              if (val == 'liberer') _showLiberDialog(g);
            },
            itemBuilder: (_) => [
              _menuItem('modifier', Icons.edit_rounded, 'Modifier', _C.dark),
              if (!isOccupe)
                _menuItem('assigner', Icons.person_add_rounded, 'Assigner',
                    _C.coral),
              if (isOccupe)
                _menuItem('liberer', Icons.person_remove_rounded, 'Liberer',
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
                color: color.withValues(alpha: 0.1),
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
                color: (iconColor ?? _C.coral).withValues(alpha: 0.12),
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

  Widget _errorBanner(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: _C.coralLight,
        borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded,
          color: _C.coral, size: 16),
      const SizedBox(width: 8),
      Expanded(
          child: Text(msg,
              style:
              const TextStyle(color: _C.coral, fontSize: 12))),
    ]),
  );

  void _showAddGarageDialog() {
    final numeroCtrl = TextEditingController();
    final prixCtrl = TextEditingController(text: '600');
    String? errorMsg;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
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
                _dialogHeader(ctx, 'Ajouter Garage',
                    icon: Icons.garage_outlined, iconColor: _C.amber),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),
                _label('Numero *'),
                _field(numeroCtrl, 'ex: G-A06'),
                const SizedBox(height: 14),
                _label('Prix annuel (DH) *'),
                _field(prixCtrl, 'ex: 600',
                    inputType: TextInputType.number),
                const SizedBox(height: 24),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Ajouter',
                  confirmColor: _C.coral,
                  onConfirm: () async {
                    if (numeroCtrl.text.trim().isEmpty) {
                      setDialog(
                              () => errorMsg = 'Numero obligatoire');
                      return;
                    }
                    setDialog(() {
                      saving = true;
                      errorMsg = null;
                    });
                    final err = await _service.addGarage(
                      numero: numeroCtrl.text.trim(),
                      trancheId: widget.trancheId,
                      residenceId: 1,
                      prixAnnuel:
                      double.tryParse(prixCtrl.text) ?? 600,
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

  void _showEditGarageDialog(GarageModel g) {
    final numeroCtrl = TextEditingController(text: g.numero);
    final prixCtrl =
    TextEditingController(text: g.prixAnnuel.toInt().toString());
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogHeader(ctx, 'Modifier Garage',
                    icon: Icons.edit_rounded, iconColor: _C.blue),
                const SizedBox(height: 20),
                _label('Numero'),
                _field(numeroCtrl, ''),
                const SizedBox(height: 14),
                _label('Prix annuel (DH)'),
                _field(prixCtrl, '',
                    inputType: TextInputType.number),
                const SizedBox(height: 24),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Enregistrer',
                  confirmColor: _C.blue,
                  onConfirm: () async {
                    setDialog(() => saving = true);
                    await _service.updateGarage(
                      garageId: g.id,
                      numero: numeroCtrl.text.trim(),
                      prixAnnuel: double.tryParse(prixCtrl.text) ??
                          g.prixAnnuel,
                    );
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

  void _showAssignerDialog(GarageModel g) {
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final telCtrl = TextEditingController();
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
                _dialogHeader(ctx, 'Assigner ${g.numero}',
                    icon: Icons.person_add_rounded,
                    iconColor: _C.coral),
                const SizedBox(height: 20),
                if (errorMsg != null) _errorBanner(errorMsg!),
                _label('Type de beneficiaire'),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setDialog(() => typebenef = 'resident'),
                      child: _typeBtn(
                          'Resident', typebenef == 'resident', _C.coral),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setDialog(() => typebenef = 'externe'),
                      child: _typeBtn(
                          'Externe', typebenef == 'externe', _C.blue),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                _label('Prenom *'),
                _field(prenomCtrl, 'ex: Ahmed'),
                const SizedBox(height: 14),
                _label('Nom *'),
                _field(nomCtrl, 'ex: Bennani'),
                const SizedBox(height: 14),
                _label('Telephone'),
                _field(telCtrl, 'ex: 0612345678',
                    inputType: TextInputType.phone),
                const SizedBox(height: 24),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Assigner',
                  confirmColor: _C.coral,
                  onConfirm: () async {
                    if (nomCtrl.text.trim().isEmpty ||
                        prenomCtrl.text.trim().isEmpty) {
                      setDialog(() =>
                      errorMsg = 'Nom et Prenom obligatoires');
                      return;
                    }
                    setDialog(() {
                      saving = true;
                      errorMsg = null;
                    });
                    final err = await _service.assignerGarage(
                      garageId: g.id,
                      nom: nomCtrl.text.trim(),
                      prenom: prenomCtrl.text.trim(),
                      telephone: telCtrl.text.isEmpty
                          ? null
                          : telCtrl.text.trim(),
                      type: typebenef,
                      trancheId: widget.trancheId,
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

  void _showLiberDialog(GarageModel g) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                    color: _C.coralLight,
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.person_remove_rounded,
                    color: _C.coral, size: 26),
              ),
              const SizedBox(height: 16),
              const Text('Liberer le garage',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: _C.dark)),
              const SizedBox(height: 8),
              Text(
                'Liberer ${g.numero} assigné à ${g.beneficiaireNom ?? "?"}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _C.textMid, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: _C.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.divider)),
                      child: const Text('Annuler',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _C.dark,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await _service.libererGarage(g.id);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _load();
                    },
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: _C.coral,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('Liberer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _C.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ),
                ),
              ]),
            ],
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
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: saving ? null : () => Navigator.pop(ctx),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.divider)),
            child: const Text('Annuler',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _C.dark,
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
                color: saving
                    ? confirmColor.withValues(alpha: 0.5)
                    : confirmColor,
                borderRadius: BorderRadius.circular(12)),
            child: saving
                ? const Center(
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: _C.white, strokeWidth: 2)))
                : Text(confirmLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _C.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ),
      ),
    ]);
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: _C.textMid)),
  );

  Widget _field(TextEditingController ctrl, String hint,
      {TextInputType inputType = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        keyboardType: inputType,
        style: const TextStyle(fontSize: 14, color: _C.dark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          const TextStyle(color: _C.textLight, fontSize: 13),
          filled: true,
          fillColor: _C.bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _C.coral, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 13),
        ),
      );

  Widget _typeBtn(String label, bool selected, Color accent) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.1) : _C.bg,
          border: Border.all(
              color: selected ? accent : _C.divider,
              width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: selected ? accent : _C.textMid,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      );
}