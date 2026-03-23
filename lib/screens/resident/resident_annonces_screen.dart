import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import 'resident_dashboard_screen.dart';

class ResidentAnnoncesScreen extends StatefulWidget {
  final int userId;
  final Function(int)? onNavigate;

  const ResidentAnnoncesScreen({super.key, this.userId = 3, this.onNavigate});

  @override
  State<ResidentAnnoncesScreen> createState() => _ResidentAnnoncesScreenState();
}

class _ResidentAnnoncesScreenState extends State<ResidentAnnoncesScreen> {
  final ResidentService _service = ResidentService();
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String _filterType = 'tous'; // 'tous', 'normale', 'urgente'

  static const _orange = Color(0xFFFF6B4A);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool inLayout = widget.onNavigate != null;

    final body = FutureBuilder<Map<String, dynamic>>(
      future: _service.getAnnoncesAndReunions(widget.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: _orange,
                  strokeWidth: 2.5,
                ),
                const SizedBox(height: 16),
                Text(
                  "Chargement des annonces...",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          );

        final List allAnnonces = snapshot.data!['annonces'];

        // Filtrage
        final filtered = allAnnonces.where((a) {
          final matchType = _filterType == 'tous' || a['type'] == _filterType;
          final matchSearch = _searchQuery.isEmpty ||
              (a['titre'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (a['contenu'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
          return matchType && matchSearch;
        }).toList();

        final urgentCount = allAnnonces.where((a) => a['type'] == 'urgente').length;
        final normaleCount = allAnnonces.where((a) => a['type'] == 'normale').length;
        final infoCount = allAnnonces.where((a) => a['type'] == 'information').length; // ← AJOUTER


        return Column(
          children: [
            // ── Header + Search + Filtres ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + badge total
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [_orange, Color(0xFFFF9A6C)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.campaign_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Annonces",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.3)),
                      Text("${allAnnonces.length} annonce${allAnnonces.length > 1 ? 's' : ''}",
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ]),
                  ]),
                  const SizedBox(height: 14),
                  // Barre de recherche
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F4F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Rechercher une annonce...",
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: Colors.grey.shade400, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: Colors.grey.shade400, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filtres par type
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _filterChip(
                        label: "Toutes",
                        count: allAnnonces.length,
                        value: 'tous',
                        color: const Color(0xFF2D2D2D),
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        label: "Urgentes",
                        count: urgentCount,
                        value: 'urgente',
                        color: _orange,
                        icon: Icons.warning_amber_rounded,
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        label: "Normales",
                        count: normaleCount,
                        value: 'normale',
                        color: const Color(0xFF2D2D2D),
                        icon: Icons.info_outline_rounded,
                      ),
                      const SizedBox(width: 8), // ← AJOUTER
                      _filterChip(              // ← AJOUTER
                        label: "Informations",
                        count: infoCount,
                        value: 'information',
                        color: const Color(0xFF4A90D9), // bleu
                        icon: Icons.campaign_outlined,
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            // ── Liste ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _searchQuery.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.campaign_outlined,
                        size: 32,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty
                          ? "Aucun résultat pour \"$_searchQuery\""
                          : "Aucune annonce pour le moment",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final a = filtered[index];
                  bool isUrgent = a['type'] == 'urgente';
                  return _AnnonceCard(annonce: a, isUrgent: isUrgent);
                },
              ),
            ),
          ],
        );
      },
    );

    if (inLayout) return body;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: const Text(
          "Annonces",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: const Color(0xFFF5F4F0),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _orange),
      ),
      drawer: ResidentMobileDrawer(currentIndex: 3, userId: widget.userId),
      body: body,
    );
  }

  Widget _filterChip({
    required String label,
    required int count,
    required String value,
    required Color color,
    IconData? icon,
  }) {
    final selected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon,
                size: 13,
                color: selected ? Colors.white : Colors.grey.shade500),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withOpacity(0.25)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _AnnonceCard extends StatelessWidget {
  final Map annonce;
  final bool isUrgent;

  const _AnnonceCard({required this.annonce, required this.isUrgent});

  @override
  Widget build(BuildContext context) {
    final dateStr = annonce['created_at'].toString().split('T')[0];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isUrgent
                ? const Color(0xFFFF6B4A).withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barre colorée gauche
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isUrgent
                        ? [const Color(0xFFFF6B4A), const Color(0xFFFF9A6C)]
                        : [const Color(0xFF2D2D2D), const Color(0xFF6B6B6B)],
                  ),
                ),
              ),
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              annonce['titre'],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.2,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (isUrgent) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B4A),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "URGENT",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        annonce['contenu'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Footer sans flèche
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Publié le $dateStr",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}