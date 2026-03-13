// lib/screens/inter_syndic/tranches_list_screen.dart
import 'package:flutter/material.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';
import '../../utils/temp_session.dart';
import 'tranche_dashboard_screen.dart';

// ── Brand Colors — aligned with ResiManager desktop app
class _C {
  static const coral       = Color(0xFFE8603C); // primary accent (orange-red)
  static const coralLight  = Color(0xFFFFF0EB);
  static const coralMid    = Color(0xFFFFD5C8);
  static const bg          = Color(0xFFF2F3F5); // app background
  static const white       = Color(0xFFFFFFFF);
  static const dark        = Color(0xFF1A1A1A); // headings
  static const textMid     = Color(0xFF5A5A6A); // secondary text
  static const textLight   = Color(0xFF9A9AAF); // tertiary/labels
  static const divider     = Color(0xFFE8E8F0);
  static const blue        = Color(0xFF4B6BFB);
  static const blueLight   = Color(0xFFEEF1FF);
  static const amber       = Color(0xFFF5A623);
  static const amberLight  = Color(0xFFFFF8EC);
  static const green       = Color(0xFF34C98B);
  static const greenLight  = Color(0xFFEBFAF4);
  static const iconBg      = Color(0xFFEDEDED); // neutral icon backgrounds
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
        vsync: this, duration: const Duration(milliseconds: 500));
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
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? _buildLoader()
                : FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
                color: _C.coral,
                onRefresh: _loadTranches,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    _buildPageTitle(),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 32),
                    _buildSectionLabel('Tranches'),
                    const SizedBox(height: 14),
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
        CircularProgressIndicator(color: _C.coral, strokeWidth: 2.5),
        SizedBox(height: 16),
        Text('Chargement…',
            style: TextStyle(
                color: _C.textLight,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ],
    ),
  );

  // ── Header — mirrors app's top bar with logo + Espace Syndic button
  // Remplace UNIQUEMENT la méthode _buildHeader() dans tranches_list_screen.dart

  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: _C.white,
      padding: EdgeInsets.only(
          top: top + 14, bottom: 14, left: 16, right: 16),
      child: Row(
        children: [
          // ── Bouton RETOUR (fond blanc, bordure grise)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.divider, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  color: _C.dark, size: 24),
            ),
          ),

          const SizedBox(width: 10),

          // ── Bouton GRILLE (fond coral)
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _C.coral,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.grid_view_rounded,
                color: _C.white, size: 20),
          ),

          const SizedBox(width: 12),

          // ── Nom app + rôle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('ResiManager',
                  style: TextStyle(
                      color: _C.dark,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2)),
              Text('inter_syndic',
                  style: TextStyle(
                      color: _C.textLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),

          const Spacer(),

          // ── Bouton Espace Syndic
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _C.dark,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.work_outline_rounded, size: 13, color: _C.white),
                SizedBox(width: 6),
                Text('Espace Syndic',
                    style: TextStyle(
                        color: _C.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Page title — mirrors "Tableau de Bord / Vue d'ensemble" heading
  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tableau de Bord',
            style: TextStyle(
                color: _C.dark,
                fontWeight: FontWeight.w800,
                fontSize: 26,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        const Text("Vue d'ensemble de vos tranches",
            style: TextStyle(
                color: _C.textMid, fontSize: 13, fontWeight: FontWeight.w400)),
      ],
    );
  }

  // ── Stats Row — 4 cards like the app (Syndics Actifs / Tranches / Immeubles / Appts)
  Widget _buildStatsRow() {
    final totalAppts = _tranches.fold(0, (s, t) => s + t.nombreAppartements);
    final totalImm   = _tranches.fold(0, (s, t) => s + t.nombreImmeubles);
    final totalParks = _tranches.fold(0, (s, t) => s + t.nombreParkings);

    return Column(
      children: [
        Row(
          children: [
            _statCard(
              icon: Icons.grid_view_rounded,
              iconBg: _C.coralLight,
              iconColor: _C.coral,
              value: '${_tranches.length}',
              label: 'Tranches',
            ),
            const SizedBox(width: 12),
            _statCard(
              icon: Icons.business_rounded,
              iconBg: _C.iconBg,
              iconColor: _C.dark,
              value: '$totalImm',
              label: 'Immeubles',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard(
              icon: Icons.home_outlined,
              iconBg: _C.coralLight,
              iconColor: _C.coral,
              value: '$totalAppts',
              label: 'Appartements',
            ),
            const SizedBox(width: 12),
            _statCard(
              icon: Icons.local_parking_rounded,
              iconBg: _C.iconBg,
              iconColor: _C.dark,
              value: '$totalParks',
              label: 'Parkings',
            ),
          ],
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.divider, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: _C.textMid,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          color: _C.dark,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          letterSpacing: -0.5)),
                ],
              ),
            ],
          ),
        ),
      );

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

  // ── Tranche Card — clean white card like app's stat cards
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.divider, width: 1),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _C.coralLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
              const Icon(Icons.grid_view_rounded, color: _C.coral, size: 22),
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
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: -0.2)),
                  if (t.description != null) ...[
                    const SizedBox(height: 2),
                    Text(t.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _C.textLight, fontSize: 12)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _chip(Icons.business_rounded,
                          '${t.nombreImmeubles} imm.', _C.iconBg, _C.textMid),
                      const SizedBox(width: 6),
                      _chip(Icons.home_outlined,
                          '${t.nombreAppartements} appts', _C.coralLight, _C.coral),
                      const SizedBox(width: 6),
                      _chip(Icons.local_parking_rounded,
                          '${t.nombreParkings} parks', _C.iconBg, _C.textMid),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Arrow chevron
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: _C.textLight),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
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