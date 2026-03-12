import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isCurrency;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.subtitle = '',
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240, // Largeur de la carte fixée
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // C'EST ICI QUE CA SE JOUE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // L'ajout de "Expanded" empêche le débordement
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  maxLines: 2, // Autorise 2 lignes
                  overflow: TextOverflow.ellipsis, // Coupe avec "..." si vraiment trop long
                ),
              ),
              const SizedBox(width: 8), // Petit espace pour séparer du logo
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              )
            ],
          ),
          const SizedBox(height: 15),
          Text(
              isCurrency ? '$value DH' : value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 5),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}