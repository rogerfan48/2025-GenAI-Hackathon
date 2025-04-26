import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'amplify_config.dart';
import 'alert.dart';

// ---------- GraphQL documents ----------
const subDoc = '''
subscription OnCreateAlert {
  onCreateAlert { id ts msg level location imgUrl resolved }
}''';

const listDoc = '''
query List {
  listAlerts { id ts msg level location imgUrl resolved }
}''';

const updateDoc = '''
mutation Update(\$id:ID!, \$r:Boolean!) {
  updateAlert(id:\$id, resolved:\$r) { id resolved }
}''';
// ---------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureAmplify();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(fontSize: 14, height: 1.4),
      ),
    );

    return MaterialApp(
      title: 'ViRAW 即時示警監控平台',
      theme: base,
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  StreamSubscription<GraphQLResponse<String>>? _sub;
  List<Alert> _unresolved = [];
  List<Alert> _resolved = [];

  @override
  void initState() {
    super.initState();
    _subscribeLive();
    _loadHistory();
  }

  void _subscribeLive() {
    _sub = Amplify.API
        .subscribe<String>(
      GraphQLRequest(document: subDoc),
      onEstablished: () => debugPrint('🔗 subscription ready'),
    )
        .listen((ev) async {
      if (ev.data == null) return;
      final root = jsonDecode(ev.data!) as Map<String, dynamic>;
      if (root['onCreateAlert'] == null) return;
      await _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    final resp = await Amplify.API
        .query<String>(request: GraphQLRequest(document: listDoc))
        .response;
    final items = (jsonDecode(resp.data!)['listAlerts'] as List)
        .cast<Map<String, dynamic>>();

    final Map<String, Alert> map = {};
    for (var item in items) {
      final a = Alert.fromJson(item);
      map[a.id] = a;
    }
    final alerts = map.values.toList();
    final unresolved = alerts.where((a) => !a.resolved).toList();
    final resolved = alerts.where((a) => a.resolved).toList();
    unresolved.sort((a, b) => b.ts.compareTo(a.ts));
    resolved.sort((a, b) => b.ts.compareTo(a.ts));

    setState(() {
      _unresolved = unresolved;
      _resolved = resolved;
    });
  }

  Future<void> _markResolved(Alert a) async {
    await Amplify.API
        .mutate<String>(
            request: GraphQLRequest(
                document: updateDoc, variables: {'id': a.id, 'r': true}))
        .response;
    await _loadHistory();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ViRAW 即時示警監控平台',
            style: Theme.of(context).textTheme.headlineSmall),
        centerTitle: true,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(child: _unresolvedPanel()),
            const VerticalDivider(width: 32),
            Expanded(child: _historyPanel()),
          ],
        ),
      ),
    );
  }

  Widget _unresolvedPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('最新警示', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _unresolved.length,
            itemBuilder: (context, i) => _buildUnresolvedCard(_unresolved[i]),
          ),
        ),
      ],
    );
  }

  Widget _historyPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('歷史警示', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            separatorBuilder: (_, __) => const Divider(),
            itemCount: _resolved.length,
            itemBuilder: (context, i) => _buildResolvedCard(_resolved[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildUnresolvedCard(Alert a) => Card(
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Image.network(
                a.imgUrl ?? '',
                width: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                    width: 200,
                    child: Center(child: Icon(Icons.image_not_supported))),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.msg,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('危險等級 ${a.level} • 發生位置 ${a.location}'),
                      const SizedBox(height: 4),
                      Text(
                          DateTime.parse(a.ts)
                              .toLocal()
                              .toString()
                              .split('.')
                              .first,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _markResolved(a),
                          icon: const Icon(Icons.check),
                          label: const Text('已處理'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildResolvedCard(Alert a) => Row(
        children: [
          Image.network(
            a.imgUrl ?? '',
            width: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(
              width: 100,
              child: Center(child: Icon(Icons.image_not_supported)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateTime.parse(a.ts).toLocal().toString().split('.').first,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('危險等級 ${a.level} • 發生位置 ${a.location}'),
                  const SizedBox(height: 4),
                  Text(
                    a.msg,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  // 如果你未來想加按鈕，也能同樣放在這裡
                ],
              ),
            ),
          ),
        ],
      );
}
