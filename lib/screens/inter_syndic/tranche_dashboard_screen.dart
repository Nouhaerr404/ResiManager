// lib/screens/inter_syndic/tranche_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';
import 'garages/garages_screen.dart';
import 'residents/residents_screen.dart';

// -- Brand palette
class _C {
  static const mint         = Color(0xFF5FD4A0);
  static const mintLight    = Color(0xFFE8F8F2);
  static const mintMid      = Color(0xFFB2EADA);
  static const coral        = Color(0xFFFF6B4A);
  static const coralLight   = Color(0xFFFFEDE9);
  static const cream        = Color(0xFFF5EFE7);
  static const dark         = Color(0xFF2D2D2D);
  static const gray         = Color(0xFF6B6B6B);
  static const divider      = Color(0xFFEDE8E0);
  static const white        = Color(0xFFFFFFFF);
  static const amber        = Color(0xFFF59E0B);
  static const amberLight   = Color(0xFFFFF7E6);
  static const blue         = Color(0xFF3B82F6);
  static const blueLight    = Color(0xFFEFF6FF);
  static const purple       = Color(0xFF8B5CF6);
  static const purpleLight  = Color(0xFFF5F3FF);
  static const green        = Color(0xFF16A34A);
  static const greenLight   = Color(0xFFF0FDF4);
  static const coralSoft    = Color(0xFFFF8A75);
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
  Widget _buildLoader() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
              color: _C.mint, strokeWidth: 3),
        ),
        const SizedBox(height: 16),
        const Text('Chargement...',
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
          // Back + Title row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _C.cream,
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                  _C.mintLight, _C.mint, _C.mintMid),
              _pill(Icons.door_front_door_rounded,
                  '${widget.tranche.nombreAppartements} appts',
                  _C.coralLight, _C.coral, _C.coralLight),
              _pill(Icons.local_parking_rounded,
                  '${widget.tranche.nombreParkings} parkings',
                  _C.amberLight, _C.amber, _C.amberLight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label,
      Color bg, Color fg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
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

  // -- Finance Banner
  Widget _buildFinanceBanner() {
    final solde    = _stats!['solde']    ?? 0;
    final revenus  = _stats!['revenus']  ?? 0;
    final depenses = _stats!['depenses'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.dark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SOLDE ACTUEL',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontFamily: 'sans-serif'),
              children: [
                TextSpan(
                    text: '$solde ',
                    style: const TextStyle(
                        color: _C.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 1)),
                const TextSpan(
                    text: 'DH',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 20,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 14),
          Row(
            children: [
              _financeStat('+$revenus DH', 'Revenus', _C.mint),
              Container(
                  width: 1,
                  height: 36,
                  color: Colors.white12,
                  margin: const EdgeInsets.symmetric(horizontal: 16)),
              _financeStat('-$depenses DH', 'Depenses', _C.coralSoft),
            ],
          ),
        ],
      ),
    );
  }

  Widget _financeStat(String val, String label, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(val,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 10)),
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
            height: 18,
            decoration: BoxDecoration(
                color: _C.coral, borderRadius: BorderRadius.circular(2))),
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
        childAspectRatio: 1.45,
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
      onTap: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => ResidentsScreen(trancheId: widget.tranche.id))),
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
      onTap: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => GaragesScreen(trancheId: widget.tranche.id))),
    ),
    _ModuleData(
      label: 'Box',
      value: '${_stats!['nbBoxes']}',
      sub: 'unites',
      icon: Icons.inventory_2_rounded,
      iconBg: _C.greenLight,
      valueColor: _C.green,
    ),
  ];

  Widget _buildModuleCard(_ModuleData m) {
    return GestureDetector(
      onTap: m.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.divider),
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: m.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(m.icon, color: m.valueColor, size: 20),
                ),
                const SizedBox(height: 10),
                Text(m.label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _C.dark)),
                const SizedBox(height: 2),
                Text(m.value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: m.valueColor,
                        height: 1.1)),
                Text(m.sub,
                    style: const TextStyle(
                        fontSize: 10, color: _C.gray)),
              ],
            ),
            // Interactive arrow
            if (m.interactive)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: _C.cream,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 11, color: _C.gray),
                ),
              ),
            // Left accent bar
            if (m.interactive)
              Positioned(
                left: 0, top: 16, bottom: 16,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: m.accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Resume
  Widget _buildResume() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: _C.mint, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('Resume de la Tranche',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _C.dark)),
            ],
          ),
          const SizedBox(height: 14),
          _resumeRow(
            _resumeItem('Immeubles',
                '${widget.tranche.nombreImmeubles}', _C.dark),
            _resumeItem('Appartements',
                '${widget.tranche.nombreAppartements}', _C.dark),
          ),
          Container(height: 1, color: _C.divider,
              margin: const EdgeInsets.symmetric(vertical: 12)),
          _resumeRow(
            _resumeItem('Revenus',
                '+${_stats!['revenus']} DH', _C.green),
            _resumeItem('Depenses',
                '-${_stats!['depenses']} DH', _C.coral),
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
            width: 1, height: 40,
            color: _C.divider,
            margin: const EdgeInsets.symmetric(horizontal: 16)),
        Expanded(child: b),
      ],
    );
  }

  Widget _resumeItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: _C.gray, fontSize: 11)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
      ],
    );
  }
}

// -- Module data model
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
    this.accentColor = const Color(0xFF5FD4A0),
    this.onTap,
  });
}