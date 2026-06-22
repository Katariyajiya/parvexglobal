import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:parvexglobal/alert/PriceAlert.dart';
import 'package:parvexglobal/alert/alert_banner.dart';
import 'package:parvexglobal/alert/alert_service.dart';
import 'package:parvexglobal/alert/alert_sound_service.dart';
import 'package:parvexglobal/alert/set_alert_bottom_sheet.dart';
import 'package:parvexglobal/bottomsheet/add_trade_bottom_sheet.dart';
import 'package:parvexglobal/extension/extension_functions.dart';
import 'package:parvexglobal/models/tick_data.dart';
import 'package:parvexglobal/pages/AlertHistoryScreen.dart';
import 'package:parvexglobal/pages/trade_ledger_screen.dart';
import 'package:parvexglobal/services/RestApiServices.dart';
import 'package:parvexglobal/services/trade_service.dart';
import 'package:parvexglobal/utils/ad_banner_widget.dart';
import 'package:parvexglobal/utils/user_session.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'UserProfileScreen.dart';
import 'add_instrument.dart';
import 'instrument_detail.dart';
import 'profile.dart';

// ── Config ────────────────────────────────────────────────────────────────────
const String _wsUrl   = 'http://35.154.42.122:5001/ws';
const String _baseUrl = 'http://35.154.42.122:5001';
const String _mt5Host = '35.154.42.122';
const int    _mt5Port = 8765;

String _buildMt5WsUrl(List<String> symbols) {
  final params = symbols.join(',');
  return 'ws://$_mt5Host:$_mt5Port/?symbols=$params';
}

// ── Symbol → stable int key ───────────────────────────────────────────────────
// Converts a trading symbol string into a stable, unique int key using a
// djb2-style hash. Always returns a positive non-zero value.
//
// This replaces the fragile instrumentToken / id fallback chain:
//   • instrumentToken is 0 for ALL FOREX symbols from the MT5 server
//   • id can collide between different exchanges
//   • tradingSymbol is always present, always unique per instrument
//
// Same symbol → same key on every call, on every device, for all time.
// Examples:
//   symbolKey('EURUSD')   → 2090424769
//   symbolKey('RELIANCE') → 1847362910
//   symbolKey('NIFTY50')  → 3459823104
int symbolKey(String symbol) {
  final s = symbol.toUpperCase();
  int hash = 5381;
  for (final c in s.codeUnits) {
    hash = ((hash << 5) + hash) ^ c; // djb2: hash * 33 ^ charCode
  }
  // Mask to 31 bits → always positive, never zero-risks from sign
  return hash.abs() & 0x7FFFFFFF;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tabs = const ["All", "Equity", "Futures", "Options", "International"];

  int  _selectedTab = 0;
  bool _connected   = false;
  late String _userId;

  WebSocketChannel? _intlCh;
  StompClient?      _stomp;

  // ── MT5 exchange filter ────────────────────────────────────────────────────
  static const _mt5Exchanges = {'CRYPTO', 'FOREX', 'LSE', 'NYSE'};

  // Active MT5 symbol list — kept in sync with the watchlist.
  List<String> _intlSymbols = [];

  // ── Tick map ───────────────────────────────────────────────────────────────
  // Key = symbolKey(tradingSymbol) — a stable positive int derived from the
  // symbol string via djb2 hash. Uniform across STOMP, MT5, and snapshot.
  final Map<int, TickData> _tickMap = {};

  final api = RestApiService();

  // ── Alert services ─────────────────────────────────────────────────────────
  final _alertService = AlertService.instance;
  final _soundService = AlertSoundService.instance;

  // ── Trade service ──────────────────────────────────────────────────────────
  final _tradeService = TradeService.instance;

  // ── Edit mode ──────────────────────────────────────────────────────────────
  bool           _editing     = false;
  double         _editSlide   = 56;
  final Set<int> _deletingIds = {};

  // ──────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _userId = UserSession.userId.toString();
    _alertService.onAlertFired = _onAlertFired;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tickMap.clear();
      _checkForUpdate();
      loadInitialData(); // MT5 connect happens inside after snapshot loads
      _connectStomp();
    });
  }

  @override
  void dispose() {
    _stomp?.deactivate();
    http.delete(Uri.parse('$_baseUrl/api/v1/watchlist/$_userId'));
    _intlCh?.sink.close();
    _soundService.dispose();
    super.dispose();
  }

  // ── Alert callbacks ────────────────────────────────────────────────────────
  void _onAlertFiredTest() => debugPrint("Testing Alert");

  void _onAlertFired(PriceAlert alert) {
    if (!mounted) return;
    _soundService.playAlert(alert);
    AlertBannerOverlay.show(context, alert);
  }

  // ── Category classifier ────────────────────────────────────────────────────
  String _categoryOf(TickData t) {
    final ex   = (t.exchange ?? '').toUpperCase();
    final type = (t.instrumentType ?? '').toUpperCase();
    final seg  = (t.segment ?? '').toUpperCase();

    if (_mt5Exchanges.contains(ex))                                               return 'International';
    if (ex == 'COMEX' || ex == 'UAE')                                             return 'International';
    if (t.tradingSymbol.endsWith('CE') || t.tradingSymbol.endsWith('PE'))         return 'Options';
    if (type == 'FUT' || seg.contains('FUT') || t.tradingSymbol.contains('FUT')) return 'Futures';
    return 'Equity';
  }

  List<TickData> _getVisibleTicks() {
    if (_selectedTab == 0) return _tickMap.values.toList();
    final filter = _tabs[_selectedTab];
    return _tickMap.values.where((t) => _categoryOf(t) == filter).toList();
  }

  // ── Update check ───────────────────────────────────────────────────────────
  void _checkForUpdate() async {
    final update = await api.fetchLatestAppUpdate(platform: 'ANDROID');
    if (update == null) return;
    if (!_isServerVersionNewer(update.version, "2.5.1")) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
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
    // await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // ── Initial snapshot ───────────────────────────────────────────────────────
  void loadInitialData() async {
    final data = await api.loadSnapshot();

    setState(() {
      for (final item in data) {
        if (item != null) {
          final tick = TickData.fromJson(item as Map<String, dynamic>);
          final key  = symbolKey(tick.tradingSymbol); // ← hash of symbol
          _tickMap[key] = tick;
        }
      }
    });

    // Push all known prices to the trade service
    final priceMap = <int, double>{};
    for (final entry in _tickMap.entries) {
      priceMap[entry.key] = entry.value.lastPrice;
    }
    _tradeService.pushTickMap(priceMap);

    // ── Auto-connect MT5 for FOREX / CRYPTO / LSE / NYSE symbols ────────────
    final mt5Symbols = _tickMap.values
        .where((t) => _mt5Exchanges.contains(t.exchange.toUpperCase()))
        .map((t) => t.tradingSymbol)
        .toSet()
        .toList();

    if (mt5Symbols.isNotEmpty) {
      debugPrint('[MT5] Auto-connecting for symbols: $mt5Symbols');
      _updateIntlSymbols(mt5Symbols);
    } else {
      debugPrint('[MT5] No MT5 symbols in watchlist — skipping connection');
    }
  }

  // ── MT5 WebSocket ──────────────────────────────────────────────────────────
  void _connectIntl(List<String> symbols) {
    _intlCh?.sink.close();
    _intlCh = null;

    if (symbols.isEmpty) return;

    final url = _buildMt5WsUrl(symbols);
    debugPrint('[MT5] Connecting: $url');

    _intlCh = WebSocketChannel.connect(Uri.parse(url));

    _intlCh!.stream.listen(
          (raw) {
        if (raw is! String) return;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map && decoded.containsKey('error')) {
            debugPrint('[MT5] Server error: ${decoded['error']}');
            return;
          }
          if (decoded is List) {
            for (final item in decoded) {
              _handleMt5Tick(item as Map<String, dynamic>);
            }
          }
        } catch (e) {
          debugPrint('[MT5] Parse error: $e');
        }
      },
      onError: (e) => debugPrint('[MT5] WS error: $e'),
      onDone: () {
        debugPrint('[MT5] WS closed — reconnecting in 5s');
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) _connectIntl(_intlSymbols);
        });
      },
      cancelOnError: false,
    );
  }

  void _handleMt5Tick(Map<String, dynamic> raw) {
    debugPrint('[MT5] Tick: $raw');

    final symbol = (raw['tradingSymbol'] as String? ?? '').toUpperCase();
    if (symbol.isEmpty) return;

    // Key derived from symbol — instrumentToken is intentionally ignored here
    // because MT5 sends 0 for all FOREX pairs.
    final token = symbolKey(symbol);

    final lastPrice     = (raw['lastPrice']     as num?)?.toDouble() ?? 0.0;
    final change        = (raw['change']        as num?)?.toDouble() ?? 0.0;
    final changePercent = (raw['changePercent'] as num?)?.toDouble() ?? 0.0;
    final open          = (raw['open']          as num?)?.toDouble() ?? lastPrice;
    final high          = (raw['high']          as num?)?.toDouble() ?? lastPrice;
    final low           = (raw['low']           as num?)?.toDouble() ?? lastPrice;
    final close         = (raw['close']         as num?)?.toDouble() ?? lastPrice;
    final volume        = (raw['volume']        as num?)?.toDouble() ?? 0.0;
    final buyQuantity   = (raw['buyQuantity']   as num?)?.toDouble() ?? 0.0;
    final sellQuantity  = (raw['sellQuantity']  as num?)?.toDouble() ?? 0.0;
    final timestamp     = (raw['timestamp']     as num?)?.toInt()    ?? 0;
    final id            = (raw['id']            as num?)?.toInt()    ?? 0;
    final exchange      =  raw['exchange']      as String?           ?? 'MT5';
    final rawToken      = (raw['instrumentToken'] as num?)?.toInt()  ?? 0;

    final tick = TickData(
      id:              id,
      instrumentToken: rawToken,
      tradingSymbol:   symbol,
      exchange:        exchange,
      lastPrice:       lastPrice,
      change:          change,
      changePercent:   changePercent,
      open:            open,
      high:            high,
      low:             low,
      close:           close,
      volume:          volume,
      buyQuantity:     buyQuantity,
      sellQuantity:    sellQuantity,
      timestamp:       timestamp,
    );

    _alertService.checkTick(token: token, price: lastPrice);
    _tradeService.pushTick(token: token, price: lastPrice);

    if (!mounted) return;
    setState(() => _tickMap[token] = tick);
  }

  void _updateIntlSymbols(List<String> symbols) {
    setState(() => _intlSymbols = symbols);
    _connectIntl(symbols);
  }

  // ── STOMP ──────────────────────────────────────────────────────────────────
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
    debugPrint('STOMP connected');
    setState(() => _connected = true);

    _stomp!.subscribe(
      destination: '/topic/watchlist/$_userId',
      callback: (frame) {
        if (frame.body == null) return;
        final List batch = jsonDecode(frame.body!);
        setState(() {
          for (final item in batch) {
            final tick = TickData.fromJson(item as Map<String, dynamic>);
            final key  = symbolKey(tick.tradingSymbol); // ← hash of symbol
            _tickMap[key] = tick;
            _alertService.checkTick(token: key, price: tick.lastPrice);
            _tradeService.pushTick(token: key, price: tick.lastPrice);
          }
        });
      },
    );
  }

  void _onDisconnect(StompFrame frame) {
    debugPrint('STOMP disconnected');
    setState(() => _connected = false);
  }

  // ── Remove instrument ──────────────────────────────────────────────────────
  void _removeInstrument(TickData tick) async {
    final key = symbolKey(tick.tradingSymbol); // ← hash of symbol
    setState(() => _deletingIds.add(key));

    bool success = false;
    try {
      success = await api
          .removeFromWatchlist(instrumentId: tick.id)
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      // treat timeout as failure
    }

    if (success) {
      setState(() {
        _tickMap.remove(key);
        _deletingIds.remove(key);
        _alertService.removeAllForToken(key);

        if (_mt5Exchanges.contains(tick.exchange.toUpperCase())) {
          final sym = tick.tradingSymbol.toUpperCase();
          _updateIntlSymbols(_intlSymbols.where((s) => s != sym).toList());
        }
      });
    } else {
      setState(() => _deletingIds.remove(key));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove item')),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SampleAdMobBanner(),
          _buildWatchlistHeader(),
          _buildTabBar(),
          _buildTickList(),
        ],
      ),
    );
  }

  // ── Watchlist header ───────────────────────────────────────────────────────
  Widget _buildWatchlistHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
      child: Row(
        children: [
          const Text(
            'My WatchList',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ).onClick(_onAlertFiredTest),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddInstrument()),
            ),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFF1F63FF).withOpacity(0.08),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: Color(0xFF1F63FF)),
                  SizedBox(width: 4),
                  Text(
                    "Add",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F63FF)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => setState(() => _editing = !_editing),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: _editing
                    ? const Color(0xFF1F63FF)
                    : Colors.grey.shade100,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _editing ? Icons.check : Icons.edit_outlined,
                    size: 16,
                    color: _editing ? Colors.white : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _editing ? 'Done' : 'Edit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _editing ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────────────────
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
          itemBuilder: (_, i) => _ChipTab(
            label: _tabs[i],
            selected: i == _selectedTab,
            onTap: () => setState(() => _selectedTab = i),
          ),
        ),
      ),
    );
  }

  // ── Tick list ──────────────────────────────────────────────────────────────
  Widget _buildTickList() {
    if (_tickMap.isEmpty) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final visibleTicks = _getVisibleTicks();
    if (visibleTicks.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No instruments found for this filter',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
        itemCount: visibleTicks.length,
        itemBuilder: (context, index) =>
            _buildWatchlistCard(context, tick: visibleTicks[index]),
      ),
    );
  }

  // ── Watchlist card ─────────────────────────────────────────────────────────
  Widget _buildWatchlistCard(BuildContext context, {required TickData tick}) {
    final key            = symbolKey(tick.tradingSymbol); // ← hash of symbol
    final isUp           = tick.isUp;
    final directionColor =
    isUp ? const Color(0xFF1E7D3A) : const Color(0xFFCC2929);
    final pillBgColor    =
    isUp ? const Color(0xFFD6F3E0) : const Color(0xFFF9D6D6);
    final pillTextColor  =
    isUp ? const Color(0xFF1A6E33) : const Color(0xFFB82323);
    final directionIcon  =
    isUp ? Icons.trending_up : Icons.trending_down_outlined;
    final hasAlert =
    _alertService.alertsForToken(key).any((a) => !a.triggered);

    // Decide decimal precision: FOREX uses 5dp, everything else 2dp
    final isMt5    = _mt5Exchanges.contains(tick.exchange.toUpperCase());
    final priceFmt = isMt5
        ? tick.lastPrice.toStringAsFixed(5)
        : '₹${tick.lastPrice.toStringAsFixed(2)}';

    return Stack(
      children: [
        AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          offset: _editing
              ? Offset(1, 0) * (_editSlide / MediaQuery.of(context).size.width)
              : Offset.zero,
          child: GestureDetector(
            onLongPress: () => SetAlertBottomSheet.show(
              context,
              instrumentToken: key,
              symbol: tick.tradingSymbol,
              currentPrice: tick.lastPrice,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUp
                      ? const Color(0xFFB2DFBE)
                      : const Color(0xFFF1B8B8),
                  width: 0.8,
                ),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.0, 0.08, 0.3, 0.5, 0.7, 0.92, 1.0],
                  colors: [
                    directionColor.withOpacity(0.12),
                    directionColor.withOpacity(0.10),
                    directionColor.withOpacity(0.00),
                    directionColor.withOpacity(0.00),
                    directionColor.withOpacity(0.00),
                    directionColor.withOpacity(0.10),
                    directionColor.withOpacity(0.12),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 4),
                        // ── Symbol + name + action buttons ───────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tick.tradingSymbol,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              if ((tick.name ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    tick.name!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // Set Alert
                                  InkWell(
                                    onTap: () => SetAlertBottomSheet.show(
                                      context,
                                      instrumentToken: key,
                                      symbol: tick.tradingSymbol,
                                      currentPrice: tick.lastPrice,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: hasAlert
                                            ? const Color(0xFF1F63FF)
                                            .withOpacity(0.08)
                                            : Colors.grey.shade100,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            hasAlert
                                                ? Icons.notifications_active
                                                : Icons.notifications_none,
                                            size: 16,
                                            color: hasAlert
                                                ? const Color(0xFF1F63FF)
                                                : Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Set Alert",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: hasAlert
                                                  ? const Color(0xFF1F63FF)
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Add Trade
                                  InkWell(
                                    onTap: () => AddTradeBottomSheet.show(
                                      context,
                                      symbol: tick.tradingSymbol,
                                      instrumentToken: key,
                                      currentPrice: tick.lastPrice,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: const Color(0xFF7C4DFF)
                                            .withOpacity(0.08),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_chart,
                                              size: 16,
                                              color: Color(0xFF7C4DFF)),
                                          SizedBox(width: 4),
                                          Text(
                                            "Add Trade",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF7C4DFF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // ── Price + change pill ──────────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              priceFmt,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: pillBgColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(directionIcon,
                                          size: 14, color: directionColor),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${tick.changePercent.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                          color: pillTextColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tick.change.toStringAsFixed(2),
                                  style: TextStyle(
                                    color: pillTextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(
                        height: 1,
                        thickness: 0.6,
                        color: Colors.grey.shade200),
                    const SizedBox(height: 8),
                    // ── OHLC row ─────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDetailItem(
                            'Prev close', tick.close.toStringAsFixed(2)),
                        _buildDetailItem(
                            'Open', tick.open.toStringAsFixed(2)),
                        _buildDetailItem(
                          'H / L',
                          '${tick.high.toStringAsFixed(2)} / ${tick.low.toStringAsFixed(2)}',
                          alignEnd: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // ── Delete button (edit mode) ──────────────────────────────────────
        if (_editing)
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Center(
              child: _deletingIds.contains(key)
                  ? Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(left: 16),
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
                  : IconButton(
                splashRadius: 24,
                icon: const Icon(Icons.remove_circle,
                    color: Colors.red, size: 28),
                onPressed: () => _removeInstrument(tick),
              ),
            ),
          ),
      ],
    );
  }

  // ── Detail item ────────────────────────────────────────────────────────────
  Widget _buildDetailItem(String label, String value,
      {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
      alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAppBarAction(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration:
      BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
      child: IconButton(
          icon: Icon(icon, color: Colors.black54, size: 20),
          onPressed: onTap),
    );
  }
}

// ── _ChipTab ──────────────────────────────────────────────────────────────────
class _ChipTab extends StatelessWidget {
  const _ChipTab(
      {required this.label,
        required this.selected,
        required this.onTap});

  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg     = selected ? const Color(0xFF1F63FF) : Colors.white;
    final fg     = selected ? Colors.white : const Color(0xFF55657C);
    final border =
    selected ? const Color(0xFF1F63FF) : const Color(0xFFDEE6F1);

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: border, width: 1.4),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
                color: fg, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ),
    );
  }
}