import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const StatCard({super.key, required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), letterSpacing: 0.8)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'IBM Plex Mono')),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4))),
      ]),
    ));
  }
}
