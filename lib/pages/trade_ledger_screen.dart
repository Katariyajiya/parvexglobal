import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parvexglobal/bottomsheet/add_trade_bottom_sheet.dart';
import 'package:parvexglobal/bottomsheet/close_trade_bottom_sheet.dart';

import '../services/trade_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parvexglobal/bottomsheet/add_trade_bottom_sheet.dart';
import 'package:parvexglobal/bottomsheet/close_trade_bottom_sheet.dart';

import '../services/trade_service.dart';

// ── Avatar colors (mirrors HomeScreen palette) ────────────────────────────────
const _avatarColors = [
  (bg: Color(0xFF4CAF50), text: Colors.white),
  (bg: Color(0xFF1F63FF), text: Colors.white),
  (bg: Color(0xFFE48C1A), text: Colors.white),
  (bg: Color(0xFF9C27B0), text: Colors.white),
  (bg: Color(0xFFE53935), text: Colors.white),
  (bg: Color(0xFF00ACC1), text: Colors.white),
];

({Color bg, Color text}) _avatarStyle(String symbol) =>
    _avatarColors[symbol.hashCode.abs() % _avatarColors.length];

// ── Screen ────────────────────────────────────────────────────────────────────

class TradeLedgerScreen extends StatefulWidget {
  const TradeLedgerScreen({super.key});

  @override
  State<TradeLedgerScreen> createState() => _TradeLedgerScreenState();
}

class _TradeLedgerScreenState extends State<TradeLedgerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _service = TradeService.instance;

  static const _tabs = ['Open Trades', 'Closed Trades', 'Reports'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _tab.addListener(() => setState(() {}));
    _load();
  }

  Future<void> _load() async {
    await _service.load();
    // No setState needed — TradeService is a ChangeNotifier and
    // ListenableBuilder handles rebuilds automatically.
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Summary banner ─────────────────────────────────────────────────────────

  Widget _buildSummaryBanner() {
    // TradeService is a ChangeNotifier — ListenableBuilder keeps this live.
    return ListenableBuilder(
      listenable: _service,
      builder: (_, __) {
        final open = _service.openTrades.length;
        final closed = _service.closedTrades.length;
        final openMTM = _service.openMTM;
        final realised = _service.realisedPnL;
        final total = _service.totalPnL;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1F63FF), Color(0xFF0A3FBA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1F63FF).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Today's Summary",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total P&L  ${total >= 0 ? '+' : ''}₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _summaryMetric('Open Trades', '$open', Colors.white),
                  _summaryDivider(),
                  _summaryMetric(
                    'Open MTM',
                    '${openMTM >= 0 ? '+' : ''}₹${openMTM.toStringAsFixed(0)}',
                    openMTM >= 0
                        ? const Color(0xFF80E8A0)
                        : const Color(0xFFFF9090),
                  ),
                  _summaryDivider(),
                  _summaryMetric('Closed', '$closed', Colors.white),
                  _summaryDivider(),
                  _summaryMetric(
                    'Realised',
                    '${realised >= 0 ? '+' : ''}₹${realised.toStringAsFixed(0)}',
                    realised >= 0
                        ? const Color(0xFF80E8A0)
                        : const Color(0xFFFF9090),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryMetric(String label, String value, Color valueColor) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ],
      );

  Widget _summaryDivider() => Container(
    width: 1,
    height: 28,
    color: Colors.white.withOpacity(0.2),
  );

  // ── Tab bar ────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tab,
        indicator: BoxDecoration(
          color: const Color(0xFF1F63FF),
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF55657C),
        labelStyle:
        const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSummaryBanner(),
          _buildTabBar(),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // Open trades — rebuilt live via ListenableBuilder inside
                _OpenTradesTab(service: _service),
                // Closed trades — rebuilt on service notify
                _ClosedTradesTab(service: _service),
                // Reports — rebuilt on service notify
                _ReportsTab(service: _service),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tab.index == 0
          ? FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1F63FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Trade',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        onPressed: _showAddTrade,
      )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: const BackButton(color: Colors.black),
      title: RichText(
        text: const TextSpan(
          text: 'Trade ',
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20),
          children: [
            TextSpan(
              text: 'Ledger',
              style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTrade() {
    AddTradeBottomSheet.show(
      context,
      symbol: '',
      instrumentToken: 0,
      currentPrice: 0,
    );
  }
}

// ── Open Trades Tab ───────────────────────────────────────────────────────────
// Uses ListenableBuilder so MTM refreshes every time HomeScreen pushes a tick.

class _OpenTradesTab extends StatelessWidget {
  const _OpenTradesTab({required this.service});

  final TradeService service;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final trades = service.openTrades;

        if (trades.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.show_chart,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No open trades',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 15)),
                const SizedBox(height: 6),
                Text('Tap + Add Trade to get started',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 90),
          itemCount: trades.length,
          itemBuilder: (_, i) => _OpenTradeCard(
            trade: trades[i],
            onClosed: () {},   // ListenableBuilder handles rebuild
            onDeleted: () {},
          ),
        );
      },
    );
  }
}

class _OpenTradeCard extends StatelessWidget {
  const _OpenTradeCard({
    required this.trade,
    required this.onClosed,
    required this.onDeleted,
  });

  final Trade trade;
  final VoidCallback onClosed;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final t = trade;
    final isBuy = t.type == TradeType.buy;
    final accentColor =
    isBuy ? const Color(0xFF1E7D3A) : const Color(0xFFCC2929);
    final pillBg =
    isBuy ? const Color(0xFFD6F3E0) : const Color(0xFFF9D6D6);
    final pillText =
    isBuy ? const Color(0xFF1A6E33) : const Color(0xFFB82323);

    final pnl = t.unrealisedPnL;
    final pnlColor =
    pnl >= 0 ? const Color(0xFF1E7D3A) : const Color(0xFFCC2929);
    final pnlBg =
    pnl >= 0 ? const Color(0xFFD6F3E0) : const Color(0xFFF9D6D6);
    final pnlText =
    pnl >= 0 ? const Color(0xFF1A6E33) : const Color(0xFFB82323);

    final av = _avatarStyle(t.symbol);
    final initials = t.symbol.length >= 2
        ? t.symbol.substring(0, 2).toUpperCase()
        : t.symbol;

    // Live price: prefer livePrice, fall back to entryPrice
    final ltp = t.livePrice ?? t.entryPrice;
    final ltpStr = '₹${ltp.toStringAsFixed(2)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBuy
              ? const Color(0xFFB2DFBE)
              : const Color(0xFFF1B8B8),
          width: 0.8,
        ),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.0, 0.08, 0.4, 0.6, 0.92, 1.0],
          colors: [
            accentColor.withOpacity(0.12),
            accentColor.withOpacity(0.06),
            accentColor.withOpacity(0.00),
            accentColor.withOpacity(0.00),
            accentColor.withOpacity(0.06),
            accentColor.withOpacity(0.12),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          children: [
            // ── Top row ──────────────────────────────────────────────────────
            Row(
              children: [
                // Avatar
                Container(
                  width: 34,
                  height: 34,
                  decoration:
                  BoxDecoration(color: av.bg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: TextStyle(
                        color: av.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),

                // Symbol + trade detail
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.symbol,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              isBuy ? 'BUY' : 'SELL',
                              style: TextStyle(
                                  color: pillText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${t.quantity} @ ₹${t.entryPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // LTP + MTM (right side) — this column is what refreshes live
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ltpStr,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: pnlBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'MTM ${pnl >= 0 ? '+' : ''}₹${pnl.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: pnlText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(height: 1, thickness: 0.6, color: Colors.grey.shade200),
            const SizedBox(height: 10),

            // ── Bottom row ────────────────────────────────────────────────────
            Row(
              children: [
                _detailItem('LTP', ltpStr),
                const SizedBox(width: 16),
                _detailItem(
                    'Entry', '₹${t.entryPrice.toStringAsFixed(2)}'),
                const SizedBox(width: 16),
                _detailItem('Qty', '${t.quantity}'),
                const Spacer(),

                // Action button
                GestureDetector(
                  onTap: () => CloseTradeBottomSheet.show(
                    context,
                    trade: t,
                    onClosed: onClosed,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isBuy ? 'Close' : 'Cover',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w400)),
      const SizedBox(height: 2),
      Text(value,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600)),
    ],
  );
}

// ── Closed Trades Tab ─────────────────────────────────────────────────────────

class _ClosedTradesTab extends StatelessWidget {
  const _ClosedTradesTab({required this.service});

  final TradeService service;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final trades = service.closedTrades;
        final fmt = DateFormat('dd-MMM-yy');

        if (trades.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No closed trades yet',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 15)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: trades.length,
          itemBuilder: (_, i) {
            final t = trades[i];
            final isBuy = t.type == TradeType.buy;
            final pnl = t.realisedPnL;
            final pnlColor = pnl >= 0
                ? const Color(0xFF1E7D3A)
                : const Color(0xFFCC2929);
            final pnlBg = pnl >= 0
                ? const Color(0xFFD6F3E0)
                : const Color(0xFFF9D6D6);
            final pillBg = isBuy
                ? const Color(0xFFD6F3E0)
                : const Color(0xFFF9D6D6);
            final pillText = isBuy
                ? const Color(0xFF1A6E33)
                : const Color(0xFFB82323);
            final av = _avatarStyle(t.symbol);
            final initials = t.symbol.length >= 2
                ? t.symbol.substring(0, 2).toUpperCase()
                : t.symbol;

            return Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.grey.shade200, width: 0.8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: av.bg, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(initials,
                        style: TextStyle(
                            color: av.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  const SizedBox(width: 10),

                  // Symbol + details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(t.symbol,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: pillBg,
                                  borderRadius:
                                  BorderRadius.circular(4)),
                              child: Text(isBuy ? 'BUY' : 'SELL',
                                  style: TextStyle(
                                      color: pillText,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${t.quantity} @ ₹${t.entryPrice.toStringAsFixed(2)}  →  ₹${t.exitPrice?.toStringAsFixed(2) ?? '—'}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  // P&L chip + date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: pnlBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${pnl >= 0 ? '+' : ''}₹${pnl.toStringAsFixed(0)}',
                          style: TextStyle(
                              color: pnlColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(t.exitTime ?? t.entryTime),
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Reports Tab ───────────────────────────────────────────────────────────────

class _ReportsTab extends StatelessWidget {
  const _ReportsTab({required this.service});

  final TradeService service;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final closed = service.closedTrades;

        double grossProfit = 0;
        double grossLoss = 0;
        int winners = 0;
        int losers = 0;

        for (final t in closed) {
          final p = t.realisedPnL;
          if (p >= 0) {
            grossProfit += p;
            winners++;
          } else {
            grossLoss += p;
            losers++;
          }
        }

        final winRate =
        closed.isEmpty ? 0.0 : winners / closed.length * 100;
        final netPnL = service.realisedPnL;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _reportCard(
                title: 'P&L Breakdown',
                children: [
                  _reportRow('Gross Profit',
                      '+₹${grossProfit.toStringAsFixed(2)}',
                      const Color(0xFF1E7D3A)),
                  _reportRow(
                      'Gross Loss',
                      '${grossLoss == 0 ? '' : '-'}₹${grossLoss.abs().toStringAsFixed(2)}',
                      const Color(0xFFCC2929)),
                  const Divider(height: 20, thickness: 0.6),
                  _reportRow(
                    'Net Realised P&L',
                    '${netPnL >= 0 ? '+' : ''}₹${netPnL.toStringAsFixed(2)}',
                    netPnL >= 0
                        ? const Color(0xFF1E7D3A)
                        : const Color(0xFFCC2929),
                    bold: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _reportCard(
                title: 'Trade Statistics',
                children: [
                  _reportRow(
                      'Total Closed', '${closed.length}', Colors.black87),
                  _reportRow('Winners', '$winners',
                      const Color(0xFF1E7D3A)),
                  _reportRow(
                      'Losers', '$losers', const Color(0xFFCC2929)),
                  const Divider(height: 20, thickness: 0.6),
                  _reportRow(
                    'Win Rate',
                    '${winRate.toStringAsFixed(1)}%',
                    winRate >= 50
                        ? const Color(0xFF1E7D3A)
                        : const Color(0xFFCC2929),
                    bold: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _reportCard(
                title: 'Live Open MTM',
                children: [
                  _reportRow('Open Positions',
                      '${service.openTrades.length}', Colors.black87),
                  _reportRow(
                    'Unrealised MTM',
                    '${service.openMTM >= 0 ? '+' : ''}₹${service.openMTM.toStringAsFixed(2)}',
                    service.openMTM >= 0
                        ? const Color(0xFF1E7D3A)
                        : const Color(0xFFCC2929),
                    bold: true,
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _reportCard(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100, width: 0.8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _reportRow(String label, String value, Color valueColor,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: bold ? Colors.black87 : Colors.grey.shade600,
                  fontWeight:
                  bold ? FontWeight.w700 : FontWeight.w400)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  color: valueColor,
                  fontWeight:
                  bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}
