class TickData {
  final int id;
  final int instrumentToken;
  final String tradingSymbol;
  final String exchange;
  final double lastPrice;
  final double change;
  final double changePercent;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final double buyQuantity;
  final double sellQuantity;
  final int timestamp;

  TickData({
    required this.instrumentToken,
    required this.tradingSymbol,
    required this.exchange,
    required this.lastPrice,
    required this.change,
    required this.changePercent,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.buyQuantity,
    required this.sellQuantity,
    required this.timestamp,
    required this.id,
  });

  factory TickData.fromJson(Map<String, dynamic> j) {
    return TickData(
      instrumentToken: (j['instrumentToken'] ?? 0) as int,
      tradingSymbol: (j['tradingSymbol'] ?? '') as String,
      exchange: ((j['exchange'] ?? j['segment'] ?? '') as String).toUpperCase(),
      lastPrice: (j['lastPrice'] ?? 0).toDouble(),
      change: (j['change'] ?? 0).toDouble(),
      changePercent: (j['changePercent'] ?? 0).toDouble(),
      open: (j['open'] ?? 0).toDouble(),
      high: (j['high'] ?? 0).toDouble(),
      low: (j['low'] ?? 0).toDouble(),
      close: (j['close'] ?? 0).toDouble(),
      volume: (j['volume'] ?? 0).toDouble(),
      buyQuantity: (j['buyQuantity'] ?? 0).toDouble(),
      sellQuantity: (j['sellQuantity'] ?? 0).toDouble(),
      timestamp: (j['timestamp'] ?? 0) as int,
      id: (j['id'] ?? 0) as int,
    );
  }

  bool get isUp => change >= 0;
}