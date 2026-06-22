import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../data/app_database.dart';
import '../ui/widgets.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late Future<List<Map<String, Object?>>> future;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() => future = AppDatabase.query('feeds', orderBy: 'purchaseDate DESC');

  Future<void> openBuy() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedBuyForm()));
    setState(refresh);
  }

  Future<void> openUsage(Map<String, Object?> feed) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => FeedUsageForm(feed: feed)));
    setState(refresh);
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Yem',
      action: FilledButton.icon(onPressed: openBuy, icon: const Icon(Icons.add), label: const Text('Yem Al')),
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final feeds = snapshot.data!;
          if (feeds.isEmpty) return const EmptyState('Henüz yem kaydı yok.');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: feeds.map((f) => Card(
                  child: ListTile(
                    onTap: () => openUsage(f),
                    leading: const Icon(Icons.grass),
                    title: Text(f['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text('Alım: ${asDouble(f['amount']).toStringAsFixed(1)} ${f['unit']} • Tedarikçi: ${f['supplier'] ?? '-'}'),
                    trailing: Text('${asDouble(f['stock']).toStringAsFixed(1)} ${f['unit']}'),
                  ),
                )).toList(),
          );
        },
      ),
    );
  }
}

class FeedBuyForm extends StatefulWidget {
  const FeedBuyForm({super.key});

  @override
  State<FeedBuyForm> createState() => _FeedBuyFormState();
}

class _FeedBuyFormState extends State<FeedBuyForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final amount = TextEditingController();
  final unitPrice = TextEditingController();
  final supplier = TextEditingController();
  String unit = feedUnits.first;
  String date = todayIso();

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final total = asDouble(amount.text) * asDouble(unitPrice.text);
    final now = DateTime.now().toIso8601String();
    await AppDatabase.insert('feeds', {
      'name': name.text.trim(),
      'amount': asDouble(amount.text),
      'unit': unit,
      'unitPrice': asDouble(unitPrice.text),
      'total': total,
      'purchaseDate': date,
      'supplier': supplier.text.trim(),
      'stock': asDouble(amount.text),
      'createdAt': now,
    });
    await AppDatabase.insert('transactions', {
      'kind': 'gider',
      'type': 'Yem',
      'amount': total,
      'txDate': date,
      'description': 'Yem alımı: ${name.text.trim()}',
      'animalId': null,
      'createdAt': now,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FormScreen(
      title: 'Yem Alımı',
      child: Form(
        key: form,
        child: Column(
          children: [
            AppTextField(controller: name, label: 'Yem adı', required: true),
            Row(children: [
              Expanded(child: AppTextField(controller: amount, label: 'Miktar', keyboard: TextInputType.number, required: true)),
              const SizedBox(width: 10),
              Expanded(child: AppDropdown(label: 'Birim', value: unit, items: feedUnits, onChanged: (v) => setState(() => unit = v))),
            ]),
            AppTextField(controller: unitPrice, label: 'Birim fiyat', keyboard: TextInputType.number, required: true),
            DateField(label: 'Alış tarihi', value: date, onChanged: (v) => setState(() => date = v)),
            AppTextField(controller: supplier, label: 'Tedarikçi'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: save, child: const Text('Kaydet')),
          ],
        ),
      ),
    );
  }
}

class FeedUsageForm extends StatefulWidget {
  const FeedUsageForm({super.key, required this.feed});

  final Map<String, Object?> feed;

  @override
  State<FeedUsageForm> createState() => _FeedUsageFormState();
}

class _FeedUsageFormState extends State<FeedUsageForm> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  final note = TextEditingController();
  String date = todayIso();

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final used = asDouble(amount.text);
    final stock = asDouble(widget.feed['stock']) - used;
    final now = DateTime.now().toIso8601String();
    await AppDatabase.insert('feed_usages', {
      'feedId': widget.feed['id'],
      'feedName': widget.feed['name'],
      'amount': used,
      'usageDate': date,
      'note': note.text.trim(),
      'createdAt': now,
    });
    await AppDatabase.update('feeds', asInt(widget.feed['id']), {...widget.feed, 'stock': stock < 0 ? 0 : stock});
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FormScreen(
      title: 'Günlük Tüketim',
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.feed['name']} • Kalan: ${asDouble(widget.feed['stock']).toStringAsFixed(1)} ${widget.feed['unit']}', style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            AppTextField(controller: amount, label: 'Tüketilen miktar', keyboard: TextInputType.number, required: true),
            DateField(label: 'Tarih', value: date, onChanged: (v) => setState(() => date = v)),
            AppTextField(controller: note, label: 'Not', maxLines: 2),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: save, child: const Text('Kaydet')),
          ],
        ),
      ),
    );
  }
}
