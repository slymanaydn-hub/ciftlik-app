import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../data/app_database.dart';
import '../ui/widgets.dart';

class PaddockPage extends StatefulWidget {
  const PaddockPage({super.key});

  @override
  State<PaddockPage> createState() => _PaddockPageState();
}

class _PaddockPageState extends State<PaddockPage> {
  late Future<List<Map<String, Object?>>> future;
  final name = TextEditingController();

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    future = AppDatabase.raw("SELECT COALESCE(NULLIF(paddock,''),'Padok belirtilmemiş') paddock, COUNT(*) c FROM animals WHERE status IN ('aktif','gebe','kuzuladı') GROUP BY COALESCE(NULLIF(paddock,''),'Padok belirtilmemiş') ORDER BY paddock");
  }

  Future<void> addPaddock() async {
    name.clear();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yeni padok / ağıl'),
        content: TextField(controller: name, decoration: const InputDecoration(labelText: 'Padok adı')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kaydet')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await AppDatabase.insert('paddocks', {'name': name.text.trim(), 'note': '', 'createdAt': DateTime.now().toIso8601String()});
      setState(refresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Padok / Ağıl',
      action: FilledButton.icon(onPressed: addPaddock, icon: const Icon(Icons.add), label: const Text('Ekle')),
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty) return const EmptyState('Padok bilgisi yok. Hayvan kartında padok alanı doldurulabilir.');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: items.map((p) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.fence),
                    title: Text(p['paddock'].toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
                    trailing: Text('${asInt(p['c'])} hayvan'),
                  ),
                )).toList(),
          );
        },
      ),
    );
  }
}
