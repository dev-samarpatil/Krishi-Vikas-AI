import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Box _alertsBox;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initBox();
  }

  void _initBox() async {
    _alertsBox = await Hive.openBox('push_alerts');
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshAlerts() async {
    setState(() {});
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'disease':
        return Icons.bug_report;
      case 'climate':
        return Icons.thunderstorm;
      case 'mandi':
        return Icons.trending_up;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'disease':
        return Colors.orange;
      case 'climate':
        return Colors.blue;
      case 'mandi':
        return AppTheme.primaryGreen;
      default:
        return AppTheme.textHint;
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp);
      return DateFormat.yMMMd().add_jm().format(dt);
    } catch (_) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.notifications),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final alerts = _alertsBox.values.toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        centerTitle: true,
        actions: [
          if (alerts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                await _alertsBox.clear();
                setState(() {});
              },
            )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAlerts,
        child: alerts.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_none, size: 64, color: AppTheme.textHint),
                          const SizedBox(height: AppTheme.spacingMd),
                          Text(
                            l10n.noAlerts,
                            style: const TextStyle(fontSize: 16, color: AppTheme.textHint),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = Map<String, dynamic>.from(alerts[index] as Map);
                  final type = alert['type']?.toString() ?? 'general';
                  final route = alert['route']?.toString() ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColorForType(type).withOpacity(0.1),
                        child: Icon(_getIconForType(type), color: _getColorForType(type)),
                      ),
                      title: Text(
                        alert['title']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(alert['body']?.toString() ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(alert['timestamp']?.toString()),
                            style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
                          ),
                        ],
                      ),
                      onTap: route.isNotEmpty
                          ? () {
                              context.go(route);
                            }
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
