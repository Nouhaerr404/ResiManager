import 'package:flutter/material.dart';
import '../models/appartement_model.dart';
import '../theme/inter_syndic_palette.dart';

class ApartmentCard extends StatelessWidget {
  final AppartementModel apartment;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onAssign;
  final VoidCallback? onUnassign;
  final VoidCallback? onCall;
  final VoidCallback? onDelete;

  const ApartmentCard({
    super.key,
    required this.apartment,
    this.onTap,
    this.onEdit,
    this.onAssign,
    this.onUnassign,
    this.onCall,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOccupied = apartment.statut == StatutAppartEnum.occupe;
    final accentColor = isOccupied ? InterSyndicPalette.green : InterSyndicPalette.orange;
    final bgColor = isOccupied ? InterSyndicPalette.greenLight.withOpacity(0.3) : InterSyndicPalette.bgCard;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: InterSyndicPalette.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: InterSyndicPalette.divider),
        ),
        child: Column(
          children: [
            // 1. En-tête (Avatar, Titre, Statut)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: isOccupied ? InterSyndicPalette.greenLight : InterSyndicPalette.coralLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.home_rounded,
                        color: isOccupied ? InterSyndicPalette.green : InterSyndicPalette.coral,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          apartment.numero,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: InterSyndicPalette.dark,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.business_rounded, size: 10, color: InterSyndicPalette.textLight),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Immeuble ${apartment.immeubleNom ?? apartment.immeubleNum} • ${apartment.residenceNom ?? apartment.residence}',
                                style: const TextStyle(color: InterSyndicPalette.textLight, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(isOccupied),
                ],
              ),
            ),

            // 2. Section Info / Résident (Milieu)
            if (isOccupied)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: InterSyndicPalette.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: InterSyndicPalette.divider.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 14, color: InterSyndicPalette.coral),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          apartment.residentNomComplet ?? 'Résident assigné',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: InterSyndicPalette.darkMid,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (apartment.residentId != null)
                        const Icon(Icons.phone_in_talk_rounded, size: 14, color: InterSyndicPalette.green),
                    ],
                  ),
                ),
              ),

            // 3. Barre d'actions (Bas)
            Container(
              decoration: BoxDecoration(
                color: InterSyndicPalette.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: const Border(top: BorderSide(color: InterSyndicPalette.divider)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  if (!isOccupied)
                    _buildMainActionBtn(
                      label: 'Assigner',
                      icon: Icons.person_add_rounded,
                      color: InterSyndicPalette.green,
                      onTap: onAssign,
                    )
                  else
                    _buildMainActionBtn(
                      label: 'Désassigner',
                      icon: Icons.person_remove_rounded,
                      color: InterSyndicPalette.orange,
                      onTap: onUnassign,
                    ),
                  const SizedBox(width: 6),
                  if (!apartment.estLibre) ...[
                    _buildIconActionBtn(
                      icon: Icons.phone_in_talk_rounded,
                      color: InterSyndicPalette.green,
                      bgColor: InterSyndicPalette.greenLight,
                      onTap: onCall,
                    ),
                    const SizedBox(width: 6),
                  ],
                  _buildIconActionBtn(
                    icon: Icons.edit_rounded,
                    color: InterSyndicPalette.blue,
                    bgColor: InterSyndicPalette.bg,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 6),
                  if (!isOccupied && apartment.residentId == null)
                    _buildIconActionBtn(
                      icon: Icons.delete_rounded,
                      color: InterSyndicPalette.red,
                      bgColor: InterSyndicPalette.redLight,
                      onTap: onDelete,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isOccupied) {
    final color = isOccupied ? InterSyndicPalette.green : InterSyndicPalette.orange;
    final bgColor = isOccupied ? InterSyndicPalette.greenLight : InterSyndicPalette.orangeLight;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            isOccupied ? 'Occupé' : 'Vacant',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionBtn({required String label, required IconData icon, required Color color, required VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconActionBtn({required IconData icon, required Color color, required Color bgColor, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: InterSyndicPalette.divider),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
