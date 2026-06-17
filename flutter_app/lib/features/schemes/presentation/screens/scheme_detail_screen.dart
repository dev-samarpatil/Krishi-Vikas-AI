import 'package:flutter/material.dart';

/// Government Scheme detail screen — benefits, eligibility, apply steps.
class SchemeDetailScreen extends StatelessWidget {
  final String schemeId;
  const SchemeDetailScreen({super.key, required this.schemeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scheme Details')),
      body: Center(
        child: Text('Scheme Detail — $schemeId\nTODO: Benefit, eligibility, apply button, helpline'),
      ),
    );
  }
}
