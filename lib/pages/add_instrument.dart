import 'dart:async';

import 'package:flutter/material.dart';

import '../helper/bottom_navigation_bar.dart';
import '../models/search_instrument_model.dart';
import '../services/RestApiServices.dart';
import '../utils/user_session.dart';

class AddInstrument extends StatefulWidget {
  const AddInstrument({super.key});

  @override
  State<AddInstrument> createState() => _AddInstrumentState();
}

class _AddInstrumentState extends State<AddInstrument> {
  int _selectedTab = 0;

  int _requestId = 0;
  String _lastQuery = "";

  final TextEditingController searchController = TextEditingController();

  List<SearchInstrumentModel> fullList = [];
  List<SearchInstrumentModel> searchResults = [];
  bool isLoading = false;

  Timer? _debounce;

  void onSearchChanged(String value) {
    _lastQuery = value;
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchInstrument(value);
    });
  }

  final _tabs = const ["All", "NSE", "NFO", "MCX"];

  late final List<_WatchItem> _items = [
    _WatchItem(
      iconBg: const Color(0xFFFFF7E6),
      icon: "🥇",
      title: "Gold",
      subtitle1: "MCX · Commodity · Dec 2025",
      subtitle2: "Lot 100g",
      price: "₹62,840",
      change: "0.32%",
      changeUp: false,
      added: false,
      currencyStyle: _CurrencyStyle.rupee,
    ),
    _WatchItem(
      iconBg: const Color(0xFFF3F6FB),
      icon: "🥈",
      title: "Silver",
      subtitle1: "MCX · Commodity · Dec 2025",
      subtitle2: "Lot 30kg",
      price: "₹74,120",
      change: "1.10%",
      changeUp: true,
      added: false,
      currencyStyle: _CurrencyStyle.rupee,
    ),
    _WatchItem(
      iconBg: const Color(0xFFE9FFF4),
      icon: "📈",
      title: "Nifty 50",
      subtitle1: "NFO · Futures · 28 Nov · Lot 50",
      subtitle2: "",
      price: "22,450",
      change: "0.42%",
      changeUp: true,
      added: true,
      currencyStyle: _CurrencyStyle.plain,
    ),
    _WatchItem(
      iconBg: const Color(0xFFFFF1F1),
      icon: "🏦",
      title: "BankNifty",
      subtitle1: "NFO · Futures · 28 Nov · Lot 15",
      subtitle2: "",
      price: "47,820",
      change: "0.18%",
      changeUp: false,
      added: true,
      currencyStyle: _CurrencyStyle.plain,
    ),
    _WatchItem(
      iconBg: const Color(0xFFFFF7E6),
      icon: "🌐",
      title: "Comex Gold",
      subtitle1: "COMEX · Commodity · Dec 2025",
      subtitle2: "Lot 100oz",
      price: "\$2,042",
      change: "0.55%",
      changeUp: true,
      added: false,
      currencyStyle: _CurrencyStyle.dollar,
    ),
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
      currencyStyle: _CurrencyStyle.aed,
    ),
  ];

  final int _bottomIndex = 0;

  Future<void> searchInstrument(String query) async {
    if (query.isEmpty  && _lastQuery.isEmpty) return;

    final int requestId = ++_requestId; // 🔥 ADD THIS

    setState(() {
      isLoading = true;
    });

    try {
      final api = RestApiService();

      final results = await api.searchInstruments(query: query, exchange: _tabs[_selectedTab]);

      // ❗ IMPORTANT: Ignore old responses
      if (requestId != _requestId) return;

      setState(() {
        searchResults = results;
      });
    } catch (e) {
      print(e);
    } finally {
      // ❗ also protect loading state
      if (requestId == _requestId) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }


  Future<void> loadInstrumentsByTab() async {
    setState(() {
      isLoading = true;
    });

    try {
      final api = RestApiService();

      final results = await api.searchInstruments(
        query: "",
        exchange: _tabs[_selectedTab],
      );

      setState(() {
        fullList = results;
        searchResults = results;
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadInstrumentsByTab();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF8F8F8);
    const card = Colors.white;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      // bottomNavigationBar:CustomBottomNavBar(currentIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            // Top app bar
            Container(
              color: Colors.white,
              padding: EdgeInsets.only(left: 16, top: 10, right: 16),
              child: Row(
                children: [
                  _IconPillButton(icon: Icons.arrow_back, onTap: () => Navigator.maybePop(context)),
                  const SizedBox(width: 10),
                  const Expanded(child: Text("Add to Watchlist", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0D1B2A)))),
                  // _IconPillButton(icon: Icons.settings, onTap: () {}),
                ],
              ),
            ),

            // Search
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 14),
              child: _SearchField(hintText: "Search instrument, symbol...", onChanged: onSearchChanged),
            ),

            // Tabs
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final selected = i == _selectedTab;
                    return _ChipTab(
                      label: _tabs[i],
                      selected: selected,
                      onTap: () {
                        setState(() {
                          _selectedTab = i;
                          _lastQuery = "";
                          searchController.clear();
                        });

                        _requestId++;
                        loadInstrumentsByTab();
                      },
                    );
                  },
                ),
              ),
            ),

            // List
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : searchResults.isEmpty
                      ? const Center(child: Text("No results found"))
                      : ListView.separated(
                        itemCount: searchResults.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final item = searchResults[i];

                          print(searchResults[i]);

                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text("${item.exchange} • ${item.symbol}"),
                            trailing:
                                item.isLoading
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : IconButton(
                                      icon: Icon(item.subscription ? Icons.close : Icons.add, color: item.subscription ? Colors.red : Colors.green),
                                      onPressed: () async {
                                        final api = RestApiService();

                                        setState(() {
                                          item.isLoading = true;
                                        });

                                        try {
                                          if (item.subscription) {
                                            /// REMOVE
                                            final success = await api.removeFromWatchlist(instrumentId: item.instrumentId);

                                            if (success) {
                                              item.subscription = false;

                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removed from Watchlist"), duration: Duration(seconds: 1)));
                                               searchInstrument(_lastQuery);
                                            }
                                          } else {
                                            /// ADD
                                            print(item.instrumentId);
                                            print("addition requested");
                                            final success = await api.addToWatchlist(instrumentId: item.instrumentId);

                                            if (success) {
                                              item.subscription = true;

                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Watchlist"), duration: Duration(seconds: 1)));
                                            } else {
                                              /// Handle duplicate case (your API bug)
                                              item.subscription = true;

                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Already in Watchlist")));
                                            }
                                          }
                                        } catch (e) {
                                          print(e);

                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Something went wrong")));
                                        } finally {
                                          setState(() {
                                            item.isLoading = false;
                                          });
                                        }
                                      },
                                    ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hintText, required this.onChanged});

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE0E7F1))),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF0D1B2A)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: const TextStyle(color: Color(0xFF9AA8BD), fontWeight: FontWeight.w500),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // const Text(
          //   "⌘K",
          //   style: TextStyle(
          //     color: Color(0xFF9AA8BD),
          //     fontWeight: FontWeight.w700,
          //   ),
          // ),
        ],
      ),
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

class _IconPillButton extends StatelessWidget {
  const _IconPillButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 46,
        height: 46,
        // decoration: BoxDecoration(color: const Color(0xFFF1F5FB), borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: const Color(0xFF0D1B2A)),
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
  });

  final Color iconBg;
  final String icon;
  final String title;
  final String subtitle1;
  final String subtitle2;
  final String price;
  final String change;
  final bool changeUp;
  bool added;
  final _CurrencyStyle currencyStyle;
}

class _WatchTile extends StatelessWidget {
  const _WatchTile({required this.item, required this.onToggle});

  final _WatchItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isAdded = item.added;

    return Container(
      padding: const EdgeInsets.only(bottom: 6, left: 14, right: 14, top: 6),
      color: Colors.white,
      child: Row(
        children: [
          /// Title
          Expanded(child: Text(item.title.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2B2B2B)))),

          /// Exchange label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(6)),
            child: const Text("INDICES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
          ),

          const SizedBox(width: 12),

          // /// Chart button
          // Container(
          //   width: 36,
          //   height: 36,
          //   decoration: BoxDecoration(
          //     border: Border.all(color: Colors.grey.shade300),
          //     borderRadius: BorderRadius.circular(6),
          //   ),
          //   child: const Icon(
          //     Icons.show_chart,
          //     size: 20,
          //     color: Colors.black54,
          //   ),
          // ),
          //
          // const SizedBox(width: 8),
          //
          // /// List button
          // Container(
          //   width: 36,
          //   height: 36,
          //   decoration: BoxDecoration(
          //     border: Border.all(color: Colors.grey.shade300),
          //     borderRadius: BorderRadius.circular(6),
          //   ),
          //   child: const Icon(
          //     Icons.format_list_bulleted,
          //     size: 20,
          //     color: Colors.black54,
          //   ),
          // ),
          //
          // const SizedBox(width: 8),

          /// Add button
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: isAdded ? Colors.grey[200] : Color(0xFF2FB344), borderRadius: BorderRadius.circular(4)),
              child: Icon(
                // Icons.add,
                isAdded ? Icons.close : Icons.add,
                color: isAdded ? const Color(0xFFFF3B5C) : Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1F63FF),
            unselectedItemColor: const Color(0xFF9AA8BD),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: "Markets"),
              BottomNavigationBarItem(icon: SizedBox(width: 1), label: ""), // space for FAB
              BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "Alerts"),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
            ],
          ),
          Positioned(top: -26, child: _CenterFab(onTap: () {})),
        ],
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  const _CenterFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF00C389),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: const Color(0xFF00C389).withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 10))],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 30),
      ),
    );
  }
}

enum _CurrencyStyle { rupee, dollar, aed, plain }
