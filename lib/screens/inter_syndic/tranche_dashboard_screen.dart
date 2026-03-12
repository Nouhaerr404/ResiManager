// lib/screens/inter_syndic/tranche_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';
import 'garages/garages_screen.dart';
import 'residents/residents_screen.dart';
import 'reunions/reunions_screen.dart';

// -- Brand palette (unified with garage/resident screens)
class _C {
  static const mint        = Color(0xFF4CAF82);
  static const mintLight   = Color(0xFFE8F5EE);
  static const mintMid     = Color(0xFFB2EADA);
  static const coral       = Color(0xFFFF6B4A);
  static const coralLight  = Color(0xFFFFEDE9);
  static const cream       = Color(0xFFF4F6F8);
  static const dark        = Color(0xFF1C1C1E);
  static const gray        = Color(0xFF718096);
  static const divider     = Color(0xFFE2E8F0);
  static const white       = Color(0xFFFFFFFF);
  static const amber       = Color(0xFFF59E0B);
  static const amberLight  = Color(0xFFFFF7E6);
  static const blue        = Color(0xFF3B82F6);
  static const blueLight   = Color(0xFFEFF6FF);
  static const purple      = Color(0xFF8B5CF6);
  static const purpleLight = Color(0xFFF5F3FF);
  static const green       = Color(0xFF16A34A);
  static const greenLight  = Color(0xFFF0FDF4);
  static const red         = Color(0xFFDC2626);
  static const redLight    = Color(0xFFFEF2F2);
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
    final data = await _service.getTrancheStats(widget.tranche.id);
    setState(() {
      _stats = data;
      _loading = false;
    });
    _fadeCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cream,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? _buildLoader()
                : FadeTransition(
              opacity: _fadeAnim,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  _buildFinanceBanner(),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Modules'),
                  const SizedBox(height: 14),
                  _buildModulesGrid(),
                  const SizedBox(height: 20),
                  _buildResume(),
                ],
              ),
            ),
          ),
        ],
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

  // -- Header
  Widget _buildHeader() {
    return Container(
      color: _C.white,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          bottom: 16,
          left: 20,
          right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
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
                  children: [
                    Text(widget.tranche.nom,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: _C.dark)),
                    const Text('Mohammed Benali - Syndic',
                        style: TextStyle(color: _C.gray, fontSize: 12)),
                  ],
                ),
              ),
              // Refresh button
              GestureDetector(
                onTap: _loadStats,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: _C.mintLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.refresh_rounded,
                      size: 16, color: _C.mint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Quick-stat pills
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _pill(Icons.business_rounded,
                  '${widget.tranche.nombreImmeubles} immeubles',
                  _C.mintLight, _C.mint),
              _pill(Icons.door_front_door_rounded,
                  '${widget.tranche.nombreAppartements} appts',
                  _C.blueLight, _C.blue),
              _pill(Icons.local_parking_rounded,
                  '${widget.tranche.nombreParkings} parkings',
                  _C.amberLight, _C.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // -- Finance Banner (redesigned: 3 white cards like garage/resident)
  Widget _buildFinanceBanner() {
    final solde    = _stats!['solde']    ?? 0;
    final revenus  = _stats!['revenus']  ?? 0;
    final depenses = _stats!['depenses'] ?? 0;

    return Column(
      children: [
        // Solde card — full width hero
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _C.dark,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: _C.mint,
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: _C.white, size: 24),
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
                            text: '$solde ',
                            style: const TextStyle(
                                color: _C.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                height: 1)),
                        const TextSpan(
                            text: 'DH',
                            style: TextStyle(
                                color: Colors.white38,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Revenus + Depenses side by side cards
        Row(
          children: [
            Expanded(
              child: _financeCard(
                icon: Icons.trending_up_rounded,
                iconBg: _C.greenLight,
                iconColor: _C.green,
                label: 'Revenus',
                value: '+$revenus DH',
                valueColor: _C.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _financeCard(
                icon: Icons.trending_down_rounded,
                iconBg: _C.coralLight,
                iconColor: _C.coral,
                label: 'Depenses',
                value: '-$depenses DH',
                valueColor: _C.coral,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _financeCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: _C.gray, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      color: valueColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  // -- Section label
  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
                color: _C.mint, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                color: _C.dark,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
      ],
    );
  }

  // -- Modules Grid
  Widget _buildModulesGrid() {
    final modules = _buildModuleList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.9,
      ),
      itemCount: modules.length,
      itemBuilder: (_, i) => _buildModuleCard(modules[i]),
    );
  }

  List<_ModuleData> _buildModuleList() => [
    _ModuleData(
      label: 'Residents',
      value: '${_stats!['nbResidents']}',
      sub: 'residents actifs',
      icon: Icons.people_rounded,
      iconBg: _C.mintLight,
      valueColor: _C.mint,
      interactive: true,
      accentColor: _C.mint,
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  ResidentsScreen(trancheId: widget.tranche.id))),
    ),
    _ModuleData(
      label: 'Appartements',
      value: '${widget.tranche.nombreAppartements}',
      sub: 'unites',
      icon: Icons.home_rounded,
      iconBg: _C.blueLight,
      valueColor: _C.blue,
    ),
    _ModuleData(
      label: 'Personnel',
      value: '${_stats!['nbPersonnel']}',
      sub: 'employes',
      icon: Icons.badge_rounded,
      iconBg: _C.purpleLight,
      valueColor: _C.purple,
    ),
    _ModuleData(
      label: 'Parkings',
      value: '${_stats!['nbParkings']}',
      sub: 'places',
      icon: Icons.local_parking_rounded,
      iconBg: _C.coralLight,
      valueColor: _C.coral,
      interactive: true,
      accentColor: _C.coral,
    ),
    _ModuleData(
      label: 'Garages',
      value: '${_stats!['nbGarages']}',
      sub: 'places',
      icon: Icons.garage_rounded,
      iconBg: _C.amberLight,
      valueColor: _C.amber,
      interactive: true,
      accentColor: _C.amber,
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  GaragesScreen(trancheId: widget.tranche.id))),
    ),
    _ModuleData(
      label: 'Box',
      value: '${_stats!['nbBoxes']}',
      sub: 'unites',
      icon: Icons.inventory_2_rounded,
      iconBg: _C.greenLight,
      valueColor: _C.green,
    ),
    _ModuleData(
      label: 'Réunions',
      value: '${_stats!['nbReunions'] ?? 0}',
      sub: 'planifiées',
      icon: Icons.event_rounded,
      iconBg: _C.purpleLight,
      valueColor: _C.purple,
      interactive: true,
      accentColor: _C.purple,
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  ReunionsScreen(trancheId: widget.tranche.id))),
    ),
  ];

  Widget _buildModuleCard(_ModuleData m) {
    return GestureDetector(
      onTap: m.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: m.interactive
                  ? m.accentColor.withValues(alpha: 0.15)
                  : _C.divider),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: m.iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(m.icon, color: m.valueColor, size: 16),
                ),
                const SizedBox(height: 8),
                Text(m.label,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _C.dark)),
                const SizedBox(height: 1),
                Text(m.value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: m.valueColor,
                        height: 1.1)),
                Text(m.sub,
                    style: const TextStyle(fontSize: 9, color: _C.gray)),
              ],
            ),
            // Interactive arrow
            if (m.interactive)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: m.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      size: 11, color: m.accentColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -- Resume
  Widget _buildResume() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                    color: _C.mint, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              const Text('Resume de la Tranche',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _C.dark)),
            ],
          ),
          const SizedBox(height: 16),
          _resumeRow(
            _resumeItem(Icons.business_rounded, 'Immeubles',
                '${widget.tranche.nombreImmeubles}', _C.blue, _C.blueLight),
            _resumeItem(Icons.home_rounded, 'Appartements',
                '${widget.tranche.nombreAppartements}', _C.mint, _C.mintLight),
          ),
          Container(
              height: 1,
              color: _C.divider,
              margin: const EdgeInsets.symmetric(vertical: 12)),
          _resumeRow(
            _resumeItem(Icons.trending_up_rounded, 'Revenus',
                '+${_stats!['revenus']} DH', _C.green, _C.greenLight),
            _resumeItem(Icons.trending_down_rounded, 'Depenses',
                '-${_stats!['depenses']} DH', _C.coral, _C.coralLight),
          ),
        ],
      ),
    );
  }

  Widget _resumeRow(Widget a, Widget b) {
    return Row(
      children: [
        Expanded(child: a),
        Container(
            width: 1,
            height: 48,
            color: _C.divider,
            margin: const EdgeInsets.symmetric(horizontal: 16)),
        Expanded(child: b),
      ],
    );
  }

  Widget _resumeItem(IconData icon, String label, String value,
      Color color, Color bg) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: _C.gray, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

// -- Module data model (unchanged)
class _ModuleData {
  final String label, value, sub;
  final IconData icon;
  final Color iconBg, valueColor;
  final bool interactive;
  final Color accentColor;
  final VoidCallback? onTap;

  const _ModuleData({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.iconBg,
    required this.valueColor,
    this.interactive = false,
    this.accentColor = const Color(0xFF4CAF82),
    this.onTap,
  });
}