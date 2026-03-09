// apartments(1500).dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// MODELS
// ============================================================================

enum ApartmentStatus {
  occupied, // occupé
  vacant, // libre
}

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

  String get numero {
    return "R$residence-T$tranche-Imm$immeuble-$numeroAppartement";
  }

  /// construit depuis une map renvoyée par Supabase/Postgres
  factory Apartment.fromMap(Map<String, dynamic> map) {
    // Defensive: certain champs peuvent être int / String selon la requête
    final numeroRaw = map['numero'] ?? '';
    final numero = numeroRaw is String ? numeroRaw : numeroRaw.toString();

    // Parse numero format: R{res}-T{tranche}-Imm{immeuble}-{num}
    int residence = 0, tranche = 0, immeuble = 0, numeroAppartement = 0;
    try {
      final parts = numero.split('-');
      if (parts.length >= 4) {
        residence = int.parse(parts[0].substring(1));
        tranche = int.parse(parts[1].substring(1));
        // prendre apres "Imm"
        immeuble = int.parse(parts[2].substring(3));
        numeroAppartement = int.parse(parts[3]);
      }
    } catch (_) {
      // si parse échoue, on laisse 0 et on pourra afficher numero brut
    }

    final statutRaw = (map['statut'] ?? '').toString().toLowerCase();
    final statut = statutRaw.contains('lib') || statutRaw == 'vacant' ? ApartmentStatus.vacant : ApartmentStatus.occupied;

    final createdAtRaw = map['created_at'] ?? map['createdAt'] ?? DateTime.now().toIso8601String();
    final updatedAtRaw = map['updated_at'] ?? map['updatedAt'] ?? DateTime.now().toIso8601String();

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
      residentId: map['resident_id'] == null ? null : (map['resident_id'] is int ? map['resident_id'] : int.parse(map['resident_id'].toString())),
      createdAt: parseDate(createdAtRaw),
      updatedAt: parseDate(updatedAtRaw),
    );
  }

  Map<String, dynamic> toMapForInsert() {
    // Pour insérer en DB : envoyer le champ 'numero' + 'immeuble_id' + 'statut' + 'resident_id'
    return {
      'numero': numero,
      'immeuble_id': immeuble,
      'statut': statut == ApartmentStatus.vacant ? 'libre' : 'occupe',
      'resident_id': residentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ============================================================================
// UI WIDGETS (même structure que ton fichier original) MAIS connectés à Supabase
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

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec numéro et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.home,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        apartment.numero,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(context),
                ],
              ),

              const SizedBox(height: 12),

              // Informations structurelles
              _buildInfoRow(Icons.location_city, 'Résidence', 'Résidence ${apartment.residence}'),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.category, 'Tranche', 'Tranche ${apartment.tranche}'),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.business, 'Immeuble', 'Immeuble ${apartment.immeuble}'),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.meeting_room, 'N° Appart', '${apartment.numeroAppartement}'),

              // Informations du résident si occupé
              if (isOccupied) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Résident ID: ${apartment.residentId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Occupé',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isOccupied)
                    TextButton.icon(
                      onPressed: onAssign,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Assigner'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: (apartment.statut == ApartmentStatus.vacant && apartment.residentId == null)
                        ? onDelete
                        : null,
                    icon: const Icon(Icons.delete),
                    tooltip: apartment.statut == ApartmentStatus.vacant && apartment.residentId == null
                        ? 'Supprimer'
                        : 'Impossible: appartement occupé/assigné',
                    color: (apartment.statut == ApartmentStatus.vacant && apartment.residentId == null)
                        ? Colors.red
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final isOccupied = apartment.statut == ApartmentStatus.occupied;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOccupied ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOccupied ? Colors.green : Colors.orange,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOccupied ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOccupied ? 'Occupé' : 'Vacant',
            style: TextStyle(
              color: isOccupied ? Colors.green.shade900 : Colors.orange.shade900,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// FILTERS (identique au fichier original)
// ============================================================================

class ApartmentFilters extends StatefulWidget {
  final Function(int? tranche, int? immeuble, ApartmentStatus? status) onFilterChanged;

  const ApartmentFilters({
    Key? key,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  State<ApartmentFilters> createState() => _ApartmentFiltersState();
}

class _ApartmentFiltersState extends State<ApartmentFilters> {
  int? selectedTranche;
  int? selectedImmeuble;
  ApartmentStatus? selectedStatus;

  final List<int> tranches = [1, 2, 3];
  final List<int> immeubles = [1, 2, 3];

  void _resetFilters() {
    setState(() {
      selectedTranche = null;
      selectedImmeuble = null;
      selectedStatus = null;
    });
    widget.onFilterChanged(null, null, null);
  }

  void _applyFilters() {
    widget.onFilterChanged(
      selectedTranche,
      selectedImmeuble,
      selectedStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Réinitialiser'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedTranche,
                  decoration: InputDecoration(
                    labelText: 'Tranche',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Toutes')),
                    ...tranches.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text('Tranche $t'),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => selectedTranche = value);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedImmeuble,
                  decoration: InputDecoration(
                    labelText: 'Immeuble',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tous')),
                    ...immeubles.map((i) => DropdownMenuItem(
                      value: i,
                      child: Text('Immeuble $i'),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => selectedImmeuble = value);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            'Statut d\'occupation',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Tous'),
                selected: selectedStatus == null,
                onSelected: (selected) {
                  setState(() => selectedStatus = null);
                  _applyFilters();
                },
              ),
              FilterChip(
                label: const Text('Occupé'),
                selected: selectedStatus == ApartmentStatus.occupied,
                onSelected: (selected) {
                  setState(() => selectedStatus = selected ? ApartmentStatus.occupied : null);
                  _applyFilters();
                },
                selectedColor: Colors.green.shade100,
              ),
              FilterChip(
                label: const Text('Vacant'),
                selected: selectedStatus == ApartmentStatus.vacant,
                onSelected: (selected) {
                  setState(() => selectedStatus = selected ? ApartmentStatus.vacant : null);
                  _applyFilters();
                },
                selectedColor: Colors.orange.shade100,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SCREEN - APARTMENTS LIST (connecté à Supabase)
// ============================================================================

class ApartmentsListScreen extends StatefulWidget {
  const ApartmentsListScreen({Key? key}) : super(key: key);

  @override
  State<ApartmentsListScreen> createState() => _ApartmentsListScreenState();
}

class _ApartmentsListScreenState extends State<ApartmentsListScreen> {
  final _supabase = Supabase.instance.client;
  List<Apartment> apartments = [];
  List<Apartment> filteredApartments = [];
  bool showFilters = false;
  final TextEditingController searchController = TextEditingController();
  bool loading = false;

  // For undo deletion (local): keep last deleted so user can undo (DB delete will be permanent)
  Apartment? _recentlyDeleted;
  int? _recentlyDeletedIndex;

  @override
  void initState() {
    super.initState();
    _loadApartments();
  }

  Future<void> _loadApartments() async {
    setState(() => loading = true);
    try {
      final response = await _supabase.from('appartements').select().order('id', ascending: true) as List<dynamic>;
      final list = response.map((e) => Apartment.fromMap(Map<String, dynamic>.from(e))).toList();
      setState(() {
        apartments = list;
        filteredApartments = apartments;
      });
    } catch (e, st) {
      debugPrint('Erreur fetch appartements: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des appartements')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  void _applyFilters({
    int? tranche,
    int? immeuble,
    ApartmentStatus? status,
  }) {
    setState(() {
      filteredApartments = apartments.where((apt) {
        if (tranche != null && apt.tranche != tranche) return false;
        if (immeuble != null && apt.immeuble != immeuble) return false;
        if (status != null && apt.statut != status) return false;
        return true;
      }).toList();
    });
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredApartments = apartments;
      } else {
        filteredApartments = apartments.where((apt) {
          final searchLower = query.toLowerCase();
          return apt.numero.toLowerCase().contains(searchLower) ||
              'immeuble ${apt.immeuble}'.toLowerCase().contains(searchLower) ||
              'tranche ${apt.tranche}'.toLowerCase().contains(searchLower) ||
              'résidence ${apt.residence}'.toLowerCase().contains(searchLower) ||
              apt.numeroAppartement.toString().contains(searchLower);
        }).toList();
      }
    });
  }

  // -------------------------
  // CRUD via Supabase
  // -------------------------

  Future<void> _addApartmentToDb({
    required int residence,
    required int tranche,
    required int immeuble,
    required int numeroApt,
    required ApartmentStatus status,
    int? residentId,
  }) async {
    final numero = "R${residence}-T${tranche}-Imm${immeuble}-${numeroApt}";
    final now = DateTime.now().toIso8601String();
    final row = {
      'numero': numero,
      'immeuble_id': immeuble,
      'statut': status == ApartmentStatus.vacant ? 'libre' : 'occupe',
      'resident_id': residentId,
      'created_at': now,
      'updated_at': now,
    };

    try {
      final inserted = await _supabase.from('appartements').insert(row).select() as List<dynamic>;
      if (inserted.isNotEmpty) {
        final ap = Apartment.fromMap(Map<String, dynamic>.from(inserted.first));
        setState(() {
          apartments.add(ap);
          if (searchController.text.isEmpty) filteredApartments = apartments;
          else _search(searchController.text);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appartement $numero ajouté.')));
      } else {
        throw Exception('Aucune ligne insérée');
      }
    } catch (e) {
      debugPrint('Erreur insert: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'ajout en base')));
    }
  }

  Future<void> _updateApartmentInDb({
    required Apartment oldApartment,
    required int residence,
    required int tranche,
    required int immeuble,
    required int numeroApt,
    required ApartmentStatus status,
    int? residentId,
  }) async {
    final numero = "R${residence}-T${tranche}-Imm${immeuble}-${numeroApt}";
    final now = DateTime.now().toIso8601String();
    final row = {
      'numero': numero,
      'immeuble_id': immeuble,
      'statut': status == ApartmentStatus.vacant ? 'libre' : 'occupe',
      'resident_id': residentId,
      'updated_at': now,
    };

    try {
      final updated = await _supabase
          .from('appartements')
          .update(row)
          .eq('id', oldApartment.id)
          .select() as List<dynamic>;
      if (updated.isNotEmpty) {
        final ap = Apartment.fromMap(Map<String, dynamic>.from(updated.first));
        setState(() {
          final idx = apartments.indexWhere((a) => a.id == ap.id);
          if (idx != -1) apartments[idx] = ap;
          if (searchController.text.isEmpty) filteredApartments = apartments;
          else _search(searchController.text);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appartement $numero modifié.')));
      } else {
        throw Exception('Aucune ligne mise à jour');
      }
    } catch (e) {
      debugPrint('Erreur update: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la modification en base')));
    }
  }

  Future<void> _deleteApartmentFromDb(Apartment apartment) async {
    try {
      await _supabase.from('appartements').delete().eq('id', apartment.id);
      // remove locally
      setState(() {
        apartments.removeWhere((a) => a.id == apartment.id);
        if (searchController.text.isEmpty) filteredApartments = apartments;
        else _search(searchController.text);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appartement ${apartment.numero} supprimé en base.')));
    } catch (e) {
      debugPrint('Erreur delete: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression en base')));
    }
  }

  Future<void> _assignResidentInDb(Apartment apartment, int residentId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final updated = await _supabase
          .from('appartements')
          .update({'resident_id': residentId, 'statut': 'occupe', 'updated_at': now})
          .eq('id', apartment.id)
          .select() as List<dynamic>;
      if (updated.isNotEmpty) {
        final ap = Apartment.fromMap(Map<String, dynamic>.from(updated.first));
        setState(() {
          final idx = apartments.indexWhere((a) => a.id == ap.id);
          if (idx != -1) apartments[idx] = ap;
          if (searchController.text.isEmpty) filteredApartments = apartments;
          else _search(searchController.text);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Resident $residentId assigné à ${apartment.numero}')));
      }
    } catch (e) {
      debugPrint('Erreur assign: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'assignation')));
    }
  }

  // -------------------------
  // Dialogs UI : reuse ton UI original mais en appelant les méthodes DB ci-dessus
  // -------------------------

  void _showAddApartmentDialog() {
    final _formKey = GlobalKey<FormState>();
    final residenceController = TextEditingController(text: '1');
    final trancheController = TextEditingController();
    final immeubleController = TextEditingController();
    final numeroController = TextEditingController();
    final residentController = TextEditingController();
    ApartmentStatus status = ApartmentStatus.vacant;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Nouvel Appartement'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: residenceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Résidence (ex: 1)'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Requis';
                        final v = int.tryParse(value.trim());
                        if (v == null || v <= 0) return 'Entrez un entier positif';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: trancheController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tranche (ex: 2)'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Requis';
                        final v = int.tryParse(value.trim());
                        if (v == null || v <= 0) return 'Entrez un entier positif';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: immeubleController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Immeuble (ex: 3)'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Requis';
                        final v = int.tryParse(value.trim());
                        if (v == null || v <= 0) return 'Entrez un entier positif';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: numeroController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'N° Appartement (ex: 201)'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Requis';
                        final v = int.tryParse(value.trim());
                        if (v == null || v <= 0) return 'Entrez un entier positif';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ApartmentStatus>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items: const [
                        DropdownMenuItem(value: ApartmentStatus.vacant, child: Text('Vacant')),
                        DropdownMenuItem(value: ApartmentStatus.occupied, child: Text('Occupé')),
                      ],
                      onChanged: (value) {
                        if (value != null) setStateDialog(() => status = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    if (status == ApartmentStatus.occupied) ...[
                      TextFormField(
                        controller: residentController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Resident ID (entier positif)'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Resident ID requis';
                          final v = int.tryParse(value.trim());
                          if (v == null || v <= 0) return 'Entrez un entier positif';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final residence = int.parse(residenceController.text.trim());
                  final tranche = int.parse(trancheController.text.trim());
                  final immeuble = int.parse(immeubleController.text.trim());
                  final numeroApt = int.parse(numeroController.text.trim());
                  final residentId = (status == ApartmentStatus.occupied && residentController.text.trim().isNotEmpty)
                      ? int.parse(residentController.text.trim())
                      : null;
                  final newNumero = "R$residence-T$tranche-Imm$immeuble-$numeroApt";

                  final exists = apartments.any((a) => a.numero == newNumero);
                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Le numéro $newNumero existe déjà.')));
                    return;
                  }

                  Navigator.pop(context);
                  await _addApartmentToDb(
                    residence: residence,
                    tranche: tranche,
                    immeuble: immeuble,
                    numeroApt: numeroApt,
                    status: status,
                    residentId: residentId,
                  );
                },
                child: const Text('Ajouter'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showAssignResidentDialog(Apartment apartment) {
    if (apartment.statut == ApartmentStatus.occupied) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible : ${apartment.numero} est déjà occupé.')));
      return;
    }
    final _formKey = GlobalKey<FormState>();
    final residentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assigner un résident à ${apartment.numero}'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: residentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Resident ID (entier positif)'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Requis';
              final v = int.tryParse(value.trim());
              if (v == null || v <= 0) return 'Entrez un entier positif';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final residentId = int.parse(residentController.text.trim());
              Navigator.pop(context);
              await _assignResidentInDb(apartment, residentId);
            },
            child: const Text('Assigner'),
          ),
        ],
      ),
    );
  }

  void _showEditApartmentDialog(Apartment apartment) {
    final _formKey = GlobalKey<FormState>();
    final residenceController = TextEditingController(text: apartment.residence.toString());
    final trancheController = TextEditingController(text: apartment.tranche.toString());
    final immeubleController = TextEditingController(text: apartment.immeuble.toString());
    final numeroController = TextEditingController(text: apartment.numeroAppartement.toString());
    final residentController = TextEditingController(text: apartment.residentId?.toString() ?? '');
    ApartmentStatus status = apartment.statut;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Modifier ${apartment.numero}'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: residenceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Résidence'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Requis';
                        final v = int.tryParse(value.trim());
                        if (v == null || v <= 0) return 'Entrez un entier positif';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: trancheController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tranche'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Requis';
                        final v = int.tryParse(value.trim());
                        if (v == null || v <= 0) return 'Entrez un entier positif';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: immeubleController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Immeuble'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Requis';
                        final v = int.tryParse(value.trim());
                        if (v == null || v <= 0) return 'Entrez un entier positif';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: numeroController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'N° Appartement'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Requis';
                        final v = int.tryParse(value.trim());
                        if (v == null || v <= 0) return 'Entrez un entier positif';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ApartmentStatus>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items: const [
                        DropdownMenuItem(value: ApartmentStatus.vacant, child: Text('Vacant')),
                        DropdownMenuItem(value: ApartmentStatus.occupied, child: Text('Occupé')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            status = value;
                            if (value == ApartmentStatus.vacant) residentController.clear();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    if (status == ApartmentStatus.occupied) ...[
                      TextFormField(
                        controller: residentController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Resident ID (laisser vide si vacant)'),
                        validator: (value) {
                          if (status == ApartmentStatus.occupied) {
                            if (value == null || value.trim().isEmpty) return 'Resident ID requis pour un appartement occupé';
                            final v = int.tryParse(value.trim());
                            if (v == null || v <= 0) return 'Entrez un entier positif';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final residence = int.parse(residenceController.text.trim());
                  final tranche = int.parse(trancheController.text.trim());
                  final immeuble = int.parse(immeubleController.text.trim());
                  final numeroApt = int.parse(numeroController.text.trim());
                  final residentId = (status == ApartmentStatus.occupied && residentController.text.trim().isNotEmpty)
                      ? int.parse(residentController.text.trim())
                      : null;

                  final newNumero = "R$residence-T$tranche-Imm$immeuble-$numeroApt";

                  final exists = apartments.any((a) => a.numero == newNumero && a.id != apartment.id);
                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Le numéro $newNumero existe déjà pour un autre appartement.')));
                    return;
                  }

                  Navigator.pop(context);
                  await _updateApartmentInDb(
                    oldApartment: apartment,
                    residence: residence,
                    tranche: tranche,
                    immeuble: immeuble,
                    numeroApt: numeroApt,
                    status: status,
                    residentId: residentId,
                  );
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showDeleteConfirmation(Apartment apartment) {
    final canDelete = apartment.statut == ApartmentStatus.vacant && apartment.residentId == null;
    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de supprimer : appartement occupé ou assigné.')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ${apartment.numero} ?'),
        content: const Text('Cette opération est irréversible. Voulez-vous continuer ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteApartmentFromDb(apartment);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showApartmentDetails(Apartment apartment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Row(children: [Icon(Icons.home, size: 32, color: Theme.of(context).primaryColor), const SizedBox(width: 12), Text(apartment.numero, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))]),
                const SizedBox(height: 24),
                _buildDetailRow('Résidence', 'Résidence ${apartment.residence}', Icons.location_city),
                _buildDetailRow('Tranche', 'Tranche ${apartment.tranche}', Icons.category),
                _buildDetailRow('Immeuble', 'Immeuble ${apartment.immeuble}', Icons.business),
                _buildDetailRow('N° Appartement', '${apartment.numeroAppartement}', Icons.meeting_room),
                _buildDetailRow('Statut', apartment.statut == ApartmentStatus.occupied ? 'Occupé' : 'Vacant', Icons.info_outline),
                if (apartment.statut == ApartmentStatus.occupied) ...[
                  const Divider(height: 32),
                  _buildDetailRow('Résident ID', '${apartment.residentId}', Icons.person),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditApartmentDialog(apartment);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (apartment.statut == ApartmentStatus.vacant) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showAssignResidentDialog(apartment);
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Assigner'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showDeleteConfirmation(apartment);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // -------------------------
  // Build UI
  // -------------------------

  @override
  Widget build(BuildContext context) {
    final occupiedCount = filteredApartments.where((a) => a.statut == ApartmentStatus.occupied).length;
    final vacantCount = filteredApartments.where((a) => a.statut == ApartmentStatus.vacant).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Appartements'),
        actions: [
          IconButton(
            icon: Icon(showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() => showFilters = !showFilters);
            },
            tooltip: 'Filtres',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApartments,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Rechercher par numéro, résidence, immeuble ou tranche...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    _search('');
                  },
                )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Total', filteredApartments.length.toString(), Icons.home, Colors.blue),
                _buildStatCard('Occupés', occupiedCount.toString(), Icons.check_circle, Colors.green),
                _buildStatCard('Vacants', vacantCount.toString(), Icons.error_outline, Colors.orange),
              ],
            ),
          ),

          if (showFilters)
            ApartmentFilters(
              onFilterChanged: (tranche, immeuble, status) {
                _applyFilters(tranche: tranche, immeuble: immeuble, status: status);
              },
            ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredApartments.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Aucun appartement trouvé', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadApartments,
              child: ListView.builder(
                itemCount: filteredApartments.length,
                padding: const EdgeInsets.only(bottom: 80),
                itemBuilder: (context, index) {
                  final apartment = filteredApartments[index];
                  return ApartmentCard(
                    apartment: apartment,
                    onTap: () => _showApartmentDetails(apartment),
                    onEdit: () => _showEditApartmentDialog(apartment),
                    onAssign: () => _showAssignResidentDialog(apartment),
                    onDelete: () => _showDeleteConfirmation(apartment),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddApartmentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nouvel appartement'),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

