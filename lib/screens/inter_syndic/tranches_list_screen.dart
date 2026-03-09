// lib/screens/inter_syndic/tranches_list_screen.dart
import 'package:flutter/material.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';
import '../../utils/temp_session.dart';
import 'tranche_dashboard_screen.dart';

// ── Brand Colors
class _C {
  static const mint        = Color(0xFF5FD4A0);
  static const mintLight   = Color(0xFFE8F8F2);
  static const mintMid     = Color(0xFFB2EADA);
  static const coral       = Color(0xFFFF6B4A);
  static const coralLight  = Color(0xFFFFEDE9);
  static const cream       = Color(0xFFF5EFE7);
  static const darkText    = Color(0xFF2D2D2D);
  static const grayText    = Color(0xFF6B6B6B);
  static const white       = Color(0xFFFFFFFF);
  static const divider     = Color(0xFFEDE8E0);
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
                    const SizedBox(height: 28),
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
  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(
              color: _C.mint, strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text('Chargement…',
              style: TextStyle(color: _C.grayText, fontSize: 14,
                  fontFamily: 'serif')),
        ],
      ),
    );
  }

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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _C.darkText,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _C.mintLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.mintMid),
            ),
            child: const Text('Espace Syndic',
                style: TextStyle(
                    color: _C.mint,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Hero Banner
  Widget _buildHeroCard() {
    final totalAppts = _tranches.fold(0, (s, t) => s + t.nombreAppartements);
    final totalImm   = _tranches.fold(0, (s, t) => s + t.nombreImmeubles);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _C.darkText,
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          // subtle dot pattern overlay via a tinted box
          image: AssetImage('assets/images/pattern.png'),
          fit: BoxFit.cover,
          opacity: 0.04,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon row
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _C.mint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.holiday_village_rounded,
                    color: _C.white, size: 22),
              ),
              const Spacer(),
              Text('${DateTime.now().year}',
                  style: const TextStyle(
                      color: Colors.white24, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),
          // Big number
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_tranches.length}',
                  style: const TextStyle(
                      color: _C.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      height: 1)),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text('tranches\naffectées',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        height: 1.4)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Divider
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _heroStat('$totalImm', 'immeubles'),
              _heroDivider(),
              _heroStat('$totalAppts', 'appartements'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String val, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(val,
              style: const TextStyle(
                  color: _C.mint,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _heroDivider() {
    return Container(
        width: 1, height: 36, color: Colors.white12,
        margin: const EdgeInsets.symmetric(horizontal: 16));
  }

  // ── Section label
  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(width: 4, height: 18,
            decoration: BoxDecoration(
                color: _C.coral, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                color: _C.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
      ],
    );
  }

  // ── Tranche Card
  Widget _buildTrancheCard(TrancheModel t, int index) {
    // Alternate accent: even = mint, odd = coral
    final accentColor  = index.isEven ? _C.mint  : _C.coral;
    final accentLight  = index.isEven ? _C.mintLight : _C.coralLight;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TrancheDashboardScreen(tranche: t))),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300 + index * 60),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.divider),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: accentLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.domain_rounded,
                  color: accentColor, size: 26),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.nom,
                      style: const TextStyle(
                          color: _C.darkText,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  if (t.description != null) ...[
                    const SizedBox(height: 3),
                    Text(t.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _C.grayText, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 12),
                  // Stats chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _chip(Icons.business_rounded,
                          '${t.nombreImmeubles} imm.', _C.mintLight, _C.mint),
                      _chip(Icons.door_front_door_rounded,
                          '${t.nombreAppartements} appts',
                          _C.coralLight, _C.coral),
                      _chip(Icons.local_parking_rounded,
                          '${t.nombreParkings} parks',
                          const Color(0xFFFFF7E6), const Color(0xFFF59E0B)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Arrow
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _C.cream,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: _C.grayText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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