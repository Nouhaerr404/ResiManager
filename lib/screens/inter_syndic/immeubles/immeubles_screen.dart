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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: _C.coral,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: _C.white, size: 28),
      ),
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
        if (_immeubles.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business_rounded, size: 64, color: _C.white.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun immeuble trouvé',
                    style: TextStyle(color: _C.white.withOpacity(0.5), fontSize: 16),
                  ),
                ],
              ),
            ),
          )
        else
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
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert_rounded, color: _C.textLight, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'edit') _showEditDialog(imm);
                    if (val == 'delete') _confirmDelete(imm);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16, color: _C.dark),
                          SizedBox(width: 10),
                          Text('Modifier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Supprimer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
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
                          immeubleId: imm.id, 
                          trancheName: widget.tranche.nom,
                          residenceName: widget.tranche.residenceNom,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.dark,
                    foregroundColor: _C.white,
                    elevation: 0,
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

  // --- CRUD DIALOGS ---

  void _showAddDialog() => _showImmeubleForm();
  void _showEditDialog(ImmeubleModel imm) => _showImmeubleForm(immeuble: imm);

  void _showImmeubleForm({ImmeubleModel? immeuble}) {
    final bool isEdit = immeuble != null;
    final nomCtrl = TextEditingController(text: isEdit ? immeuble.nom : '');
    final countCtrl = TextEditingController(text: isEdit ? immeuble.nombreAppartements.toString() : '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 24, left: 24, right: 24,
          ),
          decoration: const BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isEdit ? 'Modifier Immeuble' : 'Nouvel Immeuble',
                style: const TextStyle(color: _C.dark, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 24),
              _buildFieldLabel('Nom de l\'immeuble (ex: Immeuble A1)'),
              _buildTextField(nomCtrl, 'Ex: Immeuble A1'),
              const SizedBox(height: 16),
              _buildFieldLabel('Nombre d\'unités'),
              _buildTextField(countCtrl, 'Ex: 24', keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.coral.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.coral.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: _C.coral, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le prix annuel est défini au niveau de la tranche (${widget.tranche.prixAnnuel.toStringAsFixed(0)} DH)',
                        style: TextStyle(color: _C.coral, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: saving ? null : () async {
                    if (nomCtrl.text.isEmpty) return;
                    setModalState(() => saving = true);
                    // Seules les colonnes qui existent dans la table Supabase
                    final data = {
                      'nom': nomCtrl.text.trim(),
                      'nombre_appartements': int.tryParse(countCtrl.text) ?? 0,
                      'tranche_id': widget.tranche.id,
                    };
                    try {
                      if (isEdit) {
                        await _service.updateImmeuble(immeuble.id, data);
                      } else {
                        await _service.createImmeuble(data);
                      }
                      if (mounted) {
                        Navigator.pop(ctx);
                        _loadData();
                        _showSnackBar(isEdit ? 'Immeuble mis à jour' : 'Immeuble ajouté');
                      }
                    } catch (e) {
                      setModalState(() => saving = false);
                      _showSnackBar('Erreur lors de l\'enregistrement', isError: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.coral,
                    foregroundColor: _C.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: saving 
                    ? const CircularProgressIndicator(color: _C.white)
                    : Text(isEdit ? 'Enregistrer les modifications' : 'Ajouter l\'immeuble', 
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(ImmeubleModel imm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer l\'immeuble ?'),
        content: Text('Voulez-vous vraiment supprimer "${imm.nom}" ? Cette action est irréversible et supprimera TOUS les appartements liés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: _C.textMid)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deleteImmeuble(imm.id);
                _loadData();
                _showSnackBar('Immeuble supprimé');
              } catch (e) {
                _showSnackBar('Erreur lors de la suppression', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: _C.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : _C.dark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(color: _C.textMid, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: _C.dark, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _C.textLight.withOpacity(0.5)),
        filled: true,
        fillColor: _C.bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
