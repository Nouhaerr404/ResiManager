import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/appartement_model.dart';
import '../../../models/resident_model.dart';
import '../../../services/resident_service.dart';
import '../../../widgets/apartment_card.dart';
import '../../../widgets/apartment_filters.dart';
import '../../../services/tranche_service.dart';

class ApartmentsListScreen extends StatefulWidget {
  final int? trancheId;
  final int? residenceId;
  final int? immeubleId; // Ajouté
  final String? trancheName;
  final String? residenceName;
  final VoidCallback? onBack;

  const ApartmentsListScreen({
    Key? key, 
    this.trancheId, 
    this.residenceId,
    this.immeubleId, // Ajouté
    this.trancheName,
    this.residenceName,
    this.onBack
  }) : super(key: key);

  @override
  State<ApartmentsListScreen> createState() => _ApartmentsListScreenState();
}

class _ApartmentsListScreenState extends State<ApartmentsListScreen> {
  final _supabase = Supabase.instance.client;
  final _residentService = ResidentService();
  final _trancheService = TrancheService();
  
  List<AppartementModel> apartments = [];
  List<AppartementModel> filteredApartments = [];
  List<Map<String, dynamic>> _immeublesDeLaTranche = []; // Liste des immeubles pour l'autocomplete
  
  bool showFilters = false;
  final TextEditingController searchController = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadApartments();
    _loadTrancheImmeubles();
  }

  Future<void> _loadTrancheImmeubles() async {
    if (widget.trancheId != null) {
      final list = await _trancheService.getImmeublesByTranche(widget.trancheId!);
      setState(() {
        _immeublesDeLaTranche = list;
      });
    }
  }

  Future<void> _loadApartments() async {
    setState(() => loading = true);
    try {
      dynamic query = _supabase.from('appartements').select('*, users(*), immeubles!inner(id, nom, tranche_id, tranches!inner(id, nom, residence_id, residences!inner(id, nom)))');
      
      if (widget.trancheId != null) {
        query = query.eq('immeubles.tranche_id', widget.trancheId!);
      }
      if (widget.immeubleId != null) {
        query = query.eq('immeuble_id', widget.immeubleId!);
      }

      final response = await query.order('id', ascending: true) as List<dynamic>;

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
        if (tranche != null && int.tryParse(apt.tranche) != tranche) return false;
        if (immeuble != null && (int.tryParse(apt.immeubleNum) != immeuble)) return false;
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
    required dynamic residence,
    required dynamic tranche,
    required int immeubleId,
    required dynamic immeubleLabel, // peut être varchar
    required dynamic numeroApt,
    required StatutAppartEnum status,
    int? residentId,
  }) async {
    // Le numero généré utilise le label de l'immeuble (ex: "A" ou "3")
    final numero = AppartementModel.generateNumero(residence, tranche, immeubleLabel, numeroApt);
    final now = DateTime.now().toIso8601String();
    final row = {
      'numero': numero,
      'immeuble_id': immeubleId,
      'statut': status == StatutAppartEnum.libre ? 'libre' : 'occupe',
      'resident_id': residentId,
      'created_at': now,
      'updated_at': now,
    };

    try {
      final inserted = await _supabase.from('appartements').insert(row).select('*, users(*), immeubles!inner(id, nom, tranche_id, tranches!inner(id, nom, residence_id, residences!inner(id, nom)))') as List<dynamic>;
      if (inserted.isNotEmpty) {
        final ap = AppartementModel.fromJson(Map<String, dynamic>.from(inserted.first));
        
        // Synchronisation du résident si assigné
        if (residentId != null) {
          await _supabase.from('residents').update({'appartement_id': ap.id, 'updated_at': now}).eq('user_id', residentId);
        }

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
    required dynamic residence,
    required dynamic tranche,
    required int immeubleId,
    required dynamic immeubleLabel,
    required dynamic numeroApt,
    required StatutAppartEnum status,
    int? residentId,
  }) async {
    final numero = AppartementModel.generateNumero(residence, tranche, immeubleLabel, numeroApt);
    final now = DateTime.now().toIso8601String();
    final row = {
      'numero': numero,
      'immeuble_id': immeubleId,
      'statut': status == StatutAppartEnum.libre ? 'libre' : 'occupe',
      'resident_id': residentId,
      'updated_at': now,
    };

    try {
      // 1. Nettoyer TOUS les liens actuels vers cet appartement dans la table residents
      // pour garantir qu'un seul résident pointe vers lui.
      if (oldApartment.residentId != residentId) {
        await _supabase.from('residents').update({'appartement_id': null, 'updated_at': now}).eq('appartement_id', oldApartment.id);
      }

      final updated = await _supabase
          .from('appartements')
          .update(row)
          .eq('id', oldApartment.id)
          .select('*, users(*), immeubles!inner(id, nom, tranche_id, tranches!inner(id, nom, residence_id, residences!inner(id, nom)))') as List<dynamic>;

      if (updated.isNotEmpty) {
        final ap = AppartementModel.fromJson(Map<String, dynamic>.from(updated.first));

        // 2. Assigner le nouveau résident si présent
        if (residentId != null) {
          await _supabase.from('residents').update({'appartement_id': ap.id, 'updated_at': now}).eq('user_id', residentId);
        }

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
      
      // 1. Libérer quiconque était lié à cet appartement dans la table residents
      await _supabase
          .from('residents')
          .update({'appartement_id': null, 'updated_at': now})
          .eq('appartement_id', apartment.id);

      // 2. Mise à jour de l'appartement
      final updated = await _supabase
          .from('appartements')
          .update({'resident_id': residentId, 'statut': 'occupe', 'updated_at': now})
          .eq('id', apartment.id)
          .select('*, users(*), immeubles!inner(id, nom, tranche_id, tranches!inner(id, nom, residence_id, residences!inner(id, nom)))') as List<dynamic>;
      
      // 3. Mise à jour du nouveau résident pour lier à l'appartement
      await _supabase
          .from('residents')
          .update({'appartement_id': apartment.id, 'updated_at': now})
          .eq('user_id', residentId);

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
    final residenceController = TextEditingController(text: widget.residenceName ?? widget.residenceId?.toString() ?? '1');
    final trancheController = TextEditingController(text: widget.trancheName ?? widget.trancheId?.toString() ?? '');
    
    int? selectedImmeubleId;
    String? selectedImmeubleNom;
    final immeubleInputController = TextEditingController();

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
                      readOnly: true, // Désactivé modification
                      decoration: const InputDecoration(labelText: 'Résidence', fillColor: Colors.black12, filled: true),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: trancheController,
                      readOnly: true, // Désactivé modification
                      decoration: const InputDecoration(labelText: 'Tranche', fillColor: Colors.black12, filled: true),
                    ),
                    const SizedBox(height: 8),
                    
                    // Autocomplete Immeuble
                    Autocomplete<Map<String, dynamic>>(
                      displayStringForOption: (i) => i['nom'],
                      optionsBuilder: (textEditingValue) {
                        return _immeublesDeLaTranche.where((i) => 
                          i['nom'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase())
                        );
                      },
                      onSelected: (i) {
                        setStateDialog(() {
                          selectedImmeubleId = i['id'];
                          selectedImmeubleNom = i['nom'];
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Immeuble (Autocomplétion)',
                            hintText: 'Sélectionnez un immeuble...',
                            prefixIcon: Icon(Icons.business_rounded),
                          ),
                          validator: (value) {
                            if (selectedImmeubleId == null) return 'Sélectionnez un immeuble';
                            return null;
                          },
                        );
                      },
                    ),
                    
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: numeroController,
                      keyboardType: TextInputType.text, // Changé en text pour varchar
                      decoration: const InputDecoration(labelText: 'N° Appartement (ex: 201 ou A1)'),
                      validator: (value) => (value == null || value.isEmpty) ? 'Requis' : null,
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
                      const SizedBox(height: 8),
                      Autocomplete<ResidentModel>(
                        displayStringForOption: (r) => '${r.prenom} ${r.nom} (${r.userId})',
                        optionsBuilder: (textEditingValue) async {
                          if (textEditingValue.text.isEmpty) return const Iterable<ResidentModel>.empty();
                          return await _residentService.searchResidents(textEditingValue.text, trancheId: widget.trancheId);
                        },
                        onSelected: (r) {
                          residentController.text = r.userId.toString();
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Chercher un résident (Nom/Prénom)',
                              hintText: 'Commencez à taper...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            validator: (value) {
                              if (residentController.text.isEmpty) return 'Veuillez sélectionner un résident';
                              return null;
                            },
                          );
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
                  
                  final residenceStr = widget.residenceId?.toString() ?? residenceController.text.trim();
                  final trancheStr = widget.trancheId?.toString() ?? trancheController.text.trim();
                  final immId = selectedImmeubleId!;
                  final immLabel = selectedImmeubleNom!;
                  final numAptStr = numeroController.text.trim();
                  
                  final residentId = (status == StatutAppartEnum.occupe && residentController.text.trim().isNotEmpty)
                      ? int.parse(residentController.text.trim())
                      : null;
                  
                  final newNumero = AppartementModel.generateNumero(residenceStr, trancheStr, immLabel, numAptStr);

                  final exists = apartments.any((a) => a.numero == newNumero);
                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Le numéro $newNumero existe déjà.')));
                    return;
                  }

                  Navigator.pop(context);
                  await _addApartmentToDb(
                    residence: residenceStr,
                    tranche: trancheStr,
                    immeubleId: immId,
                    immeubleLabel: immLabel,
                    numeroApt: numAptStr,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<ResidentModel>(
                displayStringForOption: (r) => '${r.prenom} ${r.nom} (${r.userId})',
                optionsBuilder: (textEditingValue) async {
                  if (textEditingValue.text.isEmpty) return const Iterable<ResidentModel>.empty();
                  return await _residentService.searchResidents(textEditingValue.text, trancheId: widget.trancheId);
                },
                onSelected: (r) {
                  residentController.text = r.userId.toString();
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Chercher un résident (Nom/Prénom)',
                      hintText: 'Commencez à taper...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    validator: (value) {
                      if (residentController.text.isEmpty) return 'Veuillez sélectionner un résident';
                      return null;
                    },
                  );
                },
              ),
            ],
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
    final residenceController = TextEditingController(text: widget.residenceName ?? apartment.residence);
    final trancheController = TextEditingController(text: widget.trancheName ?? apartment.tranche);
    
    int? selectedImmeubleId = apartment.immeubleId;
    String? selectedImmeubleNom = apartment.immeubleNum; // C'est le label du numéro
    
    final numeroController = TextEditingController(text: apartment.numeroAppartement);
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
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Résidence', fillColor: Colors.black12, filled: true),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: trancheController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Tranche', fillColor: Colors.black12, filled: true),
                    ),
                    const SizedBox(height: 8),
                    
                    Autocomplete<Map<String, dynamic>>(
                      displayStringForOption: (i) => i['nom'],
                      initialValue: TextEditingValue(text: apartment.immeubleNom ?? apartment.immeubleNum),
                      optionsBuilder: (textEditingValue) {
                        return _immeublesDeLaTranche.where((i) => 
                          i['nom'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase())
                        );
                      },
                      onSelected: (i) {
                        setStateDialog(() {
                          selectedImmeubleId = i['id'];
                          selectedImmeubleNom = i['nom'];
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Immeuble (Autocomplétion)',
                            prefixIcon: Icon(Icons.business_rounded),
                          ),
                          validator: (value) {
                            if (selectedImmeubleId == null) return 'Sélection requise';
                            return null;
                          },
                        );
                      },
                    ),
                    
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: numeroController,
                      decoration: const InputDecoration(labelText: 'N° Appartement'),
                      validator: (value) => (value == null || value.isEmpty) ? 'Requis' : null,
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
                      const SizedBox(height: 8),
                      Autocomplete<ResidentModel>(
                        displayStringForOption: (r) => '${r.prenom} ${r.nom} (${r.userId})',
                        initialValue: TextEditingValue(text: apartment.residentNomComplet ?? (apartment.residentId?.toString() ?? '')),
                        optionsBuilder: (textEditingValue) async {
                          if (textEditingValue.text.isEmpty) return const Iterable<ResidentModel>.empty();
                          return await _residentService.searchResidents(textEditingValue.text, trancheId: widget.trancheId);
                        },
                        onSelected: (r) {
                          residentController.text = r.userId.toString();
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Chercher un résident (Nom/Prénom)',
                              hintText: 'Commencez à taper...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            validator: (value) {
                              if (residentController.text.isEmpty) return 'Sélection requise';
                              return null;
                            },
                          );
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

                  final resStr = widget.residenceId?.toString() ?? residenceController.text.trim();
                  final traStr = widget.trancheId?.toString() ?? trancheController.text.trim();
                  final immId = selectedImmeubleId!;
                  final immLabel = selectedImmeubleNom!;
                  final numAptStr = numeroController.text.trim();
                  
                  final residentId = (status == StatutAppartEnum.occupe && residentController.text.trim().isNotEmpty)
                      ? int.parse(residentController.text.trim())
                      : null;

                  final newNumero = AppartementModel.generateNumero(resStr, traStr, immLabel, numAptStr);

                  final exists = apartments.any((a) => a.numero == newNumero && a.id != apartment.id);
                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Le numéro $newNumero existe déjà.')));
                    return;
                  }

                  Navigator.pop(context);
                  await _updateApartmentInDb(
                    oldApartment: apartment,
                    residence: resStr,
                    tranche: traStr,
                    immeubleId: immId,
                    immeubleLabel: immLabel,
                    numeroApt: numAptStr,
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
                Row(children: [Icon(Icons.home, size: 32, color: Theme.of(context).primaryColor), const SizedBox(width: 12), Expanded(child: Text(apartment.titreAffichage, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))]),
                const SizedBox(height: 24),
                _buildDetailRow('Résidence', 'Résidence ${apartment.residence}', Icons.location_city),
                _buildDetailRow('Tranche', 'Tranche ${apartment.tranche}', Icons.category),
                _buildDetailRow('Immeuble', 'Immeuble ${apartment.immeubleNom ?? apartment.immeubleNum}', Icons.business),
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
      body: Stack(
        children: [
          // 1. IMAGE DE FOND
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/residence_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. VOILE SOMBRE
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),

          // 3. CONTENU
          SafeArea(
            child: Column(
              children: [
                // En-tête personnalisé (Style Syndic Général)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      // Bouton RETOUR
                      GestureDetector(
                        onTap: widget.onBack ?? () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.chevron_left_rounded,
                              color: Colors.black87, size: 24),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Bouton GRILLE coral
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6F4A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.apartment_rounded,
                            color: Colors.white, size: 20),
                      ),

                      const SizedBox(width: 16),

                      // Titre
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gestion des',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400),
                            ),
                            Text(
                              'Appartements',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bouton AJOUTER (coral, reste inchangé)
                      GestureDetector(
                        onTap: _showAddApartmentDialog,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6F4A),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6F4A).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 26),
                        ),
                      ),
                    ],
                  ),
                ),

                // Barre de recherche stylisée
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: TextField(
                    controller: searchController,
                    onChanged: _search,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un appartement...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          searchController.clear();
                          _search('');
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Statistiques stylisées
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Total', filteredApartments.length.toString(), Icons.home, Colors.white),
                      _buildStatCard('Occupés', occupiedCount.toString(), Icons.check_circle, const Color(0xFFFF6F4A)),
                      _buildStatCard('Vacants', vacantCount.toString(), Icons.error_outline, Colors.white70),
                    ],
                  ),
                ),

                if (showFilters)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ApartmentFilters(
                      onFilterChanged: (tranche, immeuble, status) {
                        _applyFilters(tranche: tranche, immeuble: immeuble, status: status);
                      },
                    ),
                  ),

                // Liste des appartements
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : filteredApartments.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.white.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        const Text('Aucun appartement trouvé', style: TextStyle(fontSize: 16, color: Colors.white70)),
                      ],
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: _loadApartments,
                    child: ListView.builder(
                      itemCount: filteredApartments.length,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
