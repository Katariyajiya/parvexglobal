import 'package:flutter/material.dart';

import '../helper/bottom_navigation_bar.dart';

class AddInstrument extends StatefulWidget {
  const AddInstrument({super.key});

  @override
  State<AddInstrument> createState() => _AddInstrumentState();
}

class _AddInstrumentState extends State<AddInstrument> {
  int _selectedTab = 0;

  final _tabs = const ["All", "NFO", "MCX", "COMEX", "UAE"];

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

  int _bottomIndex = 0;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF3F6FB);
    const card = Colors.white;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      bottomNavigationBar:CustomBottomNavBar(currentIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            // Top app bar
            Container(
              color: Colors.white,
              padding:  EdgeInsets.only(left:16,top: 25,right:  16,bottom:  14),
              child: Row(
                children: [
                  _IconPillButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Add to Watchlist",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D1B2A),
                      ),
                    ),
                  ),
                  _IconPillButton(
                    icon: Icons.settings,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Search
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16,top: 12,right:  16,bottom:  14),
              child: _SearchField(
                hintText: "Search instrument, symbol...",
                onChanged: (_) {},
              ),
            ),

            // Tabs
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final selected = i == _selectedTab;
                    return _ChipTab(
                      label: _tabs[i],
                      selected: selected,
                      onTap: () => setState(() => _selectedTab = i),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final item = _items[i];
                  return _WatchTile(
                    item: item,
                    onToggle: () => setState(() => item.added = !item.added),
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
  const _SearchField({
    required this.hintText,
    required this.onChanged,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E7F1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF0D1B2A)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF9AA8BD),
                  fontWeight: FontWeight.w600,
                ),
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
  const _ChipTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF1F63FF) : Colors.white;
    final fg = selected ? Colors.white : const Color(0xFF55657C);
    final border = selected ? const Color(0xFF1F63FF) : const Color(0xFFDEE6F1);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
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
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ),
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
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5FB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: const Color(0xFF0D1B2A)),
      ),
    );
  }
}

enum _CurrencyStyle { rupee, dollar, aed, plain }

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
    final bg = isAdded ? const Color(0xFFF2FFF7) : Colors.white;
    final border = isAdded ? const Color(0xFFBFEFD0) : const Color(0xFFE2EAF4);

    return Container(
      width: MediaQuery.sizeOf(context).width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          // Leading icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(item.icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),

          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0D1B2A),
                        ),
                      ),
                    ),
                    if (isAdded) ...[
                      const SizedBox(width: 10),
                      Container(
                        // padding: const EdgeInsets.symmetric(
                        //   horizontal: 10,
                        //   vertical: 6,
                        // ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9FFE8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 16, color: Color(0xFF0AAE6D)),
                            SizedBox(width: 6),
                            Text(
                              "Added",
                              style: TextStyle(
                                color: Color(0xFF0AAE6D),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.subtitle1,
                  style: const TextStyle(
                    color: Color(0xFF5D6E86),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                if (item.subtitle2.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle2,
                    style: const TextStyle(
                      color: Color(0xFF5D6E86),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Right side: price + change + action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.price,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D1B2A),
                ),
              ),
             // const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.changeUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: item.changeUp ? const Color(0xFF0AAE6D) : const Color(0xFFFF3B5C),
                    size: 20,
                  ),
                  Text(
                    item.change,
                    style: TextStyle(
                      color: item.changeUp ? const Color(0xFF0AAE6D) : const Color(0xFFFF3B5C),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Action button (plus / X)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isAdded ? const Color(0xFFFFEFF2) : const Color(0xFF1F63FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAdded ? Icons.close : Icons.add,
                color: isAdded ? const Color(0xFFFF3B5C) : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.onTap,
  });

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
          Positioned(
            top: -26,
            child: _CenterFab(
              onTap: () {},
            ),
          ),
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
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C389).withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 30),
      ),
    );
  }
}