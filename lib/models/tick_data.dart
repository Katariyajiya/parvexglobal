class TickData {
  final int    id;
  int          instrumentToken;
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
  final int    timestamp;

  // ── New fields ─────────────────────────────────────────────────────────────
  final String?  name;
  final String?  instrumentType;
  final String?  segment;
  final String?  expiryDate;
  final double?  strikePrice;
  final double   tickSize;
  final int      lotSize;
  final int      exchangeToken;

  TickData({
    required this.id,
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
    this.name,
    this.instrumentType,
    this.segment,
    this.expiryDate,
    this.strikePrice,
    this.tickSize    = 0.0,
    this.lotSize     = 1,
    this.exchangeToken = 0,
  });

  factory TickData.fromJson(Map<String, dynamic> j) => TickData(
    id:              (j['id']              as num?)?.toInt()    ?? 0,
    instrumentToken: (j['instrumentToken'] as num?)?.toInt()    ?? 0,
    tradingSymbol:    j['tradingSymbol']   as String?           ?? '',
    exchange:         j['exchange']        as String?           ?? '',
    lastPrice:       (j['lastPrice']       as num?)?.toDouble() ?? 0.0,
    change:          (j['change']          as num?)?.toDouble() ?? 0.0,
    changePercent:   (j['changePercent']   as num?)?.toDouble() ?? 0.0,
    open:            (j['open']            as num?)?.toDouble() ?? 0.0,
    high:            (j['high']            as num?)?.toDouble() ?? 0.0,
    low:             (j['low']             as num?)?.toDouble() ?? 0.0,
    close:           (j['close']           as num?)?.toDouble() ?? 0.0,
    volume:          (j['volume']          as num?)?.toDouble() ?? 0.0,
    buyQuantity:     (j['buyQuantity']     as num?)?.toDouble() ?? 0.0,
    sellQuantity:    (j['sellQuantity']    as num?)?.toDouble() ?? 0.0,
    timestamp:       (j['timestamp']       as num?)?.toInt()    ?? 0,
    name:             j['name']            as String?,
    instrumentType:   j['instrumentType']  as String?,
    segment:          j['segment']         as String?,
    expiryDate:       j['expiryDate']      as String?,
    strikePrice:     (j['strikePrice']     as num?)?.toDouble(),
    tickSize:        (j['tickSize']        as num?)?.toDouble() ?? 0.0,
    lotSize:         (j['lotSize']         as num?)?.toInt()    ?? 1,
    exchangeToken:   (j['exchangeToken']   as num?)?.toInt()    ?? 0,
  );

  bool get isUp => change >= 0;
}