import 'package:flutter/material.dart';
import '../theme/inter_syndic_palette.dart';

class InterSyndicHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData gridIcon;
  final VoidCallback? onBack;
  final VoidCallback? onAdd;
  final String? addLabel;
  final List<Widget> extraActions; // Allows adding extra buttons like PDF export

  const InterSyndicHeader({
    Key? key,
    required this.title,
    this.subtitle = 'inter_syndic',
    this.gridIcon = Icons.grid_view_rounded,
    this.onBack,
    this.onAdd,
    this.addLabel = 'Ajouter',
    this.extraActions = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: InterSyndicPalette.bgCard,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack ?? () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: InterSyndicPalette.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: InterSyndicPalette.divider),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14, color: InterSyndicPalette.dark),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: InterSyndicPalette.coral,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(gridIcon, color: InterSyndicPalette.bgCard, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: InterSyndicPalette.dark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: InterSyndicPalette.textLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ...extraActions.map((action) => Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: action,
              )),
          if (onAdd != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: InterSyndicPalette.coral,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          size: 16, color: InterSyndicPalette.bgCard),
                      if (addLabel != null && addLabel!.isNotEmpty && MediaQuery.of(context).size.width > 380) ...[
                        const SizedBox(width: 4),
                        Text(
                          addLabel!,
                          style: const TextStyle(
                            color: InterSyndicPalette.bgCard,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
