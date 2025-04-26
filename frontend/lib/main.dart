import 'dart:async'; //  ← StreamSubscription
import 'dart:convert'; //  ← jsonDecode
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
  Widget build(BuildContext context) => MaterialApp(
        title: 'Crowd-Alert Dashboard',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        home: const DashboardPage(),
      );
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
      final payload = root['onCreateAlert'];
      if (payload == null) return;

      // 每次有新事件 → 重新 Load 全部
      await _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    final resp = await Amplify.API
        .query<String>(request: GraphQLRequest<String>(document: listDoc))
        .response;
    final items = (jsonDecode(resp.data!)['listAlerts'] as List)
        .cast<Map<String, dynamic>>();

    // 把重複ID去掉：以 id 當 key
    final alertsMap = <String, Alert>{};
    for (final item in items) {
      final alert = Alert.fromJson(item);
      alertsMap[alert.id] = alert;
    }
    final alerts = alertsMap.values.toList();

    // 分成未 resolved 和 resolved
    final unresolved = alerts.where((a) => a.resolved != true).toList();
    final resolved = alerts.where((a) => a.resolved == true).toList();

    // 按時間排序，新的在前
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
          request: GraphQLRequest<String>(
            document: updateDoc,
            variables: {'id': a.id, 'r': true},
          ),
        )
        .response;

    // 標記完也 reload
    await _loadHistory();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Crowd-Alert Dashboard')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_unresolved.isNotEmpty)
                  ..._unresolved.map((a) => _buildUnresolvedCard(a)),
                const SizedBox(height: 20),
                const Text('歷史警示', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                ..._resolved.map((a) => _buildResolvedTile(a)),
              ],
            ),
          ),
        ),
      );

// 新增一個小小的 Helper，原本的 ListTile 抽出來
  Widget _buildResolvedTile(Alert a) => Column(
        children: [
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(a.msg),
            subtitle: Text(
              '等級 ${a.level} • 位置 ${a.location} • ${DateTime.parse(a.ts).toLocal().toString().split(".").first}',
            ),
          ),
          const Divider(),
        ],
      );

  Widget _buildUnresolvedCard(Alert a) => Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(children: [
          Image.network(
            a.imgUrl ?? '',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(
                height: 200,
                child: Center(child: Icon(Icons.image_not_supported))),
          ),
          ListTile(
            title: Text(a.msg),
            subtitle: Text(
              '等級 ${a.level} • 位置 ${a.location}\n'
              '${DateTime.parse(a.ts).toLocal().toString().split(".").first}',
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _markResolved(a),
            icon: const Icon(Icons.check),
            label: const Text('已處理'),
          ),
        ]),
      );

  Widget _buildHistoryList() => ListView.separated(
        itemCount: _resolved.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, i) {
          final a = _resolved[i];
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(a.msg),
            subtitle: Text(
              '等級 ${a.level} • 位置 ${a.location} • ${DateTime.parse(a.ts).toLocal().toString().split(".").first}',
            ),
          );
        },
      );
}
