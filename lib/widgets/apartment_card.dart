import 'package:flutter/material.dart';
import '../models/appartement_model.dart';

class ApartmentCard extends StatelessWidget {
  final AppartementModel apartment;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onAssign;
  final VoidCallback? onDelete;

  const ApartmentCard({
    super.key,
    required this.apartment,
    this.onTap,
    this.onEdit,
    this.onAssign,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOccupied = apartment.statut == StatutAppartEnum.occupe;

    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.95),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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
                        apartment.titreAffichage,
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
              _buildInfoRow(Icons.location_city, 'Résidence', apartment.residenceNom ?? 'Résidence ${apartment.residence}'),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.category, 'Tranche', apartment.trancheNom ?? 'Tranche ${apartment.tranche}'),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.business, 'Immeuble', 'Immeuble ${apartment.immeubleNum}'),
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
                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                            apartment.residentNomComplet ?? 'Résident ID: ${apartment.residentId}',
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
                    onPressed: (apartment.statut == StatutAppartEnum.libre && apartment.residentId == null)
                        ? onDelete
                        : null,
                    icon: const Icon(Icons.delete),
                    tooltip: apartment.statut == StatutAppartEnum.libre && apartment.residentId == null
                        ? 'Supprimer'
                        : 'Impossible: appartement occupé/assigné',
                    color: (apartment.statut == StatutAppartEnum.libre && apartment.residentId == null)
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
    final isOccupied = apartment.statut == StatutAppartEnum.occupe;
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
