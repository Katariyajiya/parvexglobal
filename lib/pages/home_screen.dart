import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
// import 'package:package_info_plus/package_info_plus.dart';
import 'package:parvexglobal/extension/extension_functions.dart';
import 'package:parvexglobal/models/tick_data.dart';
import 'package:parvexglobal/services/RestApiServices.dart';
import 'package:parvexglobal/utils/user_session.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'UserProfileScreen.dart';
import 'add_instrument.dart';
import 'instrument_detail.dart';
import 'profile.dart';

// ── Config ────────────────────────────────────────────────────────────────────
const String _wsUrl = 'http://13.127.145.152:5001/ws';
const String _baseUrl = 'http://13.127.145.152:5001';
const String _intlWsUrl = 'ws://13.127.145.152:8000/ws/ticks';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tabs = const ["All", "Equity", "Futures", "Options", "International"];

  int _selectedTab = 0;
  bool _connected = false;
  late String _userId;
  WebSocketChannel? _intlCh;
  StompClient? _stomp;

  // latest tick by token
  final Map<int, TickData> _tickMap = {};

  final api = RestApiService();

  @override
  void initState() {
    super.initState();

    _userId = UserSession.userId.toString();

    WidgetsBinding.instance.addPostFrameCallback((duration) {
      _tickMap.clear();
      _checkForUpdate();
      loadInitialData();
      _connectStomp();
      _connectIntl();
    });
  }

  // 2. ── Helper to classify each tick ─────────────────────────
  String _categoryOf(TickData t) {
    // a. International: any non-Indian exchange you stream separately
    final ex = (t.exchange ?? '').toUpperCase();
    if (ex == 'COMEX' || ex == 'UAE' || ex == 'FOREX') return 'International';

    // b. Prefer an explicit type field if your DTO has it
    final type = (t.tradingSymbol ?? '').toUpperCase();
    if (type.contains('FUT')) return 'Futures';
    if (type.contains('OPT')) return 'Options';

    final forex = (t.exchange ??'').toUpperCase();
    if (forex.contains('FOREX') || forex.contains('COMEX') || forex.contains('METALS')) return 'International';

    // c. Fallback heuristics based on symbol suffix
    if (t.tradingSymbol.endsWith('CE') || t.tradingSymbol.endsWith('PE')) {
      return 'Options';
    }

    if (t.tradingSymbol.contains('FUT')) return 'Futures';

    // d. Default
    return 'Equity';
  }


// 3. ── Visible-tick selector + hook-up ─────────────────────
  List<TickData> _getVisibleTicks() {
    if (_selectedTab == 0) return _tickMap.values.toList();          // “All”
    final filter = _tabs[_selectedTab];
    return _tickMap.values.where((t) => _categoryOf(t) == filter).toList();
  }

  @override
  void dispose() {
    _stomp?.deactivate();
    http.delete(Uri.parse('$_baseUrl/api/v1/watchlist/$_userId'));
    super.dispose();
  }


  void _checkForUpdate() async {
    final update = await api.fetchLatestAppUpdate(platform: 'ANDROID');
    if (update == null) return;

    // final info = await PackageInfo.fromPlatform();
    if (!_isServerVersionNewer(update.version, "2.5.1")) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,          // 🔒 cannot tap outside or press back
      builder: (_) => WillPopScope(       // ⬅️ also blocks Android back button
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Update Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version ${update.version} is available.'),
              if (update.releaseNotes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(update.releaseNotes),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _launchDownload(update.downloadUrl),
              child: const Text('UPDATE NOW'),
            ),
            if (!update.mandatory)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('LATER'),
              ),
          ],
        ),
      ),
    );
  }

  bool _isServerVersionNewer(String server, String local) {
    final s = server.split('.').map(int.parse).toList();
    final l = local.split('.').map(int.parse).toList();
    for (var i = 0; i < s.length || i < l.length; i++) {
      final sv = i < s.length ? s[i] : 0;
      final lv = i < l.length ? l[i] : 0;
      if (sv > lv) return true;
      if (sv < lv) return false;
    }
    return false;
  }

  void _launchDownload(String url) async {
    final uri = Uri.parse(url);
    // if (await canLaunchUrl(uri)) {
    //   await launchUrl(uri, mode: LaunchMode.externalApplication);
    // }
  }

  void _connectIntl() {
    _intlCh = WebSocketChannel.connect(Uri.parse(_intlWsUrl));
    _intlCh!.stream
        .listen(
          (raw) {
            if (raw is String && raw != "ping" && raw != "pong") {
              final m = jsonDecode(raw) as Map<String, dynamic>;
              final tick = TickData.fromJson(m);
              if (tick.tradingSymbol.isNotEmpty) {
                tick.instrumentToken = mapAlphabetsToInt(tick.tradingSymbol);
                if (!mounted) return;
                setState(() {
                  _tickMap[tick.instrumentToken] = tick;
                });
              }
            }
          },
          onError: (e) => debugPrint('Intl WS error: $e'),
          onDone: () => debugPrint('Intl WS closed – reconnecting in 5 s'),
        )
        .onDone(() => Future.delayed(const Duration(seconds: 5), _connectIntl));

    // subscribeSymbols();
  }

  void subscribeSymbols() {
    if (_intlCh == null) {
      addLog("Connect socket first");
      return;
    }

    final payload = {
      "action": "subscribe",
      "symbols": ["EURUSD", "XAUUSD", "GBPUSD"],
    };

    final jsonMsg = jsonEncode(payload);

    _intlCh!.sink.add(jsonMsg);

    addLog("Sent: $jsonMsg");
  }

  void disconnectSocket() {
    _intlCh?.sink.close();
    _intlCh = null;

    setState(() {
      _connected = false;
    });

    addLog("Socket closed");
  }

  List<String> logs = [];

  void addLog(String msg) {
    final time = TimeOfDay.now().format(context);
    setState(() {
      logs.insert(0, "[$time] $msg");
    });
  }

  void loadInitialData() async {
    var data = await api.loadSnapshot();
    setState(() {
      for (final item in data) {
        if (item != null) {
          final tick = TickData.fromJson(item as Map<String, dynamic>);
          _tickMap[tick.instrumentToken] = tick;
        }
      }
    });
  }

  void _connectStomp() {
    _stomp?.deactivate();
    _stomp = StompClient(
      config: StompConfig.SockJS(
        url: _wsUrl,
        onConnect: _onConnect,
        onDisconnect: _onDisconnect,
        onStompError: (f) => debugPrint('STOMP error: ${f.body}'),
        onWebSocketError: (e) => debugPrint('WS error: $e'),
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _stomp!.activate();
  }

  void _onConnect(StompFrame frame) {
    debugPrint('WebSocket connected');
    setState(() => _connected = true);

    _stomp!.subscribe(
      destination: '/topic/watchlist/$_userId',
      callback: (frame) {
        if (frame.body == null) return;

        final List batch = jsonDecode(frame.body!);

        setState(() {
          for (final item in batch) {
            final tick = TickData.fromJson(item as Map<String, dynamic>);
            _tickMap[tick.instrumentToken] = tick;

            // keep snapshot order stable; only append if truly new
            // if (!_snapshotOrder.contains(tick.instrumentToken)) {
            //   _snapshotOrder.add(tick.instrumentToken);
            // }
          }
        });
      },
    );
  }

  void _onDisconnect(StompFrame frame) {
    debugPrint('WebSocket disconnected');
    setState(() => _connected = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFFF6F6F6), appBar: _buildAppBar(), body: Column(children: [_buildWatchlistHeader(), _buildTabBar(), _buildTickList()]));
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: RichText(
        text: const TextSpan(
          text: 'Bhav',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          children: [TextSpan(text: 'Tav', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 20))],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.circle, size: 9, color: _connected ? Colors.green : Colors.grey),
              const SizedBox(width: 4),
              Text(_connected ? 'Live' : '...', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        _buildAppBarAction(Icons.search, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddInstrument()))),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 8),
          child: const CircleAvatar(backgroundColor: Color(0xFF2979FF), child: Icon(Icons.person, color: Colors.white, size: 20)),
        ).onClick(() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
      ],
    );
  }

  Widget _buildWatchlistHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('My WatchList', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddInstrument())),
            child: const Text('+ Add', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  final Set<int> _deletingIds = {};

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => _ChipTab(label: _tabs[i], selected: i == _selectedTab, onTap: () => setState(() => _selectedTab = i)),
        ),
      ),
    );
  }

  Widget _buildTickList() {
    if (_tickMap.isEmpty) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    // final visibleTicks = _getVisibleTicks();
    // final visibleTicks = _tickMap.values.toList();
    final visibleTicks =_getVisibleTicks();

    if (visibleTicks.isEmpty) {
      return const Expanded(child: Center(child: Text('No instruments found for this filter', style: TextStyle(color: Colors.grey))));
    }

    return Expanded(
      child: ListView.builder(
        itemCount: visibleTicks.length,
        itemBuilder: (context, index) {
          final tick = visibleTicks[index];
          return Dismissible(
            key: Key(tick.instrumentToken.toString()),
            direction: DismissDirection.endToStart,

            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),

            onDismissed: (direction) async {
              final removedTick = tick;

              setState(() {
                _tickMap.remove(removedTick.instrumentToken);
              });

              final success = await api.removeFromWatchlist(instrumentId: removedTick.id);

              if (!success) {
                setState(() {
                  _tickMap[removedTick.instrumentToken] = removedTick;
                });

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to remove item")));
              }
            },

            child: _buildWatchlistCard(context, tick: tick),
          );
        },
      ),
    );
  }

  Widget _buildWatchlistCard(BuildContext context, {required TickData tick}) {
    final color = tick.isUp ? Colors.green.shade700 : Colors.red.shade700;
    final arrow = tick.isUp ? '▲' : '▼';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstrumentDetailScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        margin: const EdgeInsets.only(bottom: 2),
        color: Colors.white,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const SizedBox(), _buildDetailItem('LTP : ', '₹${tick.lastPrice.toStringAsFixed(2)}', isHighlight: true)],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: Text(tick.tradingSymbol, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900))),
                Text('₹${tick.lastPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                Text(
                  '$arrow ${tick.change.toStringAsFixed(2)} (${tick.changePercent.toStringAsFixed(2)}%)',
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem('PREV CLOSE : ', '₹${tick.close.toStringAsFixed(2)}'),
                _buildDetailItem('OPEN : ', '₹${tick.open.toStringAsFixed(2)}'),
                _buildDetailItem('H : ', '₹${tick.high.toStringAsFixed(2)}'),
                _buildDetailItem('L : ', '₹${tick.low.toStringAsFixed(2)}', isHighlight: true),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarAction(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: Colors.black54, size: 20), onPressed: onTap),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(width: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isHighlight ? Colors.red.shade400 : Colors.black87)),
      ],
    );
  }
}

class _ChipTab extends StatelessWidget {
  const _ChipTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF1F63FF) : Colors.white;
    final fg = selected ? Colors.white : const Color(0xFF55657C);
    final border = selected ? const Color(0xFF1F63FF) : const Color(0xFFDEE6F1);

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4), border: Border.all(color: border, width: 1.4)),
        child: Center(child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12))),
      ),
    );
  }
}

int mapAlphabetsToInt(String input) {
  final buffer = StringBuffer();

  for (int i = 0; i < input.length; i++) {
    final c = input[i].toUpperCase();

    if (c.codeUnitAt(0) >= 65 && c.codeUnitAt(0) <= 90) {
      int value = c.codeUnitAt(0) - 65 + 1;
      buffer.write(value);
    }
  }

  return int.parse(buffer.toString());
}
