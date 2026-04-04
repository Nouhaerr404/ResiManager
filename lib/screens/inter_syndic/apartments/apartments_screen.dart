import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/appartement_model.dart';
import '../../../models/resident_model.dart';
import '../../../services/resident_service.dart';
import '../../../widgets/apartment_card.dart';
import '../../../widgets/apartment_filters.dart';
import '../../../services/tranche_service.dart';
import '../../../services/apartment_pdf_service.dart';
import '../../../widgets/inter_syndic_header.dart';
import '../../../theme/inter_syndic_palette.dart';
import 'package:url_launcher/url_launcher.dart';
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
      // 1. Supprimer les paiements liés à cet appartement d'abord (contrainte FK)
      await _supabase.from('paiements').delete().eq('appartement_id', apartment.id);

      // 2. Désassigner quiconque est lié à lui côté résidents
      await _supabase.from('residents').update({'appartement_id': null}).eq('appartement_id', apartment.id);

      // 3. Supprimer l'appartement (le code précédent était correct mais incomplet)
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

  Future<void> _callResident(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numéro de téléphone non disponible')));
      return;
    }
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de lancer l\'appel')));
    }
  }

  Future<void> _unassignResidentInDb(AppartementModel apartment) async {
    try {
      setState(() => loading = true);
      final now = DateTime.now().toIso8601String();
      
      // 1. Libérer le résident lié à cet appartement
      await _supabase
          .from('residents')
          .update({'appartement_id': null, 'updated_at': now})
          .eq('appartement_id', apartment.id);

      // 2. Mettre à jour l'appartement : statut libre et resident_id null
      final updated = await _supabase
          .from('appartements')
          .update({
            'resident_id': null, 
            'statut': 'libre', 
            'updated_at': now
          })
          .eq('id', apartment.id)
          .select('*, users(*), immeubles!inner(id, nom, tranche_id, tranches!inner(id, nom, residence_id, residences!inner(id, nom)))') as List<dynamic>;

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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Résident désassigné de ${apartment.numero}')));
      }
    } catch (e) {
      debugPrint('Erreur unassign: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la désassignation')));
    } finally {
      if (mounted) setState(() => loading = false);
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

  Future<void> _exportPdf() async {
    if (filteredApartments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La liste est vide')),
      );
      return;
    }

    try {
      final pdfBytes = await ApartmentPdfService.generate(
        apartments: filteredApartments,
        residenceNom: widget.residenceName ?? widget.residenceId?.toString() ?? 'ResiManager',
        trancheNom: widget.trancheName ?? widget.trancheId?.toString() ?? '-',
      );

      await ApartmentPdfService.share(
        pdfBytes,
        'Rapport_Appartements_${widget.trancheName ?? "General"}',
      );
    } catch (e) {
      debugPrint('Erreur PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la génération du PDF')),
        );
      }
    }
  }

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
                  
                  final residenceStr = widget.residenceName ?? residenceController.text.trim();
                  final trancheStr = widget.trancheName ?? trancheController.text.trim();
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

                  final resStr = widget.residenceName ?? residenceController.text.trim();
                  final traStr = widget.trancheName ?? trancheController.text.trim();
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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

  void _showUnassignResidentConfirm(AppartementModel apartment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Désassigner le résident ?'),
        content: Text('Voulez-vous vraiment retirer le résident de l\'appartement ${apartment.numero} ? L\'appartement redeviendra "Vacant".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: InterSyndicPalette.orange, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await _unassignResidentInDb(apartment);
              if (mounted) Navigator.pop(context); // Close details sheet if still open
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showApartmentDetails(AppartementModel apartment) {
    final isOccupied = apartment.statut == StatutAppartEnum.occupe;
    final accentColor = isOccupied ? InterSyndicPalette.green : InterSyndicPalette.orange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: InterSyndicPalette.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: InterSyndicPalette.divider, borderRadius: BorderRadius.circular(10))),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.home_work_rounded, color: accentColor, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                apartment.numero,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: InterSyndicPalette.dark),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  isOccupied ? 'OCCUPÉ' : 'VACANT',
                                  style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: InterSyndicPalette.textLight)),
                      ],
                    ),

                    const SizedBox(height: 32),
                    const Text('Détails du bien', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: InterSyndicPalette.darkMid)),
                    const SizedBox(height: 16),
                    
                    _buildDetailBox(
                      items: [
                        _DetailItem(Icons.location_city_rounded, 'Résidence', apartment.residenceNom ?? 'N/A'),
                        _DetailItem(Icons.layers_rounded, 'Tranche', apartment.trancheNom ?? 'N/A'),
                        _DetailItem(Icons.business_rounded, 'Immeuble', 'Immeuble ${apartment.immeubleNum}'),
                        _DetailItem(Icons.meeting_room_rounded, 'Numéro', 'Appartement ${apartment.numeroAppartement}'),
                      ],
                    ),

                    if (isOccupied) ...[
                      const SizedBox(height: 32),
                      const Text('Résident actuel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: InterSyndicPalette.darkMid)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: InterSyndicPalette.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: InterSyndicPalette.divider.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: InterSyndicPalette.coralLight,
                              child: Icon(Icons.person_rounded, color: InterSyndicPalette.coral),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    apartment.residentNomComplet ?? 'Utilisateur',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: InterSyndicPalette.dark),
                                  ),
                                  const Text('Occupant assigné', style: TextStyle(fontSize: 12, color: InterSyndicPalette.textLight)),
                                ],
                              ),
                            ),
                            if (apartment.residentId != null)
                              Container(
                                decoration: BoxDecoration(color: InterSyndicPalette.greenLight, borderRadius: BorderRadius.circular(12)),
                                child: IconButton(
                                  onPressed: () => _callResident(apartment.residentTelephone),
                                  icon: const Icon(Icons.phone_in_talk_rounded, color: InterSyndicPalette.green, size: 20),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 48),
                    
                    // Actions
                    const Text('Actions disponibles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: InterSyndicPalette.darkMid)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildActionButton(Icons.edit_rounded, 'Modifier', InterSyndicPalette.blue, () { Navigator.pop(context); _showEditApartmentDialog(apartment); })),
                        const SizedBox(width: 12),
                        if (apartment.estLibre)
                          Expanded(child: _buildActionButton(Icons.person_add_rounded, 'Assigner', InterSyndicPalette.green, () { Navigator.pop(context); _showAssignResidentDialog(apartment); }))
                        else
                          Expanded(child: _buildActionButton(Icons.person_remove_rounded, 'Désassigner', InterSyndicPalette.orange, () { Navigator.pop(context); _showUnassignResidentConfirm(apartment); })),
                      ],
                    ),
                    if (apartment.estLibre && apartment.residentId == null) ...[
                      const SizedBox(height: 12),
                      _buildActionButton(Icons.delete_outline_rounded, 'Supprimer définitivement', InterSyndicPalette.red, () { Navigator.pop(context); _showDeleteConfirmation(apartment); }, fullWidth: true),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailBox({required List<_DetailItem> items}) {
    return Container(
      decoration: BoxDecoration(
        color: InterSyndicPalette.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: InterSyndicPalette.divider.withOpacity(0.5)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: InterSyndicPalette.bg, borderRadius: BorderRadius.circular(12)), child: Icon(item.icon, size: 18, color: InterSyndicPalette.textMid)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label, style: const TextStyle(fontSize: 11, color: InterSyndicPalette.textLight, fontWeight: FontWeight.w600)),
                        Text(item.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: InterSyndicPalette.darkMid)),
                      ],
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1) Divider(height: 1, indent: 64, color: InterSyndicPalette.divider.withOpacity(0.5)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap, {bool fullWidth = false}) {
    final btn = Container(
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
          ],
        ),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
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
      backgroundColor: InterSyndicPalette.bg,
      body: SafeArea(
        child: Column(
          children: [
            // E-tête unifiée
            InterSyndicHeader(
              title: 'ResiManager',
              subtitle: 'inter_syndic',
              gridIcon: Icons.business_rounded,
              onBack: widget.onBack ?? () => Navigator.pop(context),
              onAdd: _showAddApartmentDialog,
              addLabel: 'Ajouter',
              extraActions: [
                GestureDetector(
                  onTap: _exportPdf,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: InterSyndicPalette.coralLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: InterSyndicPalette.coral.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded,
                        color: InterSyndicPalette.coral, size: 20),
                  ),
                ),
              ],
            ),

            // Zone de contenu (Scrollable avec Slivers)
            Expanded(
              child: RefreshIndicator(
                color: InterSyndicPalette.coral,
                onRefresh: _loadApartments,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // 1. Statistiques (Hero Card)
                    SliverToBoxAdapter(
                      child: _buildHeroStatsCard(filteredApartments.length, occupiedCount, vacantCount),
                    ),

                    // 2. Barre de recherche
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: InterSyndicPalette.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: InterSyndicPalette.divider),
                          ),
                          child: TextField(
                            controller: searchController,
                            onChanged: _search,
                            style: const TextStyle(fontSize: 14, color: InterSyndicPalette.dark, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'Rechercher un appartement...',
                              hintStyle: const TextStyle(color: InterSyndicPalette.textLight, fontSize: 13),
                              prefixIcon: const Icon(Icons.search_rounded, color: InterSyndicPalette.coral, size: 22),
                              suffixIcon: searchController.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        searchController.clear();
                                        _search('');
                                      },
                                      child: const Icon(Icons.close_rounded, color: InterSyndicPalette.textLight, size: 18),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. Filtres (Optionnel)
                    if (showFilters)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: ApartmentFilters(
                              onFilterChanged: (tranche, immeuble, status) {
                                _applyFilters(tranche: tranche, immeuble: immeuble, status: status);
                              },
                            ),
                          ),
                        ),
                      ),

                    // 4. Bouton Toggle Filtres
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => setState(() => showFilters = !showFilters),
                            icon: Icon(showFilters ? Icons.filter_list_off : Icons.filter_list, color: InterSyndicPalette.textMid, size: 18),
                            label: Text(showFilters ? 'Masquer filtres' : 'Afficher filtres', style: const TextStyle(color: InterSyndicPalette.textMid, fontSize: 12)),
                          ),
                        ),
                      ),
                    ),

                    // 5. Liste des appartements
                    if (loading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator(color: InterSyndicPalette.coral)),
                      )
                    else if (filteredApartments.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: InterSyndicPalette.divider.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.search_off_rounded, size: 80, color: InterSyndicPalette.textLight.withOpacity(0.5)),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Aucun appartement trouvé', 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: InterSyndicPalette.darkMid),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Essayez de modifier vos filtres ou votre recherche', 
                                style: TextStyle(fontSize: 14, color: InterSyndicPalette.textLight),
                              ),
                              const SizedBox(height: 24),
                              if (searchController.text.isNotEmpty || showFilters)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      searchController.clear();
                                      _search('');
                                      showFilters = false;
                                      // Note: Reset filters logic here if applicable
                                    });
                                  },
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Réinitialiser tout'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: InterSyndicPalette.coral,
                                    side: const BorderSide(color: InterSyndicPalette.coral),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final apartment = filteredApartments[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ApartmentCard(
                                  apartment: apartment,
                                  onTap: () => _showApartmentDetails(apartment),
                                  onEdit: () => _showEditApartmentDialog(apartment),
                                  onAssign: () => _showAssignResidentDialog(apartment),
                                  onUnassign: () => _showUnassignResidentConfirm(apartment),
                                  onCall: () => _callResident(apartment.residentTelephone),
                                  onDelete: () => _showDeleteConfirmation(apartment),
                                ),
                              );
                            },
                            childCount: filteredApartments.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStatsCard(int total, int occupied, int vacant) {
    double occupationPercentage = total > 0 ? (occupied / total) : 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: InterSyndicPalette.coral,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: InterSyndicPalette.coral.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'Appartements',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '$total appartements',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    const Text(
                      'Votre parc',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(occupationPercentage * 100).toInt()}% occupés',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$occupied / $total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: occupationPercentage,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHeroStatMiniItem(total.toString().padLeft(2, '0'), 'Total'),
                _buildHeroStatDivider(),
                _buildHeroStatMiniItem(occupied.toString().padLeft(2, '0'), 'Occupés'),
                _buildHeroStatDivider(),
                _buildHeroStatMiniItem(vacant.toString().padLeft(2, '0'), 'Vacants'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatMiniItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStatDivider() {
    return Container(
      height: 28,
      width: 1,
      color: Colors.white.withOpacity(0.15),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, List<Color> gradientColors, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: InterSyndicPalette.bgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: InterSyndicPalette.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradientColors[0].withOpacity(0.15),
                  gradientColors[0].withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: gradientColors[0], size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value, 
            style: const TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.w800, 
              color: InterSyndicPalette.dark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label, 
            style: const TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.w600, 
              color: InterSyndicPalette.textMid,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  _DetailItem(this.icon, this.label, this.value);
}
