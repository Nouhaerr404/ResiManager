import 'package:flutter/material.dart';
import '../../../models/resident_model.dart';
import '../../../models/paiement_model.dart';
import '../../../services/resident_service.dart';
import '../../../services/parking_service.dart';
import '../../../services/box_service.dart';
import '../../../services/garage_service.dart';
import '../../../models/parking_model.dart';
import '../../../models/box_model.dart';
import '../../../models/garage_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ignore_for_file: avoid_multiple_underscores_for_members

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

  // Prix annuel de la tranche
  double? _prixAnnuel;
  bool _loadingPrix = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadPrixAnnuel();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Charger le prix annuel depuis la table tranches
  // La colonne s'appelle "prix annuel" (avec espace) dans Supabase
  Future<void> _loadPrixAnnuel() async {
    try {
      final db = Supabase.instance.client;
      // Supabase PostgREST : les colonnes avec espaces doivent etre
      // selectionnees avec guillemets doubles dans la requete
      final res = await db
          .from('tranches')
          .select('"prix annuel"')
          .eq('id', widget.trancheId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          if (res != null) {
            // Supabase peut retourner la cle avec espace ou sans
            final raw = res['prix annuel'] ?? res['"prix annuel"'] ?? 0;
            _prixAnnuel = double.tryParse(raw.toString()) ?? 0.0;
          } else {
            _prixAnnuel = 0.0;
          }
          _loadingPrix = false;
        });
      }
    } catch (e) {
      debugPrint('>>> ERREUR _loadPrixAnnuel: $e');
      if (mounted) setState(() => _loadingPrix = false);
    }
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

  int get _total => _residents.length;
  int get _complets =>
      _residents.where((r) => r.statutPaiement == 'complet').length;
  int get _impayes =>
      _residents.where((r) => r.statutPaiement == 'impaye').length;

  // ── Modifier le prix annuel de la tranche
  void _showEditPrixAnnuelDialog() {
    final prixCtrl = TextEditingController(
        text: _prixAnnuel != null ? _prixAnnuel!.toInt().toString() : '');
    bool saving = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogHeader(ctx, 'Prix Annuel Tranche',
                    icon: Icons.edit_rounded, iconColor: _C.amber),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: _C.amberLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: _C.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ce prix sera appliqué automatiquement lors de l\'ajout de nouveaux résidents.',
                          style: TextStyle(
                              color: _C.amber.withValues(alpha: 0.85),
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (errorMsg != null) _errorBanner(errorMsg!),
                _label('Nouveau prix annuel (DH) *'),
                _field(prixCtrl, 'ex: 3000',
                    inputType: TextInputType.number),
                const SizedBox(height: 24),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Enregistrer',
                  confirmColor: _C.amber,
                  onConfirm: () async {
                    final val = double.tryParse(prixCtrl.text.trim());
                    if (val == null || val <= 0) {
                      setDialog(
                              () => errorMsg = 'Entrez un prix valide');
                      return;
                    }
                    setDialog(() {
                      saving = true;
                      errorMsg = null;
                    });
                    try {
                      await Supabase.instance.client
                          .from('tranches')
                          .update({'prix annuel': val}).eq(
                          'id', widget.trancheId);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      setState(() => _prixAnnuel = val);
                    } catch (e) {
                      setDialog(() {
                        errorMsg = e.toString();
                        saving = false;
                      });
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
                      const SizedBox(height: 16),
                      _buildPrixAnnuelBanner(),
                      const SizedBox(height: 16),
                      _buildStatsBanner(),
                      const SizedBox(height: 20),
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildFilterTabs(),
                      const SizedBox(height: 24),
                      _buildSectionLabel(
                          '${_filtered.length} resident${_filtered.length > 1 ? 's' : ''}'),
                      const SizedBox(height: 14),
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
          const Icon(Icons.people_rounded, color: _C.coral, size: 30),
        ),
        const SizedBox(height: 14),
        const Text('Aucun resident',
            style: TextStyle(
                color: _C.dark,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Modifiez les filtres ou ajoutez un resident.',
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
              color: _C.coral,
              borderRadius: BorderRadius.circular(10),
            ),
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
            onTap: _showAddResidentDialog,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                  color: _C.coral, borderRadius: BorderRadius.circular(22)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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

  // ── Prix Annuel Banner
  Widget _buildPrixAnnuelBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.amberLight),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: _C.amberLight, borderRadius: BorderRadius.circular(11)),
            child:
            const Icon(Icons.monetization_on_rounded, color: _C.amber, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prix annuel de la tranche',
                    style: TextStyle(
                        color: _C.textMid,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                _loadingPrix
                    ? const SizedBox(
                    width: 80,
                    height: 16,
                    child: LinearProgressIndicator(
                        color: _C.amber,
                        backgroundColor: _C.amberLight))
                    : Text(
                  '${_prixAnnuel?.toInt() ?? 0} DH / an',
                  style: const TextStyle(
                      color: _C.amber,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.3),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showEditPrixAnnuelDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: _C.amberLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.amber.withValues(alpha: 0.3))),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, size: 13, color: _C.amber),
                  SizedBox(width: 5),
                  Text('Modifier',
                      style: TextStyle(
                          color: _C.amber,
                          fontSize: 12,
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
        Text('Residents',
            style: TextStyle(
                color: _C.dark,
                fontWeight: FontWeight.w800,
                fontSize: 26,
                letterSpacing: -0.5)),
        SizedBox(height: 4),
        Text('Gestion des residents de la tranche',
            style: TextStyle(
                color: _C.textMid,
                fontSize: 13,
                fontWeight: FontWeight.w400)),
      ],
    );
  }

  // ── Stats Banner
  Widget _buildStatsBanner() {
    final totalPercent = _total == 0 ? 0.0 : _complets / _total;
    final pctVal = _total == 0 ? 0 : (_complets * 100 ~/ _total);

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
                child:
                const Icon(Icons.people_rounded, color: _C.coral, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_total residents',
                        style: const TextStyle(
                            color: _C.dark,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: -0.3)),
                    const Text('dans cette tranche',
                        style: TextStyle(color: _C.textLight, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: _C.coralLight,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('$pctVal% complets',
                    style: const TextStyle(
                        color: _C.coral,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: totalPercent.clamp(0.0, 1.0),
              backgroundColor: _C.divider,
              valueColor: const AlwaysStoppedAnimation(_C.coral),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _bannerChip('$_complets', 'Complets', _C.green, _C.greenLight,
                  Icons.check_circle_rounded),
              const SizedBox(width: 10),
              _bannerChip('$_impayes', 'Impayes', _C.coral, _C.coralLight,
                  Icons.cancel_rounded),
              const SizedBox(width: 10),
              _bannerChip('${_total - _complets - _impayes}', 'Partiels',
                  _C.amber, _C.amberLight, Icons.timelapse_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerChip(String value, String label, Color color, Color bg,
      IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                Text(label,
                    style: TextStyle(
                        color: color.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
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
          hintText: 'Rechercher un resident...',
          hintStyle: const TextStyle(color: _C.textLight, fontSize: 13),
          prefixIcon:
          const Icon(Icons.search_rounded, color: _C.textLight, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? GestureDetector(
            onTap: () {
              _searchCtrl.clear();
              _applyFilter();
            },
            child: const Icon(Icons.close_rounded,
                color: _C.textLight, size: 18),
          )
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                            color:
                            isSelected ? _C.white : _C.textLight,
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

  Widget _buildSectionLabel(String text) => Text(text,
      style: const TextStyle(
          color: _C.dark,
          fontWeight: FontWeight.w700,
          fontSize: 16,
          letterSpacing: -0.3));

  // ── Resident Card
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: isProp ? _C.blueLight : _C.amberLight,
                    borderRadius: BorderRadius.circular(12)),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.nomComplet,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: _C.dark,
                            letterSpacing: -0.2)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 11, color: _C.textLight),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(r.adresseAppart,
                              style: const TextStyle(
                                  color: _C.textLight, fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _typeBadge(r.type),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: _C.bg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Paiement ${r.anneePaiement}',
                        style: const TextStyle(
                            color: _C.textMid,
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: _C.divider,
                    valueColor: AlwaysStoppedAnimation(barColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _amountChip('Paye', '${r.montantPaye.toInt()} DH',
                        _C.greenLight, _C.green),
                    _amountChip('Reste', '${r.resteAPayer.toInt()} DH',
                        _C.coralLight, _C.coral),
                    _amountChip('Total', '${r.montantTotal.toInt()} DH',
                        _C.iconBg, _C.textMid),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showPaiementDialog(r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                        color: _C.coral,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payments_rounded, size: 15, color: _C.white),
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
              _iconBtn(Icons.history_rounded, _C.blueLight, _C.blue,
                      () => _showHistoriqueDialog(r)),
              const SizedBox(width: 8),
              _iconBtn(Icons.edit_rounded, _C.iconBg, _C.textMid,
                      () => _showEditDialog(r)),
              const SizedBox(width: 8),
              _iconBtn(Icons.delete_rounded, _C.coralLight, _C.coral,
                      () => _showDeleteConfirm(r)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: fg, size: 17),
      ),
    );
  }

  Widget _amountChip(String label, String value, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: _C.textLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _typeBadge(String type) {
    final isProp = type == 'proprietaire';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: isProp ? _C.blueLight : _C.amberLight,
          borderRadius: BorderRadius.circular(20)),
      child: Text(
        isProp ? 'Proprietaire' : 'Locataire',
        style: TextStyle(
            color: isProp ? _C.blue : _C.amber,
            fontSize: 10,
            fontWeight: FontWeight.w700),
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
            child:
            const Icon(Icons.close_rounded, size: 15, color: _C.textMid),
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
      const Icon(Icons.error_outline_rounded, color: _C.coral, size: 16),
      const SizedBox(width: 8),
      Expanded(
          child: Text(msg,
              style: const TextStyle(color: _C.coral, fontSize: 12))),
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

  Widget _infoRow(String label, String value, Color color,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: _C.textMid, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14)),
      ],
    );
  }

  // ── Add Resident Dialog (UPDATED)
  void _showAddResidentDialog() {
    final prenomCtrl = TextEditingController();
    final nomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    // Le montant vient du prix annuel de la tranche — pas de champ manuel
    String type = 'proprietaire';
    String? errorMsg;
    bool saving = false;
    bool obscurePassword = true;

    List<Map<String, dynamic>> appartementsLibres = [];
    int? selectedAppartId;
    int? selectedParkingId;
    int? selectedBoxId;
    int? selectedGarageId;

    bool loadingApparts = true;
    bool loadingParkings = true;
    bool loadingBoxes = true;
    bool loadingGarages = true;

    List<ParkingModel> parkingsLibres = [];
    List<BoxModel> boxesLibres = [];
    List<GarageModel> garagesLibres = []; // Voir note ci-dessous

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          // Charger les appartements libres
          if (loadingApparts) {
            loadingApparts = false;
            _service
                .getAppartementsLibres(widget.trancheId)
                .then((list) {
              if (ctx.mounted) setDialog(() => appartementsLibres = list);
            });
          }
          // Charger les parkings libres
          if (loadingParkings) {
            loadingParkings = false;
            ParkingService()
                .getParkingsByTranche(widget.trancheId)
                .then((list) {
              if (ctx.mounted) {
                setDialog(() => parkingsLibres = list
                    .where((p) => p.statut.name == 'disponible')
                    .toList());
              }
            });
          }
          // Charger les boxes libres
          if (loadingBoxes) {
            loadingBoxes = false;
            BoxService().getBoxesByTranche(widget.trancheId).then((list) {
              if (ctx.mounted) {
                setDialog(() => boxesLibres = list
                    .where((b) => b.statut.name == 'disponible')
                    .toList());
              }
            });
          }
          // Charger les garages libres
          if (loadingGarages) {
            loadingGarages = false;
            GarageService()
                .getGaragesByTranche(widget.trancheId)
                .then((list) {
              if (ctx.mounted) {
                setDialog(() => garagesLibres = list
                    .where((g) => g.statut == 'disponible')
                    .toList());
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
                        icon: Icons.person_add_rounded, iconColor: _C.coral),
                    const SizedBox(height: 20),

                    // ── Prix annuel (lecture seule, depuis la tranche)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: _C.amberLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _C.amber.withValues(alpha: 0.3))),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on_rounded,
                              color: _C.amber, size: 18),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Prix annuel appliqué',
                                  style: TextStyle(
                                      color: _C.textMid,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500)),
                              Text(
                                '${_prixAnnuel?.toInt() ?? 0} DH / an',
                                style: const TextStyle(
                                    color: _C.amber,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

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

                    // ── Champ Mot de passe (NOUVEAU)
                    _label('Mot de passe * (espace résident)'),
                    StatefulBuilder(
                      builder: (ctx2, setLocal) => TextField(
                        controller: passwordCtrl,
                        obscureText: obscurePassword,
                        style: const TextStyle(fontSize: 14, color: _C.dark),
                        decoration: InputDecoration(
                          hintText: 'Min. 8 caractères',
                          hintStyle: const TextStyle(
                              color: _C.textLight, fontSize: 13),
                          filled: true,
                          fillColor: _C.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: _C.coral, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setDialog(
                                      () => obscurePassword = !obscurePassword);
                            },
                            child: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: _C.textLight,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _label('Telephone'),
                    _field(telCtrl, 'ex: 0612345678',
                        inputType: TextInputType.phone),
                    const SizedBox(height: 14),

                    // ── Appartement
                    _label('Appartement *'),
                    appartementsLibres.isEmpty
                        ? _emptyDropdownBox('Aucun appartement libre')
                        : _dropdownContainer(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          hint: const Text('Selectionner un appartement',
                              style: TextStyle(
                                  color: _C.textLight, fontSize: 13)),
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

                    // ── Parking (optionnel)
                    _label('Parking (Optionnel)'),
                    parkingsLibres.isEmpty
                        ? _emptyDropdownBox('Aucun parking libre dans cette tranche')
                        : _dropdownContainer(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          hint: const Text(
                              'Aucun parking sélectionné',
                              style: TextStyle(
                                  color: _C.textLight, fontSize: 13)),
                          value: selectedParkingId,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Aucun',
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: _C.textLight)),
                            ),
                            ...parkingsLibres.map((p) =>
                                DropdownMenuItem<int?>(
                                  value: p.id,
                                  child: Text(
                                      'Parking ${p.numero}'),
                                )),
                          ],
                          onChanged: (val) =>
                              setDialog(() => selectedParkingId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Box (optionnel)
                    _label('Box / Garage de rangement (Optionnel)'),
                    boxesLibres.isEmpty
                        ? _emptyDropdownBox('Aucun box libre dans cette tranche')
                        : _dropdownContainer(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          hint: const Text(
                              'Aucun box sélectionné',
                              style: TextStyle(
                                  color: _C.textLight, fontSize: 13)),
                          value: selectedBoxId,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Aucun',
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: _C.textLight)),
                            ),
                            ...boxesLibres.map((b) =>
                                DropdownMenuItem<int?>(
                                  value: b.id,
                                  child: Text('Box ${b.numero}'),
                                )),
                          ],
                          onChanged: (val) =>
                              setDialog(() => selectedBoxId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Garage (optionnel) (NOUVEAU)
                    _label('Garage (Optionnel)'),
                    garagesLibres.isEmpty
                        ? _emptyDropdownBox('Aucun garage libre dans cette tranche')
                        : _dropdownContainer(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          hint: const Text(
                              'Aucun garage sélectionné',
                              style: TextStyle(
                                  color: _C.textLight, fontSize: 13)),
                          value: selectedGarageId,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Aucun',
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: _C.textLight)),
                            ),
                            ...garagesLibres.map((g) =>
                                DropdownMenuItem<int?>(
                                  value: g.id,
                                  child:
                                  Text('Garage ${g.numero}'),
                                )),
                          ],
                          onChanged: (val) =>
                              setDialog(() => selectedGarageId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Type
                    _label('Type *'),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setDialog(() => type = 'proprietaire'),
                          child: _typeToggle(
                              'Proprietaire', type == 'proprietaire', _C.blue),
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
                      confirmLabel: 'Ajouter',
                      confirmColor: _C.coral,
                      onConfirm: () async {
                        // Validations
                        if (prenomCtrl.text.trim().isEmpty ||
                            nomCtrl.text.trim().isEmpty ||
                            emailCtrl.text.trim().isEmpty) {
                          setDialog(() =>
                          errorMsg = 'Prenom, Nom et Email obligatoires');
                          return;
                        }
                        if (passwordCtrl.text.trim().length < 8) {
                          setDialog(() =>
                          errorMsg = 'Le mot de passe doit avoir au moins 8 caractères');
                          return;
                        }
                        if (selectedAppartId == null) {
                          setDialog(() =>
                          errorMsg = 'Selectionnez un appartement');
                          return;
                        }
                        setDialog(() {
                          saving = true;
                          errorMsg = null;
                        });

                        // Le montant vient du prix annuel de la tranche
                        final montant = _prixAnnuel ?? 0.0;

                        final err = await _service.addResident(
                          nom: nomCtrl.text,
                          prenom: prenomCtrl.text,
                          email: emailCtrl.text,
                          telephone: telCtrl.text.isEmpty
                              ? null
                              : telCtrl.text,
                          password: passwordCtrl.text.trim(),
                          type: type,
                          trancheId: widget.trancheId,
                          appartementId: selectedAppartId!,
                          montantTotal: montant,
                          parkingId: selectedParkingId,
                          boxId: selectedBoxId,
                          garageId: selectedGarageId,
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
          );
        },
      ),
    );
  }

  // ── Payment Dialog (unchanged)
  void _showPaiementDialog(ResidentModel r) {
    final montantCtrl = TextEditingController();
    PaiementModel? selectedPaiement =
    r.paiements.isNotEmpty ? r.paiements.first : null;
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
                    icon: Icons.payments_rounded, iconColor: _C.coral),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: _C.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.divider)),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: _C.coralLight,
                            borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Text(
                            r.nomComplet.isNotEmpty
                                ? r.nomComplet[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: _C.coral),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.nomComplet,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _C.dark)),
                            Text(r.adresseAppart,
                                style: const TextStyle(
                                    color: _C.textLight, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _label('Ligne de paiement *'),
                const SizedBox(height: 6),
                _dropdownContainer(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PaiementModel>(
                      value: selectedPaiement,
                      isExpanded: true,
                      onChanged: (val) =>
                          setDialog(() => selectedPaiement = val),
                      items: r.paiements
                          .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          _paiementLabel(p),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (selectedPaiement != null) ...[
                  _infoRow('Total ligne',
                      '${selectedPaiement!.montantTotal.toInt()} DH', _C.dark),
                  const SizedBox(height: 8),
                  _infoRow('Payé ligne',
                      '${selectedPaiement!.montantPaye.toInt()} DH', _C.green),
                  const SizedBox(height: 8),
                  _infoRow(
                      'Reste ligne',
                      '${selectedPaiement!.resteAPayer.toInt()} DH',
                      _C.coral,
                      bold: true),
                ],
                const SizedBox(height: 16),
                if (errorMsg != null) _errorBanner(errorMsg!),
                _label('Montant à payer (DH)'),
                _field(montantCtrl, 'ex: 1500',
                    inputType: TextInputType.number),
                const SizedBox(height: 22),
                _dialogActions(
                  ctx: ctx,
                  saving: saving,
                  confirmLabel: 'Enregistrer',
                  confirmColor: _C.coral,
                  onConfirm: () async {
                    final montant =
                        double.tryParse(montantCtrl.text.trim()) ?? 0;
                    if (montant <= 0) {
                      setDialog(
                              () => errorMsg = 'Entrez un montant valide');
                      return;
                    }
                    if (selectedPaiement == null) {
                      setDialog(() =>
                      errorMsg = 'Sélectionnez une ligne de paiement');
                      return;
                    }
                    setDialog(() {
                      saving = true;
                      errorMsg = null;
                    });
                    final err = await _service.enregistrerPaiement(
                      paiementId: selectedPaiement!.id,
                      residentUserId: r.userId,
                      montantAjoute: montant,
                      montantDejaPane: selectedPaiement!.montantPaye,
                      montantTotal: selectedPaiement!.montantTotal,
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

  // ── History Dialog (unchanged)
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
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: _C.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _C.divider)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r.nomComplet,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: _C.dark)),
                            Text('${(pct * 100).toInt()}% payé',
                                style: TextStyle(
                                    color: barColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: pct.clamp(0.0, 1.0),
                            backgroundColor: _C.divider,
                            valueColor: AlwaysStoppedAnimation(barColor),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _infoRow(
                                'Paye', '${r.montantPaye.toInt()} DH', _C.green),
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
                  historique.isEmpty
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        Icon(Icons.history_rounded,
                            color: _C.divider, size: 40),
                        const SizedBox(height: 8),
                        const Text('Aucun historique',
                            style: TextStyle(color: _C.textLight)),
                      ]),
                    ),
                  )
                      : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: historique.length,
                      separatorBuilder: (_, __) =>
                          Container(height: 1, color: _C.divider),
                      itemBuilder: (_, i) {
                        final h = historique[i];
                        final montant =
                        double.parse(h['montant'].toString()).toInt();
                        return Padding(
                          padding:
                          const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
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
                                      h['description'] ?? 'Paiement',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: _C.dark),
                                    ),
                                    Text(
                                      h['date']?.toString() ?? '',
                                      style: const TextStyle(
                                          color: _C.textLight,
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
                          color: _C.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.divider)),
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

  // ── Edit Dialog (unchanged)
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
                _field(telCtrl, '', inputType: TextInputType.phone),
                const SizedBox(height: 14),
                _label('Type'),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setDialog(() => type = 'proprietaire'),
                      child: _typeToggle(
                          'Proprietaire', type == 'proprietaire', _C.blue),
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
                      telephone:
                      telCtrl.text.isEmpty ? null : telCtrl.text,
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

  // ── Delete Dialog (unchanged)
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: _C.coralLight,
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.person_remove_rounded,
                    color: _C.coral, size: 26),
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
                style: const TextStyle(color: _C.textMid, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
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
                    onTap: () async {
                      await _service.deleteResident(
                          r.userId, r.appartementId);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  // ── Construit le label lisible pour une ligne de paiement
  // Ex: "CHARGES - 2026" / "GARAGE G-A06 - 2026" / "PARKING P-03 - 2026"
  String _paiementLabel(PaiementModel p) {
    final type = p.typePaiement.name.toUpperCase();
    final ref  = (p.reference != null && p.reference!.isNotEmpty)
        ? ' ${p.reference}'
        : '';
    final annee = p.annee > 0 ? ' - ${p.annee}' : '';
    return '$type$ref$annee';
  }

  // ── Helpers
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
          hintStyle: const TextStyle(color: _C.textLight, fontSize: 13),
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
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      );

  Widget _typeToggle(String label, bool selected, Color accent) => Container(
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

  Widget _emptyDropdownBox(String msg) => Container(
    padding: const EdgeInsets.all(14),
    width: double.infinity,
    decoration: BoxDecoration(
        color: _C.bg, borderRadius: BorderRadius.circular(10)),
    child: Text(msg, style: const TextStyle(color: _C.textLight)),
  );

  Widget _dropdownContainer({required Widget child}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: _C.bg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _C.divider),
    ),
    child: child,
  );
}