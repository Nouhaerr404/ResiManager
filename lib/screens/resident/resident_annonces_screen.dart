import 'dart:async';
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
  Timer? _debounce;

  List<dynamic> _annonces = [];
  bool _isLoading = true;
  bool _hasMore = false;
  int _page = 0;
  final int _pageSize = 10;

  // Filtres
  String _searchQuery = '';
  String _filterType = 'tous';
  List<Map<String, dynamic>> _mandats = [];
  int? _selectedMandatId;
  static const _orange = Color(0xFFFF6B4A);

  @override
  void initState() {
    super.initState();
    _loadMandats();
    _fetchAnnonces();
  }

  Future<void> _loadMandats() async {
    final mandats = await _service.getMandatsVecus(widget.userId);
    if (mounted) {
      setState(() => _mandats = mandats.cast<Map<String, dynamic>>());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchAnnonces({bool resetPage = false}) async {
    if (resetPage) setState(() => _page = 0);
    setState(() => _isLoading = true);
    final result = await _service.getAnnoncesPaginated(
      userId: widget.userId,
      typeAnnonce: _filterType,
      searchQuery: _searchQuery,
      mandatId: _selectedMandatId,
      page: _page,
      pageSize: _pageSize,
    );
    setState(() {
      _annonces = result['annonces'];
      _hasMore = result['hasMore'];
      _isLoading = false;
    });
  }

  void _nextPage() {
    if (_hasMore) { setState(() => _page++); _fetchAnnonces(); }
  }

  void _prevPage() {
    if (_page > 0) { setState(() => _page--); _fetchAnnonces(); }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      setState(() => _searchQuery = value);
      _fetchAnnonces(resetPage: true);
    });
  }

  // ══════════════════════════════════════════════════════
  // BOTTOMSHEET SÉLECTEUR MANDAT
  // ══════════════════════════════════════════════════════
  void _showMandatPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Filtrer par mandat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(height: 1),

          // Option "Tous"
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: _orange, size: 18),
            ),
            title: const Text('Tous les mandats',
                style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: _selectedMandatId == null
                ? const Icon(Icons.check_circle_rounded, color: _orange)
                : null,
            onTap: () {
              setState(() => _selectedMandatId = null);
              Navigator.pop(ctx);
              _fetchAnnonces(resetPage: true);
            },
          ),

          // Liste mandats
          ..._mandats.map((m) {
            final bool isSel = _selectedMandatId == m['id'];
            final bool enCours = m['est_en_cours'] == true;
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: enCours
                      ? Colors.green.withOpacity(0.1)
                      : _orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  enCours ? Icons.radio_button_checked : Icons.history_rounded,
                  color: enCours ? Colors.green : _orange,
                  size: 18,
                ),
              ),
              title: Text(m['label'],
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSel ? _orange : Colors.black87)),
              subtitle: Text(
                '${m['syndic_nom']}${enCours ? ' · En cours' : ''}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              trailing: isSel
                  ? const Icon(Icons.check_circle_rounded, color: _orange)
                  : null,
              onTap: () {
                setState(() => _selectedMandatId = m['id'] as int);
                Navigator.pop(ctx);
                _fetchAnnonces(resetPage: true);
              },
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool inLayout = widget.onNavigate != null;

    // Libellé du mandat sélectionné
    String mandatLabel = 'Tous mandats';
    if (_selectedMandatId != null && _mandats.isNotEmpty) {
      final found = _mandats.where((m) => m['id'] == _selectedMandatId);
      if (found.isNotEmpty) mandatLabel = found.first['label'];
    }

    final body = Column(
      children: [
        // ── Header + Search + Filtres ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icône + Titre
                  Expanded(
                    child: Row(children: [
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
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Annonces",
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A1A1A),
                                      letterSpacing: -0.3)),
                              Text("Toutes vos annonces",
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12),
                                  overflow: TextOverflow.ellipsis),
                            ]),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),

                  // ── BOUTON MANDAT → ouvre BottomSheet ──
                  if (_mandats.isNotEmpty)
                    GestureDetector(
                      onTap: _showMandatPicker,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F4F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _orange.withOpacity(0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                            _selectedMandatId == null
                                ? Icons.calendar_month_rounded
                                : Icons.history_rounded,
                            size: 15, color: _orange,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: Text(
                              mandatLabel,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: _orange),
                        ]),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Barre de recherche ──
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F4F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Rechercher une annonce...",
                    hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.grey.shade400, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: Colors.grey.shade400, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                        _fetchAnnonces(resetPage: true);
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

              // ── Filtres par type ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _filterChip(label: "Toutes", value: 'tous',
                      color: const Color(0xFF2D2D2D)),
                  const SizedBox(width: 8),
                  _filterChip(label: "Urgentes", value: 'urgente',
                      color: _orange, icon: Icons.warning_amber_rounded),
                  const SizedBox(width: 8),
                  _filterChip(label: "Normales", value: 'normale',
                      color: const Color(0xFF2D2D2D),
                      icon: Icons.info_outline_rounded),
                  const SizedBox(width: 8),
                  _filterChip(label: "Informations", value: 'information',
                      color: const Color(0xFF4A90D9),
                      icon: Icons.campaign_outlined),
                ]),
              ),
            ],
          ),
        ),

        // ── Liste d'annonces ──
        Expanded(
          child: _isLoading
              ? const Center(
              child: CircularProgressIndicator(
                  color: _orange, strokeWidth: 2.5))
              : _annonces.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _searchQuery.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.campaign_outlined,
                    size: 32, color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? "Aucun résultat pour \"$_searchQuery\""
                      : "Aucune annonce trouvée.",
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
          )
              : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: _annonces.length,
                  itemBuilder: (context, index) {
                    final a = _annonces[index];
                    return _AnnonceCard(
                        annonce: a,
                        isUrgent: a['type'] == 'urgente');
                  },
                ),
              ),

              // ── Pagination ──
              if (_page > 0 || _hasMore)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _page > 0 ? _prevPage : null,
                        icon: const Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 16),
                        label: const Text("Précédent"),
                        style: TextButton.styleFrom(
                          foregroundColor: _orange,
                          disabledForegroundColor:
                          Colors.grey.shade400,
                        ),
                      ),
                      Text("Page ${_page + 1}",
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                              fontSize: 13)),
                      TextButton.icon(
                        onPressed: _hasMore ? _nextPage : null,
                        label: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16),
                        icon: const Text("Suivant"),
                        style: TextButton.styleFrom(
                          foregroundColor: _orange,
                          disabledForegroundColor:
                          Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    if (inLayout) return body;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: const Text("Annonces",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.3)),
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
    required String value,
    required Color color,
    IconData? icon,
  }) {
    final selected = _filterType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filterType = value);
        _fetchAnnonces(resetPage: true);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13,
                color: selected ? Colors.white : Colors.grey.shade500),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// CARTE ANNONCE
// ══════════════════════════════════════════════════════
class _AnnonceCard extends StatelessWidget {
  final Map annonce;
  final bool isUrgent;

  const _AnnonceCard({required this.annonce, required this.isUrgent});

  @override
  Widget build(BuildContext context) {
    final createdAt = annonce['created_at'].toString();
    String dateStr = createdAt.split('T')[0];
    if (createdAt.length >= 10) {
      final parts = dateStr.split('-');
      if (parts.length == 3) dateStr = "${parts[2]}/${parts[1]}/${parts[0]}";
    }

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
                              annonce['titre'] ?? 'Sans Titre',
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
                              child: const Text("URGENT",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  )),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(annonce['contenu'] ?? '',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            height: 1.5,
                            letterSpacing: 0.1,
                          )),
                      const SizedBox(height: 12),
                      Row(children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 5),
                        Text("Publié le $dateStr",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              letterSpacing: 0.2,
                            )),
                      ]),
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