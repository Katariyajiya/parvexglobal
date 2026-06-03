import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Trade model ───────────────────────────────────────────────────────────────

enum TradeType { buy, sell }

class Trade {
  final String id;
  final String symbol;
  final int instrumentToken;
  final TradeType type;
  final int quantity;
  final double entryPrice;
  final DateTime entryTime;

  // closed fields
  double? exitPrice;
  DateTime? exitTime;
  bool isClosed;

  // live price — updated by HomeScreen tick feed
  double? livePrice;

  Trade({
    required this.id,
    required this.symbol,
    required this.instrumentToken,
    required this.type,
    required this.quantity,
    required this.entryPrice,
    required this.entryTime,
    this.exitPrice,
    this.exitTime,
    this.isClosed = false,
    this.livePrice,
  });

  // ── P&L helpers ──────────────────────────────────────────────────────────

  /// Unrealised MTM for open trades.
  double get unrealisedPnL {
    if (livePrice == null) return 0;
    final diff = type == TradeType.buy
        ? livePrice! - entryPrice
        : entryPrice - livePrice!;
    return diff * quantity;
  }

  /// Realised P&L for closed trades.
  double get realisedPnL {
    if (!isClosed || exitPrice == null) return 0;
    final diff = type == TradeType.buy
        ? exitPrice! - entryPrice
        : entryPrice - exitPrice!;
    return diff * quantity;
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'symbol': symbol,
    'instrumentToken': instrumentToken,
    'type': type.name,
    'quantity': quantity,
    'entryPrice': entryPrice,
    'entryTime': entryTime.toIso8601String(),
    'exitPrice': exitPrice,
    'exitTime': exitTime?.toIso8601String(),
    'isClosed': isClosed,
  };

  factory Trade.fromJson(Map<String, dynamic> j) => Trade(
    id: j['id'] as String,
    symbol: j['symbol'] as String,
    instrumentToken: j['instrumentToken'] as int? ?? 0,
    type: j['type'] == 'sell' ? TradeType.sell : TradeType.buy,
    quantity: j['quantity'] as int,
    entryPrice: (j['entryPrice'] as num).toDouble(),
    entryTime: DateTime.parse(j['entryTime'] as String),
    exitPrice: j['exitPrice'] != null ? (j['exitPrice'] as num).toDouble() : null,
    exitTime: j['exitTime'] != null ? DateTime.parse(j['exitTime'] as String) : null,
    isClosed: j['isClosed'] as bool? ?? false,
  );
}

// ── TradeService ──────────────────────────────────────────────────────────────

class TradeService extends ChangeNotifier {
  TradeService._();
  static final instance = TradeService._();

  static const _prefKey = 'trades_v1';

  final List<Trade> _trades = [];

  List<Trade> get openTrades => _trades.where((t) => !t.isClosed).toList();
  List<Trade> get closedTrades =>
      _trades.where((t) => t.isClosed).toList()
        ..sort((a, b) => (b.exitTime ?? b.entryTime).compareTo(a.exitTime ?? a.entryTime));

  // ── Aggregates ─────────────────────────────────────────────────────────────

  double get openMTM => openTrades.fold(0, (s, t) => s + t.unrealisedPnL);
  double get realisedPnL => closedTrades.fold(0, (s, t) => s + t.realisedPnL);
  double get totalPnL => openMTM + realisedPnL;

  // ── Load / save ────────────────────────────────────────────────────────────

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _trades
          ..clear()
          ..addAll(list.map((e) => Trade.fromJson(e as Map<String, dynamic>)));
      }
    } catch (e) {
      debugPrint('TradeService.load error: $e');
    }
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(_trades.map((t) => t.toJson()).toList()));
    } catch (e) {
      debugPrint('TradeService._save error: $e');
    }
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<void> addTrade({
    required String symbol,
    required int instrumentToken,
    required TradeType type,
    required int quantity,
    required double entryPrice,
    double? currentLivePrice,
  }) async {
    final trade = Trade(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      symbol: symbol,
      instrumentToken: instrumentToken,
      type: type,
      quantity: quantity,
      entryPrice: entryPrice,
      entryTime: DateTime.now(),
      livePrice: currentLivePrice ?? entryPrice,
    );
    _trades.add(trade);
    await _save();
    notifyListeners();
  }

  Future<void> closeTrade(Trade trade, double exitPrice) async {
    trade.exitPrice = exitPrice;
    trade.exitTime = DateTime.now();
    trade.isClosed = true;
    await _save();
    notifyListeners();
  }

  Future<void> deleteTrade(String id) async {
    _trades.removeWhere((t) => t.id == id);
    await _save();
    notifyListeners();
  }

  // ── Live price feed ────────────────────────────────────────────────────────
  // Called by HomeScreen every time a tick arrives.
  // Updates livePrice on every open trade with a matching instrumentToken.

  void pushTick({required int token, required double price}) {
    bool changed = false;
    for (final t in _trades) {
      if (!t.isClosed && t.instrumentToken == token) {
        t.livePrice = price;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  // Bulk update from initial snapshot (called once on load).
  void pushTickMap(Map<int, double> priceMap) {
    bool changed = false;
    for (final t in _trades) {
      if (!t.isClosed && priceMap.containsKey(t.instrumentToken)) {
        t.livePrice = priceMap[t.instrumentToken]!;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}