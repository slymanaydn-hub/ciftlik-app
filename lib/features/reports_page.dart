import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../data/app_database.dart';
import '../ui/widgets.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late Future<Map<String, List<Map<String, Object?>>>> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<Map<String, List<Map<String, Object?>>>> load() async {
    return {
      'animals': await AppDatabase.query('animals', orderBy: 'earTag'),
      'lambings': await AppDatabase.query('lambings', orderBy: 'birthDate DESC'),
      'breedings': await AppDatabase.query('breedings', orderBy: 'breedingDate DESC'),
      'health': await AppDatabase.query('health_records', orderBy: 'recordDate DESC'),
      'feedUsage': await AppDatabase.raw('SELECT feedName, substr(usageDate,1,7) month, SUM(amount) total FROM feed_usages GROUP BY feedName, substr(usageDate,1,7) ORDER BY month DESC'),
      'money': await AppDatabase.raw("SELECT substr(txDate,1,7) month, SUM(CASE WHEN kind='gelir' THEN amount ELSE 0 END) income, SUM(CASE WHEN kind='gider' THEN amount ELSE 0 END) expense FROM transactions GROUP BY substr(txDate,1,7) ORDER BY month DESC"),
      'sales': await AppDatabase.query('sales', orderBy: 'saleDate DESC'),
    };
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Raporlar',
      child: FutureBuilder<Map<String, List<Map<String, Object?>>>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Report(
                title: 'Hayvan listesi raporu',
                empty: 'Hayvan kaydı yok.',
                children: data['animals']!.map((a) => ListTile(
                      title: Text('Küpe ${a['earTag']} • ${a['type']}'),
                      subtitle: Text('${a['status']} • Yaş: ${ageText(a['birthDate'])} • Padok: ${a['paddock'] ?? '-'}'),
                    )).toList(),
              ),
              _Report(
                title: 'Kuzulama raporu',
                empty: 'Kuzulama kaydı yok.',
                children: data['lambings']!.map((l) => ListTile(
                      title: Text('Anne ${l['motherEarTag']} • ${showDate(l['birthDate'])}'),
                      subtitle: Text('Doğan ${l['lambCount']} • Yaşayan ${l['aliveCount']} • Ölen ${l['deadCount']}'),
                    )).toList(),
              ),
              _Report(
                title: 'Gebelik raporu',
                empty: 'Gebelik kaydı yok.',
                children: data['breedings']!.map((b) => ListTile(
                      title: Text('${b['eweEarTag']} x ${b['ramEarTag']} • ${b['pregnancyStatus']}'),
                      subtitle: Text('Çiftleşme ${showDate(b['breedingDate'])} • Doğum ${showDate(b['estimatedBirthDate'])}'),
                    )).toList(),
              ),
              _Report(
                title: 'Aşı / sağlık raporu',
                empty: 'Sağlık kaydı yok.',
                children: data['health']!.map((h) => ListTile(
                      title: Text('${h['earTag']} • ${h['recordType']}'),
                      subtitle: Text('${showDate(h['recordDate'])} • Sonraki ${showDate(h['nextControlDate'])}'),
                      trailing: Text(money(h['cost'])),
                    )).toList(),
              ),
              _Report(
                title: 'Yem tüketim raporu',
                empty: 'Yem tüketimi yok.',
                children: data['feedUsage']!.map((f) => ListTile(
                      title: Text('${f['feedName']} • ${f['month']}'),
                      trailing: Text('${asDouble(f['total']).toStringAsFixed(1)}'),
                    )).toList(),
              ),
              _Report(
                title: 'Gelir-gider ve aylık kâr/zarar raporu',
                empty: 'Para kaydı yok.',
                children: data['money']!.map((m) {
                  final income = asDouble(m['income']);
                  final expense = asDouble(m['expense']);
                  return ListTile(
                    title: Text(m['month'].toString()),
                    subtitle: Text('Gelir ${money(income)} • Gider ${money(expense)}'),
                    trailing: Text(money(income - expense), style: const TextStyle(fontWeight: FontWeight.w900)),
                  );
                }).toList(),
              ),
              _Report(
                title: 'Satılan hayvan raporu',
                empty: 'Satış kaydı yok.',
                children: data['sales']!.map((s) => ListTile(
                      title: Text('Küpe ${s['earTag']} • ${money(s['salePrice'])}'),
                      subtitle: Text('${showDate(s['saleDate'])} • ${s['buyerName'] ?? '-'} • ${s['paymentStatus']}'),
                      trailing: Text('Kâr ${money(s['profit'])}'),
                    )).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.title, required this.empty, required this.children});

  final String title;
  final String empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: false,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        children: children.isEmpty ? [Padding(padding: const EdgeInsets.all(16), child: Text(empty))] : children,
      ),
    );
  }
}
