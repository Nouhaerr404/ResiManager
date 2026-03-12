import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import '../../widgets/resident_nav_bar.dart';

class ResidentNotificationsScreen extends StatefulWidget {
  @override
  _ResidentNotificationsScreenState createState() => _ResidentNotificationsScreenState();
}

class _ResidentNotificationsScreenState extends State<ResidentNotificationsScreen> {
  final ResidentService _service = ResidentService();
  final int userId = 3; // Ahmed
  String _filterStatus = "Toutes";
  String _filterType = "Tous types";

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const Color tealColor = Color(0xFF009688);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: const ResidentNavBar(currentIndex: 2), // Index des Notifs dans ta Navbar
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _service.getNotifications(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: tealColor));

          List allNotifs = snapshot.data!;
          int unreadCount = allNotifs.where((n) => n['lu'] == false).length;

          // Filtrage local
          List filtered = allNotifs.where((n) {
            if (_filterStatus == "Non lues (2)" && n['lu'] == true) return false;
            if (_filterStatus == "Lues" && n['lu'] == false) return false;
            return true;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Notifications", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        Text("$unreadCount notifications non lues", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _service.markAllAsRead(userId);
                        _refresh();
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("Tout marquer comme lu"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tealColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 30),

                // FILTRES (Image section grise)
                _buildFilters(allNotifs, unreadCount),
                const SizedBox(height: 30),

                // LISTE DES NOTIFICATIONS
                ...filtered.map((n) => _buildNotifCard(n)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters(List all, int unread) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [Icon(Icons.filter_list, size: 18, color: Colors.grey), SizedBox(width: 10), Text("Filtres", style: TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 15),
          Row(
            children: [
              _filterChip("Toutes", true),
              _filterChip("Non lues ($unread)", false),
              _filterChip("Lues", false),
              const SizedBox(width: 20),
              const VerticalDivider(width: 1),
              const SizedBox(width: 20),
              _typeChip("Tous types", Icons.all_inclusive, true),
              _typeChip("Annonces", Icons.campaign_outlined, false),
              _typeChip("Réunions", Icons.calendar_today_outlined, false),
              _typeChip("Urgences", Icons.warning_amber_rounded, false),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildNotifCard(Map n) {
    bool isNew = n['lu'] == false;
    IconData icon = n['type'] == 'annonce' ? Icons.campaign_outlined : Icons.info_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isNew ? Colors.teal.shade200 : Colors.grey.shade200, width: isNew ? 1.5 : 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 20),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(n['titre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Spacer(),
                    if (isNew) _badge("Nouveau", Colors.teal),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.teal),
                      onPressed: () async {
                        await _service.markAsRead(n['id']);
                        _refresh();
                      },
                    ),
                  ],
                ),
                Text(n['created_at'].toString().split('.')[0], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 10),
                Text(n['message'], style: const TextStyle(color: Colors.black87, fontSize: 15)),
                const SizedBox(height: 15),
                _typeBadge(n['type']),
              ],
            ),
          ),
          // Delete action
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              await _service.deleteNotification(n['id']);
              _refresh();
            },
          )
        ],
      ),
    );
  }

  // --- HELPERS UI ---

  Widget _filterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: _filterStatus == label,
        onSelected: (v) => setState(() => _filterStatus = label),
        selectedColor: const Color(0xFF009688),
        labelStyle: TextStyle(color: _filterStatus == label ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _typeChip(String label, IconData icon, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: _filterType == label ? Colors.white : Colors.black54),
        label: Text(label),
        onPressed: () => setState(() => _filterType = label),
        backgroundColor: _filterType == label ? const Color(0xFF009688) : Colors.grey.shade100,
        labelStyle: TextStyle(color: _filterType == label ? Colors.white : Colors.black54),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _typeBadge(String type) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info_outline, size: 14, color: Colors.blue),
        const SizedBox(width: 5),
        Text(type.toUpperCase(), style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}