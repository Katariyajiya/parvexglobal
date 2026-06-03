import 'package:parvexglobal/alert/AlertCondition.dart';
import 'package:parvexglobal/alert/AlertDirection.dart';

class PriceAlert {
  final String id;
  final int instrumentToken;
  final String symbol;
  final double targetPrice;
  final AlertCondition condition;
  bool triggered;
  AlertDirection direction;
  AlertType? alertType;

  PriceAlert({
    required this.id,
    required this.instrumentToken,
    required this.symbol,
    required this.targetPrice,
    required this.condition,
    required this.direction,
    this.triggered = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'token': instrumentToken,
    'symbol': symbol,
    'targetPrice': targetPrice,
    'condition': condition.name,
    'triggered': triggered,
  };

  factory PriceAlert.fromJson(Map<String, dynamic> j) => PriceAlert(
    id: j['id'],
    instrumentToken: j['token'],
    symbol: j['symbol'],
    targetPrice: j['targetPrice'],
    condition: AlertCondition.values.byName(j['condition']),
    triggered: j['triggered'] ?? false,
    direction: j['direction'] ?? AlertDirection.above,
  );

}
