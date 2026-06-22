import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../data/app_database.dart';
import '../ui/widgets.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  late Future<List<Map<String, Object?>>> future;

  @override
  void initState() {
    super.initState();
    future = AppDatabase.query('health_records', orderBy: 'recordDate DESC');
  }

  Future<void> openForm() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthForm()));
    setState(() => future = AppDatabase.query('health_records', orderBy: 'recordDate DESC'));
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Sağlık / Aşı',
      action: FilledButton.icon(onPressed: openForm, icon: const Icon(Icons.add), label: const Text('Ekle')),
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty) return const EmptyState('Sağlık kaydı yok.');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: items.map((h) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.medical_services_outlined),
                    title: Text('${h['earTag']} • ${h['recordType']}'),
                    subtitle: Text('${showDate(h['recordDate'])} • Vet: ${h['vetName'] ?? '-'} • Sonraki: ${showDate(h['nextControlDate'])}'),
                    trailing: Text(money(h['cost'])),
                  ),
                )).toList(),
          );
        },
      ),
    );
  }
}

class HealthForm extends StatefulWidget {
  const HealthForm({super.key, this.animal});

  final Map<String, Object?>? animal;

  @override
  State<HealthForm> createState() => _HealthFormState();
}

class _HealthFormState extends State<HealthForm> {
  final form = GlobalKey<FormState>();
  final vet = TextEditingController();
  final cost = TextEditingController();
  final note = TextEditingController();
  List<Map<String, Object?>> animals = [];
  Map<String, Object?>? animal;
  String type = healthTypes.first;
  String recordDate = todayIso();
  String nextControl = todayIso();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    animals = await AppDatabase.raw("SELECT * FROM animals WHERE status IN ($activeStatusesSql) ORDER BY earTag");
    animal = widget.animal ?? (animals.isNotEmpty ? animals.first : null);
    setState(() {});
  }

  Future<void> save() async {
    if (animal == null) {
      snack(context, 'Önce hayvan kaydı ekleyin.');
      return;
    }
    if (!form.currentState!.validate()) return;
    final now = DateTime.now().toIso8601String();
    await AppDatabase.insert('health_records', {
      'animalId': animal!['id'],
      'earTag': animal!['earTag'],
      'recordType': type,
      'recordDate': recordDate,
      'vetName': vet.text.trim(),
      'cost': asDouble(cost.text),
      'nextControlDate': nextControl,
      'note': note.text.trim(),
      'createdAt': now,
    });
    if (asDouble(cost.text) > 0) {
      await AppDatabase.insert('transactions', {
        'kind': 'gider',
        'type': type == 'aşı' ? 'Aşı' : type == 'ilaç' ? 'İlaç' : 'Veteriner',
        'amount': asDouble(cost.text),
        'txDate': recordDate,
        'description': 'Sağlık kaydı: ${animal!['earTag']} - $type',
        'animalId': animal!['id'],
        'createdAt': now,
      });
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FormScreen(
      title: 'Sağlık Kaydı',
      child: Form(
        key: form,
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: animal == null ? null : asInt(animal!['id']),
              decoration: const InputDecoration(labelText: 'Hayvan seç'),
              items: animals.map((a) => DropdownMenuItem(value: asInt(a['id']), child: Text('Küpe ${a['earTag']}'))).toList(),
              onChanged: (id) => setState(() => animal = animals.firstWhere((a) => asInt(a['id']) == id)),
            ),
            const SizedBox(height: 10),
            AppDropdown(label: 'Kayıt türü', value: type, items: healthTypes, onChanged: (v) => setState(() => type = v)),
            DateField(label: 'Kayıt tarihi', value: recordDate, onChanged: (v) => setState(() => recordDate = v)),
            AppTextField(controller: vet, label: 'Veteriner adı'),
            AppTextField(controller: cost, label: 'Masraf tutarı', keyboard: TextInputType.number),
            DateField(label: 'Sonraki kontrol tarihi', value: nextControl, onChanged: (v) => setState(() => nextControl = v)),
            AppTextField(controller: note, label: 'Açıklama', maxLines: 3),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: save, child: const Text('Kaydet')),
          ],
        ),
      ),
    );
  }
}
