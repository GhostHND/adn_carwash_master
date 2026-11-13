import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../../core/master_api_client.dart';
import '../console/master_commercial_console.dart';

class MasterApiAuditScreen extends StatefulWidget {
  final MasterApiClient apiClient;

  const MasterApiAuditScreen({super.key, required this.apiClient});

  @override
  State<MasterApiAuditScreen> createState() => _MasterApiAuditScreenState();
}

class _MasterApiAuditScreenState extends State<MasterApiAuditScreen> {
  late Future<List<Map<String, dynamic>>> _events;

  @override
  void initState() {
    super.initState();
    _events = widget.apiClient.getCollection('audit-events');
  }

  void _reload() {
    setState(() => _events = widget.apiClient.getCollection('audit-events'));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _events,
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <Map<String, dynamic>>[];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Auditoría del servidor',
                style: TextStyle(
                  color: AdnColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Eventos inmutables de operaciones autenticadas.',
                style: TextStyle(color: AdnColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (snapshot.hasError)
                MasterConsoleCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          snapshot.error.toString(),
                          style: const TextStyle(color: AdnColors.coral),
                        ),
                      ),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              else if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (events.isEmpty)
                const MasterConsoleCard(
                  child: Center(
                    child: Text(
                      'Sin eventos registrados.',
                      key: Key('audit_empty'),
                      style: TextStyle(color: AdnColors.muted),
                    ),
                  ),
                )
              else
                for (final event in events)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AuditEventCard(event: event),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _AuditEventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const _AuditEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final success = event['outcome'] == 'success';
    return MasterConsoleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: success ? AdnColors.turquoiseLight : AdnColors.coral,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${event['action']} · ${event['resource_type']}',
                  style: const TextStyle(
                    color: AdnColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${event['http_status'] ?? '—'}',
                style: const TextStyle(color: AdnColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Actor: ${event['actor_type']} ${event['actor_id'] ?? 'sistema'} · '
            'Recurso: ${event['resource_id'] ?? '—'}',
            style: const TextStyle(color: AdnColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Fecha: ${event['occurred_at']} · Referencia: ${event['request_reference'] ?? '—'}',
            style: const TextStyle(color: AdnColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
