import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../data/app_database.dart';
import '../ui/widgets.dart';

class BreedingPage extends StatefulWidget {
  const BreedingPage({super.key});

  @override
  State<BreedingPage> createState() => _BreedingPageState();
}

class _BreedingPageState extends State<BreedingPage> {
  late Future<List<Map<String, Object?>>> future;

  @override
  void initState() {
    super.initState();
    future = AppDatabase.query('breedings', orderBy: 'breedingDate DESC');
  }

  Future<void> openForm() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const BreedingForm()));
    setState(() => future = AppDatabase.query('breedings', orderBy: 'breedingDate DESC'));
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Çiftleşme / Gebelik',
      action: FilledButton.icon(onPressed: openForm, icon: const Icon(Icons.add), label: const Text('Ekle')),
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty) return const EmptyState('Gebelik kaydı yok.');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: items.map((b) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.favorite_outline),
                    title: Text('Koyun ${b['eweEarTag']} • Koç ${b['ramEarTag']}'),
                    subtitle: Text('Çiftleşme: ${showDate(b['breedingDate'])} • Tahmini doğum: ${showDate(b['estimatedBirthDate'])}'),
                    trailing: Text(b['pregnancyStatus'].toString()),
                  ),
                )).toList(),
          );
        },
      ),
    );
  }
}

class BreedingForm extends StatefulWidget {
  const BreedingForm({super.key});

  @override
  State<BreedingForm> createState() => _BreedingFormState();
}

class _BreedingFormState extends State<BreedingForm> {
  final note = TextEditingController();
  List<Map<String, Object?>> ewes = [];
  List<Map<String, Object?>> rams = [];
  Map<String, Object?>? ewe;
  Map<String, Object?>? ram;
  String breedingDate = todayIso();
  String controlDate = todayIso();
  String status = breedingStatuses.first;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    ewes = await AppDatabase.raw("SELECT * FROM animals WHERE gender='dişi' AND status IN ($activeStatusesSql) ORDER BY earTag");
    rams = await AppDatabase.raw("SELECT * FROM animals WHERE gender='erkek' AND status IN ($activeStatusesSql) ORDER BY earTag");
    ewe = ewes.isNotEmpty ? ewes.first : null;
    ram = rams.isNotEmpty ? rams.first : null;
    setState(() {});
  }

  Future<void> save() async {
    if (ewe == null || ram == null) {
      snack(context, 'Koyun ve koç kaydı gerekli.');
      return;
    }
    final date = DateTime.parse(breedingDate);
    final est = estimatedBirth(date).toIso8601String().substring(0, 10);
    final now = DateTime.now().toIso8601String();
    await AppDatabase.insert('breedings', {
      'eweId': ewe!['id'],
      'eweEarTag': ewe!['earTag'],
      'ramId': ram!['id'],
      'ramEarTag': ram!['earTag'],
      'breedingDate': breedingDate,
      'estimatedBirthDate': est,
      'pregnancyStatus': status,
      'controlDate': controlDate,
      'reminderDate': controlDate,
      'note': note.text.trim(),
      'createdAt': now,
    });
    if (status == 'gebe') {
      await AppDatabase.update('animals', asInt(ewe!['id']), {...ewe!, 'status': 'gebe', 'updatedAt': now});
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final est = estimatedBirth(DateTime.tryParse(breedingDate) ?? DateTime.now()).toIso8601String().substring(0, 10);
    return FormScreen(
      title: 'Çiftleşme Kaydı',
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            value: ewe == null ? null : asInt(ewe!['id']),
            decoration: const InputDecoration(labelText: 'Koyun seç'),
            items: ewes.map((a) => DropdownMenuItem(value: asInt(a['id']), child: Text('Küpe ${a['earTag']}'))).toList(),
            onChanged: (id) => setState(() => ewe = ewes.firstWhere((a) => asInt(a['id']) == id)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: ram == null ? null : asInt(ram!['id']),
            decoration: const InputDecoration(labelText: 'Koç seç'),
            items: rams.map((a) => DropdownMenuItem(value: asInt(a['id']), child: Text('Küpe ${a['earTag']}'))).toList(),
            onChanged: (id) => setState(() => ram = rams.firstWhere((a) => asInt(a['id']) == id)),
          ),
          const SizedBox(height: 10),
          DateField(label: 'Çiftleşme tarihi', value: breedingDate, onChanged: (v) => setState(() => breedingDate = v)),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('Tahmini doğum tarihi'), trailing: Text(showDate(est))),
          AppDropdown(label: 'Gebelik durumu', value: status, items: breedingStatuses, onChanged: (v) => setState(() => status = v)),
          DateField(label: 'Ultrason / kontrol tarihi', value: controlDate, onChanged: (v) => setState(() => controlDate = v)),
          AppTextField(controller: note, label: 'Not', maxLines: 3),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: save, child: const Text('Kaydet')),
        ],
      ),
    );
  }
}
