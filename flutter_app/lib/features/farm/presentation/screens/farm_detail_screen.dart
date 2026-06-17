import 'package:flutter/material.dart';

/// Farm detail screen — shows full farm info, lifecycle timeline, soil health.
class FarmDetailScreen extends StatelessWidget {
  final String farmId;
  const FarmDetailScreen({super.key, required this.farmId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Farm Details')),
      body: Center(
        child: Text('Farm Detail — $farmId\nTODO: Implement full farm view'),
      ),
    );
  }
}
