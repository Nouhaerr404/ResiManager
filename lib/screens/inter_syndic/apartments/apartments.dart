import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// BRAND PALETTE
// ============================================================================
class _C {
  static const mint        = Color(0xFF5FD4A0);
  static const mintLight   = Color(0xFFE8F8F2);
  static const mintMid     = Color(0xFFB2EADA);
  static const coral       = Color(0xFFFF6B4A);
  static const coralLight  = Color(0xFFFFEDE9);
  static const cream       = Color(0xFFF5EFE7);
  static const dark        = Color(0xFF2D2D2D);
  static const gray        = Color(0xFF6B6B6B);
  static const divider     = Color(0xFFEDE8E0);
  static const white       = Color(0xFFFFFFFF);
  static const amber       = Color(0xFFF59E0B);
  static const amberLight  = Color(0xFFFFF7E6);
  static const blue        = Color(0xFF3B82F6);
  static const blueLight   = Color(0xFFEFF6FF);
  static const green       = Color(0xFF16A34A);
  static const greenLight  = Color(0xFFF0FDF4);
}

// ============================================================================
// MODELS (unchanged logic)
// ============================================================================
enum ApartmentStatus { occupied, vacant }

class Apartment {
  final int id;
  final int residence;
  final int tranche;
  final int immeuble;
  final int numeroAppartement;
  final ApartmentStatus statut;
  final int? residentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Apartment({
    required this.id,
    required this.residence,
    required this.tranche,
    required this.immeuble,
    required this.numeroAppartement,
    required this.statut,
    this.residentId,
    required this.createdAt,
    required this.updatedAt,
  });

  String get numero =>
      'R$residence-T$tranche-Imm$immeuble-$numeroAppartement';

  factory Apartment.fromMap(Map<String, dynamic> map) {
    final numeroRaw = map['numero'] ?? '';
    final numero =
    numeroRaw is String ? numeroRaw : numeroRaw.toString();
    int residence = 0, tranche = 0, immeuble = 0, numeroAppartement = 0;
    try {
      final parts = numero.split('-');
      if (parts.length >= 4) {
        residence = int.parse(parts[0].substring(1));
        tranche = int.parse(parts[1].substring(1));
        immeuble = int.parse(parts[2].substring(3));
        numeroAppartement = int.parse(parts[3]);
      }
    } catch (_) {}

    final statutRaw = (map['statut'] ?? '').toString().toLowerCase();
    final statut = statutRaw.contains('lib') || statutRaw == 'vacant'
        ? ApartmentStatus.vacant
        : ApartmentStatus.occupied;

    DateTime parseDate(dynamic raw) {
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.parse(raw);
      return DateTime.now();
    }

    return Apartment(
      id: map['id'] is int ? map['id'] : int.parse(map['id'].toString()),
      residence: residence,
      tranche: tranche,
      immeuble: immeuble,
      numeroAppartement: numeroAppartement,
      statut: statut,
      residentId: map['resident_id'] == null
          ? null
          : (map['resident_id'] is int
          ? map['resident_id']
          : int.parse(map['resident_id'].toString())),
      createdAt: parseDate(
          map['created_at'] ?? map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: parseDate(
          map['updated_at'] ?? map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// ============================================================================
// APARTMENT CARD
// ============================================================================
class ApartmentCard extends StatelessWidget {
  final Apartment apartment;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onAssign;
  final VoidCallback? onDelete;

  const ApartmentCard({
    Key? key,
    required this.apartment,
    this.onTap,
    this.onEdit,
    this.onAssign,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOccupied = apartment.statut == ApartmentStatus.occupied;
    final statusColor = isOccupied ? _C.mint : _C.amber;
    final statusBg    = isOccupied ? _C.mintLight : _C.amberLight;
    final statusLabel = isOccupied ? 'Occupe' : 'Vacant';
    final canDelete   = !isOccupied && apartment.residentId == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Top row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.home_rounded,
                      color: statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                // Number + address path
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(apartment.numero,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: _C.dark)),
                      const SizedBox(height: 3),
                      Text(
                        'Imm. ${apartment.immeuble}  ·  Tranche ${apartment.tranche}  ·  Res. ${apartment.residence}',
                        style: const TextStyle(
                            color: _C.gray, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),

            // -- Resident info if occupied
            if (isOccupied) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: _C.mintLight,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                          color: _C.mint,
                          borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.person_rounded,
                          color: _C.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text('Resident ID: ${apartment.residentId}',
                        style: const TextStyle(
                            color: _C.dark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    const Spacer(),
                    Text('Occupe',
                        style: const TextStyle(
                            color: _C.mint,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // -- Actions row
            Row(
              children: [
                // Assign (only if vacant)
                if (!isOccupied) ...[
                  Expanded(
                    child: _actionBtn(
                      label: 'Assigner',
                      icon: Icons.person_add_rounded,
                      color: _C.mint,
                      bg: _C.mintLight,
                      onTap: onAssign,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Edit
                _squareBtn(
                  icon: Icons.edit_rounded,
                  color: _C.blue,
                  bg: _C.blueLight,
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                // Delete
                _squareBtn(
                  icon: Icons.delete_rounded,
                  color: canDelete ? _C.coral : _C.gray,
                  bg: canDelete ? _C.coralLight : _C.cream,
                  onTap: canDelete ? onDelete : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required Color bg,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _squareBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ============================================================================
// FILTERS PANEL
// ============================================================================
class ApartmentFilters extends StatefulWidget {
  final Function(int? tranche, int? immeuble, ApartmentStatus? status)
  onFilterChanged;

  const ApartmentFilters({Key? key, required this.onFilterChanged})
      : super(key: key);

  @override
  State<ApartmentFilters> createState() => _ApartmentFiltersState();
}

class _ApartmentFiltersState extends State<ApartmentFilters> {
  int? selectedTranche;
  int? selectedImmeuble;
  ApartmentStatus? selectedStatus;
  final List<int> tranches = [1, 2, 3];
  final List<int> immeubles = [1, 2, 3];

  void _reset() {
    setState(() {
      selectedTranche = null;
      selectedImmeuble = null;
      selectedStatus = null;
    });
    widget.onFilterChanged(null, null, null);
  }

  void _apply() =>
      widget.onFilterChanged(selectedTranche, selectedImmeuble, selectedStatus);

  InputDecoration _dropDeco(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _C.gray, fontSize: 12),
    filled: true,
    fillColor: _C.cream,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _C.mint, width: 1.5)),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: const BoxDecoration(
        color: _C.white,
        border: Border(bottom: BorderSide(color: _C.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                    color: _C.cream,
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.tune_rounded,
                    size: 15, color: _C.gray),
              ),
              const SizedBox(width: 10),
              const Text('Filtres',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _C.dark)),
              const Spacer(),
              GestureDetector(
                onTap: _reset,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: _C.cream,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Reinitialiser',
                      style: TextStyle(
                          color: _C.gray,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedTranche,
                  decoration: _dropDeco('Tranche'),
                  style: const TextStyle(
                      color: _C.dark, fontSize: 13),
                  dropdownColor: _C.white,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Toutes')),
                    ...tranches.map((t) => DropdownMenuItem(
                        value: t, child: Text('Tranche $t'))),
                  ],
                  onChanged: (v) {
                    setState(() => selectedTranche = v);
                    _apply();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedImmeuble,
                  decoration: _dropDeco('Immeuble'),
                  style: const TextStyle(
                      color: _C.dark, fontSize: 13),
                  dropdownColor: _C.white,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Tous')),
                    ...immeubles.map((i) => DropdownMenuItem(
                        value: i, child: Text('Immeuble $i'))),
                  ],
                  onChanged: (v) {
                    setState(() => selectedImmeuble = v);
                    _apply();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text("Statut d'occupation",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _C.gray)),
          const SizedBox(height: 8),
          Row(
            children: [
              _statusChip('Tous', null),
              const SizedBox(width: 8),
              _statusChip('Occupes', ApartmentStatus.occupied),
              const SizedBox(width: 8),
              _statusChip('Vacants', ApartmentStatus.vacant),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, ApartmentStatus? status) {
    final isSelected = selectedStatus == status;
    Color accent;
    if (status == ApartmentStatus.occupied) {
      accent = _C.mint;
    } else if (status == ApartmentStatus.vacant) {
      accent = _C.amber;
    } else {
      accent = _C.dark;
    }
    return GestureDetector(
      onTap: () {
        setState(() => selectedStatus = status);
        _apply();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.1)
              : _C.cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? accent : _C.divider,
              width: isSelected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? accent : _C.gray,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
      ),
    );
  }
}

// ============================================================================
// MAIN SCREEN
// ============================================================================
class ApartmentsListScreen extends StatefulWidget {
  const ApartmentsListScreen({Key? key}) : super(key: key);

  @override
  State<ApartmentsListScreen> createState() =>
      _ApartmentsListScreenState();
}

class _ApartmentsListScreenState extends State<ApartmentsListScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<Apartment> apartments = [];
  List<Apartment> filteredApartments = [];
  bool showFilters = false;
  bool loading = false;
  final _searchCtrl = TextEditingController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadApartments();
    _searchCtrl.addListener(() => _search(_searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadApartments() async {
    setState(() => loading = true);
    try {
      final response = await _supabase
          .from('appartements')
          .select()
          .order('id', ascending: true) as List<dynamic>;
      final list = response
          .map((e) => Apartment.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      setState(() {
        apartments = list;
        filteredApartments = apartments;
      });
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      debugPrint('Erreur fetch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erreur lors du chargement')));
      }
    } finally {
      setState(() => loading = false);
    }
  }

  void _applyFilters(
      {int? tranche, int? immeuble, ApartmentStatus? status}) {
    setState(() {
      filteredApartments = apartments.where((a) {
        if (tranche != null && a.tranche != tranche) return false;
        if (immeuble != null && a.immeuble != immeuble) return false;
        if (status != null && a.statut != status) return false;
        return true;
      }).toList();
    });
  }

  void _search(String q) {
    setState(() {
      if (q.isEmpty) {
        filteredApartments = apartments;
      } else {
        final s = q.toLowerCase();
        filteredApartments = apartments.where((a) {
          return a.numero.toLowerCase().contains(s) ||
              'immeuble ${a.immeuble}'.contains(s) ||
              'tranche ${a.tranche}'.contains(s);
        }).toList();
      }
    });
  }

  // -- Stats
  int get _total => filteredApartments.length;
  int get _occupied =>
      filteredApartments.where((a) => a.statut == ApartmentStatus.occupied).length;
  int get _vacant =>
      filteredApartments.where((a) => a.statut == ApartmentStatus.vacant).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (showFilters)
              ApartmentFilters(
                onFilterChanged: (t, i, s) =>
                    _applyFilters(tranche: t, immeuble: i, status: s),
              ),
            Expanded(
              child: loading
                  ? _buildLoader()
                  : FadeTransition(
                opacity: _fadeAnim,
                child: RefreshIndicator(
                  color: _C.mint,
                  onRefresh: _loadApartments,
                  child: ListView(
                    physics:
                    const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                        20, 20, 20, 100),
                    children: [
                      _buildStatsBanner(),
                      const SizedBox(height: 20),
                      _buildSearchBar(),
                      const SizedBox(height: 20),
                      _buildSectionLabel(
                          '$_total appartement${_total > 1 ? 's' : ''}'),
                      const SizedBox(height: 12),
                      if (filteredApartments.isEmpty)
                        _buildEmpty()
                      else
                        ...filteredApartments.map(
                              (a) => ApartmentCard(
                            apartment: a,
                            onTap: () =>
                                _showDetails(a),
                            onEdit: () =>
                                _showEditDialog(a),
                            onAssign: () =>
                                _showAssignDialog(a),
                            onDelete: () =>
                                _showDeleteConfirm(a),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: _showAddDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
              color: _C.dark,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                    color: _C.dark.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              ]),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.add_rounded, color: _C.white, size: 18),
              SizedBox(width: 8),
              Text('Nouvel appartement',
                  style: TextStyle(
                      color: _C.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  // -- Loader
  Widget _buildLoader() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
            color: _C.mint, strokeWidth: 3),
        SizedBox(height: 14),
        Text('Chargement...',
            style: TextStyle(color: _C.gray, fontSize: 13)),
      ],
    ),
  );

  // -- Empty
  Widget _buildEmpty() => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
              color: _C.amberLight,
              borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.home_rounded,
              color: _C.amber, size: 32),
        ),
        const SizedBox(height: 14),
        const Text('Aucun appartement',
            style: TextStyle(
                color: _C.dark,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Modifiez les filtres ou ajoutez un appartement.',
            style: TextStyle(color: _C.gray, fontSize: 12)),
      ],
    ),
  );

  // -- Header
  Widget _buildHeader() {
    return Container(
      color: _C.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
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
              children: const [
                Text('Appartements',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: _C.dark)),
                Text('Gestion des appartements',
                    style: TextStyle(color: _C.gray, fontSize: 11)),
              ],
            ),
          ),
          // Filter toggle
          GestureDetector(
            onTap: () => setState(() => showFilters = !showFilters),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: showFilters ? _C.dark : _C.cream,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.tune_rounded,
                  size: 17,
                  color: showFilters ? _C.white : _C.gray),
            ),
          ),
          const SizedBox(width: 8),
          // Refresh
          GestureDetector(
            onTap: _loadApartments,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: _C.cream,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.refresh_rounded,
                  size: 17, color: _C.gray),
            ),
          ),
        ],
      ),
    );
  }

  // -- Stats banner
  Widget _buildStatsBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: _C.dark, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: _C.blue,
                    borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.home_rounded,
                    color: _C.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_total appartements',
                      style: const TextStyle(
                          color: _C.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                  const Text('dans la selection',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 16),
          Row(
            children: [
              _bannerStat('$_occupied', 'Occupes', _C.mint),
              _bannerDivider(),
              _bannerStat('$_vacant', 'Vacants', _C.amber),
              _bannerDivider(),
              _bannerStat(
                  _total > 0
                      ? '${(_occupied / _total * 100).round()}%'
                      : '0%',
                  'Taux occup.',
                  _C.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerStat(String val, String label, Color color) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(val,
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 10)),
          ],
        ),
      );

  Widget _bannerDivider() => Container(
      width: 1,
      height: 32,
      color: Colors.white12,
      margin: const EdgeInsets.symmetric(horizontal: 12));

  // -- Search bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.divider)),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14, color: _C.dark),
        decoration: InputDecoration(
          hintText: 'Rechercher par numero, tranche, immeuble...',
          hintStyle: const TextStyle(color: _C.gray, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: _C.gray, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? GestureDetector(
            onTap: () {
              _searchCtrl.clear();
              _search('');
            },
            child: const Icon(Icons.close_rounded,
                color: _C.gray, size: 18),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // -- Section label
  Widget _buildSectionLabel(String text) => Row(
    children: [
      Container(
          width: 4, height: 16,
          decoration: BoxDecoration(
              color: _C.coral,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(text,
          style: const TextStyle(
              color: _C.dark,
              fontWeight: FontWeight.w700,
              fontSize: 14)),
    ],
  );

  // ============================================================
  // SHARED DIALOG HELPERS
  // ============================================================
  Widget _dialogHeader(BuildContext ctx, String title,
      {IconData? icon, Color? iconColor}) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color:
                (iconColor ?? _C.mint).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor ?? _C.mint, size: 18),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: _C.dark)),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
                color: _C.cream,
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.close_rounded,
                size: 15, color: _C.gray),
          ),
        ),
      ],
    );
  }

  Widget _dialogActions({
    required BuildContext ctx,
    required bool saving,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) =>
      Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: saving ? null : () => Navigator.pop(ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  color: _C.cream,
                  borderRadius: BorderRadius.circular(12)),
              child: const Text('Annuler',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _C.dark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: saving ? null : onConfirm,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  color: saving
                      ? confirmColor.withValues(alpha: 0.5)
                      : confirmColor,
                  borderRadius: BorderRadius.circular(12)),
              child: saving
                  ? const Center(
                  child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: _C.white, strokeWidth: 2)))
                  : Text(confirmLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _C.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
        ),
      ]);

  Widget _fldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: _C.gray)),
  );

  Widget _fld(TextEditingController ctrl, String hint,
      {TextInputType inputType = TextInputType.text,
        FormFieldValidator<String>? validator}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: inputType,
        style: const TextStyle(fontSize: 14, color: _C.dark),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _C.gray, fontSize: 13),
          filled: true,
          fillColor: _C.cream,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              const BorderSide(color: _C.mint, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              const BorderSide(color: _C.coral, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 13),
        ),
      );

  // ============================================================
  // DIALOG: Add apartment
  // ============================================================
  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    final resCtrl = TextEditingController(text: '1');
    final trCtrl = TextEditingController();
    final immCtrl = TextEditingController();
    final numCtrl = TextEditingController();
    final ridCtrl = TextEditingController();
    ApartmentStatus status = ApartmentStatus.vacant;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialogHeader(ctx, 'Nouvel Appartement',
                        icon: Icons.home_rounded, iconColor: _C.blue),
                    const SizedBox(height: 20),
                    _fldLabel('Residence (ex: 1)'),
                    _fld(resCtrl, 'ex: 1',
                        inputType: TextInputType.number,
                        validator: _intValidator),
                    const SizedBox(height: 12),
                    _fldLabel('Tranche (ex: 2)'),
                    _fld(trCtrl, 'ex: 2',
                        inputType: TextInputType.number,
                        validator: _intValidator),
                    const SizedBox(height: 12),
                    _fldLabel('Immeuble (ex: 3)'),
                    _fld(immCtrl, 'ex: 3',
                        inputType: TextInputType.number,
                        validator: _intValidator),
                    const SizedBox(height: 12),
                    _fldLabel('N Appartement (ex: 201)'),
                    _fld(numCtrl, 'ex: 201',
                        inputType: TextInputType.number,
                        validator: _intValidator),
                    const SizedBox(height: 12),
                    _fldLabel('Statut'),
                    _statusToggle(
                        status,
                            (v) => setD(() => status = v)),
                    if (status == ApartmentStatus.occupied) ...[
                      const SizedBox(height: 12),
                      _fldLabel('Resident ID'),
                      _fld(ridCtrl, 'ex: 42',
                          inputType: TextInputType.number,
                          validator: _intValidator),
                    ],
                    const SizedBox(height: 24),
                    _dialogActions(
                      ctx: ctx,
                      saving: saving,
                      confirmLabel: 'Ajouter',
                      confirmColor: _C.mint,
                      onConfirm: () async {
                        if (!formKey.currentState!.validate()) return;
                        final res = int.parse(resCtrl.text.trim());
                        final tr  = int.parse(trCtrl.text.trim());
                        final imm = int.parse(immCtrl.text.trim());
                        final num = int.parse(numCtrl.text.trim());
                        final rid = ridCtrl.text.trim().isNotEmpty
                            ? int.parse(ridCtrl.text.trim())
                            : null;
                        final newNum = 'R$res-T$tr-Imm$imm-$num';
                        if (apartments.any((a) => a.numero == newNum)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Le numero $newNum existe deja.')));
                          return;
                        }
                        setD(() => saving = true);
                        Navigator.pop(ctx);
                        final now = DateTime.now().toIso8601String();
                        try {
                          final inserted = await _supabase
                              .from('appartements')
                              .insert({
                            'numero': newNum,
                            'immeuble_id': imm,
                            'statut': status == ApartmentStatus.vacant
                                ? 'libre'
                                : 'occupe',
                            'resident_id': rid,
                            'created_at': now,
                            'updated_at': now,
                          })
                              .select() as List<dynamic>;
                          if (inserted.isNotEmpty) {
                            final ap = Apartment.fromMap(
                                Map<String, dynamic>.from(
                                    inserted.first));
                            setState(() {
                              apartments.add(ap);
                              filteredApartments = apartments;
                            });
                          }
                        } catch (e) {
                          debugPrint('Insert error: $e');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DIALOG: Edit
  // ============================================================
  void _showEditDialog(Apartment apt) {
    final formKey = GlobalKey<FormState>();
    final resCtrl =
    TextEditingController(text: apt.residence.toString());
    final trCtrl =
    TextEditingController(text: apt.tranche.toString());
    final immCtrl =
    TextEditingController(text: apt.immeuble.toString());
    final numCtrl =
    TextEditingController(text: apt.numeroAppartement.toString());
    final ridCtrl = TextEditingController(
        text: apt.residentId?.toString() ?? '');
    ApartmentStatus status = apt.statut;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialogHeader(ctx, 'Modifier ${apt.numero}',
                        icon: Icons.edit_rounded, iconColor: _C.blue),
                    const SizedBox(height: 20),
                    _fldLabel('Residence'),
                    _fld(resCtrl, '',
                        inputType: TextInputType.number,
                        validator: _intValidator),
                    const SizedBox(height: 12),
                    _fldLabel('Tranche'),
                    _fld(trCtrl, '',
                        inputType: TextInputType.number,
                        validator: _intValidator),
                    const SizedBox(height: 12),
                    _fldLabel('Immeuble'),
                    _fld(immCtrl, '',
                        inputType: TextInputType.number,
                        validator: _intValidator),
                    const SizedBox(height: 12),
                    _fldLabel('N Appartement'),
                    _fld(numCtrl, '',
                        inputType: TextInputType.number,
                        validator: _intValidator),
                    const SizedBox(height: 12),
                    _fldLabel('Statut'),
                    _statusToggle(status, (v) {
                      setD(() {
                        status = v;
                        if (v == ApartmentStatus.vacant) ridCtrl.clear();
                      });
                    }),
                    if (status == ApartmentStatus.occupied) ...[
                      const SizedBox(height: 12),
                      _fldLabel('Resident ID'),
                      _fld(ridCtrl, '',
                          inputType: TextInputType.number,
                          validator: _intValidator),
                    ],
                    const SizedBox(height: 24),
                    _dialogActions(
                      ctx: ctx,
                      saving: saving,
                      confirmLabel: 'Enregistrer',
                      confirmColor: _C.blue,
                      onConfirm: () async {
                        if (!formKey.currentState!.validate()) return;
                        final res = int.parse(resCtrl.text.trim());
                        final tr  = int.parse(trCtrl.text.trim());
                        final imm = int.parse(immCtrl.text.trim());
                        final num = int.parse(numCtrl.text.trim());
                        final rid = ridCtrl.text.trim().isNotEmpty
                            ? int.parse(ridCtrl.text.trim())
                            : null;
                        final newNum = 'R$res-T$tr-Imm$imm-$num';
                        if (apartments.any((a) =>
                        a.numero == newNum && a.id != apt.id)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '$newNum existe deja.')));
                          return;
                        }
                        setD(() => saving = true);
                        Navigator.pop(ctx);
                        try {
                          final updated = await _supabase
                              .from('appartements')
                              .update({
                            'numero': newNum,
                            'immeuble_id': imm,
                            'statut': status == ApartmentStatus.vacant
                                ? 'libre'
                                : 'occupe',
                            'resident_id': rid,
                            'updated_at':
                            DateTime.now().toIso8601String(),
                          })
                              .eq('id', apt.id)
                              .select() as List<dynamic>;
                          if (updated.isNotEmpty) {
                            final ap = Apartment.fromMap(
                                Map<String, dynamic>.from(
                                    updated.first));
                            setState(() {
                              final idx = apartments
                                  .indexWhere((a) => a.id == ap.id);
                              if (idx != -1) apartments[idx] = ap;
                              filteredApartments = apartments;
                            });
                          }
                        } catch (e) {
                          debugPrint('Update error: $e');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DIALOG: Assign resident
  // ============================================================
  void _showAssignDialog(Apartment apt) {
    if (apt.statut == ApartmentStatus.occupied) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${apt.numero} est deja occupe.')));
      return;
    }
    final formKey = GlobalKey<FormState>();
    final ridCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogHeader(ctx, 'Assigner ${apt.numero}',
                      icon: Icons.person_add_rounded,
                      iconColor: _C.mint),
                  const SizedBox(height: 20),
                  _fldLabel('Resident ID'),
                  _fld(ridCtrl, 'ex: 42',
                      inputType: TextInputType.number,
                      validator: _intValidator),
                  const SizedBox(height: 24),
                  _dialogActions(
                    ctx: ctx,
                    saving: saving,
                    confirmLabel: 'Assigner',
                    confirmColor: _C.mint,
                    onConfirm: () async {
                      if (!formKey.currentState!.validate()) return;
                      final rid = int.parse(ridCtrl.text.trim());
                      setD(() => saving = true);
                      Navigator.pop(ctx);
                      try {
                        final updated = await _supabase
                            .from('appartements')
                            .update({
                          'resident_id': rid,
                          'statut': 'occupe',
                          'updated_at':
                          DateTime.now().toIso8601String(),
                        })
                            .eq('id', apt.id)
                            .select() as List<dynamic>;
                        if (updated.isNotEmpty) {
                          final ap = Apartment.fromMap(
                              Map<String, dynamic>.from(
                                  updated.first));
                          setState(() {
                            final idx = apartments
                                .indexWhere((a) => a.id == ap.id);
                            if (idx != -1) apartments[idx] = ap;
                            filteredApartments = apartments;
                          });
                        }
                      } catch (e) {
                        debugPrint('Assign error: $e');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DIALOG: Delete confirm
  // ============================================================
  void _showDeleteConfirm(Apartment apt) {
    final canDelete =
        apt.statut == ApartmentStatus.vacant && apt.residentId == null;
    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Impossible: appartement occupe ou assigne.')));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                    color: _C.coralLight,
                    borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.delete_rounded,
                    color: _C.coral, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Confirmer la suppression',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: _C.dark)),
              const SizedBox(height: 8),
              Text(
                'Supprimer ${apt.numero} ? Cette action est irreversible.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _C.gray, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: _C.cream,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('Annuler',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _C.dark,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        await _supabase
                            .from('appartements')
                            .delete()
                            .eq('id', apt.id);
                        setState(() {
                          apartments
                              .removeWhere((a) => a.id == apt.id);
                          filteredApartments = apartments;
                        });
                      } catch (e) {
                        debugPrint('Delete error: $e');
                      }
                    },
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: _C.coral,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('Supprimer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _C.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM SHEET: Details
  // ============================================================
  void _showDetails(Apartment apt) {
    final isOcc = apt.statut == ApartmentStatus.occupied;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(
          color: _C.white,
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 1.0,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          expand: false,
          builder: (ctx, scrollCtrl) => SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: _C.divider,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                // Title row
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                          color: isOcc
                              ? _C.mintLight
                              : _C.amberLight,
                          borderRadius:
                          BorderRadius.circular(14)),
                      child: Icon(Icons.home_rounded,
                          color: isOcc ? _C.mint : _C.amber,
                          size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(apt.numero,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: _C.dark)),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: isOcc
                                  ? _C.mintLight
                                  : _C.amberLight,
                              borderRadius:
                              BorderRadius.circular(20)),
                          child: Text(
                              isOcc ? 'Occupe' : 'Vacant',
                              style: TextStyle(
                                  color: isOcc
                                      ? _C.mint
                                      : _C.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: _C.cream,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _detailRow('Residence',
                          'Residence ${apt.residence}',
                          Icons.location_city_rounded),
                      _divRow(),
                      _detailRow('Tranche',
                          'Tranche ${apt.tranche}',
                          Icons.layers_rounded),
                      _divRow(),
                      _detailRow('Immeuble',
                          'Immeuble ${apt.immeuble}',
                          Icons.business_rounded),
                      _divRow(),
                      _detailRow('N Appart',
                          '${apt.numeroAppartement}',
                          Icons.meeting_room_rounded),
                      if (isOcc) ...[
                        _divRow(),
                        _detailRow('Resident ID',
                            '${apt.residentId}',
                            Icons.person_rounded),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _showEditDialog(apt);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 13),
                          decoration: BoxDecoration(
                              color: _C.blueLight,
                              borderRadius:
                              BorderRadius.circular(14)),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.edit_rounded,
                                  size: 16, color: _C.blue),
                              SizedBox(width: 6),
                              Text('Modifier',
                                  style: TextStyle(
                                      color: _C.blue,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isOcc) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _showAssignDialog(apt);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 13),
                            decoration: BoxDecoration(
                                color: _C.mintLight,
                                borderRadius:
                                BorderRadius.circular(14)),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.person_add_rounded,
                                    size: 16, color: _C.mint),
                                SizedBox(width: 6),
                                Text('Assigner',
                                    style: TextStyle(
                                        color: _C.mint,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _showDeleteConfirm(apt);
                        },
                        child: Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                              color: _C.coralLight,
                              borderRadius:
                              BorderRadius.circular(14)),
                          child: const Icon(Icons.delete_rounded,
                              color: _C.coral, size: 20),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: _C.white,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 15, color: _C.gray),
            ),
            const SizedBox(width: 12),
            Text('$label  ',
                style: const TextStyle(
                    color: _C.gray, fontSize: 13)),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      color: _C.dark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _divRow() =>
      Container(height: 1, color: _C.divider);

  // ============================================================
  // HELPERS
  // ============================================================
  Widget _statusToggle(
      ApartmentStatus current, ValueChanged<ApartmentStatus> onChange) {
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () => onChange(ApartmentStatus.vacant),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: current == ApartmentStatus.vacant
                  ? _C.amberLight
                  : _C.cream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: current == ApartmentStatus.vacant
                      ? _C.amber
                      : _C.divider,
                  width: current == ApartmentStatus.vacant ? 1.5 : 1),
            ),
            child: Text('Vacant',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: current == ApartmentStatus.vacant
                        ? _C.amber
                        : _C.gray,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: GestureDetector(
          onTap: () => onChange(ApartmentStatus.occupied),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: current == ApartmentStatus.occupied
                  ? _C.mintLight
                  : _C.cream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: current == ApartmentStatus.occupied
                      ? _C.mint
                      : _C.divider,
                  width: current == ApartmentStatus.occupied ? 1.5 : 1),
            ),
            child: Text('Occupe',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: current == ApartmentStatus.occupied
                        ? _C.mint
                        : _C.gray,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ),
      ),
    ]);
  }

  String? _intValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requis';
    final v = int.tryParse(value.trim());
    if (v == null || v <= 0) return 'Entier positif requis';
    return null;
  }
}