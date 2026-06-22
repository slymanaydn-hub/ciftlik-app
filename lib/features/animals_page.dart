import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../data/app_database.dart';
import '../ui/widgets.dart';
import 'breeding_page.dart';
import 'health_page.dart';
import 'paddock_page.dart';
import 'sale_form.dart';

class AnimalsPage extends StatefulWidget {
  const AnimalsPage({super.key});

  @override
  State<AnimalsPage> createState() => _AnimalsPageState();
}

class _AnimalsPageState extends State<AnimalsPage> {
  final search = TextEditingController();
  bool showArchive = false;
  late Future<List<Map<String, Object?>>> future;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    final term = search.text.trim();
    final archiveSql = showArchive ? '' : "AND status IN ($activeStatusesSql)";
    future = AppDatabase.raw(
      "SELECT * FROM animals WHERE earTag LIKE ? $archiveSql ORDER BY status, earTag",
      ['%$term%'],
    );
  }

  Future<void> openForm([Map<String, Object?>? animal]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AnimalForm(animal: animal)));
    setState(refresh);
  }

  Future<void> openPage(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    setState(refresh);
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Hayvanlar',
      action: FilledButton.icon(onPressed: () => openForm(), icon: const Icon(Icons.add), label: const Text('Ekle')),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              children: [
                TextField(
                  controller: search,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Küpe numarasına göre hızlı arama'),
                  onChanged: (_) => setState(refresh),
                ),
                SwitchListTile(
                  value: showArchive,
                  title: const Text('Satılan, ölen ve kesilen hayvanları da göster'),
                  onChanged: (v) => setState(() {
                    showArchive = v;
                    refresh();
                  }),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(onPressed: () => openPage(const BreedingPage()), child: const Text('Çiftleşme / Gebelik')),
                    FilledButton.tonal(onPressed: () => openPage(const HealthPage()), child: const Text('Sağlık / Aşı')),
                    FilledButton.tonal(onPressed: () => openPage(const PaddockPage()), child: const Text('Padok / Ağıl')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, Object?>>>(
              future: future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final animals = snapshot.data!;
                if (animals.isEmpty) return const EmptyState('Hayvan kaydı bulunamadı.');
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: animals.length,
                  itemBuilder: (context, index) {
                    final a = animals[index];
                    return Card(
                      child: ListTile(
                        onTap: () => openForm(a),
                        leading: CircleAvatar(child: Text(a['type'].toString().substring(0, 1).toUpperCase())),
                        title: Text('Küpe ${a['earTag']}', style: const TextStyle(fontWeight: FontWeight.w900)),
                        subtitle: Text('${a['type']} • ${a['gender']} • ${a['status']} • Yaş: ${ageText(a['birthDate'])}\nPadok: ${a['paddock'] ?? '-'}'),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') openForm(a);
                            if (value == 'sell') openPage(SaleForm(animal: a));
                            if (value == 'health') openPage(HealthForm(animal: a));
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                            PopupMenuItem(value: 'health', child: Text('Sağlık kaydı')),
                            PopupMenuItem(value: 'sell', child: Text('Satış yap')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AnimalForm extends StatefulWidget {
  const AnimalForm({super.key, this.animal});

  final Map<String, Object?>? animal;

  @override
  State<AnimalForm> createState() => _AnimalFormState();
}

class _AnimalFormState extends State<AnimalForm> {
  final form = GlobalKey<FormState>();
  final earTag = TextEditingController();
  final breed = TextEditingController();
  final mother = TextEditingController();
  final father = TextEditingController();
  final price = TextEditingController();
  final purchasedFrom = TextEditingController();
  final paddock = TextEditingController();
  final note = TextEditingController();
  String type = animalTypes.first;
  String gender = genders.first;
  String status = 'aktif';
  String birthDate = todayIso();
  String purchaseDate = todayIso();
  String photoPath = '';

  bool get editing => widget.animal != null;

  @override
  void initState() {
    super.initState();
    final a = widget.animal;
    if (a == null) return;
    earTag.text = a['earTag']?.toString() ?? '';
    type = a['type']?.toString() ?? animalTypes.first;
    gender = a['gender']?.toString() ?? genders.first;
    breed.text = a['breed']?.toString() ?? '';
    birthDate = a['birthDate']?.toString() ?? todayIso();
    mother.text = a['motherEarTag']?.toString() ?? '';
    father.text = a['fatherEarTag']?.toString() ?? '';
    purchaseDate = a['purchaseDate']?.toString() ?? todayIso();
    price.text = asDouble(a['purchasePrice']).toString();
    purchasedFrom.text = a['purchasedFrom']?.toString() ?? '';
    status = a['status']?.toString() ?? 'aktif';
    paddock.text = a['paddock']?.toString() ?? '';
    note.text = a['note']?.toString() ?? '';
    photoPath = a['photoPath']?.toString() ?? '';
  }

  Future<void> pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) setState(() => photoPath = picked.path);
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final now = DateTime.now().toIso8601String();
    final data = {
      'earTag': earTag.text.trim(),
      'type': type,
      'gender': gender,
      'breed': breed.text.trim(),
      'birthDate': birthDate,
      'motherEarTag': mother.text.trim(),
      'fatherEarTag': father.text.trim(),
      'purchaseDate': purchaseDate,
      'purchasePrice': asDouble(price.text),
      'purchasedFrom': purchasedFrom.text.trim(),
      'status': status,
      'paddock': paddock.text.trim(),
      'note': note.text.trim(),
      'photoPath': photoPath,
      'createdAt': widget.animal?['createdAt'] ?? now,
      'updatedAt': now,
    };
    if (editing) {
      await AppDatabase.update('animals', asInt(widget.animal!['id']), data);
    } else {
      await AppDatabase.insert('animals', data);
      await AppDatabase.insert('purchases', {
        'animalCount': 1,
        'earTag': earTag.text.trim(),
        'purchasePrice': asDouble(price.text),
        'sellerName': purchasedFrom.text.trim(),
        'purchaseDate': purchaseDate,
        'note': note.text.trim(),
        'createdAt': now,
      });
      if (asDouble(price.text) > 0) {
        await AppDatabase.insert('transactions', {
          'kind': 'gider',
          'type': 'Diğer',
          'amount': asDouble(price.text),
          'txDate': purchaseDate,
          'description': 'Hayvan alımı: ${earTag.text.trim()}',
          'animalId': null,
          'createdAt': now,
        });
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FormScreen(
      title: editing ? 'Hayvan Kartı' : 'Yeni Hayvan',
      child: Form(
        key: form,
        child: Column(
          children: [
            AppTextField(controller: earTag, label: 'Küpe numarası', required: true),
            Row(children: [
              Expanded(child: AppDropdown(label: 'Hayvan türü', value: type, items: animalTypes, onChanged: (v) => setState(() => type = v))),
              const SizedBox(width: 10),
              Expanded(child: AppDropdown(label: 'Cinsiyet', value: gender, items: genders, onChanged: (v) => setState(() => gender = v))),
            ]),
            AppTextField(controller: breed, label: 'Irk'),
            Row(children: [
              Expanded(child: DateField(label: 'Doğum tarihi', value: birthDate, onChanged: (v) => setState(() => birthDate = v))),
              const SizedBox(width: 10),
              Expanded(child: DateField(label: 'Alış tarihi', value: purchaseDate, onChanged: (v) => setState(() => purchaseDate = v))),
            ]),
            AppTextField(controller: mother, label: 'Anne küpe no'),
            AppTextField(controller: father, label: 'Baba / koç küpe no'),
            AppTextField(controller: price, label: 'Alış fiyatı', keyboard: TextInputType.number),
            AppTextField(controller: purchasedFrom, label: 'Nereden alındı / satıcı'),
            AppDropdown(label: 'Durum', value: status, items: animalStatuses, onChanged: (v) => setState(() => status = v)),
            AppTextField(controller: paddock, label: 'Bulunduğu padok / ağıl'),
            AppTextField(controller: note, label: 'Notlar', maxLines: 3),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(photoPath.isEmpty ? 'Fotoğraf ekleme alanı' : 'Fotoğraf seçildi'),
              subtitle: photoPath.isEmpty ? null : Text(photoPath, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: FilledButton.tonal(onPressed: pickPhoto, child: const Text('Seç')),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: save, child: const Text('Kaydet')),
          ],
        ),
      ),
    );
  }
}
