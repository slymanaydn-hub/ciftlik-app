import 'package:flutter/material.dart';

import '../core/formatters.dart';

class PageShell extends StatelessWidget {
  const PageShell({super.key, required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              ),
              if (action != null) action!,
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class FormScreen extends StatelessWidget {
  const FormScreen({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [child],
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboard,
    this.required = false,
    this.maxLines = 1,
    this.hint,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboard;
  final bool required;
  final int maxLines;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: required ? (v) => v == null || v.trim().isEmpty ? 'Bu alan gerekli' : null : null,
      ),
    );
  }
}

class AppDropdown extends StatelessWidget {
  const AppDropdown({super.key, required this.label, required this.value, required this.items, required this.onChanged});

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class DateField extends StatelessWidget {
  const DateField({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            initialDate: DateTime.tryParse(value) ?? DateTime.now(),
          );
          if (picked != null) onChanged(picked.toIso8601String().substring(0, 10));
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(showDate(value)),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.danger = false});

  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 42) / 2;
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: danger ? Colors.red.shade700 : Colors.green.shade800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
