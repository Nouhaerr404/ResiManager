import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../utils/temp_session.dart';
import 'tranches_list_screen.dart';

class InterSyndicSelectionScreen extends StatefulWidget {
  const InterSyndicSelectionScreen({Key? key}) : super(key: key);

  @override
  _InterSyndicSelectionScreenState createState() => _InterSyndicSelectionScreenState();
}

class _InterSyndicSelectionScreenState extends State<InterSyndicSelectionScreen> {
  final UserService _userService = UserService();
  late Future<List<UserModel>> _interSyndicsFuture;

  @override
  void initState() {
    super.initState();
    _interSyndicsFuture = _userService.getUsersByRole(RoleEnum.inter_syndic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("Sélectionner un Inter-Syndic"),
        backgroundColor: const Color(0xFF4CAF82),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _interSyndicsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF82)));
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucun Inter-Syndic trouvé"));
          }

          final users = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF4CAF82).withOpacity(0.1),
                    child: Text(
                      user.prenom[0] + user.nom[0],
                      style: const TextStyle(color: Color(0xFF4CAF82), fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    "${user.prenom} ${user.nom}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(user.email, style: TextStyle(color: Colors.grey.shade600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    TempSession.interSyndicId = user.id;
                    TempSession.interSyndicNom = "${user.prenom} ${user.nom}";
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const TranchesListScreen()),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
