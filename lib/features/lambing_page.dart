import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../data/app_database.dart';
import '../ui/widgets.dart';

class LambingPage extends StatefulWidget {
  const LambingPage({super.key});

  @override
  State<LambingPage> createState() => _LambingPageState();
}

class _LambingPageState extends State<LambingPage> {
  late Future<List<Map<String, Object?>>> future;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() => future = AppDatabase.query('lambings', orderBy: 'birthDate DESC');

  Future<void> openForm() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const LambingForm()));
    setState(refresh);
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Kuzulama',
      action: FilledButton.icon(onPressed: openForm, icon: const Icon(Icons.add), label: const Text('Ekle')),
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty) return const EmptyState('Henüz kuzulama kaydı yok.');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: items.map((l) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.child_care),
                    title: Text('Anne ${l['motherEarTag']} • ${showDate(l['birthDate'])}'),
                    subtitle: Text('Doğan: ${l['lambCount']} • Yaşayan: ${l['aliveCount']} • Ölen: ${l['deadCount']}\n${l['gendersText'] ?? ''}'),
                    isThreeLine: true,
                  ),
                )).toList(),
          );
        },
      ),
    );
  }
}

class LambingForm extends StatefulWidget {
  const LambingForm({super.key});

  @override
  State<LambingForm> createState() => _LambingFormState();
}

class _LambingFormState extends State<LambingForm> {
  final form = GlobalKey<FormState>();
  final lambCount = TextEditingController(text: '1');
  final aliveCount = TextEditingController(text: '1');
  final deadCount = TextEditingController(text: '0');
  final gendersText = TextEditingController(text: 'dişi');
  final note = TextEditingController();
  List<Map<String, Object?>> mothers = [];
  Map<String, Object?>? mother;
  String birthDate = todayIso();
  bool autoAdd = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    mothers = await AppDatabase.raw("SELECT * FROM animals WHERE gender='dişi' AND status IN ($activeStatusesSql) ORDER BY earTag");
    mother = mothers.isNotEmpty ? mothers.first : null;
    setState(() {});
  }

  Future<void> save() async {
    if (mother == null) {
      snack(context, 'Önce doğum yapan koyun kaydı ekleyin.');
      return;
    }
    if (!form.currentState!.validate()) return;
    final now = DateTime.now().toIso8601String();
    final motherTag = mother!['earTag'].toString();
    final id = await AppDatabase.insert('lambings', {
      'motherId': mother!['id'],
      'motherEarTag': motherTag,
      'birthDate': birthDate,
      'lambCount': asInt(lambCount.text),
      'aliveCount': asInt(aliveCount.text),
      'deadCount': asInt(deadCount.text),
      'gendersText': gendersText.text.trim(),
      'birthNote': note.text.trim(),
      'createdAt': now,
    });
    await AppDatabase.update('animals', asInt(mother!['id']), {...mother!, 'status': 'kuzuladı', 'updatedAt': now});
    if (autoAdd) {
      final genderList = gendersText.text.split(',').map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();
      for (var i = 0; i < asInt(aliveCount.text); i++) {
        final gender = i < genderList.length && genderList[i].startsWith('e') ? 'erkek' : 'dişi';
        await AppDatabase.insert('animals', {
          'earTag': '$motherTag-K$id-${i + 1}',
          'type': 'kuzu',
          'gender': gender,
          'breed': mother!['breed'] ?? '',
          'birthDate': birthDate,
          'motherEarTag': motherTag,
          'fatherEarTag': mother!['fatherEarTag'] ?? '',
          'purchaseDate': birthDate,
          'purchasePrice': 0,
          'purchasedFrom': 'Doğum',
          'status': 'aktif',
          'paddock': mother!['paddock'] ?? '',
          'note': 'Kuzulama kaydından otomatik eklendi.',
          'photoPath': '',
          'createdAt': now,
          'updatedAt': now,
        });
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FormScreen(
      title: 'Kuzulama Kaydı',
      child: Form(
        key: form,
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: mother == null ? null : asInt(mother!['id']),
              decoration: const InputDecoration(labelText: 'Kuzulayan koyun'),
              items: mothers.map((m) => DropdownMenuItem(value: asInt(m['id']), child: Text('Küpe ${m['earTag']}'))).toList(),
              onChanged: (id) => setState(() => mother = mothers.firstWhere((m) => asInt(m['id']) == id)),
            ),
            const SizedBox(height: 10),
            DateField(label: 'Doğum tarihi', value: birthDate, onChanged: (v) => setState(() => birthDate = v)),
            Row(children: [
              Expanded(child: AppTextField(controller: lambCount, label: 'Doğan kuzu', keyboard: TextInputType.number, required: true)),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(controller: aliveCount, label: 'Yaşayan', keyboard: TextInputType.number, required: true)),
            ]),
            AppTextField(controller: deadCount, label: 'Ölen kuzu', keyboard: TextInputType.number),
            AppTextField(controller: gendersText, label: 'Kuzu cinsiyetleri', hint: 'dişi, erkek'),
            SwitchListTile(
              value: autoAdd,
              title: const Text('Kuzuları otomatik hayvan listesine ekle'),
              onChanged: (v) => setState(() => autoAdd = v),
            ),
            AppTextField(controller: note, label: 'Doğum notu', maxLines: 3),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: save, child: const Text('Kaydet')),
          ],
        ),
      ),
    );
  }
}
