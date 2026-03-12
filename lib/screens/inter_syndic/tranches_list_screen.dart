// lib/screens/inter_syndic/tranches_list_screen.dart
import 'package:flutter/material.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';
import '../../utils/temp_session.dart';
import 'tranche_dashboard_screen.dart';

// ── Brand Colors (unified with garage/resident/dashboard screens)
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
  static const green       = Color(0xFF16A34A);
  static const greenLight  = Color(0xFFF0FDF4);
}

class TranchesListScreen extends StatefulWidget {
  const TranchesListScreen({super.key});
  @override
  State<TranchesListScreen> createState() => _TranchesListScreenState();
}

class _TranchesListScreenState extends State<TranchesListScreen>
    with SingleTickerProviderStateMixin {
  final _service = TrancheService();
  List<TrancheModel> _tranches = [];
  bool _loading = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadTranches();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTranches() async {
    setState(() => _loading = true);
    try {
      final data = await _service
          .getTranchesOfInterSyndic(TempSession.interSyndicId)
          .timeout(const Duration(seconds: 10));
      setState(() {
        _tranches = data;
        _loading = false;
      });
      _fadeCtrl.forward();
    } catch (e) {
      setState(() => _loading = false);
    }
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
              child: RefreshIndicator(
                color: _C.mint,
                onRefresh: _loadTranches,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    const SizedBox(height: 20),
                    _buildHeroCard(),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Vos Tranches'),
                    const SizedBox(height: 12),
                    ..._tranches
                        .asMap()
                        .entries
                        .map((e) => _buildTrancheCard(e.value, e.key)),
                  ],
                ),
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
        CircularProgressIndicator(color: _C.mint, strokeWidth: 3),
        SizedBox(height: 14),
        Text('Chargement…',
            style: TextStyle(color: _C.gray, fontSize: 13)),
      ],
    ),
  );

  // ── Header
  Widget _buildHeader() {
    return Container(
      color: _C.white,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          bottom: 16,
          left: 20,
          right: 20),
      child: Row(
        children: [
          // Logo pill
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _C.dark,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: _C.mint, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('ResiManager',
                    style: TextStyle(
                        color: _C.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.3)),
              ],
            ),
          ),
          const Spacer(),
          // Espace badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _C.mintLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _C.mint.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.verified_rounded, size: 12, color: _C.mint),
                SizedBox(width: 5),
                Text('Espace Syndic',
                    style: TextStyle(
                        color: _C.mint,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Banner
  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.dark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: _C.mint, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.holiday_village_rounded,
                color: _C.white, size: 26),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TABLEAU DE BORD',
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
                        text: '${_tranches.length} ',
                        style: const TextStyle(
                            color: _C.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1)),
                    const TextSpan(
                        text: 'tranches',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              const Text('affectées à votre compte',
                  style: TextStyle(
                      color: Colors.white38, fontSize: 11)),
            ],
          ),
          const Spacer(),
          Text('${DateTime.now().year}',
              style: const TextStyle(
                  color: Colors.white12,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Stats Row (3 white cards like garage/resident screens)
  Widget _buildStatsRow() {
    final totalAppts = _tranches.fold(0, (s, t) => s + t.nombreAppartements);
    final totalImm   = _tranches.fold(0, (s, t) => s + t.nombreImmeubles);
    final totalParks = _tranches.fold(0, (s, t) => s + t.nombreParkings);

    return Row(
      children: [
        _statCard(
          icon: Icons.business_rounded,
          iconBg: _C.blueLight,
          iconColor: _C.blue,
          value: '$totalImm',
          label: 'Immeubles',
        ),
        const SizedBox(width: 12),
        _statCard(
          icon: Icons.home_rounded,
          iconBg: _C.mintLight,
          iconColor: _C.mint,
          value: '$totalAppts',
          label: 'Appts',
        ),
        const SizedBox(width: 12),
        _statCard(
          icon: Icons.local_parking_rounded,
          iconBg: _C.amberLight,
          iconColor: _C.amber,
          value: '$totalParks',
          label: 'Parkings',
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(height: 10),
              Text(value,
                  style: const TextStyle(
                      color: _C.dark,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
              Text(label,
                  style:
                  const TextStyle(color: _C.gray, fontSize: 10)),
            ],
          ),
        ),
      );

  // ── Section label
  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
                color: _C.mint,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                color: _C.dark,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
      ],
    );
  }

  // ── Tranche Card
  Widget _buildTrancheCard(TrancheModel t, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TrancheDashboardScreen(tranche: t))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _C.mintLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.domain_rounded,
                  color: _C.mint, size: 22),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.nom,
                      style: const TextStyle(
                          color: _C.dark,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                  if (t.description != null) ...[
                    const SizedBox(height: 3),
                    Text(t.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _C.gray, fontSize: 12)),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _chip(Icons.business_rounded,
                          '${t.nombreImmeubles} imm.',
                          _C.blueLight, _C.blue),
                      _chip(Icons.home_rounded,
                          '${t.nombreAppartements} appts',
                          _C.mintLight, _C.mint),
                      _chip(Icons.local_parking_rounded,
                          '${t.nombreParkings} parks',
                          _C.amberLight, _C.amber),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Arrow
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _C.mintLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: _C.mint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}