import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../data/app_database.dart';
import '../ui/widgets.dart';

class MoneyPage extends StatefulWidget {
  const MoneyPage({super.key});

  @override
  State<MoneyPage> createState() => _MoneyPageState();
}

class _MoneyPageState extends State<MoneyPage> {
  late Future<Map<String, Object?>> future;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() => future = load();

  Future<Map<String, Object?>> load() async {
    final start = monthStartIso();
    final end = monthEndIso();
    final txs = await AppDatabase.query('transactions', orderBy: 'txDate DESC');
    final income = await AppDatabase.raw("SELECT COALESCE(SUM(amount),0) s FROM transactions WHERE kind='gelir' AND txDate BETWEEN ? AND ?", [start, end]);
    final expense = await AppDatabase.raw("SELECT COALESCE(SUM(amount),0) s FROM transactions WHERE kind='gider' AND txDate BETWEEN ? AND ?", [start, end]);
    final active = await AppDatabase.raw("SELECT COUNT(*) c FROM animals WHERE status IN ($activeStatusesSql)");
    final totalExpense = await AppDatabase.raw("SELECT COALESCE(SUM(amount),0) s FROM transactions WHERE kind='gider'");
    final profit = await AppDatabase.raw('SELECT COALESCE(SUM(profit),0) s FROM sales');
    return {
      'txs': txs,
      'income': income.first['s'],
      'expense': expense.first['s'],
      'active': active.first['c'],
      'totalExpense': totalExpense.first['s'],
      'saleProfit': profit.first['s'],
    };
  }

  Future<void> openForm(String kind) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionForm(kind: kind)));
    setState(refresh);
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Para',
      action: Row(
        children: [
          FilledButton(onPressed: () => openForm('gelir'), child: const Text('Gelir')),
          const SizedBox(width: 8),
          FilledButton.tonal(onPressed: () => openForm('gider'), child: const Text('Gider')),
        ],
      ),
      child: FutureBuilder<Map<String, Object?>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          final txs = data['txs'] as List<Map<String, Object?>>;
          final income = asDouble(data['income']);
          final expense = asDouble(data['expense']);
          final avgCost = asInt(data['active']) == 0 ? 0 : asDouble(data['totalExpense']) / asInt(data['active']);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  StatTile(label: 'Aylık gelir', value: money(income)),
                  StatTile(label: 'Aylık gider', value: money(expense), danger: true),
                  StatTile(label: 'Net', value: money(income - expense), danger: income < expense),
                  StatTile(label: 'Hayvan başı maliyet', value: money(avgCost), danger: true),
                  StatTile(label: 'Satış kârı', value: money(data['saleProfit'])),
                ],
              ),
              const SizedBox(height: 12),
              if (txs.isEmpty) const EmptyState('Gelir gider kaydı yok.'),
              ...txs.map((t) {
                final isIncome = t['kind'] == 'gelir';
                return Card(
                  child: ListTile(
                    leading: Icon(isIncome ? Icons.trending_up : Icons.trending_down, color: isIncome ? Colors.green : Colors.red),
                    title: Text('${t['type']} • ${showDate(t['txDate'])}'),
                    subtitle: Text(t['description']?.toString() ?? ''),
                    trailing: Text(money(t['amount']), style: TextStyle(fontWeight: FontWeight.w900, color: isIncome ? Colors.green.shade800 : Colors.red.shade700)),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key, required this.kind});

  final String kind;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  final description = TextEditingController();
  String type = '';
  String date = todayIso();

  @override
  void initState() {
    super.initState();
    type = widget.kind == 'gelir' ? incomeTypes.first : expenseTypes.first;
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    await AppDatabase.insert('transactions', {
      'kind': widget.kind,
      'type': type,
      'amount': asDouble(amount.text),
      'txDate': date,
      'description': description.text.trim(),
      'animalId': null,
      'createdAt': DateTime.now().toIso8601String(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.kind == 'gelir' ? incomeTypes : expenseTypes;
    return FormScreen(
      title: widget.kind == 'gelir' ? 'Gelir Kaydı' : 'Gider Kaydı',
      child: Form(
        key: form,
        child: Column(
          children: [
            AppDropdown(label: 'Tür', value: type, items: items, onChanged: (v) => setState(() => type = v)),
            AppTextField(controller: amount, label: 'Tutar', keyboard: TextInputType.number, required: true),
            DateField(label: 'Tarih', value: date, onChanged: (v) => setState(() => date = v)),
            AppTextField(controller: description, label: 'Açıklama', maxLines: 3),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: save, child: const Text('Kaydet')),
          ],
        ),
      ),
    );
  }
}
