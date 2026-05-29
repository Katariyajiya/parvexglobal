import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:parvexglobal/alert/PriceAlert.dart';
import 'package:parvexglobal/alert/alert_banner.dart';
import 'package:parvexglobal/alert/alert_service.dart';
import 'package:parvexglobal/alert/alert_sound_service.dart';
import 'package:parvexglobal/alert/set_alert_bottom_sheet.dart';
import 'package:parvexglobal/extension/extension_functions.dart';
import 'package:parvexglobal/models/tick_data.dart';
import 'package:parvexglobal/pages/AlertHistoryScreen.dart';
import 'package:parvexglobal/services/RestApiServices.dart';
import 'package:parvexglobal/utils/ad_banner_widget.dart';
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

  // ── Alert services (NEW) ───────────────────────────────────────────────────
  final _alertService = AlertService.instance;
  final _soundService = AlertSoundService.instance;

  @override
  void initState() {
    super.initState();

    _userId = UserSession.userId.toString();

    // Wire up alert callback (NEW)
    _alertService.onAlertFired = _onAlertFired;

    WidgetsBinding.instance.addPostFrameCallback((duration) {
      _tickMap.clear();
      _checkForUpdate();
      loadInitialData();
      _connectStomp();
      _connectIntl();
    });
  }

  void _onAlertFiredTest() {
    print("Testing Alert");
    _soundService.playAlert();
  }

  // ── NEW: Called whenever any alert fires ───────────────────────────────────
  void _onAlertFired(PriceAlert alert) {
    if (!mounted) return;
    _soundService.playAlert(); // 🔔 play sound
    AlertBannerOverlay.show(context, alert); // 📢 show banner
  }

  // ── Category classifier ────────────────────────────────────────────────────
  String _categoryOf(TickData t) {
    final ex = (t.exchange ?? '').toUpperCase();
    if (ex == 'COMEX' || ex == 'UAE' || ex == 'FOREX') return 'International';

    final type = (t.tradingSymbol ?? '').toUpperCase();
    if (type.contains('FUT')) return 'Futures';
    if (type.contains('OPT')) return 'Options';

    final forex = (t.exchange ?? '').toUpperCase();
    if (forex.contains('FOREX') || forex.contains('COMEX') || forex.contains('METALS')) return 'International';

    if (t.tradingSymbol.endsWith('CE') || t.tradingSymbol.endsWith('PE')) {
      return 'Options';
    }
    if (t.tradingSymbol.contains('FUT')) return 'Futures';

    return 'Equity';
  }

  List<TickData> _getVisibleTicks() {
    if (_selectedTab == 0) return _tickMap.values.toList();
    final filter = _tabs[_selectedTab];
    return _tickMap.values.where((t) => _categoryOf(t) == filter).toList();
  }

  @override
  void dispose() {
    _stomp?.deactivate();
    http.delete(Uri.parse('$_baseUrl/api/v1/watchlist/$_userId'));
    _soundService.dispose(); // ← NEW
    super.dispose();
  }

  // ── Update check ──────────────────────────────────────────────────────────
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
    final uri = Uri.parse(url);
    // if (await canLaunchUrl(uri)) {
    //   await launchUrl(uri, mode: LaunchMode.externalApplication);
    // }
  }

  // ── WebSocket: International ───────────────────────────────────────────────
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

                // ── Check alerts for this tick (NEW) ──────────────────────
                _alertService.checkTick(
                  token: tick.instrumentToken,
                  price: tick.lastPrice,
                );

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
    _intlCh!.sink.add(jsonEncode(payload));
    addLog("Sent: ${jsonEncode(payload)}");
  }

  void disconnectSocket() {
    _intlCh?.sink.close();
    _intlCh = null;
    setState(() => _connected = false);
    addLog("Socket closed");
  }

  List<String> logs = [];

  void addLog(String msg) {
    final time = TimeOfDay.now().format(context);
    setState(() => logs.insert(0, "[$time] $msg"));
  }

  // ── Initial snapshot ───────────────────────────────────────────────────────
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

  // ── STOMP ─────────────────────────────────────────────────────────────────
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

            // ── Check alerts for this tick (NEW) ──────────────────────────
            _alertService.checkTick(
              token: tick.instrumentToken,
              price: tick.lastPrice,
            );
          }
        });
      },
    );
  }

  bool _editing = false;

  void _onDisconnect(StompFrame frame) {
    debugPrint('WebSocket disconnected');
    setState(() => _connected = false);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
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

  double _editSlide = 56;

  // ── Watchlist card ─────────────────────────────────────────────────────────
  // Matches the BhavTav screenshot design exactly:
  // • Colored avatar circle with initials (left)
  // • Symbol name (bold) + subtitle (muted, below)
  // • Price on the right (large, bold)
  // • RISING / FALLING label + colored % pill badge
  // • Prev close / Open / H/L detail row at the bottom
  // • Subtle green/red tinted card background

  Widget _buildWatchlistCard(BuildContext context, {required TickData tick}) {
    final isUp = tick.isUp;
    final directionColor = isUp ? const Color(0xFF1E7D3A) : const Color(0xFFCC2929);
    final bgColor = isUp ? const Color(0xFFF8FDF9) : const Color(0xFFFEF7F7);
    final pillBgColor = isUp ? const Color(0xFFD6F3E0) : const Color(0xFFF9D6D6);
    final pillTextColor = isUp ? const Color(0xFF1A6E33) : const Color(0xFFB82323);
    final directionLabel = isUp ? 'RISING' : 'FALLING';
    final directionIcon = isUp ? Icons.trending_up : Icons.trending_down_outlined;

    // Initials from trading symbol (up to 2 chars)
    final initials = tick.tradingSymbol.length >= 2 ? tick.tradingSymbol.substring(0, 2).toUpperCase() : tick.tradingSymbol.toUpperCase();

    // Avatar colors — rotate through a set based on symbol hash
    final avatarColors = [
      (bg: const Color(0xFF4CAF50), text: Colors.white), // green
      (bg: const Color(0xFF1F63FF), text: Colors.white), // blue
      (bg: const Color(0xFFE48C1A), text: Colors.white), // amber
      (bg: const Color(0xFF9C27B0), text: Colors.white), // purple
      (bg: const Color(0xFFE53935), text: Colors.white), // red
      (bg: const Color(0xFF00ACC1), text: Colors.white), // teal
    ];
    final avatarStyle = avatarColors[tick.tradingSymbol.hashCode.abs() % avatarColors.length];

    // NEW: does this instrument have any active (non-triggered) alert?
    final hasAlert = _alertService.alertsForToken(tick.instrumentToken).any((a) => !a.triggered);

    return Stack(
      children: [
        // ── Card ────────────────────────────────────────────────────────────
        AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          offset: _editing ? Offset(1, 0) * (_editSlide / MediaQuery.of(context).size.width) : Offset.zero,
          child: GestureDetector(
            onTap: () {
              // if (_editing) return;
              // Navigator.push(context,
              //   MaterialPageRoute(builder: (_) => const InstrumentDetailScreen()));
            },
            onLongPress: () => SetAlertBottomSheet.show(
              context,
              instrumentToken: tick.instrumentToken,
              symbol: tick.tradingSymbol,
              currentPrice: tick.lastPrice,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                // color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUp ? const Color(0xFFB2DFBE) : const Color(0xFFF1B8B8),
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
                    directionColor.withOpacity(0.0),
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
                    // ── Top row: avatar + name/subtitle | price + direction ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar circle
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: avatarStyle.bg,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: avatarStyle.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Symbol name + subtitle
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
                              SizedBox(height: 6),
                              InkWell(
                                onTap: () => SetAlertBottomSheet.show(
                                  context,
                                  instrumentToken: tick.instrumentToken,
                                  symbol: tick.tradingSymbol,
                                  currentPrice: tick.lastPrice,
                                ),
                                borderRadius: BorderRadius.circular(12), // Matches the container's radius
                                child: Container(
                                  // Adjusted padding: wider on the sides to accommodate the text
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6), // Pill shape
                                    color: hasAlert ? const Color(0xFF1F63FF).withOpacity(0.08) : Colors.grey.shade100,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min, // Keeps the button from stretching
                                    children: [
                                      Icon(
                                        hasAlert ? Icons.notifications_active : Icons.notifications_none,
                                        size: 16, // Scaled down slightly to balance with the text
                                        color: hasAlert ? const Color(0xFF1F63FF) : Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4), // Small gap between icon and text
                                      Text(
                                        "Set Alert",
                                        style: TextStyle(
                                          fontSize: 12, // Keeps it subtle
                                          fontWeight: FontWeight.w500, // Medium weight for readability
                                          color: hasAlert ? const Color(0xFF1F63FF) : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Price + direction column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Price
                            Text(
                              '₹${tick.lastPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Direction label row
                            Row(
                              children: [
                                // RISING / FALLING label
                                // Row(
                                //   children: [
                                //     Container(
                                //       width: 10,
                                //       height: 10,
                                //       decoration: BoxDecoration(
                                //         border: Border.all(color: directionColor, width: 1.5),
                                //         borderRadius: BorderRadius.circular(2),
                                //       ),
                                //     ),
                                //     const SizedBox(width: 4),
                                //     Text(
                                //       directionLabel,
                                //       style: TextStyle(
                                //         color: directionColor,
                                //         fontSize: 12,
                                //         fontWeight: FontWeight.w700,
                                //         letterSpacing: 0.5,
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                // const SizedBox(width: 6),
                                // Percentage pill badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: pillBgColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(directionIcon, size: 14, color: directionColor),
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
                              ],
                            ),
                          ],
                        ),

                        // Bell icon (alert) — top-right
                        const SizedBox(width: 6),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Divider(
                      height: 1,
                      thickness: 0.6,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 8),

                    // ── Bottom row: Prev close | Open | H / L ────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDetailItem('Prev close', '${tick.close.toStringAsFixed(2)}'),
                        _buildDetailItem('Open', '${tick.open.toStringAsFixed(2)}'),
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
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: _deletingIds.contains(tick.instrumentToken)
                  ? Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(left: 16.0),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      splashRadius: 24,
                      icon: const Icon(Icons.remove_circle, color: Colors.red, size: 28),
                      onPressed: () => _removeInstrument(tick),
                    ),
            ),
          ),
      ],
    );
  }

  // ── Detail label + value column (bottom row) ─────────────────────────────────
  Widget _buildDetailItem(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: RichText(
        text: const TextSpan(
          text: 'Bhav',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          children: [
            TextSpan(
              text: 'Tav',
              style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
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
        _buildAppBarAction(
          Icons.search,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddInstrument()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 8),
          child: const CircleAvatar(
            backgroundColor: Color(0xFF2979FF),
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ).onClick(
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(right: 16, left: 8),
          child: const CircleAvatar(
            backgroundColor: Color(0xFFFF3264),
            child: Icon(Icons.notifications, color: Colors.white, size: 20),
          ),
        ).onClick(
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AlertHistoryScreen()),
          ),
        ),
      ],
    );
  }

  // ── Watchlist header ───────────────────────────────────────────────────────
  Widget _buildWatchlistHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
      child: Row(
        children: [
          const Text('My WatchList', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)).onClick(() {
            _onAlertFiredTest();
          }),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddInstrument()),
            ),
            child: const Text(
              '+ Add',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _editing = !_editing),
            child: Text(
              _editing ? 'Done' : 'Edit',
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  final Set<int> _deletingIds = {};

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
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    final visibleTicks = _getVisibleTicks();

    if (visibleTicks.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('No instruments found for this filter', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: visibleTicks.length,
        itemBuilder: (context, index) {
          final tick = visibleTicks[index];
          return _buildWatchlistCard(context, tick: tick);
        },
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _buildAppBarAction(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.black54, size: 20),
        onPressed: onTap,
      ),
    );
  }

  void _removeInstrument(TickData tick) async {
    final token = tick.instrumentToken;
    setState(() => _deletingIds.add(token));

    bool success = false;
    try {
      success = await api.removeFromWatchlist(instrumentId: tick.id).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      // treat timeout as failure
    }

    if (success) {
      setState(() {
        _tickMap.remove(token);
        _deletingIds.remove(token);
        // Also remove any alerts for this token (NEW)
        _alertService.removeAllForToken(token);
      });
    } else {
      setState(() => _deletingIds.remove(token));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove item')),
      );
    }
  }
}

// ── _ChipTab ──────────────────────────────────────────────────────────────────
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
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: border, width: 1.4),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
int mapAlphabetsToInt(String input) {
  final buffer = StringBuffer();
  for (int i = 0; i < input.length; i++) {
    final c = input[i].toUpperCase();
    if (c.codeUnitAt(0) >= 65 && c.codeUnitAt(0) <= 90) {
      buffer.write(c.codeUnitAt(0) - 65 + 1);
    }
  }
  return int.parse(buffer.toString());
}
