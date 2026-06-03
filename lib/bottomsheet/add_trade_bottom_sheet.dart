import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:parvexglobal/services/trade_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/trade_service.dart';

/// Shows the "Add Trade" bottom sheet.
///
/// [symbol]          — trading symbol (e.g. "NIFTY25JUNFUT")
/// [instrumentToken] — numeric token from the tick map
/// [currentPrice]    — live last-price from HomeScreen tick; pre-fills the
///                     price field so the user sees the real market price.
class AddTradeBottomSheet {
  static Future<void> show(
      BuildContext context, {
        required String symbol,
        required int instrumentToken,
        required double currentPrice,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTradeSheet(
        symbol: symbol,
        instrumentToken: instrumentToken,
        currentPrice: currentPrice,
      ),
    );
  }
}

class _AddTradeSheet extends StatefulWidget {
  const _AddTradeSheet({
    required this.symbol,
    required this.instrumentToken,
    required this.currentPrice,
  });

  final String symbol;
  final int instrumentToken;
  final double currentPrice;

  @override
  State<_AddTradeSheet> createState() => _AddTradeSheetState();
}

class _AddTradeSheetState extends State<_AddTradeSheet> {
  TradeType _type = TradeType.buy;
  final _qtyCtrl = TextEditingController(text: '1');
  late final TextEditingController _priceCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with live market price. If 0 (opened from ledger FAB), leave blank.
    _priceCtrl = TextEditingController(
      text: widget.currentPrice > 0
          ? widget.currentPrice.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // Derived: total trade value
  double get _totalValue {
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    return qty * price;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final qty = int.parse(_qtyCtrl.text.trim());
    final price = double.parse(_priceCtrl.text.trim());

    await TradeService.instance.addTrade(
      symbol: widget.symbol,
      instrumentToken: widget.instrumentToken,
      type: _type,
      quantity: qty,
      entryPrice: price,
      currentLivePrice: widget.currentPrice > 0 ? widget.currentPrice : price,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final isBuy = _type == TradeType.buy;
    final accentColor =
    isBuy ? const Color(0xFF1E7D3A) : const Color(0xFFCC2929);
    final accentBg =
    isBuy ? const Color(0xFFF0FBF4) : const Color(0xFFFDF0F0);

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
            // ── Drag handle ──────────────────────────────────────────────────
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
                        widget.symbol,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (widget.currentPrice > 0)
                        Text(
                          'LTP  ₹${widget.currentPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  // Live price badge
                  if (widget.currentPrice > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F63FF).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹${widget.currentPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF1F63FF),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── BUY / SELL toggle ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _typeBtn(TradeType.buy, 'BUY', const Color(0xFF1E7D3A),
                        const Color(0xFFD6F3E0)),
                    _typeBtn(TradeType.sell, 'SELL', const Color(0xFFCC2929),
                        const Color(0xFFF9D6D6)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Form ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Quantity
                    _field(
                      label: 'Quantity (lots / shares)',
                      controller: _qtyCtrl,
                      inputType: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter quantity';
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) return 'Must be > 0';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    // Price
                    _field(
                      label: 'Entry Price (₹)',
                      controller: _priceCtrl,
                      inputType:
                      const TextInputType.numberWithOptions(decimal: true),
                      formatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter price';
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return 'Must be > 0';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Trade summary ─────────────────────────────────────────────────
            if (_totalValue > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withOpacity(0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Trade Value',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${_totalValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ── Submit button ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
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
                    isBuy ? 'Add BUY Trade' : 'Add SELL Trade',
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

  Widget _typeBtn(
      TradeType type, String label, Color selectedFg, Color selectedBg) {
    final active = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active
                ? Border.all(color: selectedFg.withOpacity(0.4), width: 1)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? selectedFg : Colors.grey.shade500,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required TextInputType inputType,
    required List<TextInputFormatter> formatters,
    required String? Function(String?) validator,
    required void Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: formatters,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        TextStyle(fontSize: 13, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: Color(0xFF1F63FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: Color(0xFFCC2929), width: 1),
        ),
      ),
    );
  }
}