import 'package:flutter/material.dart';
import '../models/tranche_model.dart';
import '../services/tranche_service.dart';

class TrancheDetailCard extends StatefulWidget {
  final TrancheModel tranche;
  final TrancheService service;
  final VoidCallback onEditTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback onAssignTap;

  const TrancheDetailCard({Key? key, required this.tranche, required this.service, required this.onEditTap, this.onDeleteTap, required this.onAssignTap}) : super(key: key);

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
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(onPressed: widget.onEditTap, icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20)),
                  if (widget.onDeleteTap != null)
                    IconButton(
                      onPressed: widget.onDeleteTap, 
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20)
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
              _buildStatIcon(Icons.storefront_outlined, widget.tranche.nombreGarages, "Gar.", "gar"), // CHANGEMENT ICI
              _buildStatIcon(Icons.inventory_2, widget.tranche.nombreBoxes, "Box", "box"),
            ],
          ),

          if (_selectedType != null) ...[
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 10),
            Text("Détails ${_selectedType == 'imm' ? 'Immeubles' : _selectedType == 'app' ? 'Appartements' : 'Espaces'} :", 
                 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            if (_isLoading) 
              const Center(child: Padding(
                padding: EdgeInsets.all(10.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ))
            else 
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120), // Empêche le dépassement vertical
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6, 
                    runSpacing: 6, 
                    children: (_currentList ?? []).map((n) => _buildDetailTag(n)).toList()
                  ),
                ),
              ),
          ]
        ],
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
        if (type == "box") _toggleDetail(type, widget.service.getBoxNumeros(widget.tranche.id));
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: primaryOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(name, style: TextStyle(fontSize: 11, color: primaryOrange, fontWeight: FontWeight.bold)),
    );
  }
}