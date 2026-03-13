// lib/screens/inter_syndic/finance/manage_categories_screen.dart
import 'package:flutter/material.dart';
import '../../../services/finance_service.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final FinanceService _service = FinanceService();
  late Future<List<Map<String, dynamic>>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _categoriesFuture = _service.getCategories('individuelle');
    });
  }

  void _showCategoryDialog([Map<String, dynamic>? category]) {
    final TextEditingController nameController = TextEditingController(text: category?['nom']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? "Nouvelle Catégorie" : "Modifier la Catégorie"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Nom de la catégorie"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                if (category == null) {
                  await _service.addCategory(nom: nameController.text.trim(), type: 'individuelle');
                } else {
                  await _service.updateCategory(id: category['id'], nom: nameController.text.trim());
                }
                if (!context.mounted) return;
                Navigator.pop(context);
                _refresh();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer"),
        content: const Text("Voulez-vous vraiment supprimer cette catégorie ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              try {
                await _service.deleteCategory(id);
                if (!context.mounted) return;
                Navigator.pop(context);
                _refresh();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
              }
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F6),
      appBar: AppBar(
        title: const Text("Gérer les Catégories Individualisées", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFFFF6F4A)),
            onPressed: () => _showCategoryDialog(),
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final categories = snapshot.data!;
          if (categories.isEmpty) return const Center(child: Text("Aucune catégorie individuelle"));

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
                ),
                child: ListTile(
                  title: Text(cat['nom'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _showCategoryDialog(cat)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _confirmDelete(cat['id'])),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
