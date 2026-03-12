import 'package:flutter/material.dart';
import '../models/appartement_model.dart';

class ApartmentFilters extends StatefulWidget {
  final Function(int? tranche, int? immeuble, StatutAppartEnum? status) onFilterChanged;

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
  StatutAppartEnum? selectedStatus;

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
                selected: selectedStatus == StatutAppartEnum.occupe,
                onSelected: (selected) {
                  setState(() => selectedStatus = selected ? StatutAppartEnum.occupe : null);
                  _applyFilters();
                },
                selectedColor: Colors.green.shade100,
              ),
              FilterChip(
                label: const Text('Vacant'),
                selected: selectedStatus == StatutAppartEnum.libre,
                onSelected: (selected) {
                  setState(() => selectedStatus = selected ? StatutAppartEnum.libre : null);
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
