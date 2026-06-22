import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../data/app_database.dart';
import '../ui/widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, Object?>> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<Map<String, Object?>> load() async {
    final start = monthStartIso();
    final end = monthEndIso();
    final sheep = await AppDatabase.raw("SELECT COUNT(*) c FROM animals WHERE type='koyun' AND status IN ($activeStatusesSql)");
    final rams = await AppDatabase.raw("SELECT COUNT(*) c FROM animals WHERE type='koç' AND status IN ($activeStatusesSql)");
    final lambs = await AppDatabase.raw("SELECT COUNT(*) c FROM animals WHERE type='kuzu' AND status IN ($activeStatusesSql)");
    final pregnant = await AppDatabase.raw("SELECT COUNT(*) c FROM animals WHERE status='gebe'");
    final newBirths = await AppDatabase.raw("SELECT COUNT(*) c FROM lambings WHERE birthDate >= date('now','-30 day')");
    final income = await AppDatabase.raw("SELECT COALESCE(SUM(amount),0) s FROM transactions WHERE kind='gelir' AND txDate BETWEEN ? AND ?", [start, end]);
    final expense = await AppDatabase.raw("SELECT COALESCE(SUM(amount),0) s FROM transactions WHERE kind='gider' AND txDate BETWEEN ? AND ?", [start, end]);
    final feeds = await AppDatabase.raw('SELECT name, stock, unit FROM feeds ORDER BY stock ASC LIMIT 5');
    final health = await AppDatabase.raw("SELECT earTag, recordType, nextControlDate FROM health_records WHERE nextControlDate BETWEEN date('now') AND date('now','+30 day') ORDER BY nextControlDate LIMIT 5");
    final births = await AppDatabase.raw("SELECT eweEarTag, estimatedBirthDate FROM breedings WHERE pregnancyStatus IN ('beklemede','gebe') AND estimatedBirthDate BETWEEN date('now') AND date('now','+30 day') ORDER BY estimatedBirthDate LIMIT 5");
    final payments = await AppDatabase.raw("SELECT earTag, saleDate, paymentStatus FROM sales WHERE paymentStatus != 'ödendi' ORDER BY saleDate DESC LIMIT 5");
    return {
      'sheep': sheep.first['c'],
      'rams': rams.first['c'],
      'lambs': lambs.first['c'],
      'pregnant': pregnant.first['c'],
      'newBirths': newBirths.first['c'],
      'income': income.first['s'],
      'expense': expense.first['s'],
      'feeds': feeds,
      'health': health,
      'births': births,
      'payments': payments,
    };
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Sürü Gardaş',
      child: RefreshIndicator(
        onRefresh: () async => setState(() => future = load()),
        child: FutureBuilder<Map<String, Object?>>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!;
            final income = asDouble(data['income']);
            final expense = asDouble(data['expense']);
            final feeds = data['feeds'] as List<Map<String, Object?>>;
            final health = data['health'] as List<Map<String, Object?>>;
            final births = data['births'] as List<Map<String, Object?>>;
            final payments = data['payments'] as List<Map<String, Object?>>;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    StatTile(label: 'Aktif koyun', value: '${data['sheep']}'),
                    StatTile(label: 'Koç', value: '${data['rams']}'),
                    StatTile(label: 'Kuzu', value: '${data['lambs']}'),
                    StatTile(label: 'Gebe koyun', value: '${data['pregnant']}'),
                    StatTile(label: 'Yeni kuzulayan', value: '${data['newBirths']}'),
                    StatTile(label: 'Bu ay gelir', value: money(income)),
                    StatTile(label: 'Bu ay gider', value: money(expense), danger: true),
                    StatTile(label: 'Net kâr/zarar', value: money(income - expense), danger: income < expense),
                  ],
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Yem stok durumu',
                  empty: 'Henüz yem stoğu yok.',
                  children: feeds.map((f) => ListTile(
                        leading: const Icon(Icons.grass),
                        title: Text(f['name'].toString()),
                        trailing: Text('${asDouble(f['stock']).toStringAsFixed(1)} ${f['unit']}'),
                      )).toList(),
                ),
                _Section(
                  title: 'Yaklaşan aşı ve tedaviler',
                  empty: 'Yaklaşan sağlık hatırlatması yok.',
                  children: health.map((h) => ListTile(
                        leading: const Icon(Icons.medical_services_outlined),
                        title: Text('${h['earTag']} • ${h['recordType']}'),
                        subtitle: Text('Kontrol: ${showDate(h['nextControlDate'])}'),
                      )).toList(),
                ),
                _Section(
                  title: 'Yaklaşan doğumlar',
                  empty: 'Yaklaşan doğum yok.',
                  children: births.map((b) => ListTile(
                        leading: const Icon(Icons.child_care),
                        title: Text('Koyun: ${b['eweEarTag']}'),
                        subtitle: Text('Tahmini doğum: ${showDate(b['estimatedBirthDate'])}'),
                      )).toList(),
                ),
                _Section(
                  title: 'Ödeme hatırlatmaları',
                  empty: 'Bekleyen ödeme yok.',
                  children: payments.map((p) => ListTile(
                        leading: const Icon(Icons.credit_card),
                        title: Text('Küpe ${p['earTag']} • ${p['paymentStatus']}'),
                        subtitle: Text('Satış: ${showDate(p['saleDate'])}'),
                      )).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.empty, required this.children});

  final String title;
  final String empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        children: children.isEmpty ? [Padding(padding: const EdgeInsets.all(16), child: Text(empty))] : children,
      ),
    );
  }
}
