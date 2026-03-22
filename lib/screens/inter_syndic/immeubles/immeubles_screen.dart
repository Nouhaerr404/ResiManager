import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../models/immeuble_model.dart';
import '../../../models/tranche_model.dart';
import '../../../services/immeuble_service.dart';
import '../apartments/apartments_screen.dart';

class _C {
  static const coral = Color(0xFFE8603C);
  static const white = Color(0xFFFFFFFF);
  static const dark = Color(0xFF1A1A1A);
  static const bg = Color(0xFFF2F3F5);
  static const textMid = Color(0xFF5A5A6A);
  static const textLight = Color(0xFF9A9AAF);
}

class InterSyndicImmeublesScreen extends StatefulWidget {
  final TrancheModel tranche;

  const InterSyndicImmeublesScreen({super.key, required this.tranche});

  @override
  State<InterSyndicImmeublesScreen> createState() => _InterSyndicImmeublesScreenState();
}

class _InterSyndicImmeublesScreenState extends State<InterSyndicImmeublesScreen> {
  final _service = ImmeubleService();
  List<ImmeubleModel> _immeubles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await _service.getImmeublesByTranche(widget.tranche.id);
    setState(() {
      _immeubles = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Background - Consistent with TrancheDashboard
          Positioned.fill(
            child: Image.asset(
              'assets/images/tranche_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.4),
                    Color.fromRGBO(0, 0, 0, 0.8),
                  ],
                ),
              ),
            ),
          ),
          _loading ? _buildLoader() : _buildContent(),
        ],
      ),
    );
  }

  Widget _buildLoader() => const Center(
        child: CircularProgressIndicator(color: _C.coral),
      );

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildSliverHeader(),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildImmeubleCard(_immeubles[index]),
              childCount: _immeubles.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 140,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Espace Immeubles',
              style: TextStyle(
                  color: _C.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.5),
            ),
            Text(
              'Tranche ${widget.tranche.nom}',
              style: TextStyle(
                  color: _C.white.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImmeubleCard(ImmeubleModel imm) {
    // Calcul "adapté" basé sur la tranche si prixAnnuel est 0
    final displayPrice = imm.prixAnnuel > 0 ? imm.prixAnnuel : widget.tranche.prixAnnuel; 

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        color: Colors.white.withOpacity(0.9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _C.coral.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business_rounded, color: _C.coral, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        imm.nom, // Codification: ex "Immeuble A1"
                        style: const TextStyle(
                          color: _C.dark,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Codification: ${imm.nom.split(' ').last}',
                        style: const TextStyle(color: _C.textLight, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _chip('${imm.nombreAppartements} unités', _C.coral),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoColumn('Prix Annuel / Appt', '${displayPrice.toStringAsFixed(0)} DH'),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ApartmentsListScreen(
                          trancheId: widget.tranche.id,
                          residenceId: widget.tranche.residenceId,
                          immeubleId: imm.id, // Ajouté pour filtrer par immeuble
                          trancheName: widget.tranche.nom,
                          residenceName: widget.tranche.residenceNom,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.dark,
                    foregroundColor: _C.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Row(
                    children: [
                      Text('Voir Unités', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _C.textLight, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: _C.dark, fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final Color color;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.color = const Color.fromRGBO(255, 255, 255, 0.08),
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
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}
