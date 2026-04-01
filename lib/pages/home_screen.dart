import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:parvexglobal/extension/extension_functions.dart';
import 'package:parvexglobal/helper/bottom_navigation_bar.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../services/websocket_service.dart';
import 'add_instrument.dart';
import 'instrument_detail.dart';
import 'profile.dart'; // Ensure this matches your profile file name

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WebSocketService _wsService = WebSocketService();

  final _tabs = const ["All", "NFO", "MCX", "COMEX", "UAE"];

  int _selectedTab = 0;

  StompClient? stompClient;
  List<Map<String, dynamic>> ticks = [];



  late final List<_WatchItem> _items = [
    _WatchItem(
      iconBg: const Color(0xFFE9FFF4),
      icon: "🇦🇪",
      title: "UAE Gold",
      subtitle1: "UAE · Commodity · per gram",
      subtitle2: "",
      price: "AED 218",
      change: "0.55%",
      changeUp: true,
      added: true,
      currencyStyle: _CurrencyStyle.aed, symbol: 'MCX',
    ),
  ];

  @override
  void initState() {
    super.initState();
    connectWebSocket();
  }

  void connectWebSocket() {
    stompClient = StompClient(
      config: StompConfig.SockJS(
        url:
        'http://marketwatch-env.eba-i9huczsw.eu-north-1.elasticbeanstalk.com/ws',
        onConnect: onConnect,
        // onError: (error) => print('Error: $error'),
      ),
    );

    stompClient!.activate();
  }

  void onConnect(StompFrame frame) {
    print("Connected");

    stompClient!.subscribe(
      destination: '/topic/ticks/all',
      callback: (frame) {
        if (frame.body != null) {
          final tick = jsonDecode(frame.body!);

          setState(() {
            print(tick.toString());
            ticks.insert(0, tick);
          });
        }
      },
    );
  }

  @override
  void dispose() {
    stompClient?.deactivate();
    super.dispose();
  }

  void _handleLiveData(dynamic data) {
    print("LIVE => $data");

    /*
   EXPECTED (example)
   {
     "symbol": "GOLD",
     "price": 62840,
     "change": -12
   }
  */

    final symbol = data['symbol'];

    final index = _items.indexWhere((e) => e.symbol == symbol);

    if (index != -1) {
      setState(() {
        final price = data['price'];
        final change = data['change'];

        _items[index].price = "₹$price";
        _items[index].change = "$change (${data['percent'] ?? ''}%)";
        _items[index].changeUp = change >= 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: RichText(
          text: const TextSpan(
            text: 'Bhav',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
            children: [TextSpan(text: 'Tav', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 20))],
          ),
        ),
        actions: [
          // _buildAppBarAction(Icons.notifications_none_outlined, () {}),
          _buildAppBarAction(Icons.search, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddInstrument()));
          }),
          const Padding(
            padding: EdgeInsets.only(right: 16, left: 8),
            child: CircleAvatar(backgroundColor: Color(0xFF2979FF), child: Text('AS', style: TextStyle(color: Colors.white, fontSize: 14))),
          ).onClick(() => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddInstrument()));
        },
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Ticker Tape
            // Container(
            //   height: 45,
            //   color: const Color(0xFF101828),
            //   child: ListView(
            //     scrollDirection: Axis.horizontal,
            //     padding: const EdgeInsets.symmetric(horizontal: 10),
            //     children: [
            //       _buildTickerItem('NIFTY', '22,450', '0.42%', true),
            //       _buildTickerItem('SENSEX', '73,950', '0.34%', true),
            //       _buildTickerItem('GOLD', '62,840', '0.31%', false),
            //       _buildTickerItem('SILVER', '74,130', '1.15%', true),
            //     ],
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Market Pulse Section
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     const Text('Market Pulse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  //     TextButton(onPressed: () {
                  //       Navigator.push(context, MaterialPageRoute(builder: (context) => const AddInstrument()));
                  //     }, child: const Text('See all →', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                  //   ],
                  // ),
                  // const SizedBox(height: 8),
                  // SizedBox(
                  //   height: 100,
                  //   child: ListView(
                  //     scrollDirection: Axis.horizontal,
                  //     children: [
                  //       _buildPulseCard('NIFTY 50', '22,450', '0.42%', true),
                  //       _buildPulseCard('BANK NIFTY', '47,820', '0.18%', false),
                  //       _buildPulseCard('MCX GOLD', '62,840', '0.31%', false),
                  //     ],
                  //   ),
                  // ),
                  //
                  // const SizedBox(height: 18),

                  // 3. Watchlist Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('My WatchList', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddInstrument()));
                        },
                        child: const Text('+ Add', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                ],
              ),
            ),

            Container(
              color: Colors.white,
              padding:   EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final selected = i == _selectedTab;
                    return _ChipTab(label: _tabs[i], selected: selected, onTap: () => setState(() => _selectedTab = i));
                  },
                ),
              ),
            ),

            Column(
              children: ticks.map((item) {
                return _buildWatchlistCard(
                  context,
                  title: item["tradingSymbol"],
                  tags: [],
                  price: item["lastPrice"].toString(),
                  change: "TEst",
                  isPositive: true,
                  accentColor: Colors.blue,
                  details: {
                    "PREV CLOSE": "-",
                    "OPEN": "-",
                    "H": "-",
                    "L": "-",
                    "LTP": "Test",
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      // --- UPDATED BOTTOM NAV ---
      // bottomNavigationBar: CustomBottomNavBar(currentIndex: 0),
    );
  }

  // --- ALL YOUR ORIGINAL UI METHODS UNTOUCHED ---
  Widget _buildAppBarAction(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: Colors.black54, size: 20), onPressed: onTap),
    );
  }

  Widget _buildTickerItem(String name, String price, String percent, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        children: [
          Text('$name ', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Icon(isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: isPositive ? Colors.green : Colors.red, size: 18),
          Text(price, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPulseCard(String title, String price, String percent, bool isPositive) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Icon(isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: isPositive ? Colors.green : Colors.red, size: 16),
              Text(percent, style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistCard(
    BuildContext context, {
    required String title,
    required List<String> tags,
    required String price,
    required String change,
    required bool isPositive,
    required Color accentColor,
    required Map<String, String> details,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const InstrumentDetailScreen()));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0,  vertical: 6.0),
        margin: const EdgeInsets.only(bottom: 2),
        color: Colors.white,
        // decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(spacing: 4, runSpacing: -6, children: tags.map((t) => _buildTag(t)).toList()),
                _buildDetailItem("LTP : ", "₹62,950", isHighlight: true),
              ],
            ),
            // SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Container(width: 3, height: 36, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
                // const SizedBox(width: 8),
                /// LEFT SIDE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),

                /// RIGHT SIDE
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(price, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    Text('${isPositive ? '▲' : '▼'} $change', style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),

            // const Divider(height: 1),

            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem("PREV CLOSE : ", "₹60,050"),
                _buildDetailItem("OPEN : ", "₹62,950"),
                _buildDetailItem("H : ", "₹62,950"),
                _buildDetailItem("L : ", "₹62,950", isHighlight: true),
              ],
            ),

            /// DETAILS GRID
            // Container(
            //   // color: Colors.yellow,
            //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            //   child: Column(
            //     children: [
            //       Row(
            //         children:
            //             details.entries.take(3).map((entry) {
            //               return Expanded(child: _buildDetailItem(entry.key, entry.value, isHighlight: entry.key == 'LTP'));
            //             }).toList(),
            //       ),
            //       const SizedBox(height: 6),
            //       Row(
            //         children:
            //             details.entries.skip(3).take(3).map((entry) {
            //               return Expanded(child: _buildDetailItem(entry.key, entry.value, isHighlight: entry.key == 'LTP'));
            //             }).toList(),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    bool isDate = label.contains('2025');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: isDate ? Colors.orange.shade50 : Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: isDate ? Colors.orange.shade700 : Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(width: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isHighlight ? Colors.red.shade400 : Colors.black87)),
      ],
    );
  }
}

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
          // boxShadow: selected
          //     ? [
          //   BoxShadow(
          //     color: const Color(0xFF1F63FF).withOpacity(0.18),
          //     blurRadius: 14,
          //     offset: const Offset(0, 6),
          //   )
          // ]
          //     : null,
        ),
        child: Center(child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12))),
      ),
    );
  }
}
class _WatchItem {
  _WatchItem({
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle1,
    required this.subtitle2,
    required this.price,
    required this.change,
    required this.changeUp,
    required this.added,
    required this.currencyStyle,
    required this.symbol
  });

  final Color iconBg;
  final String icon;
  final String title;
  final String subtitle1;
  final String subtitle2;
  String price;
  String change;
  bool changeUp;
  bool added;
  final _CurrencyStyle currencyStyle;
  final String symbol;
}
enum _CurrencyStyle { rupee, dollar, aed, plain }

