import 'package:flutter/material.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';

class AssignSyndicDialog extends StatefulWidget {
  final TrancheModel tranche;
  final TrancheService service;
  final VoidCallback onAssigned;

  const AssignSyndicDialog({
    Key? key,
    required this.tranche,
    required this.service,
    required this.onAssigned,
  }) : super(key: key);

  @override
  _AssignSyndicDialogState createState() => _AssignSyndicDialogState();
}

class _AssignSyndicDialogState extends State<AssignSyndicDialog> {
  int? _selectedSyndicId;

  @override
  void initState() {
    super.initState();
    _selectedSyndicId = widget.tranche.interSyndicId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Assigner un syndic à ${widget.tranche.nom}"),
      content: FutureBuilder<List<Map<String, dynamic>>>(
        future: widget.service.getAvailableInterSyndics(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final syndics = snapshot.data!;
          return DropdownButton<int>(
            value: _selectedSyndicId,
            hint: const Text("Choisir un inter-syndic"),
            isExpanded: true,
            items: syndics.map((syndic) {
              return DropdownMenuItem<int>(
                value: syndic['id'],
                child: Text("${syndic['prenom']} ${syndic['nom']}"),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSyndicId = value;
              });
            },
          );
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () async {
            await widget.service.assignInterSyndic(widget.tranche.id, _selectedSyndicId);
            widget.onAssigned(); // Rafraîchit la liste derrière
            Navigator.pop(context);
          },
          child: const Text("Enregistrer"),
        ),
      ],
    );
  }
}