import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parvexglobal/services/trade_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/trade_service.dart';

class CloseTradeBottomSheet {
  static Future<void> show(
      BuildContext context, {
        required Trade trade,
        required VoidCallback onClosed,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CloseTradeSheet(trade: trade, onClosed: onClosed),
    );
  }
}

class _CloseTradeSheet extends StatefulWidget {
  const _CloseTradeSheet({required this.trade, required this.onClosed});

  final Trade trade;
  final VoidCallback onClosed;

  @override
  State<_CloseTradeSheet> createState() => _CloseTradeSheetState();
}

class _CloseTradeSheetState extends State<_CloseTradeSheet> {
  late final TextEditingController _priceCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with live price if available, else entry price
    final prefill = widget.trade.livePrice ?? widget.trade.entryPrice;
    _priceCtrl =
        TextEditingController(text: prefill.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  double get _exitPrice => double.tryParse(_priceCtrl.text) ?? 0;

  double get _projectedPnL {
    if (_exitPrice <= 0) return 0;
    final diff = widget.trade.type == TradeType.buy
        ? _exitPrice - widget.trade.entryPrice
        : widget.trade.entryPrice - _exitPrice;
    return diff * widget.trade.quantity;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await TradeService.instance.closeTrade(widget.trade, _exitPrice);
    if (mounted) {
      Navigator.pop(context);
      widget.onClosed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final isBuy = widget.trade.type == TradeType.buy;
    final accentColor =
    isBuy ? const Color(0xFF1E7D3A) : const Color(0xFFCC2929);
    final pnl = _projectedPnL;
    final pnlColor =
    pnl >= 0 ? const Color(0xFF1E7D3A) : const Color(0xFFCC2929);
    final pnlBg =
    pnl >= 0 ? const Color(0xFFD6F3E0) : const Color(0xFFF9D6D6);

    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.trade.symbol,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${isBuy ? 'BUY' : 'SELL'}  ·  ${widget.trade.quantity} qty  ·  Entry ₹${widget.trade.entryPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isBuy ? 'CLOSE LONG' : 'COVER SHORT',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Price input ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter exit price';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Must be > 0';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Exit Price (₹)',
                    labelStyle: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.grey.shade200, width: 0.8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.grey.shade200, width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF1F63FF), width: 1.5),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Projected P&L banner ──────────────────────────────────────────
            if (_exitPrice > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: pnlBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Projected P&L',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${pnl >= 0 ? '+' : ''}₹${pnl.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: pnlColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ── Confirm button ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                      AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : Text(
                    isBuy ? 'Confirm Close' : 'Confirm Cover',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}