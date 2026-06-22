import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../data/app_database.dart';
import '../ui/widgets.dart';

class SaleForm extends StatefulWidget {
  const SaleForm({super.key, required this.animal});

  final Map<String, Object?> animal;

  @override
  State<SaleForm> createState() => _SaleFormState();
}

class _SaleFormState extends State<SaleForm> {
  final form = GlobalKey<FormState>();
  final price = TextEditingController();
  final buyer = TextEditingController();
  String saleDate = todayIso();
  String payment = paymentStatuses.first;

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final salePrice = asDouble(price.text);
    final profit = salePrice - asDouble(widget.animal['purchasePrice']);
    final now = DateTime.now().toIso8601String();
    await AppDatabase.insert('sales', {
      'animalId': widget.animal['id'],
      'earTag': widget.animal['earTag'],
      'salePrice': salePrice,
      'buyerName': buyer.text.trim(),
      'saleDate': saleDate,
      'paymentStatus': payment,
      'profit': profit,
      'createdAt': now,
    });
    await AppDatabase.update('animals', asInt(widget.animal['id']), {...widget.animal, 'status': 'satıldı', 'updatedAt': now});
    final type = switch (widget.animal['type']?.toString()) {
      'kuzu' => 'Kuzu satışı',
      'koç' => 'Koç satışı',
      _ => 'Koyun satışı',
    };
    await AppDatabase.insert('transactions', {
      'kind': 'gelir',
      'type': type,
      'amount': salePrice,
      'txDate': saleDate,
      'description': 'Hayvan satışı: ${widget.animal['earTag']} - ${buyer.text.trim()}',
      'animalId': widget.animal['id'],
      'createdAt': now,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FormScreen(
      title: 'Satış Kaydı',
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Satılan hayvan: Küpe ${widget.animal['earTag']}', style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            AppTextField(controller: price, label: 'Satış fiyatı', keyboard: TextInputType.number, required: true),
            AppTextField(controller: buyer, label: 'Alıcı adı'),
            DateField(label: 'Satış tarihi', value: saleDate, onChanged: (v) => setState(() => saleDate = v)),
            AppDropdown(label: 'Ödeme durumu', value: payment, items: paymentStatuses, onChanged: (v) => setState(() => payment = v)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: save, child: const Text('Satışı Kaydet')),
          ],
        ),
      ),
    );
  }
}
