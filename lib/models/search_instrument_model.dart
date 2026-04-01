class SearchInstrumentModel {
  final int instrumentId;
  final String name;
  final String symbol;
  final String exchange;

  bool subscription; // from API (or default)
  bool isLoading;    // UI state

  SearchInstrumentModel({
    required this.instrumentId,
    required this.name,
    required this.symbol,
    required this.exchange,
    required this.subscription,
    required this.isLoading,
  });

  factory SearchInstrumentModel.fromJson(Map<String, dynamic> json) {
    return SearchInstrumentModel(
      instrumentId: json['instrumentId'],
      name: json['name'] ?? "",
      symbol: json['symbol'] ?? "",
      exchange: json['exchange'] ?? "",

      // 🔥 VERY IMPORTANT
      subscription: json['subscription'] ?? false,

      // 🔥 UI only
      isLoading: false,
    );
  }
}