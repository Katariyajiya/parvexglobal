// lib/services/alert_service.dart
//
// Foreground-only local price alert system.
// No background execution — alerts only fire while the app is open.

import 'dart:convert';

import 'package:parvexglobal/alert/AlertCondition.dart';
import 'package:parvexglobal/alert/AlertHistoryEntry.dart';
import 'package:parvexglobal/alert/PriceAlert.dart';
import 'package:parvexglobal/pages/AlertHistoryScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertService {
  AlertService._();

  static final instance = AlertService._();

  static const _alertsKey = 'price_alerts_v1';
  static const _historyKey = 'alert_history_v1';

  final List<PriceAlert> _alerts = [];
  final List<AlertHistoryEntry> _history = [];

  void Function(PriceAlert alert)? onAlertFired;

  List<PriceAlert> get allAlerts => List.unmodifiable(_alerts);

  List<AlertHistoryEntry> get history => List.unmodifiable(_history);

  /// Call once at app start (e.g. in main() after WidgetsFlutterBinding.ensureInitialized())
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final alertsRaw = prefs.getString(_alertsKey);
    if (alertsRaw != null) {
      final List decoded = jsonDecode(alertsRaw);
      _alerts.addAll(decoded.map((e) => PriceAlert.fromJson(e)));
    }

    final historyRaw = prefs.getString(_historyKey);
    if (historyRaw != null) {
      final List decoded = jsonDecode(historyRaw);
      _history.addAll(decoded.map((e) => AlertHistoryEntry.fromJson(e)));
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> addAlert(PriceAlert alert) async {
    _alerts.add(alert);
    await _saveAlerts();
  }

  Future<void> removeAlert(String id) async {
    _alerts.removeWhere((a) => a.id == id);
    await _saveAlerts();
  }

  Future<void> removeAllForToken(int token) async {
    _alerts.removeWhere((a) => a.instrumentToken == token);
    await _saveAlerts();
  }

  List<PriceAlert> alertsForToken(int token) => _alerts.where((a) => a.instrumentToken == token).toList();

  // ── Tick check ────────────────────────────────────────────────────────────

  void checkTick({required int token, required double price}) {
    final toFire = _alerts.where((a) {
      if (a.instrumentToken != token || a.triggered) return false;
      return (a.condition == AlertCondition.above && price >= a.targetPrice) || (a.condition == AlertCondition.below && price <= a.targetPrice);
    }).toList();

    for (final alert in toFire) {
      alert.triggered = true;
      _recordHistory(alert, triggeredPrice: price);
      onAlertFired?.call(alert);
    }

    if (toFire.isNotEmpty) {
      _saveAlerts(); // persist triggered state
    }
  }

  // ── History ───────────────────────────────────────────────────────────────

  Future<void> _recordHistory(PriceAlert alert, {required double triggeredPrice}) async {
    final entry = AlertHistoryEntry(
      id: '${alert.id}_${DateTime.now().millisecondsSinceEpoch}',
      instrumentToken: alert.instrumentToken,
      symbol: alert.symbol,
      targetPrice: alert.targetPrice,
      triggeredPrice: triggeredPrice,
      condition: alert.condition,
      firedAt: DateTime.now(),
    );
    _history.add(entry);
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alertsKey, jsonEncode(_alerts.map((a) => a.toJson()).toList()));
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(_history.map((e) => e.toJson()).toList()));
  }
}
