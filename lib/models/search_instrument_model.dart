class SearchInstrumentModel {
  final int instrumentId;
  final String name;
  final String exchange;
  final String symbol;

  bool isAdded;

  SearchInstrumentModel({
    required this.instrumentId,
    required this.name,
    required this.exchange,
    required this.symbol,
    this.isAdded = false,
  });

  factory SearchInstrumentModel.fromJson(Map<String, dynamic> json) {
    return SearchInstrumentModel(
      instrumentId: json['instrumentId'],
      name: json['name'],
      exchange: json['exchange'],
      symbol: json['symbol'],
      isAdded: false, // default
    );
  }
}