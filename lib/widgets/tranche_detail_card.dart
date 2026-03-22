import 'package:flutter/material.dart';
import '../models/tranche_model.dart';
import '../services/tranche_service.dart';

class TrancheDetailCard extends StatefulWidget {
  final TrancheModel tranche;
  final TrancheService service;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onAssignTap;

  const TrancheDetailCard({Key? key, required this.tranche, required this.service, required this.onEditTap, required this.onDeleteTap, required this.onAssignTap}) : super(key: key);

  @override
  State<TrancheDetailCard> createState() => _TrancheDetailCardState();
}

class _TrancheDetailCardState extends State<TrancheDetailCard> {
  String? _selectedType;
  List<String>? _currentList;
  bool _isLoading = false;

  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);

  void _toggleDetail(String type, Future<List<String>> fetchFunction) async {
    if (_selectedType == type) {
      setState(() { _selectedType = null; _currentList = null; });
      return;
    }
    setState(() { _selectedType = type; _isLoading = true; });
    final list = await fetchFunction;
    setState(() { _currentList = list; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    bool isActif = widget.tranche.statut == 'Actif';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(child: Text(widget.tranche.nom, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGrey), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    _buildStatusBadge(widget.tranche.statut),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(onPressed: widget.onEditTap, icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20)),
                  IconButton(
                    onPressed: widget.onDeleteTap, 
                    icon: Icon(isActif ? Icons.block_flipped : Icons.check_circle_outline, color: isActif ? Colors.red : Colors.green, size: 20)
                  ),
                ],
              )
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              "Objectif Annuel : ${widget.tranche.prixAnnuel.toInt()} DH",
              style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.person_outline, size: 16, color: primaryOrange),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.tranche.interSyndicNom ?? "Non assigné", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            ]),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatIcon(Icons.apartment, widget.tranche.nombreImmeubles, "Imm.", "imm"),
              _buildStatIcon(Icons.home_work_outlined, widget.tranche.nombreAppartements, "App.", "app"),
              _buildStatIcon(Icons.local_parking, widget.tranche.nombreParkings, "Park.", "park"),
              _buildStatIcon(Icons.garage, widget.tranche.nombreGarages, "Gar.", "gar"),
            ],
          ),

          if (_selectedType != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Text("Détails ${_selectedType == 'imm' ? 'Immeubles' : _selectedType == 'app' ? 'Appartements' : 'Espaces'} :", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            if (_isLoading) const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            else Wrap(spacing: 6, runSpacing: 6, children: (_currentList ?? []).map((n) => _buildDetailTag(n)).toList()),
          ]
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isActif = status == 'Actif';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isActif ? Colors.green : Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: (isActif ? Colors.green : Colors.grey).withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isActif ? Colors.green : Colors.grey),
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, int count, String label, String type) {
    bool isSelected = _selectedType == type;
    bool hasData = count > 0;
    return InkWell(
      onTap: !hasData ? null : () {
        if (type == "imm") _toggleDetail(type, widget.service.getImmeubleNames(widget.tranche.id));
        if (type == "app") _toggleDetail(type, widget.service.getAppartementNumeros(widget.tranche.id));
        if (type == "park") _toggleDetail(type, widget.service.getParkingNumeros(widget.tranche.id));
        if (type == "gar") _toggleDetail(type, widget.service.getGarageNumeros(widget.tranche.id));
      },
      child: Column(
        children: [
          Icon(icon, size: 22, color: isSelected ? primaryOrange : (hasData ? darkGrey : Colors.grey.shade300)),
          const SizedBox(height: 4),
          Text(count.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? primaryOrange : (hasData ? darkGrey : Colors.grey))),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          if (isSelected) Container(margin: const EdgeInsets.only(top: 4), height: 3, width: 20, decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }

  Widget _buildDetailTag(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: primaryOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(name, style: TextStyle(fontSize: 12, color: primaryOrange, fontWeight: FontWeight.bold)),
    );
  }
}
