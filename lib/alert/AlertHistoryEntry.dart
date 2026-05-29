import 'package:parvexglobal/alert/AlertCondition.dart';

class AlertHistoryEntry {
  final String id;
  final int instrumentToken;
  final String symbol;
  final double targetPrice;
  final double triggeredPrice;
  final AlertCondition condition;
  final DateTime firedAt;
  final bool fired;

  AlertHistoryEntry({
    required this.id,
    required this.instrumentToken,
    required this.symbol,
    required this.targetPrice,
    required this.triggeredPrice,
    required this.condition,
    required this.firedAt,
    this.fired = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'token': instrumentToken,
    'symbol': symbol,
    'targetPrice': targetPrice,
    'triggeredPrice': triggeredPrice,
    'condition': condition.name,
    'firedAt': firedAt.toIso8601String(),
    'fired': fired,
  };

  factory AlertHistoryEntry.fromJson(Map<String, dynamic> j) => AlertHistoryEntry(
    id: j['id'],
    instrumentToken: j['token'],
    symbol: j['symbol'],
    targetPrice: j['targetPrice'],
    triggeredPrice: j['triggeredPrice'],
    condition: AlertCondition.values.byName(j['condition']),
    firedAt: DateTime.parse(j['firedAt']),
    fired: j['fired'] ?? true,
  );
}