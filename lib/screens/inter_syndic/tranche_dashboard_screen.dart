// lib/screens/inter_syndic/tranche_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';
import 'garages/garages_screen.dart';
import 'residents/residents_screen.dart';
import 'reunions/reunions_screen.dart';
import 'finance/finance_dashboard_screen.dart';
import 'apartments/apartments_screen.dart';

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
  String _selectedView = 'dashboard'; // 'dashboard' or 'apartments'

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
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? _buildLoader()
                : FadeTransition(
              opacity: _fadeAnim,
              child: _selectedView == 'apartments' 
                ? ApartmentsListScreen(trancheId: widget.tranche.id, onBack: () => setState(() => _selectedView = 'dashboard'))
                : ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  _buildPageTitle(),
                  const SizedBox(height: 20),
                  _buildFinanceBanner(),
                  const SizedBox(height: 32),
                  _buildSectionLabel('Modules'),
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
    );
  }

  // ── Loader
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

  // ── Header — white top bar with back button
  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: _C.white,
      padding: EdgeInsets.only(
          top: top + 14, bottom: 14, left: 16, right: 16),
      child: Row(
        children: [
          // Back button
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
          // App logo pill
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
          // Refresh
          GestureDetector(
            onTap: _loadStats,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.divider)),
              child:
              const Icon(Icons.refresh_rounded, size: 18, color: _C.dark),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page title + quick-stat chips
  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.tranche.nom,
            style: const TextStyle(
                color: _C.dark,
                fontWeight: FontWeight.w800,
                fontSize: 24,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        const Text('Mohammed Benali · Syndic',
            style: TextStyle(
                color: _C.textMid,
                fontSize: 13,
                fontWeight: FontWeight.w400)),
        const SizedBox(height: 14),
        // Chips row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(Icons.business_rounded,
                '${widget.tranche.nombreImmeubles} immeubles',
                _C.iconBg, _C.dark),
            _chip(Icons.door_front_door_rounded,
                '${widget.tranche.nombreAppartements} appts',
                _C.coralLight, _C.coral),
            _chip(Icons.local_parking_rounded,
                '${widget.tranche.nombreParkings} parkings',
                _C.iconBg, _C.dark),
          ],
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Finance Banner — matches app's "Résumé Financier" section
  Widget _buildFinanceBanner() {
    final solde    = _stats!['solde']    ?? 0;
    final revenus  = _stats!['revenus']  ?? 0;
    final depenses = _stats!['depenses'] ?? 0;

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
          _buildSectionLabel('Résumé Financier'),
          const SizedBox(height: 14),
          // Solde hero card — dark like app
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _C.dark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: _C.coral,
                      borderRadius: BorderRadius.circular(12)),
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
                              text: '$solde ',
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
          // Revenus + Dépenses
          Row(
            children: [
              Expanded(
                child: _financeCard(
                  icon: Icons.trending_up_rounded,
                  iconBg: _C.greenLight,
                  iconColor: _C.green,
                  label: 'Revenus Parkings',
                  value: '${revenus.toStringAsFixed(2)} DH',
                  sub: 'par mois',
                  valueColor: _C.dark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _financeCard(
                  icon: Icons.trending_down_rounded,
                  iconBg: _C.coralLight,
                  iconColor: _C.coral,
                  label: 'Charges Totales',
                  value: '${depenses.toStringAsFixed(2)} DH',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: _C.textLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        color: valueColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.3)),
                Text(sub,
                    style: const TextStyle(
                        color: _C.textLight, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label — matches app's bold section headers
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          color: _C.dark,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: -0.3),
    );
  }

  // ── Modules Grid
  Widget _buildModulesGrid() {
    final modules = _buildModuleList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.3, // Increased to avoid overflow
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
      iconBg: _C.coralLight,
      valueColor: _C.coral,
      interactive: true,
      accentColor: _C.coral,
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
      icon: Icons.home_outlined,
      iconBg: _C.iconBg,
      valueColor: _C.dark,
      interactive: true,
      onTap: () => setState(() => _selectedView = 'apartments'),
    ),
    _ModuleData(
      label: 'Personnel',
      value: '${_stats!['nbPersonnel']}',
      sub: 'employes',
      icon: Icons.badge_outlined,
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
      icon: Icons.garage_outlined,
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
      icon: Icons.inventory_2_outlined,
      iconBg: _C.greenLight,
      valueColor: _C.green,
    ),
    _ModuleData(
      label: 'Réunions',
      value: '${_stats!['nbReunions'] ?? 0}',
      sub: 'planifiées',
      icon: Icons.event_outlined,
      iconBg: _C.blueLight,
      valueColor: _C.blue,
      interactive: true,
      accentColor: _C.blue,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
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
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _C.textMid)),
                  const SizedBox(height: 1),
                      Text(m.value,
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: _C.dark,
                          letterSpacing: -0.5,
                          height: 1.2)), // Reduced height to avoid overflow
                ],
              ),
            ),
            if (m.interactive)
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: _C.textLight),
          ],
        ),
      ),
    );
  }

  // ── Resume
  Widget _buildResume() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Résumé de la Tranche'),
          const SizedBox(height: 16),
          _resumeRow(
            _resumeItem(Icons.business_rounded, 'Immeubles',
                '${widget.tranche.nombreImmeubles}', _C.blue, _C.blueLight),
            _resumeItem(Icons.home_outlined, 'Appartements',
                '${widget.tranche.nombreAppartements}', _C.coral, _C.coralLight),
          ),
          Container(
              height: 1,
              color: _C.divider,
              margin: const EdgeInsets.symmetric(vertical: 14)),
          _resumeRow(
            _resumeItem(Icons.trending_up_rounded, 'Revenus',
                '+${_stats!['revenus']} DH', _C.green, _C.greenLight),
            _resumeItem(Icons.trending_down_rounded, 'Dépenses',
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

  Widget _resumeItem(
      IconData icon, String label, String value, Color color, Color bg) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: _C.textLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: _C.dark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

// ── Module data model
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
    this.accentColor = const Color(0xFFE8603C),
    this.onTap,
  });
}