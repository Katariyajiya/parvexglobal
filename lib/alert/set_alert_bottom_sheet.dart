// lib/widgets/set_alert_bottom_sheet.dart
//
// Bottom sheet that lets the user set a price alert for one instrument.
// Shows existing active alerts and allows deletion.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parvexglobal/alert/AlertCondition.dart';
import 'package:parvexglobal/alert/AlertDirection.dart';
import 'package:parvexglobal/alert/PriceAlert.dart';
import 'package:parvexglobal/alert/alert_service.dart';
import 'package:parvexglobal/pages/AlertHistoryScreen.dart';
import 'package:parvexglobal/pages/alert.dart';
// lib/widgets/set_alert_bottom_sheet.dart
//
// Bottom sheet that lets the user set a price alert for one instrument.
// Shows existing active alerts and allows deletion.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parvexglobal/alert/AlertCondition.dart';
import 'package:parvexglobal/alert/AlertDirection.dart';
import 'package:parvexglobal/alert/PriceAlert.dart';
import 'package:parvexglobal/alert/alert_service.dart';
import 'package:parvexglobal/pages/AlertHistoryScreen.dart';
import 'package:parvexglobal/pages/alert.dart';

class SetAlertBottomSheet extends StatefulWidget {
  final int instrumentToken;
  final String symbol;
  final double currentPrice;

  const SetAlertBottomSheet({
    super.key,
    required this.instrumentToken,
    required this.symbol,
    required this.currentPrice,
  });

  /// Convenience launcher.
  static Future<void> show(
      BuildContext context, {
        required int instrumentToken,
        required String symbol,
        required double currentPrice,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SetAlertBottomSheet(
        instrumentToken: instrumentToken,
        symbol: symbol,
        currentPrice: currentPrice,
      ),
    );
  }

  @override
  State<SetAlertBottomSheet> createState() => _SetAlertBottomSheetState();
}

class _SetAlertBottomSheetState extends State<SetAlertBottomSheet> {
  final _priceController = TextEditingController();
  AlertDirection _direction = AlertDirection.above;
  AlertType _alertType = AlertType.Target;
  final _alertService = AlertService.instance;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _addAlert() {
    final raw = _priceController.text.trim();
    final price = double.tryParse(raw);

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    final alert = PriceAlert(
      instrumentToken: widget.instrumentToken,
      symbol: widget.symbol,
      targetPrice: price,
      direction: _direction,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      condition: _direction == AlertDirection.above ? AlertCondition.above : AlertCondition.below,
      // If your PriceAlert model supports AlertType, you can pass it here:
      // type: _alertType,
    );

    _alertService.addAlert(alert);
    _priceController.clear();
    setState(() {}); // rebuild to show new alert in list
  }

  void _deleteAlert(PriceAlert alert) {
    _alertService.removeAlert(alert.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final existing = _alertService.alertsForToken(widget.instrumentToken);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      bottom: true,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        // Padding pushes content up when keyboard opens
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
        // --- NEW: Scrollable body ---
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Title ───────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, color: Color(0xFF1F63FF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Set Alert — ${widget.symbol}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    'LTP ₹${widget.currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── NEW UX: Separated & Identifiable Toggles ────────────

              // 1. Direction Entity
              Text(
                'PRICE DIRECTION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _OptionCard(
                      label: 'Above',
                      icon: Icons.trending_up,
                      selected: _direction == AlertDirection.above,
                      color: Colors.green,
                      onTap: () => setState(() => _direction = AlertDirection.above),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OptionCard(
                      label: 'Below',
                      icon: Icons.trending_down,
                      selected: _direction == AlertDirection.below,
                      color: Colors.red,
                      onTap: () => setState(() => _direction = AlertDirection.below),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 2. Type Entity (Target vs Stoploss)
              Text(
                'ALERT PURPOSE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _OptionCard(
                      label: 'Target',
                      icon: Icons.my_location_outlined,
                      selected: _alertType == AlertType.Target,
                      color: const Color(0xFF1F63FF), // Distinct Blue
                      onTap: () => setState(() => _alertType = AlertType.Target),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OptionCard(
                      label: 'Stoploss',
                      icon: Icons.security_outlined,
                      selected: _alertType == AlertType.Stoploss,
                      color: Colors.deepOrange, // Distinct Orange
                      onTap: () => setState(() => _alertType = AlertType.Stoploss),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Price input ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                      decoration: InputDecoration(
                        labelText: 'Trigger Price',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addAlert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F63FF),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Set Alert', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Existing alerts list ─────────────────────────────────
              if (existing.isNotEmpty) ...[
                const Text('Active Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                ...existing.map(
                      (a) => _AlertRow(
                    alert: a,
                    onDelete: () => _deleteAlert(a),
                  ),
                ),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No active alerts for ${widget.symbol}', style: TextStyle(color: Colors.grey.shade400)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

/// A visually distinct card for selecting options
class _OptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? color : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final PriceAlert alert;
  final VoidCallback onDelete;

  const _AlertRow({required this.alert, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isTriggered = alert.triggered;
    final directionColor = alert.direction == AlertDirection.above ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isTriggered ? Colors.amber.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTriggered ? Colors.amber.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isTriggered ? Icons.check_circle_rounded : Icons.notifications_active_outlined,
            color: isTriggered ? Colors.amber.shade700 : directionColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alert.direction == AlertDirection.above ? "Above" : "Below"} ₹${alert.targetPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: directionColor, fontSize: 14),
                ),
                if (isTriggered)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Triggered', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade700)),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
            onPressed: onDelete,
            splashRadius: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}