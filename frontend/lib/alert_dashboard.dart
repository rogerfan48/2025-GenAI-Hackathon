import 'dart:async';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'models/ModelProvider.dart';

class AlertDashboard extends StatefulWidget {
  const AlertDashboard({super.key});
  @override
  State<AlertDashboard> createState() => _AlertDashboardState();
}

class _AlertDashboardState extends State<AlertDashboard> {
  StreamSubscription<GraphQLResponse<Alert>>? _sub;
  Alert? _latest;
  List<Alert> _history = [];

  @override
  void initState() {
    super.initState();
    _subscribeLatest();
    _loadHistory();
  }

  void _subscribeLatest() {
    _sub = Amplify.API
        .subscribe(
          onCreateAlertSubscription(),
          onEstablished: () => safePrint('🔗 subscription ready'),
        )
        .listen((event) {
          setState(() => _latest = event.data);
        });
  }

  GraphQLRequest<Alert> onCreateAlertSubscription() {
    return ModelSubscription.onCreate(Alert.classType);
  }

  Future<void> _loadHistory() async {
    final resp = await Amplify.API
        .query(request: ModelQueries.list(
          Alert.classType,
          where: Alert.RESOLVED.eq(true),
        ))
        .response;
    setState(() => _history = resp.data?.items ?? []);
  }

  Future<void> _markResolved() async {
    if (_latest == null) return;
    final updated = _latest!.copyWith(resolved: true);
    await Amplify.API.mutate(request: ModelMutations.update(updated)).response;
    setState(() {
      _history.insert(0, updated);
      _latest = null;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crowd‑Alert Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_latest != null) _buildLatestCard(),
            const SizedBox(height: 16),
            const Text('歷史警示', style: TextStyle(fontSize: 18)),
            Expanded(child: _buildHistoryList()),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestCard() {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_latest!.imgUrl != null)
            Image.network(_latest!.imgUrl!, height: 220, fit: BoxFit.cover),
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.redAccent),
            title: Text(_latest!.msg),
            subtitle: Text(
              DateTime.parse(_latest!.ts).toLocal().toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('已處理'),
                onPressed: _markResolved,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return const Center(child: Text('（尚無資料）'));
    }
    return ListView.separated(
      itemCount: _history.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, idx) {
        final a = _history[idx];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(a.msg),
          subtitle:
              Text(DateTime.parse(a.ts).toLocal().toString()),
        );
      },
    );
  }
}
