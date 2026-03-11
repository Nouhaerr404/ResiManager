import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/appartement_model.dart';
import '../../../widgets/apartment_card.dart';
import '../../../widgets/apartment_filters.dart';

class ApartmentsListScreen extends StatefulWidget {
  const ApartmentsListScreen({Key? key}) : super(key: key);

  @override
  State<ApartmentsListScreen> createState() => _ApartmentsListScreenState();
}

class _ApartmentsListScreenState extends State<ApartmentsListScreen> {
  final _supabase = Supabase.instance.client;
  List<AppartementModel> apartments = [];
  List<AppartementModel> filteredApartments = [];
  bool showFilters = false;
  final TextEditingController searchController = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadApartments();
  }

  Future<void> _loadApartments() async {
    setState(() => loading = true);
    try {
      final response = await _supabase.from('appartements').select().order('id', ascending: true) as List<dynamic>;
      final list = response.map((e) => AppartementModel.fromJson(Map<String, dynamic>.from(e))).toList();
      setState(() {
        apartments = list;
        filteredApartments = apartments;
      });
    } catch (e, st) {
      debugPrint('Erreur fetch appartements: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement des appartements')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _applyFilters({
    int? tranche,
    int? immeuble,
    StatutAppartEnum? status,
  }) {
    setState(() {
      filteredApartments = apartments.where((apt) {
        if (tranche != null && apt.tranche != tranche) return false;
        if (immeuble != null && apt.immeubleNum != immeuble) return false;
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
              'immeuble ${apt.immeubleNum}'.toLowerCase().contains(searchLower) ||
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
    required StatutAppartEnum status,
    int? residentId,
  }) async {
    final numero = AppartementModel.generateNumero(residence, tranche, immeuble, numeroApt);
    final now = DateTime.now().toIso8601String();
    final row = {
      'numero': numero,
      'immeuble_id': immeuble,
      'statut': status == StatutAppartEnum.libre ? 'libre' : 'occupe',
      'resident_id': residentId,
      'created_at': now,
      'updated_at': now,
    };

    try {
      final inserted = await _supabase.from('appartements').insert(row).select() as List<dynamic>;
      if (inserted.isNotEmpty) {
        final ap = AppartementModel.fromJson(Map<String, dynamic>.from(inserted.first));
        setState(() {
          apartments.add(ap);
          if (searchController.text.isEmpty) {
            filteredApartments = apartments;
          } else {
            _search(searchController.text);
          }
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appartement $numero ajouté.')));
      }
    } catch (e) {
      debugPrint('Erreur insert: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'ajout en base')));
    }
  }

  Future<void> _updateApartmentInDb({
    required AppartementModel oldApartment,
    required int residence,
    required int tranche,
    required int immeuble,
    required int numeroApt,
    required StatutAppartEnum status,
    int? residentId,
  }) async {
    final numero = AppartementModel.generateNumero(residence, tranche, immeuble, numeroApt);
    final now = DateTime.now().toIso8601String();
    final row = {
      'numero': numero,
      'immeuble_id': immeuble,
      'statut': status == StatutAppartEnum.libre ? 'libre' : 'occupe',
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
        final ap = AppartementModel.fromJson(Map<String, dynamic>.from(updated.first));
        setState(() {
          final idx = apartments.indexWhere((a) => a.id == ap.id);
          if (idx != -1) apartments[idx] = ap;
          if (searchController.text.isEmpty) {
            filteredApartments = apartments;
          } else {
            _search(searchController.text);
          }
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appartement $numero modifié.')));
      }
    } catch (e) {
      debugPrint('Erreur update: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la modification en base')));
    }
  }

  Future<void> _deleteApartmentFromDb(AppartementModel apartment) async {
    try {
      await _supabase.from('appartements').delete().eq('id', apartment.id);
      setState(() {
        apartments.removeWhere((a) => a.id == apartment.id);
        if (searchController.text.isEmpty) {
          filteredApartments = apartments;
        } else {
          _search(searchController.text);
        }
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appartement ${apartment.numero} supprimé.')));
    } catch (e) {
      debugPrint('Erreur delete: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur suppression en base')));
    }
  }

  Future<void> _assignResidentInDb(AppartementModel apartment, int residentId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final updated = await _supabase
          .from('appartements')
          .update({'resident_id': residentId, 'statut': 'occupe', 'updated_at': now})
          .eq('id', apartment.id)
          .select() as List<dynamic>;
      if (updated.isNotEmpty) {
        final ap = AppartementModel.fromJson(Map<String, dynamic>.from(updated.first));
        setState(() {
          final idx = apartments.indexWhere((a) => a.id == ap.id);
          if (idx != -1) apartments[idx] = ap;
          if (searchController.text.isEmpty) {
            filteredApartments = apartments;
          } else {
            _search(searchController.text);
          }
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Resident $residentId assigné à ${apartment.numero}')));
      }
    } catch (e) {
      debugPrint('Erreur assign: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'assignation')));
    }
  }

  // -------------------------
  // Dialogs UI
  // -------------------------

  void _showAddApartmentDialog() {
    final _formKey = GlobalKey<FormState>();
    final residenceController = TextEditingController(text: '1');
    final trancheController = TextEditingController();
    final immeubleController = TextEditingController();
    final numeroController = TextEditingController();
    final residentController = TextEditingController();
    StatutAppartEnum status = StatutAppartEnum.libre;

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
                    DropdownButtonFormField<StatutAppartEnum>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items: const [
                        DropdownMenuItem(value: StatutAppartEnum.libre, child: Text('Libre')),
                        DropdownMenuItem(value: StatutAppartEnum.occupe, child: Text('Occupé')),
                      ],
                      onChanged: (value) {
                        if (value != null) setStateDialog(() => status = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    if (status == StatutAppartEnum.occupe) ...[
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
                  final residentId = (status == StatutAppartEnum.occupe && residentController.text.trim().isNotEmpty)
                      ? int.parse(residentController.text.trim())
                      : null;
                  final newNumero = AppartementModel.generateNumero(residence, tranche, immeuble, numeroApt);

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

  void _showAssignResidentDialog(AppartementModel apartment) {
    if (apartment.statut == StatutAppartEnum.occupe) {
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

  void _showEditApartmentDialog(AppartementModel apartment) {
    final _formKey = GlobalKey<FormState>();
    final residenceController = TextEditingController(text: apartment.residence.toString());
    final trancheController = TextEditingController(text: apartment.tranche.toString());
    final immeubleController = TextEditingController(text: apartment.immeubleNum.toString());
    final numeroController = TextEditingController(text: apartment.numeroAppartement.toString());
    final residentController = TextEditingController(text: apartment.residentId?.toString() ?? '');
    StatutAppartEnum status = apartment.statut;

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
                    DropdownButtonFormField<StatutAppartEnum>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items: const [
                        DropdownMenuItem(value: StatutAppartEnum.libre, child: Text('Libre')),
                        DropdownMenuItem(value: StatutAppartEnum.occupe, child: Text('Occupé')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            status = value;
                            if (value == StatutAppartEnum.libre) residentController.clear();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    if (status == StatutAppartEnum.occupe) ...[
                      TextFormField(
                        controller: residentController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Resident ID (laisser vide si vacant)'),
                        validator: (value) {
                          if (status == StatutAppartEnum.occupe) {
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
                  final residentId = (status == StatutAppartEnum.occupe && residentController.text.trim().isNotEmpty)
                      ? int.parse(residentController.text.trim())
                      : null;

                  final newNumero = AppartementModel.generateNumero(residence, tranche, immeuble, numeroApt);

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

  void _showDeleteConfirmation(AppartementModel apartment) {
    if (!apartment.estLibre || apartment.residentId != null) {
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

  void _showApartmentDetails(AppartementModel apartment) {
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
                _buildDetailRow('Immeuble', 'Immeuble ${apartment.immeubleNum}', Icons.business),
                _buildDetailRow('N° Appartement', '${apartment.numeroAppartement}', Icons.meeting_room),
                _buildDetailRow('Statut', apartment.statut == StatutAppartEnum.occupe ? 'Occupé' : 'Libre', Icons.info_outline),
                if (apartment.statut == StatutAppartEnum.occupe) ...[
                  const Divider(height: 32),
                  _buildDetailRow('Résident', apartment.residentNomComplet ?? 'ID: ${apartment.residentId}', Icons.person),
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
                    if (apartment.estLibre) ...[
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
    final occupiedCount = filteredApartments.where((a) => a.statut == StatutAppartEnum.occupe).length;
    final vacantCount = filteredApartments.where((a) => a.statut == StatutAppartEnum.libre).length;

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
                  const Text('Aucun appartement trouvé', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
