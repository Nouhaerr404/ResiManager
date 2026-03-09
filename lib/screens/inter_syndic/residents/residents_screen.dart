import 'package:flutter/material.dart';
import '../../../models/resident_model.dart';
import '../../../services/resident_service.dart';

// -- Brand palette
class _C {
  static const mint        = Color(0xFF5FD4A0);
  static const mintLight   = Color(0xFFE8F8F2);
  static const mintMid     = Color(0xFFB2EADA);
  static const coral       = Color(0xFFFF6B4A);
  static const coralLight  = Color(0xFFFFEDE9);
  static const cream       = Color(0xFFF5EFE7);
  static const dark        = Color(0xFF2D2D2D);
  static const gray        = Color(0xFF6B6B6B);
  static const divider     = Color(0xFFEDE8E0);
  static const white       = Color(0xFFFFFFFF);
  static const amber       = Color(0xFFF59E0B);
  static const amberLight  = Color(0xFFFFF7E6);
  static const blue        = Color(0xFF3B82F6);
  static const blueLight   = Color(0xFFEFF6FF);
  static const green       = Color(0xFF16A34A);
  static const greenLight  = Color(0xFFF0FDF4);
  static const red         = Color(0xFFDC2626);
  static const redLight    = Color(0xFFFEF2F2);
  static const orange      = Color(0xFFF97316);
  static const orangeLight = Color(0xFFFFF7ED);
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
          .getResidentsByTranche(widget.trancheId)
          .timeout(const Duration(seconds: 15));
      setState(() {
        _residents = data;
        _loading = false;
      });
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
        final matchSearch = r.nomComplet.toLowerCase().contains(q) ||
            (r.appartementNumero?.toLowerCase().contains(q) ?? false);
        final matchStatut =
            _filterStatut == 'tous' || r.statutPaiement == _filterStatut;
        return matchSearch && matchStatut;
      }).toList();
    });
  }

  void _setFilter(String f) {
    setState(() => _filterStatut = f);
    _applyFilter();
  }

  // -- Computed counts
  int get _total => _residents.length;
  int get _complets =>
      _residents.where((r) => r.statutPaiement == 'complet').length;
  int get _impayes =>
      _residents.where((r) => r.statutPaiement == 'impaye').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cream,
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
                  color: _C.mint,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                    const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    children: [
                      _buildStatsBanner(),
                      const SizedBox(height: 20),
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildFilterTabs(),
                      const SizedBox(height: 20),
                      _buildSectionLabel(
                          '${_filtered.length} resident${_filtered.length > 1 ? 's' : ''}'),
                      const SizedBox(height: 12),
                      if (_filtered.isEmpty)
                        _buildEmpty()
                      else
                        ..._filtered.map(_buildResidentCard),
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

  // -- Loader
  Widget _buildLoader() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: _C.mint, strokeWidth: 3),
        SizedBox(height: 14),
        Text('Chargement...',
            style: TextStyle(color: _C.gray, fontSize: 13)),
      ],
    ),
  );

  // -- Empty state
  Widget _buildEmpty() => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
              color: _C.mintLight,
              borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.people_rounded,
              color: _C.mint, size: 32),
        ),
        const SizedBox(height: 14),
        const Text('Aucun resident',
            style: TextStyle(
                color: _C.dark,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Modifiez les filtres ou ajoutez un resident.',
            style: TextStyle(color: _C.gray, fontSize: 12)),
      ],
    ),
  );

  // -- Header
  Widget _buildHeader() {
    return Container(
      color: _C.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: _C.cream,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14, color: _C.dark),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Residents',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: _C.dark)),
                Text('Gestion des residents',
                    style: TextStyle(color: _C.gray, fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showAddResidentDialog,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                  color: _C.dark, borderRadius: BorderRadius.circular(22)),
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

  // -- Stats Banner
  Widget _buildStatsBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: _C.dark, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: _C.mint,
                    borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.people_rounded,
                    color: _C.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_total residents',
                      style: const TextStyle(
                          color: _C.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                  const Text('dans cette tranche',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 16),
          Row(
            children: [
              _bannerStat('$_complets', 'Complets', _C.mint),
              _bannerDivider(),
              _bannerStat('$_impayes', 'Impayes', _C.coral),
              _bannerDivider(),
              _bannerStat(
                  '${_total - _complets - _impayes}', 'Partiels', _C.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerStat(String val, String label, Color color) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val,
            style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(
                color: Colors.white38, fontSize: 10)),
      ],
    ),
  );

  Widget _bannerDivider() => Container(
      width: 1, height: 32, color: Colors.white12,
      margin: const EdgeInsets.symmetric(horizontal: 12));

  // -- Search bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.divider)),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14, color: _C.dark),
        decoration: InputDecoration(
          hintText: 'Rechercher un resident...',
          hintStyle: const TextStyle(color: _C.gray, fontSize: 13),
          prefixIcon:
          const Icon(Icons.search_rounded, color: _C.gray, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? GestureDetector(
            onTap: () {
              _searchCtrl.clear();
              _applyFilter();
            },
            child: const Icon(Icons.close_rounded,
                color: _C.gray, size: 18),
          )
              : null,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // -- Filter tabs
  Widget _buildFilterTabs() {
    final filters = [
      ('tous', 'Tous', _total),
      ('complet', 'Complets', _complets),
      ('partiel', 'Partiels', _total - _complets - _impayes),
      ('impaye', 'Impayes', _impayes),
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
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _C.dark : _C.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: isSelected ? _C.dark : _C.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(f.$2,
                      style: TextStyle(
                          color: isSelected ? _C.white : _C.gray,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.15)
                          : _C.cream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${f.$3}',
                        style: TextStyle(
                            color: isSelected ? _C.white : _C.gray,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // -- Section label
  Widget _buildSectionLabel(String text) => Row(
    children: [
      Container(
          width: 4, height: 16,
          decoration: BoxDecoration(
              color: _C.coral,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(text,
          style: const TextStyle(
              color: _C.dark,
              fontWeight: FontWeight.w700,
              fontSize: 14)),
    ],
  );

  // -- Resident card
  Widget _buildResidentCard(ResidentModel r) {
    final pct = r.pourcentagePaiement;
    final Color barColor =
    pct >= 1.0 ? _C.green : pct > 0 ? _C.orange : _C.coral;
    final Color barBg =
    pct >= 1.0 ? _C.greenLight : pct > 0 ? _C.orangeLight : _C.coralLight;
    final String pctLabel = '${(pct * 100).toInt()}%';

    final bool isProp = r.type == 'proprietaire';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: avatar + info + badges + actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isProp ? _C.blueLight : _C.amberLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    r.nomComplet.isNotEmpty
                        ? r.nomComplet[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: isProp ? _C.blue : _C.amber),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.nomComplet,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: _C.dark)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 11, color: _C.gray),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(r.adresseAppart,
                              style: const TextStyle(
                                  color: _C.gray, fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Type badge
              _typeBadge(r.type),
            ],
          ),
          const SizedBox(height: 14),

          // Payment progress section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.cream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Paiement ${r.anneePaiement}',
                        style: const TextStyle(
                            color: _C.gray,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: barBg,
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            pct >= 1.0
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: barColor,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(pctLabel,
                              style: TextStyle(
                                  color: barColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: _C.divider,
                    valueColor: AlwaysStoppedAnimation(barColor),
                    minHeight: 7,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _amountChip('Paye', '${r.montantPaye.toInt()} DH',
                        _C.greenLight, _C.green),
                    _amountChip('Reste', '${r.resteAPayer.toInt()} DH',
                        _C.coralLight, _C.coral),
                    _amountChip('Total', '${r.montantTotal.toInt()} DH',
                        _C.cream, _C.gray),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Actions row
          Row(
            children: [
              // Pay button
              Expanded(
                child: GestureDetector(
                  onTap: () => _showPaiementDialog(r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                        color: _C.mint,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.payments_rounded,
                            size: 15, color: _C.white),
                        SizedBox(width: 6),
                        Text('Payer',
                            style: TextStyle(
                                color: _C.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // History button
              GestureDetector(
                onTap: () => _showHistoriqueDialog(r),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: _C.blueLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.history_rounded,
                      color: _C.blue, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              // Edit button
              GestureDetector(
                onTap: () => _showEditDialog(r),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: _C.cream,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.edit_rounded,
                      color: _C.gray, size: 17),
                ),
              ),
              const SizedBox(width: 8),
              // Delete button
              GestureDetector(
                onTap: () => _showDeleteConfirm(r),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: _C.coralLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.delete_rounded,
                      color: _C.coral, size: 17),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountChip(
      String label, String value, Color bg, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: _C.gray, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
      ],
    );
  }

  Widget _typeBadge(String type) {
    final isProp = type == 'proprietaire';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isProp ? _C.blueLight : _C.amberLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isProp ? 'Proprietaire' : 'Locataire',
        style: TextStyle(
            color: isProp ? _C.blue : _C.amber,
            fontSize: 10,
            fontWeight: FontWeight.w700),
      ),
    );
  }

  // =============================================
  // DIALOGS - shared helpers
  // =============================================

  Widget _dialogHeader(BuildContext ctx, String title,
      {IconData? icon, Color? iconColor}) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: (iconColor ?? _C.mint).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor ?? _C.mint, size: 18),
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
            width: 30, height: 30,
            decoration: BoxDecoration(
                color: _C.cream, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.close_rounded,
                size: 15, color: _C.gray),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: _C.coralLight, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded,
          color: _C.coral, size: 16),
      const SizedBox(width: 8),
      Expanded(
          child: Text(msg,
              style: const TextStyle(
                  color: _C.coral, fontSize: 12))),
    ]),
  );

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
                color: _C.cream, borderRadius: BorderRadius.circular(12)),
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
                    width: 18, height: 18,
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

  // -- Info row used in payment dialog
  Widget _infoRow(String label, String value, Color color,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _C.gray, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14)),
      ],
    );
  }

  // =============================================
  // DIALOG: Add resident
  // =============================================
  void _showAddResidentDialog() {
    final prenomCtrl = TextEditingController();
    final nomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final montantCtrl = TextEditingController(text: '3000');
    String type = 'proprietaire';
    String? errorMsg;
    bool saving = false;
    List<Map<String, dynamic>> appartementsLibres = [];
    int? selectedAppartId;
    bool loadingApparts = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          if (loadingApparts) {
            loadingApparts = false;
            _service
                .getAppartementsLibres(widget.trancheId)
                .then((list) {
              if (ctx.mounted) {
                setDialog(() => appartementsLibres = list);
              }
            });
          }
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialogHeader(ctx, 'Ajouter Resident',
                        icon: Icons.person_add_rounded,
                        iconColor: _C.mint),
                    const SizedBox(height: 20),
                    if (errorMsg != null) _errorBanner(errorMsg!),
                    _label('Prenom *'),
                    _field(prenomCtrl, 'ex: Ahmed'),
                    const SizedBox(height: 14),
                    _label('Nom *'),
                    _field(nomCtrl, 'ex: Bennani'),
                    const SizedBox(height: 14),
                    _label('Email *'),
                    _field(emailCtrl, 'ex: ahmed@example.com',
                        inputType: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    _label('Telephone'),
                    _field(telCtrl, 'ex: 0612345678',
                        inputType: TextInputType.phone),
                    const SizedBox(height: 14),
                    _label('Appartement *'),
                    appartementsLibres.isEmpty
                        ? Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _C.cream,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Aucun appartement libre',
                        style: TextStyle(color: _C.gray),
                      ),
                    )
                        : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14),
                      decoration: BoxDecoration(
                        color: _C.cream,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          hint: const Text(
                              'Selectionner un appartement',
                              style: TextStyle(
                                  color: _C.gray, fontSize: 13)),
                          value: selectedAppartId,
                          items: appartementsLibres.map((a) {
                            return DropdownMenuItem<int>(
                              value: a['id'] as int,
                              child: Text(a['label'].toString()),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setDialog(() => selectedAppartId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _label('Montant annuel (DH) *'),
                    _field(montantCtrl, '3000',
                        inputType: TextInputType.number),
                    const SizedBox(height: 14),
                    _label('Type *'),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setDialog(() => type = 'proprietaire'),
                          child: _typeToggle(
                              'Proprietaire', type == 'proprietaire',
                              _C.blue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setDialog(() => type = 'locataire'),
                          child: _typeToggle(
                              'Locataire', type == 'locataire',
                              _C.amber),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _dialogActions(
                      ctx: ctx,
                      saving: saving,
                      confirmLabel: 'Ajouter',
                      confirmColor: _C.mint,
                      onConfirm: () async {
                        if (prenomCtrl.text.trim().isEmpty ||
                            nomCtrl.text.trim().isEmpty ||
                            emailCtrl.text.trim().isEmpty) {
                          setDialog(() => errorMsg =
                          'Prenom, Nom et Email obligatoires');
                          return;
                        }
                        if (selectedAppartId == null) {
                          setDialog(() => errorMsg =
                          'Selectionnez un appartement');
                          return;
                        }
                        setDialog(
                                () { saving = true; errorMsg = null; });
                        final montant =
                            double.tryParse(montantCtrl.text) ?? 3000.0;
                        final err = await _service.addResident(
                          nom: nomCtrl.text,
                          prenom: prenomCtrl.text,
                          email: emailCtrl.text,
                          telephone: telCtrl.text.isEmpty
                              ? null
                              : telCtrl.text,
                          type: type,
                          trancheId: widget.trancheId,
                          appartementId: selectedAppartId!,
                          montantTotal: montant,
                        );
                        if (!ctx.mounted) return;
                        if (err != null) {
                          setDialog(
                                  () { errorMsg = err; saving = false; });
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
          );
        },
      ),
    );
  }

  // =============================================
  // DIALOG: Payment
  // =============================================
  void _showPaiementDialog(ResidentModel r) {
    final montantCtrl = TextEditingController();
    String? errorMsg;
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
                _dialogHeader(ctx, 'Enregistrer Paiement',
                    icon: Icons.payments_rounded, iconColor: _C.mint),
                const SizedBox(height: 18),
                // Resident info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: _C.cream,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                            color: _C.mintLight,
                            borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Text(
                            r.nomComplet.isNotEmpty
                                ? r.nomComplet[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: _C.mint),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.nomComplet,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _C.dark)),
                          Text(r.adresseAppart,
                              style: const TextStyle(
                                  color: _C.gray, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Amounts
                _infoRow('Total', '${r.montantTotal.toInt()} DH', _C.dark),
                const SizedBox(height: 8),
                _infoRow('Paye', '${r.montantPaye.toInt()} DH', _C.green),
                const SizedBox(height: 8),
                _infoRow('Reste', '${r.resteAPayer.toInt()} DH', _C.coral,
                    bold: true),
                const SizedBox(height: 16),
                if (errorMsg != null) _errorBanner(errorMsg!),
                _label('Montant a payer (DH)'),
                _field(montantCtrl, 'ex: 1500',
                    inputType: TextInputType.number),
                const SizedBox(height: 22),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Enregistrer',
                  confirmColor: _C.mint,
                  onConfirm: () async {
                    final montant =
                        double.tryParse(montantCtrl.text.trim()) ?? 0;
                    if (montant <= 0) {
                      setDialog(
                              () => errorMsg = 'Entrez un montant valide');
                      return;
                    }
                    if (r.paiementId == null) {
                      setDialog(
                              () => errorMsg = 'Aucun paiement trouve');
                      return;
                    }
                    setDialog(() { saving = true; errorMsg = null; });
                    final err = await _service.enregistrerPaiement(
                      paiementId: r.paiementId!,
                      residentUserId: r.userId,
                      montantAjoute: montant,
                      montantDejaPane: r.montantPaye,
                      montantTotal: r.montantTotal,
                    );
                    if (!ctx.mounted) return;
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

  // =============================================
  // DIALOG: History
  // =============================================
  void _showHistoriqueDialog(ResidentModel r) {
    List<Map<String, dynamic>> historique = [];
    bool loadingHist = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          if (loadingHist) {
            loadingHist = false;
            _service.getHistoriquePaiements(r.userId).then((data) {
              if (ctx.mounted) setDialog(() => historique = data);
            });
          }

          final pct = r.pourcentagePaiement;
          final Color barColor =
          pct >= 1.0 ? _C.green : pct > 0 ? _C.orange : _C.coral;

          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogHeader(ctx, 'Historique',
                      icon: Icons.history_rounded, iconColor: _C.blue),
                  const SizedBox(height: 16),
                  // Resident summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: _C.cream,
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r.nomComplet,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: _C.dark)),
                            Text('${(pct * 100).toInt()}% paye',
                                style: TextStyle(
                                    color: barColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct.clamp(0.0, 1.0),
                            backgroundColor: _C.divider,
                            valueColor:
                            AlwaysStoppedAnimation(barColor),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            _infoRow('Paye',
                                '${r.montantPaye.toInt()} DH', _C.green),
                            _infoRow('Reste',
                                '${r.resteAPayer.toInt()} DH', _C.coral),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: _C.divider),
                  const SizedBox(height: 12),
                  // History list
                  historique.isEmpty
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        Icon(Icons.history_rounded,
                            color: _C.divider, size: 40),
                        const SizedBox(height: 8),
                        const Text('Aucun historique',
                            style: TextStyle(color: _C.gray)),
                      ]),
                    ),
                  )
                      : ConstrainedBox(
                    constraints:
                    const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: historique.length,
                      separatorBuilder: (_, __) =>
                          Container(height: 1, color: _C.divider),
                      itemBuilder: (_, i) {
                        final h = historique[i];
                        final montant = double.parse(
                            h['montant'].toString())
                            .toInt();
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                    color: _C.greenLight,
                                    borderRadius:
                                    BorderRadius.circular(10)),
                                child: const Icon(
                                    Icons.arrow_downward_rounded,
                                    color: _C.green,
                                    size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      h['description'] ??
                                          'Paiement',
                                      style: const TextStyle(
                                          fontWeight:
                                          FontWeight.w600,
                                          fontSize: 13,
                                          color: _C.dark),
                                    ),
                                    Text(
                                      h['date']?.toString() ?? '',
                                      style: const TextStyle(
                                          color: _C.gray,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text('+$montant DH',
                                  style: const TextStyle(
                                      color: _C.green,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: _C.cream,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('Fermer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _C.dark,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =============================================
  // DIALOG: Edit
  // =============================================
  void _showEditDialog(ResidentModel r) {
    final nomCtrl = TextEditingController(text: r.nom);
    final prenomCtrl = TextEditingController(text: r.prenom);
    final telCtrl = TextEditingController(text: r.telephone ?? '');
    String type = r.type;
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
                _dialogHeader(ctx, 'Modifier Resident',
                    icon: Icons.edit_rounded, iconColor: _C.blue),
                const SizedBox(height: 20),
                _label('Prenom'),
                _field(prenomCtrl, ''),
                const SizedBox(height: 14),
                _label('Nom'),
                _field(nomCtrl, ''),
                const SizedBox(height: 14),
                _label('Telephone'),
                _field(telCtrl, '',
                    inputType: TextInputType.phone),
                const SizedBox(height: 14),
                _label('Type'),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setDialog(() => type = 'proprietaire'),
                      child: _typeToggle(
                          'Proprietaire', type == 'proprietaire',
                          _C.blue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setDialog(() => type = 'locataire'),
                      child: _typeToggle(
                          'Locataire', type == 'locataire', _C.amber),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Enregistrer',
                  confirmColor: _C.blue,
                  onConfirm: () async {
                    setDialog(() => saving = true);
                    await _service.updateResident(
                      userId: r.userId,
                      nom: nomCtrl.text,
                      prenom: prenomCtrl.text,
                      telephone: telCtrl.text.isEmpty
                          ? null
                          : telCtrl.text,
                      type: type,
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

  // =============================================
  // DIALOG: Delete confirm
  // =============================================
  void _showDeleteConfirm(ResidentModel r) {
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
                width: 56, height: 56,
                decoration: BoxDecoration(
                    color: _C.coralLight,
                    borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.person_remove_rounded,
                    color: _C.coral, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Confirmer la suppression',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: _C.dark)),
              const SizedBox(height: 8),
              Text(
                'Supprimer ${r.nomComplet} de la liste ?',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _C.gray, fontSize: 13),
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
                          color: _C.cream,
                          borderRadius: BorderRadius.circular(12)),
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
                      await _service.deleteResident(
                          r.userId, r.appartementId);
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
                      child: const Text('Supprimer',
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

  // =============================================
  // HELPERS
  // =============================================
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: _C.gray)),
  );

  Widget _field(TextEditingController ctrl, String hint,
      {TextInputType inputType = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        keyboardType: inputType,
        style: const TextStyle(fontSize: 14, color: _C.dark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _C.gray, fontSize: 13),
          filled: true,
          fillColor: _C.cream,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _C.mint, width: 1.5),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      );

  Widget _typeToggle(String label, bool selected, Color accent) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.1) : _C.cream,
          border: Border.all(
              color: selected ? accent : _C.divider,
              width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: selected ? accent : _C.gray,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      );
}