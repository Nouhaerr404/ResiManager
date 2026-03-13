import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/user_service.dart';
import '../../../widgets/syndic_sidebar.dart';

class InterSyndicsScreen extends StatefulWidget {
  const InterSyndicsScreen({Key? key}) : super(key: key);

  @override
  _InterSyndicsScreenState createState() => _InterSyndicsScreenState();
}

class _InterSyndicsScreenState extends State<InterSyndicsScreen> {
  final UserService _userService = UserService();
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = _userService.getUsersByRole(RoleEnum.inter_syndic);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      drawer: MediaQuery.of(context).size.width < 900 ? const SyndicSidebar() : null,
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 900)
            const SizedBox(width: 250, child: SyndicSidebar()),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gestion des Inter-Syndics', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                      ElevatedButton.icon(
                        onPressed: () => _showUserDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6F4A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: FutureBuilder<List<UserModel>>(
                      future: _usersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Erreur : ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('Aucun Inter-Syndic trouvé'));
                        }

                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final user = snapshot.data![index];
                            return _buildUserCard(user);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2C2C2C),
          child: Text(user.prenom[0] + user.nom[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text('${user.prenom} ${user.nom}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(user.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showUserDialog(user: user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(user),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDialog({UserModel? user}) {
    final nomController = TextEditingController(text: user?.nom);
    final prenomController = TextEditingController(text: user?.prenom);
    final emailController = TextEditingController(text: user?.email);
    final telephoneController = TextEditingController(text: user?.telephone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user == null ? 'Ajouter un Inter-Syndic' : 'Modifier l\'Inter-Syndic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: prenomController, decoration: const InputDecoration(labelText: 'Prénom')),
            TextField(controller: nomController, decoration: const InputDecoration(labelText: 'Nom')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: telephoneController, decoration: const InputDecoration(labelText: 'Téléphone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (user == null) {
                await _userService.createUser(
                  nomController.text,
                  prenomController.text,
                  emailController.text,
                  telephoneController.text,
                  RoleEnum.inter_syndic,
                );

              } else {
                await _userService.updateUser(
                  user.id,
                  nomController.text,
                  prenomController.text,
                  emailController.text,
                  telephoneController.text,
                  user.statut,
                );
              }
              Navigator.pop(context);
              _loadUsers();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${user.prenom} ${user.nom} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await _userService.deleteUser(user.id);
              Navigator.pop(context);
              _loadUsers();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
