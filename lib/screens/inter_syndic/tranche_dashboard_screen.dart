import 'dart:ui'; // pour ImageFilter
import 'package:flutter/material.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';
import 'garages/garages_screen.dart';
import 'residents/residents_screen.dart';
import 'reunions/reunions_screen.dart';
import 'finance/finance_dashboard_screen.dart';
import 'apartments/apartments_screen.dart';
import 'parkings/parkings_screen.dart';
import 'boxes/boxes_screen.dart';
import 'reclamations/reclamations_screen.dart';
import 'immeubles/immeubles_screen.dart'; // Ajouté

// ── Palette de couleurs
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
  static const purple      = Color(0xFF7C5CFC);
  static const purpleLight = Color(0xFFF3F0FF);
}

class TrancheDashboardScreen extends StatefulWidget {
  final TrancheModel tranche;
  const TrancheDashboardScreen({super.key, required this.tranche});

  @override
  State<TrancheDashboardScreen> createState() =>
      _TrancheDashboardScreenState();
}

class _TrancheDashboardScreenState extends State<TrancheDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _service = TrancheService();
  Map<String, dynamic>? _stats;
  bool _loading = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  String _selectedView = 'dashboard';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadStats();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getTrancheStats(widget.tranche.id);
      setState(() {
        _stats = data;
        _loading = false;
      });
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      setState(() {
        _stats = {};
        _loading = false;
      });
      _fadeCtrl.forward(from: 0);
    }
  }

  num _num(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/tranche_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.20),
                    Color.fromRGBO(0, 0, 0, 0.90),
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          Column(
            children: [
              if (_selectedView != 'apartments') _buildHeader(),
              Expanded(
                child: _loading
                    ? _buildLoader()
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: _selectedView == 'apartments'
                            ? ApartmentsListScreen(
                                trancheId: widget.tranche.id,
                                residenceId: widget.tranche.residenceId,
                                trancheName: widget.tranche.nom,
                                residenceName: widget.tranche.residenceNom,
                                onBack: () =>
                                    setState(() => _selectedView = 'dashboard'),
                              )
                            : ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 24, 20, 40),
                                children: [
                                  _buildPageTitle(),
                                  const SizedBox(height: 24),
                                  _buildFinanceBanner(),
                                  const SizedBox(height: 32),
                                  _buildSectionLabel('Modules', color: _C.white),
                                  const SizedBox(height: 14),
                                  _buildModulesGrid(),
                                  const SizedBox(height: 24),
                                  _buildResume(),
                                ],
                              ),
                      ),
              ),
            ],
          ),
        ],
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
                    color: _C.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(top: top + 14, bottom: 14, left: 16, right: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14, color: _C.white),
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
            child: const Icon(Icons.grid_view_rounded, color: _C.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ResiManager',
                  style: TextStyle(
                      color: _C.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: -0.2)),
              Text('inter_syndic',
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _loadStats,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24)),
              child: const Icon(Icons.refresh_rounded, size: 18, color: _C.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitle() {
    final syndicName = widget.tranche.interSyndicNom ?? 'Inter-Syndic';
    final residenceName = widget.tranche.residenceNom;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tranche ${widget.tranche.nom}',
          style: const TextStyle(
              color: _C.white,
              fontWeight: FontWeight.w900,
              fontSize: 34,
              letterSpacing: -1.0),
        ),
        const SizedBox(height: 6),
        if (residenceName != null)
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                residenceName,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        const SizedBox(height: 4),
        // MODIFICATION ICI : Visibilité du Syndic améliorée
        Row(
          children: [
            const Icon(Icons.person_pin_rounded, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Text(
              '$syndicName · Inter-Syndic',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9), // Plus clair
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.4),
                      offset: const Offset(0.5, 1),
                      blurRadius: 3.0,
                    ),
                  ]),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // MODIFICATION ICI : Uniformisation des Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(Icons.business_rounded,
                '${widget.tranche.nombreImmeubles} immeubles',
                Colors.white.withOpacity(0.15), _C.white),
            _chip(
                Icons.door_front_door_rounded,
                '${_num(_stats?['nbAppartements'] ?? widget.tranche.nombreAppartements)} appts',
                Colors.white.withOpacity(0.15), // Changé de Corail à Blanc Glass
                _C.white),
            _chip(Icons.local_parking_rounded,
                '${widget.tranche.nombreParkings} parkings', 
                Colors.white.withOpacity(0.15), _C.white),
          ],
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color bg, Color fg) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg, 
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: fg.withOpacity(0.1))
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceBanner() {
    final soldeNum = _num(_stats?['solde'] ?? 0);
    final revenusNum = _num(_stats?['revenus'] ?? 0);
    final depensesNum = _num(_stats?['depenses'] ?? 0);

    final soldeStr = soldeNum.toDouble().toStringAsFixed(2);
    final revenusStr = revenusNum.toDouble().toStringAsFixed(2);
    final depensesStr = depensesNum.toDouble().toStringAsFixed(2);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FinanceDashboardScreen(
            residenceId: widget.tranche.residenceId,
            interSyndicId: widget.tranche.interSyndicId ?? 0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Résumé Financier', color: Colors.white),
          const SizedBox(height: 14),
          GlassCard(
            borderRadius: 16,
            color: const Color.fromRGBO(26, 26, 26, 0.6),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: _C.coral, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: _C.white, size: 22),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SOLDE ACTUEL',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                              text: '$soldeStr ',
                              style: const TextStyle(
                                  color: _C.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1)),
                          const TextSpan(
                              text: 'DH',
                              style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white24, size: 22),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _financeCard(
                  icon: Icons.trending_up_rounded,
                  iconBg: _C.greenLight.withOpacity(0.8),
                  iconColor: _C.green,
                  label: 'Revenus Parkings',
                  value: '$revenusStr DH',
                  sub: 'par mois',
                  valueColor: _C.dark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _financeCard(
                  icon: Icons.trending_down_rounded,
                  iconBg: _C.coralLight.withOpacity(0.8),
                  iconColor: _C.coral,
                  label: 'Charges Totales',
                  value: '$depensesStr DH',
                  sub: 'par mois',
                  valueColor: _C.dark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _financeCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
    required Color valueColor,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      color: Colors.white.withOpacity(0.85),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: _C.textLight, fontSize: 10, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: valueColor, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.3)),
                Text(sub, style: const TextStyle(color: _C.textLight, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, {Color color = Colors.white, double size = 20}) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildModulesGrid() {
    final modules = _buildModuleList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: modules.length,
      itemBuilder: (_, i) => _buildModuleCard(modules[i]),
    );
  }

  // ── 2. REMPLACER _buildModuleList() par cette version ─────
//    (ajouter le module Reclamations a la liste existante)

  List<_ModuleData> _buildModuleList() => [
    _ModuleData(
      label: 'Residents',
      value: '${_num(_stats?['nbResidents'] ?? 0)}',
      sub: 'residents actifs',
      icon: Icons.people_rounded,
      iconBg: _C.coralLight,
      valueColor: _C.coral,
      interactive: true,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ResidentsScreen(trancheId: widget.tranche.id))),
    ),
    _ModuleData(
      label: 'Appartements',
      value: '${_num(_stats?['nbAppartements'] ?? 0)}',
      sub: 'unites',
      icon: Icons.home_outlined,
      iconBg: _C.iconBg,
      valueColor: _C.dark,
      interactive: true,
      onTap: () => setState(() => _selectedView = 'apartments'),
    ),
    _ModuleData(
      label: 'Immeubles',
      value: '${widget.tranche.nombreImmeubles}',
      sub: 'batiments',
      icon: Icons.business_rounded,
      iconBg: _C.blueLight,
      valueColor: _C.blue,
      interactive: true,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => InterSyndicImmeublesScreen(tranche: widget.tranche))),
    ),
    _ModuleData(
      label: 'Personnel',
      value: '${_num(_stats?['nbPersonnel'] ?? 0)}',
      sub: 'employes',
      icon: Icons.badge_outlined,
      iconBg: _C.purpleLight,
      valueColor: _C.purple,
    ),
    _ModuleData(
      label: 'Parkings',
      value: '${_num(_stats?['nbParkings'] ?? 0)}',
      sub: 'places',
      icon: Icons.local_parking_rounded,
      iconBg: _C.coralLight,
      valueColor: _C.coral,
      interactive: true,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ParkingsScreen(
            trancheId: widget.tranche.id,
            residenceId: widget.tranche.residenceId,
            trancheName: widget.tranche.nom,
            residenceName: widget.tranche.residenceNom,
          ))),
    ),
    _ModuleData(
      label: 'Garages',
      value: '${_num(_stats?['nbGarages'] ?? 0)}',
      sub: 'places',
      icon: Icons.garage_outlined,
      iconBg: _C.amberLight,
      valueColor: _C.amber,
      interactive: true,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => GaragesScreen(
            trancheId: widget.tranche.id,
            residenceId: widget.tranche.residenceId,
            trancheName: widget.tranche.nom,
            residenceName: widget.tranche.residenceNom,
          ))),
    ),
    _ModuleData(
      label: 'Box',
      value: '${_num(_stats?['nbBoxes'] ?? 0)}',
      sub: 'unites',
      icon: Icons.inventory_2_outlined,
      iconBg: _C.iconBg,
      valueColor: _C.coral,
      interactive: true,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => BoxesScreen(
            trancheId: widget.tranche.id,
            residenceId: widget.tranche.residenceId,
            trancheName: widget.tranche.nom,
            residenceName: widget.tranche.residenceNom,
          ))),
    ),
    _ModuleData(
      label: 'Reunions',
      value: '${_num(_stats?['nbReunions'] ?? 0)}',
      sub: 'planifiees',
      icon: Icons.event_outlined,
      iconBg: _C.blueLight,
      valueColor: _C.blue,
      interactive: true,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ReunionsScreen(trancheId: widget.tranche.id))),
    ),
    // ── NOUVEAU MODULE RECLAMATIONS ──────────────────────────
    _ModuleData(
      label: 'Reclamations',
      value: '${_num(_stats?['nbReclamations'] ?? 0)}',
      sub: 'en cours',
      icon: Icons.report_problem_rounded,
      iconBg: const Color(0xFFFFF8EC),   // amberLight
      valueColor: const Color(0xFFF5A623), // amber
      interactive: true,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ReclamationsScreen(trancheId: widget.tranche.id))),
    ),
  ];



  Widget _buildModuleCard(_ModuleData m) {
    return GestureDetector(
      onTap: m.onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: 14,
        color: Colors.white.withOpacity(0.85),
        border: Border.all(color: Colors.white),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: m.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(m.icon, color: m.valueColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(m.label,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600, color: _C.textMid)),
                  Text(m.value,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, color: _C.dark, letterSpacing: -0.5, height: 1.1)),
                ],
              ),
            ),
            if (m.interactive) Icon(Icons.chevron_right_rounded, size: 16, color: _C.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildResume() {
    final revenus = _num(_stats?['revenus'] ?? 0).toDouble();
    final depenses = _num(_stats?['depenses'] ?? 0).toDouble();
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      color: Colors.white.withOpacity(0.92),
      border: Border.all(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Résumé de la Tranche', color: _C.dark, size: 18),
          const SizedBox(height: 16),
          _resumeRow(
            _resumeItem(Icons.business_rounded, 'Immeubles', '${widget.tranche.nombreImmeubles}', _C.blue, _C.blueLight),
            _resumeItem(Icons.home_outlined, 'Appartements', '${widget.tranche.nombreAppartements}', _C.coral, _C.coralLight),
          ),
          Container(height: 1, color: _C.divider, margin: const EdgeInsets.symmetric(vertical: 14)),
          _resumeRow(
            _resumeItem(Icons.trending_up_rounded, 'Revenus', '+${revenus.toStringAsFixed(2)} DH', _C.green, _C.greenLight),
            _resumeItem(Icons.trending_down_rounded, 'Dépenses', '-${depenses.toStringAsFixed(2)} DH', _C.coral, _C.coralLight),
          ),
        ],
      ),
    );
  }

  Widget _resumeRow(Widget a, Widget b) {
    return Row(
      children: [
        Expanded(child: a),
        Container(width: 1, height: 40, color: _C.divider, margin: const EdgeInsets.symmetric(horizontal: 16)),
        Expanded(child: b),
      ],
    );
  }

  Widget _resumeItem(IconData icon, String label, String value, Color color, Color bg) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: _C.textLight, fontSize: 10, fontWeight: FontWeight.w500)),
              Text(value, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModuleData {
  final String label, value, sub;
  final IconData icon;
  final Color iconBg, valueColor;
  final bool interactive;
  final VoidCallback? onTap;

  const _ModuleData({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.iconBg,
    required this.valueColor,
    this.interactive = false,
    this.onTap,
  });
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final Color color;
  final BoxBorder? border;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.color = const Color.fromRGBO(255, 255, 255, 0.08),
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}